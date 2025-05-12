//`timescale 1ns/1ns
/*
* Project: NASH
* Module: LIF_neuron
* Version: 1.5 update signed membrane potential
*/
//`include "../parameters/common.v"
//`include "../parameters/LIF.v"
`define PRAGMA_SYN_OFF synopsys synthesis_off
`define PRAGMA_SYN_ON synopsys synthesis_on

`define LIF_WEIGHT_WIDTH        3
`define LIF_NEURON_OVRFL_WIDTH  3
`define LIF_THRESHOLD_WIDTH     `LIF_WEIGHT_WIDTH+`LIF_NEURON_OVRFL_WIDTH+1

`define LIF_RESET_V             0
`define LIF_LEAK                0
`define LIF_INV_LEAK            0 //`LIF_LEAK*(-1)
`define LIF_THRESHOLD           10

`define LIF_REFRAC_WITH 4 // set to 5
`define LIF_REFRAC 5

// Signed and unsigned for V and w:
// For pure SNN: unsigned V and w (biasing to reduce one bit of sign)
// For STDP (diehl and cook): signed V and unsigned w
// For ANN-to-SNN conversion: signed V and w

`define __SIGNED_V_POTEN__ 1
// `define __SIGNED_WEIGHT__ 1

// For the adaptive threshold option:
// For pure SNN: ???
// For STDP (diehl and cook): 1 (adaptived) (load from file/outside)
// For ANN-to-SNN conversion: 0 (fixed) ( value threshold = 2^ FRACTIONAL)
`define __ADAPTIVE_THRESHOLD__ 0 
`define DELTA_THRES 8 // 0.03125 in fractional
// Setting for async/sync reset (depend on FPGA/ASIC implemenation)
`define __RST_SENS__ //or negedge rst_n
// `define __LIF_V1_0__ 1
// `define __NO_LEARNING__ 1     // --> parameterize
// set this parameter to let the RAM interface of weight as output
`define __EXT_RAM_INF__ 1
`define INIT_RAM_FILE "../input/data.bin"
`define STATE_WIDTH 4
`define SPK_ARRAY_WIDTH 256 // should be similar to number of neural
`define WEIGHT_ADDR_WIDTH 8
`define NEURAL_ARRAY_WIDTH 256
`define NEURAL_ADDR_WIDTH 8
// for RAM model
`define RAM_DP_MODEL ram_dp_sr_sw
`define RAM_DW data_0_WIDTH
`define RAM_AW ADDR_WIDTH
`define RAM_DP RAM_DEPTH


////////////////////////////////////////////////////////////////////////////////
// State declarations
////////////////////////////////////////////////////////////////////////////////
`define ST_IDLE          `STATE_WIDTH'd0
// `define ST_DOWNLD_SPIKE  `STATE_WIDTH'd1 // remove it since we don't use spike vector
`define ST_GENSPK_A_COM  `STATE_WIDTH'd2
`define ST_LEAK          `STATE_WIDTH'd3
`define ST_FIRE          `STATE_WIDTH'd4
`define ST_UPLD_SPIKE    `STATE_WIDTH'd5
`define ST_RECC          `STATE_WIDTH'd6
`define ST_LEARN          `STATE_WIDTH'd7

`define ST_RESET_NET    `STATE_WIDTH'd8
`define ST_INIT_NET     `STATE_WIDTH'd8

// old state:
`ifdef __LIF_V1_0__
`define ST_LEAK_A_FIRE `STATE_WIDTH'd3
`endif


// Recurrent connection
//`define ENABLE_RECURRENT 1    // --> parameterize
`define FIX_RECURRENT_WEIGHT 16'h64ff //25600
//-3
`define ZERO_RECURRENT_WEIGHT 0


// Testbench params

// `define SYNTHETIC_INPUT 1
`define TRACE_VOLTAGE 0

////////////////////////////////////////////////////////////////////////////////
// Learning
////////////////////////////////////////////////////////////////////////////////
// It only work with 0/1 since the condition of LB is simplified (simple comparision)
`define DELTA_W_PRE     1
`define DELTA_W_POST    0
module LIF_neuron
#( 
    parameter WEIGHT_WIDTH           = `LIF_WEIGHT_WIDTH,
    parameter ENABLE_LB              = 0,
    parameter LIF_NEURON_OVRFL_WIDTH = `LIF_NEURON_OVRFL_WIDTH,
    parameter STATE_WIDTH            = `STATE_WIDTH,
    parameter THRESHOLD              = `LIF_THRESHOLD,
    parameter INV_LEAK               = `LIF_INV_LEAK,
    parameter REFRAC_TIME            = `LIF_REFRAC,
    parameter DELTA_THRES            = `DELTA_THRES,
    parameter WRAM_FOLDER            = "RAM",
    parameter TRACE_INPUT            = 0,
    parameter TRACE_VOLTAGE          = 0,
    parameter TRACE_THRESH           = 0,
    parameter INDEX                  = 0,
    parameter OUTPUT_REG             = 0
)(
`ifndef FIX_INTEFACE
    input                    clk,        // system clock
    input                    rst_n,      // system reset
    input [WEIGHT_WIDTH-1:0] i_wspike,   // input spike with weight
    input                    i_svalid,   // valid of spike
    // input [LIF_NEURON_OVRFL_WIDTH+WEIGHT_WIDTH-1:0] i_V, // input membrane potential
    input [STATE_WIDTH-1:0]  i_State,    // System State, for controlling
    input                    i_recc,
    `ifdef __ADAPTIVE_THRESHOLD__
    input [LIF_NEURON_OVRFL_WIDTH+WEIGHT_WIDTH-1:0] i_Thres,
    input                                           i_Thres_valid,
    `endif
    output [LIF_NEURON_OVRFL_WIDTH+WEIGHT_WIDTH-1:0] o_V,       // output for membrane potential
    output                                           o_spike    // output spike
`else
`endif
);
////////////////////////////////////////////////////////////////////////////////
// Wire/reg declarations
////////////////////////////////////////////////////////////////////////////////
// v1.1: +1 width for signal and under/overflow check
// v1.2: signed
`ifdef __SIGNED_V_POTEN__
    wire signed [1+WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0] w_acc_V_sum; 
    wire signed [1+WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0] w_acc_V_ovflw; 
    wire signed [1+WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0] w_acc_V_leak; 
    wire signed [1+WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0] w_acc_V_leak_ovflw; 
    wire signed [WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0]   w_acc_V;
    reg  signed [WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0]   r_acc_V;
    reg signed [WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0]   r_const_threshold;
    wire signed [1+WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0] w_leak;
`else
    wire [1+WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0] w_acc_V_sum; 
    wire [1+WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0] w_acc_V_ovflw; 
    wire [1+WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0] w_acc_V_leak; 
    wire [1+WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0] w_acc_V_leak_ovflw; 
    wire [WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0]   w_acc_V;
    reg  [WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0]   r_acc_V;
    reg [WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0]   r_const_threshold;
    wire [1+WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0] w_leak;
`endif

//wire w_leak_en;
   reg r_leak_en;
//wire w_spike;
   reg r_spike;

// v1.3: refractory
reg  [`LIF_REFRAC_WITH-1:0] r_refrac; 
wire [`LIF_REFRAC_WITH-1:0] w_nxt_refrac;

// v1.4 variable threshold

`ifdef __ADAPTIVE_THRESHOLD__
    `ifdef __SIGNED_V_POTEN__
        reg signed [WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0] r_threshold;
        reg signed [WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0] r_delta_thres;
    `else
        reg [WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0] r_threshold;
        reg [WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0] r_delta_thres;
    `endif
`endif

// 1.5 recurrent mode:

wire [1+WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0] w_recc_val; 
////////////////////////////////////////////////////////////////////////////////
// Wire assignments
////////////////////////////////////////////////////////////////////////////////
`ifdef __SIGNED_V_POTEN__
    `ifdef __SIGNED_WEIGHT__
//        assign w_acc_V_sum  = (w_leak_en == 1'b0) ?
        assign w_acc_V_sum  = (r_leak_en == 1'b0) ?			      
			      {r_acc_V[WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1],r_acc_V} + {{LIF_NEURON_OVRFL_WIDTH+1{i_wspike[WEIGHT_WIDTH-1]}},i_wspike} :
                              {r_acc_V[WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1],r_acc_V} ; // remove + `LIF_INV_LEAK
    `else
//        assign w_acc_V_sum  = (w_leak_en == 1'b0) ?
        assign w_acc_V_sum  = (r_leak_en == 1'b0) ?			      
			      {r_acc_V[WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1],r_acc_V} + {{LIF_NEURON_OVRFL_WIDTH+1{1'b0}},i_wspike} :
                              {r_acc_V[WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1],r_acc_V} ; // remove + `LIF_INV_LEAK
    `endif
    assign w_acc_V_ovflw        = (w_acc_V_sum[WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH]==1'b0 &&
				   w_acc_V_sum[WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1]==1'b1) ?
				  {2'b00,{WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1{1'b1}} } : 
                                 (w_acc_V_sum[WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH]==1'b1 &&
				   w_acc_V_sum[WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1]==1'b0 ) ?
				  {2'b11,{WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1{1'b0}} } :
				  w_acc_V_sum;
    assign w_acc_V_leak         = (i_recc == 1'b1) ? 
				  w_acc_V_ovflw - w_recc_val:
//                                  (w_leak_en == 1'b0) ?
                                  (r_leak_en == 1'b0) ?				  
				  w_acc_V_ovflw :
				  w_acc_V_ovflw+ w_leak;
    assign w_acc_V_leak_ovflw   = (w_acc_V_leak[WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH]==1'b0 &&
				   w_acc_V_leak[WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1]==1'b1) ?
				  {2'b00,{WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1{1'b1}} } : 
                                  (w_acc_V_leak[WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH]==1'b1 &&
				   w_acc_V_leak[WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1]==1'b0) ?
				  {2'b11,{WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1{1'b0}} } :
				  w_acc_V_leak;
    assign w_acc_V              = w_acc_V_leak_ovflw[WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0];
`else
    assign w_acc_V_sum          = (r_leak_en == 1'b0)? {1'b0,r_acc_V} + {{LIF_NEURON_OVRFL_WIDTH+1{1'b0}},i_wspike}:
                                  r_acc_V ; // remove + `LIF_INV_LEAK
    assign w_acc_V_ovflw        = (w_acc_V_sum[WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH]==1'b1)? {1'b0,{WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH{1'b1}} }: w_acc_V_sum;
    assign w_acc_V_leak         = (i_recc == 1'b1)? w_acc_V_ovflw - w_recc_val:
                                  (r_leak_en == 1'b0)?w_acc_V_ovflw: w_acc_V_ovflw+ `LIF_INV_LEAK;
    assign w_acc_V_leak_ovflw   = (w_acc_V_leak[WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH]==1'b1)? {1'b0,{WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH{1'b0}} }: w_acc_V_leak;
    assign w_acc_V              = w_acc_V_leak_ovflw[WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0];
`endif
//`ifdef __SIGNED_V_POTEN__
   // note: i have problem with comparing signed values, so I force r_acc_V as position first
//   assign w_spike          = (i_State == `ST_FIRE && $signed(r_acc_V) >= $signed(w_threshold))? 1'b1:1'b0;
   // assign w_spike          = (i_State == `ST_FIRE && r_acc_V[WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1] == 1'b0 && $signed(r_acc_V) >= $signed(w_threshold))? 1'b1:1'b0;
//`else
//   assign w_spike          = (i_State == `ST_FIRE && r_acc_V >= r_const_threshold)? 1'b1:1'b0;
//`endif
//assign w_leak_en        = (i_State == `ST_LEAK)? 1'b1:1'b0;
assign w_recc_val       = `FIX_RECURRENT_WEIGHT;
assign w_leak           = INV_LEAK;

// v1.3: refractory


//v 1.4 variable threshold
`ifdef __ADAPTIVE_THRESHOLD__
    assign w_threshold      = r_threshold;
`else
    assign w_threshold      = THRESHOLD;
`endif
////////////////////////////////////////////////////////////////////////////////
// Seq. processes
////////////////////////////////////////////////////////////////////////////////
always @ (posedge clk) begin
    if (~rst_n) begin
       r_acc_V <= 0;
       r_leak_en <= 0;
       r_spike <= 0;
    end
    else begin
       if (i_State == `ST_FIRE && r_acc_V >= r_const_threshold) begin
	  r_spike <= 1'b1;
       end else begin
	  r_spike <= 1'b0;
       end

       if (i_State == `ST_LEAK) begin
	  r_leak_en <= 1'b1;
       end else begin
	  r_leak_en <= 1'b0;
       end
       
       if (r_spike | r_refrac != 0) // v1.3 add refractory
         r_acc_V <= 0;
       else if (r_leak_en | i_svalid | i_recc)
         r_acc_V <= w_acc_V;
    end
end

//v 1.3 refractory

always @ (posedge clk) begin
    if (~rst_n)
        r_refrac <= 0;
    else begin
       if (r_spike) begin
	  r_refrac <= REFRAC_TIME;
       end else begin
	  if (r_refrac != 0 && i_State == `ST_FIRE) begin
	     r_refrac <= r_refrac - 1;
	  end
       end
    end
end

//v 1.4 variable threshold
`ifdef __ADAPTIVE_THRESHOLD__
always @ (posedge clk) begin
    if (~rst_n) begin
        r_threshold <= THRESHOLD;
        r_const_threshold <= 10;
        r_delta_thres    <= DELTA_THRES;
    end
    else if (i_Thres_valid) begin
        r_threshold <= {i_Thres};
// synopsys translate_off
        // $display("Loading threshold at %m");
        // #(1);
        // $display("  >> with value %d", i_Thres);
// synopsys translate_on
    end else if (r_spike == 1'b1 && ENABLE_LB == 1) begin
        r_threshold <= r_threshold + r_delta_thres;
    end
end
`endif
////////////////////////////////////////////////////////////////////////////////
// Output registers: for timing check only, please disable if you dont need
////////////////////////////////////////////////////////////////////////////////
generate 
if (OUTPUT_REG == 1) begin : OUTPUTREG
    reg [WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0] or_V;
    reg [WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0] or_spike;
    always @ (posedge clk) begin
        if (~rst_n) begin
            or_V <= `LIF_RESET_V;
            or_spike <= 1'b0;
        end else begin
            or_V <= r_acc_V;
            or_spike <= r_spike;
        end
    end
    assign o_V = or_V;
    assign o_spike = or_spike;
end else begin  : NO_OUTPUTREG
    assign o_V = r_acc_V;
    assign o_spike = r_spike;
end
endgenerate


////////////////////////////////////////////////////////////////////////////////
// Trace block (not synthesized)
////////////////////////////////////////////////////////////////////////////////
// synopsys translate_off

integer spike_trace_file, voltage_trace_file, threshold_trace_file, s_i;
reg [41*8:1] winput_file_name;
reg [41*8:1] voltage_file_name;
reg [41*8:1] threshold_file_name;

reg [3*8:1] w_folder = WRAM_FOLDER;

integer t0, t1, t2, t3;
initial begin
    s_i = 0;
    winput_file_name   = "../trace/XXX/W_INPT/INPUT_NEURON_XXXX.csv";
    voltage_file_name = "../trace/XXX/MEM_PO/MEM-P_NEURON_XXXX.csv";
    threshold_file_name = "../trace/XXX/THRESH/THRES_NEURON_XXXX.csv";
            
    t3 = (INDEX/32'd1000) % 32'd10; 
    t2 = (INDEX/32'd100) % 32'd10; 
    t1 = (INDEX/32'd10) % 32'd10; 
    t0 = INDEX % 32'd10; 
    winput_file_name [40:33] = "0" + t0; 
    winput_file_name [48:41] = "0" + t1; 
    winput_file_name [56:49] = "0" + t2; 
    winput_file_name [64:57] = "0" + t3; 
    
    voltage_file_name [64:33] = winput_file_name [64:33];
    threshold_file_name [64:33] = winput_file_name [64:33];

    winput_file_name [32*8:29*8+1] = w_folder;
    voltage_file_name [32*8:29*8+1] = w_folder;
    threshold_file_name [32*8:29*8+1] = w_folder;

    // $display("WRAM = %s", w_folder );
    // $display("Voltage trace of = %s", voltage_file_name );
    // $display("Input trace of = %s", winput_file_name );
    if (TRACE_INPUT == 1) begin
        s_i = 10;
        spike_trace_file = $fopen(winput_file_name, "w");
    end

    if (TRACE_VOLTAGE == 1) begin
        voltage_trace_file = $fopen(voltage_file_name, "w");
        s_i = 20;
    end
    if (TRACE_THRESH == 1) begin
        threshold_trace_file = $fopen(threshold_file_name, "w");
        s_i = 30;
    end
    @(i_Thres_valid == 1'b1);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    // $display("Neuron ID = %d", INDEX);
    // $display("Threshold = %d", w_threshold);
    
end

// always @(posedge clk) begin
//     if (s_i != 0) begin
//         if (i_svalid) begin
//             // $display("%d,",i_wspike);
//             $fwrite(spike_trace_file, "%d,",i_wspike);
//         end
        
//         if (i_State == `ST_DOWNLD_SPIKE) begin
//             // $display("%d,",i_wspike);
//             $fwrite(voltage_trace_file, "%d,",r_acc_V);
//         end

//         if (i_State == `ST_DOWNLD_SPIKE) begin
//             // $display("%d,",i_wspike);
//             $fwrite(threshold_trace_file, "%d,",r_threshold);
//         end

//         // if (i_State == `ST_FIRE) begin
//         //     s_i = 0;
//         //     $fclose(spike_trace_file);
//         // end
            
//     end
// end
// synopsys translate_on
endmodule // LIF_neuron
