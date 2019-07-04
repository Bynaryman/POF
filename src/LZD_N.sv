`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/12/2019 05:24:35 PM
// Design Name: 
// Module Name: LZD_N
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

module LZD_N #(
    parameter integer C_N = 64
)
(
    input logic [C_N-1:0] in,
    output logic [$clog2(C_N)-1:0] out
);

logic vld;
localparam isPowerOfTwo = ~|(C_N&(C_N-1));
localparam nbZeroToPad = (1<<($clog2(C_N))) - C_N;

if (isPowerOfTwo) begin

    LZD #
    (
        .C_N(C_N),
        .C_S(log2(C_N))
    )
    lzd_inst (
        .in  ( in  ),
        .out ( out ),
        .vld ( vld ) 
    );
    
end
else begin
    
    LZD #
    (
        .C_N(1<<($clog2(C_N))),
        .C_S($clog2(C_N))
    )
    lzd_inst (
        .in  ( {in, {{nbZeroToPad}{1'b0}}}  ),
        .out ( out ),
        .vld ( vld ) 
    );
end
endmodule
