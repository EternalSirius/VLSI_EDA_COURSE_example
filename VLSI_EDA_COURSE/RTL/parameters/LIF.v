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
