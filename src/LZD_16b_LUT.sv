`timescale 1ns/1ps 
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: Ledoux Louis
// 
// Create Date: 11/15/2018 3:30:29 PM
// Design Name: 
// Module Name: LZD_16b_LUT
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
//     Experimenting fast LUT casex wildcard LZD
//
//       
//////////////////////////////////////////////////////////////////////////////////

module LZD_16b_LUT (
    input  logic [15:0] in,
    output logic [3:0] out
);

    always_comb  begin
        casex (in)
            16'b0???_????_????_???? : out = 4'd0; 
            16'b10??_????_????_???? : out = 4'd1;
            16'b110?_????_????_???? : out = 4'd2;
            16'b1110_????_????_???? : out = 4'd3;
            16'b1111_0???_????_???? : out = 4'd4;
            16'b1111_10??_????_???? : out = 4'd5;
            16'b1111_110?_????_???? : out = 4'd6;
            16'b1111_1110_????_???? : out = 4'd7;
            16'b1111_1111_0???_???? : out = 4'd8;
            16'b1111_1111_10??_???? : out = 4'd9;
            16'b1111_1111_110?_???? : out = 4'd10;
            16'b1111_1111_1110_???? : out = 4'd11;
            16'b1111_1111_1111_0??? : out = 4'd12;
            16'b1111_1111_1111_10?? : out = 4'd13;
            16'b1111_1111_1111_110? : out = 4'd14;
            16'b1111_1111_1111_1110 : out = 4'd15;
            default                 : out = 4'd0;
        endcase
    end

endmodule
