localparam WADDR_DEPTH = 16;
localparam WDATA_WIDTH = 16;
localparam RADDR_DEPTH = 16;
localparam RDATA_WIDTH = 16;
localparam FIFO_CONTROLLER = "FABRIC";
localparam FORCE_FAST_CONTROLLER = 0;
localparam IMPLEMENTATION = "EBR";
localparam WADDR_WIDTH = 4;
localparam RADDR_WIDTH = 4;
localparam REGMODE = "reg";
localparam RESETMODE = "async";
localparam ENABLE_ALMOST_FULL_FLAG = "TRUE";
localparam ALMOST_FULL_ASSERTION = "static-dual";
localparam ALMOST_FULL_ASSERT_LVL = 15;
localparam ALMOST_FULL_DEASSERT_LVL = 14;
localparam ENABLE_ALMOST_EMPTY_FLAG = "TRUE";
localparam ALMOST_EMPTY_ASSERTION = "static-dual";
localparam ALMOST_EMPTY_ASSERT_LVL = 1;
localparam ALMOST_EMPTY_DEASSERT_LVL = 2;
localparam ENABLE_DATA_COUNT_WR = "FALSE";
localparam ENABLE_DATA_COUNT_RD = "FALSE";
localparam FAMILY = "iCE40UP";
`define iCE40UP
`define ice40tp
`define iCE40UP5K
