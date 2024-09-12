onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ZIRSnapshot/ic_OctalRAM/iRst_N
add wave -noupdate /ZIRSnapshot/ic_OctalRAM/oOp_Done
add wave -noupdate /ZIRSnapshot/ic_OctalRAM/oRx_Back_Data
add wave -noupdate /ZIRSnapshot/ic_OctalRAM/oe_DQS
add wave -noupdate /ZIRSnapshot/ic_OctalRAM/DQS_Out
add wave -noupdate /ZIRSnapshot/ic_OctalRAM/DQS_In
add wave -noupdate /ZIRSnapshot/ic_OctalRAM/iClk
add wave -noupdate /ZIRSnapshot/ic_OctalRAM/iPSRAM_DATA
add wave -noupdate /ZIRSnapshot/ic_OctalRAM/oPSRAM_DATA
add wave -noupdate /ZIRSnapshot/ic_OctalRAM/DDR_Data_In_Rising
add wave -noupdate /ZIRSnapshot/ic_OctalRAM/DDR_Data_In_Falling
add wave -noupdate /ZIRSnapshot/ic_OctalRAM/DDR_Data_Out_Rising
add wave -noupdate /ZIRSnapshot/ic_OctalRAM/DDR_Data_Out_Falling
add wave -noupdate /ZIRSnapshot/ic_OctalRAM/cfg_No
add wave -noupdate /ZIRSnapshot/ic_OctalRAM/cfg_RegAddr
add wave -noupdate /ZIRSnapshot/ic_OctalRAM/cfg_RegData
add wave -noupdate /ZIRSnapshot/ic_OctalRAM/CNT2
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -radix decimal /ZIRSnapshot/ic_OctalRAM/iOp_Code
add wave -noupdate -radix decimal /ZIRSnapshot/ic_OctalRAM/CNT1
add wave -noupdate /ZIRSnapshot/ic_OctalRAM/fab2oe
add wave -noupdate -radix hexadecimal /ZIRSnapshot/ic_OctalRAM/oe2pad
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -label oPSRAM_CLK /ZIRSnapshot/ic_OctalRAM/oPSRAM_CLK
add wave -noupdate -label oPSRAM_CE /ZIRSnapshot/ic_OctalRAM/oPSRAM_CE
add wave -noupdate -label oPSRAM_RST /ZIRSnapshot/ic_OctalRAM/oPSRAM_RST
add wave -noupdate -label oPSRAM_DATA -radix hexadecimal /ZIRSnapshot/ic_OctalRAM/ioPSRAM_DATA
add wave -noupdate -label oPSRAM_DQS /ZIRSnapshot/ic_OctalRAM/ioPSRAM_DQS
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {7112394 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 188
configure wave -valuecolwidth 38
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {6118056 ps} {7138662 ps}
