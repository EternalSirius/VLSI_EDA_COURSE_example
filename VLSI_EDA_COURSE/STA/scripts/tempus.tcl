################################################################
# Purpose:  Show a simple Tempus STA script
# Purpose:  Hightlight the order of operations and simple commands
# Author:   John Schritz   Nov 2015
################################################################

################################
# Setup threading and client counts
################################
set model_name "LIF_neuron"

set_multi_cpu_usage -localCpu 1

################################
# Setup some global variables or report settings
################################
set_table_style -no_frame_fix_width -nosplit

################################
# Read a view file
################################
read_view_definition ../PNR/scripts/$model_name.view

################################
# Read the netlist in a gzipped format
################################
read_verilog ../PNR/outputs/LIF_neuron_m_top_enc.v

################################
# Link the design
################################
set_top_module LIF_neuron_m_top -ignore_undefined_cell

################################
# Check the size of the testcase
################################
set cellCnt [sizeof_collection [get_cells -hier *]]
puts "Your design has: $cellCnt instances"

################################
# Load netlist parasitics
################################
read_spef -rc_corner RcCorner ../PNR/outputs/LIF_neuron_m_top.spef

set_interactive_constraint_modes [all_constraint_modes -active]
set_propagated_clock [all_clocks]
source ./latency.sdc

################################
# Adjust timer settings
################################
set_delay_cal_mode -siAware false   ;# Turn on SI when true
setSIMode -enable_glitch_report 0   ;# Turn on glitch analysis when set to 1

###################################
# Run timing
###################################
update_timing -full

###################################
# Run a whole list of common reports
###################################
set reportDir ./reports
file mkdir $reportDir

source ./reports/reports.tcl

###################################
# Save the design and timing information
###################################
save_design ./results/$model_name.session -overwrite

Puts "All done"
###################################
# If in interactive session, return to the Tempus prompt
# If in batch session, return to the Linux prompt
###################################
return
exit

