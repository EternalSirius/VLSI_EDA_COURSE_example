vlib post_work

# compile
vlog /eda/PDK_DIR/TSMC/180_DIG_CELL/TSMCHOME/digital/Front_End/verilog/tcb018g3d3_280a/tcb018g3d3.v
vlog ../SYN/outputs_basic/LIF_neuron_m.v
vlog ../TB/LIF/TB_LIF_neuron.v

# simulate

vsim -voptargs="+acc" -t 1ps -wlf post-LIF_neuron.wlf TB_LIF_neuron

# add wave to the view
log -r *
add wave *

# run the simulation
run -a
