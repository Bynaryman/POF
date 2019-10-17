`default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: Ledoux Louis
// 
// Create Date: 16/09/19 10:37AM
// Design Name: 
// Module Name: posit_denormalize
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
//     - 16/9/19 : update dual LOD/LZD by cpt1+LOD
//     - 16/9/19 : update inf to NaR
//     - 16/9/19 : add prefixe _o for output
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

module posit_denormalize_I #(
    parameter integer POSIT_WIDTH = 32,
    parameter integer POSIT_ES    = 2
)
(
    // slave side
    input  wire [POSIT_WIDTH-1:0] posit_word_i,

    // master
    pd_control_if.master_wo_c denormalized 

);

localparam integer scale_width    = get_scale_width(POSIT_WIDTH, POSIT_ES, NORMAL);
localparam integer fraction_width = get_fraction_width(POSIT_WIDTH, POSIT_ES, NORMAL);

// intermediate signals for interface output
logic sign_o;
logic NaR_o;
logic zero_o;
logic [fraction_width-1:0] fraction_o;
logic [scale_width-1:0] scale_o;

// #0  in regime or in cpt1 regime (1 is minus 1 see posit rules)
logic [$clog2(POSIT_WIDTH-1)-1:0] k0;
// unsigned input
logic [POSIT_WIDTH-2:0] posit_word_i_u;
// useed^k, max value of k can be 16 so 4 bits needed
logic [$clog2(POSIT_WIDTH-1)-1:0] absolute_k;

logic [POSIT_WIDTH-1:0] exp_and_frac;
logic signed [scale_width-1:0] regime_scale;
logic [$clog2(POSIT_WIDTH)-1:0] regime_width;

// Determine sign of posit
assign sign_o = posit_word_i[POSIT_WIDTH-1];

// Determine Zero and Infinite cases
assign NaR_o  =  sign_o & ~( |posit_word_i[POSIT_WIDTH-2:0] );
assign zero_o = ~sign_o & ~( |posit_word_i[POSIT_WIDTH-2:0] );

// if negative input, take 2's complement
assign posit_word_i_u = (sign_o)? -posit_word_i[POSIT_WIDTH-2:0] : posit_word_i[POSIT_WIDTH-2:0];

// bit to know if we count 0s or 1s
logic regime_check;
assign regime_check = posit_word_i_u[POSIT_WIDTH-2];

// take the cpt1 to count 0s if they are 1s regime
logic [POSIT_WIDTH-2:0] posit_word_i_u_cpt1;
assign posit_word_i_u_cpt1 = (regime_check)? ~posit_word_i_u : posit_word_i_u;

// count 0 with LOD
LOD_N  # (
    .C_N ( POSIT_WIDTH-1 )
)
lod_zero_counter (
    .in  ( posit_word_i_u_cpt1 ),
    .out ( k0                  )
);

// count 1 with LZD
// k = (number of 1) - 1 so we start LZD 1 bit after
// LZD_N  # (
//     .C_N ( POSIT_WIDTH )
// ) lzd_one_counter 
// (
//     .in  ( {posit_word_i_u[POSIT_WIDTH-3:0], 2'b0} ),
//     .out ( k1                                  )
// );

// if first regime bit = 1 then with choose #1, #0 otherwise
assign absolute_k = regime_check ? k0-1 : k0;

// compute the regime scale
// scale = regime scale + exp scale
// scale = k * (2^es)   + exp
// scale = k << es      + exp
assign regime_scale = regime_check ? (absolute_k << POSIT_ES) : -(absolute_k << POSIT_ES);
assign regime_width = k0 ;// regime_check ? k0;


// remove sign and regime bits
assign exp_and_frac = posit_word_i_u << (regime_width + 2);

// compute scale
// handle exponent size 0 case
generate
    if (POSIT_ES==0) begin
        assign scale_o = regime_scale;
    end
    else begin
        assign scale_o = regime_scale + exp_and_frac[POSIT_WIDTH-1:POSIT_WIDTH-POSIT_ES];
    end
endgenerate


// compute frac
generate
    if ((POSIT_WIDTH - POSIT_ES -3) > 0) begin  // if posit configuration allows mantissa to exist
        assign fraction_o = exp_and_frac[POSIT_WIDTH-POSIT_ES-1:3];
    end
    else begin
        assign fraction_o = 0;
    end
endgenerate

// assign to interfaces pins
assign denormalized.sign     = sign_o;
assign denormalized.NaR      = NaR_o;
assign denormalized.zero     = zero_o;
assign denormalized.scale    = scale_o;
assign denormalized.fraction = fraction_o;
assign denormalized.guard    = 1'b0;
assign denormalized.round    = 1'b0;
assign denormalized.sticky   = 1'b0;

endmodule
`default_nettype wire