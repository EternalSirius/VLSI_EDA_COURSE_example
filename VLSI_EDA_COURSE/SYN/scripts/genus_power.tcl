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
set _OUTPUTS_PATH ./outputs_power
set _REPORTS_PATH ./reports_power
set _LOG_PATH ./logs_power
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
set_attribute lp_insert_clock_gating true /
set_attribute lp_insert_discrete_clock_gating_logic true /

## Power root attributes
#set_attribute lp_clock_gating_prefix <string> /
#set_attribute lp_power_analysis_effort <high> /
#set_attribute lp_power_unit mW /
#set_attribute lp_toggle_rate_unit /ns /
## The attribute has been set to default value "medium"
## you can try setting it to high to explore MVT QoR for low power optimization
set_attribute leakage_power_effort medium /


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
# read_sdc sdc/idct_rc.sdc
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
#######################################################################################
## Leakage/Dynamic power/Clock Gating setup.
#######################################################################################


#set_attribute lp_clock_gating_cell [find /lib* -libcell <cg_libcell_name>] "/designs/$DESIGN"
#set_attribute max_leakage_power 0.0 "/designs/$DESIGN"
#set_attribute lp_power_optimization_weight <value from 0 to 1> "/designs/$DESIGN"
#set_attribute max_dynamic_power <number> "/designs/$DESIGN"
## read_tcf <TCF file name>
## read_saif <SAIF file name>
## read_vcd <VCD file name>



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


#### Build RTL power models
##build_rtl_power_models -design $DESIGN -clean_up_netlist [-clock_gating_logic] [-relative <hierarchical instance>]
#report power -rtl



####################################################################################################
## Synthesizing to gates
####################################################################################################

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

## Uncomment to remove assigns & insert tiehilo cells during Incremental synthesis
##set_attribute remove_assigns true /
##set_remove_assign_options -buffer_or_inverter <libcell> -design <design|subdesign> 
##set_attribute use_tiehilo_for_const <none|duplicate|unique> /
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
## write backend file set (verilog, SDC, config, etc.)
######################################################################################################


report datapath > $_REPORTS_PATH/${DESIGN}_datapath_incr.rpt
report messages > $_REPORTS_PATH/${DESIGN}_messages.rpt

#HS 5
report area > $_REPORTS_PATH/${DESIGN}_area.rpt
report gates > $_REPORTS_PATH/${DESIGN}_gates.rpt 
report timing > $_REPORTS_PATH/${DESIGN}_timing.rpt 
report power -depth 9 > $_REPORTS_PATH/${DESIGN}_power.rpt 
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
