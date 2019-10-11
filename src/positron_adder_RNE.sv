`default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: LEDOUX Louis
// 
// Create Date: 12/11/2018 12:07:03 PM
// Design Name: 
// Module Name: positron
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
// A positron is a pipeline engine of 6 stages
//
// ------------------------------------------------------------------------------------------
//                                                 
//
//                                                                               +---+ 
//                                                                               |   |
//                                                               +---------------| D |
//                                                               |               |   |
//         +--------+    +---+      +---+                        |  +---+        +---+
//         | WEIGHT |    |   | w[i] |   |                        |  |   |          ^
//         |  ROM   |--->| D |----->|   |                        +->|   |          |
//         |        |    |   |      |   |                           |   |          |
//         +----^---+    +---+      |   |   +---+    +---+          |   |        +---+         +---+
//                                  |   |   |   |    |   |  mult[i] | + | acc[i] |   | norm[i] |   | sigm[i] 
//                                  | * |---| N |--->| D |--------->|   |------->| N |-------->| S |-------->
//                                  |   |   |   |    |   |          |   |        |   |         |   |
//          +-------+    +---+      |   |   +---+    +---+          |   |        +---+         +---+
//          | DELAY |    |   | x[i] |   |                           |   | 
//  x[i]--->|       |--->| D |----->|   |                           +-^-+  
//          |       |    |   |      |   |                 
//          +---^---+    +---+      +-^-+                 
//
//                                                        
//
//         STAGE 1      STAGE 2    STAGE 3   STAGE 4 STAGE 5       STAGE 6       STAGE 7
// ---------------------------------------------------------------------------------------------
//
// Description of stages :
//
//  Stage 1 : N clks (default 2)
//      Read weight corresponding to the i_th activation coming. ROM has delay
//      for hight throughput therefore the activation is also delayed 
//
//  Stage 2 : 0 clk (comb)
//      Extract part of a posit aka denormalisation
//
//  Stage 3 : 1 clk
//      Multiplication of denormalised posits, the result is denormalised
//      posit with twice fract bits, and +1 scale bits
//
//  Stage 4 : 0 clk (comb)
//      NO FMA so we round after mult and also allows to have same size bus
//      for adder
//
//  Stage 4 : 2 clk
//      accumulation performed with an adder
//
//  Stage 5 : 0 clk
//      Normalisation of Quire. Supposed to perform a Rounding scheme like :
//        - truncation : DONE
//        - nearest : "round to nearest, tie to nearest even" : TODO
//        - stochastic rounding : TODO
//
//  Stage 6 : 0 clk
//    perform basic fast sigmoid
// --------------------------------------------------------------------------------------------

import posit_defines::*;

module positron_adder_noFMA_RNE#
`default_nettype none

