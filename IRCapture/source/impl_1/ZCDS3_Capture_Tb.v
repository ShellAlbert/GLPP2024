`timescale 1ps/1ps
module ZCDS3_Capture_Tb;

reg clk_48MHz;
reg clk_9D375MHz;
reg rst_n;
initial begin
    rst_n=0;
    #100 rst_n=1; 
end
//f=48MHz,t=20nS
//tHigh=10nS, tLow=10nS
initial begin
    clk_48MHz=0;
    forever #10 clk_48MHz=~clk_48MHz;
end
//f=9.375MHz,t=106nS
//tHigh=50nS, tLow=50nS
initial begin
    clk_9D375MHz=0;
    forever #50 clk_9D375MHz=~clk_9D375MHz;
end

reg [7:0] IR_Data;

always @(posedge clk_9D375MHz or negedge rst_n)
if(!rst_n) begin
    IR_Data<=8'hFF;
end
else begin
    IR_Data<=IR_Data-1;
end

wire EBR_Wr_En;
wire [7:0] EBR_Wr_Data;
wire [8:0] EBR_Wr_Addr;
wire Frame_Done;
ZCDS3_Capture ic_CDS3(
    .iClk(clk_48MHz),
    .iRst_N(rst_n),
    .iEn(1'b1),

    //input signals.
    .iIR_PCLK(clk_9D375MHz),
    .iIR_Data(IR_Data),

    //EBR Interface.
    .oEBR_Wr_En(EBR_Wr_En),
    .oEBR_Wr_Data(EBR_Wr_Data),
    .oEBR_Wr_Addr(EBR_Wr_Addr),

    //Already captured one frame?
    .oFrame_Done(Frame_Done)
);

endmodule
