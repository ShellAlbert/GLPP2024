module ZIRCAMOverUART(
    //Infrared Image Sensor Interface.
    //Multiplex with other function ports.
    inout ioIR_Data1_UP_UART_Tx,
    input iIR_Data2_UP_UART_Rx,
    inout ioIR_Data3_UPLD_Done,
    input iIR_Data4,
    inout ioIR_Data5_CFG_UART_Tx,
    input iIR_Data6_CFG_UART_Rx,
    input iIR_Data7,
    input iIR_Data8,
    input iIR_Data9,
    input iIR_Data10,
    input iIR_Data11,
    input iIR_Data12,
    input iIR_Data13,
    input iIR_Data14,

    input iIR_PClk,
    input iIR_VSync,
    input iIR_HSync,
    input iIR_UART_Rx,
    output oIR_UART_Tx,
    output oIR_Shutdown,

    //Octal RAM/EEPROM Interface.
    output oPSRAM_RST,
    output oPSRAM_CE,
    output oPSRAM_DQS,
    output oPSRAM_CLK,
    inout [7:0] ioPSRAM_DATA,

    //IO Multiplex Control.
    output [1:0] oMUX_SEL,

    //Debug UART.
    output oDBG_UART_Tx,
    input iDBG_UART_Rx,

    //Debug LEDx3.
    output oLED_Configuring, //Configuring LED.
    output oLED_Capturing, //Capturing LED.
    output oLED_Uploading //Uploading LED.
);

//HSOSC
//High-frequency oscillator.
//Generates 48-MHz nominal clock, +/- 10 percent, with user-programmable divider. 
//Can drive global clock network or fabric routing.
//Input Ports
//CLKHFPU :Power up the oscillator. After power up, output will be stable after 100 µs. Active high.
//CLKHFEN :Enable the clock output. Enable should be low for the 100-µs power-up period. Active high.
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
HSOSC #(.CLKHF_DIV("0b00")) //48 MHz
my_HSOSC(
    .CLKHFPU(1'b1), 
    .CLKHFEN(1'b1), 
    .CLKHF(clk_48MHz));

//Clock/PLL  
//Phase locked loop. For internal use.
//USER INSTANTIATION: Not recommended; prefer IP Generation Tool.
wire clk_main;
wire rst_n;
//48MHz => 200MHz
My_PLL my_PLL_inst(
.ref_clk_i(clk_48MHz),
.rst_n_i(1'b1),
.lock_o(rst_n),
.outcore_o( ),
.outglobal_o(clk_main));

//Task Schedule for Yantai InfiRay Infrared Image Sensor
//MicroIII 256L
ZIRTaskSchedule taskSchedule(
	.iClk(clk_main),
	.iRst_N(rst_n),
    .iEn(1'b1),

    //IO Multiplex Control.
    .oMUX_SEL(oMUX_SEL),

    //IR Configuration by FPGA or STM32?
    //iCfgByWhich=0, Configured by STM32.
    //iCfgByWhich=1, Configured by FPGA.
    .iCfgByWhich(1'b1),

    //IR Configuration Interface Signals.
    .oIR_UART_Txd(oIR_UART_Tx),
    .iIR_UART_Rxd(iIR_UART_Rx),

    //IR Interface Signals.
    //Multiplex with other function ports.
    .ioIR_Data1_UP_UART_Tx(ioIR_Data1_UP_UART_Tx),
    .iIR_Data2_UP_UART_Rx(iIR_Data2_UP_UART_Rx),
    .ioIR_Data3_UPLD_Done(ioIR_Data3_UPLD_Done),
    .iIR_Data4(iIR_Data4),
    .ioIR_Data5_CFG_UART_Tx(ioIR_Data5_CFG_UART_Tx),
    .iIR_Data6_CFG_UART_Rx(iIR_Data6_CFG_UART_Rx),
    .iIR_Data7(iIR_Data7),
    .iIR_Data8(iIR_Data8),
    .iIR_Data9(iIR_Data9),
    .iIR_Data10(iIR_Data10),
    .iIR_Data11(iIR_Data11),
    .iIR_Data12(iIR_Data12),
    .iIR_Data13(iIR_Data13),
    .iIR_Data14(iIR_Data14),

    .iIR_PClk(iIR_PClk),
    .iIR_HSync(iIR_HSync),
    .iIR_VSync(iIR_VSync),
    .oIR_Shutdown(oIR_Shutdown),

    //Octal RAM/EEPROM Interface.
    .oPSRAM_RST(oPSRAM_RST),
    .oPSRAM_CE(oPSRAM_CE),
    .oPSRAM_DQS(oPSRAM_DQS),
    .oPSRAM_CLK(oPSRAM_CLK),
    .ioPSRAM_DATA(ioPSRAM_DATA),

    //Debug UART.
    .oDBG_UART_Tx(oDBG_UART_Tx),
    .iDBG_UART_Rx(iDBG_UART_Rx),

    //Debug LEDx3.
    .oLED_Configuring(oLED_Configuring), //Configuring LED.
    .oLED_Capturing(oLED_Capturing), //Capturing LED.
    .oLED_Uploading(oLED_Uploading) //Uploading LED.
);

endmodule