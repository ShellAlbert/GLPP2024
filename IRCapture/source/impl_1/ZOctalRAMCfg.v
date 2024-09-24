`timescale 1ps/1ps

module ZOctalRAMCfg(
    input [7:0] iNo,
    output reg [7:0] oRegAddr,
    output reg [7:0] oRegData
);

always @(*)
begin
    case(iNo)
        0:
            //Mode Register Address, MA[7:0]='h00; 
            //[OP7:OP6]=00, [OP5]=0,Latency Type,variable. [OP4:OP2]=010(Read Latency=5~10), 133MHz. [OP1:OP0]=00, Drive Strength, Full(25-OHMS default).
            //00_0_010_00=0x08 

            //In order to control Memory-Read Latency, we set Latency Type to Fixed.
            //[OP7:OP6]=00, [OP5]=1,Latency Type,Fixed. [OP4:OP2]=010(Read Latency=10), 133MHz. [OP1:OP0]=00, Drive Strength, Full(25-OHMS default).
            //00_1_010_00=0x28 (This is Active.)

            //[OP7:OP6]=00, [OP5]=1,Latency Type,Fixed. [OP4:OP2]=000(Read Latency=6), 66MHz. [OP1:OP0]=00, Drive Strength, Full(25-OHMS default).
            //00_1_000_00=0x20
            begin oRegAddr=8'h00; oRegData=8'h28; end
        1: 
            //Mode Register Address, MA[7:0]='h04; 
            //Write Latency Code, [OP7:OP5]=010(Write Latency=5), Refresh Frequency Rate, [OP4:OP3]=00, PASR, [OP2:OP0]=000
            //010_00_000=0x40 (This is Active.)

            //I changed this configuration to see if Mode Register Write&Read was succeed.
            //Write Latency Code, [OP7:OP5]=010(Write Latency=5), Refresh Frequency Rate, [OP4:OP3]=00, PASR, [OP2:OP0]=111
            //010_00_111=0x47

            //Write Latency Code, [OP7:OP5]=000(Write Latency=3), Refresh Frequency Rate, [OP4:OP3]=00, PASR, [OP2:OP0]=000
            //000_00_000=0x00
            begin oRegAddr=8'h04; oRegData=8'h40; end
        2: 
            //Mode Register Address, MA[7:0]='h06; 
            //Half Sleep, [OP7:OP0]='hF0
            begin oRegAddr=8'h06; oRegData=8'hF0; end
        3:
            //Mode Register Address, MA[7:0]='h08; 
            //[OP7]=0, [OP6]=0, [OP5:OP4]=rsvd, [OP3]=RBX, [OP2]=Burst Type, [OP1:OP0]=Burst Length.
            //2K Byte Wrap, [2,1:0]=111.
            //Note that Linear Burst commands, 20h and A0h, ignore burst setting defined by MR8[2:0]. 
            //Note that only Linear Burst Read command is capable of performing row boundary crossing (RBX) read function.  
        
            //This register setting applies to Linear Burst reads only on RBX enabled devices (MR3[7]=1).  
            //Default write and read burst behavior is limited within 2K page (row) address space (CA=’h000 -> ‘h7FF). 
            //Setting this bit high will allow Linear Burst Read command to cross over into the next Row (RA+1).
            //MR8[3]=1, Allow reads cross page (row) boundary.

            //0_0_xx_1_1_11
            begin oRegAddr=8'h08; oRegData=8'h0F; end
        ////////////////////////////////////////////////////////////////////////
        //MA: Read Mode Register Address.
        4:
            begin oRegAddr=8'h00; oRegData=8'h00; end
        5:
            begin oRegAddr=8'h01; oRegData=8'h00; end         
        6:
            begin oRegAddr=8'h02; oRegData=8'h00; end
        7:
            begin oRegAddr=8'h03; oRegData=8'h00; end   
        8:
            begin oRegAddr=8'h04; oRegData=8'h00; end   
        9:
            begin oRegAddr=8'h08; oRegData=8'h00; end   
        default:
            begin oRegAddr=0; oRegData=0; end
    endcase
end
endmodule