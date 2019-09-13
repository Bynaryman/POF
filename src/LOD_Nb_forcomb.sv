`default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: LEDOUX Louis
// 
// Create Date: 09/11/2019 11:42:34 AM
// Design Name: 
// Module Name: LOD_Nb_LUT
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


module LOD_Nb_forcomb #(
     parameter integer DATA_WIDTH = 64
)
(
    input  wire [DATA_WIDTH-1:0] in,
    output logic [$clog2(DATA_WIDTH)-1:0] out
);

integer j;
always_comb for (j=0;j<DATA_WIDTH;j++) if (in[j]) out=j;

endmodule
`default_nettype wire
