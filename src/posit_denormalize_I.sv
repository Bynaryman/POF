`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: LEDOUX Louis
// 
// Create Date: 27/06/2019 11:14:03 AM
// Interface Name : Denormalized_I 
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

interface Denormalized_I #(
    parameter POSIT_WIDTH = 8,
    parameter POSIT_ES = 0
);

typedef struct packed {
    logic sign;
    logic inf;
    logic zero;
    logic [(`GET_SCALE_WIDTH(POSIT_WIDTH, POSIT_ES, 0))-1:0] scale;
    logic [(`GET_FRACTION_WIDTH(POSIT_WIDTH, POSIT_ES, 0))-1:0] fraction;

} Denormalized;

Denormalized data;

endinterface

`default_nettype wire