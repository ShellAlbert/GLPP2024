`timescale 1ps/1ps
module ZClockDomainCrossing(
    input iClk_Global,
    input iClk_Local,
    input iRst_N,

    //Clk_Global -> Clk_Local.
    input [2:0] iOp_Code,
    output [2:0] oOp_Code,

    //Clk_Local -> Clk->Global.
    input iOp_Done,
    output oOp_Done
);

//Clk_Global -> Clk_Local.
reg [2:0] Op_Code1;
reg [2:0] Op_Code2;
always @(posedge iClk_Local or negedge iRst_N)
if(!iRst_N) begin
    Op_Code1<=3'b000;
    Op_Code2<=3'b000;
end
else begin
    Op_Code1<=iOp_Code;
    Op_Code2<=Op_Code1;
end
assign oOpCode=Op_Code2;

//Clk_Local -> Clk->Global.
reg Op_Done1;
reg Op_Done2;
always @(posedge iClk_Global or negedge iRst_N)
if(!iRst_N) begin
    Op_Done1<=0;
    Op_Done2<=0;
end
else begin
    Op_Done1<=iOp_Done;
    Op_Done2<=Op_Done1;
end
assign oOp_Done=Op_Done2;

endmodule