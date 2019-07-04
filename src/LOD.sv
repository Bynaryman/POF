//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: Ledoux Louis
// 
// Create Date: 11/14/2018 01:59:24 PM
// Design Name: 
// Module Name: LOD
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
//       
//////////////////////////////////////////////////////////////////////////////////

import posit_defines::*;

module LOD #(
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
            assign vld = |in;
            assign out = ~in[1] & in[0];
        end
        else if (C_N & (C_N-1)) begin
            LOD #(1<<C_S) 
            lod_inst (
                .in  ( {1<<C_S {1'b0}} | in ),
                .out ( out                  ),
                .vld ( vld                  )
            );
        end
        else begin
            wire [C_S-2:0] out_l, out_h;
            wire out_vl, out_vh;
            LOD #(C_N>>1)
            lod_l(
                .in  ( in[(C_N>>1)-1:0]     ),
                .out ( out_l                ),
                .vld ( out_vl               )
            );
            LOD #(C_N>>1)
            lod_h(
                .in  ( in[C_N-1:C_N>>1]     ), 
                .out ( out_h                ),
                .vld ( out_vh               )
            );
            assign vld = out_vl | out_vh;
            assign out = out_vh ? {1'b0,out_h} : {out_vl,out_l};
        end
  endgenerate
endmodule
