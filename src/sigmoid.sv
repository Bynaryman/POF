`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: LEDOUX Louis
// 
// Create Date: 12/12/2018 11:09:43 AM
// Design Name: 
// Module Name: sigmoid
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: perform the shift left fast sigmoid
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: 
// /!\ works fine with exp size 0
// 
//////////////////////////////////////////////////////////////////////////////////


module sigmoid #
(
    parameter integer POSIT_WIDTH = 16
)
(
    input  logic [POSIT_WIDTH-1:0] posit_i,
    output logic [POSIT_WIDTH-1:0] posit_o
);

    assign posit_o = {~posit_i[POSIT_WIDTH-1], posit_i[POSIT_WIDTH-2:0]} >> 2;

endmodule
