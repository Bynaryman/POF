`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: LEDOUX Louis
// 
// Create Date: 22/09/2019 11:43:52 AM
// Design Name: 
// Module Name: posit_adder_full
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//
//   this posit adder takes normalized posit as input
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

import posit_defines::*;

module posit_adder_full # (
    parameter integer POSIT_WIDTH = 16,
    parameter integer POSIT_ES    = 0
)
(
    // System signals
    input  clk,
    input  rst_n,
    
    // SLAVE SIDE
    
    // control signals
    output rtr_o,
    input  rts_i,
    input  sow_i,
    input  eow_i,

    // input posit 1
    wire [POSIT_WIDTH-1:0] operand1,
   
    // input posit 2
    wire [POSIT_WIDTH-1:0] operand2,
    
    // MASTER SIDE
    
    // output posit
    input  rtr_i,
    output rts_o,
    output eow_o,
    output sow_o,
    
    // output posit
    logic [POSIT_WIDTH-1:0] result
);

localparam integer SCALE_WIDTH_BEFORE_ADD    = (`GET_SCALE_WIDTH(POSIT_WIDTH, POSIT_ES, 0));
localparam integer FRACTION_WIDTH_BEFORE_ADD = (`GET_FRACTION_WIDTH(POSIT_WIDTH, POSIT_ES, 0));
localparam integer SCALE_WIDTH_AFTER_ADD     = ;
localparam integer FRACTION_WIDTH_AFTER_ADD  = ;

// extraction
logic sign_operand1, sign_operand2;
logic NaR_operand1, NaR_operand2;
logic zero_operand1, zero_operand2;
logic [SCALE_WIDTH_BEFORE_MULT-1:0] scale_operand1, scale_operand2;
logic [FRACTION_WIDTH_BEFORE_MULT-1:0] fraction_operand1, fraction_operand2;

// extract operand1
posit_data_extract #(
    .POSIT_WIDTH ( POSIT_WIDTH ),
    .POSIT_ES    ( POSIT_ES    )
)
extract_operand1 (

    // in
    .posit_word_i ( operand1          ),

    // out
    .sign         ( sign_operand1     ),
    .inf          ( NaR_operand1      ),
    .zero         ( zero_operand1     ),
    .scale        ( scale_operand1    ),
    .fraction     ( fraction_operand1 )
);

// extract operand2
posit_data_extract #(
    .POSIT_WIDTH ( POSIT_WIDTH ),
    .POSIT_ES    ( POSIT_ES    )
)
extract_operand2(

    // in
    .posit_word_i ( operand2          ),

    // out
    .sign         ( sign_operand2     ),
    .inf          ( NaR_operand2      ),
    .zero         ( zero_operand2     ),
    .scale        ( scale_operand2    ),
    .fraction     ( fraction_operand2 )
);


// op to perform
// addition when op = 0, subtraction otherwise
logic op;
assign op = operand1.sign ^ operand2.sign;

// abs(OP1) >= abs(OP2)
logic in1_gt_in2;
logic [POSIT_WIDTH-2:0] abs_op1, abs_op2;
assign abs_op1 = operand1[POSIT_WIDTH-1] ? -operand1[POSIT_WIDTH-2:0] : operand1[POSIT_WIDTH-2:0];
assign abs_op2 = operand2[POSIT_WIDTH-1] ? -operand2[POSIT_WIDTH-2:0] : operand2[POSIT_WIDTH-2:0];
assign in1_gt_in2 = abs_op1 >= abs_op2;

// compute difference between scales

// right shift smaller scale by difference

// get the outshifted bits to compute sticky bit

//

endmodule
`default_nettype wire
