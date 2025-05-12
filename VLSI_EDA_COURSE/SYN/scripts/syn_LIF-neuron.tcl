######################################################
# Script for Cadence RTL Compiler synthesis      
# Erik Brunvand, 2008
# Use with syn-rtl -f rtl-script
# Replace items inside <> with your own information
######################################################

# Set the search paths to the libraries and the HDL files
# Remember that "." means your current directory. Add more directories
# after the . if you like.  
set_attribute hdl_search_path {../RTL/} 
set_attribute lib_search_path {../cell_lib/}
set_attribute library [list slow.lib ]
set_attribute lef_library ../lef/all.lef
set_attribute information_level 9
# set_db hdl_search_path {../../RTL/} 
# set_db lib_search_path {/home/lib/}
# set_db library [list typical.lib ]
# set_db information_level 6 

set_attribute lp_insert_clock_gating true /
set_attribute lp_insert_discrete_clock_gating_logic true /
set_attribute leakage_power_effort medium /

set myFiles [list LIF/LIF_neuron.v ]         ;# All HDL files
set basename LIF_neuron          ;# name of top level module
set myClk clk                    ;# clock name
set myPeriod_ps 5000             ;# Clock period in ps
set myInDelay_ns 0.1             ;# delay from clock to inputs valid
set myOutDelay_ns 0.1            ;# delay from clock to output valid
set runname v2_32                  ;# name appended to output files

#*********************************************************
#*   below here shouldn't need to be changed...          *
#*********************************************************

# Analyze and Elaborate the HDL files
read_hdl ${myFiles}
elaborate ${basename}

# Apply Constraints and generate clocks
set clock [define_clock -period ${myPeriod_ps} -name ${myClk} [clock_ports]]	
external_delay -input $myInDelay_ns -clock ${myClk} [find / -port ports_in/*]
external_delay -output $myOutDelay_ns -clock ${myClk} [find / -port ports_out/*]

# Sets transition to default values for Synopsys SDC format, 
# fall/rise 400ps
dc::set_clock_transition .4 $myClk

# check that the design is OK so far
check_design -unresolved
report timing -lint

# Synthesize the design to the target library
#synthesize -to_mapped
#ungroup -all
#syn_gen
#syn_map
#syn_opt            
synthesize -to_mapped 

# Write out the reports
report clock_gating > ./reports/${basename}_${runname}_clockgating.rep
report timing > ./reports/${basename}_${runname}_timing.rep
report gates  > ./reports/${basename}_${runname}_cell.rep
report area  > ./reports/${basename}_${runname}_area.rep
report power  > ./reports/${basename}_${runname}_power.rep

# Write out the structural Verilog and sdc files
write_hdl -mapped >  ./output_files/${basename}_${runname}.v
write_sdc >  ./output_files/${basename}_${runname}.sdc
