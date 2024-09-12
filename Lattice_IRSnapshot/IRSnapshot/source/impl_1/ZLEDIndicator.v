`timescale 1ps/1ps

module ZLEDIndicator(
	input iClk, 
	input iRst_N, 
	output reg oLED1, 
	output reg oLED2, 
	output reg oIOMux );
/* synthesis RGB_TO_GPIO = "oLED1, oLED2" */

//100MHz
always @(posedge iClk or negedge iRst_N)
if(!iRst_N) begin
	oIOMux<=1'b0;
end
else begin
	oIOMux<=~oIOMux;
	end

//100MHz/2Hz=50_000_000
reg [31:0] CNT1;
always @(posedge iClk or negedge iRst_N)
if(!iRst_N) begin
	CNT1<=0;
	oLED1<=0;
	oLED2<=0;
end
else begin
		if(CNT1>=32'd50_000_000-1) begin
			CNT1<=0;
			oLED1<=~oLED1;
			oLED2<=~oLED2;
			end
		else begin
			CNT1<=CNT1+1'b1;
			end
	end
endmodule