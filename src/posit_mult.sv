`default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: LEDOUX Louis
// 
// Create Date: 12/10/2018 11:43:52 AM
// Design Name: 
// Module Name: posit_mult
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: generic HW for denormalized posits multiplication
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

import posit_defines::*;

module posit_mult #
(
    parameter integer POSIT_WIDTH = 16,
    parameter integer POSIT_ES = 1
)
(

    // System signals
    input  wire clk,
    input  wire rst_n,
    
    // SLAVE SIDE
    
    // control signals
    output logic rtr_o,
    input  wire rts_i,
    input  wire sow_i,
    input  wire eow_i,
    
    // input posit 1
    input wire [(get_fraction_width(POSIT_WIDTH,POSIT_ES,NORMAL))-1:0] fraction_i1,
    input wire signed [(get_scale_width(POSIT_WIDTH,POSIT_ES,NORMAL))-1:0] scale_i1,
    input wire NaR_i1,
    input wire zero_i1,
    input wire sign_i1,
   
    // input posit 2
    input wire [(get_fraction_width(POSIT_WIDTH,POSIT_ES,NORMAL))-1:0] fraction_i2,
    input wire signed [(get_scale_width(POSIT_WIDTH,POSIT_ES,NORMAL))-1:0] scale_i2,
    input wire NaR_i2,
    input wire zero_i2,
    input wire sign_i2,
    
    // MASTER SIDE
    
    // control signals
    input  wire rtr_i,
    output logic rts_o,
    output logic eow_o,
    output logic sow_o,
    
    // output posit
    output logic [(get_fraction_width(POSIT_WIDTH,POSIT_ES,AMULT))-1:0] fraction_o,  // 2*(12+1)-1
    output logic signed [(get_scale_width(POSIT_WIDTH,POSIT_ES,AMULT))-1:0] scale_o,
    output logic NaR_o,
    output logic sign_o,
    output logic zero_o

);

// localparam for register sizes
localparam integer FRACTION_SIZE_IN  = (get_fraction_width(POSIT_WIDTH,POSIT_ES,NORMAL));
localparam integer FRACTION_SIZE_OUT = (get_fraction_width(POSIT_WIDTH,POSIT_ES,AMULT));
localparam integer SCALE_SIZE_IN     = (get_scale_width(POSIT_WIDTH,POSIT_ES,NORMAL));
localparam integer SCALE_SIZE_OUT    = (get_scale_width(POSIT_WIDTH,POSIT_ES,AMULT));

// signal state control
logic process_en;
logic receive_en;
logic rtr_o_int;
logic rts_o_int;

// signal latched inputs
// control
logic latched;
logic latched_sow_i;
logic latched_eow_i;

// posit 1
logic latched_zero_i1;
logic latched_NaR_i1;
logic latched_sign_i1;
logic [FRACTION_SIZE_IN-1:0] latched_fraction_i1;
logic signed [SCALE_SIZE_IN-1:0]  latched_scale_i1;

// posit 2
logic latched_zero_i2;
logic latched_NaR_i2;
logic latched_sign_i2;
logic [FRACTION_SIZE_IN-1:0] latched_fraction_i2;
logic signed [SCALE_SIZE_IN-1:0]  latched_scale_i2;

logic zero_in1;
logic NaR_in1;
logic sign_in1;
logic [FRACTION_SIZE_IN-1:0] fraction_in1;
logic signed [SCALE_SIZE_IN-1:0]  scale_in1;

logic zero_in2;
logic NaR_in2;
logic sign_in2;
logic [FRACTION_SIZE_IN-1:0] fraction_in2;
logic signed [SCALE_SIZE_IN-1:0]  scale_in2;

// pipeline control signals
localparam integer PIPELEN = 1;
logic [PIPELEN-1:0] stage_en;
logic [PIPELEN-1:0] stage_clr;
logic [PIPELEN-1:0] staged;
logic [PIPELEN:0] sow;
logic [PIPELEN:0] eow;

// Shift condition: downstream module ready for receive, 
// or current module not ready to send
assign process_en = rtr_i | ~rts_o_int;

// Receive condition: current module ready for receive, 
// and upstream module ready to send
assign receive_en = rts_i & rtr_o_int;

//    _____ __               
//   / ___// /___ __   _____ 
//   \__ \/ / __ `/ | / / _ \
//  ___/ / / /_/ /| |/ /  __/
// /____/_/\__,_/ |___/\___/ 

always_ff @( posedge clk or negedge rst_n ) begin
    if ( ~rst_n ) begin
        latched <= 0;
        latched_sow_i <= 0;
        latched_eow_i <= 0;
        
        latched_zero_i1 <= 0;
        latched_sign_i1 <= 0;
        latched_NaR_i1 <= 0;
        latched_fraction_i1 <= 0;
        latched_scale_i1 <= 0;
        
        latched_zero_i2 <= 0;
        latched_sign_i2 <= 0;
        latched_NaR_i2 <= 0;
        latched_fraction_i2 <= 0;
        latched_scale_i2 <= 0;
    end
    else begin
       if ( receive_en & ~process_en ) begin
           latched <= 1;
           latched_sow_i <= sow_i;
           latched_eow_i <= eow_i;
           
           latched_NaR_i1 <= NaR_i1;
           latched_zero_i1 <= zero_i1;
           latched_sign_i1 <= sign_i1;
           latched_fraction_i1 <= fraction_i1;
           latched_scale_i1 <= scale_i1;
           
           latched_NaR_i2 <= NaR_i2;
           latched_zero_i2 <= zero_i2;
           latched_sign_i2 <= sign_i2;
           latched_fraction_i2 <= fraction_i2;
           latched_scale_i2 <= scale_i2;
       end
       else if ( process_en ) begin
           latched <= 0;
       end
       rtr_o_int <= process_en;
    end
end
assign rtr_o = rtr_o_int;


//     ____  _            ___          
//    / __ \(_)___  ___  / (_)___  ___ 
//   / /_/ / / __ \/ _ \/ / / __ \/ _ \
//  / ____/ / /_/ /  __/ / / / / /  __/
// /_/   /_/ .___/\___/_/_/_/ /_/\___/ 
//        /_/                          

// mux to select latched data if present
assign sow[0]      = (latched)? latched_sow_i        : sow_i;
assign eow[0]      = (latched)? latched_eow_i        : eow_i;

assign fraction_in1 = (latched)? latched_fraction_i1 : fraction_i1;
assign scale_in1    = (latched)? latched_scale_i1    : scale_i1;
assign sign_in1     = (latched)? latched_sign_i1     : sign_i1;
assign NaR_in1      = (latched)? latched_NaR_i1      : NaR_i1;
assign zero_in1     = (latched)? latched_zero_i1     : zero_i1;

assign fraction_in2 = (latched)? latched_fraction_i2 : fraction_i2;
assign scale_in2    = (latched)? latched_scale_i2    : scale_i2;
assign sign_in2     = (latched)? latched_sign_i2     : sign_i2;
assign NaR_in2      = (latched)? latched_NaR_i2      : NaR_i2;
assign zero_in2     = (latched)? latched_zero_i2     : zero_i2;


//    ___
//   <  /
//   / / 
//  / /  
// /_/   
      
// accept 1 datum if pipeline works and upstream module is able to provide or latched is present
assign stage_en[0] = process_en & ( receive_en | latched );
// clear first stage when pipeline works and upstream module is unable to provide data and no latched data present
assign stage_clr[0] = process_en & ( ~receive_en & ~latched );

logic [FRACTION_SIZE_IN:0] f1, f2; // not -1 because of hidden bit
logic [FRACTION_SIZE_OUT-1:0] fmult, fout;
logic signed [SCALE_SIZE_OUT-1:0] scaleout, scale_add;
logic signout, NaRout, zeroout;
// add hidden bit before mult
assign f1 = {1'b1, fraction_in1};
assign f2 = {1'b1, fraction_in2};

always_ff @( posedge clk or negedge rst_n ) begin
    if ( ~rst_n ) begin
         staged[0]   <= 0;
         sow[1]      <= 0;
         eow[1]      <= 0;
         fmult       <= 0;
         scale_add   <= 0;
         signout     <= 0;
         NaRout      <= 0;
         zeroout     <= 0;
    end
    else begin
        if ( stage_en[0] ) begin
            staged[0] <= 1;
            sow[1]    <= sow[0];
            eow[1]    <= eow[0];
            fmult     <= f1 * f2;
            scale_add <= scale_in1 + scale_in2;
            signout   <= sign_in1 ^ sign_in2;
            NaRout    <= NaR_in1 | NaR_in2;
            zeroout   <= zero_in1 | zero_in2;
        end
        else if ( stage_clr[0] ) begin
            staged[0] <= 0;
        end
    end
end

// shift out hidden bit
assign fout     = fmult[FRACTION_SIZE_OUT-1] ? (fmult<<1) : (fmult<<2);
// add one in case of overflow in frac multiplication
assign scaleout = fmult[FRACTION_SIZE_OUT-1] ? (scale_add+1) : (scale_add);

//                          __           
//    ____ ___  ____ ______/ /____  _____
//   / __ `__ \/ __ `/ ___/ __/ _ \/ ___/
//  / / / / / / /_/ (__  ) /_/  __/ /    
// /_/ /_/ /_/\__,_/____/\__/\___/_/     

assign rts_o_int = staged[PIPELEN-1];
assign rts_o     = rts_o_int;
assign eow_o     = eow[PIPELEN];
assign sow_o     = sow[PIPELEN];

assign fraction_o = fout;
assign scale_o    = scaleout;
assign sign_o     = signout;
assign zero_o     = zeroout;
assign NaR_o      = NaRout;


endmodule
`default_nettype wire