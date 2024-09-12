lappend auto_path "F:/MySoftware/Lattice/radiant/scripts/tcl/simulation"
package require tbdeclaration_generation

set ::bali::Para(MODNAME) ZIRSnapshot
set ::bali::Para(PROJECT) IRSnapshot
set ::bali::Para(PRIMITIVEFILE) {"F:/MySoftware/Lattice/radiant/cae_library/synthesis/verilog/iCE40UP.v=iCE40UP"}
set ::bali::Para(TFT) {"F:/MySoftware/Lattice/radiant/data/templates/tfi_f.tft"}
set ::bali::Para(FILELIST) {"F:/MyTemporary/Github/GLPP2024/Lattice_IRSnapshot/IRSnapshot/source/impl_1/ZLEDIndicator.v=work,Verilog_2001" "F:/MyTemporary/Github/GLPP2024/Lattice_IRSnapshot/IRSnapshot/source/impl_1/ZIRSnapshot.v=work,Verilog_2001" "F:/MyTemporary/Github/GLPP2024/Lattice_IRSnapshot/IRSnapshot/IPCores/ZIP_PLL/rtl/ZIP_PLL.v=work,Verilog_2001" "F:/MyTemporary/Github/GLPP2024/Lattice_IRSnapshot/IRSnapshot/source/impl_1/ZOctalRAMOperator.v=work,Verilog_2001" "F:/MyTemporary/Github/GLPP2024/Lattice_IRSnapshot/IRSnapshot/source/impl_1/ZUART_Tx.v=work,Verilog_2001" "F:/MyTemporary/Github/GLPP2024/Lattice_IRSnapshot/IRSnapshot/source/impl_1/ZOctalRAMCfg.v=work,Verilog_2001" "F:/MyTemporary/Github/GLPP2024/Lattice_IRSnapshot/IRSnapshot/source/impl_1/ZUART_Tx_TB.v=work,Verilog_2001" }
set ::bali::Para(INCLUDEPATH) {"F:/MyTemporary/Github/GLPP2024/Lattice_IRSnapshot/IRSnapshot/source/impl_1" "F:/MyTemporary/Github/GLPP2024/Lattice_IRSnapshot/IRSnapshot/IPCores/ZIP_PLL/rtl" }
::bali::GenerateTbDeclaration
