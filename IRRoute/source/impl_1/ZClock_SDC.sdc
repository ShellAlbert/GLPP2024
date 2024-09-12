create_clock -name {clk_48MHz} -period 20.8333333333333 -waveform {0 10} [get_nets clk_48MHz]
create_clock -name {clk_Virtual_66MHz} -period 15.1515151515152 -waveform {0 7}
create_clock -name {clk_Virtual_24MHz} -period 41.6666666666667 -waveform {0 20}
set_input_delay -clock [get_clocks clk_Virtual_66MHz] -max -add_delay 3 [get_ports {iRAM_ADQ[7] iRAM_ADQ[6] iRAM_ADQ[5] iRAM_ADQ[4] iRAM_ADQ[3] iRAM_ADQ[2] iRAM_ADQ[1] iRAM_ADQ[0] iRAM_CE iRAM_CLK iRAM_DQS_DM iRAM_RST iWr_Done iWr_Req}]
set_input_delay -clock [get_clocks clk_Virtual_66MHz] -min -add_delay 1 [get_ports {iRAM_ADQ[7] iRAM_ADQ[6] iRAM_ADQ[5] iRAM_ADQ[4] iRAM_ADQ[3] iRAM_ADQ[2] iRAM_ADQ[1] iRAM_ADQ[0] iRAM_CE iRAM_CLK iRAM_DQS_DM iRAM_RST iWr_Done iWr_Req}]
set_input_delay -clock [get_clocks clk_Virtual_66MHz] -clock_fall -max -add_delay 3 [get_ports {iRAM_ADQ[7] iRAM_ADQ[6] iRAM_ADQ[5] iRAM_ADQ[4] iRAM_ADQ[3] iRAM_ADQ[2] iRAM_ADQ[1] iRAM_ADQ[0] iRAM_CE iRAM_CLK iRAM_RST iWr_Done iWr_Req iRAM_DQS_DM}]
set_input_delay -clock [get_clocks clk_Virtual_66MHz] -clock_fall -min -add_delay 1 [get_ports {iRAM_CE iRAM_ADQ[7] iRAM_ADQ[6] iRAM_ADQ[5] iRAM_ADQ[4] iRAM_ADQ[3] iRAM_ADQ[2] iRAM_ADQ[1] iRAM_ADQ[0] iRAM_CLK iRAM_RST iRAM_DQS_DM iWr_Done iWr_Req}]
set_output_delay -clock [get_clocks clk_48MHz] -max -add_delay 2 [get_ports {ioPSRAM_ADQ[7] ioPSRAM_ADQ[6] ioPSRAM_ADQ[5] ioPSRAM_ADQ[4] ioPSRAM_ADQ[3] ioPSRAM_ADQ[2] ioPSRAM_ADQ[1] ioPSRAM_ADQ[0] ioPSRAM_DQS_DM oPSRAM_CE oPSRAM_CLK oPSRAM_RST}]
set_output_delay -clock [get_clocks clk_48MHz] -min -add_delay 1 [get_ports {ioPSRAM_ADQ[7] ioPSRAM_ADQ[6] ioPSRAM_ADQ[5] ioPSRAM_ADQ[4] ioPSRAM_ADQ[3] ioPSRAM_ADQ[2] ioPSRAM_ADQ[1] ioPSRAM_ADQ[0] ioPSRAM_DQS_DM oPSRAM_CE oPSRAM_CLK oPSRAM_RST}]
set_output_delay -clock [get_clocks clk_48MHz] -clock_fall -max -add_delay 2 [get_ports {ioPSRAM_ADQ[7] ioPSRAM_ADQ[6] ioPSRAM_ADQ[5] ioPSRAM_ADQ[4] ioPSRAM_ADQ[3] ioPSRAM_ADQ[2] ioPSRAM_ADQ[1] ioPSRAM_ADQ[0] ioPSRAM_DQS_DM oPSRAM_CE oPSRAM_CLK}]
set_output_delay -clock [get_clocks clk_48MHz] -clock_fall -min -add_delay 1 [get_ports {ioPSRAM_ADQ[7] ioPSRAM_ADQ[6] ioPSRAM_ADQ[5] ioPSRAM_ADQ[4] ioPSRAM_ADQ[3] ioPSRAM_ADQ[2] ioPSRAM_ADQ[1] ioPSRAM_ADQ[0] ioPSRAM_DQS_DM oPSRAM_CE oPSRAM_CLK oPSRAM_RST}]
set_input_delay -clock [get_clocks clk_Virtual_24MHz] -max -add_delay 1 [get_ports ioPSRAM_DQS_DM]
