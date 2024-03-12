module ZDataCapture(
	input iClk,
	input iRst_N,
	input iEn,

    //IR Interface Signals.
    input [13:0] iIR_Data,
    input iIR_PClk,
    input iIR_HSync,
    input iIR_VSync,

    //FIFO Write Interface.
    output oFIFO_Rst,
    output oFIFO_Wr_En,
    output oFIFO_Wr_Clk,
    output [15:0] oFIFO_Wr_Data,
    input iFIFO_Full,
    input iFIFO_Almost_Full,

    //Indicate One Complete Frame Received.
    output oFrameDone
);

endmodule
