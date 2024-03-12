module ZCfgM3256LBySTM32(
	input iClk,
	input iRst_N,
	input iEn,
	output reg oCfgDone,
	output reg oUART_Txd,
	input iUART_Rxd
);
//driven by step_i.
reg [1:0] step_i;
always @(posedge iClk or negedge iRst_N)
if(!iRst_N) begin
	step_i<=0;
	oCfgDone<=1'b0;
	oUART_Txd<=1'b1;
end
else begin
	if(!iEn) begin
		oCfgDone<=1'b0;
		oUART_Txd<=1'b1;
	end
	else begin
		oCfgDone<=1'b1;
	end
end
endmodule
