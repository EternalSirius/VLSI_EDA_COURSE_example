//`timescale 1ns/1ns
//`include "../../RTL/parameters/common.v"
//`include "../../RTL/parameters/LIF.v"
`define CLK_PERIOD 5
// Setting for async/sync reset (depend on FPGA/ASIC implemenation)
`define __RST_SENS__  //or negedge rst_n
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
`define __ADAPTIVE_THRESHOLD__ 1 
`define DELTA_THRES 8 // 0.03125 in fractional

// `define __DFT_MODE__ 1
`timescale 1ns/10ps
module TB_LIF_neuron;

parameter WEIGHT_WIDTH   = `LIF_WEIGHT_WIDTH;
parameter LIF_NEURON_OVRFL_WIDTH = `LIF_NEURON_OVRFL_WIDTH;
parameter STATE_WIDTH    = `STATE_WIDTH;
parameter THRESHOLD      = 10;
////////////////////////////////////////////////////////////////////////////////
// Wire/reg declarations
////////////////////////////////////////////////////////////////////////////////
reg clk;
reg rst_n;

reg signed [WEIGHT_WIDTH-1:0] i_wspike;  
reg                    i_svalid;   
reg [STATE_WIDTH-1:0]  i_State;    

wire [WEIGHT_WIDTH+LIF_NEURON_OVRFL_WIDTH-1:0] o_V;   
wire                    o_spike;
wire [LIF_NEURON_OVRFL_WIDTH+WEIGHT_WIDTH-1:0] w_Thres;
integer r_timestep_cnt;


`ifdef __DFT_MODE__
   reg i_test_mode, i_scan, i_scan_en;
   wire o_scan, o_sdo;
   
   LIF_neuron LIF0
     (
      .clk (clk),
      .rst_n (rst_n),
      .i_wspike (i_wspike),
      .i_svalid (i_svalid),
      .i_State  (i_State),
      .i_recc   (1'b0),
      .i_Thres  (w_Thres),
      .i_Thres_valid (1'b1),
      .sdi_1 (1'b0),
      .scan_en  (i_scan_en),
      .test_mode (i_test_mode),
      .scan_in  (i_scan),
      .o_V (o_V),
      .sdo_1 (o_sdo),
      .o_spike (o_spike),
      .scan_out (o_scan)
      );
`else
LIF_neuron 
// #(
//   .WEIGHT_WIDTH           (WEIGHT_WIDTH),
//   .LIF_NEURON_OVRFL_WIDTH (LIF_NEURON_OVRFL_WIDTH), 
//   .OUTPUT_REG             (0)
// )
 LIF0 (
  .clk          (clk),
  .rst_n        (rst_n),

  .i_wspike     (i_wspike),
  .i_svalid     (i_svalid),
  .i_State      (i_State),
  .i_recc       (1'b0),
  .i_Thres      (w_Thres),
  .i_Thres_valid (1'b1),

  .o_V          (o_V),
  .o_spike      (o_spike)
);
`endif 
   
assign w_Thres = THRESHOLD;

always #(`CLK_PERIOD/2) clk = ~clk;
integer i,j;

initial begin
  i = 0; j = 0;
  i_svalid = 1'b0;
  i_wspike = 0;
  i_State = `ST_IDLE;
  /////////////////////////////////////////////////////////
  clk = 1'b0;
  rst_n = 1'b0;
`ifdef __DFT_MODE__
   i_scan_en = 1'b0;
   i_scan = 1'b0;
   i_test_mode = 1'b0;
`endif
  #(2*`CLK_PERIOD-1);
  rst_n = 1'b1;
  #(1*`CLK_PERIOD-1);
  @(posedge clk);
  /////////////////////////////////////////////////////////
  i_State = `ST_GENSPK_A_COM;
`ifdef __DFT_MODE__
   i_scan_en = 1'b1;
   i_scan = 1'b1;
   i_test_mode = 1'b0;
`endif
  for (i=0; i <50; i=i+1) begin
    @(posedge clk);
    i_svalid = 1'b1;
    i_wspike = $urandom_range(1,5) - 120;
  end

  @(posedge clk);
  i_svalid = 1'b0;
`ifdef __LIF_V1_0__
  i_State = `ST_LEAK_A_FIRE;
`else
  i_State = `ST_LEAK;
  @(posedge clk);
  i_State = `ST_FIRE;
`endif
  @(posedge clk);

  /////////////////////////////////////////////////////////
  i_State = `ST_GENSPK_A_COM;
  
  for (i=0; i <50; i=i+1) begin
    @(posedge clk);
    i_svalid = 1'b1;
    i_wspike = $urandom_range(1,2)+60;
  end

  @(posedge clk);
  i_svalid = 1'b0;
`ifdef __LIF_V1_0__
  i_State = `ST_LEAK_A_FIRE;
`else
  i_State = `ST_LEAK;
  @(posedge clk);
  i_State = `ST_FIRE;
`endif
  @(posedge clk);

  /////////////////////////////////////////////////////////
  i_State = `ST_GENSPK_A_COM;
  
  for (i=0; i <50; i=i+1) begin
    @(posedge clk);
    i_svalid = 1'b1;
    i_wspike = $urandom_range(1,2)+120;
  end

  @(posedge clk);
  i_svalid = 1'b0;
`ifdef __LIF_V1_0__
  i_State = `ST_LEAK_A_FIRE;
`else
  i_State = `ST_LEAK;
  @(posedge clk);
  i_State = `ST_FIRE;
`endif
  @(posedge clk);
  for (j = 0; j < 20 ; j=j+1 ) begin
    /////////////////////////////////////////////////////////
    i_State = `ST_GENSPK_A_COM;
    
    for (i=0; i <50; i=i+1) begin
      @(posedge clk);
      i_svalid = 1'b1;
      i_wspike = $urandom_range(1,2)+50;
    end

    @(posedge clk);
    i_svalid = 1'b0;
  `ifdef __LIF_V1_0__
    i_State = `ST_LEAK_A_FIRE;
  `else
    i_State = `ST_LEAK;
    @(posedge clk);
    i_State = `ST_FIRE;
  `endif
    @(posedge clk);
    
  end

  $stop;
end


always @(posedge clk) begin
  if (~rst_n) begin
    r_timestep_cnt = 0;
  end else begin
    if (i_State == `ST_FIRE) begin
      r_timestep_cnt = r_timestep_cnt+1;
    end
  end 
end
endmodule
