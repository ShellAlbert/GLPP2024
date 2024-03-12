module ZOctalRAMOperator(
	input iClk,
	input iRst_N,
	input iEn,

    //iCmd[1:0]=00, Single Write.
    //iCmd[1:0]=01, Burst Write.
    //iCmd[1:0]=10, Single Read.
    //iCmd[1:0]=11, Burst Read.
    input [1:0] iCmd,

    //FIFO Read Interface.
    output oFIFO_Rd_En,
    output oFIFO_Rd_Clk,
    input [15:0] iFIFO_Rd_Data,
    input iFIFO_Empty,
    input iFIFO_Almost_Empty,

    //Octal RAM/EEPROM Interface.
    output oPSRAM_RST,
    output oPSRAM_CE,
    output oPSRAM_DQS,
    output oPSRAM_CLK,
    inout [7:0] ioPSRAM_DATA,

    //Output data for uploading via UART.
    output oDataRdy,
    output [15:0] oData,
    output oWrFrameDone,
    output oRdFrameDone
);
endmodule
