`timescale 1ps/1ps

//Test Bench for ZUART_Tx.
module ZUART_Tx_TB(
    input iClk,
    input iRst_N,
    output oUART_TxD
);


//UART Tx.
reg [7:0] upload_data;
reg tx_en;
wire tx_done;

ZUART_Tx ic_tx(
	.iClk(iClk),
	.iRst_N(iRst_N),
	.iData(upload_data),
	
	.iEn(tx_en),
	.oDone(tx_done),
	.oTxD(oUART_TxD));


//driven by counter.
reg [7:0] CNT1;
reg [31:0] CNT2;

always @(posedge iClk or negedge iRst_N)
if(!iRst_N) begin
	CNT1<=0;
	CNT2<=0;
end
else begin
		case(CNT1)
			0: 
				if(tx_done) begin tx_en<=0; CNT1<=CNT1+1; end
				else begin tx_en<=1; upload_data<=8'h20; end
			1:	if(tx_done) begin tx_en<=0; CNT1<=CNT1+1; end
				else begin tx_en<=1; upload_data<=8'h24; end
			2: 
				if(tx_done) begin tx_en<=0; CNT1<=CNT1+1; end
				else begin tx_en<=1; upload_data<=8'h08; end
			3: 
				if(tx_done) begin tx_en<=0; CNT1<=CNT1+1; end
				else begin tx_en<=1; upload_data<=8'h15; end
			4: 
				if(CNT2==32'hFFFFFFF) begin CNT2<=0; CNT1<=CNT1+1; end
				else begin CNT2<=CNT2+1; end
			5: 
				begin CNT1<=0; end
		endcase
	end
endmodule