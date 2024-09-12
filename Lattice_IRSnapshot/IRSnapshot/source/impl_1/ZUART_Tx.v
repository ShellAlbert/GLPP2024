`timescale 1ps/1ps

module ZUART_Tx(
	input iClk,
	input iRst_N,
	input [7:0] iData,
	
	//pull down iEn to start transmition until pulse done oDone was issued.
	input iEn,
	output reg oDone,
	output reg oTxD);

//generate 1MHz Clock. //48MHz/1MHz=48.
//generate 2MHz Clock. //48MHz/2M=24.

//We expect a 100MHz PLL output, but the report gives out the maximum frequency is 51MHz.
//Single Clock Domain
//-------------------------------------------------------------------------------------------------------
//	Clock clk_100MHz            |                    |       Period       |     Frequency      
//-------------------------------------------------------------------------------------------------------
//	 From clk_100MHz                        |             Target |          10.000 ns |        100.002 MHz 
//											| Actual (all paths) |          19.442 ns |         51.435 MHz 
//100MHz/2MHz=5.
//51.435MHz/2MHz=25.7175
reg [15:0] CNT1;
wire tx_clk;
always @(posedge iClk or negedge iRst_N)
if(!iRst_N) begin
	CNT1<=0;
end
else if(iEn) begin 
				if(CNT1==26-1) 
					CNT1<=0;
				else 
					CNT1<=CNT1+1;
			end
	else begin
			CNT1<=0;
		end
assign tx_clk=(CNT1==26-1)?1:0;

//Tx: start bit(1)+data bits(8)+stop bit(1)
reg [7:0] CNT2;
reg [8:0] CNT_Shift;
always @(posedge iClk or negedge iRst_N)
if(!iRst_N) begin
	oTxD<=1;
	oDone<=0;
	CNT2<=0;
	CNT_Shift<=0;
end
else if(iEn) begin
				case(CNT2)
					0: //start bit(1).
						if(tx_clk) begin oTxD<=0; CNT2<=CNT2+1; end
					1: //data bits(8).
						if(CNT_Shift==8) begin CNT_Shift<=0; CNT2<=CNT2+1; end
						else begin
								if(tx_clk) begin 
											//oTxD<=iData[7-CNT_Shift]; //MSB first.
											oTxD<=iData[CNT_Shift]; //LSB first.
											CNT_Shift<=CNT_Shift+1;
										 end
							end
					2: //stop bit(1).
						if(tx_clk) begin oTxD<=0; CNT2<=CNT2+1; end
					3: //done signal.
						begin oTxD<=1; oDone<=1; CNT2<=CNT2+1; end
					4: //done signal.
						begin oDone<=0; CNT2<=0; end
				endcase
			end
	else begin
			oTxD<=1;
			oDone<=0;
			CNT2<=0;
		end
endmodule