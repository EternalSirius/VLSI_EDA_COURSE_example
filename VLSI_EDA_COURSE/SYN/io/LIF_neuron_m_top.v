module LIF_neuron_m_top (clk, rst_n, i_wspike, i_svalid, i_State, i_recc, scan_in,
			 scan_en, test_mode, scan_out, i_Thres, i_Thres_valid,
			 o_V, o_spike);
   
  input clk, rst_n, i_svalid, i_recc, i_Thres_valid, scan_en, test_mode, scan_in;
  input [2:0] i_wspike;
  input [3:0] i_State;
  input [5:0] i_Thres;
  output [5:0] o_V;
  output o_spike, scan_out;

   wire  clkI, rst_nI, svalidI, reccI, thres_validI, scan_enI, test_modeI, scanI;
   wire [2:0] wspikeI;
   wire [3:0] stateI;
   wire [5:0] thresI;
   wire [5:0] vO;
   wire       spikeO, scanO;

   LIF_neuron LIF_neuron_inst
     (
      .clk(clkI),
      .rst_n(rst_nI),
      .i_svalid(svalidI),
      .i_recc(reccI),
      .i_Thres_valid(thres_validI),
      .i_wspike(wspikeI),
      .i_State(stateI),
      .i_Thres(thresI),
      .scan_en(scan_enI),
      .test_mode(test_modeI),
      .scan_in(scanI),
      .o_V(vO),
      .scan_out(scanO),
      .o_spike(spikeO)
      );

   iopads iopads_inst 
     (
      .clk(clk),
      .rst_n(rst_n),
      .i_svalid(i_svalid),
      .i_recc(i_recc),
      .i_Thres_valid(i_Thres_valid),
      .i_wspike(i_wspike),
      .i_State(i_state),
      .i_Thres(i_Thres),
      .scan_en(scan_en),
      .test_mode(test_mode),
      .scan_in(scan_in),
      .o_V(o_V),
      .scan_out(scan_out),
      .o_spike(o_spike),
      .clkI(clkI),
      .rst_nI(rst_nI),
      .svalidI(svalidI),
      .reccI(reccI),
      .thres_validI(thres_validI),
      .wspikeI(wspikeI),
      .stateI(stateI),
      .thresI(thresI),
      .scanI(scanI),
      .scan_enI(scan_enI),
      .test_modeI(test_modeI),
      .scanO(scanO),
      .vO(vO),
      .spikeO(spikeO)
      );      
endmodule   
