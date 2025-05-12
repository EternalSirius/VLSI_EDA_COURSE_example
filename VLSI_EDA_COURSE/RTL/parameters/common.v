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