`timescale 1ps/1ps
`include "ZPortableDefine.v"
module ZCDS3_Capture(
    input iClk,
    input iRst_N,
    input iEn,

    //input signals.
    input iIR_PCLK,
    input [7:0] iIR_Data,

    //Capture one frame done?
    output reg oCap_Frame_Done,

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

always @(posedge iClk or negedge iRst_N)
if(!iRst_N) begin
    CNT_Step<=0; CNT_SubStep<=0; CNT_Delay<=0;
    //Initial Receive Data Registers.
    Rx_DR3<=0; Rx_DR2<=0; Rx_DR1<=0; Rx_DR0<=0;

    oWr_Which<=0; //Write 0# Single-Port-RAM first.
    oWr_Addr<=0; oWr_Data<=0; oWr_En<=0; oRAM_Data_Valid<=0;
    Temp_DR<=0;
    CNT_Bytes<=0; Captured_Bytes<=0; oCap_Frame_Done<=0;
end
else begin
    if(iEn) begin 
            case(CNT_Step)
                0: //Waiting 100mS. //f=66MHz,t=15nS. //100mS=100_000uS=100_000_000nS/15nS=6666666.hex(666666)=0xA2C2A
                    `ifdef USING_MODELSIM
                        if(CNT_Delay==100) begin CNT_Delay<=0; CNT_Step<=CNT_Step+1; end
                    `else
                        if(CNT_Delay=='hA2C2A) begin CNT_Delay<=0; CNT_Step<=CNT_Step+1; end
                    `endif
                        else begin CNT_Delay<=CNT_Delay+1; end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                1: //Waiting until ZDDRWriter initials DDR-PSRAM done.
                    if(iRAM_Init_Done) begin 
                        oWr_Which<=0;
                        oWr_Addr<=0; oWr_Data<=0; oWr_En<=0; oRAM_Data_Valid<=0;
                        CNT_Bytes<=0; Captured_Bytes<=0; oCap_Frame_Done<=0; 
                        CNT_Step<=CNT_Step+1; 
                    end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                2: //Waiting Rising Edge. (all external input were delayed 2 clocks, so now is 3rd Clock)
                    begin
                        `ifdef USING_MODELSIM
                            if(1) begin CNT_Step<=CNT_Step+1; end //Enable this line in ModelSim.
                        `else
                            if(IR_CLK_Rising_Edge) begin CNT_Step<=CNT_Step+1; end //Enable this line in Radiant.
                        `endif
                        /////////////////////////////////////////////////////////////
                        oCap_Frame_Done<=0; oWr_En<=0; //Must disabled, or data will change.
                    end
                3: //Sample at middle point & check patten match. (4th Clock)
                    begin 
                        Rx_DR3<=Rx_DR2; Rx_DR2<=Rx_DR1; Rx_DR1<=Rx_DR0; Rx_DR0<=IR_Data_Bus; //Latch data in.
                        //Rx_DR0<={IR_Data7[1],IR_Data6[1],IR_Data5[1],IR_Data4[1],IR_Data3[1],IR_Data2[1],IR_Data1[1],IR_Data0[1]};

                        //Checking until we get FF 00 00 80 sync header bytes. 
                        `ifdef USING_MODELSIM //Enable this line in ModelSim.
                            if(1) begin CNT_Step<=CNT_Step+1; end 
                        `else //Enable this line in Radiant.
                            if(Rx_DR3==8'hFF && Rx_DR2==8'h00 && Rx_DR1==8'h00 && IR_Data_Bus==8'h80) begin CNT_Step<=CNT_Step+1; end
                            else begin CNT_Step<=CNT_Step-1; end//Continue to check next data.
                        `endif
                        //////////////////////////////////////////////////////////////////////////////////////////////////////////
                        CNT_Step<=CNT_Step+1; 
                    end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                4: //Already got FF 00 00 80 sync header bytes.  (all external input were delayed 2 clocks, so now is 3rd Clock)
                    begin
                        `ifdef USING_MODELSIM //Enable this line in ModelSim.
                            if(1) begin CNT_Step<=CNT_Step+1; end 
                        `else //Enable this line in Radiant.
                            if(IR_CLK_Rising_Edge) begin CNT_Step<=CNT_Step+1; end 
                        `endif
                        ///////////////////////////////////////////////////////
                        oWr_En<=0; //Must disabled, or data will change.
                    end
                5: //Sample at middle point and Save Image&Temperature data. (4th Clock)
                    begin
                        //Temp_DR<={Temp_DR[7:0],IR_Data7[1],IR_Data6[1],IR_Data5[1],IR_Data4[1],IR_Data3[1],IR_Data2[1],IR_Data1[1],IR_Data0[1]};
                        Temp_DR[15:8]<=IR_Data_Bus; CNT_Step<=CNT_Step+1; 
                    end
//////////////////////////////////////////////////////////////////////////////////////////////////
                6: //Single-Port-RAM data width is 16-bits, but Pixel data width is 8-bits, so here we capture two times and write once.
                    `ifdef USING_MODELSIM //Enable this line in ModelSim.
                        if(1) begin CNT_Step<=CNT_Step+1; end 
                    `else //Enable this line in Radiant.
                        if(IR_CLK_Rising_Edge) begin CNT_Step<=CNT_Step+1; end 
                    `endif
                7: //Sample at middle point and Save Image&Temperature data. (4th Clock)
                    begin
                        //Temp_DR<={Temp_DR[7:0],IR_Data7[1],IR_Data6[1],IR_Data5[1],IR_Data4[1],IR_Data3[1],IR_Data2[1],IR_Data1[1],IR_Data0[1]};
                        Temp_DR[7:0]<=IR_Data_Bus; CNT_Step<=CNT_Step+1; 
                    end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                8: //Single-Port-RAM data width is 16-bits, but Pixel data width is 8-bits, so here we capture two times and write once.
                    begin //(5th Clock)
                        oWr_En<=1; oWr_Data<=Temp_DR; //Write into Single-Port-RAM.
                        ////////////////////////////////////////////////////////////
                        if(Captured_Bytes>=1022-1) begin  //512:0~511   =>1024: 0~1022. one line end?
                            Captured_Bytes<=0; 
                            oRAM_Data_Valid<=(oWr_Which)?(2'b10):(2'b01); //Now Single-Port-RAM data is valid for first time.
                            oWr_Which<=~oWr_Which; //Change which Single-Port-RAM we will write periodically.
                            oWr_Addr<=0;
                            oCap_Frame_Done<=1; 
                            CNT_Step<=2; //Go to capture next line.
                        end
                        else begin 
                            Captured_Bytes<=Captured_Bytes+2; 
                            oWr_Addr<=oWr_Addr+1; //Single-Port-RAM data width is 16-bits.
                            CNT_Step<=CNT_Step-4; //continue to capture rest data.
                        end
                    end
////////////////////////////////////////////////////////////////////////////////////////////////
            endcase
    end
end
endmodule
