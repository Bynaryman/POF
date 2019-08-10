`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: LEDOUX Louis
// 
// Create Date: 12/19/2018 03:01:14 PM
// Design Name: 
// Module Name: positron_layer
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

module positron_layer #
(
    parameter integer NB_UPSTREAM_POSITRON = 784,
    parameter WEIGHTS_BASE_PATH = "/home/lledoux/Desktop/PhD/ML/C/mnist-3lnn/hidden_weights/hidden_weights_",
    parameter integer NB_POSITRON = 20,
    parameter integer POSIT_WIDTH = 16,
    parameter integer POSIT_ES    = 0
)
(
    // System signals
    input  logic clk,
    input  logic rst_n,
    
    // SLAVE SIDE
    
    // control signals
    output logic rtr_o,
    input  logic rts_i,
    input  logic eow_i,  // end of DMA
    
    input logic [POSIT_WIDTH-1:0] posit_i ,
    
    
    // MASTER SIDE
        
    // control signals
    input  logic rtr_i,
    output logic rts_o,
    output logic eow_o,
    
    output logic [POSIT_WIDTH-1:0] posit_o
);

// local parameters

// signals

// fake dma tfirst
logic fake_sow_i;
logic rts_i_r;

// intermediate sow and eow
logic sow_xxx_i;  // start of frame
logic eow_xxx_i;  // end of frame
logic [$clog2(NB_UPSTREAM_POSITRON)-1:0]wc;  // word in counter

// positrons
logic positrons_ready [NB_POSITRON-1:0];
logic positrons_valid [NB_POSITRON-1:0];
logic positrons_eow_o [NB_POSITRON-1:0];
logic [POSIT_WIDTH-1:0] positrons_posit_o [NB_POSITRON-1:0];

// memory to stream
logic mm2s_ready_o;
logic mm2s_valid_o;
logic [POSIT_WIDTH-1:0] mm2s_data_o;


//    _____ __               
//   / ___// /___ __   _____ 
//   \__ \/ / __ `/ | / / _ \
//  ___/ / / /_/ /| |/ /  __/
// /____/_/\__,_/ |___/\___/ 

// layer is ready when one positron is ready
// assuming they all have same latency and same behaviour
assign rtr_o = positrons_ready[0];

// logic for fake sow of DMA
always @(posedge clk or negedge rst_n) begin
    if ( ~rst_n ) begin
        rts_i_r <= 0;
    end
    else begin
        rts_i_r <= rts_i;
    end
end
assign fake_sow_i = ( wc == 0 ) & rts_i;

// wc logic
// count from [0;NB_UPSTREAM_POSITRON-1] -> NB_UPSTREAM_POSITRON values
always_ff @( posedge clk or negedge rst_n ) begin
    if ( ~rst_n ) begin
        wc <= 0;
    end
    else if ( rts_i &  rtr_o ) begin
        if ( fake_sow_i ) begin
            wc <= 1;
        end
        else if ( eow_i | (wc >= (NB_UPSTREAM_POSITRON - 1)) ) begin
            wc <= 0;
        end
        else begin
            wc <= wc + 1;
        end
    end
end

// frame sow/eow logic
assign sow_xxx_i = ( wc == 0 ) & rts_i;
assign eow_xxx_i = ( wc == (NB_UPSTREAM_POSITRON-1) ) & rts_i;

// dma tlast propagate logic
logic dma_tlast_i;
logic dma_tlast_o;

always_ff @( posedge clk or negedge rst_n ) begin
    if ( ~rst_n ) begin
        dma_tlast_i <= 0;
    end
    else if ( eow_i & rts_i ) begin  // if last word of dma we latch to 1 
        dma_tlast_i <= 1;
    end
    else if ( positrons_eow_o[0] ) begin
        dma_tlast_i <= 0;
    end 
end


//     ____             _ __                       
//    / __ \____  _____(_) /__________  ____  _____
//   / /_/ / __ \/ ___/ / __/ ___/ __ \/ __ \/ ___/
//  / ____/ /_/ (__  ) / /_/ /  / /_/ / / / (__  ) 
// /_/    \____/____/_/\__/_/   \____/_/ /_/____/  
                                                

genvar positron_i;
for (positron_i = 0 ; positron_i < NB_POSITRON ; positron_i++) begin
   
    positron#
    (
        .POSIT_WIDTH          ( POSIT_WIDTH                  ),
        .POSIT_ES             ( POSIT_ES                     ),
        .WEIGHTS_BASE_PATH    ( WEIGHTS_BASE_PATH            ),
        .WEIGHTS_FILE_NUMBER  ( `GENVAR_TO_ASCII(positron_i) ),
        .NB_UPSTREAM_POSITRON ( NB_UPSTREAM_POSITRON         ),
        .LOG_NB_ACCUM         ( 15 /*$clog2(NB_UPSTREAM_POSITRON)*/ )  // handle at least all the accumulation of previous layer
    )
    positron_inst(
    
        // System signals
        .clk     ( clk                           ),
        .rst_n   ( rst_n                         ),
        
        // SLAVE SIDE
        
        // control signals
        .rtr_o   ( positrons_ready[positron_i]   ),
        .rts_i   ( rts_i                         ),
        .sow_i   ( sow_xxx_i                     ),
        .eow_i   ( eow_xxx_i                     ),
        
        .posit_i ( posit_i                       ),
        
        
        // MASTER SIDE
            
        // control signals
        .rtr_i   ( mm2s_ready_o                  ),
        .rts_o   ( positrons_valid[positron_i]   ),
        .eow_o   ( positrons_eow_o[positron_i]   ),  // last accumulation
        
        .posit_o ( positrons_posit_o[positron_i] )
    );
end

memory_to_stream # (
    .DATA_WIDTH   ( POSIT_WIDTH ),
    .MEMORY_DEPTH ( NB_POSITRON )
) memory_to_stream_inst (

    // System signals
    .clk     ( clk               ),
    .rst_n   ( rst_n             ),
    
    // SLAVE SIDE
    
    // control signals
    .rtr_o   ( mm2s_ready_o       ),
    .rts_i   ( positrons_valid[0] & positrons_eow_o[0] ),  // when one has finish accumulation, they all have
    .eow_i   ( dma_tlast_i  &  positrons_eow_o[0] ),  // propagate dma tlast
    
    .data_i  ( positrons_posit_o  ),
    
    
    // MASTER SIDE
        
    // control signals
    .rtr_i   ( rtr_i              ),
    .rts_o   ( mm2s_valid_o       ),
    .eow_o   ( dma_tlast_o        ),
    
    .data_o  ( mm2s_data_o        )
);


//                          __           
//    ____ ___  ____ ______/ /____  _____
//   / __ `__ \/ __ `/ ___/ __/ _ \/ ___/
//  / / / / / / /_/ (__  ) /_/  __/ /    
// /_/ /_/ /_/\__,_/____/\__/\___/_/     

assign posit_o = mm2s_data_o;
assign rts_o = mm2s_valid_o;
assign eow_o = dma_tlast_o;

endmodule
