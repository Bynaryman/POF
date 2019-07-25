`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: LEDOUX Louis
// 
// Create Date: 01/10/2019 02:37:36 PM
// Design Name: 
// Module Name: memory_to_stream
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


module memory_to_stream #
(
    parameter integer DATA_WIDTH = 16,
    parameter integer MEMORY_DEPTH = 20
)
(
    // System signals
    input  logic clk,
    input  logic rst_n,
    
    // SLAVE SIDE
    
    // control signals
    output logic rtr_o,
    input  logic rts_i,
    input  logic eow_i,
    
    input logic [DATA_WIDTH-1:0] data_i [MEMORY_DEPTH-1:0],
    
    
    // MASTER SIDE
        
    // control signals
    input  logic rtr_i,
    output logic rts_o,
    output logic eow_o,
    
    output logic [DATA_WIDTH-1:0] data_o
);

typedef enum logic [2:0] { IDLE, LOAD_VALUES, SEND_STREAM } State;

State sm_state = IDLE;

// Axi Stream internal signals
logic tvalid;
logic tlast;
logic [DATA_WIDTH-1:0] tdata;

logic eow_i_r1;

// internal RAM
logic [DATA_WIDTH-1:0] data_intern [MEMORY_DEPTH-1:0];

// counter
logic [$clog2(MEMORY_DEPTH)-1:0] counter;

assign rts_o  = tvalid;
assign data_o = tdata;
assign eow_o  = tlast;

always_ff @(posedge clk or negedge rst_n) begin
    if ( ~rst_n ) begin
        sm_state <= IDLE;
    end
    else begin
        case(sm_state)
            
            IDLE: begin
                tvalid <= 0;
                eow_i_r1 <= 0;
                tlast  <= 0;
                tdata  <= 0;
                counter <= 0;
                data_intern <= '{default:'0};
                rtr_o <= 1;
                if ( rts_i & rtr_i ) begin
                    sm_state <= SEND_STREAM;
                    eow_i_r1 <= eow_i;
                    data_intern <= data_i;
                    rtr_o <= 0;;
                end
            end
                       
            SEND_STREAM: begin
                rtr_o <= 0;
                tvalid <= 1;
                tdata <= data_intern[counter];
                if ( rtr_i ) begin
                    counter <= counter + 1;
                end
                // TODO(lledoux) : FIXME, when rtr_i deassert, one data is lost because of 1 clk delay:
                // 1 possible solution is
                // if ( ~rtr_i ) begin
                //     tdata <= data_intern[counter-1];
                // end
                if ( counter == (MEMORY_DEPTH-1) ) begin
                    if ( eow_i_r1 ) begin
                        tlast <= 1;
                    end
                    eow_i_r1 <= 0;
                    sm_state <= IDLE;
                end
            end
            
            default: begin
                sm_state <= IDLE;
            end
         endcase
    end
end
    
endmodule
