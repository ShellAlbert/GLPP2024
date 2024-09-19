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
	output reg oWr_Req, //Write Request for DDR-PSRAM.
	output reg oWr_Done, //Write Done for DDR-PSRAM.

	//DDR-PSRAM physical write interface.
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
//Along with FPGA logic gets larger, 66MHz is not also reliable. 
//The maximum working frequency is 48MHz.
//If over 48MHz, unreliable potential risk will occur.
wire rst_n;
wire clk_48MHz_Global;
wire clk_48MHz_Fabric;
ZPLL ic_pll(
		.ref_clk_i(clk_48MHz), 
        
		`ifdef USING_MODELSIM
			.rst_n_i(rst_n_POR), //Enable this line in ModelSim.
		`else
			.rst_n_i(1'b1),  //Enable this line in Radiant.
		`endif
        .lock_o(rst_n), 
        .outcore_o(clk_48MHz_Fabric), 
        .outglobal_o(clk_48MHz_Global)
);


// ZResetGenerator ic_Reset(
// 	.iClk(clk_48MHz), 
// 	.oRst_N(rst_n)
// );



// always @(posedge clk_48MHz or negedge rst_n)
// if(!rst_n) begin
// 	oRAM_CLK<=0;
// end
// else begin
// 	oRAM_CLK<=~oRAM_CLK; //Measured 24MHz 50% duty cycle waveform at Physical Pin.
// end

/////////////////////////////////////////////////////////////////
//In order to make PingPong Operation success, 
//DDR-Writer must fast then CDS3Capture.
//DDR-Writer must read out all data before CDS3Capture start to write.
//////////////////////////////////////////////////////////////////
//Write Operation from CDS3_Capture.
wire SPRAM_Wr_Which; //Write which SPRAM:0/1.
wire [13:0] SPRAM_Wr_Addr; //Write Address.
wire [15:0] SPRAM_Wr_Data; //Write Data.
wire SPRAM_Wr_En; //Write Enable. 1:Write, 0:Read.
//Read Port from DDR_Writer.
wire [13:0] SPRAM_Rd_Addr; //Read Address.
wire SPRAM_Rd_En; //Read Enable. 1:Write, 0:Read.
wire [15:0] SPRAM_Rd_Data; //Read out Data.
///////////////////////////////////////////////////////////
ZSinglePortRAM ic_PingPongRAM(
    .iClk(clk_48MHz_Global), //I, Clock.

    .iWr_Which(SPRAM_Wr_Which), //I, Write which SPRAM:0/1.

    //Write Operation from CDS3_Capture.
    .iWr_Addr(SPRAM_Wr_Addr), //I, Write Address.
    .iWr_Data(SPRAM_Wr_Data), //I, Write Data.
    .iWr_En(SPRAM_Wr_En), //I, Write Enable. 1:Write, 0:Read.

    //Read Port from DDR_Writer.
    .iRd_Addr(SPRAM_Rd_Addr), //I, Read Address.
    .iRd_En(SPRAM_Rd_En), //I, Read Enable. 1:Write, 0:Read.
    .oRd_Data(SPRAM_Rd_Data) //O, Read out Data.
);
/////////////////////////////////////////////////////////////////////////////
//Capture DVP signals and write into EBR.
reg Capture_En;
wire SPRAM_Init_Done;
wire Cap_Line_Done;
wire Cap_Frame_Start;
wire Cap_Frame_Done;
wire [1:0] RAM_Data_Valid;
reg PCLK_Simulate;
ZCDS3_Capture ic_CDS3(
    .iClk(clk_48MHz_Global),
    .iRst_N(rst_n),
    .iEn(Capture_En),

    //input signals.
	`ifdef USING_MODELSIM
		.iIR_PCLK(PCLK_Simulate),
	`else
    	.iIR_PCLK(iIR_PCLK),
	`endif
    .iIR_Data(iIR_Data[7:0]), //only 8-bits are used in CDS-3 Interface.

	//Start to capture a new frame.
    .oCap_Frame_Start(Cap_Frame_Start),
    //End to capture a new frame.
    .oCap_Frame_Done(Cap_Frame_Done),
    //Capture one frame done?
	.oCap_Line_Done(Cap_Line_Done),

	//Write Single-Port RAM Interfaces.
	.oWr_Which(SPRAM_Wr_Which), //O, Write which SPRAM:0/1.
    .oWr_Addr(SPRAM_Wr_Addr), //O, Write Address.
    .oWr_Data(SPRAM_Wr_Data), //O, Write Data.
    .oWr_En(SPRAM_Wr_En), //O, Write Enable. 1:Write, 0:Read.

	//Notify me that DDR-Writer has done initilization.
    .iRAM_Init_Done(SPRAM_Init_Done),

	//indicate which Single-Port RAM data is valid.
    .oRAM_Data_Valid(RAM_Data_Valid)
);
/////////////////////////////////////////////////////////////////
reg DDRWriter_En;
wire Wr_Line_Done;
wire Wr_Frame_Done;
ZDDRWriter ic_DDRWriter(
    .iClk(clk_48MHz_Global),
    .iRst_N(rst_n),
    .iEn(DDRWriter_En),

	//DDR PSRAM physical write interface.
	.oRAM_CLK(oRAM_CLK),
	.oRAM_RST(oRAM_RST),
	.oRAM_CE(oRAM_CE),
	.oRAM_DQS(oRAM_DQS),
	.oRAM_ADQ(oRAM_ADQ),

    //Notify Capture Module that DDR-PSRAM initial done.
    .oRAM_Init_Done(SPRAM_Init_Done),

	//Frame Start & End.
    .iCap_Frame_Start(Cap_Frame_Start),
    .iCap_Frame_Done(Cap_Frame_Done),
	//CDS3Capture captured one line.
	.iCap_Line_Done(Cap_Line_Done),

	//Which Single-Port is in writing? 
    .iWr_Which(SPRAM_Wr_Which), //0/1.
    //Read from Single-Port RAM.
    .oRd_Addr(SPRAM_Rd_Addr), //O, Read Address.
    .oRd_En(SPRAM_Rd_En), //O, Read Enable. 1:Write, 0:Read.
    .iRd_Data(SPRAM_Rd_Data), //I, Read out Data from Single-Port-RAM.

	//indicate which Single-Port RAM data is valid.
    .iRAM_Data_Valid(RAM_Data_Valid), //I.
	.oWr_Line_Done(Wr_Line_Done), //O, write one line from Single-Port-RAM to DDR-PSRAM done.
	.oWr_Frame_Done(Wr_Frame_Done), //O, Means already written 1024 bytes to DDR-PSRAM.

	//Dump data from Single-Port-RAM to UART to check its correctness.
    .oUART_TxD(oIR_UPLD_DONE)
);
////////////////////////////////////////////////////////////
reg [15:0] CNT_Step;
reg [31:0] CNT_Delay;
reg [7:0] Temp_DR;
always @(posedge clk_48MHz_Global or negedge rst_n)
if(!rst_n) begin
	CNT_Step<=0; CNT_Delay<=0;
	Capture_En<=0; DDRWriter_En<=0; 
	oWr_Req<=0; oWr_Done<=0; 
end
else begin
	case(CNT_Step)
		0: //delay for a while to be stable, without delay, UART will send random data when power on.//66MHz=32'h3EF1480
				begin
				`ifdef USING_MODELSIM
					if(CNT_Delay==100) begin CNT_Delay<=0; CNT_Step<=CNT_Step+1; end //Enable this line in ModelSim.
				`else //66MHz, wait 6s to prepare the oscilloscope.
					if(CNT_Delay==32'h179A7B00) begin CNT_Delay<=0; CNT_Step<=CNT_Step+1; end //Enable this line in Radiant.
				`endif
				else begin CNT_Delay<=CNT_Delay+1; end
				///////////////////////////////
				oWr_Done<=0; 
				Capture_En<=0; DDRWriter_En<=0;
			end

		1: //output Wr_Req for 6 clock periods to ensure StoreFPGA can capture it correctly.
			// if(CNT_Delay==6-1) begin oWr_Req<=0; CNT_Step<=CNT_Step+1; end
			// else begin CNT_Delay<=CNT_Delay+1; oWr_Req<=1; end
			begin CNT_Step<=CNT_Step+1; end
		2: //Enable CD3Capture first because it waits for RAM_Init_Done from ZDDRWriter.
			begin 
				// if(Cap_Line_Done) begin Capture_En<=0; end
				// else begin Capture_En<=1; end
				///////////////////////////////////////////
				if(Wr_Frame_Done) begin DDRWriter_En<=0; Capture_En<=0; CNT_Step<=CNT_Step+1; end
				else begin DDRWriter_En<=1; Capture_En<=1; end
			end
		3: //output Wr_Done to notify StoreFPGA it can read.
			begin oWr_Done<=1; CNT_Step<=CNT_Step+1; end
		4: //Stop Here.
			begin CNT_Step<=CNT_Step; end
	endcase
end

//Fmax=66MHz, PixelCLK=9.375MHz.
//66MHz/9.375MHz=7.04
//66MHz is not reliable, we use 48MHz.
//48MHz/9.375MHz=5.12
reg [7:0] CNT_PCLK;
always @(posedge clk_48MHz_Global or negedge rst_n)
if(!rst_n) begin
	CNT_PCLK<=0;
	PCLK_Simulate<=0;
end
else begin
	if(CNT_PCLK==5-1) begin 
		CNT_PCLK<=0;
		PCLK_Simulate<=~PCLK_Simulate;
	end
	else begin 
		CNT_PCLK<=CNT_PCLK+1;
	end
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