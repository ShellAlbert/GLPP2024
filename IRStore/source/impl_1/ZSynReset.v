`timescale 1ps/1ps
module ZSyncReset(
    input iClk,
    input iRst_N_ASync,
    output reg oRst_N_Sync
);
reg rst_delay;
always @(posedge iClk or negedge iRst_N_ASync)
if(!iRst_N_ASync) begin
    rst_delay<=0;
    oRst_N_Sync<=0;
end
else begin
    rst_delay<=1;
    oRst_N_Sync<=rst_delay;
end
endmodule