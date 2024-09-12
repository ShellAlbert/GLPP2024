`timescale 1ps/1ps
module ZIRStore_Bottom(
    input iClk,
    input iRst_N,

	output reg oLED1,
	output reg oLED2,
    
    //IO Multiplex
    //0: DB_IO_0 -> CFG_SPI_D0, DB_IO_1 -> CFG_SPI_D2, DB_IO_2 -> CFG_SPI_D1, DB_IO_3 -> CFG_SPI_D3
    //1: DB_IO_0 -> IR_UART_TX, DB_IO_1 -> IR_UART_RX, DB_IO_2 -> UPLD_UART_TX, DB_IO_3 -> UPLD_UART_RX
	output reg oIOMux,
    //IR Configure UART Interface.
	output oIR_UART_TxD,
    input iIR_UART_RxD,

	//Octal RAM Interface.
	output oPSRAM_RST, //RESET# : Input Reset signal, active low. 
	output oPSRAM_CE, //CE#: Input, Chip select, active low. When CE#=1, chip is in standby state. 
	//output oPSRAM_CLK,
	//DQS, IO.
	//DQ Strobe clock for DQ[7:0] during all reads.
	//Data mask for DQ[7:0] during memory writes.
	//DM is active HIGH, DM=1 means "do not write".
	inout ioPSRAM_DQS,
	inout [7:0] ioPSRAM_DATA, //Address/Data bus [7:0].

    //Using CFG_SPI_CS(37) to flywire as Debug UART TxD.
    output oDbgUART_TxD
);

/////////////////////////////////////////
reg IRSensor_En;
reg [2:0] IRSensor_OpReq;
wire IRSensor_OpDone;
ZIRSensor_Controller ic_IRSensor_Controller(
    .iClk(iClk),
    .iRst_N(iRst_N),
    .iEn(IRSensor_En),

    //Interactive Interface.
    //iOp_Req=0, idle.
    //iOp_Req=1, Select CDS3 Interface & Save.
    .iOp_Req(IRSensor_OpReq),
    .oOp_Done(IRSensor_OpDone),

    //Physical Pins.
    .iIR_UART_RxD(iIR_UART_RxD),
    .oIR_UART_TxD(oIR_UART_TxD)
);
////////////////////////////////////////////////////////
//Debug UART Tx.
reg [7:0] Dbg_UART_Tx_DR; //Tx Data Register.
reg Dbg_UART_Tx_En;
wire Dbg_UART_Tx_Done;
//generate 2MHz Clock. 
//48MHz/2MHz=24.
ZUART_Tx #(.Freq_divider(24)) ic_DBG_UART_Tx 
(
	.iClk(iClk),
	.iRst_N(iRst_N),
	.iData(Dbg_UART_Tx_DR),

	//pull down iEn to start transmition until pulse done oDone was issued.
	.iEn(Dbg_UART_Tx_En),
	.oDone(Dbg_UART_Tx_Done),
	.oTxD(oDbgUART_TxD)
);
/////////////////////////////////////////////////////
//Embedded Block RAM 4K.
//Write Signals.
wire EBR_Wr_En;
wire [15:0] EBR_Wr_Data;
wire [9:0] EBR_Wr_Addr;
//Read Signals.
reg EBR_Rd_En;
wire [15:0] EBR_Rd_Data; 
reg [9:0] EBR_Rd_Addr;

ZRAM_DP ic_RAM_DP(
		.wr_clk_i(iClk),  //I, write clock.
		.rd_clk_i(iClk),  //I, read clock.
		.rst_i(!iRst_N), //I, reset.
		.wr_clk_en_i(EBR_Wr_En), //I, Write Clock Enable.
		.rd_en_i(EBR_Rd_En), //I, Read Enable.
		.rd_clk_en_i(EBR_Rd_En), //I, Read Clock Enable. 
		.wr_en_i(EBR_Wr_En), //I, Write Enable.
		.wr_data_i(EBR_Wr_Data), //I, write data to RAM. 
		.wr_addr_i(EBR_Wr_Addr), //I, write address to RAM.
		.rd_addr_i(EBR_Rd_Addr), //I, Read Address from RAM.
		.rd_data_o(EBR_Rd_Data) //O, Read Data from RAM.
); 
///////////////////////////////////////////////////////
//Clock Domain Crossing
reg [2:0] Op_Code;
wire Op_Done;
/////////////////////////////////////////////////////////
//Octal RAM Interface.
reg [31:0] ram_Addr;
reg [15:0] ram_Data_i;
wire [15:0] ram_Data_o;
ZOctalRAMOperator ic_OctalRAM(
	.iClk(iClk),
	.iRst_N(iRst_N),
	//iOp_Code=0: Idle.
	//iOp_Code=1: Reset IC.
	//iOp_Code=2: Write Mode Register.
	//iOp_Code=3: Read Mode Register and write to EBR 4K.
	//iOp_Code=4: Sync Write, iAddress[31:0], iData[15:0].
	//iOp_Code=5: Sync Read, iAddress[31:0], oData[15:0].
	.iOp_Code(Op_Code),
	.oOp_Done(Op_Done),

	.iAddress(ram_Addr),
	.iData(ram_Data_i),
	.oData(ram_Data_o),

	//Octal RAM/EEPROM Interface.
	.oPSRAM_RST(oPSRAM_RST), //RESET# : Input Reset signal, active low. 
	.oPSRAM_CE(oPSRAM_CE), //CE#: Input, Chip select, active low. When CE#=1, chip is in standby state. 
	//.oPSRAM_CLK(oPSRAM_CLK),
	.ioPSRAM_DQS_DM(ioPSRAM_DQS),
	.ioPSRAM_DATA(ioPSRAM_DATA),

	//Embedded Block RAM Interface.
	.oEBR_Wr_En(EBR_Wr_En),
	.oEBR_Wr_Data(EBR_Wr_Data),
	.oEBR_Wr_Addr(EBR_Wr_Addr)
);

//EBR Space Assignment
//0x0~0x3: Fixed Bytes.
//0x4~0x9: Mode Register 0,1,2,3,4,8 Readback.
//0xA~0xx: Memory Readback.
///////////////////////////////////////
reg [7:0] CNT_Rising;
reg [31:0] CNT_Delay;
reg [15:0] Temp_DR; //Temporary Data Register.
reg [9:0] CNT_Addr; //EBR 4K Address Index.
reg [15:0] UPLD_DR; //Upload Data Register.
reg upload_done;
always @(posedge iClk or negedge iRst_N)
if(!iRst_N) begin
    CNT_Rising<=0; CNT_Delay<=0;
    //IO Multiplex
    //1: DB_IO_0 -> IR_UART_TX, DB_IO_1 -> IR_UART_RX, DB_IO_2 -> UPLD_UART_TX, DB_IO_3 -> UPLD_UART_RX
    oIOMux<=1; oLED1<=0; oLED2<=0;
    
    Op_Code<=0; CNT_Addr<=0;
    /////////////////
    ram_Addr<=0; ram_Data_i<=0;
    ////////////////
    EBR_Rd_En<=0; EBR_Rd_Addr<=0;
end
else begin
    case(CNT_Rising)
        0: //Configure IR Sensor, should be removed before distribution.
            //ONLY NEED TO CONFIGURE ONCE,
            //Yantai InfiRay IR Image Sensor ELF3 Module will save configuration.
            //if(IRSensor_OpDone) begin IRSensor_En<=0; CNT_Rising<=CNT_Rising+1; end
            //else begin IRSensor_OpReq<=1; IRSensor_En<=1; end       
        
            //48MHz=32'h2DC6C00
            //if(CNT_Delay==32'h2DC6C00) begin CNT_Delay<=0; CNT_Rising<=CNT_Rising+1; end  //in Radiant.
            if(CNT_Delay==3) begin CNT_Delay<=0; CNT_Rising<=CNT_Rising+1; end //in ModelSim.
            else begin CNT_Delay<=CNT_Delay+1; end
//////////////////////////////////////////////////////////////////////////////////////////
        1: //iOp_Code=1: Reset IC. //Takes up EBR Address Range: 0~3.
            if(Op_Done) begin Op_Code<=0; CNT_Rising<=CNT_Rising+1; end
            else begin Op_Code<=1; end
///////////////////////////////////////////////////////////////////////////////////////////
        2: //iOp_Code=2: Write Mode Register.
            if(Op_Done) begin Op_Code<=0; CNT_Rising<=CNT_Rising+1; end
            else begin Op_Code<=2; end

        3: //iOp_Code=3: Read Mode Register and write to EBR. //Takes up EBR Address Range:4~9.
            if(Op_Done) begin Op_Code<=0; CNT_Addr<=0; CNT_Rising<=CNT_Rising+1; end
            else begin Op_Code<=3; end
            //begin CNT_Rising<=CNT_Rising+1; end
////////////////////////////////////////////////////////////////////////////////////
        4: //iOp_Code=4: Sync Write, iAddress[31:0], iData[15:0].
            // if(Op_Done) begin Op_Code<=0; CNT_Rising<=CNT_Rising+1; end
            // else begin Op_Code<=4; ram_Addr<=4; ram_Data_i<=16'h1987; end
        begin CNT_Rising<=CNT_Rising+1; end

        5: //iOp_Code=5: Sync Read, iAddress[31:0], oData[15:0]. //Takes up EBR Address Range:10,11.
            // if(Op_Done) begin Op_Code<=0; CNT_Addr<=0; CNT_Rising<=CNT_Rising+1; end
            // else begin Op_Code<=5; ram_Addr<=4; end
        begin CNT_Rising<=CNT_Rising+1; end
//////////////////////////////////////////////////////////////////////////////////////
        6: //Read data from EBR. //Sample data at falling edge of this clock.
            begin EBR_Rd_En<=1; EBR_Rd_Addr<=CNT_Addr; CNT_Rising<=CNT_Rising+1; end
        7: //Waiting for upload done.
            if(upload_done) begin CNT_Rising<=CNT_Rising+1; end 
        8: //Loop to read all EBR data.
            if(CNT_Addr==60) begin CNT_Addr<=0; CNT_Rising<=CNT_Rising+1; end
            else begin CNT_Addr<=CNT_Addr+1; CNT_Rising<=CNT_Rising-2; end
    //////////////////////////////////////////////////////////////////////////////////////
        9: //Loop to read 5 times.
            if(CNT_Delay==0) begin CNT_Delay<=0; CNT_Rising<=CNT_Rising+1; end
            else begin CNT_Delay<=CNT_Delay+1; CNT_Rising<=CNT_Rising-3; end
///////////////////////////////////////////////////////////////////////////////////
        10: //Stop here.
            begin oLED1<=1; end
        
        21: //retry after 1s. //using less time in ModelSim.
            if(CNT_Delay==32'h5B8D800) begin CNT_Delay<=0; CNT_Rising<=15; end //Enable this line in Radiant.
            //if(CNT_Delay==3) begin CNT_Delay<=0; CNT_Rising<=15; end //Enable this line in ModelSim.
            else begin CNT_Delay<=CNT_Delay+1; end

        22: //Configure done, Flash LED. //48MHz='h2DC6C00,/2='h16E3600,/2='hB71B00
            begin oLED1<=~oLED1; CNT_Rising<=CNT_Rising+1; end
        23: //Delay.
            if(CNT_Delay==32'h2DC6C00) begin CNT_Delay<=0; CNT_Rising<=CNT_Rising+1; end
            else begin CNT_Delay<=CNT_Delay+1; end
        24:
            begin CNT_Rising<=CNT_Rising-2; end
    endcase
end
/////////////////////////////////////////////////////////////////////////
reg [7:0] CNT_Falling;
reg [15:0] Temp_Data_Falling;
//bypass the first data output from EBR.
//EBR output data will delay 1 clock.
reg bypass_1st; 
always @(negedge iClk or negedge iRst_N)
if(!iRst_N) begin
    Temp_Data_Falling<=0;
    upload_done<=0;
    CNT_Falling<=0;
    bypass_1st<=0;
end
else begin
        case(CNT_Rising)
            6: //Sample data at falling edge of this clock.
                begin Temp_Data_Falling<=EBR_Rd_Data; end
            7: //Waiting for upload done.
                if(!bypass_1st) begin
                    bypass_1st<=1;
                    upload_done<=1; 
                end
                else begin 
                        case(CNT_Falling)
                            0: 
                                if(Dbg_UART_Tx_Done) begin Dbg_UART_Tx_En<=0; CNT_Falling<=CNT_Falling+1; end
                                    else begin Dbg_UART_Tx_En<=1; Dbg_UART_Tx_DR<=Temp_Data_Falling[15:8]; end
                            1:
                                if(Dbg_UART_Tx_Done) begin Dbg_UART_Tx_En<=0; CNT_Falling<=CNT_Falling+1; end
                                    else begin Dbg_UART_Tx_En<=1; Dbg_UART_Tx_DR<=Temp_Data_Falling[7:0]; end
                            2:
                                begin upload_done<=1; CNT_Falling<=0; end
                            default:
                                begin CNT_Falling<=0; end
                        endcase
                end
            8: //Loop to read all EBR 4K data.
                begin upload_done<=0; end
        endcase
end



/*
//EBR Test Successfully! 
//EBR Must Sample data at Falling Edge !!!
reg [9:0] Temp_Addr;
reg [15:0] Temp_Data;
reg tx_done;
always @(posedge iClk or negedge iRst_N)
if(!iRst_N) begin
    CNT_Rising<=0; CNT_Delay<=0;
    EBR_Wr_En<=0; EBR_Rd_En<=0;
    
    Temp_Data<=1; //initial value.
    Temp_Addr<=0;

    oLED1<=0;
end
else begin
    case(CNT_Rising)
        0: //Must delay for a while after power on, otherwise data will incorrect !!!
            if(CNT_Delay==32'h2DC6C01) begin CNT_Delay<=0; CNT_Rising<=CNT_Rising+1; end
            else begin CNT_Delay<=CNT_Delay+1; end

        1: //Write data.
            begin EBR_Wr_En<=1; EBR_Wr_Data<=Temp_Data; EBR_Wr_Addr<=Temp_Addr; CNT_Rising<=CNT_Rising+1; end
        2: //Loop to write.
            if(Temp_Addr==512) begin Temp_Addr<=0; CNT_Rising<=CNT_Rising+1; end
            else begin Temp_Addr<=Temp_Addr+1; Temp_Data<=Temp_Data+1; CNT_Rising<=CNT_Rising-1; end
        3: //stop writing.
            begin EBR_Wr_En<=0; CNT_Rising<=CNT_Rising+1; end

        4: //Read data.
            begin EBR_Rd_En<=1; EBR_Rd_Addr<=Temp_Addr; CNT_Rising<=CNT_Rising+1; end
        5: //Sample data at falling edge of this clock.
            begin CNT_Rising<=CNT_Rising+1; end
        6: //Waiting for txdone.
            if(tx_done) begin CNT_Rising<=CNT_Rising+1; end 
        7: //Loop to read.
            if(Temp_Addr==512) begin Temp_Addr<=0; CNT_Rising<=CNT_Rising+1; end
            else begin Temp_Addr<=Temp_Addr+1; CNT_Rising<=CNT_Rising-3; end
        8: //stop reading.
            begin EBR_Rd_En<=0; CNT_Rising<=CNT_Rising+1; end
        9:
            begin oLED1<=1; CNT_Rising<=CNT_Rising; end
    endcase
end

reg [7:0] CNT_Falling;
reg [15:0] Temp_Data_Falling;
//bypass the first data output from EBR.
//EBR output data will delay 1 clock.
reg bypass_1st; 
always @(negedge iClk or negedge iRst_N)
if(!iRst_N) begin
    Temp_Data_Falling<=0;
    tx_done<=0;
    CNT_Falling<=0;
    bypass_1st<=0;
end
else begin
        case(CNT_Rising)
        5: //Sample data at falling edge of this clock.
            begin Temp_Data_Falling<=EBR_Rd_Data; end
        6: //Waiting for txdone.
            if(!bypass_1st) begin
                bypass_1st<=1;
                tx_done<=1; 
            end
            else begin 
                    case(CNT_Falling)
                        0: 
                            if(Dbg_UART_Tx_Done) begin Dbg_UART_Tx_En<=0; CNT_Falling<=CNT_Falling+1; end
                                else begin Dbg_UART_Tx_En<=1; Dbg_UART_Tx_DR<=Temp_Data_Falling[15:8]; end
                        1:
                            if(Dbg_UART_Tx_Done) begin Dbg_UART_Tx_En<=0; CNT_Falling<=CNT_Falling+1; end
                                else begin Dbg_UART_Tx_En<=1; Dbg_UART_Tx_DR<=Temp_Data_Falling[7:0]; end

                        2: //Send fixed data to ensure UART communication is correct.
                            if(Dbg_UART_Tx_Done) begin Dbg_UART_Tx_En<=0; CNT_Falling<=CNT_Falling+1; end
                            else begin Dbg_UART_Tx_En<=1; Dbg_UART_Tx_DR<=8'h66; end
                        3:
                            if(Dbg_UART_Tx_Done) begin Dbg_UART_Tx_En<=0; CNT_Falling<=CNT_Falling+1; end
                                else begin Dbg_UART_Tx_En<=1; Dbg_UART_Tx_DR<=8'h88; end
                        4:
                            begin tx_done<=1; CNT_Falling<=0; end
                        default:
                            begin CNT_Falling<=0; end
                    endcase
            end
        7:
            begin tx_done<=0; end
        endcase
end
*/
endmodule