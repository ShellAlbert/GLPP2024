if {[catch {

# define run engine funtion
source [file join {F:/MySoftware/Lattice/radiant} scripts tcl flow run_engine.tcl]
# define global variables
global para
set para(gui_mode) 1
set para(prj_dir) "F:/MyTemporary/Github/GLPP2024/RevealTest"
# synthesize IPs
# synthesize VMs
# propgate constraints
file delete -force -- RevealTest_impl_1_cpe.ldc
run_engine_newmsg cpe -f "RevealTest_impl_1.cprj" "ZPLL.cprj" -a "iCE40UP"  -o RevealTest_impl_1_cpe.ldc
# synthesize top design
file delete -force -- RevealTest_impl_1.vm RevealTest_impl_1.ldc
run_engine_newmsg synthesis -f "RevealTest_impl_1_lattice.synproj"
run_postsyn [list -a iCE40UP -p iCE40UP5K -t SG48 -sp High-Performance_1.2V -oc Industrial -top -w -o RevealTest_impl_1_syn.udb RevealTest_impl_1.vm] "F:/MyTemporary/Github/GLPP2024/RevealTest/impl_1/RevealTest_impl_1.ldc"

} out]} {
   runtime_log $out
   exit 1
}
