`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: Ledoux Louis
// 
// Create Date: 11/14/2018 03:47:31 PM
// Design Name: 
// Module Name: tb_LOD_N
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


module tb_LOD_N();

    // system signals    
    logic rst_n;
    logic clk;
    
    // dut signals
    logic [127:0]data_in_128;
    logic [6:0]  data_out_128;
    logic [63:0] data_in_64;
    logic [5:0]  data_out_64;
    logic [31:0] data_in_32;
    logic [4:0]  data_out_32;
    logic [11:0] data_in_12;
    logic [3:0]  data_out_12;
    logic [11:0] data_in_12_orig;
    logic [3:0]  data_out_12_orig;
    logic [15:0] data_in_16_LUT;
    logic [3:0]  data_out_16_LUT;
    logic [15:0] data_in_16;
    logic [3:0]  data_out_16;
    logic [71:0]   data_in_72;
    logic [$clog2(71+1)-1:0]   data_out_72;
    
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
    LOD_N #(
        .C_N ( 72 )
    ) lod_72_inst (
        .in  ( data_in_72  ),
        .out ( data_out_72 )
    );
    
    // LOD 64 bits recursive gen no clk
    LOD_N #(
        .C_N ( 128 )
    ) lod_64_inst (
        .in  ( data_in_128  ),
        .out ( data_out_128 )
    );
    
    // LOD 32 bits recursive gen no clk
    LOD_N #(
        .C_N ( 32 )
    ) lod_32_inst (
        .in  ( data_in_32  ),
        .out ( data_out_32 )
    );
    
    // LOD 16 bits recursive gen no clk
    LOD_N #(
        .C_N ( 16 )
    ) lod_16_inst (
        .in  ( data_in_16  ),
        .out ( data_out_16 )
    );
    
    // LOD 16 bits clk lut casex
    LOD_16b_LUT  lod_16_lut_inst (
        .in    ( data_in_16_LUT  ),
        .out   ( data_out_16_LUT )
    );
    
    // LOD 12 bits recursive gen no clk
    LOD_N #(
        .C_N ( 12 )
    ) lod_12_inst (
        .in  ( data_in_12  ),
        .out ( data_out_12 )
    );   
 
    // LOD 12 bits recursive gen no clk from origin code
    orig_LOD_N #(
        .N ( 12 )
    ) orig_lod_12_inst (
        .in  ( data_in_12_orig  ),
        .out ( data_out_12_orig )
    );
         
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_in_128 <= {1'b1,{127{1'b0}}};
            data_in_72 <= {1'b1,{71{1'b0}}};
            data_in_64 <= {1'b1,{63{1'b0}}};
            data_in_32 <= {1'b1,{31{1'b0}}};
            data_in_16 <= {1'b1,{15{1'b0}}};
            data_in_16_LUT <= {1'b1,{15{1'b0}}};
            data_in_12 <= {1'b1,{11{1'b0}}};
            data_in_12_orig <= {1'b1,{11{1'b0}}};
        end
        else begin
            data_in_128     <= {data_in_128[0]     , data_in_128[127:1]};
            data_in_72      <= {data_in_72[0]      , data_in_72[71:1]};
            data_in_64      <= {data_in_64[0]      , data_in_64[63:1]};
            data_in_32      <= {data_in_32[0]      , data_in_32[31:1]};
            data_in_16      <= {data_in_16[0]      , data_in_16[15:1]};
            data_in_16_LUT  <= {data_in_16_LUT[0]  , data_in_16_LUT[15:1]};
            data_in_12      <= {data_in_12[0]      , data_in_12[11:1]};
            data_in_12_orig <= {data_in_12_orig[0] , data_in_12_orig[11:1]};;
        end
    end
endmodule
