`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/29/2018 11:26:52 AM
// Design Name: 
// Module Name: posit_mult_16_1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: perform multiplication of 2 posit<16,1> denormalized
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module posit_mult_16_1(

    // System signals
    input  clk,
    input  rst_n,
    
    // SLAVE SIDE
    
    // control signals
    output rtr_o,
    input  rts_i,
    input  sow_i,
    input  eow_i,
    
    // input posit 1
    input logic [11:0] fraction_i1,
    input logic signed [5:0] scale_i1,
    input logic NaR_i1,
    input logic zero_i1,
    input logic sign_i1,
   
    // input posit 2
    input logic [11:0] fraction_i2,
    input logic signed [5:0] scale_i2,
    input logic NaR_i2,
    input logic zero_i2,
    input logic sign_i2,
    
    // MASTER SIDE
    
    // control signals
    input  rtr_i,
    output rts_o,
    output eow_o,
    output sow_o,
    
    // output posit
    output logic [25:0] fraction_o,  // 2*(12+1)-1
    output logic signed [6:0] scale_o,
    output logic NaR_o,
    output logic sign_o,
    output logic zero_o

);

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
logic [11:0] latched_fraction_i1;
logic signed [5:0]  latched_scale_i1;

// posit 2
logic latched_zero_i2;
logic latched_NaR_i2;
logic latched_sign_i2;
logic [11:0] latched_fraction_i2;
logic signed [5:0]  latched_scale_i2;

logic zero_in1;
logic NaR_in1;
logic sign_in1;
logic [11:0] fraction_in1;
logic signed [5:0]  scale_in1;

logic zero_in2;
logic NaR_in2;
logic sign_in2;
logic [11:0] fraction_in2;
logic signed [5:0]  scale_in2;

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

logic [12:0] f1, f2;
logic [25:0] fmult, fout;
logic signed [6:0] scaleout, scale_add;
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
assign fout     = fmult[25] ? (fmult<<1) : (fmult<<2);
// add one in case of overflow in frac multiplication
assign scaleout = fmult[25] ? (scale_add+1) : (scale_add);

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
