set_clock_latency -source -early -max -rise  -1.86172 [get_ports {clk}] -clock clk 
set_clock_latency -source -early -max -fall  -1.44016 [get_ports {clk}] -clock clk 
set_clock_latency -source -late -max -rise  -1.86172 [get_ports {clk}] -clock clk 
set_clock_latency -source -late -max -fall  -1.44016 [get_ports {clk}] -clock clk 
