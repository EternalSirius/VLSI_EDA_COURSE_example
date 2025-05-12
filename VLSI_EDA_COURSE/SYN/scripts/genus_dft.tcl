#### Template Script for RTL->Gate-Level Flow (generated from GENUS 16.13-s036_1) 

if {[file exists /proc/cpuinfo]} {
  sh grep "model name" /proc/cpuinfo
  sh grep "cpu MHz"    /proc/cpuinfo
}

puts "Hostname : [info hostname]"

##############################################################################
## Preset global variables and attributes
##############################################################################

#HS
set DESIGN LIF_neuron
set GEN_EFF medium
#HS 5
set MAP_OPT_EFF medium
#set DATE [clock format [clock seconds] -format "%b%d-%T"] 
set _OUTPUTS_PATH ./outputs_dft
set _REPORTS_PATH ./reports_dft
set _LOG_PATH ./logs_dft
##set ET_WORKDIR <ET work directory>
#HS 3
#set_attribute init_lib_search_path {. ./lib} / 
#set_attribute script_search_path {. <path>} /
#set_attribute init_hdl_search_path {. ./rtl} /
##Uncomment and specify machine names to enable super-threading.
##set_attribute super_thread_servers {<machine names>} /
##For design size of 1.5M - 5M gates, use 8 to 16 CPUs. For designs > 5M gates, use 16 to 32 CPUs
#HS
set_attribute max_cpus_per_server 8 /

##Default undriven/unconnected setting is 'none'.  
##set_attribute hdl_unconnected_input_port_value 0 | 1 | x | none /
##set_attribute hdl_undriven_output_port_value   0 | 1 | x | none /
##set_attribute hdl_undriven_signal_value        0 | 1 | x | none /


##set_attribute wireload_mode <value> /
#HS
set_attribute information_level 9 /

###############################################################
## Library setup
###############################################################

#HS 2
set_attribute hdl_search_path {../RTL/} 
set_attribute lib_search_path {../cell_lib/}
set_attribute library [list slow.lib ]
set_attribute lef_library ../lef/all.lef
set_attribute avoid true [find / -libcell CLK*]
## PLE
#HS
## Provide either cap_table_file or the qrc_tech_file
#HS
#set_attribute cap_table_file <file> /
#set_attribute qrc_tech_file <file> /
##generates <signal>_reg[<bit_width>] format
#set_attribute hdl_array_naming_style %s\[%d\] /  
##

#HS 2
#set_attribute lp_insert_clock_gating true /
#set_attribute lp_insert_discrete_clock_gating_logic true /

####################################################################
## Load Design
####################################################################

#HS
set myFiles [list LIF/LIF_neuron.v ]         ;# All HDL files
set myClk clk                    ;# clock name
set myPeriod_ps 5000             ;# Clock period in ps
set myInDelay_ns 0.1             ;# delay from clock to inputs valid
set myOutDelay_ns 0.1            ;# delay from clock to output valid
set runname v2_32                  ;# name appended to output files

read_hdl ${myFiles}
elaborate $DESIGN
puts "Runtime & Memory after 'read_hdl'"
time_info Elaboration

set clock [define_clock -period ${myPeriod_ps} -name ${myClk} [clock_ports]]	
external_delay -input $myInDelay_ns -clock ${myClk} [find / -port ports_in/*]
external_delay -output $myOutDelay_ns -clock ${myClk} [find / -port ports_out/*]
dc::set_clock_transition .4 $myClk

check_design -unresolved

####################################################################
## Constraints Setup
####################################################################

#HS
# read_sdc  sdc/idct_rc.sdc
# puts "The number of exceptions is [llength [find /designs/$DESIGN -exception *]]"


#set_attribute force_wireload <wireload name> "/designs/$DESIGN"

if {![file exists ${_LOG_PATH}]} {
  file mkdir ${_LOG_PATH}
  puts "Creating directory ${_LOG_PATH}"
}

if {![file exists ${_OUTPUTS_PATH}]} {
  file mkdir ${_OUTPUTS_PATH}
  puts "Creating directory ${_OUTPUTS_PATH}"
}

if {![file exists ${_REPORTS_PATH}]} {
  file mkdir ${_REPORTS_PATH}
  puts "Creating directory ${_REPORTS_PATH}"
}
report timing -lint


###################################################################################
## Define cost groups (clock-clock, clock-output, input-clock, input-output)
###################################################################################

## Uncomment to remove already existing costgroups before creating new ones.
## rm [find /designs/* -cost_group *]

if {[llength [all::all_seqs]] > 0} { 
  define_cost_group -name I2C -design $DESIGN
  define_cost_group -name C2O -design $DESIGN
  define_cost_group -name C2C -design $DESIGN
  path_group -from [all::all_seqs] -to [all::all_seqs] -group C2C -name C2C
  path_group -from [all::all_seqs] -to [all::all_outs] -group C2O -name C2O
  path_group -from [all::all_inps]  -to [all::all_seqs] -group I2C -name I2C
}

define_cost_group -name I2O -design $DESIGN
path_group -from [all::all_inps]  -to [all::all_outs] -group I2O -name I2O
foreach cg [find / -cost_group *] {
  report timing -cost_group [list $cg] >> $_REPORTS_PATH/${DESIGN}_pretim.rpt
}
##################################################################################################
## DFT Setup
##################################################################################################

set_attribute dft_scan_style muxed_scan /

## Uncomment for clocked_LSSD 
#set_attribute dft_scan_style clocked_lssd_scan /
#define_dft scan_clock_a -name <scanClockAObject> -period <delay in pico sec, default 50000> -rise <integer> -fall <integer> <portOrpin> 
#define_dft scan_clock_b -name <scanClockAObject> -period <delay in pico sec, default 50000> -rise <integer> -fall <integer> <portOrpin> 

set_attribute dft_prefix DFT_ /
# For VDIO customers, it is recommended to set the value of the next two attributes to false.
set_attribute dft_identify_top_level_test_clocks true /
set_attribute dft_identify_test_signals true /

set_attribute dft_identify_internal_test_clocks false /
set_attribute use_scan_seqs_for_non_dft false /

set_attribute dft_scan_map_mode tdrc_pass "/designs/$DESIGN"
set_attribute dft_connect_shift_enable_during_mapping tie_off "/designs/$DESIGN"
set_attribute dft_connect_scan_data_pins_during_mapping loopback "/designs/$DESIGN"
set_attribute dft_scan_output_preference auto "/designs/$DESIGN"
set_attribute dft_lockup_element_type preferred_level_sensitive "/designs/$DESIGN"
#set_attribute dft_mix_clock_edges_in_scan_chains true "/designs/$DESIGN"

#set_attribute dft_dont_scan true <instance or subdesign> 
#set_attribute dft_controllable "<from pin> <inverting|non_inverting>" <to pin>

#HS 3
define_dft test_clock -name scanclk -period 5000 [clock_ports]
define_dft shift_enable -name se -active high -create_port scan_en
define_dft test_mode -name tm -active high -create_port test_mode

## If you intend to insert compression logic, define your compression test signals or clocks here:
## define_dft test_mode...  [-shared_in]
## define_dft test_clock...
#########################################################################
## Segments Constraints (support fixed, floating, preserved and abstract)
## only showing preserved, and abstract segments as these are most often used
#############################################################################

##define_dft preserved_segment -name <segObject> -sdi <pin|port|subport> -sdo <pin|port|subport> -analyze 
## If the block is complete from a DFT perspective, uncomment to prevent any non-scan flops from being scan-replaced
#set_attribute dft_dont_scan true [filter dft_mapped false [find /designs/* -instance <subDesignInstance>/instances_seq/*]]

##define_dft abstract_segment -name <segObject> <-module|-instance|-libcell> -sdi <pin> -sdo <pin> -clock_port <pin> [-rise|-fall] -shift_enable_port <pin> -active <high|low> -length <integer> 
## Uncomment if abstract segments are modeled in CTL format
##read_dft_abstract_model -ctl <file>

#HS
define_dft scan_chain -name top_chain -sdi scan_in -sdo scan_out -create_ports

## Run the DFT rule checks
check_dft_rules > $_REPORTS_PATH/${DESIGN}-tdrcs
report dft_registers > $_REPORTS_PATH/${DESIGN}-DFTregs
report dft_setup > $_REPORTS_PATH/${DESIGN}-DFTsetup_tdrc

## Fix the DFT Violations
## Uncomment to fix dft violations
## set numDFTviolations [check_dft_rules]
## if {$numDFTviolations > "0"} {
##   report dft_violations > $_REPORTS_PATH/${DESIGN}-DFTviols  
##   fix_dft_violations -async_set -async_reset [-clock] -test_control <TestModeObject>
##   check_dft_rules
## }

##  Run the Advanced DFT rule checks to identify:
## ...  x-source generators, internal tristate nets, and clock and data race violations
## Note:  tristate nets are reported for busses in which the enables are driven by
## tristate devices.  Use 'check_design' to report other types of multidriven nets.

check_design -multidriven
check_dft_rules -advanced  > $_REPORTS_PATH/${DESIGN}-Advancedtdrcs
#HS
report dft_violations > $_REPORTS_PATH/${DESIGN}-AdvancedDFTViols

## Fix the Avanced DFT Violations
## ... x-source violations are fixed by inserting registered shadow logic
## ... tristate net violations are fixed by selectively enabling and disabiling the tristate enable signals
##  in shift-mode. 
## ... clock and data race violations are not auto-fixed by the tool.
## Note: The fixing of tristate net violations using the 'fix_dft_violations -tristate_net' command
## should be deferred until a full-chip representation of the design is available.

## Uncomment to fix x-source violations (or alternatively, insert the shadow logic using the
## 'insert_dft shadow_logic' command).
#fix_dft_violations -xsource -test_control <TestModeObject> -test_clock_pin <ClockPinOrPort> [-exclude_xsource <instance>]
#check_dft_rules -advanced

## Update DFT status
## report dft_registers > $_REPORTS_PATH/${DESIGN}-DFTregs_tdrc
## report dft_setup > $_REPORTS_PATH/${DESIGN}-DFTsetup_tdrc


#### To turn off sequential merging on the design 
#### uncomment & use the following attributes.
##set_attribute optimize_merge_flops false /
##set_attribute optimize_merge_latches false /
#### For a particular instance use attribute 'optimize_merge_seqs' to turn off sequential merging. 



####################################################################################################
## Synthesizing to generic 
####################################################################################################

set_attribute syn_generic_effort $GEN_EFF /
syn_generic
puts "Runtime & Memory after 'syn_generic'"
time_info GENERIC
write_snapshot -outdir $_REPORTS_PATH -tag generic
report datapath > $_REPORTS_PATH/generic/${DESIGN}_datapath.rpt
report_summary -outdir $_REPORTS_PATH




######################################################################################################
## Optional DFT commands (section 1)
######################################################################################################

#############
## Identify Functional Shift Registers
#############
#identify_shift_register_scan_segments

#############
## Add testability logic as required
#############
#insert_dft shadow_logic -around <instance> -mode <no_share|share|bypass> -test_control <TestModeObject>
#insert_dft test_point -location <port|pin> -test_control <test_signal> -type <string>

#######################
## Add Boundary Scan and Programmable MBIST logic
########################

## Uncomment to define the existing 3rd party TAP controller to be used as the master controller for
## DFT logic such as boundary-scan, compression, Programmable MBIST and ptam.
#define_dft jtag_macro -name <objectName> ....

## Define JTAG Instructions for the existing Macro or when building the JTAG_Macro with user-defined instructions. 
## ... For current release, name the mandatory JTAG instructions as: EXTEST, SAMPLE, PRELOAD, BYPASS

##define_dft jtag_instruction_register -name <string> -length <integer> -capture <string>
##define_dft jtag_instruction -name <string> -opcode <string> ;# [-register <string> -length <integer>] [-private]

## Uncomment to build a JTAG_Macro with Programmable MBIST instructions.
## Names of the mandatory instructions are: MBISTTPN, MBISTSCH, MBISTCHK
#define_dft jtag_instruction -name <string> -opcode <string> -register <string> -length <integer>

## Uncomment to define the MBIST clock if inserting Programmable MBIST logic
#define_dft mbist_clock -name <objectNameOfMBISTClock> ...

## Uncomment to read memory view files for programmable MBIST
#read_memory_view -cdns_memory_view_file <string> -arm_mbif <string> -directory <string> <design>

#insert_dft boundary_scan -tck <tckpin> -tdi <tdipin> -tms <tmspin> -trst <trstpin> -tdo <tdopin> -exclude_ports <list of ports excluded from boundary register> -preview

## Uncomment to read block-level interface files for programmable MBIST
#read_pmbist_interface_files -directory <locationOfInterfaceFiles> <lib_cell|module|design>

## Uncomment to insert Programmable BIST (PMBIST) for memories
#insert_dft pmbist -config_file <filename> -connect_to_jtag -directory <PMBISTworkDir> -dft_cfg_mode <dft_configuration_mode> -amu_location <design|module|inst|hinst> ..

## Uncomment to write interface files for programmable MBIST
#write_pmbist_interface_files -directory <locationOfInterfaceFiles> [<design>]

## Uncomment to write out data and script files to generate PMBIST patterns
#write_pmbist_testbench [-create_embedded_test_options <string>] [-irun_options <string>] [-directory <string>] [-testbench_directory <string>] [-ncsim_library <string>] [-script_only] [-no_deposit_script] [-no_build_model] [<design>]

##Write out BSDL file
#write_bsdl -bsdlout <BSDLfileName> -directory <work directory>


####################################################################################################
## Synthesizing to gates
####################################################################################################

## Add '-auto_identify_shift_registers' to 'syn_map' to automatically 
## identify functional shift register segments. Not applicable for n2n flow.
set_attribute syn_map_effort $MAP_OPT_EFF /
syn_map
puts "Runtime & Memory after 'syn_map'"
time_info MAPPED
write_snapshot -outdir $_REPORTS_PATH -tag map
report_summary -outdir $_REPORTS_PATH
report datapath > $_REPORTS_PATH/map/${DESIGN}_datapath.rpt


foreach cg [find / -cost_group *] {
  report timing -cost_group [list $cg] > $_REPORTS_PATH/${DESIGN}_[vbasename $cg]_post_map.rpt
}



##Intermediate netlist for LEC verification..
write_hdl -lec > ${_OUTPUTS_PATH}/${DESIGN}_intermediate.v
write_do_lec -revised_design ${_OUTPUTS_PATH}/${DESIGN}_intermediate.v -logfile ${_LOG_PATH}/rtl2intermediate.lec.log > ${_OUTPUTS_PATH}/rtl2intermediate.lec.do

## ungroup -threshold <value>

#######################################################################################################
## Optimize Netlist
#######################################################################################################
set_attribute syn_opt_effort $MAP_OPT_EFF /
syn_opt
write_snapshot -outdir $_REPORTS_PATH -tag syn_opt
report_summary -outdir $_REPORTS_PATH

puts "Runtime & Memory after 'syn_opt'"
time_info OPT

foreach cg [find / -cost_group *] {
  report timing -cost_group [list $cg] > $_REPORTS_PATH/${DESIGN}_[vbasename $cg]_post_opt.rpt
}

######################################################################################################
## Optional additional DFT commands. (section 2)
######################################################################################################

## Re-run DFT rule checks
## check_dft_rules [-advanced]
## Build the full scan chanins
#HS 2
connect_scan_chains
report dft_chains > $_REPORTS_PATH/${DESIGN}-DFTchains

## Inserting Compression logic
## compress_scan_chains -ratio <integer>  -mask <string> [-auto_create] [-preview]
##report dft_chains > $_REPORTS_PATH/${DESIGN}-DFTchains_compression
## Reapply CPF rules
#commit_cpf

#######################################################################################################
## Optimize Netlist
#######################################################################################################
 
## Uncomment to remove assigns & insert tiehilo cells during Incremental synthesis
##set_attribute remove_assigns true /
##set_remove_assign_options -buffer_or_inverter <libcell> -design <design|subdesign>
##set_attribute use_tiehilo_for_const <none|duplicate|unique> /
 
## An effort of low was selected to minimize runtime of incremental opto.
## If your timing is not met, rerun incremental opto with a different effort level
set_attribute syn_opt_effort low /
syn_opt -incremental
write_snapshot -outdir $_REPORTS_PATH -tag syn_opt_low_incr 
report_summary -outdir $_REPORTS_PATH
puts "Runtime & Memory after 'syn_opt'"
time_info INCREMENTAL_POST_SCAN_CHAINS


#############################################
## DFT Reports
#############################################

report dft_setup > $_REPORTS_PATH/${DESIGN}-DFTsetup_final
#HS 4n
#write_scandef > $_OUTPUTS_PATH/${DESIGN}-scanDEF
#write_dft_abstract_model > $_OUTPUTS_PATH/${DESIGN}-scanAbstract
write_hdl -abstract > $_OUTPUTS_PATH/${DESIGN}-logicAbstract
write_script -analyze_all_scan_chains > $_OUTPUTS_PATH/${DESIGN}-writeScript-analyzeAllScanChains
## check_atpg_rules -library <Verilog simulation library files> -compression -directory <Encounter Test workdir directory>
## write_et_bsv -library <Verilog structural library files> -directory $ET_WORKDIR
#HS
#write_et_atpg -library <Verilog structural library files> -compression -directory $ET_WORKDIR 


######################################################################################################
## write backend file set (verilog, SDC, config, etc.)
######################################################################################################

report datapath > $_REPORTS_PATH/${DESIGN}_datapath_incr.rpt
report messages > $_REPORTS_PATH/${DESIGN}_messages.rpt

#HS 5
report area > $_REPORTS_PATH/${DESIGN}_area.rpt
report timing > $_REPORTS_PATH/${DESIGN}_timing.rpt
report power -depth 9 > $_REPORTS_PATH/${DESIGN}_power.rpt
report gates -power > $_REPORTS_PATH/${DESIGN}_gates_power.rpt
report clock_gating > $_REPORTS_PATH/${DESIGN}_clockgating.rpt
write_snapshot -outdir $_REPORTS_PATH -tag final
report_summary -outdir $_REPORTS_PATH
#HS
write_design -basename ${_OUTPUTS_PATH}/${DESIGN}_m
## write_hdl  > ${_OUTPUTS_PATH}/${DESIGN}_m.v
## write_script > ${_OUTPUTS_PATH}/${DESIGN}_m.script
write_sdc > ${_OUTPUTS_PATH}/${DESIGN}_m.sdc


#################################
### write_do_lec
#################################


write_do_lec -golden_design ${_OUTPUTS_PATH}/${DESIGN}_intermediate.v -revised_design ${_OUTPUTS_PATH}/${DESIGN}_m.v -logfile  ${_LOG_PATH}/intermediate2final.lec.log > ${_OUTPUTS_PATH}/intermediate2final.lec.do
##Uncomment if the RTL is to be compared with the final netlist..
##write_do_lec -revised_design ${_OUTPUTS_PATH}/${DESIGN}_m.v -logfile ${_LOG_PATH}/rtl2final.lec.log > ${_OUTPUTS_PATH}/rtl2final.lec.do

puts "Final Runtime & Memory."
time_info FINAL
puts "============================"
puts "Synthesis Finished ........."
puts "============================"

file copy [get_attribute stdout_log /] ${_LOG_PATH}/.

##quit
