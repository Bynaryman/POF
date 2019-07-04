`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/12/2019 05:34:38 PM
// Design Name: 
// Module Name: LZD
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

module LZD #(
    parameter integer C_N = 64,
    parameter integer C_S = log2(C_N)
)
(
    input  logic [C_N-1:0] in,
    output logic [C_S-1:0] out,
    output logic vld
);

    generate
        if (C_N == 2) begin
            assign vld = ~&in;
            assign out = in[1] & ~in[0];
        end
        else if (C_N & (C_N-1))
            LZD #(1<<C_S)
            lzd_inst (
                .in  ( {1<<C_S {1'b0}} | in ),
                .out ( out                  ),
                .vld ( vld                  )
            );
        else begin
            logic [C_S-2:0] out_l;
            logic [C_S-2:0] out_h;
            logic out_vl, out_vh;
            LZD #(C_N>>1)
            lzd_l(
                .in  ( in[(C_N>>1)-1:0] ),
                .out ( out_l            ),
                .vld ( out_vl           )
            );
            LZD #(C_N>>1)
            lzd_h(
                .in  ( in[C_N-1:C_N>>1] ),
                .out ( out_h            ),
                .vld ( out_vh           )
            );
            assign vld = out_vl | out_vh;
            assign out = out_vh ? {1'b0,out_h} : {out_vl,out_l};
        end
    endgenerate
endmodule
