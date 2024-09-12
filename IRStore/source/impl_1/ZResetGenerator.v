`timescale 1ps/1ps

module ZResetGenerator(
	input iClk, 
	output reg oRst_N);

reg [15:0] CNT;
always @(posedge iClk)
begin
    if(CNT==16'hFF) begin
        oRst_N<=1;
    end
    else begin
        CNT<=CNT+1;
        oRst_N<=0;
    end
end
endmodule