`timescale 1ps/1ps
`include "ZPortableDefine.v"
//Read data from Single-Port-RAM and write into DDR-PSRAM.
module ZDDRWriter(
    input iClk,
    input iRst_N,
    input iEn,

	//DDR PSRAM physical write interface.
	output reg oRAM_CLK,
	output reg oRAM_RST,
	output reg oRAM_CE,
	output reg oRAM_DQS,
	output reg [7:0] oRAM_ADQ,

    //Notify Capture Module that DDR-PSRAM initial done.
    output reg oRAM_Init_Done,
    //Frame Start & End.
    input iCap_Frame_Start,
    input iCap_Frame_Done,
    //CDS3Capture captured one line.
	input iCap_Line_Done,

    //Which Single-Port is in writing? 
    input iWr_Which, //0/1.
    //Read from Single-Port RAM.
    output reg [13:0] oRd_Addr, //O, Read Address.
    output reg oRd_En, //O, Read Enable. 1:Write, 0:Read.
    input [15:0] iRd_Data, //I, Read out Data from Single-Port-RAM.
    output reg oWr_Line_Done, //O, write one line from Single-Port-RAM to DDR-PSRAM done.

    //indicate which Single-Port RAM data is valid.
    // input [1:0] iRAM_Data_Valid, //I.

    output reg oWr_Frame_Done, //Means already written 1024 bytes to DDR-PSRAM.

    //Dump data from Single-Port-RAM to UART to check its correctness.
    output oUART_TxD
);


////////////////////////////////////////////////////////
//UART Tx.
reg [7:0] UART_Tx_DR; //Tx Data Register.
reg UART_Tx_En;
wire UART_Tx_Done;
//generate 2MHz Clock. 
//66MHz/2MHz=33.
//48MHz/2MHz=24.
ZUART_Tx #(.Freq_divider(24)) ic_UART_Tx 
(
	.iClk(iClk),
	.iRst_N(iRst_N),
	.iData(UART_Tx_DR),

	//pull down iEn to start transmition until pulse done oDone was issued.
	.iEn(UART_Tx_En),
	.oDone(UART_Tx_Done),
	.oTxD(oUART_TxD)
);

//Command List.
parameter CMD_SYNC_RD=8'h00;
parameter CMD_SYNC_WR=8'h80;
parameter CMD_LINEAR_BURST_RD=8'h20;
parameter CMD_LINEAR_BURST_WR=8'hA0;
parameter CMD_MODE_REG_RD=8'h40;
parameter CMD_MODE_REG_WR=8'hC0;
parameter CMD_GBL_RST=8'hFF;
//DDR Octal RAM Configuration before using.
reg [7:0] cfg_No;
wire [7:0] cfg_RegAddr;
wire [7:0] cfg_RegData;
ZOctalRAMCfg ic_cfg(
    .iNo(cfg_No),
    .oRegAddr(cfg_RegAddr),
    .oRegData(cfg_RegData)
);

reg [7:0] CNT_Step;
reg [7:0] CNT_SubStep;
reg [31:0] CNT_Delay;
reg [7:0] CNT_Repeat;
reg [7:0] CNT_WrDDR;

reg [95:0] Correctness_Fixed_Data; //'h198709011986101420160323 (12bytes in total, 12*8=96bits)
reg [15:0] Rd_Back_Data;
reg [31:0] Rd_Back_Bytes;
////////////////////////////////////////////////////////////////////////////////////////////////////
reg [13:0] rowAddr; //2^14=16384 Pages.
reg [10:0] colAddr; //2^11=2048/1024=2K
//(16384*2048)/1024=32768K/1024=32M,  32M*8bits=256Mbits.
wire [31:0] DDR_RAM_Addr; 
assign DDR_RAM_Addr={7'd0, rowAddr, colAddr};
///////////////////////////////////////////////////////////////////////////////////////////////////
reg [15:0] CNT_Lines; //There are 192 lines in one frame.
/////////////////////////////////////////////////////////////////////////////////////////////////
always @(posedge iClk or negedge iRst_N)
if(!iRst_N) begin
    CNT_Step<=0; CNT_SubStep<=0; CNT_Delay<=0; CNT_Repeat<=0;

    cfg_No<=0;
    oRAM_CLK<=0; oRAM_RST<=1; oRAM_CE<=1; oRAM_DQS<=0; oRAM_ADQ<=0;

    oRd_Addr<=0; Rd_Back_Data<=0; Rd_Back_Bytes<=0; 
    rowAddr<=0; colAddr<=0; 

    oRAM_Init_Done<=0; oWr_Line_Done<=0;
    CNT_Lines<=0; oWr_Frame_Done<=0; 
    UART_Tx_En<=0; UART_Tx_DR<=0;
    CNT_WrDDR<=0;
end
else begin
    if(iEn) begin 
            case(CNT_Step)
                0: //DDR-PSRAM: Reset.
                    case(CNT_SubStep)
                        0: //At default, CE=1, RST=1, CLK=0.
                            begin oRAM_CE<=1; oRAM_RST<=1; oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
                        1: //Device Initialization, tPU>150uS.
                        //Wait for OctalRAM to be stable after power on.
                        //f=66MHz, t=15nS.
                        //Here we wait 2 times of tPU, 300uS/15nS=300_000ns/15ns=20000.
                            `ifdef USING_MODELSIM
                                if(CNT_Delay==20) begin CNT_Delay<=0; CNT_SubStep<=CNT_SubStep+1; end
                            `else
                                if(CNT_Delay==20000) begin CNT_Delay<=0; CNT_SubStep<=CNT_SubStep+1; end
                            `endif
                                else begin CNT_Delay<=CNT_Delay+1; end
                        2:  //pull down RST while CE=1, tRP>1uS,
                            begin oRAM_RST<=0; CNT_SubStep<=CNT_SubStep+1; end
                        3: //pull up RST, tRST>=2uS, Reset to CMD valid.
                            begin oRAM_RST<=1; CNT_SubStep<=CNT_SubStep+1; end
                        4: //After reset, delay for a while for later operations.
                            `ifdef USING_MODELSIM
                                if(CNT_Delay==10) begin CNT_Delay<=0; CNT_SubStep<=CNT_SubStep+1; end
                            `else
                                if(CNT_Delay==1000) begin CNT_Delay<=0; CNT_SubStep<=CNT_SubStep+1; end
                            `endif
                                else begin CNT_Delay<=CNT_Delay+1; end
                        5:
                            begin 
                                CNT_SubStep<=0; CNT_Step<=CNT_Step+1; 
                                cfg_No<=0; //Necessary, Initial value before next step.
                            end
                    endcase
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                1: //DDR-PSRAM: Write Mode Registers.
                    case(CNT_SubStep)
                        0: //Prepare rising edge data. //Pull down CE to start. //DQS=0, no write mask.
                            begin oRAM_CE<=0; oRAM_DQS<=0; oRAM_ADQ<=CMD_MODE_REG_WR; CNT_SubStep<=CNT_SubStep+1; end
                        1: //Pull up CLK. (1st Rising Edge)
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        2: //Prepare falling edge data.
                            begin oRAM_ADQ<=CMD_MODE_REG_WR; CNT_SubStep<=CNT_SubStep+1; end
                        3: //Pull down CLK. (1st Falling Edge)
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
////////////////////////////////////////////////////////////////////////////////////////////////////
                        4: //Pull up CLK. (2nd Rising Edge)
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        5: //Pull down CLK. (2nd Falling Edge)
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end                           
//////////////////////////////////////////////////////////////////////////////////////////
                        6: //Pull up CLK. (3rd Rising Edge)
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        7: //Prepare data.
                            begin oRAM_ADQ<=cfg_RegAddr; CNT_SubStep<=CNT_SubStep+1;end 
                        8: //Pull down CLK. (3rd Falling Edge)
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
                        9: //Prepare data.
                            begin oRAM_ADQ<=cfg_RegData; CNT_SubStep<=CNT_SubStep+1;end 
                        10: //Pull up CLK. (4th Rising Edge).
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        11: //Pull down CLK. (4th Falling Edge)
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
//////////////////////////////////////////////////////////////////////////////////////////////////////////
                        12: //pull up CE to end.
                            begin oRAM_CE<=1; CNT_SubStep<=CNT_SubStep+1;end
//////////////////////////////////////////////////////////////////////////////////////////////////////////
                        13: //Must keep minimum 3 clocks after next CE. Here we keep 6 clocks.
                            if(CNT_Delay==6) begin CNT_Delay<=0; CNT_SubStep<=CNT_SubStep+1; end
                            else begin CNT_Delay<=CNT_Delay+1; end
                        14: //Loop to write all mode registers.
                            if(cfg_No==3) begin CNT_SubStep<=CNT_SubStep+1; end
                            else begin cfg_No<=cfg_No+1; CNT_SubStep<=0; end

                        15: //Write Mode Register done, move to next step.
                            begin CNT_SubStep<=0; CNT_Step<=CNT_Step+1; end
                    endcase        
//////////////////////////////////////////////////////////////////////////////////////////////
                2: //Write Sync Fixed Data to DDR-PSRAM(Addr:0~11) to verify writing correctness. //Write Latency=5.
                    case(CNT_SubStep)
                        0: //Prepare rising edge data. //Pull down CE to start. //DQS=0, no write mask.
                            begin 
                                oRAM_CE<=0; oRAM_DQS<=0; oRAM_ADQ<=CMD_LINEAR_BURST_WR; 
                                rowAddr<=0; colAddr<=0; //Page-0. Generate DDR_RAM_Addr.
                                CNT_SubStep<=CNT_SubStep+1; 
                            end
                        1: //Pull up CLK. (1st Rising Edge)
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        2: //Prepare falling edge data.
                            begin oRAM_ADQ<=CMD_LINEAR_BURST_WR; CNT_SubStep<=CNT_SubStep+1; end
                        3: //Pull down CLK. (1st Falling Edge)
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end 
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                        4: //prepare rising edge data. /////////////iAddress[31:24]=0.
                            begin oRAM_ADQ<=DDR_RAM_Addr[31:24]; CNT_SubStep<=CNT_SubStep+1; end 
                        5: //Pull up CLK. (2nd Rising Edge)
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        6: //Prepare falling edge data. ////////////iAddress[23:16]=0.
                            begin oRAM_ADQ<=DDR_RAM_Addr[23:16]; CNT_SubStep<=CNT_SubStep+1; end
                        7: //Pull down CLK. (2nd Falling Edge)
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                        8: //prepare rising edge data. //////////////iAddress[15:8]=0.
                            begin oRAM_ADQ<=DDR_RAM_Addr[15:8]; CNT_SubStep<=CNT_SubStep+1; end
                        9: //Pull up CLK. (3rd Rising Edge)
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        10: //Prepare falling edge data. ////////////iAddress[7:0]=0.
                            begin oRAM_ADQ<=DDR_RAM_Addr[7:0]; CNT_SubStep<=CNT_SubStep+1; end 
                        11: //Pull down CLK. (3rd Falling Edge)
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end   //Latency=1.
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                        12: //Latency=2.
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        13:
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                        14: //Latency=3.
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        15:
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                        16: //Latency=4.
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        17:
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                        18: //Latency=5.
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        19:
                            begin oRAM_CLK<=0; Correctness_Fixed_Data<=96'h090110140323871986191620; CNT_SubStep<=CNT_SubStep+1; end
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                        20: //We Write Fixed Data to DDR-PSRAM so the reader can verity if it reads correctly.
                            begin oRAM_ADQ<=Correctness_Fixed_Data[95:88];CNT_SubStep<=CNT_SubStep+1; end
                        21: //Generate Rising Edge.
                            begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                        22:
                            begin oRAM_ADQ<=Correctness_Fixed_Data[87:80]; CNT_SubStep<=CNT_SubStep+1; end
                        23: //Generate Falling Edge.
                            begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                        24: //Loop to write data in.
                            if(CNT_Delay==9-1) begin CNT_Delay<=0; CNT_SubStep<=CNT_SubStep+1; end
                            else begin 
                                    CNT_Delay<=CNT_Delay+1; 
                                    Correctness_Fixed_Data<={Correctness_Fixed_Data[79:0],16'd0}; //left shift 16-bits.
                                    CNT_SubStep<=CNT_SubStep-4; //continue to write.
                            end
//////////////////////////////////////////////////////////////////////////////////////////////////
                        25: 
                            begin 
                                oRAM_CE<=1; //Pull up CE to end.
                                //Progress Indicator.
                                if(UART_Tx_Done) begin UART_Tx_En<=0; CNT_SubStep<=CNT_SubStep+1; end
                                else begin UART_Tx_En<=1; UART_Tx_DR<=8'h66; end
                            end
                        26: //Notify Capture Module that DDR-PSRAM Initial done, you can capture now. 
                            begin 
                                oRAM_Init_Done<=1; //Notify CDS3Capture Module to start capture.
                                //96'h090110140323871986191620, 96bits/8=12 Bytes.
                                //Address[0~11] are used for writing Sync Fixed Data. (12 Bytes)
                                //Address[12~1035] are used for writing one line. (1024 Bytes)
                                rowAddr<=1; colAddr<=0; CNT_Lines<=0; //Write Page-1. 
                                CNT_SubStep<=0; CNT_Step<=CNT_Step+1;
                            end
                    endcase
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                3: //Waiting A New Frame.   
                    //First iCap_Line_Done means CD3Capture write SPRAM-0# done, it will start to write SPRAM-1#.
                    //So DDRWriter can read SPRAM-0# now.
                    if(iCap_Line_Done) begin              
                        //Read Enable. 1:Write, 0:Read.
                        oRd_Addr<=0; oRd_En<=0; CNT_Step<=CNT_Step+1;
                    end
                4: //Prepare to write DDR-PSRAM. Send Command+Address first.
                    begin
                        //oWr_Line_Done<=0; 
                        case(CNT_SubStep)
                            0: //Prepare rising edge data. //Pull down CE to start. //DQS=0, no write mask.
                                begin oRAM_CE<=0; oRAM_DQS<=0; oRAM_ADQ<=CMD_LINEAR_BURST_WR; CNT_SubStep<=CNT_SubStep+1; end
                            1: //Pull up CLK. (1st Rising Edge)
                                begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                            2: //Prepare falling edge data.
                                begin oRAM_ADQ<=CMD_LINEAR_BURST_WR; CNT_SubStep<=CNT_SubStep+1; end
                            3: //Pull down CLK. (1st Falling Edge)
                                begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end 
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                            4: //prepare rising edge data. /////////////iAddress[31:24]=0.
                                begin oRAM_ADQ<=DDR_RAM_Addr[31:24]; CNT_SubStep<=CNT_SubStep+1; end 
                            5: //Pull up CLK. (2nd Rising Edge)
                                begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                            6: //Prepare falling edge data. ////////////iAddress[23:16]=0.
                                begin oRAM_ADQ<=DDR_RAM_Addr[23:16]; CNT_SubStep<=CNT_SubStep+1; end
                            7: //Pull down CLK. (2nd Falling Edge)
                                begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                            8: //prepare rising edge data. //////////////iAddress[15:8]=0.
                                begin oRAM_ADQ<=DDR_RAM_Addr[15:8]; CNT_SubStep<=CNT_SubStep+1; end
                            9: //Pull up CLK. (3rd Rising Edge)
                                begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                            10: //Prepare falling edge data. ////////////iAddress[7:0]=0.
                                begin oRAM_ADQ<=DDR_RAM_Addr[7:0]; CNT_SubStep<=CNT_SubStep+1; end 
                            11: //Pull down CLK. (3rd Falling Edge)
                                begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end   //Latency=1.
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                            12: //Latency=2.
                                begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                            13:
                                begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                            14: //Latency=3.
                                begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                            15:
                                begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                            16: //Latency=4.
                                begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                            17:
                                begin oRAM_CLK<=0; CNT_SubStep<=CNT_SubStep+1; end
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                            18: //Latency=5.
                                begin oRAM_CLK<=1; CNT_SubStep<=CNT_SubStep+1; end
                            19: 
                                begin oRAM_CLK<=0; CNT_SubStep<=0; CNT_Step<=CNT_Step+1; end
                        endcase
                    end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                5: //Read data from Single-Port RAM.
                    //Single-Port-RAM has FF0000B6,FF0000AB,FF00009D,FF000080,Pixel(256*2),Temperature(256*2)=1040 Bytes.
                    //According to ice40_ultraplus_example, must wait 2 cycles to have data.
                    //https://github.com/damdoy/ice40_ultraplus_examples/blob/master/spram/top.v
                    begin CNT_Step<=CNT_Step+1; end
                6:  //Latch data in.
                    begin Rd_Back_Data<=iRd_Data; CNT_Step<=CNT_Step+1; end
/////////////////////////////////////////////////////////////////////////////////////////
                7: //Write data to DDR-SPRAM. (Rising Edge)
                    //begin oRAM_ADQ<=8'h55; CNT_Step<=CNT_Step+1; end 
                    begin oRAM_ADQ<=Rd_Back_Data[15:8]; CNT_Step<=CNT_Step+1; end 
                8: //Generate Rising Edge.
                    begin oRAM_CLK<=1; CNT_Step<=CNT_Step+1; end
                9: //Write data to DDR-SPRAM. (Rising Edge)
                    //begin oRAM_ADQ<=8'h44; CNT_Step<=CNT_Step+1; end
                    begin oRAM_ADQ<=Rd_Back_Data[7:0]; CNT_Step<=CNT_Step+1; end
                10: //Generate Falling Edge.
                    begin oRAM_CLK<=0; CNT_Step<=CNT_Step+1; end
                11: //Single-Port-RAM has FF0000B6,FF0000AB,FF00009D,FF000080,Pixel(256*2),Temperature(256*2)=1040 Bytes.
                    //Single-Port-RAM data width is 16-bits, we only need to read 1040/2=520 times.
                    if(oRd_Addr>=520-1) begin //Read one frame done.
                        oRd_Addr<=0; oWr_Line_Done<=1; oRAM_CE<=1; CNT_Step<=CNT_Step+1;
                    end
                    else begin //We can only write 10 clocks(10*2=20bytes) each time. because CE low width is limited within 2uS.
                        if(CNT_Delay==10-1) begin //10 times means (10*2Bytes=20Bytes).
                            oRAM_CE<=1; //Pull up CE to end writing.
                            CNT_Delay<=0; 
                            colAddr<=colAddr+20; //Next Write Position within one Page.
                            oRd_Addr<=oRd_Addr+1; CNT_Step<=4; //start next CE.
                        end
                        else begin 
                            CNT_Delay<=CNT_Delay+1; oRd_Addr<=oRd_Addr+1; //Addr+1.
                            CNT_Step<=5; //Continue to read from Single-Port-RAM and write into DDR-PSRAM.
                        end
                    end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
                12: //One Frame Done or to start a new page and capture next line.
                    begin
                        if(CNT_Lines>=192-1) begin CNT_Lines<=0; CNT_Step<=CNT_Step+1; end
                        //if(CNT_Lines>=20-1) begin CNT_Lines<=0; CNT_Step<=CNT_Step+1; end
                        else begin 
                            CNT_Lines<=CNT_Lines+1; 
                            rowAddr<=rowAddr+1; colAddr<=0; CNT_Step<=3; //Continue to read next line.
                        end 
                        ///////////////////////////////////////////////////////////////////////////////////////
                        oWr_Line_Done<=0; CNT_Delay<=0; CNT_Repeat<=0; oRd_Addr<=0; //reset read address to 0.
                    end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////      
                13: //One Frame done, stop here!
                    begin  //Always pull up Wr_Frame_Done to Notify another FPGA.
                        oWr_Frame_Done<=1; //Always pull-up and stop here.
                        CNT_Step<=CNT_Step;
                    end
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                14: //Dump the last line data from Single-Port-RAM to UART to check its correctness.
                    begin //Read Enable. 1:Write, 0:Read. //Read Address.
                        oRd_En<=0; CNT_Step<=CNT_Step+1; 
                    end
                15: //According to ice40_ultraplus_example, must wait 2 cycles to have data.
                    //https://github.com/damdoy/ice40_ultraplus_examples/blob/master/spram/top.v
                    begin CNT_Step<=CNT_Step+1; end
                16:
                    begin Rd_Back_Data<=iRd_Data; CNT_Step<=CNT_Step+1; end
                17: //Tx out - HIGH byte.
                    if(UART_Tx_Done) begin UART_Tx_En<=0; CNT_Step<=CNT_Step+1; end
                    else begin UART_Tx_En<=1; UART_Tx_DR<=Rd_Back_Data[15:8]; end
                18: //Tx out - LOW byte.
                    if(UART_Tx_Done) begin UART_Tx_En<=0; CNT_Step<=CNT_Step+1; end
                    else begin UART_Tx_En<=1; UART_Tx_DR<=Rd_Back_Data[7:0]; end
                19: //One Single Line 256*2(Pixel)+256*2(Temperature)=1024 Bytes.
                    //Single-Port-RAM data width is 16-bits, so we read 1024/2=512 times.
                    if(oRd_Addr==512-1) begin oRd_Addr<=0; CNT_Step<=CNT_Step+1; end
                    else begin oRd_Addr<=oRd_Addr+1; CNT_Step<=CNT_Step-5; end //continue to read next one.
                20: 
                    begin 
                        //I found Single-Port-RAM does not output valid data at 1st time reading in ModelSim.
                        //So here I read 3 frames from Single-Port-RAM.
                        if(CNT_WrDDR>=3) begin CNT_WrDDR<=0; CNT_Step<=CNT_Step+1; end
                        else begin CNT_WrDDR<=CNT_WrDDR+1; CNT_Step<=3; end
                    end
                21: //Stop Here.
                    begin  //Always pull up Wr_Frame_Done to Notify another FPGA.
                        oWr_Frame_Done<=1; //Always pull-up and stop here.
                        CNT_Step<=CNT_Step;
                    end
            endcase
    end
end
//The SB_SPRAM256KA and SP256K do not include output registers.
//When desired, pipeline registers are required to be implemented in the fabric. 
//While inferring the RAM, the software should implement the output pipeline registers in the fabric.
// always @(negedge iClk or negedge iRst_N)
// if(!iRst_N) begin
//     Temp_DR<=0;
// end
// else begin
//     if(iEn) begin
//         case(CNT_Step)
//             14: //Sample data at falling edge of this clock.
//                 begin 
//                     Temp_DR<=iRd_Data; 
//                 end
//         endcase
//     end
// end
endmodule
