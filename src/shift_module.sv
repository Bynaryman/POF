`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: Ledoux Louis
// 
// Create Date: 12/10/2018 09:28:24 AM
// Design Name: 
// Module Name: shift_module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: dummy module to compute ressource of a shift
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module shift_module # (
    parameter integer DATA_WIDTH_A = 4;
    parameter integer DATA_WIDTH_B = 4;
    parameter integer DATA_WIDTH_C = 4;    
)(
    input wire [DATA_WIDTH_A-1:0] a,
    input wire [DATA_WIDTH_B-1:0] b,
    output wire [DATA_WIDTH_C-1:0] c
);

assign c = a << b;

endmodule
`default_nettype wire

