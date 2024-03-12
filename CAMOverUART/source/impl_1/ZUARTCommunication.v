module ZUARTCommunication(
	input iClk,
	input iRst_N,
	input iEn,

    //Transmit data out.
    input iTxEn,
    input [15:0] iTxData,
    output oTxDone,

    //Receive data in.
    output [15:0] oRxData,
    output oRxRdy,

    //Physical I/O Interface.
    output oTxd,
    input iRxd
);

endmodule