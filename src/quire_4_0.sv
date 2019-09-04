`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: Ledoux Louis
// 
// Create Date: 12/10/2018 09:28:24 AM
// Design Name: 
// Module Name: quire
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Generic quire.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

import posit_defines::*;

module quire_4_0 #
(
    parameter integer LOG_NB_ACCUM = 10,
    parameter integer IS_PROD_ACCUM = 1
)
(
    
    // System signals
    input  wire clk,
    input  wire rst_n,

    // Slave side
    output logic rtr_o,
    input  wire rts_i,
    input  wire sow_i,
    input  wire eow_i,
    input  wire [3:0] fraction,
    input  wire signed [3:0] scale,
    input  wire sign_i,
    input  wire zero_i,
    input  wire NaR_i,
    
    // Master side
    input  wire rtr_i,
    output logic rts_o,
    output logic eow_o,
    output logic sow_o,
    output logic [18:0] data_o,
    output logic NaR_o,
    output logic sign_o,
    output logic zero_o

);

// localparam for size of internal registers
localparam integer QUIRE_SIZE     = 19;
localparam integer FRACTION_WIDTH = 4;
localparam integer SCALE_WIDTH    = 4;

// localparam to compute size binary point offsets
localparam integer es = 0;
localparam integer posit_width = 4;
localparam integer nqmin = (2**(es+2))*(posit_width-2)+1; //4*2+1=9
localparam integer log_nb_accum = LOG_NB_ACCUM;
localparam integer nq = nqmin + log_nb_accum; // 19
localparam integer binary_point_position = (nqmin-1)/2; // 4
localparam integer bpp_lsb = binary_point_position - FRACTION_WIDTH; // 4-4=0
localparam integer bias_sf_mult = (2**(es+1))*(posit_width-2); //2*2=4


// signal state control
logic process_en;
logic receive_en;
logic rtr_o_int;
logic rts_o_int;

// signal latched inputs
logic latched;
logic latched_zero_i;
logic latched_NaR_i;
logic latched_sign_i;
logic latched_sow_i;
logic latched_eow_i;
logic [FRACTION_WIDTH-1:0] latched_fraction;
logic signed [SCALE_WIDTH-1:0]  latched_scale;

logic zero_in;
logic NaR_in;
logic sign_in;
logic [FRACTION_WIDTH-1:0] fraction_in;
logic signed [SCALE_WIDTH-1:0]  scale_in;

// pipeline control signals
localparam integer PIPELEN = 2;
logic [PIPELEN-1:0] stage_en;
logic [PIPELEN-1:0] stage_clr;
logic [PIPELEN-1:0] staged;

logic [PIPELEN:0] sow;
logic [PIPELEN:0] eow;

//    _____ __               
//   / ___// /___ __   _____ 
//   \__ \/ / __ `/ | / / _ \
//  ___/ / / /_/ /| |/ /  __/
// /____/_/\__,_/ |___/\___/ 

// Shift condition: downstream module ready for receive, 
// or current module not ready to send
assign process_en = rtr_i | ~rts_o_int;

// Receive condition: current module ready for receive, 
// and upstream module ready to send
assign receive_en = rts_i & rtr_o_int;

always_ff @(posedge clk) rtr_o_int <= process_en;

assign rtr_o = rtr_o_int;

//     ____  _            ___          
//    / __ \(_)___  ___  / (_)___  ___ 
//   / /_/ / / __ \/ _ \/ / / __ \/ _ \
//  / ____/ / /_/ /  __/ / / / / /  __/
// /_/   /_/ .___/\___/_/_/_/ /_/\___/ 
//        /_/                          

//    ___
//   <  /
//   / / 
//  / /  
// /_/   
      
// accept 1 datum if pipeline works and upstream module is able to provide or latched is present
assign stage_en[0] = process_en & receive_en;
// clear first stage when pipeline works and upstream module is unable to provide data and no latched data present
assign stage_clr[0] = process_en & ~receive_en;

logic sign_r1, NaR_r1, zero_r1, RaZ_r1;

wire signed [8:0] shifted;
signed_shift_lut 
signed_shift_lut_inst (
    .clk ( clk  ),
    .in  ( { fraction_in[3], fraction_in[1], scale_in} ),
    .out ( shifted )
);

always_ff @( posedge clk ) begin
    if ( ~rst_n ) begin
         staged[0] <= 0;
         sow[1]    <= 0;
         eow[1]    <= 0;
         shifted   <= 0;
         sign_r1   <= 0;
         NaR_r1    <= 0;
         zero_r1   <= 0;
         RaZ_r1    <= 0;
    end
    else begin
        if ( stage_en[0] ) begin
            staged[0] <= 1;
            sow[1]    <= sow[0];
            eow[1]    <= eow[0];
            sign_r1 <= sign_in;
            NaR_r1 <= NaR_in;
            zero_r1 <= zero_in;
        end
        else if ( stage_clr[0] ) begin
            staged[0] <= 0;
        end
    end
end


// always_ff @( posedge clk or negedge rst_n ) begin
//     if ( ~rst_n ) begin
//          staged[0]   <= 0;
//          sow[1]      <= 0;
//          eow[1]      <= 0;
//          shift_register <= 0;
//          sign_r1 <= 0;
//          NaR_r1 <= 0;
//          zero_r1 <= 0;
//          RaZ_r1 <= 0;
//     end
//     else begin
//         if ( stage_en[0] ) begin
//             staged[0] <= 1;
//             sow[1]    <= sow[0];
//             eow[1]    <= eow[0];
//              //handle negative scale
//             if (scale_in[SCALE_WIDTH-1]) begin // TODO !!
//                 shift_register <= (frac_hidden >> (bpp_lsb - $signed(scale_in) ));
//             end
//             else begin
//                 shift_register <= (frac_hidden << (bpp_lsb + $signed(scale_in)) );
//             end
//             //shift_register <= (frac_hidden << (bias_sf_mult + scale_in));
//             sign_r1 <= sign_in;
//             NaR_r1 <= NaR_in;
//             zero_r1 <= zero_in;
//         end
//         else if ( stage_clr[0] ) begin
//             staged[0] <= 0;
//         end
//     end
// end

//    ___ 
//   |__ \
//   __/ /
//  / __/ 
// /____/ 

assign stage_en[1]  =  staged[0] & process_en;
assign stage_clr[1] = ~staged[0] & process_en;

logic signed [QUIRE_SIZE-1:0] quire_r;
logic  NaR_r2;

always_ff @( posedge clk ) begin
    if ( ~rst_n ) begin
         staged[1] <= 0;
         sow[2]    <= 0;
         eow[2]    <= 0;
         quire_r   <= 0;
         NaR_r2    <= 0; 
    end
    else begin
        if ( stage_en[1] ) begin
            staged[1] <= 1;
            sow[2]    <= sow[1];
            eow[2]    <= eow[1];
            if ( ~NaR_r1 ) begin
                if ( ~zero_r1 ) begin
                    if ( sow[1] ) begin //sow
                        quire_r   <= (sign_r1) ?  - shifted :
                                                  + shifted ;
                    end
                    else begin
                        quire_r   <= (sign_r1) ?  quire_r - shifted :
                                                  quire_r + shifted ;
                    end
                end
                else begin
                   if ( sow[1] ) begin // sow and zero
                       quire_r <= 0;
                   end
                end
            end
            NaR_r2 <= NaR_r1; // TODO
        end
        else if ( stage_clr[1] ) begin
            staged[1] <= 0;
        end
    end
end

//                          __           
//    ____ ___  ____ ______/ /____  _____
//   / __ `__ \/ __ `/ ___/ __/ _ \/ ___/
//  / / / / / / /_/ (__  ) /_/  __/ /    
// /_/ /_/ /_/\__,_/____/\__/\___/_/     

assign rts_o_int = staged[1];
assign rts_o     = rts_o_int;
assign eow_o     = eow[PIPELEN];
assign sow_o     = sow[PIPELEN];
assign data_o    = quire_r;
assign sign_o    = quire_r[QUIRE_SIZE-1];
assign NaR_o     = NaR_r2; // TODO
assign zero_o    = ~|quire_r;

endmodule
`default_nettype wire
