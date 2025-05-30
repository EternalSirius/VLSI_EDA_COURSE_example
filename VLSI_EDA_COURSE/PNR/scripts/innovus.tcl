setMultiCpuUsage -localCpu 1
setMessageLimit 10000
set_global _enable_mmmc_by_default_flow      $CTE::mmmc_default
set DESIGN LIF_neuron
set init_gnd_net VSS
set init_pwr_net VDD

set init_lef_file {/eda/PDK_DIR/TSMC/180_DIG_CELL/TSMCHOME/digital/Back_End/lef/tcb018g3d3_280a/lef/tcb018g3d3_6lm.lef /eda/PDK_DIR/TSMC/180_DIG_CELL/TSMCHOME/digital/Back_End/lef/tpz973gv_280a/mt_2/6lm/lef/tpz973gv_6lm.lef /eda/PDK_DIR/TSMC/180_DIG_CELL/TSMCHOME/digital/Back_End/lef/tpz973gv_280a/mt_2/6lm/lef/antenna_6lm.lef}
set init_verilog [list ../SYN/outputs_basic/${DESIGN}_m.v ../SYN/io/iopads_basic.v ../SYN/io/${DESIGN}_m_top_basic.v]
set init_mmmc_file ./scripts/${DESIGN}.view
set init_io_file ../SYN/io/${DESIGN}_m_top_basic.io
init_design

checkDesign -io -netlist -physicalLibrary -tieHiLo -timingLibrary -noHtml -outfile ./reports/checkDesign.rpt

clearGlobalNets
globalNetConnect VDD -type pgpin -pin VDD -inst *
globalNetConnect VSS -type pgpin -pin VSS -inst *
# globalNetConnect VDD -type pgpin -pin vdd! -inst *
# globalNetConnect VSS -type pgpin -pin gnd! -inst *
globalNetConnect VDD -type tiehi -inst *
globalNetConnect VSS -type tielo -inst *
setFPlanMode -snap_all_corners_to_grid true -snapPlaceBlockageGrid manufacturing -snapCoreGrid manufacturing
# floorPlan -site core -r 1 0.8 120 120 120 120
floorPlan -site core -d 630.0 650.0 110 110 110 110

checkFPlan -reportUtil -outFile ./reports/checkFPlan

addHaloToBlock 20 20 20 20 -allBlock

setAddRingMode -stacked_via_top_layer METAL6
setAddRingMode -stacked_via_bottom_layer METAL1

addRing -skip_via_on_wire_shape Noshape -skip_via_on_pin Standardcell \
    -type core_rings -jog_distance 1 -threshold 1 -nets {VDD VSS} -follow core \
    -layer {bottom METAL5 top METAL5 right METAL6 left METAL6} -width 10 -spacing 2 -offset 3

saveDesign ./outputs/${DESIGN}_ring.enc

setAddStripeMode -stacked_via_top_layer METAL6
setAddStripeMode -stacked_via_bottom_layer METAL1

addStripe -block_ring_top_layer_limit METAL6 -max_same_layer_jog_length 1 -padcore_ring_bottom_layer_limit METAL5 -set_to_set_distance 100 \
  -padcore_ring_top_layer_limit METAL6 -spacing 2 -merge_stripes_value 1 \
  -direction horizontal -layer METAL5 -block_ring_bottom_layer_limit METAL5 -width 6 -nets {VDD VSS}

saveDesign ./outputs/${DESIGN}_m_stripe.enc


sroute -connect { blockPin padPin padRing corePin } -layerChangeRange { METAL1 METAL6 } -blockPinTarget { nearestRingStripe nearestTarget } -padPinPortConnect { allPort oneGeom } -blockPin useLef -allowJogging 1 -crossoverViaLayerRange {METAL1 METAL6} -allowLayerChange 1 -targetViaLayerRange {METAL1 METAL6} -nets { VDD VSS }

saveDesign ./outputs/${DESIGN}_m_sroute.enc

specifyScanChain top_chain -start scan_in -stop scan_out
scanTrace

placeDesign -prePlaceOpt
checkPlace ./reports/checkPlace.rpt

timeDesign -preCTS -idealClock -pathReports -drvReports -slackReports -numPaths 50 -prefix ${DESIGN}_preCTS -outDir ./reports/timingReports

setOptMode -fixCap true -fixTran true -fixFanoutLoad false
optDesign -preCTS

clockDesign -specFile lib/Clock.ctstch -outDir ./reports/clock_report

set_interactive_constraint_modes [all_constraint_modes -active]
set_propagated_clock [all_clocks]

optDesign -postCTS
optDesign -postCTS -hold

setNanoRouteMode -quiet -routeInsertAntennaDiode true
routeDesign -globalDetail

setAnalysisMode -analysisType onChipVariation

optDesign -postRoute
optDesign -postRoute -hold

verifyGeometry -report ./reports/geomafterroute.rpt
verifyConnectivity -type all -error 1000 -warning 50 -report ./reports/connafterroute.rpt

violationBrowserReport -all -no_display_false -report ./reports/violrout.rpt
summaryReport -noHtml -outfile ./reports/summaryReport.rpt

setExtractRCMode -engine postRoute -effortLevel low -coupled false
extractRC
rcOut -spef ./outputs/${DESIGN}_m_top.spef -rc_corner RcCorner

saveNetlist ./outputs/${DESIGN}_m_top_enc.v
streamOut ./outputs/${DESIGN}_m_top -mapFile streamOut.map -libName DesignLib -units 2000 -mode ALL
saveDesign ./outputs/${DESIGN}_m_top.enc

win
