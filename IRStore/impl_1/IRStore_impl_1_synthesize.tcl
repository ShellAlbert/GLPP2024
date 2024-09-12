if {[catch {

# define run engine funtion
source [file join {F:/MySoftware/Lattice/radiant} scripts tcl flow run_engine.tcl]
# define global variables
global para
set para(gui_mode) 1
set para(prj_dir) "F:/MyTemporary/Github/GLPP2024/IRStore"
# synthesize IPs
# synthesize VMs
# propgate constraints
file delete -force -- IRStore_impl_1_cpe.ldc
run_engine_newmsg cpe -f "IRStore_impl_1.cprj" "ZPLL.cprj" "ZRAM_DP.cprj" -a "iCE40UP"  -o IRStore_impl_1_cpe.ldc
# synthesize top design
file delete -force -- IRStore_impl_1.vm IRStore_impl_1.ldc
run_engine synpwrap -prj "IRStore_impl_1_synplify.tcl" -log "IRStore_impl_1.srf"
run_postsyn [list -a iCE40UP -p iCE40UP5K -t SG48 -sp High-Performance_1.2V -oc Industrial -top -w -o IRStore_impl_1_syn.udb IRStore_impl_1.vm] "F:/MyTemporary/Github/GLPP2024/IRStore/impl_1/IRStore_impl_1.ldc"

} out]} {
   runtime_log $out
   exit 1
}
