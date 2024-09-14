`timescale 1ps/1ps
`include "ZPortableDefine.v"
//vsim work.ZIRRoute_Top iCE40UP.HSOSC
module ZIRRoute_Top(
	//IO Multiplex
    //0: DB_IO_0 -> CFG_SPI_D0, DB_IO_1 -> CFG_SPI_D2, DB_IO_2 -> CFG_SPI_D1, DB_IO_3 -> CFG_SPI_D3
    //1: DB_IO_0 -> IR_UART_TX, DB_IO_1 -> IR_UART_RX, DB_IO_2 -> UPLD_UART_TX, DB_IO_3 -> UPLD_UART_RX
	output reg oIOMux,
	//IR Configure UART Interface.
	output oIR_UART_TxD,
	input iIR_UART_RxD,
	//Upload UART.
	output oUPLD_UART_TxD,
	input iUPLD_UART_RxD,

	//HyperRAM Interface.
	inout [7:0] ioPSRAM_ADQ,
	output oPSRAM_CLK,
	output oPSRAM_CE,
	output oPSRAM_RST,
	inout ioPSRAM_DQS_DM,
	
	//IR FPGA Interface, route these signals to HyperRAM for writing.
	input [7:0] iRAM_ADQ,
	input iRAM_CLK,
	input iRAM_CE,
	input iRAM_RST,
	input iRAM_DQS_DM,

	//1: IR Image Sensor Request to write HyperRAM.
	input iWr_Req, //SAMPLE_EN.
	//1: IR Image Sensor write HyperRAM done.
	input iWr_Done, //SAMPLE_DONE.

	//LED Indicator.
	output reg oLED1,
	output reg oLED2
)/* synthesis RGB_TO_GPIO = "oLED1, oLED2" */;

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
//By default, the outputs are routed to global clock network. 
//To route to local fabric, see the examples in the Appendix: Design Entry section.
HSOSC #(.CLKHF_DIV("0b00")) //48 MHz
my_HSOSC(
    .CLKHFPU(1'b1), 
    .CLKHFEN(1'b1), 
    .CLKHF(clk_48MHz)
)/* synthesis ROUTE_THROUGH_FABRIC= 0 */; //the value can be either 0 or 1

///////////////////////////////////////////////////////////////////
//We are not allowed to use PLL output, because it's exclusive with Pin-35. ADQ[7].
//if PLL use internal clock source, Pin-35 can be used as output.
//PLL: 48MHz->66MHz.
//WARNING!!!!!
//If I configured PLL outputs 70MHz, it doesn't work correctly.
//Then I slowed down to 66MHz, it starts to work.
// wire rst_n;
// wire clk_66MHz_Global;
// wire clk_66MHz_Fabric;
// ZPLL ic_pll(
// 	.ref_clk_i(clk_48MHz), 
// 	.rst_n_i(1'b1), 
// 	.lock_o(rst_n), 
// 	.outcore_o(clk_66MHz_Fabric), 
// 	.outglobal_o(clk_66MHz_Global)
// );

// reg rst_n;
// initial begin 
// 	rst_n=0;
// 	#100 rst_n=1;
// end
wire rst_n;
ZResetGenerator ic_Reset(
	.iClk(clk_48MHz), 
	.oRst_N(rst_n)
);

/////////////////////////////////////////////////////
reg [7:0] wrData_ADQ;
reg whichWr; //select, 0:Data1, 1:Data2.
reg triState;
wire [7:0] rdData_ADQ;
///////////////////////////////////////////////////
genvar i1;
generate 
	for(i1=0;i1<=7;i1=i1+1) begin: gen_i1
		ZHyperRAMMux_B ic_mux_ADQ(
			.ioPAD(ioPSRAM_ADQ[i1]), //bidirectional PAD.
			///////////////////
			.iWrData1(iRAM_ADQ[i1]), //From IR Image Sensor(FPGA).
			.iWrData2(wrData_ADQ[i1]), //This FPGA.
			.iWhichWr(whichWr), //select, 0:Data1, 1:Data2.
			//////////////////////////
			.iTriState(triState),  //Tri-State control, 1:output, 0:High-Z.
			.oRdData(rdData_ADQ[i1]) //Read data from PAD.
		);
	end
endgenerate

///////////////////////////////////////////////////////
reg wrData_DQS_DM;
wire Data_DQS_DM;
// assign Data_DQS_DM=(!whichWr)?(iRAM_DQS_DM):(wrData_DQS_DM);

wire rdData_DQS_DM;
reg triState_DQS_DM;
// BB_B ic_DQS_DM(
//   .T_N (triState_DQS_DM),  // I, T_N=0, O=High-Z.
//   .I   (Data_DQS_DM),  // I
//   .B   (ioPSRAM_DQS_DM),  // IO
//   .O   (rdData_DQS_DM)   // O
// );
assign ioPSRAM_DQS_DM=(!whichWr)?(1'b0):(1'bz);
/*
ZHyperRAMMux_B ic_mux_DQS_DM(
	.ioPAD(ioPSRAM_DQS_DM), //bidirectional PAD.
	///////////////////
	.iWrData1(iRAM_DQS_DM), //From IR Image Sensor(FPGA)
	.iWrData2(wrData_DQS_DM), //This FPGA.
	.iWhichWr(whichWr), //select, 0:Data1, 1:Data2.
	//////////////////////////
	.iTriState(triState_DQS_DM),  //Bidirectional control, 1=output direction, 0=input direction.
	.oRdData(rdData_DQS_DM) //Read data from PAD.
);
*/
////////////////////////////////////////////////////////////////////
reg RAM_CLK_i;
reg RAM_CE_i;
//Route IR_FPGA-RAM_CLk to HyperRAM-PSRAM_CLK for Writing.
//Route ME_FPGA-RAM_CLK_i to HyperRAM-PSRAM_CLK for Reading.
assign oPSRAM_CLK=(!whichWr)?(iRAM_CLK):(RAM_CLK_i);
assign oPSRAM_CE=(!whichWr)?(iRAM_CE):(RAM_CE_i);
//Only IR(FPGA) has permission to reset HyperRAM.
assign oPSRAM_RST=iRAM_RST; 
///////////////////////////////////////////////////////////////////
//UART uploading.
reg [7:0] UART_Tx_DR; //Tx Data Register.
reg UART_Tx_En;
wire UART_Tx_Done;
//generate 2MHz Clock. //48MHz/2MHz=24.
ZUART_Tx #(.Freq_divider(24)) ic_UART_Tx 
(
	.iClk(clk_48MHz),
	.iRst_N(rst_n),
	.iData(UART_Tx_DR),

	//pull down iEn to start transmition until pulse done oDone was issued.
	.iEn(UART_Tx_En),
	.oDone(UART_Tx_Done),
	.oTxD(oUPLD_UART_TxD)
);

/////////////////////////////////////////
reg IRSensor_En;
reg [2:0] IRSensor_OpReq;
wire IRSensor_OpDone;
ZIRSensor_Controller ic_IRSensor_Controller(
    .iClk(clk_48MHz),
    .iRst_N(rst_n),
    .iEn(IRSensor_En),

    //Interactive Interface.
    //iOp_Req=0, idle.
    //iOp_Req=1, Select CDS3 Interface & Save.
    .iOp_Req(IRSensor_OpReq),
    .oOp_Done(IRSensor_OpDone),

    //Physical Pins.
    .iIR_UART_RxD(iIR_UART_RxD),
    .oIR_UART_TxD(oIR_UART_TxD)
);
////////////////////////////////////////////////////////////////////
//Command List.
parameter CMD_SYNC_RD=8'h00;
parameter CMD_SYNC_WR=8'h80;
parameter CMD_LINEAR_BURST_RD=8'h20;
parameter CMD_LINEAR_BURST_WR=8'hA0;
parameter CMD_MODE_REG_RD=8'h40;
parameter CMD_MODE_REG_WR=8'hC0;
parameter CMD_GBL_RST=8'hFF;
///////////////////////////////////////////////////////////////////////
reg [7:0] CNT_i;
reg [31:0] CNT_Delay;
//Read Fixed Data at the beginning address 0x0 of HyperRAM, they're 96'h090110140323871986191320.
reg [95:0] Temp_DR;
reg [31:0] Rd_Addr; 
reg [7:0] Rd_Bytes;
reg [7:0] Rd_Retry;
reg Rd_Data_Valid;
always @(posedge clk_48MHz or negedge rst_n)
if(!rst_n) begin
	CNT_i<=0; CNT_Delay<=0;
	UART_Tx_En<=0; UART_Tx_DR<=0; 
	IRSensor_En<=0; IRSensor_OpReq<=0; 
	whichWr<=0; //select, 0:Data1 from IR(FPGA) for writing, 1:Data2 from me for reading.
	triState<=1; //Bidirectional control, 1=output direction, 0=input direction.
	triState_DQS_DM<=1; //Output direction.
	wrData_ADQ<=0;
	RAM_CLK_i<=0; RAM_CE_i<=1; //CLK=0 at default, CE=1 at default.
	Temp_DR<=0; Rd_Addr<=0; Rd_Bytes<=0; Rd_Retry<=0; Rd_Data_Valid<=0;

	oLED1<=0; oLED2<=0;
	//IO Multiplex
    //0: DB_IO_0 -> CFG_SPI_D0, DB_IO_1 -> CFG_SPI_D2, DB_IO_2 -> CFG_SPI_D1, DB_IO_3 -> CFG_SPI_D3
    //1: DB_IO_0 -> IR_UART_TX, DB_IO_1 -> IR_UART_RX, DB_IO_2 -> UPLD_UART_TX, DB_IO_3 -> UPLD_UART_RX
	oIOMux<=1;
end
else begin
	case(CNT_i)
		0: //Waiting device to be stable after power on.
			begin 
				whichWr<=0; //select, 0:Data1 from IR(FPGA) for writing, 1:Data2 from me for reading.
				triState<=1; //Bidirectional control, 1=output direction, 0=input direction.
				triState_DQS_DM<=1; //Bidirectional control, 1=output direction, 0=input direction.
				RAM_CLK_i<=0; RAM_CE_i<=1; //CLK=0 at default, CE=1 at default.
				Rd_Bytes<=0; Rd_Retry<=0; Rd_Data_Valid<=0;
				////////////////////////////////////////////////////////////////
				`ifdef USING_MODELSIM
					if(CNT_Delay==1024) begin CNT_Delay<=0; CNT_i<=CNT_i+1; end
				`else //Wait 2s. //48MHz=32'h2DC6C00
					if(CNT_Delay==32'h2DC6C00) begin CNT_Delay<=0; CNT_i<=CNT_i+1; end
				`endif
					else begin CNT_Delay<=CNT_Delay+1; end
			end
		1: //Configure IR Sensor, should be removed before distribution.
			//ONLY NEED TO CONFIGURE ONCE,
			//Yantai InfiRay IR Image Sensor ELF3 Module will save configuration.
			// if(IRSensor_OpDone) begin IRSensor_En<=0; CNT_i<=CNT_i+1; end
			// else begin IRSensor_OpReq<=1; IRSensor_En<=1; end
			begin CNT_i<=CNT_i+1; end
		2: //Upload fixed bytes to indicate I start to work.
			if(UART_Tx_Done) begin UART_Tx_En<=0; CNT_i<=CNT_i+1; end
			else begin UART_Tx_En<=1; UART_Tx_DR<=8'h66; end
		3: //Waiting for IR Image Sensor Write Request.
			//iWr_Req was issued by IR(FPGA) and extended 6 times clock period to ensure that I can capture it correctly.
			// `ifdef USING_MODELSIM 
			// 	if(1) begin
			// `else
			// 	if(iWr_Req) begin
			// `endif
			// 		whichWr<=0; //select, 0:Data1 from IR(FPGA) for writing, 1:Data2 from me for reading.
			// 		triState<=1; //Bidirectional control, 1=output direction, 0=input direction.
			// 		oLED1<=1;
			// 		CNT_i<=CNT_i+1; 
			// 	end
			begin CNT_i<=CNT_i+1; end
		4: //Waiting for IR Image Sensor Write Done.
			//iWr_Done was issued by IR(FPGA) and extended 6 times clock period to ensure that I can capture it correctly.
			// `ifdef USING_MODELSIM 
			// 	if(1) begin
			// `else
			// 	if(iWr_Done) begin
			// `endif
			// 		//IR(FPGA) write done, now let's read.
			// 		whichWr<=1; //select, 0:Data1 from IR(FPGA) for writing, 1:Data2 from me for reading.
			// 		triState<=1; //Bidirectional control, 1=output direction, 0=input direction.
			// 		oLED1<=0;
			// 		CNT_i<=CNT_i+1; 
			// 	end
			begin CNT_Delay<=0; CNT_i<=CNT_i+1; end
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		5: //if we detect iWr_Done is 1 over 20 clocks, it means FPGA(Capture) work done, we can read now.
			if(iWr_Done) begin 
				if(CNT_Delay==20-1) begin CNT_Delay<=0; oLED1<=1; Rd_Addr<=0; CNT_i<=CNT_i+1; end
				else begin CNT_Delay<=CNT_Delay+1; end
			end
		6: //Prepare rising edge data. 
			if(CNT_Delay==2) begin CNT_Delay<=0; CNT_i<=CNT_i+1; end
			else begin
				CNT_Delay<=CNT_Delay+1;

				whichWr<=1; //select, 0:Data1 from IR(FPGA) for writing, 1:Data2 from me for reading.
				triState<=1; //Bidirectional control, 1=output direction, 0=input direction.
				triState_DQS_DM<=0; //Bidirectional control, 1=output direction, 0=input direction.
				oLED1<=1;

				RAM_CE_i<=0; //Pull down CE to start, extend CE to 3 clock periods.
				wrData_ADQ<=CMD_LINEAR_BURST_RD; //output data.
			end
/////////////////////////////////////////////////////////////////////////////////////
		7: //Pull up CLK. (1st Rising Edge)
			begin RAM_CLK_i<=1; CNT_i<=CNT_i+1; end
		8: //Prepare falling edge data.
			begin wrData_ADQ<=CMD_LINEAR_BURST_RD; CNT_i<=CNT_i+1; end
		9: //Pull down CLK. (1st Falling Edge)
			begin RAM_CLK_i<=0; CNT_i<=CNT_i+1; end
/////////////////////////////////////////////////////////////////////////////////
		10: //prepare rising edge data. //iAddress[31:24]
			begin wrData_ADQ<=Rd_Addr[31:24]; CNT_i<=CNT_i+1; end
		11: //Pull up CLK. (2nd Rising Edge)
			begin RAM_CLK_i<=1; CNT_i<=CNT_i+1; end
		12: //Prepare falling edge data. //iAddress[23:16]
			begin wrData_ADQ<=Rd_Addr[23:16]; CNT_i<=CNT_i+1; end
		13: //Pull down CLK. (2nd Falling Edge)
			begin RAM_CLK_i<=0; CNT_i<=CNT_i+1; end
	/////////////////////////////////////////////////////////////////////////////////////////////////
		14: //prepare rising edge data. //iAddress[15:8]
			begin wrData_ADQ<=Rd_Addr[15:8]; CNT_i<=CNT_i+1; end
		15: //Pull up CLK. (3rd Rising Edge)
			begin RAM_CLK_i<=1; CNT_i<=CNT_i+1; end
		16: //Prepare data. //iAddress[7:0]
			begin wrData_ADQ<=Rd_Addr[7:0]; CNT_i<=CNT_i+1; end 
		17: //Pull down CLK. (3rd Falling Edge)  
			begin RAM_CLK_i<=0; CNT_i<=CNT_i+1; end //Latency=1.
	//////////////////////////////////////////////////////////////////////////////////////////////////
		18: 
			begin 
				triState<=0; //Bidirectional control, 1=output direction, 0=input direction.
				Temp_DR<=0; Rd_Bytes<=0; Rd_Retry<=0; Rd_Data_Valid<=0;
				CNT_i<=CNT_i+1; 
			end
		19: //Pull up CLK. (Xth Rising Edge)
			begin RAM_CLK_i<=1; CNT_i<=CNT_i+1; end
		20: //The 1st DQS/DM rising edge after read pre-amble indicates the beginning of valid data.
			begin //And I'm not sure DQS/DM rising edge will occur on rising or falling edge of clock. Therefore I check on both edges.
				if(ioPSRAM_DQS_DM|Rd_Data_Valid) begin 
					Rd_Data_Valid<=1; Temp_DR<={Temp_DR[87:0],ioPSRAM_ADQ}; Rd_Bytes<=Rd_Bytes+1; 
				end
				///////////////////////////////////////////////
				CNT_i<=CNT_i+1; 
			end
		21: //Pull down CLK. (Xth Falling Edge)
			begin RAM_CLK_i<=0; CNT_i<=CNT_i+1; end
		22: //The 1st DQS/DM rising edge after read pre-amble indicates the beginning of valid data. 
			begin //And I'm not sure DQS/DM rising edge will occur on rising or falling edge of clock. Therefore I check on both edges.
				if(ioPSRAM_DQS_DM|Rd_Data_Valid) begin 
					Rd_Data_Valid<=1; Temp_DR<={Temp_DR[87:0],ioPSRAM_ADQ}; Rd_Bytes<=Rd_Bytes+1; 
				end
				///////////////////////////////////////////////
				CNT_i<=CNT_i+1; 
			end
		23: //Waiting 10 clocks for DQS/DM, timeout to break.
			if(Rd_Data_Valid) begin 
				if(Rd_Bytes>=12) begin CNT_i<=CNT_i+1; end
				else begin CNT_i<=CNT_i-4; end //continue to read.
			end
			else begin //According to the experiment consequence, DQS/DM isn't be pulled up at first reading.
			//so I retry 10 times, if still not get valid DQS/DM, then send fixed data to indicate failure.
				if(Rd_Retry==10) begin Rd_Retry<=0; Temp_DR<=96'hFF19AA89FF0604FF205524FF; CNT_i<=CNT_i+1; end //Failed this time!
				else begin Rd_Retry<=Rd_Retry+1; CNT_i<=CNT_i-4; end //Retry! 
			end
		24: 
			begin CNT_i<=CNT_i+1; end 
		25: 
			begin CNT_i<=CNT_i+1; end
	//////////////////////////////////////////////////////////////////////////////////////////////////
		26: //pull up CE to end. Extend CE width to 6*clcoks.
			if(CNT_Delay==6) begin CNT_Delay<=0; RAM_CE_i<=1; CNT_i<=CNT_i+1; end
			else begin CNT_Delay<=CNT_Delay+1; end
////////////////////////////////////////////////////////////////////
		27: //Tx one byte.
			if(UART_Tx_Done) begin UART_Tx_En<=0; CNT_i<=CNT_i+1; end
			else begin UART_Tx_En<=1; UART_Tx_DR<=Temp_DR[95:88]; end
		28: //Loop to Tx 12 times.
			if(CNT_Delay==12-1) begin CNT_Delay<=0; CNT_i<=CNT_i+1; end
			else begin CNT_Delay<=CNT_Delay+1; Temp_DR<={Temp_DR[87:0],8'd0}; CNT_i<=CNT_i-1; end
/////////////////////////////////////////////////////////////////////////////////
		29: 
			//Because maximum CE Low Width is 2uS. 
			//And now I measured with an oscilloscope, reading 12 bytes each time takes up 1.6uS.
			//so we repeat 1024bytes/12bytes=85.3333 times, so we read 1032/12=86.
			if(Rd_Data_Valid) begin
				if(Rd_Addr>=1024) begin Rd_Addr<=0; oLED1<=0; CNT_i<=CNT_i+1; end
				else begin Rd_Addr<=Rd_Addr+12; CNT_i<=6; end //read next address.
			end
			else begin
					CNT_i<=6; //previous reading failed, try one more time.
			end
////////////////////////////////////////////////////////////////////////////////
		30: //retry after 5s.
			if(CNT_Delay==32'hE4E1C00) begin CNT_Delay<=0; CNT_i<=6; end
			else begin CNT_Delay<=CNT_Delay+1; end 
	endcase
end
//////////////////////////////////////////////////////////////////
endmodule