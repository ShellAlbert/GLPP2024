`timescale 1ps/1ps

module ZOctalRAMOperator(
	input iClk,
	input iRst_N,
	//iOp_Code=0: Idle.
	//iOp_Code=1: Reset IC.
	//iOp_Code=2: Write Mode Register.
	//iOp_Code=3: Read Mode Register and write to EBR 4K.
	//iOp_Code=4: Sync Write, iAddress[31:0], iData[15:0].
	//iOp_Code=5: Sync Read, iAddress[31:0], oData[15:0].
	input [2:0] iOp_Code,
	output reg oOp_Done,

	//iOp_Code=4: Burst Write, Address[31:0], Data[15:0].
	input [31:0] iAddress,
	input [15:0] iData,
	output reg [15:0] oData,

	//Octal RAM/EEPROM Interface.
    output reg oPSRAM_RST, //RESET# : Input Reset signal, active low. 
    output reg oPSRAM_CE, //CE#: Input, Chip select, active low. When CE#=1, chip is in standby state. 
	//output oPSRAM_CLK,

	//DQS, IO.
	//DQ Strobe clock for DQ[7:0] during all reads.
	//Data mask for DQ[7:0] during memory writes.
	//DM is active HIGH, DM=1 means "do not write".
    inout ioPSRAM_DQS_DM,
    inout [7:0] ioPSRAM_DATA, //Address/Data bus [7:0].

	//Embedded Block RAM Interface.
	output reg oEBR_Wr_En,
	output reg [15:0] oEBR_Wr_Data,
	output reg [9:0] oEBR_Wr_Addr
);

//DQS Tri-State control.
//Data Mask for Wring(1: Not Write), Data Strobe for Reading(1: Data Valid).
reg oe_DQS_DM;
reg DQS_DM_Out;
wire DQS_DM_In;
// assign ioPSRAM_DQS_DM=(oe_DQS_DM)?(DQS_DM_Out):(1'bz);
// assign DQS_DM_In=ioPSRAM_DQS_DM;
BB_B bb_b_DQS (
  .T_N     (oe_DQS_DM),  // I,  from oe/tristate output to pad
  .I       (DQS_DM_Out),  // I,  from output register to pad
  .O       (DQS_DM_In),  // O,  from pad to input register input
  .B       (ioPSRAM_DQS_DM)   // IO, bidirectional pad
);

//Command List.
parameter CMD_SYNC_RD=8'h00;
parameter CMD_SYNC_WR=8'h80;
parameter CMD_LINEAR_BURST_RD=8'h20;
parameter CMD_LINEAR_BURST_WR=8'hA0;
parameter CMD_MODE_REG_RD=8'h40;
parameter CMD_MODE_REG_WR=8'hC0;
parameter CMD_GBL_RST=8'hFF;

//8-bits bus input DDR.
//PADDI(Pad In) => Split into => DI0(Rising Edge) & DI1(Falling Edge)
wire [7:0] DDR_Data_In_Rising;
wire [7:0] DDR_Data_In_Falling; 
genvar i1;
generate 
	for(i1=0; i1<=7; i1=i1+1) begin: gen_i1
		IOL_B #(.LATCHIN ("NONE_DDR")) 
		DDR_DataBusIn_IOL_B (
		  .PADDI  (ioPSRAM_DATA[i1]),  // I, DDR data input from pad.
		  .DO1    (1'b0),  // I, output data to pad at falling edge.
		  .DO0    (1'b0),  // I, output data to pad at rising edge.
		  //I enable clock always, so it encodes continously, its output changes until input changes.
		  .CE     (1'b1),  // I, clock enabled.
		  .IOLTO  (1'b1),  // I, from Fabric to OE/Tri-State Control, Active Low.
		  .HOLD   (1'b0),  // I
		  .INCLK  (iClk),  // I, clock for input DDR.
		  .OUTCLK (iClk),  // I, clock for output DDR.
		  .PADDO  (),  // O, DDR data output to pad.
		  .PADDT  (),  // O, tri-state control to pad.
		  .DI1    (DDR_Data_In_Falling[i1]),  // O, input data from pad at falling edge.
		  .DI0    (DDR_Data_In_Rising[i1])   // O, input data from pad at rising edge.
		);
	end
endgenerate

wire [7:0] oe2pad; //tri-state output enable to pad, driven by IOL_B primitive.
// wire [7:0] iPSRAM_DATA;
wire [7:0] oPSRAM_DATA;
// BB_B bb_b_Pad[7:0] (
//   .T_N     (oe2pad),  // I,  from oe/tristate output to pad
//   .I       (oPSRAM_DATA),  // I,  from output register to pad
//   .O       (iPSRAM_DATA),  // O,  from pad to input register input
//   .B       (ioPSRAM_DATA)   // IO, bidirectional pad
// );
//8-bits bus input DDR.
//DO0(Rising Edge) & DO1(Falling Edge) => Packed into => PADDO(Pad Out)
reg [7:0] DDR_Data_Out_Rising;
reg [7:0] DDR_Data_Out_Falling; 
reg fab2oe; //Tri-state Control, Active Low. from Fabric to OE/Tri-State Control.
genvar i2;
generate 
	for(i2=0;i2<=7;i2=i2+1) begin: gen_i2
		IOL_B #(.DDROUT ("YES")) 
		DDR_DataBusOut_IOL_B (
		.PADDI  (1'b0),  // I, DDR data input from pad.
		.DO1    (DDR_Data_Out_Falling[i2]),  // I, output data to pad at falling edge.
		.DO0    (DDR_Data_Out_Rising[i2]),  // I, output data to pad at rising edge.
		//I enable clock always, so it encodes continously, its output changes until input changes.
		.CE     (1'b1),  // I, clock enabled.
		.IOLTO  (fab2oe),  // I, from Fabric to OE/Tri-State Control, Active Low.
		.HOLD   (1'b0),  // I
		.INCLK  (iClk),  // I, clock for input DDR.
		.OUTCLK (iClk),  // I, clock for output DDR.
		.PADDO  (oPSRAM_DATA[i2]),  // O, DDR data output to pad.
		.PADDT  (oe2pad[i2]),  // O, tri-state control to pad.
		.DI1    (),  // O, input data from pad at falling edge.
		.DI0    ()   // O, input data from pad at rising edge.
		);
		assign ioPSRAM_DATA[i2]=(oe2pad[i2]==1)?(oPSRAM_DATA[i2]):(1'bz);
	end
endgenerate

//Octal RAM Configuration before using.
reg [7:0] cfg_No;
wire [7:0] cfg_RegAddr;
wire [7:0] cfg_RegData;
ZOctalRAMCfg ic_cfg(
    .iNo(cfg_No),
    .oRegAddr(cfg_RegAddr),
    .oRegData(cfg_RegData)
);
//driven by counter.
reg [15:0] CNT1;
reg [15:0] CNT2;
reg [15:0] Temp_DR; //Temporary Data Register.
/////////////////////////////////////////////////////
always @(posedge iClk or negedge iRst_N)
if(!iRst_N) begin
				CNT1<=0; CNT2<=0; Temp_DR<=0;
				oOp_Done<=0; cfg_No<=0;
				//From fabric to oe/tri-state control, active low.
				fab2oe<=0;

				//DQS Tri-State control.
				//Data Mask for Wring(1: Not Write), Data Strobe for Reading(1: Data Valid).
				oe_DQS_DM<=1; DQS_DM_Out<=0; 
				DDR_Data_Out_Rising<=0; DDR_Data_Out_Falling<=0;
				oPSRAM_CE<=1; oPSRAM_RST<=1;

				//EBR 4K Interface.
				oEBR_Wr_En<=0; oEBR_Wr_Data<=0; oEBR_Wr_Addr<=0;
			end
else begin
		case (iOp_Code)
			1: //iOp_Code=1: Reset IC, RESET# Timing. Takes up EBR Address Range: 0~5.
				case(CNT1)
					0: //At default, CE=1, RST=1.
						begin oPSRAM_CE<=1; oPSRAM_RST<=1; CNT1<=CNT1+1; end
					1: //Device Initialization, tPU>150uS.
					//Wait for OctalRAM to be stable after power on.
					//f=100MHz, t=1/100MHz(s)=1000/100MHz(ms)=1000_000/100MHz(us)=10uS
					//Here we wait 2 times of tPU, 300uS/10uS=30.
						if(CNT2==100) begin CNT2<=0; CNT1<=CNT1+1; end
						else begin CNT2<=CNT2+1; end
					2:  //pull down RST while CE=1, tRP>1uS,
						begin oPSRAM_RST<=0; CNT1<=CNT1+1; end
					3: //pull up RST, tRST>=2uS, Reset to CMD valid.
						begin oPSRAM_RST<=1; CNT1<=CNT1+1; end
					4: //Write Fixed Bytes to EBR to verify its correction.
						begin oEBR_Wr_En<=1; oEBR_Wr_Data<=16'h1987; oEBR_Wr_Addr<=0; CNT1<=CNT1+1; end
					5: 
						begin oEBR_Wr_En<=1; oEBR_Wr_Data<=16'h0901; oEBR_Wr_Addr<=1; CNT1<=CNT1+1; end
					6:
						begin oEBR_Wr_En<=1; oEBR_Wr_Data<=16'h2016; oEBR_Wr_Addr<=2; CNT1<=CNT1+1; end
					7: 
						begin oEBR_Wr_En<=1; oEBR_Wr_Data<=16'h0323; oEBR_Wr_Addr<=3; CNT1<=CNT1+1; end
					8: 
						begin oEBR_Wr_En<=1; oEBR_Wr_Data<=16'h1986; oEBR_Wr_Addr<=4; CNT1<=CNT1+1; end
					9:  
						begin oEBR_Wr_En<=1; oEBR_Wr_Data<=16'h1014; oEBR_Wr_Addr<=5; CNT1<=CNT1+1; end	
					10:
						begin oEBR_Wr_En<=0; CNT1<=CNT1+1; end
					11: //generate done signal, single pulse.
						begin oOp_Done<=1; CNT1<=CNT1+1; end
					12: //generate done signal, single pulse.
						begin oOp_Done<=0; CNT1<=0; end
					default:
						begin oOp_Done<=0; CNT1<=0; end
				endcase
			2: //iOp_Code=2: Write Mode Register.
				case(CNT1)
					0: //Prepare rising edge data before 1 clock.
						begin
							fab2oe<=1; //fabric to oe/tri-state control, tri-state enabled, output.
							DDR_Data_Out_Rising<=CMD_MODE_REG_WR; //1st clock rising edge data.
							CNT1<=CNT1+1; 
						end
					1: //1st Clock to issue INST. 8'h01(rising)+8'h02(falling)
						begin
							oPSRAM_CE<=0; //Pull down CE to start.
							DDR_Data_Out_Falling<=CMD_MODE_REG_WR; //1st clock falling edge data.
							DDR_Data_Out_Rising<=8'h00;  //2nd clock rising edge data.
							CNT1<=CNT1+1; 
						end
					2: //2nd Clock, don't care.
						begin 
							DDR_Data_Out_Falling<=8'h00; //2nd clock falling edge data.
							DDR_Data_Out_Rising<=0; //3rd clock rising edge data.
							CNT1<=CNT1+1; 
						end
					3: //3rd Clock to issue MA#(ModeRegisterAddress) at falling edge.
						begin
							DDR_Data_Out_Falling<=cfg_RegAddr; //3rd clock falling edge data.
							DDR_Data_Out_Rising<=cfg_RegData; //4th clock rising edge data.
							CNT1<=CNT1+1; 
						end
					4: //4th Clock to issue MR#(ModeRegisterData) at rising edge, Latency=1.
						begin 
							DDR_Data_Out_Falling<=0; //4th clock falling edge data.
							DDR_Data_Out_Rising<=0;
							CNT1<=CNT1+1; 
						end
					5: //pull up CE to end.
						begin oPSRAM_CE<=1; CNT1<=CNT1+1; end

					6: //Loop to write all mode registers.
						if(cfg_No==3) begin CNT1<=CNT1+1; end
						else begin cfg_No<=cfg_No+1; CNT1<=0; end
					7: //generate one single pulse done signal.
						begin oOp_Done<=1; CNT1<=CNT1+1; end
					8: //generate one single pulse done signal.
						begin oOp_Done<=0; CNT1<=0; end
					default:
						begin CNT1<=0; end
				endcase
			3: //iOp_Code=3: Read Mode Register and write to EBR. //Read Latency=5. Takes up EBR Address Range:6~11.
				case(CNT1)
					0: //Initial relevant registers.
						begin 
							oe_DQS_DM<=0; //High-Z, Input direction. 
							cfg_No<=4; //pre-setting read mode register address.
							CNT1<=CNT1+1; 
						end
					1: //Prepare rising edge data before 1 clock.
						begin
							fab2oe<=1; //fabric to oe/tri-state control, tri-state enabled, output.
							DDR_Data_Out_Rising<=CMD_MODE_REG_RD; //1st clock rising edge data.
							CNT1<=CNT1+1; 
						end
					2: //1st Clock to issue INST.
						begin
							oPSRAM_CE<=0; //Pull down CE to start.
							DDR_Data_Out_Falling<=CMD_MODE_REG_RD; //1st clock falling edge data.
							DDR_Data_Out_Rising<=0;  //2nd clock rising edge data.
							CNT1<=CNT1+1; 
						end
					3: //2nd Clock, ignore.
						begin 
							DDR_Data_Out_Falling<=0; //2nd clock falling edge data.
							DDR_Data_Out_Rising<=0; //3rd clock rising edge data.
							CNT1<=CNT1+1; 
						end
					4: //3rd Clock to issue MA#(ModeRegisterAddress) at falling edge, Latency=1.
						begin
							DDR_Data_Out_Falling<=cfg_RegAddr; //3rd clock falling edge data.
							//fabric to oe/tri-state control, tri-state disabled, input.
							CNT1<=CNT1+1; 
						end
					5: 
						begin fab2oe<=0; CNT1<=CNT1+1; end //Latency=2.
					6: 
						begin CNT1<=CNT1+1; end //Latency=3.
					7: 
						begin CNT1<=CNT1+1; end //Latency=4.
					8: 
						begin CNT1<=CNT1+1; end //Latency=5.
					9: 
						begin 
							oEBR_Wr_Data<={DDR_Data_In_Rising, DDR_Data_In_Falling}; CNT1<=CNT1+1; 
						end //Latency=6.
					
					10:	//Latency=7. //Sample D0 at Rising Edge, Sample D1 at Falling Edge.
						begin
							//oEBR_Wr_En<=1; oEBR_Wr_Addr<=oEBR_Wr_Addr+1; oEBR_Wr_Data<=Temp_DR;
							CNT1<=CNT1+1; 
						end
					/*
					11: //Rising Edge data is D1.
						begin
							oEBR_Wr_En<=1; oEBR_Wr_Addr<=oEBR_Wr_Addr+1; oEBR_Wr_Data<=Temp_DR;
							Temp_DR<={DDR_Data_In_Rising, DDR_Data_In_Falling}; //Leading with 0x55 to recognize easily.
							CNT1<=CNT1+1; 
						end
					12: //Rising Edge data is D1.
						begin
							oEBR_Wr_En<=1; oEBR_Wr_Addr<=oEBR_Wr_Addr+1; oEBR_Wr_Data<=Temp_DR;
							Temp_DR<={DDR_Data_In_Rising, DDR_Data_In_Falling}; //Leading with 0x55 to recognize easily.
							CNT1<=CNT1+1; 
						end
					*/
					11: //pull up CE to end.
						begin oPSRAM_CE<=1; oEBR_Wr_En<=0; CNT1<=CNT1+1; end

					12: //Loop to read all mode registers.
						if(cfg_No==9) begin cfg_No<=0; CNT1<=CNT1+1; end
						else begin cfg_No<=cfg_No+1; CNT1<=1; end

					13: //generate one single pulse done signal.
						begin oOp_Done<=1; CNT1<=CNT1+1; end
					14: //generate one single pulse done signal.
						begin oOp_Done<=0; CNT1<=0; end
					default:
						begin CNT1<=0; end
				endcase
			default:
				begin oOp_Done<=0; CNT1<=0; end
		endcase
end
endmodule
