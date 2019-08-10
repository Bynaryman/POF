`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: Ledoux Louis
// 
// Create Date: 11/13/2018 04:36:03 PM
// Design Name: 
// Module Name: tb_posit_data_extract
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

// `define GET_SCALE_WIDTH( p_w, p_es, prod_acc ) \
//     (prod_acc) ? \
//         (($clog2(((2**p_es) * (p_w-1))-1))+2) : \
//         (($clog2(((2**p_es) * (p_w-1))-1))+1)
//     
// `define GET_FRACTION_WIDTH( p_w, p_es, prod_acc ) \
//     (prod_acc) ? \
//         (((p_w - p_es - 3)+1)*2) : \
//         (p_w - p_es - 3)

import posit_defines::*;

module tb_posit_data_extract #();

    localparam integer C_WIDTH = 8;
    localparam integer C_ES    = 0;
    localparam integer C_SCALE_WIDTH = (`GET_SCALE_WIDTH( C_WIDTH, C_ES, 0 ));
    localparam integer C_FRACTION_WIDTH = (`GET_FRACTION_WIDTH( C_WIDTH, C_ES, 0));

    logic rst_n;
    logic clk;
    logic [C_WIDTH-1:0] counter;

    task apply_reset();
        clk <= 1;
        #5  rst_n <= 0;
        #20 rst_n <= 1;
    endtask
    
    // init reset
    initial begin
        apply_reset();
    end
    
    // load file with posit words
    //reg [15:0] data [0:65535];
    //initial $readmemb("/home/lledoux/Desktop/PhD/fpga/my_posits/my_posits.srcs/sim_1/new/tb_16b_values.txt", data);
    
    
    // clock generation
    always begin
        #5 clk <= ~clk;
    end
    
   
    logic [C_WIDTH-1:0] data_in;
    logic sign;
    logic inf;
    logic zero;
    logic [C_SCALE_WIDTH-1:0] scale;
    logic [C_FRACTION_WIDTH-1:0] fraction;

    // instanciate DUT
    posit_data_extract  # (
        .POSIT_WIDTH( C_WIDTH ),
        .POSIT_ES   ( C_ES    )
    ) pde_inst (
    
        // inputs
        .posit_word_i       ( data_in  ),

        // outputs
        .sign               ( sign     ),
        .inf                ( inf      ),
        .zero               ( zero     ),
        .scale              ( scale    ),
        .fraction           ( fraction )
    );

    // instanciate original DUT from manish-kj to compare
    
    
    // loading new data at each clok posedge
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin 
            data_in <= 0;
        end
        else begin
            data_in <= counter;
        end
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin 
            counter <= 0;
        end
        else if (counter == 8'hff ) begin
            $finish;
        end
        else begin
            counter <= counter + 1;
        end
    end

endmodule
