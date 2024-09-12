`timescale 1ps/1ps

module ZOctalRAMOperator(
	input iClk,
	input iClk_LocalFabric,
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
	output wire oPSRAM_CLK,
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

assign oPSRAM_CLK=iClk_LocalFabric;

reg oPSRAM_CLK;
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

//bidirectional IO.
reg oe_PSRAM_DATA;
wire [7:0] iPSRAM_DATA;
reg [7:0] oPSRAM_DATA;
assign ioPSRAM_DATA=(oe_PSRAM_DATA)?(oPSRAM_DATA):(8'bzzzzzzzz);
assign iPSRAM_DATA=ioPSRAM_DATA;

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
always @(posedge iClk or negedge iRst_N)
if(!iRst_N) begin
				CNT1<=0; CNT2<=0;
				oOp_Done<=0; 
				oPSRAM_CLK<=0; //We drive PSRAM_CLK by manual.
				oPSRAM_CE<=1; oPSRAM_RST<=1;
				cfg_No<=0;
				//DQS Tri-State control.
				//Data Mask for Wring(1: Not Write), Data Strobe for Reading(1: Data Valid).
				oe_DQS_DM<=1; DQS_DM_Out<=0; 
				//EBR 4K Interface.
				oEBR_Wr_En<=0;
				oEBR_Wr_Data<=0;
				oEBR_Wr_Addr<=0;
			end
else begin
		case (iOp_Code)
			1: //iOp_Code=1: Reset IC, RESET# Timing.
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
					4: //generate done signal, single pulse.
						begin oOp_Done<=1; CNT1<=CNT1+1; end
					5: //generate done signal, single pulse.
						begin oOp_Done<=0; CNT1<=0; end
				endcase
			2: //iOp_Code=2: Write Mode Register.
				case(CNT1)
					0: //Pull down CLK.
						begin oPSRAM_CLK<=0; CNT1<=CNT1+1; end
					1: //Prepare rising edge data.
						begin
							oPSRAM_CE<=0; //Pull down CE to start.
							//output data.
							oe_PSRAM_DATA<=1; oPSRAM_DATA<=CMD_MODE_REG_WR;
							CNT1<=CNT1+1; 
						end
					2: //Pull up CLK. (1st Rising Edge)
						begin oPSRAM_CLK<=1; CNT1<=CNT1+1; end
					3: //Prepare falling edge data.
						begin 
							oPSRAM_DATA<=CMD_MODE_REG_WR;
							CNT1<=CNT1+1; 
						end
					4: //Pull down CLK. (1st Falling Edge)
						begin oPSRAM_CLK<=0; CNT1<=CNT1+1; end

					5: //Pull up CLK. (2nd Rising Edge)
						begin oPSRAM_CLK<=1; CNT1<=CNT1+1; end
					6: //Pull down CLK. (2nd Falling Edge)
						begin oPSRAM_CLK<=0; CNT1<=CNT1+1; end

					7: //Pull up CLK. (3rd Rising Edge)
						begin oPSRAM_CLK<=1; CNT1<=CNT1+1; end
					8: //Prepare data.
						begin oPSRAM_DATA<=cfg_RegAddr; CNT1<=CNT1+1; end 
					9: //Pull down CLK. (3rd Falling Edge)
						begin oPSRAM_CLK<=0; CNT1<=CNT1+1; end

					10: //Prepare data.
						begin oPSRAM_DATA<=cfg_RegData; CNT1<=CNT1+1; end 
					11: //Pull up CLK. (4th Rising Edge).
						begin oPSRAM_CLK<=1; CNT1<=CNT1+1; end
					12: //Pull down CLK. (4th Falling Edge)
						begin oPSRAM_CLK<=0; CNT1<=CNT1+1; end

					13: //pull up CE to end.
						begin oPSRAM_CE<=1; CNT1<=CNT1+1; end

					14: //Loop to write all mode registers.
						if(cfg_No==3) begin CNT1<=CNT1+1; end
						else begin cfg_No<=cfg_No+1; CNT1<=0; end
					15: //generate one single pulse done signal.
						begin oOp_Done<=1; CNT1<=CNT1+1; end
					16: //generate one single pulse done signal.
						begin oOp_Done<=0; CNT1<=0; end
					default:
						begin CNT1<=0; end
				endcase
			3: //iOp_Code=3: Read Mode Register and write to EBR 4K.
				case(CNT1)
					0: 
						begin cfg_No<=4; oEBR_Wr_Addr<=0; CNT1<=CNT1+1; end
					1: //Pull down CLK.
						begin oPSRAM_CLK<=0; CNT1<=CNT1+1; end
					2: //Prepare rising edge data.
						begin
							oPSRAM_CE<=0; //Pull down CE to start.
							//output data.
							oe_PSRAM_DATA<=1; oPSRAM_DATA<=CMD_MODE_REG_RD;
							CNT1<=CNT1+1; 
						end
					3: //Pull up CLK. (1st Rising Edge)
						begin oPSRAM_CLK<=1; CNT1<=CNT1+1; end
					4: //Prepare falling edge data.
						begin 
							oPSRAM_DATA<=CMD_MODE_REG_RD;
							CNT1<=CNT1+1; 
						end
					5: //Pull down CLK. (1st Falling Edge)
						begin oPSRAM_CLK<=0; CNT1<=CNT1+1; end

					6: //Pull up CLK. (2nd Rising Edge)
						begin oPSRAM_CLK<=1; CNT1<=CNT1+1; end
					7: //Pull down CLK. (2nd Falling Edge)
						begin oPSRAM_CLK<=0; CNT1<=CNT1+1; end

					8: //Pull up CLK. (3rd Rising Edge)
						begin oPSRAM_CLK<=1; CNT1<=CNT1+1; end
					9: //Prepare data.
						begin oPSRAM_DATA<=cfg_RegAddr; CNT1<=CNT1+1; end 
					10: //Pull down CLK. (3rd Falling Edge)  
						begin oPSRAM_CLK<=0; CNT1<=CNT1+1; end //Latency=1.
					
					11: //Pull up CLK. (Xth Rising Edge)
						begin oPSRAM_CLK<=1; CNT1<=CNT1+1; end
					12: //Pull down CLK. (Xth Falling Edge)
						begin oPSRAM_CLK<=0; oe_PSRAM_DATA<=0; CNT1<=CNT1+1; end //Latency=2.
					13: //Pull up CLK. (Xth Rising Edge)
						begin oPSRAM_CLK<=1; CNT1<=CNT1+1; end
					14: //Pull down CLK. (Xth Falling Edge)
						begin oPSRAM_CLK<=0; CNT1<=CNT1+1; end //Latency=3.
					15: //Pull up CLK. (Xth Rising Edge)
						begin oPSRAM_CLK<=1; CNT1<=CNT1+1; end
					16: //Pull down CLK. (Xth Falling Edge)
						begin oPSRAM_CLK<=0; CNT1<=CNT1+1; end //Latency=4.
					17: //Pull up CLK. (Xth Rising Edge)
						begin oPSRAM_CLK<=1; CNT1<=CNT1+1; end
					18: //Pull down CLK. (Xth Falling Edge)
						begin oPSRAM_CLK<=0; CNT1<=CNT1+1; end //Latency=5.
////////////////////////////////////////////////////////////////////////////
					19: //Pull up CLK. (Xth Rising Edge)
						begin oPSRAM_CLK<=1; CNT1<=CNT1+1; end
					20: //Pull down CLK. (Xth Falling Edge)
						begin oPSRAM_CLK<=0; CNT1<=CNT1+1; end 
////////////////////////////////////////////////////////////////////////////////
					21: //Pull up CLK. (Xth Rising Edge)
						begin oPSRAM_CLK<=1; CNT1<=CNT1+1; end
					22: //Sample D1 at Rising Edge.
						begin Temp_DR[15:8]<=iPSRAM_DATA; CNT1<=CNT1+1; end 
					23: //Pull down CLK. (Xth Falling Edge)
						begin oPSRAM_CLK<=0; CNT1<=CNT1+1; end 
					24: //Sample D0 at Falling Edge.
						begin Temp_DR[7:0]<=iPSRAM_DATA; CNT1<=CNT1+1; end 
/////////////////////////////////////////////////////////////////////////////////
					25:	//write data to EBR.
						begin oEBR_Wr_En<=1; oEBR_Wr_Data<=Temp_DR;	CNT1<=CNT1+1; end
					26: //pull up CE to end.
						begin oPSRAM_CE<=1; oEBR_Wr_En<=0; CNT1<=CNT1+1; end

					27: //Loop to read all mode registers.
						if(cfg_No==9) begin cfg_No<=0; CNT1<=CNT1+1; end
						else begin cfg_No<=cfg_No+1; oEBR_Wr_Addr<=oEBR_Wr_Addr+1; CNT1<=1; end

					28: //generate one single pulse done signal.
						begin oOp_Done<=1; CNT1<=CNT1+1; end
					29: //generate one single pulse done signal.
						begin oOp_Done<=0; CNT1<=0; end
					default:
						begin CNT1<=0; end
				endcase
		endcase

	end

endmodule
