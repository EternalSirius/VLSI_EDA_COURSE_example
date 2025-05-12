all: base

base:
	genus -legacy_ui -no_gui -execute "source ./scripts/genus_base.tcl; exit" 2>&1 | \
	tee run_base.LIF-neuron.`date +%Y-%m-%d-%H%M%S`.log

power:
	genus -legacy_ui -no_gui -execute "source ./scripts/genus_power.tcl; exit" 2>&1 | \
	tee run_power.LIF-neuron.`date +%Y-%m-%d-%H%M%S`.log

dft:
	genus -legacy_ui -no_gui -execute "source ./scripts/genus_dft.tcl; exit" 2>&1 | \
	tee run_dft.LIF-neuron.`date +%Y-%m-%d-%H%M%S`.log

full:
	genus -legacy_ui -no_gui -execute "source ./scripts/genus_full.tcl; exit" 2>&1 | \
	tee run_full.LIF-neuron.`date +%Y-%m-%d-%H%M%S`.log

clean:
	rm -rf genus* reports output_files fv *~ *.log logs_full/*.log logs_dft/*.log logs_power/*.log log_basic/*.log
.PHONY: clean
