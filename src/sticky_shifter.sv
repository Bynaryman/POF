`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: LEDOUX Louis
// 
// Create Date: 26/09/2019 
// Design Name: 
// Module Name: sticky_shifter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Right shift computing the sticky bits
// 
// performs c = a >> b
// c is 3 bit bigger since it will contains the remainder on the form of GRS
// bits
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sticky_shifter #
(
    parameter integer DATA_WIDTH = 16,
    parameter integer MAX_STAGES = 4
)
(
    input  wire  [DATA_WIDTH-1:0]       a,
    input  wire  [$clog2(MAX_STAGES):0] b,
    output logic [DATA_WIDTH-1+3:0]     c
);
   
    localparam integer S = MAX_STAGES;
    localparam integer N = DATA_WIDTH;

    logic [N-1+3:0] shift_stages [S-1:0];

    assign shift_stages[0] = {a,{3{1'b0}}};
    
    genvar j;
    generate
        for ( j = 1 ; j < S ; j++ ) begin: shift_stage   
            assign shift_stages[j][DATA_WIDTH-1+3:1] = shift_stages[j-1][DATA_WIDTH-1+3:1] >> 1;
            assign shift_stages[j][0] = (shift_stages[j-1][1:0])? 1'b1 : 1'b0;
        end
    endgenerate

    assign c = shift_stages[b-1];

endmodule
`default_nettype wire