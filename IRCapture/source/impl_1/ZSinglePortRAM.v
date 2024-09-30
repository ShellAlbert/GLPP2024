`timescale 1ps/1ps
module ZSinglePortRAM(
    input iClk, //I, Clock.
    input iRst_N,

    input iWr_Which, //I, Write which SPRAM:0/1/2/3.

    //Write Operation from CDS3_Capture.
    input [13:0] iWr_Addr, //I, Write Address.
    input [15:0] iWr_Data, //I, Write Data.
    input iWr_En, //I, Write Enable. 1:Write, 0:Read.

    //Read Port from DDR_Writer.
    input [13:0] iRd_Addr, //I, Read Address.
    input iRd_En, //I, Read Enable. 1:Write, 0:Read.
    output reg [15:0] oRd_Data //O, Read out Data.
);

/////////////////////////////////////////////////////////
//Each SPRAM block is 256 kb, supporting configuration that are 16K x 16.
//These memories are cascaded to form larger memory based on the user requirements.
//Address Cascading or Data Cascading.
reg [13:0] SP_RAM0_Addr; //(2^14)/1024=16K.
reg [15:0] SP_RAM0_WrDR;
reg SP_RAM0_En; //1:Write, 0:Read.
wire [15:0] SP_RAM0_RdDR;
SP256K SP_RAM0(
//This Address Input port is used to address the location to be written during the write cycle and read during the read cycle. 
  .AD       (SP_RAM0_Addr),  // I, Address Input.
//The Data Input bus is used to write the data into the memory location specified by Address input port during the write cycle. 
  .DI       (SP_RAM0_WrDR),  // I, Data Input Bus.
//It includes the Bit Write feature where selective write to individual I/O can be done using the Maskable Write Enable signals. 
//When the memory is in write cycle, one can write selectively on some I/O. 
//The default value of each MASKWREN is 1. In order to mask a nibble of DATAIN, the MASKWREN needs to be pulled low (0). 
  .MASKWE   (4'b1111),  // I, Mask Write Enable.
//When the Write Enable input is Logic High, the memory is in the write cycle.  
//When the Write Enable is Logic Low, the memory is in the read cycle. 
  .WE       (SP_RAM0_En),  // I, Write Enable.
//When the memory enable input is Logic High, the memory is enabled and read/write operations can be performed. 
//When memory enable input is logic Low, the memory is deactivated. 
  .CS       (1'b1),  // I, Chip Select.
//This is the external clock for the memory.
  .CK       (iClk),  // I, Clock.
//When this pin is active then memory goes into low leakage mode, there is no change in the output state. 
  .STDBY    (1'b0),  // I, Standby.
//This pin shuts down power to periphery and maintains memory contents.  
//The outputs of the memory are pulled low. 
  .SLEEP    (1'b0),  // I, Sleep.
//This pin turns off the power to the memory core. 
//Note that there is no memory data retention when this is driven low.
  .PWROFF_N (1'b1),  // I, Power OfF.
//This pin outputs the contents of the memory location addressed by the address Input signals.
  .DO       (SP_RAM0_RdDR)   // O, Data Output Bus.
);
////////////////////////////////////////////////////////////////////////////////////////////
reg [13:0] SP_RAM1_Addr;
reg [15:0] SP_RAM1_WrDR;
reg SP_RAM1_En; //1:Write, 0:Read.
wire [15:0] SP_RAM1_RdDR;
SP256K SP_RAM1(
  .AD       (SP_RAM1_Addr),  // I, Address Input.
  .DI       (SP_RAM1_WrDR),  // I, Data Input Bus.
  .MASKWE   (4'b1111),  // I, Mask Write Enable.
  .WE       (SP_RAM1_En),  // I, Write Enable.
  .CS       (1'b1),  // I, Chip Select.
  .CK       (iClk),  // I, Clock.
  .STDBY    (1'b0),  // I, Standby.
  .SLEEP    (1'b0),  // I, Sleep.
  .PWROFF_N (1'b1),  // I, Power OfF.
  .DO       (SP_RAM1_RdDR)   // O, Data Output Bus.
);
////////////////////////////////////////////////////////////////
reg [13:0] SP_RAM2_Addr;
reg [15:0] SP_RAM2_WrDR;
reg SP_RAM2_En;
wire [15:0] SP_RAM2_RdDR;
SP256K SP_RAM2(
  .AD       (SP_RAM2_Addr),  // I, Address Input.
  .DI       (SP_RAM2_WrDR),  // I, Data Input Bus.
  .MASKWE   (4'b1111),  // I, Mask Write Enable.
  .WE       (SP_RAM2_En),  // I, Write Enable.
  .CS       (1'b1),  // I, Chip Select.
  .CK       (iClk),  // I, Clock.
  .STDBY    (1'b0),  // I, Standby.
  .SLEEP    (1'b0),  // I, Sleep.
  .PWROFF_N (1'b1),  // I, Power OfF.
  .DO       (SP_RAM2_RdDR)   // O, Data Output Bus.
);
///////////////////////////////////////////////////////////////////
reg [13:0] SP_RAM3_Addr;
reg [15:0] SP_RAM3_WrDR;
reg SP_RAM3_En;
wire [15:0] SP_RAM3_RdDR;
SP256K SP_RAM3(
  .AD       (SP_RAM3_Addr),  // I, Address Input.
  .DI       (SP_RAM3_WrDR),  // I, Data Input Bus.
  .MASKWE   (4'b1111),  // I, Mask Write Enable.
  .WE       (SP_RAM3_En),  // I, Write Enable.
  .CS       (1'b1),  // I, Chip Select.
  .CK       (iClk),  // I, Clock.
  .STDBY    (1'b0),  // I, Standby.
  .SLEEP    (1'b0),  // I, Sleep.
  .PWROFF_N (1'b1),  // I, Power OfF.
  .DO       (SP_RAM3_RdDR)   // O, Data Output Bus.
);

/////////////////////////////////////////////////////////////////////////////////////////////
//Exclusive Writing & Reading.
//Can't write and read one SPRAM simultaneously.
// always @(*) begin 
//   case(iWr_Which)
//       0: //Write 0, Read 1.
//           begin 
//             SP_RAM0_Addr=iWr_Addr; SP_RAM0_En=iWr_En; SP_RAM0_WrDR=iWr_Data; 
//             SP_RAM1_Addr=iRd_Addr; SP_RAM1_En=iRd_En; oRd_Data=SP_RAM1_RdDR; 
//           end
//       1: //Write 1, Read 0.
//           begin 
//             SP_RAM1_Addr=iWr_Addr; SP_RAM1_En=iWr_En; SP_RAM1_WrDR=iWr_Data;
//             SP_RAM0_Addr=iRd_Addr; SP_RAM0_En=iRd_En; oRd_Data=SP_RAM0_RdDR; 
//           end
//   endcase
// end
always @(posedge iClk or negedge iRst_N) 
if(!iRst_N) begin
  //Write 0, Read 1.
  SP_RAM0_Addr<=iWr_Addr; SP_RAM0_En<=iWr_En; SP_RAM0_WrDR<=iWr_Data; 
  SP_RAM1_Addr<=iRd_Addr; SP_RAM1_En<=iRd_En; oRd_Data<=SP_RAM1_RdDR; 
end
else begin
  case(iWr_Which)
    0: //Write 0, Read 1.
          begin 
            SP_RAM0_Addr<=iWr_Addr; SP_RAM0_En<=iWr_En; SP_RAM0_WrDR<=iWr_Data; 
            SP_RAM1_Addr<=iRd_Addr; SP_RAM1_En<=iRd_En; oRd_Data<=SP_RAM1_RdDR; 
          end
    1: //Write 1, Read 0.
          begin 
            SP_RAM1_Addr<=iWr_Addr; SP_RAM1_En<=iWr_En; SP_RAM1_WrDR<=iWr_Data;
            SP_RAM0_Addr<=iRd_Addr; SP_RAM0_En<=iRd_En; oRd_Data<=SP_RAM0_RdDR; 
          end
  endcase
end
endmodule
