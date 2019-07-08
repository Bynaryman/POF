`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: Ledoux Louis
// 
// Create Date: 11/15/2018 03:38:31 PM
// Design Name: 
// Module Name: tb_LZD_16
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
// test bench for LZD lut 16bits
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_LZD_16();

    // system signals    
    logic rst_n;
    logic clk;

    // dut signals
    logic [15:0] data_in_16_LUT;
    logic [3:0]  data_out_16_LUT;
    logic [15:0] data_in_16_orig;
    logic [3:0]  data_out_16_orig;

    task apply_reset();
        clk <= 1;
        #5  rst_n <= 0;
        #20 rst_n <= 1;
    endtask
    
    // init reset
    initial begin
        apply_reset();
    end
    
    // clock generation
    always begin
        #5 clk <= ~clk;
    end

    // instanciate DUTs

    // LOD 16 bits clk lut casex
    LZD_16b_LUT  lzd_16_lut_inst (
        .in    ( data_in_16_LUT  ),
        .out   ( data_out_16_LUT )
    );

    // LOD 16 bits clk lut casex
    LZD_N  # (
        .N( 16 )	    
    )    
    lzd_16_orig_inst (
        .in    ( data_in_16_orig  ),
        .out   ( data_out_16_orig )
    );


    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_in_16_LUT  <= {1'b0,{15{1'b1}}};
            data_in_16_orig <= {1'b0,{15{1'b1}}};
        end
        else begin
            data_in_16_LUT  <= {data_in_16_LUT[0], data_in_16_LUT[15:1]};
            data_in_16_orig <= {data_in_16_orig[0], data_in_16_orig[15:1]};
        end
    end

endmodule
