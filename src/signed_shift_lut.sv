`default_nettype none
`timescale 1ns/1ps 
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: Ledoux Louis
// 
// Create Date: 11/15/2018 10:53:24 AM
// Design Name: signed_shift_lut 
// Module Name: 
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
//
//////////////////////////////////////////////////////////////////////////////////

module signed_shift_lut (
    input  wire [5:0] in,
    output logic [11:0] out
);

    always_comb  begin
        case (in)
            6'd0    : out = 9'b/*000*/000010000;//00000000;
            6'd1    : out = 9'b/*000*/000100000;//00000000;
            6'd2    : out = 9'b/*000*/001000000;//00000000;
            6'd3    : out = 9'b/*000*/010000000;//00000000;
            6'd4    : out = 9'b/*000*/100000000;//00000000;
            6'd5    : out = 9'b/*001*/000000000;//00000000;
            6'd6    : out = 9'b/*010*/000000000;//00000000;
            6'd7    : out = 9'b/*100*/000000000;//00000000;
            6'd8    : out = 9'b/*000*/000000000;//00010000;
            6'd9    : out = 9'b/*000*/000000000;//00100000;
            6'd10   : out = 9'b/*000*/000000000;//01000000;
            6'd11   : out = 9'b/*000*/000000000;//10000000;
            6'd12   : out = 9'b/*000*/000000001;//00000000;
            6'd13   : out = 9'b/*000*/000000010;//00000000;
            6'd14   : out = 9'b/*000*/000000100;//00000000;
            6'd15   : out = 9'b/*000*/000001000;//00000000;
            6'd16   : out = 9'b/*000*/000010010;//00000000;
            6'd17   : out = 9'b/*000*/000100100;//00000000;
            6'd18   : out = 9'b/*000*/001001000;//00000000;
            6'd19   : out = 9'b/*000*/010010000;//00000000;
            6'd20   : out = 9'b/*000*/100100000;//00000000;
            6'd21   : out = 9'b/*001*/001000000;//00000000;
            6'd22   : out = 9'b/*010*/010000000;//00000000;
            6'd23   : out = 9'b/*100*/100000000;//00000000;
            6'd24   : out = 9'b/*000*/000000000;//00010010;
            6'd25   : out = 9'b/*000*/000000000;//00100100;
            6'd26   : out = 9'b/*000*/000000000;//01001000;
            6'd27   : out = 9'b/*000*/000000000;//10010000;
            6'd28   : out = 9'b/*000*/000000001;//00100000;
            6'd29   : out = 9'b/*000*/000000010;//01000000;
            6'd30   : out = 9'b/*000*/000000100;//10000000;
            6'd31   : out = 9'b/*000*/000001001;//00000000;
            6'd32   : out = 9'b/*000*/000011000;//00000000;
            6'd33   : out = 9'b/*000*/000110000;//00000000;
            6'd34   : out = 9'b/*000*/001100000;//00000000;
            6'd35   : out = 9'b/*000*/011000000;//00000000;
            6'd36   : out = 9'b/*000*/110000000;//00000000;
            6'd37   : out = 9'b/*001*/100000000;//00000000;
            6'd38   : out = 9'b/*011*/000000000;//00000000;
            6'd39   : out = 9'b/*110*/000000000;//00000000;
            6'd40   : out = 9'b/*000*/000000000;//00011000;
            6'd41   : out = 9'b/*000*/000000000;//00110000;
            6'd42   : out = 9'b/*000*/000000000;//01100000;
            6'd43   : out = 9'b/*000*/000000000;//11000000;
            6'd44   : out = 9'b/*000*/000000001;//10000000;
            6'd45   : out = 9'b/*000*/000000011;//00000000;
            6'd46   : out = 9'b/*000*/000000110;//00000000;
            6'd47   : out = 9'b/*000*/000001100;//00000000;
            6'd48   : out = 9'b/*000*/000011010;//00000000;
            6'd49   : out = 9'b/*000*/000110100;//00000000;
            6'd50   : out = 9'b/*000*/001101000;//00000000;
            6'd51   : out = 9'b/*000*/011010000;//00000000;
            6'd52   : out = 9'b/*000*/110100000;//00000000;
            6'd53   : out = 9'b/*001*/101000000;//00000000;
            6'd54   : out = 9'b/*011*/010000000;//00000000;
            6'd55   : out = 9'b/*110*/100000000;//00000000;
            6'd56   : out = 9'b/*000*/000000000;//00011010;
            6'd57   : out = 9'b/*000*/000000000;//00110100;
            6'd58   : out = 9'b/*000*/000000000;//01101000;
            6'd59   : out = 9'b/*000*/000000000;//11010000;
            6'd60   : out = 9'b/*000*/000000001;//10100000;
            6'd61   : out = 9'b/*000*/000000011;//01000000;

            default : out = 12'b000000000000;
        endcase
    end

endmodule
`default_nettype wire