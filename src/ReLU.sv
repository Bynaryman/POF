`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: LEDOUX Louis
// 
// Create Date: 01/14/2019 05:26:10 PM
// Design Name: 
// Module Name: ReLU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//
// if in <= 0; out = 0. in otherwise.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ReLU#
(
    parameter integer POSIT_WIDTH = 16
)
(
    input  logic [POSIT_WIDTH-1:0] posit_i,
    output logic [POSIT_WIDTH-1:0] posit_o
);

assign posit_o = (posit_i[POSIT_WIDTH-1]) ? 0 : posit_i;

endmodule
