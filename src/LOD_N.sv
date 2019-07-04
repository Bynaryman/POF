//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: Ledoux Louis
// 
// Create Date: 11/14/2018 01:59:24 PM
// Design Name: 
// Module Name: LOD_N
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

module LOD_N # (
    parameter integer C_N = 64
)
(
    input  logic [C_N-1:0] in,
    output logic [$clog2(C_N)-1:0] out
);

logic vld;
localparam isPowerOfTwo = ~|(C_N&(C_N-1));
localparam nbZeroToPad = (1<<($clog2(C_N))) - C_N;

if (isPowerOfTwo) begin
    LOD #
    (
        .C_N(C_N),
        .C_S(log2(C_N))
    )
    lod_inst (
        .in  ( in  ),
        .out ( out ),
        .vld ( vld ) 
    );
end
else begin
    
    LOD #
    (
        .C_N(1<<($clog2(C_N))),
        .C_S($clog2(C_N))
    )
    lod_inst (
        .in  ( {in, {{nbZeroToPad}{1'b0}}}  ),
        .out ( out ),
        .vld ( vld ) 
    );
end

endmodule
