create_clock -name {clk_48MHz} -period 20.8333333333333 [get_nets clk_48MHz]
create_clock -name {ic_pll/lscc_pll_inst/outglobalb_o} -period 8.33333333333333 [get_nets ic_pll/lscc_pll_inst/outglobalb_o]
set_input_delay -clock [get_clocks ic_pll/lscc_pll_inst/outglobalb_o] 10 [all_inputs]
set_output_delay -clock [get_clocks ic_pll/lscc_pll_inst/outglobalb_o] 10 [all_outputs]
