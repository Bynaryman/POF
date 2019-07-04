`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: LEDOUX Louis
// 
// Create Date: 02/19/2019 11:14:03 AM
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
//////////////////////////////////////////////////////////////////////////////////


module posit_denormalize #(
    parameter integer POSIT_WIDTH = 16,
    parameter integer POSIT_ES    = 0
)
(
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
endmodule
