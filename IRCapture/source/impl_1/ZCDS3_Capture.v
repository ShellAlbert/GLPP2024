`timescale 1ps/1ps
`include "ZPortableDefine.v"
module ZCDS3_Capture(
    input iClk,
    input iRst_N,
    input iEn,

    //input signals.
    input iIR_PCLK,
    input [7:0] iIR_Data,

    //Start to capture a new frame.
    output reg oCap_Frame_Start,
    //End to capture a new frame.
    output reg oCap_Frame_Done,

    //Capture one frame done?
    output reg oCap_Line_Done,

	//Write Single-Port RAM Interfaces.
	output reg oWr_Which, //O, Write which SPRAM:0/1.
    output reg [13:0] oWr_Addr, //O, Write Address.
    output reg [15:0] oWr_Data, //O, Write Data.
    output reg oWr_En, //O, Write Enable. 1:Write, 0:Read.

    //Notify me that DDR-Writer has done initilization.
    input iRAM_Init_Done
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
///////////////////////////////////////////
//combine data bus, only use data delayed 2 clocks.
wire [7:0] IR_Data_Bus;
assign IR_Data_Bus={IR_Data7[1],IR_Data6[1],IR_Data5[1],IR_Data4[1],IR_Data3[1],IR_Data2[1],IR_Data1[1],IR_Data0[1]};

//We sample data at middle point to get a stable value.
//Main clock is 66MHz, PCLK is 9.375MHz, the ratio is 66MHz/10MHz=6.6
//In order to get a stable value, we sample at the middle point.
//Here, we choose 2 as the middle point.
reg [7:0] CNT_Step;
reg [7:0] CNT_SubStep;
reg [31:0] CNT_Delay;

reg [7:0] Rx_DR0; //Receive Data Registers.
reg [7:0] Rx_DR1;
reg [7:0] Rx_DR2;
reg [7:0] Rx_DR3;
reg [15:0] Temp_DR;
reg [15:0] CNT_Bytes; 
//one line contains 256*2 bytes pixel data and 256*2 bytes temperature data, 1024 bytes totally.
reg [15:0] CNT_Lines;
reg [15:0] Random_Data;
//////////////////////////////////////////
always @(posedge iClk or negedge iRst_N)
if(!iRst_N) begin
    CNT_Step<=0; CNT_SubStep<=0; CNT_Delay<=0;
    //Initial Receive Data Registers.
    Rx_DR3<=0; Rx_DR2<=0; Rx_DR1<=0; Rx_DR0<=0;

    oWr_Which<=0; //Write 0# Single-Port-RAM first.
    oWr_Addr<=0; oWr_Data<=0; oWr_En<=0;
    Temp_DR<=0; CNT_Lines<=0; Random_Data<=0;
    CNT_Bytes<=0; oCap_Line_Done<=0; oCap_Frame_Start<=0; oCap_Frame_Done<=0; 
end
else begin
    if(iEn) begin 
            case(CNT_Step)
                0: //Waiting 1 second.
                    `ifdef USING_MODELSIM
                        if(CNT_Delay==100) begin CNT_Delay<=0; CNT_Step<=CNT_Step+1; end
                        else begin CNT_Delay<=CNT_Delay+1; end
                    `else //hex(48000000*7)=0x1406F400
                    //Yantai InfiRay Infrared Image Sensor needs 7 seconds to startup.
                    //Here if we don't wait 7 seconds, all capture data are 80 10.
                        if(CNT_Delay==32'h1406F400) begin CNT_Delay<=0; CNT_Step<=CNT_Step+1; end
                        else begin CNT_Delay<=CNT_Delay+1; end
                    `endif
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                1: //Waiting until ZDDRWriter initials DDR-PSRAM done.
                    begin
                        if(iRAM_Init_Done) begin CNT_Step<=CNT_Step+1; end
                        //////////////////////////////////////////////////
                        oWr_Which<=0; //Write 0, Read 1.
                        oWr_En<=0; oWr_Addr<=0; oWr_Data<=0; 
                        CNT_Bytes<=0; CNT_Lines<=0; oCap_Line_Done<=0; oCap_Frame_Start<=0; oCap_Frame_Done<=0; 
                    end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Since the size of One Page of DDR-PSRAM is 2K, data width is 8-bits, so it's 2KByte.
//And One Single Line of Infrared Image Sensor is 256*2Bytes(Pixel)+256*2Bytes(Temperature)=1024 Bytes.
//So each time we write FF0000B6, FF0000AB, FF00009D, FF000080, 256*2Bytes(Pixel)+256*2Bytes(Temperature) into Single-Port-RAM,
//the total size is 4+4+4+4+256*2+256*2=1040.
//The resolution of infrared image is 256*192, so we need 192 pages to save all lines.

//Warning!!!!!!!
//Only the 1st line of each frame is leading with FF0000B6, FF0000AB, FF00009D, FF000080.
//Other lines are leading with XXXXXXXX, XXXXXXXX, XXXXXXXX, FF000080
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                2: //Waiting Rising Edge. (all external input were delayed 2 clocks, so now is 3rd Clock)
                    begin
                        if(IR_CLK_Rising_Edge) begin CNT_Step<=CNT_Step+1; end
                       //write fixed data at the beginning of SPRAM to verify its correctness.
                        oWr_En<=1; oWr_Data<=16'hFF00; oWr_Addr<=(0); 
                    end
                3: //Sample at middle point & check patten match. (4th Clock)
                    begin 
                        Rx_DR3<=Rx_DR2; Rx_DR2<=Rx_DR1; Rx_DR1<=Rx_DR0; Rx_DR0<=IR_Data_Bus; //Latch data in.
                        //Rx_DR0<={IR_Data7[1],IR_Data6[1],IR_Data5[1],IR_Data4[1],IR_Data3[1],IR_Data2[1],IR_Data1[1],IR_Data0[1]};
                        `ifdef USING_MODELSIM  //write from address 0x2.
                            if(1) begin oCap_Frame_Start<=1; CNT_Lines<=0; CNT_Step<=CNT_Step+1; end
                        `else //Checking until we get FF 00 00 B6 sync header bytes, start of a frame.
                            if(Rx_DR2==8'hFF && Rx_DR1==8'h00 && Rx_DR0==8'h00 && IR_Data_Bus==8'hB6) begin 
                                oCap_Frame_Start<=1; CNT_Lines<=0; CNT_Step<=CNT_Step+1; 
                            end
                            else begin CNT_Step<=CNT_Step-1; end//Continue to check next data.
                        `endif
                        //write fixed data at the beginning of SPRAM to verify its correctness.
                        oWr_En<=1; oWr_Data<=16'h00B6; oWr_Addr<=(1); 
                    end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                4: //Waiting Rising Edge. (all external input were delayed 2 clocks, so now is 3rd Clock)
                    begin 
                        if(IR_CLK_Rising_Edge) begin CNT_Step<=CNT_Step+1; end
                        ///////////////////////////////
                        oCap_Frame_Start<=0; //Only keep one single pulse.
                       //write fixed data at the beginning of SPRAM to verify its correctness.
                        oWr_En<=1; oWr_Data<=16'hFF00; oWr_Addr<=(2); 
                    end
                5: //Sample at middle point & check patten match. (4th Clock)
                    begin 
                        Rx_DR3<=Rx_DR2; Rx_DR2<=Rx_DR1; Rx_DR1<=Rx_DR0; Rx_DR0<=IR_Data_Bus; //Latch data in.
                        //Rx_DR0<={IR_Data7[1],IR_Data6[1],IR_Data5[1],IR_Data4[1],IR_Data3[1],IR_Data2[1],IR_Data1[1],IR_Data0[1]};
                        `ifdef USING_MODELSIM  //write from address 0x2.
                            if(1) begin CNT_Step<=CNT_Step+1; end
                        `else //Checking until we get FF 00 00 AB sync header bytes, start of a frame.
                            if(Rx_DR2==8'hFF && Rx_DR1==8'h00 && Rx_DR0==8'h00 && IR_Data_Bus==8'hAB) begin CNT_Step<=CNT_Step+1; end
                            else begin CNT_Step<=CNT_Step-1; end//Continue to check next data.
                        `endif
                        //write fixed data at the beginning of SPRAM to verify its correctness.
                        oWr_En<=1; oWr_Data<=16'h00AB; oWr_Addr<=(3); 
                    end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                6: //Waiting Rising Edge. (all external input were delayed 2 clocks, so now is 3rd Clock)
                    begin
                        if(IR_CLK_Rising_Edge) begin CNT_Step<=CNT_Step+1; end
                        //write fixed data at the beginning of SPRAM to verify its correctness.
                        oWr_En<=1; oWr_Data<=16'hFF00; oWr_Addr<=(4); 
                        oCap_Line_Done<=0; Random_Data<=0; //Reset Random Data to zero.
                    end
                7: //Sample at middle point & check patten match. (4th Clock)
                    begin 
                        Rx_DR3<=Rx_DR2; Rx_DR2<=Rx_DR1; Rx_DR1<=Rx_DR0; Rx_DR0<=IR_Data_Bus; //Latch data in.
                        //Rx_DR0<={IR_Data7[1],IR_Data6[1],IR_Data5[1],IR_Data4[1],IR_Data3[1],IR_Data2[1],IR_Data1[1],IR_Data0[1]};
                        `ifdef USING_MODELSIM  //write from address 0x2.
                            if(1) begin CNT_Step<=CNT_Step+1; end
                        `else //Checking until we get FF 00 00 9D sync header bytes, start of a frame.
                            if(Rx_DR2==8'hFF && Rx_DR1==8'h00 && Rx_DR0==8'h00 && IR_Data_Bus==8'h9D) begin CNT_Step<=CNT_Step+1; end
                            else begin CNT_Step<=CNT_Step-1; end//Continue to check next data.
                        `endif
                        //write fixed data at the beginning of SPRAM to verify its correctness.
                        oWr_En<=1; oWr_Data<=16'h009D; oWr_Addr<=(5); 
                    end
                8:  //real data: FF 00 00 9D 80 10 80 10 80 10 80 10...................................
                    //in order to avoid confusion, I rewrite Addr(0-1)=0000, Addr(2-3)=0000.
                    //we have enough clock period to rewrite SPRAM before FF000080 arrives.
                    begin //Keep Line-0 to be original data.(FF0000B6).
                        if(CNT_Lines!=0) begin oWr_En<=1; oWr_Data<=16'hFFFF; oWr_Addr<=(0); end
                        CNT_Step<=CNT_Step+1; 
                    end
                9:
                    begin //Keep Line-0 to be original data.(FF0000B6).
                        if(CNT_Lines!=0) begin oWr_En<=1; oWr_Data<=16'hFFFF; oWr_Addr<=(1); end
                        CNT_Step<=CNT_Step+1; 
                    end
                10:
                    begin //Keep Line-0 to be original data.(FF0000AB).
                        if(CNT_Lines!=0) begin oWr_En<=1; oWr_Data<=16'h0000; oWr_Addr<=(2); end
                        CNT_Step<=CNT_Step+1; 
                    end
                11: 
                    begin //Keep Line-0 to be original data.(FF0000AB).
                        if(CNT_Lines!=0) begin oWr_En<=1; oWr_Data<={8'd0,CNT_Lines[7:0]}; oWr_Addr<=(3); end
                        CNT_Step<=CNT_Step+1; 
                    end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                12: //Waiting Rising Edge. (all external input were delayed 2 clocks, so now is 3rd Clock)
                    begin
                        if(IR_CLK_Rising_Edge) begin CNT_Step<=CNT_Step+1; end
                        /////////////////////////////////////////////////////////////
                        oCap_Line_Done<=0; 
                        //write fixed data at the beginning of SPRAM to verify its correctness.
                        oWr_En<=1; oWr_Data<=16'hFF00; oWr_Addr<=(6);
                    end
                13: //Sample at middle point & check patten match. (4th Clock)
                    begin 
                        Rx_DR3<=Rx_DR2; Rx_DR2<=Rx_DR1; Rx_DR1<=Rx_DR0; Rx_DR0<=IR_Data_Bus; //Latch data in.
                        //Rx_DR0<={IR_Data7[1],IR_Data6[1],IR_Data5[1],IR_Data4[1],IR_Data3[1],IR_Data2[1],IR_Data1[1],IR_Data0[1]};
                        `ifdef USING_MODELSIM  //write from address 0x2.
                            if(1) begin CNT_Step<=CNT_Step+1; end
                        `else //Checking until we get FF 00 00 80 sync header bytes. //write from address 0x8.
                            if(Rx_DR2==8'hFF && Rx_DR1==8'h00 && Rx_DR0==8'h00 && IR_Data_Bus==8'h80) begin 
                                CNT_Step<=CNT_Step+1; 
                            end
                            else begin CNT_Step<=CNT_Step-1; end//Continue to check next data.
                        `endif
                        //write fixed data at the beginning of SPRAM to verify its correctness.
                        oWr_En<=1; oWr_Data<=16'h0080; oWr_Addr<=(7); 
                    end
                14: //pre-set oWr_Addr.
                    begin oWr_En<=0; oWr_Addr<=(8); CNT_Step<=CNT_Step+1; end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                15: //Already got FF 00 00 80 sync header bytes.  (all external input were delayed 2 clocks, so now is 3rd Clock)
                    begin
                        if(IR_CLK_Rising_Edge) begin CNT_Step<=CNT_Step+1; end 
                    end
                16: //Sample at middle point and Save Image&Temperature data. (4th Clock)
                    begin
                        `ifdef USING_TEST_DATA
                            Temp_DR[15:8]<=Random_Data[15:8]; //8'h11;
                        `else
                            //Temp_DR<={Temp_DR[7:0],IR_Data7[1],IR_Data6[1],IR_Data5[1],IR_Data4[1],IR_Data3[1],IR_Data2[1],IR_Data1[1],IR_Data0[1]};
                            Temp_DR[15:8]<=IR_Data_Bus;
                        `endif
                        CNT_Step<=CNT_Step+1; 
                    end
//////////////////////////////////////////////////////////////////////////////////////////////////
                17: //Single-Port-RAM data width is 16-bits, but Pixel data width is 8-bits, so here we capture two times and write once. (3rd Clock)
                    if(IR_CLK_Rising_Edge) begin CNT_Step<=CNT_Step+1; end 
                18: //Sample at middle point and Save Image&Temperature data. (4th Clock)
                    begin
                        `ifdef USING_TEST_DATA
                            Temp_DR[7:0]<=Random_Data[7:0]; //8'h77;
                        `else
                            //Temp_DR<={Temp_DR[7:0],IR_Data7[1],IR_Data6[1],IR_Data5[1],IR_Data4[1],IR_Data3[1],IR_Data2[1],IR_Data1[1],IR_Data0[1]};
                            Temp_DR[7:0]<=IR_Data_Bus;
                        `endif
                        CNT_Step<=CNT_Step+1;
                    end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                19: //Single-Port-RAM data width is 16-bits, but Pixel data width is 8-bits, so here we capture two times and write once.
                    begin //(5th Clock)
                        oWr_En<=1; oWr_Data<=Temp_DR; //Write into Single-Port-RAM.
                        Random_Data<=Random_Data+1; CNT_Step<=CNT_Step+1; 
                    end
                20:
                    begin 
                        oWr_En<=0; 
                        if(oWr_Addr==520-1) begin  //one line contains 256*2+256*2=1024 bytes.1024/2=520.
                            oWr_Which<=~oWr_Which; //Change which Single-Port-RAM we will write periodically.
                            CNT_Step<=CNT_Step+1;
                        end
                        else begin 
                            oWr_Addr<=oWr_Addr+1; //Single-Port-RAM data width is 16-bits.
                            CNT_Step<=CNT_Step-5; //continue to capture rest data of this line.
                        end
                    end
                21: //One Frame contains 192 Lines.
                    begin 
                        oCap_Line_Done<=1; //oCap_Line_Done Must delay 1 clock after oWr_Which.
                        `ifdef USING_MODELSIM
                            if(CNT_Lines>=10-1) begin CNT_Lines<=0; CNT_Step<=CNT_Step+1; end
                        `else
                            if(CNT_Lines>=192-1) begin CNT_Lines<=0; CNT_Step<=CNT_Step+1; end
                        `endif
                            else begin CNT_Lines<=CNT_Lines+1; CNT_Step<=6; end //Continue to read next line. 
                    end
                22: //Already captured one frame!
                    begin oCap_Line_Done<=0; oCap_Frame_Done<=1; CNT_Step<=CNT_Step+1; end
                        
                23: //Go to capture next frame. //Capture 2 frames.
                    begin oCap_Frame_Done<=0; CNT_Step<=2; end
////////////////////////////////////////////////////////////////////////////////////////////////
            endcase
    end
end
endmodule
