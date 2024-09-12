`timescale 1ps/1ps
`include "ZPortableDefine.v"
//vsim work.ZIRCapture_Top iCE40UP.HSOSC iCE40UP.PLL_B

module ZIRCapture_Top(
	//Reserved IO(s).
	output reg [1:0] oIR_Reserved,
	output oIR_UPLD_DONE,

	//Yantai InfiRay Infrared Image Sensor Interface.
	input iIR_PCLK,
	input iIR_VSYNC,
	input iIR_HSYNC,
	input [13:0] iIR_Data, //only 8-bits are used in CDS-3 Interface.

	//Interfactive signals.
	output oWr_Req, //Write Request for HyperRAM.
	output oWr_Done, //Write Done for HyperRAM.

	//HyperRAM write interface.
	output oRAM_CLK,
	output oRAM_RST,
	output oRAM_CE,
	output oRAM_DQS,
	output [7:0] oRAM_ADQ
);
/* synthesis RGB_TO_GPIO = "oIR_Reserved[0], oIR_Reserved[1], oIR_UPLD_DONE" */

//HSOSC
//High-frequency oscillator.
//Generates 48-MHz nominal clock, +/- 10 percent, with user-programmable divider. 
//Can drive global clock network or fabric routing.
//Input Ports
//CLKHFPU :Power up the oscillator. After power up, output will be stable after 100us. Active high.
//CLKHFEN :Enable the clock output. Enable should be low for the 100us power-up period. Active high.
//Output Ports
//CLKHF :Oscillator output
//Parameters
//CLKHF_DIV
//Clock divider selection:
//0'b00 = 48 MHz
//0'b01 = 24 MHz
//0'b10 = 12 MHz
//0'b11 = 6 MHz
wire clk_48MHz;
HSOSC #(.CLKHF_DIV("0b00")) //48 MHz
my_HSOSC(
    .CLKHFPU(1'b1), 
    .CLKHFEN(1'b1), 
    .CLKHF(clk_48MHz)
);

reg rst_n_POR;
initial begin 
	rst_n_POR<=0;
	#100 rst_n_POR<=1;
end
//PLL: 48MHz->66MHz.
//WARNING!!!!!
//If I configured PLL outputs 70MHz, it doesn't work correctly.
//Then I slowed down to 66MHz, it starts to work.
wire rst_n;
wire clk_66MHz_Global;
wire clk_66MHz_Fabric;
ZPLL ic_pll(
		.ref_clk_i(clk_48MHz), 
        
		`ifdef USING_MODELSIM
			.rst_n_i(rst_n_POR), //Enable this line in ModelSim.
		`else
			.rst_n_i(1'b1),  //Enable this line in Radiant.
		`endif
        .lock_o(rst_n), 
        .outcore_o(clk_66MHz_Fabric), 
        .outglobal_o(clk_66MHz_Global)
);


// ZResetGenerator ic_Reset(
// 	.iClk(clk_48MHz), 
// 	.oRst_N(rst_n)
// );

////////////////////////////////////////////////////////
//UART Tx.
reg [7:0] UART_Tx_DR; //Tx Data Register.
reg UART_Tx_En;
wire UART_Tx_Done;
//generate 2MHz Clock. 
//66MHz/2MHz=33.
ZUART_Tx #(.Freq_divider(33)) ic_UART_Tx 
(
	.iClk(clk_66MHz_Global),
	.iRst_N(rst_n),
	.iData(UART_Tx_DR),

	//pull down iEn to start transmition until pulse done oDone was issued.
	.iEn(UART_Tx_En),
	.oDone(UART_Tx_Done),
	.oTxD(oIR_UPLD_DONE)
);

// always @(posedge clk_48MHz or negedge rst_n)
// if(!rst_n) begin
// 	oRAM_CLK<=0;
// end
// else begin
// 	oRAM_CLK<=~oRAM_CLK; //Measured 24MHz 50% duty cycle waveform at Physical Pin.
// end

//Capture DVP signals and write into EBR.
reg Capture_En;
wire Frame_Done;
ZCDS3_Capture ic_CDS3(
    .iClk(clk_66MHz_Global),
    .iRst_N(rst_n),
    .iEn(Capture_En),

    //input signals.
    .iIR_PCLK(iIR_PCLK),
    .iIR_Data(iIR_Data[7:0]), //only 8-bits are used in CDS-3 Interface.

	//Interfactive signals.
	.oWr_Req(oWr_Req), //Write Request for HyperRAM.
	.oWr_Done(oWr_Done), //Write Done for HyperRAM.

	//HyperRAM write interface.
	.oRAM_CLK(oRAM_CLK),
	.oRAM_RST(oRAM_RST),
	.oRAM_CE(oRAM_CE),
	.oRAM_DQS(oRAM_DQS),
	.oRAM_ADQ(oRAM_ADQ),

    //Capture one frame done?
	.oFrame_Done(Frame_Done)
);

reg [15:0] CNT_Step;
reg [31:0] CNT_Delay;
reg [7:0] Temp_DR;
always @(posedge clk_66MHz_Global or negedge rst_n)
if(!rst_n) begin
	CNT_Step<=0; CNT_Delay<=0;
	Capture_En<=0;
	UART_Tx_En<=0; UART_Tx_DR<=0; 
end
else begin
	case(CNT_Step)
		0: //delay for a while to be stable, without delay, UART will send random data when power on.//66MHz=32'h3EF1480
			`ifdef USING_MODELSIM
				if(CNT_Delay==100) begin CNT_Delay<=0; CNT_Step<=CNT_Step+1; end //Enable this line in ModelSim.
			`else //66MHz, wait 6s to prepare the oscilloscope.
				if(CNT_Delay==32'h179A7B00) begin CNT_Delay<=0; CNT_Step<=CNT_Step+1; end //Enable this line in Radiant.
			`endif
			else begin CNT_Delay<=CNT_Delay+1; end

		1: //capture one frame and write into HyperRAM.
			if(Frame_Done) begin Capture_En<=0; CNT_Step<=CNT_Step+1; end
			else begin Capture_En<=1; end

		2:
			if(UART_Tx_Done) begin UART_Tx_En<=0; CNT_Step<=CNT_Step+1; end
			else begin UART_Tx_En<=1; UART_Tx_DR<=8'h55; end
		3: //Stop Here.
			begin CNT_Step<=3; end
	endcase
end

/*
//EBR 4K Write & Read Test Successfully.
reg [7:0] CNT1;
reg [8:0] EBR_Addr; //EBR 4K Address Index.
reg [7:0] EBR_Data;
reg [7:0] Temp_DR; //Temporary Data Register.
always @(posedge clk_System or negedge rst_n)
if(!rst_n) begin
	CNT1<=0;
	UART_Tx_En<=0;
end
else begin
	case(CNT1)
		0: //delay for a while for stability, without delay, UART will send random data when power on.
			if(Temp_DR==8'hFF) begin Temp_DR<=0; CNT1<=CNT1+1; end
			else begin Temp_DR<=Temp_DR+1; end

		1: //send 2 bytes to ensure UART transmission is correct.
			if(UART_Tx_Done) begin UART_Tx_En<=0; CNT1<=CNT1+1; end
				else begin UART_Tx_En<=1; UART_Tx_DR<=8'h66; end
		2:
			begin 
				if(UART_Tx_Done) begin UART_Tx_En<=0; CNT1<=CNT1+1; end
					else begin UART_Tx_En<=1; UART_Tx_DR<=8'h88; end
				/////////////////
				EBR_Addr<=0; EBR_Data<=0; 
			end
////////////////////////////////////////////////////////////////////////////////
		3: //write into EBR.
			begin EBR_Wr_En<=1; EBR_Wr_Addr<=EBR_Addr; EBR_Wr_Data<=EBR_Data; CNT1<=CNT1+1; end
		4: //
			begin EBR_Wr_En<=0; CNT1<=CNT1+1; end
		5: //Must delay 1 clock, otherwise it won't write into EBR.
			begin CNT1<=CNT1+1; end
		6: //loop to write.
			if(EBR_Addr==510) begin EBR_Addr<=0; CNT1<=CNT1+1; end
			else begin EBR_Addr<=EBR_Addr+1; EBR_Data<=EBR_Data+1; CNT1<=3; end
////////////////////////////////////////////////////////////////////////////////
		7: //read back.
			begin 
				EBR_Rd_En<=1; EBR_Rd_Addr<=EBR_Addr; Temp_DR<=8'hFF; 
				CNT1<=CNT1+1; 
			end
		8: //must delay 1 clock.
			begin Temp_DR<=EBR_Rd_Data; CNT1<=CNT1+1; end
		9: //delay 1 clock to read correct data.
			begin EBR_Rd_En<=0; CNT1<=CNT1+1; end
		10: //Tx.
			if(UART_Tx_Done) begin UART_Tx_En<=0; CNT1<=CNT1+1; end
				else begin UART_Tx_En<=1; UART_Tx_DR<=Temp_DR; end
		11: //loop to read. 
			if(EBR_Addr==510) begin EBR_Addr<=0; CNT1<=CNT1+1; end
			else begin EBR_Addr<=EBR_Addr+1; CNT1<=7; end
////////////////////////////////////////////////////////////////////////////////
		12: //Tx 8'h33 to indicate end.
			if(UART_Tx_Done) begin UART_Tx_En<=0; CNT1<=CNT1+1; end
				else begin UART_Tx_En<=1; UART_Tx_DR<=8'h33; end
		13: //Tx 8'h99 to indicate end.
			if(UART_Tx_Done) begin UART_Tx_En<=0; CNT1<=CNT1+1; end
				else begin UART_Tx_En<=1; UART_Tx_DR<=8'h99; end
		14: //end
			begin CNT1<=CNT1; end
	endcase
end
*/
endmodule