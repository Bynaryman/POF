`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: Ledoux Louis
// 
// Create Date: 11/13/2018 03:49:24 PM
// Design Name: 
// Module Name: posit_data_extract
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
//
//  - input :
//     - posit_word_i : a N bits posit word from a Posit<N,ES> 
//       where N = POSIT_WIDTH ; ES = POSIT_ES
//  - output : 
//     - sign         : 1 if neg 0 otherwise
//     - inf          : aka NaR, boolean 1 if not a real (inf et al) 0 otherwise
//     - zero         : 1 if 0, 0 otherwise
//     - scale        : ((2^2^es)^regime) * 2^exp = 2^((2^es)*regime + exp)
//         => scale width = sup_rounding(log2(2^es * (nbits - 1) - 1))+1
//     - fraction     : "mantissa" part
//         => fraction width = N - ES - 1(sign bit) - 2(smallest regime size)
//       
//////////////////////////////////////////////////////////////////////////////////

import posit_defines::*;

module posit_data_extract #(
    parameter integer POSIT_WIDTH = 8,
    parameter integer POSIT_ES    = 0
)
(

    // System signals
    //input  logic clk,
    //input  logic rst_n,
    
    // slave side
    //output logic rtr_o,
    //input  logic rts_i,    
    input  logic [POSIT_WIDTH-1:0] posit_word_i,

    // master side
    //input  logic rtr_i,
    //output logic rts_o,
    output logic sign,
    output logic inf,
    output logic zero,
    output logic [(`GET_SCALE_WIDTH(POSIT_WIDTH, POSIT_ES, 0))-1:0] scale,
    output logic [(`GET_FRACTION_WIDTH(POSIT_WIDTH, POSIT_ES, 0))-1:0] fraction
);


localparam scale_width = (`GET_SCALE_WIDTH(POSIT_WIDTH, POSIT_ES, 0));

// #0 or #1 in regime (1 is minus 1 see posit rules)
logic [$clog2(POSIT_WIDTH)-1:0] k0, k1;
// unsigned input
logic [POSIT_WIDTH-1:0] posit_word_i_u;
// useed^k, max value of k can be 16 so 4 bits needed
logic [$clog2(POSIT_WIDTH)-1:0] k;

logic [POSIT_WIDTH-1:0] exp_and_frac;
logic signed [scale_width-1:0] regime_scale;
logic [$clog2(POSIT_WIDTH)-1:0] regime_width;

// Determine sign of posit
assign sign = posit_word_i[POSIT_WIDTH-1];

// Determine Zero and Infinite cases
assign inf  =  sign & ~( |posit_word_i[POSIT_WIDTH-2:0] );
assign zero = ~sign & ~( |posit_word_i[POSIT_WIDTH-2:0] );

// if negative input, take 2's complement
assign posit_word_i_u = (sign)? -posit_word_i : posit_word_i;

// count 0 with LOD
LOD_N  # (
    .C_N ( POSIT_WIDTH )
)
lod_zero_counter (
    .in  ( {posit_word_i_u[POSIT_WIDTH-2:0], 1'b0} ),
    .out ( k0                                  )
);

// count 1 with LZD
// k = (number of 1) - 1 so we start LZD 1 bit after
LZD_N  # (
    .C_N ( POSIT_WIDTH )
) lzd_one_counter 
(
    .in  ( {posit_word_i_u[POSIT_WIDTH-3:0], 2'b0} ),
    .out ( k1                                  )
);

// if first regime bit = 1 then with choose #1, #0 otherwise
assign k = posit_word_i_u[POSIT_WIDTH-2] ? k1 : k0;

// compute the regime scale
// scale = regime scale + exp scale
// scale = k * (2^es)   + exp
// scale = k << es      + exp
assign regime_scale = posit_word_i_u[POSIT_WIDTH-2] ? (k << POSIT_ES) : -(k << POSIT_ES);
assign regime_width = posit_word_i_u[POSIT_WIDTH-2] ? (k1+1) : k0;


// remove sign and regime bits
assign exp_and_frac = posit_word_i_u << (regime_width + 2);

// compute scale
// handle exponent size 0 case
generate
    if (POSIT_ES==0) begin
        assign scale = regime_scale;
    end
    else begin
        assign scale = regime_scale + exp_and_frac[POSIT_WIDTH-1:POSIT_WIDTH-POSIT_ES];
    end
endgenerate


// compute frac
assign fraction = exp_and_frac[POSIT_WIDTH-POSIT_ES-1:3];

endmodule
