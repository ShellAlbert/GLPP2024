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
    input iRAM_Init_Done,

    //indicate which Single-Port RAM data is valid.
    output reg [1:0] oRAM_Data_Valid
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
reg [15:0] Captured_Bytes;
reg [15:0] CNT_Lines;
always @(posedge iClk or negedge iRst_N)
if(!iRst_N) begin
    CNT_Step<=0; CNT_SubStep<=0; CNT_Delay<=0;
    //Initial Receive Data Registers.
    Rx_DR3<=0; Rx_DR2<=0; Rx_DR1<=0; Rx_DR0<=0;

    oWr_Which<=0; //Write 0# Single-Port-RAM first.
    oWr_Addr<=0; oWr_Data<=0; oWr_En<=0; oRAM_Data_Valid<=0;
    Temp_DR<=0; CNT_Lines<=0;
    CNT_Bytes<=0; Captured_Bytes<=0; oCap_Line_Done<=0; oCap_Frame_Start<=0; oCap_Frame_Done<=0; 
end
else begin
    if(iEn) begin 
            case(CNT_Step)
                0: //Waiting 100mS. //f=66MHz,t=15nS. //100mS=100_000uS=100_000_000nS/15nS=6666666.hex(666666)=0xA2C2A
                    `ifdef USING_MODELSIM
                        if(CNT_Delay==100) begin CNT_Delay<=0; CNT_Step<=CNT_Step+1; end
                        else begin CNT_Delay<=CNT_Delay+1; end
                    `else
                        if(CNT_Delay=='hA2C2A) begin CNT_Delay<=0; CNT_Step<=CNT_Step+1; end
                        else begin CNT_Delay<=CNT_Delay+1; end
                    `endif
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                1: //Waiting until ZDDRWriter initials DDR-PSRAM done.
                    begin
                        if(iRAM_Init_Done) begin CNT_Step<=CNT_Step+1; end
                        //////////////////////////////////////////////////
                        oWr_Which<=0; oRAM_Data_Valid<=0;
                        oWr_En<=0; oWr_Addr<=0; oWr_Data<=0; 
                        CNT_Bytes<=0; Captured_Bytes<=0; CNT_Lines<=0; oCap_Line_Done<=0; oCap_Frame_Start<=0; oCap_Frame_Done<=0; 
                    end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                2: //Waiting Rising Edge. (all external input were delayed 2 clocks, so now is 3rd Clock)
                    begin
                        if(IR_CLK_Rising_Edge) begin CNT_Step<=CNT_Step+1; end
                       //write fixed data at the beginning of SPRAM to verify its correctness.
                        oWr_En<=1; oWr_Data<=16'hFF00; oWr_Addr<=0; 
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
                        oWr_En<=1; oWr_Data<=16'h00B6; oWr_Addr<=1; 
                    end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                4: //Waiting Rising Edge. (all external input were delayed 2 clocks, so now is 3rd Clock)
                    begin 
                        if(IR_CLK_Rising_Edge) begin CNT_Step<=CNT_Step+1; end
                        ///////////////////////////////
                        oCap_Frame_Start<=0; //Only keep one single pulse.
                       //write fixed data at the beginning of SPRAM to verify its correctness.
                        oWr_En<=1; oWr_Data<=16'hFF00; oWr_Addr<=2; 
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
                        oWr_En<=1; oWr_Data<=16'h00AB; oWr_Addr<=3; 
                    end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                6: //Waiting Rising Edge. (all external input were delayed 2 clocks, so now is 3rd Clock)
                    begin
                        if(IR_CLK_Rising_Edge) begin CNT_Step<=CNT_Step+1; end
                        //write fixed data at the beginning of SPRAM to verify its correctness.
                        oWr_En<=1; oWr_Data<=16'hFF00; oWr_Addr<=4; 
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
                        oWr_En<=1; oWr_Data<=16'h009D; oWr_Addr<=5; 
                    end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                8: //Waiting Rising Edge. (all external input were delayed 2 clocks, so now is 3rd Clock)
                    begin
                        if(IR_CLK_Rising_Edge) begin CNT_Step<=CNT_Step+1; end
                        /////////////////////////////////////////////////////////////
                        oCap_Line_Done<=0; 
                        //write fixed data at the beginning of SPRAM to verify its correctness.
                        oWr_En<=1; oWr_Data<=16'hFF00; oWr_Addr<=6; 
                    end
                9: //Sample at middle point & check patten match. (4th Clock)
                    begin 
                        Rx_DR3<=Rx_DR2; Rx_DR2<=Rx_DR1; Rx_DR1<=Rx_DR0; Rx_DR0<=IR_Data_Bus; //Latch data in.
                        //Rx_DR0<={IR_Data7[1],IR_Data6[1],IR_Data5[1],IR_Data4[1],IR_Data3[1],IR_Data2[1],IR_Data1[1],IR_Data0[1]};
                        `ifdef USING_MODELSIM  //write from address 0x2.
                            if(1) begin oWr_Addr<=8; CNT_Step<=CNT_Step+1; end
                            else begin CNT_Step<=CNT_Step-1; end//Continue to check next data.
                        `else //Checking until we get FF 00 00 80 sync header bytes. //write from address 0x8.
                            if(Rx_DR2==8'hFF && Rx_DR1==8'h00 && Rx_DR0==8'h00 && IR_Data_Bus==8'h80) begin oWr_Addr<=8; CNT_Step<=CNT_Step+1; end
                            else begin CNT_Step<=CNT_Step-1; end//Continue to check next data.
                        `endif
                        //write fixed data at the beginning of SPRAM to verify its correctness.
                        oWr_En<=1; oWr_Data<=16'h0080; oWr_Addr<=7; 
                    end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                10: //Already got FF 00 00 80 sync header bytes.  (all external input were delayed 2 clocks, so now is 3rd Clock)
                    begin
                        if(IR_CLK_Rising_Edge) begin CNT_Step<=CNT_Step+1; end 
                        ///////////////////////////////////////////////////////
                        oWr_En<=0; //Must disabled, or data will change.
                    end
                11: //Sample at middle point and Save Image&Temperature data. (4th Clock)
                    begin
                        `ifdef USING_TEST_DATA
                            Temp_DR[15:8]<=8'h20; 
                        `else
                            //Temp_DR<={Temp_DR[7:0],IR_Data7[1],IR_Data6[1],IR_Data5[1],IR_Data4[1],IR_Data3[1],IR_Data2[1],IR_Data1[1],IR_Data0[1]};
                            Temp_DR[15:8]<=IR_Data_Bus;
                        `endif
                        CNT_Step<=CNT_Step+1; 
                    end
//////////////////////////////////////////////////////////////////////////////////////////////////
                12: //Single-Port-RAM data width is 16-bits, but Pixel data width is 8-bits, so here we capture two times and write once. (3rd Clock)
                    if(IR_CLK_Rising_Edge) begin CNT_Step<=CNT_Step+1; end 
                13: //Sample at middle point and Save Image&Temperature data. (4th Clock)
                    begin
                        `ifdef USING_TEST_DATA
                            Temp_DR[7:0]<=8'h24;
                        `else
                            //Temp_DR<={Temp_DR[7:0],IR_Data7[1],IR_Data6[1],IR_Data5[1],IR_Data4[1],IR_Data3[1],IR_Data2[1],IR_Data1[1],IR_Data0[1]};
                            Temp_DR[7:0]<=IR_Data_Bus;
                        `endif
                        CNT_Step<=CNT_Step+1; 
                    end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                14: //Single-Port-RAM data width is 16-bits, but Pixel data width is 8-bits, so here we capture two times and write once.
                    begin //(5th Clock)
                        oWr_En<=1; oWr_Data<=Temp_DR; //Write into Single-Port-RAM.
                        ////////////////////////////////////////////////////////////
                        if(Captured_Bytes>=1024-1) begin  //one line contains 256*2+256*2=1024 bytes.
                            Captured_Bytes<=0; 
                            //make sure both Single-Port-RAM were initialized.
                            if(!oWr_Which) oRAM_Data_Valid[0]<=1;
                            if(oWr_Which) oRAM_Data_Valid[1]<=1;
                            //oRAM_Data_Valid<=(oWr_Which)?(2'b10):(2'b01); //Now Single-Port-RAM data is valid for first time.
                            oWr_Which<=~oWr_Which; //Change which Single-Port-RAM we will write periodically.
                            oCap_Line_Done<=1; 
                            ///////////////////////////////////////////////////////////////////////////////////////////////
                            `ifdef USING_MODELSIM //Reduce Time in ModelSim.
                                if(CNT_Lines>=5-1) begin CNT_Lines<=0; CNT_Step<=CNT_Step+1; end
                                else begin CNT_Lines<=CNT_Lines+1; CNT_Step<=8; end //Continue to read next line.
                            `else //One Frame is 192 lines in Radiant.
                                if(CNT_Lines>=192-1) begin CNT_Lines<=0; CNT_Step<=CNT_Step+1; end
                                else begin CNT_Lines<=CNT_Lines+1; CNT_Step<=8; end //Continue to read next line.
                            `endif
                        end
                        else begin 
                            Captured_Bytes<=Captured_Bytes+2; 
                            oWr_Addr<=oWr_Addr+1; //Single-Port-RAM data width is 16-bits.
                            CNT_Step<=CNT_Step-4; //continue to capture rest data of this line.
                        end
                    end
                15: //Already captured one frame!
                    begin oCap_Frame_Done<=1; oCap_Line_Done<=0; CNT_Step<=CNT_Step+1; end
                        
                16: //Go to capture next frame!
                    begin oCap_Frame_Done<=0; CNT_Step<=2; end
////////////////////////////////////////////////////////////////////////////////////////////////
            endcase
    end
end
endmodule
