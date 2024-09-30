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

	//1: IR Image Sensor write DDR-PSRAM done.
	input iSample_Done, //SAMPLE_DONE.

	//1: FPGA Uploading done.
	output reg oUpload_Done, //SAMPLE_EN.

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

reg rst_POR_N;
initial begin 
	rst_POR_N=0;
	#100 rst_POR_N=1;
end

///////////////////////////////////////////////////////////////////
//We are not allowed to use PLL output, because it's exclusive with Pin-35. ADQ[7].
//if PLL use internal clock source, Pin-35 can be used as output.
//PLL: 48MHz->66MHz.
//WARNING!!!!!
//If I configured PLL outputs 70MHz, it doesn't work correctly.
//Then I slowed down to 66MHz, it starts to work.
//66MHz is not reliable, down to 48MHz.

//ERROR <67201318> - 
//When PLL.OUTCORE or PLL.OUTGLOBAL is used, the input IO at site 'PR13B' can only drive PLL.REFERENCECLK due to architecture constraint. 
//When PLL is utilized in the design, the I/O site 'PR13B' can only be used exclusively as a PLL clock input. 
//If PLL uses an internal clock, the I/O site 'PR13B' can be used as an output.
wire rst_n;
wire clk_48MHz_Global;
wire clk_48MHz_Fabric;
ZPLL ic_pll(
	.ref_clk_i(clk_48MHz), 
	`ifdef USING_MODELSIM
		.rst_n_i(rst_POR_N),
	`else
		.rst_n_i(1'b1), 
	`endif
	.lock_o(rst_n), 
	.outcore_o(clk_48MHz_Fabric), 
	.outglobal_o(clk_48MHz_Global)
);


// wire rst_n;
// ZResetGenerator ic_Reset(
// 	.iClk(clk_48MHz), 
// 	.oRst_N(rst_n)
// );

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
//Since the size of One Page of DDR-PSRAM is 2K, data width is 8-bits, so it's 2KByte.
//And One Single Line of Infrared Image Sensor is 256*2Bytes(Pixel)+256*2Bytes(Temperature)=1024 Bytes.
//So each time we write FF0000B6, FF0000AB, FF00009D, FF000080, 256*2Bytes(Pixel)+256*2Bytes(Temperature) into Single-Port-RAM,
//the total size is 4+4+4+4+256*2+256*2=1040.
//The resolution of infrared image is 256*192, so we need 192 pages to save all lines.

//Warning!!!!!!!
//Only the 1st line of each frame is leading with FF0000B6, FF0000AB, FF00009D, FF000080.
//Other lines are leading with XXXXXXXX, XXXXXXXX, XXXXXXXX, FF000080
//////////////////////////////////////////////////////////////////////////////////////////////////
//we read 10*2 bytes in single burst read. //10*2*8=160.
reg [159:0] Temp_DR;
reg [31:0] Rd_Addr; 
reg [7:0] Rd_Bytes;
reg [7:0] Rd_Retry;
reg Rd_Data_Valid;
////////////////////////////////////////////////////
reg [13:0] rowAddr; //2^14=16384 Pages.
reg [10:0] colAddr; //2^11=2048/1024=2K
//(16384*2048)/1024=32768K/1024=32M,  32M*8bits=256Mbits.
wire [31:0] DDR_RAM_Addr; 
assign DDR_RAM_Addr={7'd0, rowAddr, colAddr};
////////////////////////////////////////////////////////////////
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

	oLED1<=0; oLED2<=0; rowAddr<=0; colAddr<=0; 
	//IO Multiplex
    //0: DB_IO_0 -> CFG_SPI_D0, DB_IO_1 -> CFG_SPI_D2, DB_IO_2 -> CFG_SPI_D1, DB_IO_3 -> CFG_SPI_D3
    //1: DB_IO_0 -> IR_UART_TX, DB_IO_1 -> IR_UART_RX, DB_IO_2 -> UPLD_UART_TX, DB_IO_3 -> UPLD_UART_RX
	oIOMux<=1;
	oUpload_Done<=0;
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
				rowAddr<=0; colAddr<=0; 
				oUpload_Done<=0;
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
			// if(UART_Tx_Done) begin UART_Tx_En<=0; CNT_i<=CNT_i+1; end
			// else begin UART_Tx_En<=1; UART_Tx_DR<=8'h66; end
			begin CNT_i<=CNT_i+1; end
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
		5: //FPGA(IRCapture) pulls up Sample_Done after it writes one complete frame into DDR-PSRAM.
			//if we detect iSample_Done is 1 over 1 seconds, it means FPGA(Capture) work done, we can read now.
			begin
				`ifdef USING_MODELSIM
					if(1) begin 
						if(CNT_Delay==100-1) begin CNT_Delay<=0; oLED1<=1; Rd_Addr<=0; CNT_i<=CNT_i+1; end
						else begin CNT_Delay<=CNT_Delay+1; end
					end
				`else //IRCapture outputs Sample_Done 6 clocks, here we detect 3 clocks continusouly.
					if(iSample_Done) begin  
						if(CNT_Delay==3-1) begin CNT_Delay<=0; oLED1<=1; Rd_Addr<=0; CNT_i<=CNT_i+1; end
						else begin CNT_Delay<=CNT_Delay+1; end
					end
				`endif
				/////////////////////////////////////////////////////////
				//rowAddr<=1; colAddr<=0;  //read from Page1, bypass Page0.
				//rowAddr<=2; colAddr<=0;  //read from Page2.
				rowAddr<=194; colAddr<=0;  //read from Page194 to bypass Frame1.
			end
		6: //Prepare rising edge data. 
			if(CNT_Delay==6) begin CNT_Delay<=0; CNT_i<=CNT_i+1; end
			else begin
				CNT_Delay<=CNT_Delay+1;

				whichWr<=1; //select, 0:Data1 from IR(FPGA) for writing, 1:Data2 from me for reading.
				triState<=1; //Bidirectional control, 1=output direction, 0=input direction.
				triState_DQS_DM<=0; //Bidirectional control, 1=output direction, 0=input direction.
				oLED1<=1; Temp_DR<=0;

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
			begin wrData_ADQ<=DDR_RAM_Addr[31:24]; CNT_i<=CNT_i+1; end
		11: //Pull up CLK. (2nd Rising Edge)
			begin RAM_CLK_i<=1; CNT_i<=CNT_i+1; end
		12: //Prepare falling edge data. //iAddress[23:16]
			begin wrData_ADQ<=DDR_RAM_Addr[23:16]; CNT_i<=CNT_i+1; end
		13: //Pull down CLK. (2nd Falling Edge)
			begin RAM_CLK_i<=0; CNT_i<=CNT_i+1; end
/////////////////////////////////////////////////////////////////////////////////////////////////
		14: //prepare rising edge data. //iAddress[15:8]
			begin wrData_ADQ<=DDR_RAM_Addr[15:8]; CNT_i<=CNT_i+1; end
		15: //Pull up CLK. (3rd Rising Edge)
			begin RAM_CLK_i<=1; CNT_i<=CNT_i+1; end
		16: //Prepare data. //iAddress[7:0]
			begin wrData_ADQ<=DDR_RAM_Addr[7:0]; CNT_i<=CNT_i+1; end 
		17: //Pull down CLK. (3rd Falling Edge)  
			begin RAM_CLK_i<=0; CNT_i<=CNT_i+1; end //Latency=1.
//////////////////////////////////////////////////////////////////////////////////////////////////
		18: 
			begin 
				triState<=0; //Bidirectional control, 1=output direction, 0=input direction.
				Temp_DR<=0; Rd_Bytes<=0; Rd_Retry<=0; Rd_Data_Valid<=0; CNT_i<=CNT_i+1; 
			end
		19: //Pull up CLK. (Xth Rising Edge)
			begin RAM_CLK_i<=1; CNT_i<=CNT_i+1; end
		20: //APMemory datasheet shows tDQSCK(DQS output access time from CLK) is range from 2nS~6.5nS.
		//I can't adjust phase via set_input_delay, so I add an addtional clock to fix the 1st byte reading incorrect.
			begin CNT_i<=CNT_i+1; end
		21: //The 1st DQS/DM rising edge after read pre-amble indicates the beginning of valid data.
			begin //And I'm not sure DQS/DM rising edge will occur on rising or falling edge of clock. Therefore I check on both edges.
				`ifdef USING_MODELSIM
					if(1) begin 
						Rd_Data_Valid<=1; Temp_DR<={Temp_DR[151:0],ioPSRAM_ADQ}; Rd_Bytes<=Rd_Bytes+1; 
					end
				`else
					if(ioPSRAM_DQS_DM|Rd_Data_Valid) begin 
						Rd_Data_Valid<=1; Temp_DR<={Temp_DR[151:0],ioPSRAM_ADQ}; Rd_Bytes<=Rd_Bytes+1; 
					end
				`endif

				///////////////////////////////////////////////
				CNT_i<=CNT_i+1; 
			end
		22: //Pull down CLK. (Xth Falling Edge)
			begin RAM_CLK_i<=0; CNT_i<=CNT_i+1; end
		23: //The 1st DQS/DM rising edge after read pre-amble indicates the beginning of valid data. 
			begin //And I'm not sure DQS/DM rising edge will occur on rising or falling edge of clock. Therefore I check on both edges.
				`ifdef USING_MODELSIM
					if(1) begin 
						Rd_Data_Valid<=1; Temp_DR<={Temp_DR[151:0],ioPSRAM_ADQ}; Rd_Bytes<=Rd_Bytes+1; 
					end
				`else
					if(ioPSRAM_DQS_DM|Rd_Data_Valid) begin 
						Rd_Data_Valid<=1; Temp_DR<={Temp_DR[151:0],ioPSRAM_ADQ}; Rd_Bytes<=Rd_Bytes+1; 
					end
				`endif
				///////////////////////////////////////////////
				CNT_i<=CNT_i+1; 
			end
		24: //Waiting 10 clocks for DQS/DM, timeout to break.
			if(Rd_Data_Valid) begin //Sample data at rising & falling edge, so 10-clocks*2=20.
				if(Rd_Bytes>=20) begin CNT_i<=CNT_i+1; end
				else begin CNT_i<=CNT_i-5; end //continue to read.
			end
			else begin //According to the experiment consequence, DQS/DM isn't be pulled up at first reading.
			//so I retry 10 times, if still not get valid DQS/DM, then send fixed data to indicate failure.
				if(Rd_Retry==10) begin Rd_Retry<=0; Temp_DR<=96'hFF19AA89FF0604FF205524FF; CNT_i<=CNT_i+1; end //Failed this time!
				else begin Rd_Retry<=Rd_Retry+1; CNT_i<=CNT_i-5; end //Retry! 
			end
	//////////////////////////////////////////////////////////////////////////////////////////////////
		25: //pull up CE to end. Extend CE width to 6*clcoks.
			if(CNT_Delay==6) begin CNT_Delay<=0; RAM_CE_i<=1; CNT_i<=CNT_i+1; end
			else begin CNT_Delay<=CNT_Delay+1; end
////////////////////////////////////////////////////////////////////
		26: //Tx one byte. 20*8=160.
			if(UART_Tx_Done) begin UART_Tx_En<=0; CNT_i<=CNT_i+1; end
			else begin UART_Tx_En<=1; UART_Tx_DR<=Temp_DR[159:152]; end
		27: //Loop to Tx 10*2 times.
			if(CNT_Delay==20-1) begin CNT_Delay<=0; CNT_i<=CNT_i+1; end
			else begin CNT_Delay<=CNT_Delay+1; Temp_DR<={Temp_DR[151:0],8'd0}; CNT_i<=CNT_i-1; end
/////////////////////////////////////////////////////////////////////////////////
		28: //Waiting 100ms to launch next reading operation. //48MHz, hex(48000000)=0x2DC6C00
			if(CNT_Delay==32'hFFFF) begin CNT_Delay<=0; CNT_i<=CNT_i+1; end
			else begin CNT_Delay<=CNT_Delay+1; end
		29: 
			//Because maximum CE Low Width is 2uS. 
			//And now I measured with an oscilloscope, reading 10 bytes each time takes up 1.6uS.
			//so we repeat 1040Bytes/10Bytes=104 times.
			if(colAddr>=(1040-20)) begin 
				//if(rowAddr>=192) begin rowAddr<=0; colAddr<=0; oLED1<=0; CNT_i<=CNT_i+1; end
				//We write two frames into DDR-PSRAM, so here we also read two frames from DDR-PSRAM.
				//One frame is 192 lines, two frame is 192*2=384 lines.
				//(00000001~000000BF) => (1~191).
				if(rowAddr>=385) begin rowAddr<=0; colAddr<=0; oLED1<=0; CNT_i<=CNT_i+1; end
				else begin 
						rowAddr<=rowAddr+1; colAddr<=0; CNT_i<=6; //read next page.
					end
			end
			else begin 
					colAddr<=colAddr+20; //10 clocks we read 20 bytes in two edges.
					CNT_i<=6; //read next 20-Bytes within one page.
				end
/////////////////////////////////////////////////////////////////////////////////////////////////
		30: //After 10s to notify IRCapture to capture next frame.
			//48MHz, hex(48000000)=0x2DC6C00, // hex(48000000*10)=0x1C9C3800
			if(CNT_Delay==32'h1C9C3800) begin CNT_Delay<=0; CNT_i<=CNT_i+1; end
			else begin CNT_Delay<=CNT_Delay+1; end
		31: //output Upload_Done 6 clocks to ensure IR Image Sensor(FPGA) can capture it completely.
			if(CNT_Delay==6-1) begin CNT_Delay<=0; oUpload_Done<=0; CNT_i<=CNT_i+1; end
			else begin CNT_Delay<=CNT_Delay+1; oUpload_Done<=1; end
		32:
			begin oUpload_Done<=0; CNT_i<=0; end
	endcase
end
//////////////////////////////////////////////////////////////////
endmodule