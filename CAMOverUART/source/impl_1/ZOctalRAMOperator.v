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

//single bit output DDR
reg ddrout_n;
reg ddrout_p;
wire ddrout; 
wire clk;
assign clk=iClk;
IOL_B
 #(
  .DDROUT ("YES")
 ) u_ddr_IOL_B (
  .PADDI  (1'b0),   // I
  .DO1    (ddrout_n), // I, falling edge data from fabric
  .DO0    (ddrout_p), // I, rising edge data from fabric
  .CE     (1'b1),   
  // I, clock enabled
  .IOLTO  (1'b1),   
  .HOLD   (1'b0),   
  .INCLK  (clk),    
  .OUTCLK (clk),    
  .PADDO  (ddrout), 
  .PADDT  (),       
  .DI1    (),       
  .DI0    ()        
);


endmodule
