`timescale 1ps/1ps

//project open F:/MyTemporary/Github/GLPP2024/Lattice_IRSnapshot/IRSnapshot/ModelSimSimulation/ZIRSnapshot

//ModelSim <Simulation> => <Start Simulation> => 
//Desing Unit(s): 
//vsim work.ZIRSnapshot iCE40UP.HFOSC iCE40UP.IOL_B iCE40UP.PLL_B iCE40UP.BB_B
//add wave
//run 10us 
//Right Click, Add->New Window Pane, Draw & Drag deubg signal into new window pane.

module ZIRSnapshot(
	output oLED1,
	output oLED2,
	output oIOMux,
	output oUART_TxD,

	//Octal RAM Interface.
	output oPSRAM_RST, //RESET# : Input Reset signal, active low. 
	output oPSRAM_CE, //CE#: Input, Chip select, active low. When CE#=1, chip is in standby state. 
	output oPSRAM_CLK,
	//DQS, IO.
	//DQ Strobe clock for DQ[7:0] during all reads.
	//Data mask for DQ[7:0] during memory writes.
	//DM is active HIGH, DM=1 means "do not write".
	inout ioPSRAM_DQS,
	inout [7:0] ioPSRAM_DATA //Address/Data bus [7:0].
);
/* synthesis RGB_TO_GPIO = "oLED1, oLED2" */

//HSOSC
//High-frequency oscillator.
//Generates 48-MHz nominal clock, +/- 10 percent, with user-programmable divider. 
//Can drive global clock network or fabric routing.
//Input Ports
//CLKHFPU :Power up the oscillator. After power up, output will be stable after 100 �s. Active high.
//CLKHFEN :Enable the clock output. Enable should be low for the 100-�s power-up period. Active high.
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
    .CLKHF(clk_48MHz))/* synthesis ROUTE_THROUGH_FABRIC=0 */;


//We MUST to generate a Power On Reset signal to reset PLL. 
//Otherwise it cannot work correctly in ModelSim. 
//All signals in ModelSim must have initial values.
reg rst_n_POR; //power on reset.
initial begin
	rst_n_POR<=0;
	#20000 rst_n_POR<=1;
end

//Clock/PLL  
//Phase locked loop. For internal use.
//USER INSTANTIATION: Not recommended; prefer IP Generation Tool.
//PLL: 48MHz -> 100MHz.
wire rst_n;
wire clk_100MHz;
ZIP_PLL ic_pll(
		.ref_clk_i(clk_48MHz),
        .rst_n_i(1'b1/*rst_n_POR*/), //MUST reset in ModelSim.
        .lock_o(rst_n), 
        .outcore_o(), 
        .outglobal_o(clk_100MHz));

// ZResetGenerator ic_RST(
// 	.iClk(clk_48MHz), 
// 	.oRst_N(rst_n));
// assign rst_n=rst_n_POR;

////////////////////WARNING HERE!!! ////////////////////////////
//PLL output can't drive global network or fabric routing, synthesize failed.
//assign oPSRAM_CLK=clk_System; 
//HSOSC output can't drive global network or fabric routing, synthesize successed.
//assign oPSRAM_CLK=clk_48MHz;
wire clk_System;
assign clk_System=clk_100MHz;

//instance.
ZLEDIndicator ic_led(
	.iClk(clk_System),
	.iRst_N(rst_n),
	.oLED1(oLED1),
	.oLED2(oLED2),
	.oIOMux(oIOMux));


////////////////////////////////////////////////////////
//UART Tx.
reg [7:0] UART_Tx_DR; //Tx Data Register.
reg UART_Tx_En;
wire UART_Tx_Done;
ZUART_Tx ic_tx(
	.iClk(clk_System),
	.iRst_N(rst_n),
	.iData(UART_Tx_DR),
	
	.iEn(UART_Tx_En),
	.oDone(UART_Tx_Done),
	.oTxD(oUART_TxD));

////////////////////////////////////////////////////////
//Embedded Block RAM 4K.
//Write Signals.
wire EBR_Wr_En;
wire [15:0] EBR_Wr_Data;
wire [8:0] EBR_Wr_Addr;
//Read Signals.
reg EBR_Rd_En;
wire [15:0] EBR_Rd_Data; 
reg [8:0] EBR_Rd_Addr;

ZRAM_4K ic_RAM4K(
		.wr_clk_i(clk_System),  //I, write clock.
		.rd_clk_i(clk_System),  //I, read clock.
		.rst_i(rst_n), //I, reset.
		.wr_clk_en_i(EBR_Wr_En), //I, Write Clock Enable.
		.rd_en_i(EBR_Rd_En), //I, Read Enable.
		.rd_clk_en_i(EBR_Rd_En), //I, Read Clock Enable. 
		.wr_en_i(EBR_Wr_En), //I, Write Enable.
		.wr_data_i(EBR_Wr_Data), //I, write data to RAM. 
		.wr_addr_i(EBR_Wr_Addr), //I, write address to RAM.
		.rd_addr_i(EBR_Rd_Addr), //I, Read Address from RAM.
		.rd_data_o(EBR_Rd_Data) //O, Read Data from RAM.
		); 

/*
//EBR 4K Write & Read Test Successfully.
reg [7:0] CNT1;
reg [8:0] CNT_Addr; //EBR 4K Address Index.
reg [15:0] CNT_Data;
reg [15:0] Temp_DR; //Temporary Data Register.
always @(posedge clk_System or negedge rst_n)
if(!rst_n) begin
	CNT1<=0;
	UART_Tx_En<=0;
	oLED1<=0;
	oLED2<=0;
end
else begin
	case(CNT1)
		0: //send 2 bytes to ensure UART transmission is correct.
			if(UART_Tx_Done) begin UART_Tx_En<=0; CNT1<=CNT1+1; end
				else begin UART_Tx_En<=1; UART_Tx_DR<=8'h66; end
		1:
			begin 
				if(UART_Tx_Done) begin UART_Tx_En<=0; CNT1<=CNT1+1; end
					else begin UART_Tx_En<=1; UART_Tx_DR<=8'h88; end
				/////////////////
				CNT_Addr<=0; CNT_Data<=0; 
			end
		2: //write into.
			begin EBR_Wr_En<=1; EBR_Wr_Data<=CNT_Data; EBR_Wr_Addr<=CNT_Addr; CNT1<=CNT1+1; end
		3: 
			begin EBR_Wr_En<=0; CNT1<=CNT1+1; end
		4: //read back.
			begin EBR_Rd_En<=1; EBR_Rd_Addr<=CNT_Addr; CNT1<=CNT1+1; end
		5: //must delay 1 clock.
			begin CNT1<=CNT1+1; end
		6: //delay 1 clock to read correct data.
			begin Temp_DR<=EBR_Rd_Data; EBR_Rd_En<=0; CNT1<=CNT1+1; end
		7:  //do judgement, check if read back data equals write data.
			if(Temp_DR==CNT_Data) begin 
									if(CNT_Addr==9'h1FE) begin
										CNT1<=CNT1+1;
									end
									else begin
										CNT_Addr<=CNT_Addr+1; CNT_Data<=CNT_Data+1; 
										CNT1<=2; 
									end
			end
			else begin oLED2<=1; CNT1<=CNT1+1; end //error stop.
		8: //Tx 8'h99 to indicate end.
			if(UART_Tx_Done) begin UART_Tx_En<=0; CNT1<=CNT1+1; end
				else begin UART_Tx_En<=1; UART_Tx_DR<=8'h99; end
		9: //end
			begin oLED1<=1; end
	endcase
end
*/

////////////////////////////////////////////////////////////
//Octal RAM Interface.
reg [2:0] Op_Code;
wire Op_Done;
reg [31:0] ram_Addr;
reg [15:0] ram_Data_i;
wire [15:0] ram_Data_o;
ZOctalRAMOperator ic_OctalRAM(
	.iClk(clk_System),
	.iRst_N(rst_n),
	//iOp_Code=0: Idle.
	//iOp_Code=1: Reset IC.
	//iOp_Code=2: Write Mode Register.
	//iOp_Code=3: Read Mode Register and write to EBR 4K.
	//iOp_Code=4: Sync Write, iAddress[31:0], iData[15:0].
	//iOp_Code=5: Sync Read, iAddress[31:0], oData[15:0].
	.iOp_Code(Op_Code),
	.oOp_Done(Op_Done),

	.iAddress(ram_Addr),
	.iData(ram_Data_i),
	.oData(ram_Data_o),

	//Octal RAM/EEPROM Interface.
	.oPSRAM_RST(oPSRAM_RST), //RESET# : Input Reset signal, active low. 
	.oPSRAM_CE(oPSRAM_CE), //CE#: Input, Chip select, active low. When CE#=1, chip is in standby state. 
	.oPSRAM_CLK(oPSRAM_CLK),
	.ioPSRAM_DQS_DM(ioPSRAM_DQS),
	.ioPSRAM_DATA(ioPSRAM_DATA),

	//Embedded Block RAM Interface.
	.oEBR_Wr_En(EBR_Wr_En),
	.oEBR_Wr_Data(EBR_Wr_Data),
	.oEBR_Wr_Addr(EBR_Wr_Addr)
);

//////////////////////////////////////////////////////////////
//Driven by CNT_RAM.
reg [7:0] CNT_RAM;
reg [31:0] CNT_Delay;
reg [15:0] Temp_DR; //Temporary Data Register.
reg [8:0] CNT_Addr; //EBR 4K Address Index.
reg [7:0] Step_Go;
reg [15:0] UPLD_DR; //Upload Data Register.
always @(posedge clk_System or negedge rst_n)
if(!rst_n) begin
	CNT_RAM<=0;
	CNT_Delay<=0;
	Op_Code<=0;
	UART_Tx_En<=0;
	CNT_Addr<=0;

end
else begin
		case(CNT_RAM)
			0: //First send 2 fixed bytes to indicate communication is correct.
				begin UPLD_DR<=16'h6688; CNT_RAM<=100; Step_Go<=CNT_RAM; /*+1;*/ end
			///////////////////////////////////////////////////////////////////////////////////
			1: //iOp_Code=1: Reset IC then go to step 10.
				if(Op_Done) begin Op_Code<=0; CNT_RAM<=10; end
				else begin Op_Code<=1; end
			///////////////////////////////////////////////////////////////////////////////////
			2: //iOp_Code=3: Read Mode Register and write to EBR 4K.
				if(Op_Done) begin Op_Code<=0; CNT_RAM<=CNT_RAM+1; end
					else begin Op_Code<=3; end
			3: //Read data from EBR 4K.
				begin EBR_Rd_En<=1; EBR_Rd_Addr<=CNT_Addr; CNT_RAM<=CNT_RAM+1; end
			4: //Must delay 1 clock.
				begin  CNT_RAM<=CNT_RAM+1; end
			5: //Store Read back data to a temporary data register.
				begin Temp_DR<=EBR_Rd_Data; EBR_Rd_En<=0; CNT_RAM<=CNT_RAM+1; end

			6: //Tx data - high byte.
				if(UART_Tx_Done) begin UART_Tx_En<=0; CNT_RAM<=CNT_RAM+1; end
					else begin UART_Tx_En<=1; UART_Tx_DR<=Temp_DR[15:8]; end
			7: //Tx data - low byte.
				if(UART_Tx_Done) begin UART_Tx_En<=0; CNT_RAM<=CNT_RAM+1; end
					else begin UART_Tx_En<=1; UART_Tx_DR<=Temp_DR[7:0]; end
			
			8: //Loop to read all EBR 4K data.
				if(CNT_Addr==12-1) begin CNT_Addr<=0; CNT_RAM<=CNT_RAM+1; end
				else begin CNT_Addr<=CNT_Addr+1; CNT_RAM<=4; end
			9: //delay for a while.
				if(CNT_Delay==32'hFF) begin CNT_Delay<=0; CNT_RAM<=CNT_RAM+1; end
					else begin CNT_Delay<=CNT_Delay+1; end
			////////////////////////////////////////////////////////////////////////////////
			10: //iOp_Code=2: Write Mode Register.
				if(Op_Done) begin Op_Code<=0; CNT_RAM<=CNT_RAM+1; end
					else begin Op_Code<=2; end

			11: //iOp_Code=3: Read Mode Register and write to EBR 4K.
				if(Op_Done) begin Op_Code<=0; CNT_RAM<=CNT_RAM+1; end
					else begin Op_Code<=3; end

			12: //Read data from EBR 4K.
				begin EBR_Rd_En<=1; EBR_Rd_Addr<=CNT_Addr; CNT_RAM<=CNT_RAM+1; end
			13: //Must delay 1 clock.
				begin CNT_RAM<=CNT_RAM+1; end
			14: //Store Read back data to a temporary data register.
				begin Temp_DR<=EBR_Rd_Data; EBR_Rd_En<=0; CNT_RAM<=CNT_RAM+1; end

			15: //Call sub-circuit to upload data.
				begin UPLD_DR<=Temp_DR; CNT_RAM<=100; Step_Go<=CNT_RAM+1; end

			16: //Loop to read all EBR 4K data.
				if(CNT_Addr==12-1) begin CNT_Addr<=0; CNT_RAM<=CNT_RAM+1; end
				else begin CNT_Addr<=CNT_Addr+1; CNT_RAM<=12; end

			17: //Call sub-circuit to send fixed bytes to isolate data field.
				begin UPLD_DR<=16'h3399; CNT_RAM<=100; Step_Go<=CNT_RAM+1; end

			18: //iOp_Code=4: Sync Write, iAddress[31:0], iData[15:0].
				if(Op_Done) begin Op_Code<=0; CNT_RAM<=CNT_RAM+1; end
					else begin Op_Code<=4; ram_Addr<=32'h0000; ram_Data_i<=16'h7777; end
			19: //iOp_Code=5: Sync Read, iAddress[31:0], oData[15:0].
				if(Op_Done) begin Op_Code<=0; CNT_RAM<=CNT_RAM+1; end
					else begin Op_Code<=5; ram_Addr<=32'h0000;	end

			20: 
				begin CNT_Addr<=0; CNT_RAM<=CNT_RAM+1; end
			21: //Read data from EBR 4K.
				begin EBR_Rd_En<=1; EBR_Rd_Addr<=CNT_Addr; CNT_RAM<=CNT_RAM+1; end
			22: //Must delay 1 clock.
				begin CNT_RAM<=CNT_RAM+1; end
			23: //Store Read back data to a temporary data register.
				begin Temp_DR<=EBR_Rd_Data; EBR_Rd_En<=0; CNT_RAM<=CNT_RAM+1; end

			24: //Call sub-circuit to upload data.
				begin UPLD_DR<=Temp_DR; CNT_RAM<=100; Step_Go<=CNT_RAM+1; end

			25:
				if(CNT_Addr==3) begin CNT_Addr<=0; CNT_RAM<=CNT_RAM+1; end
				else begin CNT_Addr<=CNT_Addr+1; CNT_RAM<=21; end
			26: //Stop Here.
				begin /*oLED1<=1;*/ CNT_RAM<=26; end


			100: //Upload High Byte.
				if(UART_Tx_Done) begin UART_Tx_En<=0; CNT_RAM<=CNT_RAM+1; end
					else begin UART_Tx_En<=1; UART_Tx_DR<=UPLD_DR[15:8]; end
			101: //Upload Low Byte.
				if(UART_Tx_Done) begin UART_Tx_En<=0; CNT_RAM<=Step_Go; end
					else begin UART_Tx_En<=1; UART_Tx_DR<=UPLD_DR[7:0]; end
			default:
				begin CNT_RAM<=0; end
		endcase
end
endmodule
