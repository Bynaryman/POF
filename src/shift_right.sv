`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: LEDOUX Louis
// 
// Create Date: 12/18/2018 04:17:37 PM
// Design Name: 
// Module Name: shift_right
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Design from manish kumar
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module shift_right #
(
    parameter integer N = 16,
    parameter integer S = 4
)
(
    input  logic [N-1:0] a,
    input  logic [S-1:0] b,
    output logic [N-1:0] c
);
   
    logic [N-1:0] tmp [S-1:0];
    assign tmp[0] = b[0] ? (a >> 7'd1) : a;

    genvar i;
    generate
        for (i = 1; i < S; i = i + 1)
        begin: loop_blk
            assign tmp[i] = b[i] ? (tmp[i-1] >> 2**i) : tmp[i-1];
        end
    endgenerate

    assign c = tmp[S-1];

endmodule
