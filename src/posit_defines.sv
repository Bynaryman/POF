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

//`include "posit_macros.svh"

package posit_defines;

typedef enum {
    NORMAL, 
    AADD,
    AMULT, 
    AQUIRE
} pd_type;

typedef enum {
    RZERO,      // Round toward 0 <=> truncate
    RNTE,       // Round to nearest, tie to even
    RPLUSINF,   // Round toward +inf
    RMININF,    // Round toward -inf
    STOCHASTIC  // probabilistic rounding based on randomness
} rounding_type;

    function integer get_scale_width(input integer posit_width, input integer posit_es, input pd_type pdt);
        case(pdt)
            AADD: begin
                return (($clog2(((2<<posit_es) * (posit_width-1))-1))+1);  // in case of overflow of mantissa : +1 ?
            end
            AMULT: begin
                return (($clog2(((2<<posit_es) * (posit_width-1))-1))+1);  // addition of scales : +1 bit
            end
    
            NORMAL: begin
                return (($clog2(((2<<posit_es) * (posit_width-1))-1)));
            end
            default: begin
                return 0;
            end  
        endcase
    endfunction
    
    function integer get_fraction_width(input integer posit_width, input integer posit_es, input pd_type pdt);
        case(pdt)
               AADD: begin
                   return (posit_width - posit_es - 3); // for the GRS, the last bit will contin information about all lost LSBs ("it sticks")
               end
               AMULT: begin
                   return(((posit_width - posit_es - 3)+1)*2);
               end
      
               NORMAL: begin
                   return (posit_width - posit_es - 3);
               end
               default: begin
                   return 0;
               end  
           endcase
    endfunction

function [31:0] log2;
    input reg [31:0] value;
begin
value = value-1;
for (log2=0; value>0; log2=log2+1)
        value = value>>1;
    end
endfunction

endpackage
