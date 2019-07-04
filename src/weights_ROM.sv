`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: LEDOUX Louis
// 
// Create Date: 12/11/2018 03:50:39 PM
// Design Name: 
// Module Name: weights_ROM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: axi stream compliant interface with pipelined and delayed output
//              output the weight from a ROM delayed by N clk
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

import posit_defines::*;

module weights_ROM #
(
    parameter integer DELAY = 2,
    parameter PATH = "/home/lledoux/Desktop/PhD/ML/C/mnist-3lnn/hidden_weights/hidden_weights_1",
    parameter integer POSIT_WIDTH = 16,
    parameter integer NB_WEIGHTS = 784
)
(
    // System signals
    input  logic clk,
    input  logic rst_n,
    
    // SLAVE SIDE
    
    // control signals
    output logic rtr_o,
    input  logic rts_i,
    input  logic sow_i,
    input  logic eow_i,
    // addr
    input logic [log2(NB_WEIGHTS)-1:0] address_i,
    
    // MASTER SIDE
            
    // control signals
    input  logic rtr_i,
    output logic rts_o,
    output logic eow_o,
    output logic sow_o,
    // posit out
    output logic [POSIT_WIDTH-1:0] posit_o
    
);

// init ROM
logic [POSIT_WIDTH-1:0] weights_ROM [NB_WEIGHTS-1:0];
initial begin
    $readmemb(PATH, weights_ROM);
end

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
// address
logic [log2(NB_WEIGHTS)-1:0] latched_address, address_in;

// pipeline control signals
localparam integer PIPELEN = DELAY;
logic [PIPELEN:0] stage_en;
logic [PIPELEN:0] stage_clr;
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
        latched_address <= 0;
    end
    else begin
       if ( receive_en & ~process_en ) begin
           latched <= 1;
           latched_sow_i <= sow_i;
           latched_eow_i <= eow_i;
           latched_address <= address_i;
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
assign sow[0]      = (latched)? latched_sow_i   : sow_i;
assign eow[0]      = (latched)? latched_eow_i   : eow_i;
assign address_in  = (latched)? latched_address : address_i;

// accept 1 datum if pipeline works and upstream module is able to provide or latched is present
assign stage_en[0] = process_en & ( receive_en | latched );
// clear first stage when pipeline works and upstream module is unable to provide data and no latched data present
assign stage_clr[0] = process_en & ( ~receive_en & ~latched );

// pipeline posit from ROM
logic [POSIT_WIDTH-1:0] posit_rom_pipeline [PIPELEN:0] ;
assign posit_rom_pipeline[0] = weights_ROM[address_in];

genvar i;
for (i = 0 ; i < PIPELEN ; i++) begin

    assign stage_en[i+1]  =  staged[i] & process_en;
    assign stage_clr[i+1] = ~staged[i] & process_en;
    
    always_ff @( posedge clk or negedge rst_n) begin
        if ( ~rst_n ) begin
            staged[i] <= 1'b0;
            sow[i+1]  <= 1'b0;
            eow[i+1]  <= 1'b0;
            posit_rom_pipeline[i+1] <= 0;
        end
        else begin
            if ( stage_en[i] ) begin
                staged[i] <= 1'b1;
                sow[i+1]  <= sow[i];
                eow[i+1]  <= eow[i];
                posit_rom_pipeline[i+1] <= posit_rom_pipeline[i];
            end
            else if ( stage_clr[i] ) begin
                staged[i] <= 1'b0;
                eow[i+1] <= 1'b0;
                sow[i+1] <= 1'b0;
            end
        end
    end
end


//                          __           
//    ____ ___  ____ ______/ /____  _____
//   / __ `__ \/ __ `/ ___/ __/ _ \/ ___/
//  / / / / / / /_/ (__  ) /_/  __/ /    
// /_/ /_/ /_/\__,_/____/\__/\___/_/     

assign posit_o   = posit_rom_pipeline[PIPELEN];
assign rts_o_int = staged[PIPELEN-1];
assign rts_o     = rts_o_int;
assign eow_o     = eow[PIPELEN];
assign sow_o     = sow[PIPELEN];

endmodule
