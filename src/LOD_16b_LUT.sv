`timescale 1ns/1ps 
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: Ledoux Louis
// 
// Create Date: 11/15/2018 10:53:24 AM
// Design Name: 
// Module Name: LOD_16b_LUT
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
//     Experimenting fast LUT casex wildcard LOD
//
//       
//////////////////////////////////////////////////////////////////////////////////

module LOD_16b_LUT (
    input  logic [15:0] in,
    output logic [3:0] out
);

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

endmodule
