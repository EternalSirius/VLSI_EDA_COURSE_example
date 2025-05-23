module LIF_neuron_m_top (clk, rst_n, i_wspike, i_svalid, i_State, i_recc, i_Thres, i_Thres_valid,
			 o_V, o_spike);
   
  input clk, rst_n, i_svalid, i_recc, i_Thres_valid;
  input [2:0] i_wspike;
  input [3:0] i_State;
  input [5:0] i_Thres;
  output [5:0] o_V;
  output o_spike;

   wire  clkI, rst_nI, svalidI, reccI, thres_validI;

   wire [2:0] wspikeI;
   wire [3:0] stateI;
   wire [5:0] thresI;
   wire [5:0] vO;
   wire       spikeO;

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
      .o_V(vO),
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
      .o_V(o_V),
      .o_spike(o_spike),
      .clkI(clkI),
      .rst_nI(rst_nI),
      .svalidI(svalidI),
      .reccI(reccI),
      .thres_validI(thres_validI),
      .wspikeI(wspikeI),
      .stateI(stateI),
      .thresI(thresI),
      .vO(vO),
      .spikeO(spikeO)
      );      
endmodule   
