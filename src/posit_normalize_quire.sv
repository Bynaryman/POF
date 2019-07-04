`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: LEDOUX Louis
// 
// Create Date: 12/17/2018 03:31:55 PM
// Design Name: 
// Module Name: posit_normalize_quire
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
//////////////////////////////////////////////////////////////////////////////////

import posit_defines::*;

module posit_normalize_quire #
(
    parameter integer QUIRE_IN_WIDTH = 128,
    parameter integer POSIT_OUT_WIDTH = 16,
    parameter integer POSIT_IN_WIDTH = 16,
    parameter integer POSIT_IN_ES = 1
)
(
    // SLAVE SIDE   
    input  logic [QUIRE_IN_WIDTH-1:0] quire_i ,
    
    // MASTER SIDE    
    output logic [POSIT_OUT_WIDTH-1:0] posit_o 

);

localparam integer MSB = QUIRE_IN_WIDTH-1;
localparam integer fraction_width = (`GET_FRACTION_WIDTH( POSIT_IN_WIDTH, POSIT_IN_ES, 1 ));
localparam integer fraction_width_norm = (`GET_FRACTION_WIDTH( POSIT_IN_WIDTH, POSIT_IN_ES, 0 ));
localparam integer scale_width = (`GET_SCALE_WIDTH( POSIT_IN_WIDTH, POSIT_IN_ES, 1 )) + 1; // adding 1 bit to handle carry bits overflow

// localparam to compute size binary point offsets
localparam integer es = POSIT_IN_ES;
localparam integer posit_width = POSIT_IN_WIDTH;
localparam integer nqmin = (2**(es+2))*(posit_width-2)+1;
localparam integer log_nb_accum = posit_width-1;
localparam integer nq = nqmin + log_nb_accum;
localparam integer binary_point_position = (nqmin-1)/2;
localparam integer bpp_lsb = binary_point_position - fraction_width;
localparam integer bias_sf_mult = (2**(es+1))*(posit_width-2);


logic [QUIRE_IN_WIDTH-1:0] mag_quire;
logic signed [scale_width-1:0] scale_quire;
logic [fraction_width-1:0] fraction_quire;
logic sign_quire;
logic [$clog2(QUIRE_IN_WIDTH)-1:0] zero_counter;

// get sign of quire
assign sign_quire = quire_i[MSB];

// get 2's comp if quire is negative
assign mag_quire = (sign_quire)? -quire_i: quire_i;

// get number of leading zeros in mag quire
LOD_N #(
    .C_N ( QUIRE_IN_WIDTH )
) lod_inst (
    .in  ( mag_quire    ),
    .out ( zero_counter )
);

// Fraction and scale extraction
assign fraction_quire = (mag_quire >> (QUIRE_IN_WIDTH - zero_counter - 1 - fraction_width  ));
//assign scale_quire = zero_counter - bias_sf_mult;
assign scale_quire =  $signed(QUIRE_IN_WIDTH - zero_counter - 1) - $signed(binary_point_position);

logic [es-1:0] result_exponent;
if ( es > 0 ) begin
    assign result_exponent = scale_quire % (2 << es);
end


logic [7:0] regime_shift_amount;
assign regime_shift_amount = (scale_quire[scale_width-1] == 0) ? 1 + (scale_quire >> es) : -(scale_quire >> es);

/*logic [QUIRE_IN_WIDTH-1:0] fraction_leftover;
logic [7:0] leftover_shift;
assign leftover_shift = POSIT_OUT_WIDTH - 4 - regime_shift_amount;

// Determine all fraction bits that are truncated in the final result
shift_left #(
    .N(FBITS_ACCUM),
    .S(8)
) fraction_leftover_shift (
    .a(in.fraction),
    .b(leftover_shift), // Shift to right by regime value (clip at maximum number of bits)
    .c(fraction_leftover)
);

logic sticky_bit;
assign sticky_bit = truncated | |fraction_leftover[FBITS_ACCUM-2:0]; // Logical OR of all truncated fraction multiplication bits

logic [28:0] fraction_truncated;
assign fraction_truncated = {in.fraction[FBITS_ACCUM-1:FBITS_ACCUM-28], sticky_bit | in.fraction[FBITS_ACCUM-29]};
*/

//logic [(`GET_FRACTION_WIDTH( POSIT_IN_WIDTH, POSIT_IN_ES, 0 ))-1:0] frac_trunc;
//assign frac_trunc = fraction_quire[fraction_width-1:fraction_width-(`GET_FRACTION_WIDTH( POSIT_IN_WIDTH, POSIT_IN_ES, 0 ))-2];
logic [2*POSIT_OUT_WIDTH-1:0] regime_exp_fraction;
if ( es > 0 ) begin
    assign regime_exp_fraction = { {POSIT_OUT_WIDTH-1{~scale_quire[scale_width-1]}}, // Regime leading bits
                            scale_quire[scale_width-1], // Regime terminating bit
                            result_exponent, // Exponent
                            fraction_quire[fraction_width-1:fraction_width-1-fraction_width_norm] }; // Fraction
end
else begin
    assign regime_exp_fraction = { {POSIT_OUT_WIDTH-1{~scale_quire[scale_width-1]}}, // Regime leading bits
                            scale_quire[scale_width-1], // Regime terminating bit
                             // Exponent
                            fraction_quire[fraction_width-1:fraction_width-1-fraction_width_norm] }; // Fraction
end

logic [2*POSIT_OUT_WIDTH-1:0] exp_fraction_shifted_for_regime;
shift_right #(
    .N(2*POSIT_OUT_WIDTH),
    .S(8)
) shift_in_regime (
    .a(regime_exp_fraction), // exponent + fraction bits
    .b(regime_shift_amount), // Shift to right by regime value (clip at maximum number of bits)
    .c(exp_fraction_shifted_for_regime)
);

// Determine result (without sign), the unsigned regime+exp+fraction
logic [POSIT_OUT_WIDTH-2:0] result_no_sign;
assign result_no_sign = exp_fraction_shifted_for_regime[POSIT_OUT_WIDTH-2:0];

//logic bafter;
//assign bafter = fraction_leftover[FBITS_ACCUM-1];

// Perform rounding (based on sticky bit)
//logic blast, tie_to_even, round_nearest;
//logic [POSIT_OUT_WIDTH-2:0] result_no_sign_rounded;

//assign blast = result_no_sign[0];
//assign tie_to_even = blast & bafter; // Value 1.5 -> round to 2 (even)
//assign round_nearest = bafter & sticky_bit; // Value > 0.5: round to nearest

//assign result_no_sign_rounded = (tie_to_even | round_nearest) ? (result_no_sign + 1) : result_no_sign;

// In case the product is negative, take 2's complement of everything but the sign
logic [POSIT_OUT_WIDTH-2:0] signed_result_no_sign;
assign signed_result_no_sign = quire_i[MSB] ? -result_no_sign[POSIT_OUT_WIDTH-2:0] : result_no_sign[POSIT_OUT_WIDTH-2:0];

logic zero, nar;
assign zero = ~(|quire_i);
assign nar = quire_i[MSB] & ~(|quire_i[MSB-1:0]);

// Final output
assign posit_o = (zero | nar) ? {nar, {POSIT_OUT_WIDTH-1{1'b0}}} : {quire_i[MSB], signed_result_no_sign[POSIT_OUT_WIDTH-2:0]};


endmodule
