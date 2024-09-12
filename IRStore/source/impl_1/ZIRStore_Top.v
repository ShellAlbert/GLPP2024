`timescale 1ps/1ps
//ModelSim command
//vsim work.ZIRStore_Top iCE40UP.BB_B iCE40UP.HFOSC iCE40UP.IOL_B

module ZIRStore_Top(
	output oLED1,
	output oLED2,
    
    //IO Multiplex
    //0: DB_IO_0 -> CFG_SPI_D0, DB_IO_1 -> CFG_SPI_D2, DB_IO_2 -> CFG_SPI_D1, DB_IO_3 -> CFG_SPI_D3
    //1: DB_IO_0 -> IR_UART_TX, DB_IO_1 -> IR_UART_RX, DB_IO_2 -> UPLD_UART_TX, DB_IO_3 -> UPLD_UART_RX
	output oIOMux,
    //IR Configure UART Interface.
	output oIR_UART_TxD,
    input iIR_UART_RxD,

	//Octal RAM Interface.
	output oPSRAM_RST, //RESET# : Input Reset signal, active low. 
	output oPSRAM_CE, //CE#: Input, Chip select, active low. When CE#=1, chip is in standby state. 
	output oPSRAM_CLK,
	//DQS, IO.
	//DQ Strobe clock for DQ[7:0] during all reads.
	//Data mask for DQ[7:0] during memory writes.
	//DM is active HIGH, DM=1 means "do not write".
	inout ioPSRAM_DQS,
	inout [7:0] ioPSRAM_DATA, //Address/Data bus [7:0].

    //Using CFG_SPI_CS(37) to flywire as Debug UART TxD.
    output oDbgUART_TxD,
    output oTestSignal
);
/* synthesis RGB_TO_GPIO = "oLED1, oLED2" */
//HSOSC
//High-frequency oscillator.
//Generates 48-MHz nominal clock, +/- 10 percent, with user-programmable divider. 
//Can drive global clock network or fabric routing.
//Input Ports
//CLKHFPU :Power up the oscillator. After power up, output will be stable after 100 �s. Active high.
//CLKHFEN :Enable the clock output. Enable should be low for the 100-�s power-up period. Active high.
//Output Ports
//CLKHF :Oscillator output
//Parameters
//CLKHF_DIV
//Clock divider selection:
//0'b00 = 48 MHz
//0'b01 = 24 MHz
//0'b10 = 12 MHz
//0'b11 = 6 MHz
wire clk_48MHz;
//By default, the outputs are routed to global clock network. 
//To route to local fabric, see the examples in the Appendix: Design Entry section.
HSOSC #(.CLKHF_DIV("0b00")) //48 MHz
my_HSOSC(
    .CLKHFPU(1'b1), 
    .CLKHFEN(1'b1), 
    .CLKHF(clk_48MHz)
)/* synthesis ROUTE_THROUGH_FABRIC= 0 */; //the value can be either 0 or 1

//We MUST to generate a Power On Reset signal to reset PLL. 
//Otherwise it cannot work correctly in ModelSim. 
//All signals in ModelSim must have initial values.
reg rst_n_POR; //power on reset.
initial begin
	rst_n_POR<=0;
	#2000 rst_n_POR<=1;
end

wire rst_n;
//Attention here! 
//Pay attention to the clock cross domain issue!
wire clk_Global; //Global Clock Network.
wire clk_Local; //Local Fabric.
ZPLL ic_PLL(
    .ref_clk_i(clk_48MHz), 
    .rst_n_i(rst_n_POR), //Enable this line in ModelSim.
    //.rst_n_i(1'b1), //Enable this line in Lattice Radiant.
    .lock_o(rst_n),  
    .outcore_o(clk_Local), //A Channel-Local Faric.
    .outglobal_o(clk_Global) //A Channel-Global Clock Network.
    //Since iCE40UP5K only has 1 PLL, so Channel-B left empty.
	//.outcoreb_o(), //B Channel-Local Fabric.
    //.outglobalb_o() //B Channel-Global Clock Network.
);

assign oTestSignal=clk_Local;
assign oPSRAM_CLK=clk_Local;

/////////////////////////////////////
wire rst_n_sync;
ZSyncReset ic_SyncRst(
    .iClk(clk_Global),
    .iRst_N_ASync(rst_n),
    .oRst_N_Sync(rst_n_sync)
);
////////////////////////////////////////////
ZIRStore_Bottom ic_Bottom(
    .iClk(clk_Global),
	.iRst_N(rst_n_sync),

	.oLED1(oLED1),
	.oLED2(oLED2),
    
    //IO Multiplex
    //0: DB_IO_0 -> CFG_SPI_D0, DB_IO_1 -> CFG_SPI_D2, DB_IO_2 -> CFG_SPI_D1, DB_IO_3 -> CFG_SPI_D3
    //1: DB_IO_0 -> IR_UART_TX, DB_IO_1 -> IR_UART_RX, DB_IO_2 -> UPLD_UART_TX, DB_IO_3 -> UPLD_UART_RX
	.oIOMux(oIOMux),
    //IR Configure UART Interface.
	.oIR_UART_TxD(oIR_UART_TxD),
    .iIR_UART_RxD(iIR_UART_RxD),

	//Octal RAM Interface.
	.oPSRAM_RST(oPSRAM_RST), //RESET# : Input Reset signal, active low. 
	.oPSRAM_CE(oPSRAM_CE), //CE#: Input, Chip select, active low. When CE#=1, chip is in standby state. 
	//.oPSRAM_CLK(oPSRAM_CLK),
	//DQS, IO.
	//DQ Strobe clock for DQ[7:0] during all reads.
	//Data mask for DQ[7:0] during memory writes.
	//DM is active HIGH, DM=1 means "do not write".
	.ioPSRAM_DQS(ioPSRAM_DQS),
	.ioPSRAM_DATA(ioPSRAM_DATA), //Address/Data bus [7:0].

    //Using CFG_SPI_CS(37) to flywire as Debug UART TxD.
    .oDbgUART_TxD(oDbgUART_TxD)
);
endmodule