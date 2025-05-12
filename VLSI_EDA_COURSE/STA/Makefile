all:
	tempus -no_gui -execute "source ./scripts/tempus.tcl; exit" 2>&1 | \
	tee run_sa.LIF-neuron.`date +%Y-%m-%d-%H%M%S`.log
clean:
	rm -rf tempus* *.log
.PHONY: clean
