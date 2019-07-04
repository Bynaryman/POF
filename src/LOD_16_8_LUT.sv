`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/01/2019 12:40:33 PM
// Design Name: 
// Module Name: LOD_16_8_LUT
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


module LOD_16_8_LUT #
(
    parameter integer NB_BIT = 16  // 8 or 16
)
(
    input  logic [NB_BIT-1:0] in,
    output logic [$clog2(NB_BIT)-1:0] out
);

if ( NB_BIT == 16 ) begin
    always_comb  begin
        casex (in)
            16'b1???_????_????_???? : out = 4'd0; 
            16'b01??_????_????_???? : out = 4'd1;
            16'b001?_????_????_???? : out = 4'd2;
            16'b0001_????_????_???? : out = 4'd3;
            16'b0000_1???_????_???? : out = 4'd4;
            16'b0000_01??_????_???? : out = 4'd5;
            16'b0000_001?_????_???? : out = 4'd6;
            16'b0000_0001_????_???? : out = 4'd7;
            16'b0000_0000_1???_???? : out = 4'd8;
            16'b0000_0000_01??_???? : out = 4'd9;
            16'b0000_0000_001?_???? : out = 4'd10;
            16'b0000_0000_0001_???? : out = 4'd11;
            16'b0000_0000_0000_1??? : out = 4'd12;
            16'b0000_0000_0000_01?? : out = 4'd13;
            16'b0000_0000_0000_001? : out = 4'd14;
            16'b0000_0000_0000_0001 : out = 4'd15;
            default                 : out = 4'd0;
        endcase
    end
end

if ( NB_BIT == 8 ) begin
    always_comb  begin
        casex (in)
            8'b1???_???? : out = 3'd0; 
            8'b01??_???? : out = 3'd1;
            8'b001?_???? : out = 3'd2;
            8'b0001_???? : out = 3'd3;
            8'b0000_1??? : out = 3'd4;
            8'b0000_01?? : out = 3'd5;
            8'b0000_001? : out = 3'd6;
            8'b0000_0001 : out = 3'd7;
            default      : out = 3'd0;
        endcase
    end
end

endmodule