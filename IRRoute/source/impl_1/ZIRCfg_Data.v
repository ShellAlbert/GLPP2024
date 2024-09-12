`timescale 1ps/1ps
module ZIRCfg_Data(
    input [7:0] iIndex,
    output reg [7:0] oData
);
always @(*)
begin
    case(iIndex)
        //（CDS-3）AA 06 01 5D 02 05 40 55 EB AA
        0: begin oData=8'hAA; end
        1: begin oData=8'h06; end
        2: begin oData=8'h01; end
        3: begin oData=8'h5D; end
        4: begin oData=8'h02; end
        5: begin oData=8'h05; end
        6: begin oData=8'h40; end
        7: begin oData=8'h55; end
        8: begin oData=8'hEB; end
        9: begin oData=8'hAA; end
        //(Save) AA 04 01 7F 02 30 EB AA
        10: begin oData=8'hAA; end
        11: begin oData=8'h04; end
        12: begin oData=8'h01; end
        13: begin oData=8'h7F; end
        14: begin oData=8'h02; end
        15: begin oData=8'h30; end
        16: begin oData=8'hEB; end
        17: begin oData=8'hAA; end
        default: begin oData=0; end
    endcase
end
endmodule