pnr:
	innovus -no_gui -execute "source ./scripts/innovus.tcl; exit" 2>&1 | \
	tee run_pnr.LIF-neuron.`date +%Y-%m-%d-%H%M%S`.log
clean:
	rm -rf innovus* timingReports *~ reports *.log
.PHONY: pnr clean
