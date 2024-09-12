`timescale 1ps/1ps
`include "ZPortableDefine.v"

module ZResetGenerator(
	input iClk, 
	output reg oRst_N);


reg [15:0] CNT;

initial begin 
    CNT<=0;
end

always @(posedge iClk)
begin
    `ifdef USING_MODELSIM
        if(CNT==100) begin oRst_N<=1; end
    `else 
        if(CNT==16'hFFF-1) begin oRst_N<=1; end
    `endif
        else begin CNT<=CNT+1; oRst_N<=0; end
end
endmodule