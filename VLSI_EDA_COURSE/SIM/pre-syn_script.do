vlib pre_work

# compile
vlog ../RTL/parameters/LIF.v
vlog ../RTL/parameters/common.v
vlog ../RTL/LIF/LIF_neuron.v
vlog ../TB/LIF/TB_LIF_neuron.v

# simulate

vsim -voptargs="+acc" -wlf pre-LIF_neuron.wlf TB_LIF_neuron

# add wave to the view
log -r *
add wave *

# run the simulation
run -a
