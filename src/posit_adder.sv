`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: LEDOUX Louis
// 
// Create Date: 20/09/2019 11:43:52 AM
// Design Name: 
// Module Name: posit_adder
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

module posit_adder # (
    parameter integer POSIT_WIDTH = 8,
    parameter integer POSIT_ES    = 0
)
(

    // SLAVE SIDE
    
    // input posit 1
    pd.slave operand1,
   
    // input posit 2
    pd.slave operand2,
    
    // MASTER SIDE
    
    // output posit
    pd.master result

);

// Generate block waiting for asserts
if ( operand1.POSIT_WIDTH != operand2.POSIT_WIDTH ||
     operand1.POSIT_ES    != operand2.POSIT_ES    ||
     operand1.PD_TYPE     != operand2.PD_TYPE )   $error("instanciation of adder with different operands configuration");

localparam integer scale_width_b    = get_scale_width(POSIT_WIDTH, POSIT_ES, NORMAL);
localparam integer fraction_width_b = get_fraction_width(POSIT_WIDTH, POSIT_ES, NORMAL);
localparam integer scale_width_a    = get_scale_width(POSIT_WIDTH, POSIT_ES, AADD);
localparam integer fraction_width_a = get_fraction_width(POSIT_WIDTH, POSIT_ES, AADD);

// part 1
// comparison of inputs and muxes to determine the small(s) and large(l) operand 
logic op1_gt_op2;
logic signed [scale_width_b-1:0] sop_scale, lop_scale;
logic [fraction_width_b-1:0] sop_fraction, lop_fraction;
logic lzero, szero;
logic lsign, ssign;
always_comb begin
    if (operand1.scale > operand2.scale) begin
        op1_gt_op2 = 1'b1;
    end 
    else if (operand1.scale < operand2.scale) begin
        op1_gt_op2 = 1'b0;
    end
    else begin  // scales are equal, compare mantissas
        op1_gt_op2 = operand1.fraction >= operand2.fraction;
    end
end
always_comb begin
    if (op1_gt_op2) begin
        sop_scale = operand2.scale;
        lop_scale = operand1.scale;
        sop_fraction = operand2.fraction;
        lop_fraction = operand1.fraction;
        lzero = operand1.zero;
        szero = operand2.zero;
        lsign = operand1.sign;
        ssign = operand2.sign;
    end else begin
        sop_scale = operand1.scale;
        lop_scale = operand2.scale;
        sop_fraction = operand1.fraction;
        lop_fraction = operand2.fraction;
        lzero = operand2.zero;
        szero = operand1.zero;
        lsign = operand2.sign;
        ssign = operand1.sign;
    end
end

// part 2
// compute the shift amount to align significands based on scale diff
// 1 bit more than scale in for overflow cases
logic signed [scale_width_b:0] shift_amount;
assign shift_amount = lop_scale - sop_scale;

// part 3
// shift to right the sop by shift_amounts
// aligned fraction is +3 (GRS) + 1(hidden bit) bits
logic [fraction_width_b-1+3+1:0] sop_fraction_aligned_grs;
sticky_shifter #(
    .DATA_WIDTH ( fraction_width_b+1   ),
    .MAX_STAGES ( 2**(scale_width_b)-1 )
) sticky_shifter_inst (
    .a ( {~szero, sop_fraction}   ),
    .b ( shift_amount             ),
    .c ( sop_fraction_aligned_grs )
);
//assign sop_fraction_aligned_grs = {~szero, sop_fraction, 1'b0,1'b0,1'b0} >> shift_amount;

// part 4
// perform the operation depending on signs
logic op;
logic [fraction_width_b-1+3+1:0] sop, lop;
logic [fraction_width_b-1+3+1+1:0] tmp_op_res; // +5 bits : grs hidden overflow
assign op = operand1.sign ~^ operand2.sign;    // 1 for + ; 0 for -
assign lop = {~lzero, lop_fraction, {3'b0}};
assign sop = sop_fraction_aligned_grs;
assign tmp_op_res = (op)?  lop + sop : lop - sop;

// part 5
// detect overflow of mantissa eventually adjust scale and mantissa
logic mantissa_overflow;
assign mantissa_overflow = tmp_op_res[fraction_width_b-1+3+1+1];


// part 6
//  renormalize mantissa if necessary
logic [fraction_width_b-1+3+1+1:0] normalized_op_res;
logic [$clog2($bits(normalized_op_res))-1:0] hidden_pos;
LOD_N #(
    .C_N($bits(normalized_op_res))
) hidden_bit_counter(
    .in(tmp_op_res),
    .out(hidden_pos)
);

logic signed [scale_width_a-1:0] final_scale;
assign final_scale = (mantissa_overflow)? $signed(lop_scale + 1) : (~tmp_op_res[fraction_width_b-1+3+1]?  $signed(lop_scale - $signed(hidden_pos) + 1) : $signed(lop_scale));

//assign normalized_matissa_OVF = (mantissa_overflow)? tmp_op_res  : tmp_op_res << 1;
assign normalized_op_res = tmp_op_res << (hidden_pos +1);


// TODO : que faire de GRS entrant
assign result.guard  = normalized_op_res[$bits(normalized_op_res)-fraction_width_b-1];
assign result.round  = normalized_op_res[$bits(normalized_op_res)-fraction_width_b-2];
assign result.sticky = normalized_op_res[$bits(normalized_op_res)-fraction_width_b-3];
assign result.NaR = operand1.NaR | operand2.NaR;
assign result.sign = lsign;
assign result.scale = final_scale;
assign result.fraction = normalized_op_res[($bits(normalized_op_res)-1)-:fraction_width_b];
assign result.zero = (operand1.zero & operand2.zero) | (hidden_pos >= $bits(sop_fraction_aligned_grs));
endmodule

module posit_adder_synth_tester ();

pd #( 
    .POSIT_WIDTH ( 8 ),
    .POSIT_ES    ( 1 ),
    .PD_TYPE     ( NORMAL )
) de2add_op1();

pd #( 
    .POSIT_WIDTH ( 8 ),
    .POSIT_ES    ( 1 ),
    .PD_TYPE     ( NORMAL )
) de2add_op2();

pd #( 
    .POSIT_WIDTH ( 8 ),
    .POSIT_ES    ( 1 ),
    .PD_TYPE     ( AADD )
) add2acc();

posit_adder posit_adder_inst (
    .operand1 ( de2add_op1 ),
    .operand2 ( de2add_op2 ),
    .result   ( add2acc    )
);

endmodule

`default_nettype wire
