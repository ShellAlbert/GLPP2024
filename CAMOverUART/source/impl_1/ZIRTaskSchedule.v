module ZIRTaskSchedule(
	input iClk,
	input iRst_N,
    input iEn,
    //IO Multiplex Control.
    output reg [1:0] oMUX_SEL,

    //IR Configuration by FPGA or STM32?
    //iCfgByWhich=0, Configured by STM32.
    //iCfgByWhich=1, Configured by FPGA.
    input iCfgByWhich,

    //IR Configuration Interface Signals.
    output oIR_UART_Txd,
    input iIR_UART_Rxd,

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
    input iIR_HSync,
    input iIR_VSync,
    output reg oIR_Shutdown,

    //Octal RAM/EEPROM Interface.
    output oPSRAM_RST,
    output oPSRAM_CE,
    output oPSRAM_DQS,
    output oPSRAM_CLK,
    inout [7:0] ioPSRAM_DATA,

    //Debug UART.
    output oDBG_UART_Tx,
    input iDBG_UART_Rx,

    //Debug LEDx3.
    output oLED_Configuring, //Configuring LED.
    output oLED_Capturing, //Capturing LED.
    output oLED_Uploading //Uploading LED.
);

//Triangle-State Gate Control for ioIR_Data1_UP_UART_Tx.
reg OutFlag_ioIR_Data1_UP_UART_Tx;
wire UP_UART_Tx;
assign ioIR_Data1_UP_UART_Tx=(OutFlag_ioIR_Data1_UP_UART_Tx)?(UP_UART_Tx):(1'bz);
//Triangle-State Gate Control for ioIR_Data3_UPLD_Done.
reg OutFlag_ioIR_Data3_UPLD_Done;
reg UPLD_Done;
assign ioIR_Data3_UPLD_Done=(OutFlag_ioIR_Data3_UPLD_Done)?(UPLD_Done):(1'bz);
//Triangle-State Gate Control for ioIR_Data5_CFG_UART_Tx.
reg OutFlag_ioIR_Data5_CFG_UART_Tx;
reg CFG_UART_Tx;
assign ioIR_Data5_CFG_UART_Tx=(OutFlag_ioIR_Data5_CFG_UART_Tx)?(CFG_UART_Tx):(1'bz);

//IR Image Sensor configured by STM32.
reg cfgEn0;
wire cfgDone0;
ZCfgM3256LBySTM32 cfg_by_STM32(
	.iClk(iClk),
	.iRst_N(iRst_N),
	.iEn(cfgEn0),
	.oCfgDone(cfgDone0),
	.oUART_Txd(oIR_UART_Txd),
	.iUART_Rxd(iIR_UART_Rxd)
);

//IR Image Sensor configured by FPGA.
reg cfgEn1;
wire cfgDone1;
ZCfgM3256LByFPGA cfg_by_FPGA(
	.iClk(iClk),
	.iRst_N(iRst_N),
	.iEn(cfgEn1),
	.oCfgDone(cfgDone1),
	.oUART_Txd(oIR_UART_Txd),
	.iUART_Rxd(iIR_UART_Rxd)
);

//FIFO Module.
wire rdEn_FIFO;
wire wrEn_FIFO;
wire [15:0] wrData_FIFO;
wire [15:0] rdData_FIFO;
wire fullFlag_FIFO;
wire emptyFlag_FIFO;
wire almostFull_FIFO;
wire almostEmpty_FIFO;
My_FIFO buffering_FIFO(
    .wr_clk_i(iClk), //Write Clock.(25MHz)
    .rd_clk_i(iIR_PClk), //Read Clock.(100MHz)
    .rst_i(iRst_N), //FIFO Empty Reset.
    .rp_rst_i(iRst_N), //Read Point Reset, FIFO Full Reset.
    .wr_en_i(wrEn_FIFO), //Write Enable.
    .rd_en_i(rdEn_FIFO), //Read Enable.
    .wr_data_i(wrData_FIFO), //Data Input.
    .full_o(fullFlag_FIFO), //Full Flag.
    .empty_o(emptyFlag_FIFO), //Empty Flag. 
    .almost_full_o(almostFull_FIFO), //Almost Full Flag. 
    .almost_empty_o(almostEmpty_FIFO), //Almost Empty Flag.
    .rd_data_o(rdData_FIFO) //Data Output.
    ) ;

//Latch data in and write to FIFO.
reg capEn;
wire capFrameDone;
wire FIFO_Rst;
wire WrClk_FIFO;
ZDataCapture data_Capture(
	.iClk(iClk),
	.iRst_N(iRst_N),
	.iEn(capEn),

    //IR Interface Signals.
    .iIR_Data({
        ioIR_Data1_UP_UART_Tx,
        iIR_Data2_UP_UART_Rx,
        ioIR_Data3_UPLD_Done,
        iIR_Data4,
        ioIR_Data5_CFG_UART_Tx,
        iIR_Data6_CFG_UART_Rx,
        iIR_Data7,
        iIR_Data8,
        iIR_Data9,
        iIR_Data10,
        iIR_Data11,
        iIR_Data12,
        iIR_Data13,
        iIR_Data14
    }),
    .iIR_PClk(iIR_PClk),
    .iIR_HSync(iIR_HSync),
    .iIR_VSync(iIR_VSync),

    //FIFO Write Interface.
    .oFIFO_Rst(FIFO_Rst),
    .oFIFO_Wr_En(wrEn_FIFO),
    .oFIFO_Wr_Clk(WrClk_FIFO),
    .oFIFO_Wr_Data(wrData_FIFO),
    .iFIFO_Full(fullFlag_FIFO),
    .iFIFO_Almost_Full(almostFull_FIFO),

    //Indicate One Complete Frame Received.
    .oFrameDone(capFrameDone)
);

//Write data from FIFO and write to External OctalRAM.
//Read data from OctalRAM and transmit out via UART.
reg ramEn;
reg [1:0] ramCmd;
wire dataRdRdy;
wire [15:0] ramRdData;
wire RdFrameDone;
wire WrFrameDone;
wire RdClk_FIFO;
ZOctalRAMOperator ram_Operator(
	.iClk(iClk),
	.iRst_N(iRst_N),
	.iEn(ramEn),

    //iCmd[1:0]=00, Single Write.
    //iCmd[1:0]=01, Burst Write.
    //iCmd[1:0]=10, Single Read.
    //iCmd[1:0]=11, Burst Read.
    .iCmd(ramCmd),

    //FIFO Read Interface.
    .oFIFO_Rd_En(rdEn_FIFO),
    .oFIFO_Rd_Clk(RdClk_FIFO),
    .iFIFO_Rd_Data(rdData_FIFO),
    .iFIFO_Empty(emptyFlag_FIFO),
    .iFIFO_Almost_Empty(almostEmpty_FIFO),

    //Octal RAM/EEPROM Interface.
    .oPSRAM_RST(oPSRAM_RST),
    .oPSRAM_CE(oPSRAM_CE),
    .oPSRAM_DQS(oPSRAM_DQS),
    .oPSRAM_CLK(oPSRAM_CLK),
    .ioPSRAM_DATA(ioPSRAM_DATA),

    //Output data for uploading via UART.
    .oDataRdy(dataRdRdy),
    .oData(ramRdData),
    .oWrFrameDone(WrFrameDone),
    .oRdFrameDone(RdFrameDone)
);

//Fetch data from Octal RAM,
//then transmit them out via UART.
reg enUART;
reg enTx;
wire doneTx;
wire [15:0] rxData;
wire rdyRx;
ZUARTCommunication uart_Upload(
	.iClk(iClk),
	.iRst_N(iRst_N),
	.iEn(enUART),

    //Transmit data out.
    .iTxEn(enTx),
    .iTxData(ramRdData),
    .oTxDone(doneTx),

    //Receive data in.
    .oRxData(rxData),
    .oRxRdy(rdyRx),

    //Physical I/O Interface.
    .oTxd(UP_UART_Tx),
    .iRxd(iIR_Data2_UP_UART_Rx)
);


//the whole progress is driven by step i.
reg [9:0] step_i;
always @(posedge iClk or negedge iRst_N)
if(!iRst_N | !iEn) begin
    step_i<=0;
    //Disable Power Supply of IR Module.
    oIR_Shutdown<=1'b0;
    //Disable Configure Module.
    cfgEn0<=1'b0;
    cfgEn1<=1'b0;
end
else begin
    case(step_i)
    0: //step-0: Combine more steps in step-0 as possible as we can.
    begin
        //Enable Power Supply of IR Module.
        oIR_Shutdown<=1'b1;
        //IO Multiplex GPIO=>Image Sensor
        oMUX_SEL[0]<=1'b0; //SEL=0, SxA=>Dx
        //Choose iIR_Data1
        OutFlag_ioIR_Data1_UP_UART_Tx<=1'b0;
        //Choose iIR_Data3.
        OutFlag_ioIR_Data3_UPLD_Done<=1'b0;
        //Choose iIR_Data5.
        OutFlag_ioIR_Data5_CFG_UART_Tx<=1'b0;
        step_i<=step_i+1; //Move to next step.
    end
    1: //step-1: Configure Image Sensor via FPGA or STM32.
    begin
        if(!iCfgByWhich) begin //iCfgByWhich=0, Configured by STM32.
            if(!cfgDone0) begin
                cfgEn0<=1'b1;
            end
            else begin
                cfgEn0<=1'b0;
                step_i<=step_i+1; //Move to next step.
            end
        end
        else begin //iCfgByWhich=1, Configured by FPGA.
            if(!cfgDone1) begin
                cfgEn1<=1'b1;
            end
            else begin
                cfgEn1<=1'b0;
                step_i<=step_i+1; //Move to next step.
            end
        end
    end
    2: //step-2: Capture one frame and write into FIFO.
    //And Read from FIFO then write into Octal RAM simultaneously.
    begin
        if(!capFrameDone) begin
            capEn<=1'b1;
        end
        else begin
            capEn<=1'b0; 
        end

        if(!WrFrameDone) begin
            ramEn<=1'b1;
            ramCmd<=2'b01; //iCmd[1:0]=01, Burst Write.
        end
        else begin
            ramEn<=1'b0;
            //Disable Power Supply of IR Module.
            oIR_Shutdown<=1'b0;
            step_i<=step_i+1; //Move to next step.
        end
    end
    3: //step-3: //Read x bytes from Octal RAM.
    begin
        if(!dataRdRdy) begin
            ramEn<=1'b1;
            ramCmd<=2'b10;//iCmd[1:0]=10, Single Read.
        end
        else begin
            ramEn<=1'b0;
            step_i<=step_i+1; //Move to next step.
        end
    end
    4: //step-4: //Transmit x bytes out.
    begin
        if(!doneTx) begin
            enUART<=1'b1;
            enTx<=1'b1;
        end
        else begin
            enUART<=1'b0;
            enTx<=1'b0;
            step_i<=step_i+1; //Move to next step.
        end
    end
    5: //step-5: //reapeat step-3 & step-4 until one complete frame was transmit out.
    begin
        if(!RdFrameDone) begin //One Complete Frame was read out.
            step_i<=step_i+1; //Move to next step.
        end
        else begin
            step_i<=3; //Continuous to Read from OctalRAM & Transmit out.
        end
    end
    6: //step-6: All work has been done.
    begin
        OutFlag_ioIR_Data3_UPLD_Done<=1'b1;
        UPLD_Done<=1'b1; //issue Upload Done Signal.
    end
    endcase
end
endmodule
