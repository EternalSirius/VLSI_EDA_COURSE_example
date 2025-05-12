#####################
# Reports that check design health
#####################
check_timing  >	   ${reportDir}/check_timing.rpt
report_annotated_parasitics         > ${reportDir}/annotated.rpt
report_analysis_coverage            > ${reportDir}/coverage.rpt

#####################
# Reports that describe constraints
#####################
report_clocks                       > ${reportDir}/clocks.rpt
report_case_analysis                > ${reportDir}/case_analysis.rpt
report_inactive_arcs                > ${reportDir}/inactive_arcs.rpt
 
#####################
# Reports that describe timing health
#####################
report_constraint -all_violators                                > ${reportDir}/allviol.rpt
report_analysis_summary                                         > ${reportDir}/analysis_summary.rpt
report_timing -path_type summary_slack_only -late -max_paths 10000  > ${reportDir}/start_end_slack.rpt

#####################
# GBA Reports that show detailed timing
#####################
report_timing -late   -max_paths 10000 -nworst 1 -path_type full_clock -net  > ${reportDir}/worst_max_path.rpt
report_timing -early  -max_paths 10000 -nworst 1 -path_type full_clock -net  > ${reportDir}/worst_min_path.rpt
report_timing -path_type end_slack_only -max_slack 0                      > ${reportDir}/setup_1.rpt
report_timing -path_type end_slack_only -max_slack 0 -early               > ${reportDir}/hold_1.rpt
report_timing -late   -max_slack 0 -max_paths 10000                         > ${reportDir}/setup_100.rpt.gz
report_timing -early  -max_slack 0 -max_paths 10000                         > ${reportDir}/hold_100.rpt.gz

#####################
# PBA Reports that show detailed timing
#####################
report_timing -retime path_slew_propagation -max_paths 10000 -nworst 1 -path_type full_clock    > ${reportDir}/pba_50_paths.rpt

