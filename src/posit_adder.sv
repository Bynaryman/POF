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

module posit_adder
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

// part 1
// comparison of inputs and muxes to determine the small(s) and large(l) operand 
logic op1_gt_op2;
logic signed [$bits(operand1.scale)-1:0] sop_scale, lop_scale;
logic [$bits(operand1.fraction)-1:0] sop_fraction, lop_fraction;
assign op1_gt_op2 = operand1.scale > operand2.scale;
always_comb begin
    if (op1_gt_op2) begin
        sop_scale = operand2.scale;
        lop_scale = operand1.scale;
        sop_fraction = operand2.fraction;
        lop_fraction = operand1.fraction;
    end else begin
        sop_scale = operand1.scale;
        lop_scale = operand2.scale;
        sop_fraction = operand1.fraction;
        lop_fraction = operand2.fraction;
    end
end

// part 2
// compute the shift amount to align significands based on scale diff
// 1 bit more than scale in for overflow cases
logic signed [operand1.scale_width:0] shift_amount;
assign shift_amount = lop_scale - sop_scale;

// part 3
// shift to right the sop by shift_amounts
// aligned fraction is +3 (GRS) + 1(hidden bit) bits
logic [result.fraction_width:0] sop_fraction_aligned;
sticky_shifter #(
    .DATA_WIDTH ( operand1.fraction_width + 1 ),
    .MAX_STAGES ( (2**operand1.scale_width)-1 )
) sticky_shifter (
    .a ( {1'b1,sop_fraction}  ),
    .b ( shift_amount         ),
    .c ( sop_fraction_aligned )
);

// part 4
// perform the operation depending on signs
logic op;
logic [result.fraction_width+1:0] tmp_op_res;  // +2 bits for addition width hidden bits and in case of overflow
assign op = operand1.sign ~^ operand2.sign;    // 1 for + ; 0 for -
assign tmp_op_res = (op)? {1'b1, lop_fraction, {3'b0}} + sop_fraction_aligned : {1'b1, lop_fraction, {3'b0}} - sop_fraction_aligned;

// part 5
// detect overflow and
// - renormalize mantissa if necessary
// - adjust scale if necessary
logic overflow;
logic [result.fraction_width+1:0] normalized_op_res;
logic [result.scale_width-1:0] final_scale;
assign overflow = tmp_op_res[result.fraction_width+1];
assign normalized_op_res = (overflow)? tmp_op_res >> 1 : tmp_op_res;
assign final_scale = (overflow)? lop_scale + 1 : lop_scale;

// TODO (lledoux) : check sortie, check taille fraction (+3 ou + rien ?) et output le sign
// TODO : que faire de GRS entrant
assign result.guard = (overflow)? normalized_op_res[1] : normalized_op_res[2];
assign result.round = (overflow)? normalized_op_res[0] : normalized_op_res[1];
assign result.sticky =  normalized_op_res[0] | normalized_op_res[1];
assign result.NaR = final_scale[result.scale_width-1];
assign result.scale = final_scale;
assign result.fraction = operand1.fraction + operand2.fraction + |sop_fraction_aligned + |overflow;
endmodule

module posit_adder_synth_tester ();

pd #( 
    .POSIT_WIDTH ( 8 ),
    .POSIT_ES    ( 1 ),
    .PD_TYPE     ( 0 )
) de2add_op1();

pd #( 
    .POSIT_WIDTH ( 8 ),
    .POSIT_ES    ( 1 ),
    .PD_TYPE     ( 0 )
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
