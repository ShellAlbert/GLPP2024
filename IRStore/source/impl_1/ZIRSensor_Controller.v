`timescale 1ps/1ps
module ZIRSensor_Controller(
    input iClk,
    input iRst_N,
    input iEn,

    //Interactive Interface.
    //iOp_Req=0, idle.
    //iOp_Req=1, Select CDS3 Interface & Save.
    input [2:0] iOp_Req,
    output reg oOp_Done,

    //Physical Pins.
    input iIR_UART_RxD,
    output oIR_UART_TxD
);

////////////////////////////////////////////////////////
//IR Configure UART Tx.
reg [7:0] UART_Tx_DR; //Tx Data Register.
reg UART_Tx_En;
wire UART_Tx_Done;
//generate 115200bps, 48MHz/115200bps=416.7
ZUART_Tx #(.Freq_divider(416)) ic_IR_UART_Tx 
(
	.iClk(iClk),
	.iRst_N(iRst_N),
	.iData(UART_Tx_DR),

	//pull down iEn to start transmition until pulse done oDone was issued.
	.iEn(UART_Tx_En),
	.oDone(UART_Tx_Done),
	.oTxD(oIR_UART_TxD)
);
/////////////////////////////////////
reg [7:0] cfg_Index;
wire [7:0] cfg_Data;
ZIRCfg_Data ic_Cfg(
    .iIndex(cfg_Index),
    .oData(cfg_Data)
);
////////////////////////////////////////////////
reg [7:0] CNT_Step;
reg [31:0] CNT_Delay;
reg [7:0] CNT_Repeat;
always @(posedge iClk or negedge iRst_N)
if(!iRst_N) begin
    CNT_Step<=0;
    oOp_Done<=0;
    cfg_Index<=0;
    CNT_Delay<=0;
    CNT_Repeat<=0;
end
else begin
    if(iEn) begin
        case(iOp_Req)
            1: //iOp_Req=1, Select CDS3 Interface & Save.
                case(CNT_Step)
                    0: //delay 10s to wait for IR Image Sensor starts up. //48MHz='h2DC6C00
                        if(CNT_Delay==32'h2DC6C00) begin CNT_Delay<=0; CNT_Step<=CNT_Step+1; end
                        else begin CNT_Delay<=CNT_Delay+1; end
                    1: //1second *10 times = 10 seconds.
                        if(CNT_Repeat==10-1) begin CNT_Repeat<=0; CNT_Step<=CNT_Step+1; end
                        else begin CNT_Repeat<=CNT_Repeat+1; CNT_Step<=CNT_Step-1; end
////////////////////////////////////////////////////////////////////////////////////////
                    2: //Configure IR Image Sensor.
                        if(UART_Tx_Done) begin UART_Tx_En<=0; CNT_Step<=CNT_Step+1; end
                        else begin UART_Tx_En<=1; UART_Tx_DR<=cfg_Data; end
                    3: //Loop to tx all UART protocol data.
                        if(cfg_Index==9) begin cfg_Index<=0; CNT_Step<=CNT_Step+1; end
                        else begin cfg_Index<=cfg_Index+1; CNT_Step<=CNT_Step-1; end
            
                    4: //delay for a while, and do configuration one more time.
                        if(CNT_Delay==16'hFFFF) begin CNT_Delay<=0; CNT_Step<=CNT_Step+1; end
                            else begin CNT_Delay<=CNT_Delay+1; end
                    5: //do configuration one more time.
                        if(CNT_Repeat==3) begin CNT_Repeat<=0; CNT_Step<=CNT_Step+1; end
                        else begin CNT_Repeat<=CNT_Repeat+1; CNT_Step<=CNT_Step-3; end
////////////////////////////////////////////////////////////////////////////////////////
                    6: //Send UART-Save Command.
                        begin cfg_Index<=10; CNT_Step<=CNT_Step+1; end
                    7: 
                        if(UART_Tx_Done) begin UART_Tx_En<=0; CNT_Step<=CNT_Step+1; end
                            else begin UART_Tx_En<=1; UART_Tx_DR<=cfg_Data; end
                    8: //Loop to tx all UART Protocol Data.
                        if(cfg_Index==17) begin cfg_Index<=0; CNT_Step<=CNT_Step+1; end
                            else begin cfg_Index<=cfg_Index+1; CNT_Step<=CNT_Step-1; end
////////////////////////////////////////////////////////////////////////////////////////         
                    9: //Generate Single Pulse Done Signal.
                        begin oOp_Done<=1; CNT_Step<=CNT_Step+1; end
                    10: //Generate Single Pulse Done Signal.
                        begin oOp_Done<=0; CNT_Step<=0; end
                endcase
            default: 
                begin CNT_Step<=0; end
        endcase
    end
end
endmodule