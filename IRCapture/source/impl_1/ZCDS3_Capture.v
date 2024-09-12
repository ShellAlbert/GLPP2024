`timescale 1ps/1ps
`include "ZPortableDefine.v"
module ZCDS3_Capture(
    input iClk,
    input iRst_N,
    input iEn,

    //input signals.
    input iIR_PCLK,
    input [7:0] iIR_Data,

    //Interfactive signals.
	output reg oWr_Req, //Write Request for HyperRAM.
	output reg oWr_Done, //Write Done for HyperRAM.

	//HyperRAM write interface.
	output reg oRAM_CLK,
	output reg oRAM_RST,
	output reg oRAM_CE,
	output reg oRAM_DQS,
	output reg [7:0] oRAM_ADQ,

    //Capture one frame done?
    output reg oFrame_Done
);

//Delay 2 clocks to sync to main clock.
reg [1:0] IR_PCLK_Delay;
reg [1:0] IR_Data0;
reg [1:0] IR_Data1;
reg [1:0] IR_Data2;
reg [1:0] IR_Data3;
reg [1:0] IR_Data4;
reg [1:0] IR_Data5;
reg [1:0] IR_Data6;
reg [1:0] IR_Data7;
always @(posedge iClk or negedge iRst_N) 
if(!iRst_N) begin
    IR_PCLK_Delay<=2'b00;
    IR_Data0<=2'b00;
    IR_Data1<=2'b00;
    IR_Data2<=2'b00;
    IR_Data3<=2'b00;
    IR_Data4<=2'b00;
    IR_Data5<=2'b00;
    IR_Data6<=2'b00;
    IR_Data7<=2'b00;
end
else begin
    IR_PCLK_Delay<={IR_PCLK_Delay[0], iIR_PCLK};
    IR_Data0<={IR_Data0[0], iIR_Data[0]};
    IR_Data1<={IR_Data1[0], iIR_Data[1]};
    IR_Data2<={IR_Data2[0], iIR_Data[2]};
    IR_Data3<={IR_Data3[0], iIR_Data[3]};
    IR_Data4<={IR_Data4[0], iIR_Data[4]};
    IR_Data5<={IR_Data5[0], iIR_Data[5]};
    IR_Data6<={IR_Data6[0], iIR_Data[6]};
    IR_Data7<={IR_Data7[0], iIR_Data[7]};
end
wire IR_CLK_Rising_Edge;
wire IR_CLK_Falling_Edge;
assign IR_CLK_Rising_Edge=(!IR_PCLK_Delay[1]) & IR_PCLK_Delay[0];
assign IR_CLK_Falling_Edge=(IR_PCLK_Delay[1]) & !IR_PCLK_Delay[0];

//Command List.
parameter CMD_SYNC_RD=8'h00;
parameter CMD_SYNC_WR=8'h80;
parameter CMD_LINEAR_BURST_RD=8'h20;
parameter CMD_LINEAR_BURST_WR=8'hA0;
parameter CMD_MODE_REG_RD=8'h40;
parameter CMD_MODE_REG_WR=8'hC0;
parameter CMD_GBL_RST=8'hFF;
//Octal RAM Configuration before using.
reg [7:0] cfg_No;
wire [7:0] cfg_RegAddr;
wire [7:0] cfg_RegData;
ZOctalRAMCfg ic_cfg(
    .iNo(cfg_No),
    .oRegAddr(cfg_RegAddr),
    .oRegData(cfg_RegData)
);

//We sample data at middle point to get a stable value.
//Main clock is 48MHz, PCLK is 9.375MHz, the ratio is 48MHz/9.375MHz=5.12
//In order to get a stable value, we sample at the middle point.
//Here, we choose 2 as the middle point.
reg [7:0] CNT_Step;
reg [7:0] CNT_SubStep;
reg [31:0] CNT_Delay;
reg [7:0] CNT_Repeat;
reg [7:0] Rx_DR0; //Receive Data Registers.
reg [7:0] Rx_DR1;
reg [7:0] Rx_DR2;
reg [7:0] Rx_DR3;
reg [15:0] CNT_Bytes; //one line contains 256*2 bytes pixel data and 256*2 bytes temperature data, 1024 bytes totally.
reg [7:0] CNT_Lines; //one frame contains 192 lines.
reg [95:0] HyperRAM_Fixed_Data; //'h198709011986101420160323 (12bytes in total, 12*8=96bits)
always @(posedge iClk or negedge iRst_N)
if(!iRst_N) begin
    CNT_Step<=0; CNT_SubStep<=0; CNT_Delay<=0; CNT_Repeat<=0;
    cfg_No<=0;
    oRAM_CLK<=0; oRAM_RST<=1; oRAM_CE<=1; oRAM_DQS<=0; oRAM_ADQ<=0;
    //Initial Receive Data Registers.
    Rx_DR3<=0; Rx_DR2<=0; Rx_DR1<=0; Rx_DR0<=0;

    oWr_Req<=0; oWr_Done<=0;
    CNT_Bytes<=0; CNT_Lines<=0; oFrame_Done<=0;
end
else begin
    if(iEn) begin 
            case(CNT_Step)
                0: //Because IRRoute FPGA delays 10s to wait for IR Image Sensor starts up. 
                //So here we delay 15s to ensure it can receive WrReq Signal. //66MHz=32'h3EF1480
                    `ifdef USING_MODELSIM //Delay less time in ModelSim.
                        if(CNT_Delay==2) begin CNT_Delay<=0; CNT_Step<=CNT_Step+1; end
                        else begin CNT_Delay<=CNT_Delay+1; end
                    `else //Delay long time in Lattice Radiant.
                        if(CNT_Delay==32'h3EF1480) begin CNT_Delay<=0; CNT_Step<=CNT_Step+1; end
                        else begin CNT_Delay<=CNT_Delay+1; end
                    `endif
                1: //1second *10 times = 10 seconds.
                    if(CNT_Repeat==2-1) begin CNT_Repeat<=0; CNT_Step<=CNT_Step+1; end
                    else begin CNT_Repeat<=CNT_Repeat+1; CNT_Step<=CNT_Step-1; end
/////////////////////////////////////////////////////////////////////////////////////////////
                2: //Write Request for HyperRAM.
                    begin oWr_Req<=1; CNT_Step<=CNT_Step+1; end
                3: //Expand signal width to x6 clocks period to ensure to be captured by Another FPGA. //48MHz=32'h2DC6C00
                    if(CNT_Delay==6) begin CNT_Delay<=0; oWr_Req<=0; CNT_Step<=CNT_Step+1; end //Enable this line in Radiant.
                    //if(CNT_Delay==10) begin CNT_Delay<=0; oWr_Req<=0; CNT_Step<=CNT_Step+1; end//Enable this line in ModelSim.
                    else begin CNT_Delay<=CNT_Delay+1; end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
                4: //HyperRAM: Reset.
                    case(CNT_SubStep)
                        0: //At default, CE=1, RST=1.
                            begin oRAM_CE<=1; oRAM_RST<=1; CNT_SubStep<=CNT_SubStep+1; end
                        1: //Device Initialization, tPU>150uS.
                        //Wait for OctalRAM to be stable after power on.
                        //f=100MHz, t=1/100MHz(s)=1000/100MHz(ms)=1000_000/100MHz(us)=10uS
                        //Here we wait 2 times of tPU, 300uS/10uS=30.
                            if(CNT_Delay==100) begin CNT_Delay<=0; CNT_SubStep<=CNT_SubStep+1; end
                            else begin CNT_Delay<=CNT_Delay+1; end
                        2:  //pull down RST while CE=1, tRP>1uS,
                            begin oRAM_RST<=0; CNT_SubStep<=CNT_SubStep+1; end
                        3: //pull up RST, tRST>=2uS, Reset to CMD valid.
                            begin oRAM_RST<=1; CNT_SubStep<=CNT_SubStep+1; end
                        4: //After reset, delay for a while for later operations.
                            if(CNT_Delay==100) begin CNT_Delay<=0; CNT_SubStep<=CNT_SubStep+1; end
                                else begin CNT_Delay<=CNT_Delay+1; end
                        5:
                            begin 
                                CNT_SubStep<=0; CNT_Step<=CNT_Step+1; 
                                cfg_No<=0; //Necessary, Initial value before next step.
                            end
                    endcase
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                5: //HyperRAM: Write Mode Registers.
                    case(CNT_SubStep)
                        0: //Pull down CLK.
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
                        1: //Prepare rising edge data.
                            begin
                                oRAM_CE<=0; //Pull down CE to start.
                                oRAM_DQS<=0; oRAM_ADQ<=CMD_MODE_REG_WR; CNT_SubStep<=CNT_SubStep+1;  //output data.
                            end
                        2: //Pull up CLK. (1st Rising Edge)
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        3: //Prepare falling edge data.
                            begin oRAM_ADQ<=CMD_MODE_REG_WR; CNT_SubStep<=CNT_SubStep+1; end
                        4: //Pull down CLK. (1st Falling Edge)
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
////////////////////////////////////////////////////////////////////////////////////////////////////
                        5: //Pull up CLK. (2nd Rising Edge)
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        6: //Pull down CLK. (2nd Falling Edge)
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end                           
//////////////////////////////////////////////////////////////////////////////////////////
                        7: //Pull up CLK. (3rd Rising Edge)
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        8: //Prepare data.
                            begin oRAM_ADQ<=cfg_RegAddr; CNT_SubStep<=CNT_SubStep+1;end 
                        9: //Pull down CLK. (3rd Falling Edge)
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
//////////////////////////////////////////////////////////////////////////////////////
                        10: //Prepare data.
                            begin oRAM_ADQ<=cfg_RegData; CNT_SubStep<=CNT_SubStep+1;end 
                        11: //Pull up CLK. (4th Rising Edge).
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        12: //Pull down CLK. (4th Falling Edge)
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
/////////////////////////////////////////////////////////////////////////
                        13: //pull up CE to end.
                            begin oRAM_CE<=1; CNT_SubStep<=CNT_SubStep+1;end

                        14: //Must keep minimum 3 clocks after next CE.
                            if(CNT_Delay==6) begin CNT_Delay<=0; CNT_SubStep<=CNT_SubStep+1; end
                            else begin CNT_Delay<=CNT_Delay+1; end
                        15: //Loop to write all mode registers.
                            if(cfg_No==3) begin CNT_SubStep<=CNT_SubStep+1; end
                            else begin cfg_No<=cfg_No+1; CNT_SubStep<=0; end
                        16: 
                            begin CNT_SubStep<=0; CNT_Step<=CNT_Step+1; end
                    endcase        
//////////////////////////////////////////////////////////////////////////////////////////////
                6: //Prepare burst write. //Write Latency=5.
                    case(CNT_SubStep)
                        0: //Pull down CLK.
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
                        1: //Prepare rising edge data.
                            begin
                                oRAM_CE<=0; //Pull down CE to start.
                                oRAM_DQS<=0; oRAM_ADQ<=CMD_LINEAR_BURST_WR; CNT_SubStep<=CNT_SubStep+1; //output data.
                            end
    //////////////////////////////////////////////////////////////////////////
                        2: //Pull up CLK. (1st Rising Edge)
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        3: //Prepare falling edge data.
                            begin oRAM_ADQ<=CMD_LINEAR_BURST_WR; CNT_SubStep<=CNT_SubStep+1; end
                        4: //Pull down CLK. (1st Falling Edge)
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end 
    //////////////////////////////////////////////////////////////////////////////////////////
                        5: //prepare rising edge data. /////////////iAddress[31:24]=0.
                            begin oRAM_ADQ<=0; CNT_SubStep<=CNT_SubStep+1; end 
                        6: //Pull up CLK. (2nd Rising Edge)
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        7: //Prepare falling edge data. ////////////iAddress[23:16]=0.
                            begin oRAM_ADQ<=0; CNT_SubStep<=CNT_SubStep+1; end
                        8: //Pull down CLK. (2nd Falling Edge)
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
    ////////////////////////////////////////////////////////////////////////////////////////////
                        9: //prepare rising edge data. //////////////iAddress[15:8]=0.
                            begin oRAM_ADQ<=0; CNT_SubStep<=CNT_SubStep+1; end
                        10: //Pull up CLK. (3rd Rising Edge)
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        11: //Prepare falling edge data. ////////////iAddress[7:0]=0.
                            begin oRAM_ADQ<=0; CNT_SubStep<=CNT_SubStep+1; end 
                        12: //Pull down CLK. (3rd Falling Edge)
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end   //Latency=1.
    //////////////////////////////////////////////////////////////////////////////
                        13: //Latency=2.
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        14:
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
    ///////////////////////////////////////////////////////////////////////////
                        15: //Latency=3.
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        16:
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
    ///////////////////////////////////////////////////////////////////////////
                        17: //Latency=4.
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        18:
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
    ///////////////////////////////////////////////////////////////////////////
                        19: //Latency=5.
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        20:
                            begin oRAM_CLK<=0; HyperRAM_Fixed_Data<=96'h090110140323871986191620; CNT_SubStep<=CNT_SubStep+1; end
    /////////////////////////////////////////////////////////////////////////////////////
                        21: //We Write Fixed Data to HyperRAM so the reader can verity if it reads correctly.
                            begin oRAM_ADQ<=HyperRAM_Fixed_Data[95:88];CNT_SubStep<=CNT_SubStep+1; end //ADQ[x]=1.
                        22: //Generate Rising Edge.
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        23:
                            begin oRAM_ADQ<=HyperRAM_Fixed_Data[87:80]; CNT_SubStep<=CNT_SubStep+1; end //ADQ[x]=0.
                        24: //Generate Falling Edge.
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
                        25:
                            if(CNT_Delay==9-1) begin CNT_Delay<=0; CNT_SubStep<=CNT_SubStep+1; end
                            else begin 
                                    CNT_Delay<=CNT_Delay+1; 
                                    HyperRAM_Fixed_Data<={HyperRAM_Fixed_Data[79:0],16'd0}; 
                                    CNT_SubStep<=CNT_SubStep-4; 
                            end
//////////////////////////////////////////////////////////////////////////////////////////////////

                        26:
                            //begin CNT_SubStep<=0; CNT_Step<=CNT_Step+1; end
                            begin CNT_SubStep<=0; CNT_Step<=14; end
                    endcase
////////////////////////////////////////////////////////////////////////////////
                7: //Waiting Rising Edge. (1st Clock)
                    `ifdef USING_MODELSIM
                        if(1) begin CNT_Step<=CNT_Step+1; end //Enable this line in ModelSim.
                    `else
                        if(IR_CLK_Rising_Edge) begin CNT_Step<=CNT_Step+1; end //Enable this line in Radiant.
                    `endif
                8: //Sample at middle point. (2st Clock)
                    begin
                        Rx_DR3<=Rx_DR2; Rx_DR2<=Rx_DR1; Rx_DR1<=Rx_DR0;
                        Rx_DR0<={IR_Data7[1],IR_Data6[1],IR_Data5[1],IR_Data4[1],IR_Data3[1],IR_Data2[1],IR_Data1[1],IR_Data0[1]};
                        CNT_Step<=CNT_Step+1; 
                    end
                9: //Checking until we get FF 00 00 80 sync header bytes. (3rd Clock)
                    `ifdef USING_MODELSIM //Enable this line in ModelSim.
                        if(1) begin CNT_Step<=CNT_Step+1; end 
                    `else //Enable this line in Radiant.
                        if(Rx_DR3==8'hFF && Rx_DR2==8'h00 && Rx_DR1==8'h00 && Rx_DR0==8'h80) begin CNT_Step<=CNT_Step+1; end
                        else begin CNT_Step<=CNT_Step-2; end//Continue to check.
                    `endif
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                10: //Already got FF 00 00 80 sync header bytes. (1st Clock)
                    `ifdef USING_MODELSIM //Enable this line in ModelSim.
                        if(1) begin CNT_Step<=CNT_Step+1; end 
                    `else //Enable this line in Radiant.
                        if(IR_CLK_Rising_Edge) begin CNT_Step<=CNT_Step+1; end 
                    `endif
                11: //Sample at middle point and Save Image&Temperature data. (2nd Clock)
                    begin
                        //Prepare Rising Edge Data.
                        oRAM_ADQ<={IR_Data7[1],IR_Data6[1],IR_Data5[1],IR_Data4[1],IR_Data3[1],IR_Data2[1],IR_Data1[1],IR_Data0[1]};
                        CNT_Bytes<=CNT_Bytes+1;
                        CNT_Step<=CNT_Step+1; 
                    end
                12: //Generate Rising Edge. (3rd Clock)
                    begin oRAM_CLK<=1; CNT_Step<=CNT_Step+1; end
                13: //Generate Falling Edge. (4th Clock)
                    begin 
                        oRAM_CLK<=0; 
                        if(CNT_Bytes==1024-1) begin
                            CNT_Bytes<=0;
                            //one frame contains 192 lines, check if we received 192 lines.
                            if(CNT_Lines==192-1) begin CNT_Lines<=0; CNT_Step<=CNT_Step+1; end //Next Frame.
                            else begin CNT_Lines<=CNT_Lines+1; CNT_Step<=7; end //Next Line.
                        end
                        else begin 
                            CNT_Bytes<=CNT_Bytes+1; CNT_Step<=10; //Next byte within one line.
                        end
                    end
                14: //pull up CE to end.
                    begin oRAM_CE<=1; CNT_Step<=CNT_Step+1;end
////////////////////////////////////////////////////////////////////////////////////////////////
                15: //Write Done for HyperRAM.
                    begin oWr_Done<=1; CNT_Step<=CNT_Step+1; end
                16: //Expand signal width to x6 clocks periods to ensure be captured by Another FPGA. //48MHz=32'h2DC6C00
                    if(CNT_Delay==6) begin CNT_Delay<=0; oWr_Done<=0; CNT_Step<=CNT_Step+1; end //Enable this line in Radiant.
                    //if(CNT_Delay==10) begin CNT_Delay<=0; oWr_Done<=0; CNT_Step<=CNT_Step+1; end //Enable this line in ModelSim.
                    else begin CNT_Delay<=CNT_Delay+1; end
///////////////////////////////////////////////////////////////////////////////////////////////////////
                17: //Generate Done Signal.
                    begin oFrame_Done<=1; CNT_Step<=CNT_Step+1; end
                18: //only first time needed to wait for 15s. 
                    begin oFrame_Done<=0; CNT_Step<=2; end
                    //begin oFrame_Done<=0; CNT_Step<=7; end
                
            endcase
    end
end
endmodule
