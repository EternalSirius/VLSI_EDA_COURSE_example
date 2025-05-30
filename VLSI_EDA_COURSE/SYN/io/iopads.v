module iopads (clk, rst_n, i_wspike, i_svalid, i_State, i_recc,
	       i_Thres, i_Thres_valid,scan_en, scan_in, test_mode, scan_out, o_V, o_spike, 
	       clkI, rst_nI, wspikeI, svalidI, stateI, reccI,
	       scanI, scan_enI, test_modeI, scanO,
	       thresI, thres_validI, vO, spikeO);
   input clk, rst_n, i_svalid, i_recc, i_Thres_valid, scan_en, test_mode, scan_in;
   input [2:0] i_wspike;
   input [3:0] i_State;
   input [5:0] i_Thres;
   output [5:0] o_V;
   output 	o_spike, scan_out;

   output      clkI, rst_nI, svalidI, reccI, thres_validI, scan_enI, test_modeI, scanI;
   output [2:0] wspikeI;
   output [3:0] stateI;
   output [5:0] thresI;
   
   input [5:0] 	vO;
   input 	spikeO, scanO;

   PDIDGZ pclck (.PAD(clk), .C(clkI));
   PDIDGZ prst_n (.PAD(rst_n), .C(rst_nI));
   PDIDGZ psvalid (.PAD(i_svalid), .C(svalidI));
   PDIDGZ precc (.PAD(i_recc), .C(reccI));
   PDIDGZ pthres_valid (.PAD(i_Thres_valid), .C(thres_validI));
   PDIDGZ pscan_en (.PAD(scan_en), .C(scan_enI));
   PDIDGZ pscan_in (.PAD(scan_in), .C(scanI));
   PDIDGZ ptest_mode (.PAD(test_mode), .C(test_modeI));
   
   PDIDGZ pwspike0 (.PAD(i_wspike[0]), .C(wspikeI[0]));
   PDIDGZ pwspike1 (.PAD(i_wspike[1]), .C(wspikeI[1]));
   PDIDGZ pwspike2 (.PAD(i_wspike[2]), .C(wspikeI[2]));
   
   PDIDGZ pstate0 (.PAD(i_State[0]), .C(stateI[0]));
   PDIDGZ pstate1 (.PAD(i_State[1]), .C(stateI[1]));
   PDIDGZ pstate2 (.PAD(i_State[2]), .C(stateI[2]));
   PDIDGZ pstate3 (.PAD(i_State[3]), .C(stateI[3]));
   
   PDIDGZ pthres0 (.PAD(i_Thres[0]), .C(thresI[0]));
   PDIDGZ pthres1 (.PAD(i_Thres[1]), .C(thresI[1]));   
   PDIDGZ pthres2 (.PAD(i_Thres[2]), .C(thresI[2]));   
   PDIDGZ pthres3 (.PAD(i_Thres[3]), .C(thresI[3]));   
   PDIDGZ pthres4 (.PAD(i_Thres[4]), .C(thresI[4]));   
   PDIDGZ pthres5 (.PAD(i_Thres[5]), .C(thresI[5]));      

   PDO04CDG pv0 (.PAD(o_V[0]), .I(vO[0]));
   PDO04CDG pv1 (.PAD(o_V[1]), .I(vO[1]));
   PDO04CDG pv2 (.PAD(o_V[2]), .I(vO[2]));
   PDO04CDG pv3 (.PAD(o_V[3]), .I(vO[3]));
   PDO04CDG pv4 (.PAD(o_V[4]), .I(vO[4]));
   PDO04CDG pv5 (.PAD(o_V[5]), .I(vO[5]));
   
   PDO04CDG pspike (.PAD(o_spike), .I(spikeO));   
   PDO04CDG pscan_out (.PAD(scan_out), .I(scanO));
   
   PVSS1DGZ Pvss0();
   PVSS1DGZ Pvss1();
   PVSS1DGZ Pvss2();
   PVSS1DGZ Pvss3();
   PVDD1DGZ Pvdd0();
   PVDD1DGZ Pvdd1();
   PVDD1DGZ Pvdd2();
   PVDD1DGZ Pvdd3();
   
endmodule
