`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC 
// Engineer: Ledoux Louis
// 
// Create Date: 11/13/2018 04:22:06 PM
// Design Name: 
// Module Name: posit_defines
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: all declaration i.e class, struct, etc..
// 
//////////////////////////////////////////////////////////////////////////////////

package posit_defines;

// prod_acc : +1 for signed +1 for overflow = +2 
// +1 for signed scale                
`define GET_SCALE_WIDTH( p_w, p_es, prod_acc ) \
    (prod_acc) ? \
        (($clog2(((2<<p_es) * (p_w-1))-1))+1) : \
        (($clog2(((2<<p_es) * (p_w-1))-1)))
    
`define GET_FRACTION_WIDTH( p_w, p_es, prod_acc ) \
    (prod_acc) ? \
        (((p_w - p_es - 3)+1)*2) : \
        (p_w - p_es - 3)

`define GET_QUIRE_SIZE( p_w, p_es, log_nb_acc ) ((2**(p_es+2))*(p_w-2)+ 1 + log_nb_acc)

`define GENVAR_TO_ASCII(value) \
    ( value > 9 && value < 100 ) ? \
        "00"+(256 * (value / 10)) + (value % 10) : \
        ( value <= 9 && value >= 0 ) ? \
            "0"+value : \
            "0"


    function [31:0] log2;
        input reg [31:0] value;
	begin
	value = value-1;
	for (log2=0; value>0; log2=log2+1)
        	value = value>>1;
      	end
    endfunction

endpackage
