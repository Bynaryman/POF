`default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: Ledoux Louis
// 
// Create Date: 04/10/19 10:37AM
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
// Revision 0.01 - File Created
// Additional Comments: 
//
//
//       
//////////////////////////////////////////////////////////////////////////////////

import posit_defines::*;

module posit_normalize_I #(
    parameter integer POSIT_WIDTH         = 32,
    parameter integer POSIT_ES            = 2,
    parameter pd_type PD_TYPE             = NORMAL,
    parameter rounding_type ROUNDING_MODE = RNTE
)
(
    // slave side
    pd_control_if.slave_wo_c denormalized,

    // master
    output  wire [POSIT_WIDTH-1:0] posit_word_o

);

localparam integer scale_width    = get_scale_width(POSIT_WIDTH, POSIT_ES, PD_TYPE);
localparam integer fraction_width = get_fraction_width(POSIT_WIDTH, POSIT_ES, PD_TYPE);

logic [2:0] GRS;
assign GRS = {
    denormalized.guard,
    denormalized.round,
    denormalized.sticky
};
//assign GRS = 3'b0;

// part x
// compute the regime and exponent(if any)
// and pack it into a big(2*POSIT_WIDTH+3) unsigned unrounded result
logic [$clog2(POSIT_WIDTH):0] k;
localparam integer scratchpad_width = POSIT_WIDTH-1+1+POSIT_ES+fraction_width+3;
logic [scratchpad_width-1:0] extended_regime_exp_fraction_GRS;
if (POSIT_ES==0) begin
    assign k = (~denormalized.scale[scale_width-1])? 1+denormalized.scale : -denormalized.scale;
    assign extended_regime_exp_fraction_GRS = { {POSIT_WIDTH-1{~denormalized.scale[scale_width-1]}},  // regime
                                                denormalized.scale[scale_width-1],                    // regime term
                                                denormalized.fraction,                                // fraction
                                                GRS                                                   // GRS
                                              };
end
else begin
    logic [POSIT_ES-1:0] exponent;
    assign k = (~denormalized.scale[scale_width-1])? 1+(denormalized.scale >> POSIT_ES) : -(denormalized.scale >> POSIT_ES);
    assign exponent = denormalized.scale & {POSIT_ES{1'b1}};  // <=> x mod 2**y. remainder of scale / 2**es
    assign extended_regime_exp_fraction_GRS = { {POSIT_WIDTH-1{~denormalized.scale[scale_width-1]}},  // regime
                                                denormalized.scale[scale_width-1],                    // regime term
                                                exponent,                                             // exponent
                                                denormalized.fraction,                                // fraction
                                                GRS                                                   // GRS
                                              };
end

// part x
// clip into a POSIT_WIDTH-1
logic [POSIT_WIDTH-2:0] unsigned_unrounded_result;
logic [scratchpad_width-1+3:0] extended_regime_exp_fraction_shifted;
//logic [$clog2(POSIT_WIDTH)+1:0] shift_amount;
//assign shift_amount = (denormalized.scale==POSIT_WIDTH-1)? k : k+1;
// assign extended_regime_exp_fraction_shifted = extended_regime_exp_fraction_GRS >> (k + 1);
sticky_shifter #(
    .DATA_WIDTH ( scratchpad_width ),
    .MAX_STAGES ( 2**($clog2(POSIT_WIDTH)+1) )
) sticky_shifter_inst (
    .a ( extended_regime_exp_fraction_GRS     ),
    .b ( k+1                         ),
    .c ( extended_regime_exp_fraction_shifted )
);
localparam integer backward_posit_offset = scratchpad_width-1+3-POSIT_WIDTH;
localparam integer backward_posit_offset_G = backward_posit_offset-POSIT_WIDTH+1;
//assign unsigned_unrounded_result = extended_regime_exp_fraction_shifted[(POSIT_WIDTH-1+3)-:(POSIT_WIDTH-1)];


// part x
// inward projection for saturate arithmetic
if ( PD_TYPE == AMULT ) begin // temporal to not brake for add
    logic inward_proj_from_inf, inward_prof_from_zero;
    localparam integer MAX_SCALE = (2**POSIT_ES)*(POSIT_WIDTH-2);
    assign inward_proj_from_inf  = (denormalized.scale > MAX_SCALE);
    assign inward_prof_from_zero = (denormalized.scale < -MAX_SCALE);
    assign unsigned_unrounded_result = (inward_proj_from_inf) ? {POSIT_WIDTH-1{1'b1}} :
        ((inward_prof_from_zero) ? {{POSIT_WIDTH-2{1'b0}}, 1'b1} :
        extended_regime_exp_fraction_shifted[backward_posit_offset-:(POSIT_WIDTH-1)] );
end
else begin
    assign unsigned_unrounded_result = extended_regime_exp_fraction_shifted[backward_posit_offset-:(POSIT_WIDTH-1)];
end

// part x
// rounding based on the GRS triplet
logic [POSIT_WIDTH-2:0] unsigned_rounded_result;
logic guard, round, sticky;
// assign guard  = extended_regime_exp_fraction_shifted[3];
// assign round  = extended_regime_exp_fraction_shifted[2];
// assign sticky = extended_regime_exp_fraction_shifted[1] | extended_regime_exp_fraction_shifted[0];
assign guard  = extended_regime_exp_fraction_shifted[backward_posit_offset_G];
assign round  = extended_regime_exp_fraction_shifted[backward_posit_offset_G-1];
assign sticky = |extended_regime_exp_fraction_shifted[backward_posit_offset_G-2:0];

if (ROUNDING_MODE == RZERO) begin
    assign unsigned_rounded_result = unsigned_unrounded_result;
end
else begin
    logic lsb;
    logic ulp_add;
    assign lsb = unsigned_unrounded_result[0];
    if (ROUNDING_MODE == RNTE) begin
        assign ulp_add = guard & (round | sticky | lsb);
    end
    else if (ROUNDING_MODE == RPLUSINF) begin
        assign ulp_add = ~denormalized.sign & (guard | round | sticky); 
    end
    else if (ROUNDING_MODE == RMININF) begin
        assign ulp_add = denormalized.sign & (guard | round | sticky); 
    end
    else if (ROUNDING_MODE == STOCHASTIC) begin
        $fatal("no implemented yet, TRNG no, LFSR certainly");
    end
    assign unsigned_rounded_result = (ulp_add)? unsigned_unrounded_result + 1 : unsigned_unrounded_result;
end

// part x
// take the 2's complement if negative
logic [POSIT_WIDTH-2:0] signed_result;
assign signed_result = (denormalized.sign) ? -unsigned_rounded_result[POSIT_WIDTH-2:0] : unsigned_rounded_result[POSIT_WIDTH-2:0];

// part x
// build the final word
assign posit_word_o = (denormalized.zero | denormalized.NaR)   ? 
                      {denormalized.NaR,{POSIT_WIDTH-1{1'b0}}} :
                      {denormalized.sign,signed_result}        ;
endmodule
`default_nettype wire
