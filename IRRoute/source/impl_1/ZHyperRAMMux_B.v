`timescale 1ps/1ps
module ZHyperRAMMux_B(
    inout ioPAD, //bidirectional PAD.
    ///////////////////
    input iWrData1, //FPGA-1# write data.
    input iWrData2, //FPGA-2# write data.
    input iWhichWr, //select, 0:Data1, 1:Data2.
    //////////////////////////
    input iTriState,  //Tri-State control, 1:output, 0:High-Z.
    output oRdData //Read data from PAD.
);

wire wrData;
assign wrData=(!iWhichWr)?(iWrData1):(iWrData2);

assign ioPAD=(iTriState)?(wrData):(1'bz);
assign oRdData=ioPAD;

endmodule