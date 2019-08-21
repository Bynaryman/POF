`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: LEDOUX Louis
// 
// Create Date: 12/10/2018 11:43:52 AM
// Design Name: 
// Module Name: posit_mult
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: generic HW for denormalized posits multiplication
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

import posit_defines::*;

module posit_mult_4_0
(

    // SLAVE SIDE
    
    // input posit 1
    input wire fraction_i1,
    input wire signed [2:0] scale_i1,
    input wire NaR_i1,
    input wire zero_i1,
    input wire sign_i1,
   
    // input posit 2
    input wire fraction_i2,
    input wire signed [2:0] scale_i2,
    input wire NaR_i2,
    input wire zero_i2,
    input wire sign_i2,
    
    // MASTER SIDE
    
    // output posit
    output logic [3:0] fraction_o,
    output logic signed [3:0] scale_o,
    output logic NaR_o,
    output logic sign_o,
    output logic zero_o

);

assign fraction_o[0] = 0;
assign fraction_o[1] = fraction_i1 & fraction_i2;
assign fraction_o[2] = 0;
assign fraction_o[3] = fraction_i1 ^ fraction_i2;
assign scale_o = (fraction_o[3])? (scale_i1 + scale_i2 +1) : (scale_i1 + scale_i2);
assign sign_o = sign_i1 ^ sign_i2;
assign zero_o = zero_i1 | zero_i2;
assign NaR_o = NaR_i1 | NaR_i2;

endmodule
`default_nettype wire
