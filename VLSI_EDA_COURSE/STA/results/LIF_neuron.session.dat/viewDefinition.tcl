if {![namespace exists ::IMEX]} { namespace eval ::IMEX {} }
set ::IMEX::dataVar [file dirname [file normalize [info script]]]
set ::IMEX::libVar ${::IMEX::dataVar}/libs

create_library_set -name slow\
   -timing\
    [list ${::IMEX::libVar}/mmmc/slow.lib\
    ${::IMEX::libVar}/mmmc/tpz973gwc.lib]
create_rc_corner -name RcCorner\
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0\
   -qx_tech_file ${::IMEX::libVar}/mmmc/RcCorner/t018s6mm.tch
create_delay_corner -name default\
   -library_set slow\
   -rc_corner RcCorner
create_constraint_mode -name timing_cons\
   -sdc_files\
    [list /dev/null]
create_analysis_view -name ana_1 -constraint_mode timing_cons -delay_corner default
set_analysis_view -setup [list ana_1] -hold [list ana_1]
catch {set_interactive_constraint_mode [list timing_cons] } 
