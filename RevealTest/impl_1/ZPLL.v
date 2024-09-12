// Verilog netlist produced by program LSE 
// Netlist written on Wed Sep  4 08:30:40 2024
// Source file index table: 
// Object locations will have the form @<file_index>(<first_ line>[<left_column>],<last_line>[<right_column>])
// file 0 "f:/mysoftware/lattice/radiant/ip/avant/fifo/rtl/lscc_fifo.v"
// file 1 "f:/mysoftware/lattice/radiant/ip/avant/fifo_dc/rtl/lscc_fifo_dc.v"
// file 2 "f:/mysoftware/lattice/radiant/ip/avant/ram_dp/rtl/lscc_ram_dp.v"
// file 3 "f:/mysoftware/lattice/radiant/ip/avant/ram_dq/rtl/lscc_ram_dq.v"
// file 4 "f:/mysoftware/lattice/radiant/ip/avant/rom/rtl/lscc_rom.v"
// file 5 "f:/mysoftware/lattice/radiant/ip/common/adder/rtl/lscc_adder.v"
// file 6 "f:/mysoftware/lattice/radiant/ip/common/adder_subtractor/rtl/lscc_add_sub.v"
// file 7 "f:/mysoftware/lattice/radiant/ip/common/complex_mult/rtl/lscc_complex_mult.v"
// file 8 "f:/mysoftware/lattice/radiant/ip/common/counter/rtl/lscc_cntr.v"
// file 9 "f:/mysoftware/lattice/radiant/ip/common/mult_accumulate/rtl/lscc_mult_accumulate.v"
// file 10 "f:/mysoftware/lattice/radiant/ip/common/mult_add_sub/rtl/lscc_mult_add_sub.v"
// file 11 "f:/mysoftware/lattice/radiant/ip/common/mult_add_sub_sum/rtl/lscc_mult_add_sub_sum.v"
// file 12 "f:/mysoftware/lattice/radiant/ip/common/multiplier/rtl/lscc_multiplier.v"
// file 13 "f:/mysoftware/lattice/radiant/ip/common/subtractor/rtl/lscc_subtractor.v"
// file 14 "f:/mysoftware/lattice/radiant/ip/pmi/pmi_add.v"
// file 15 "f:/mysoftware/lattice/radiant/ip/pmi/pmi_addsub.v"
// file 16 "f:/mysoftware/lattice/radiant/ip/pmi/pmi_complex_mult.v"
// file 17 "f:/mysoftware/lattice/radiant/ip/pmi/pmi_counter.v"
// file 18 "f:/mysoftware/lattice/radiant/ip/pmi/pmi_dsp.v"
// file 19 "f:/mysoftware/lattice/radiant/ip/pmi/pmi_fifo.v"
// file 20 "f:/mysoftware/lattice/radiant/ip/pmi/pmi_fifo_dc.v"
// file 21 "f:/mysoftware/lattice/radiant/ip/pmi/pmi_mac.v"
// file 22 "f:/mysoftware/lattice/radiant/ip/pmi/pmi_mult.v"
// file 23 "f:/mysoftware/lattice/radiant/ip/pmi/pmi_multaddsub.v"
// file 24 "f:/mysoftware/lattice/radiant/ip/pmi/pmi_multaddsubsum.v"
// file 25 "f:/mysoftware/lattice/radiant/ip/pmi/pmi_ram_dp.v"
// file 26 "f:/mysoftware/lattice/radiant/ip/pmi/pmi_ram_dp_be.v"
// file 27 "f:/mysoftware/lattice/radiant/ip/pmi/pmi_ram_dq.v"
// file 28 "f:/mysoftware/lattice/radiant/ip/pmi/pmi_ram_dq_be.v"
// file 29 "f:/mysoftware/lattice/radiant/ip/pmi/pmi_rom.v"
// file 30 "f:/mysoftware/lattice/radiant/ip/pmi/pmi_sub.v"
// file 31 "f:/mysoftware/lattice/radiant/cae_library/simulation/verilog/ice40up/ccu2_b.v"
// file 32 "f:/mysoftware/lattice/radiant/cae_library/simulation/verilog/ice40up/fd1p3bz.v"
// file 33 "f:/mysoftware/lattice/radiant/cae_library/simulation/verilog/ice40up/fd1p3dz.v"
// file 34 "f:/mysoftware/lattice/radiant/cae_library/simulation/verilog/ice40up/fd1p3iz.v"
// file 35 "f:/mysoftware/lattice/radiant/cae_library/simulation/verilog/ice40up/fd1p3jz.v"
// file 36 "f:/mysoftware/lattice/radiant/cae_library/simulation/verilog/ice40up/hsosc.v"
// file 37 "f:/mysoftware/lattice/radiant/cae_library/simulation/verilog/ice40up/hsosc1p8v.v"
// file 38 "f:/mysoftware/lattice/radiant/cae_library/simulation/verilog/ice40up/ib.v"
// file 39 "f:/mysoftware/lattice/radiant/cae_library/simulation/verilog/ice40up/ifd1p3az.v"
// file 40 "f:/mysoftware/lattice/radiant/cae_library/simulation/verilog/ice40up/lsosc.v"
// file 41 "f:/mysoftware/lattice/radiant/cae_library/simulation/verilog/ice40up/lsosc1p8v.v"
// file 42 "f:/mysoftware/lattice/radiant/cae_library/simulation/verilog/ice40up/ob.v"
// file 43 "f:/mysoftware/lattice/radiant/cae_library/simulation/verilog/ice40up/obz_b.v"
// file 44 "f:/mysoftware/lattice/radiant/cae_library/simulation/verilog/ice40up/ofd1p3az.v"
// file 45 "f:/mysoftware/lattice/radiant/cae_library/simulation/verilog/ice40up/pdp4k.v"
// file 46 "f:/mysoftware/lattice/radiant/cae_library/simulation/verilog/ice40up/rgb.v"
// file 47 "f:/mysoftware/lattice/radiant/cae_library/simulation/verilog/ice40up/rgb1p8v.v"
// file 48 "f:/mysoftware/lattice/radiant/cae_library/simulation/verilog/ice40up/sp256k.v"
// file 49 "f:/mysoftware/lattice/radiant/cae_library/simulation/verilog/ice40up/legacy.v"

//
// Verilog Description of module ZPLL
// module wrapper written out since it is a black-box. 
//

//

module ZPLL (ref_clk_i, rst_n_i, lock_o, outcore_o, outglobal_o) /* synthesis cpe_box=1 */ ;
    input ref_clk_i;
    input rst_n_i;
    output lock_o;
    output outcore_o;
    output outglobal_o;
    
    
    
endmodule
