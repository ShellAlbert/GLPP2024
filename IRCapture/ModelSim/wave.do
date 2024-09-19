onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ZIRCapture_Top/ic_CDS3/iClk
add wave -noupdate /ZIRCapture_Top/ic_CDS3/iRst_N
add wave -noupdate /ZIRCapture_Top/ic_CDS3/iEn
add wave -noupdate /ZIRCapture_Top/ic_CDS3/iIR_PCLK
add wave -noupdate /ZIRCapture_Top/ic_CDS3/iIR_Data
add wave -noupdate /ZIRCapture_Top/ic_CDS3/oWr_Which
add wave -noupdate /ZIRCapture_Top/ic_CDS3/iRAM_Init_Done
add wave -noupdate /ZIRCapture_Top/ic_CDS3/oRAM_Data_Valid
add wave -noupdate /ZIRCapture_Top/ic_CDS3/IR_PCLK_Delay
add wave -noupdate /ZIRCapture_Top/ic_CDS3/IR_Data0
add wave -noupdate /ZIRCapture_Top/ic_CDS3/IR_Data1
add wave -noupdate /ZIRCapture_Top/ic_CDS3/IR_Data2
add wave -noupdate /ZIRCapture_Top/ic_CDS3/IR_Data3
add wave -noupdate /ZIRCapture_Top/ic_CDS3/IR_Data4
add wave -noupdate /ZIRCapture_Top/ic_CDS3/IR_Data5
add wave -noupdate /ZIRCapture_Top/ic_CDS3/IR_Data6
add wave -noupdate /ZIRCapture_Top/ic_CDS3/IR_Data7
add wave -noupdate /ZIRCapture_Top/ic_CDS3/IR_CLK_Rising_Edge
add wave -noupdate /ZIRCapture_Top/ic_CDS3/IR_CLK_Falling_Edge
add wave -noupdate /ZIRCapture_Top/ic_CDS3/IR_Data_Bus
add wave -noupdate /ZIRCapture_Top/ic_CDS3/CNT_Step
add wave -noupdate /ZIRCapture_Top/ic_CDS3/CNT_SubStep
add wave -noupdate /ZIRCapture_Top/ic_CDS3/CNT_Delay
add wave -noupdate /ZIRCapture_Top/ic_CDS3/Rx_DR0
add wave -noupdate /ZIRCapture_Top/ic_CDS3/Rx_DR1
add wave -noupdate /ZIRCapture_Top/ic_CDS3/Rx_DR2
add wave -noupdate /ZIRCapture_Top/ic_CDS3/Rx_DR3
add wave -noupdate /ZIRCapture_Top/ic_CDS3/Temp_DR
add wave -noupdate /ZIRCapture_Top/ic_CDS3/CNT_Bytes
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/iRst_N
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/iEn
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/oRAM_RST
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/oRAM_DQS
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/iCap_Frame_Done
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/oWr_Line_Done
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/iRAM_Data_Valid
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/oWr_Frame_Done
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/cfg_No
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/cfg_RegAddr
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/cfg_RegData
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/oRAM_Init_Done
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/CNT_Step
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/CNT_SubStep
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/CNT_Delay
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/CNT_Repeat
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/Correctness_Fixed_Data
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/Rd_Addr_Inc
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/Rd_Back_Data
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/Rd_Back_Bytes
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/DDR_PSRAM_Wr_Addr_Inc
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate /ZIRCapture_Top/ic_CDS3/oCap_Frame_Done
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/iWr_Which
add wave -noupdate -radix unsigned /ZIRCapture_Top/ic_CDS3/Captured_Bytes
add wave -noupdate /ZIRCapture_Top/ic_CDS3/oWr_En
add wave -noupdate -radix hexadecimal /ZIRCapture_Top/ic_CDS3/oWr_Addr
add wave -noupdate -radix hexadecimal /ZIRCapture_Top/ic_CDS3/oWr_Data
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/iClk
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/oRAM_CLK
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/oRAM_CE
add wave -noupdate -radix hexadecimal /ZIRCapture_Top/ic_DDRWriter/oRAM_ADQ
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/oRd_En
add wave -noupdate -radix unsigned /ZIRCapture_Top/ic_DDRWriter/oRd_Addr
add wave -noupdate /ZIRCapture_Top/ic_DDRWriter/iRd_Data
add wave -noupdate -radix unsigned /ZIRCapture_Top/ic_DDRWriter/CNT_Line
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {82807655 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 366
configure wave -valuecolwidth 122
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
WaveRestoreZoom {81549369 ps} {83098598 ps}
