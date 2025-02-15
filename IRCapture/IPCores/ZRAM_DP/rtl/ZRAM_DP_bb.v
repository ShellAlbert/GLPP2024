/*******************************************************************************
    Verilog netlist generated by IPGEN Lattice Radiant Software (64-bit)
    2023.1.1.200.1
    Soft IP Version: 2.2.0
    2024 08 28 15:48:34
*******************************************************************************/
/*******************************************************************************
    Wrapper Module generated per user settings.
*******************************************************************************/
module ZRAM_DP (wr_clk_i, rd_clk_i, rst_i, wr_clk_en_i, rd_en_i, rd_clk_en_i,
    wr_en_i, wr_data_i, wr_addr_i, rd_addr_i, rd_data_o)/* synthesis syn_black_box syn_declare_black_box=1 */;
    input  wr_clk_i;
    input  rd_clk_i;
    input  rst_i;
    input  wr_clk_en_i;
    input  rd_en_i;
    input  rd_clk_en_i;
    input  wr_en_i;
    input  [7:0]  wr_data_i;
    input  [12:0]  wr_addr_i;
    input  [12:0]  rd_addr_i;
    output  [7:0]  rd_data_o;
endmodule