#-- Lattice Semiconductor Corporation Ltd.
#-- Synplify OEM project file

#device options
set_option -technology SBTICE40UP
set_option -part iCE40UP5K
set_option -package SG48I
set_option -speed_grade -6
#compilation/mapping options
set_option -symbolic_fsm_compiler true
set_option -resource_sharing true

#use verilog standard option
set_option -vlog_std v2001

#map options
set_option -frequency 200
set_option -maxfan 1000
set_option -auto_constrain_io 0
set_option -retiming false; set_option -pipe true
set_option -force_gsr auto
set_option -compiler_compatible 0


set_option -default_enum_encoding default

#timing analysis options



#automatic place and route (vendor) options
set_option -write_apr_constraint 1

#synplifyPro options
set_option -fix_gated_and_generated_clocks 0
set_option -update_models_cp 0
set_option -resolve_multiple_driver 0


set_option -rw_check_on_ram 0


#-- set any command lines input by customer

set_option -dup false
set_option -disable_io_insertion false
add_file -constraint {IRStore_impl_1_cpe.ldc}
add_file -verilog {F:/MySoftware/Lattice/radiant/ip/pmi/pmi_iCE40UP.v}
add_file -vhdl -lib pmi {F:/MySoftware/Lattice/radiant/ip/pmi/pmi_iCE40UP.vhd}
add_file -verilog -vlog_std v2001 {F:/MyTemporary/Github/GLPP2024/IRStore/source/impl_1/ZIRStore_Top.v}
add_file -verilog -vlog_std v2001 {F:/MyTemporary/Github/GLPP2024/IRStore/source/impl_1/ZIRCfg_Data.v}
add_file -verilog -vlog_std v2001 {F:/MyTemporary/Github/GLPP2024/IRStore/IPCores/ZPLL/rtl/ZPLL.v}
add_file -verilog -vlog_std v2001 {F:/MyTemporary/Github/GLPP2024/IRStore/source/impl_1/ZUART_Tx.v}
add_file -verilog -vlog_std v2001 {F:/MyTemporary/Github/GLPP2024/IRStore/source/impl_1/ZIRSensor_Controller.v}
add_file -verilog -vlog_std v2001 {F:/MyTemporary/Github/GLPP2024/IRStore/IPCores/ZRAM_DP/rtl/ZRAM_DP.v}
add_file -verilog -vlog_std v2001 {F:/MyTemporary/Github/GLPP2024/IRStore/source/impl_1/ZOctalRAMOperator.v}
add_file -verilog -vlog_std v2001 {F:/MyTemporary/Github/GLPP2024/IRStore/source/impl_1/ZOctalRAMCfg.v}
add_file -verilog -vlog_std v2001 {F:/MyTemporary/Github/GLPP2024/IRStore/source/impl_1/ZIRStore_Bottom.v}
add_file -verilog -vlog_std v2001 {F:/MyTemporary/Github/GLPP2024/IRStore/source/impl_1/ZSynReset.v}
#-- top module name
set_option -top_module ZIRStore_Top
set_option -include_path {F:/MyTemporary/Github/GLPP2024/IRStore}
set_option -include_path {F:/MyTemporary/Github/GLPP2024/IRStore/IPCores/ZPLL}
set_option -include_path {F:/MyTemporary/Github/GLPP2024/IRStore/IPCores/ZRAM_DP}

#-- set result format/file last
project -result_format "vm"
project -result_file {F:/MyTemporary/Github/GLPP2024/IRStore/impl_1/IRStore_impl_1.vm}

#-- error message log file
project -log_file {IRStore_impl_1.srf}
project -run -clean
