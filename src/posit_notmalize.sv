`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: Ledoux Louis
// 
// Create Date: 11/20/2018 10:12:00 PM
// Design Name: 
// Module Name: posit_normalize
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: 
//
//  Not a generic module, aims to work with 16b posit
//
//
//  - light axi stream control
//  - input :
//     - sign         : 1 if neg 0 otherwise
//     - inf          : boolean 1 if inifinite 0 otherwise
//     - zero         : 1 if 0, 0 otherwise
//     - scale        : ((2^2^es)^regime) * 2^exp = 2^((2^es)*regime + exp)
//         => scale width = sup_rounding(log2(2^es * (nbits - 1) - 1))
//     - fraction     : "matissa" part
//         => fraction width = N - ES - 1(sign bit) - 2(smallest regime size)
//  - output : 
//       
//////////////////////////////////////////////////////////////////////////////////

import posit_defines::*;

module posit_normalize #(
    parameter integer C_WIDTH = 16,
    parameter integer C_ES    = 0,
    parameter integer C_SCALE_WIDTH = $clog2(((2<<C_ES) * (C_WIDTH-1)) -1),
    parameter integer C_FRACTION_WIDTH = C_WIDTH - C_ES - 3 
)
(
 
    // input
    output logic sign,
    output logic inf,
    output logic zero,
    output logic [C_SCALE_WIDTH-1:0] scale,
    output logic [C_FRACTION_WIDTH-1:0] fraction,
    
    // output
    input  logic [C_WIDTH-1:0] posit_word_i
    
);

endmodule

