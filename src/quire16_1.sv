`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/22/2018 01:51:49 PM
// Design Name: 
// Module Name: quire16_1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: first draft of quire for 16 bits es 1
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module quire16_1 #
(
    // for default posit16_1 accumulation choose 12;6
    // choose 26;7 for product accumulation
    parameter integer FRACTION_WIDTH = 12,
    parameter integer SCALE_WIDTH = 6
)
(
    
    // System signals
    input  clk,
    input  rst_n,

    // Slave side
    output rtr_o,
    input  rts_i,
    input  sow_i,
    input  eow_i,
    input  [FRACTION_WIDTH-1:0] fraction,
    input  [SCALE_WIDTH-1:0] scale,
    input  sign_i,
    input  zero_i,
    input  NaR_i,
    
    // Master side
    input  rtr_i,
    output rts_o,
    output eow_o,
    output sow_o,
    output [127:0] data_o,
    output NaR_o

);

localparam integer es = 1;
localparam integer posit_width = 16;
localparam integer nqmin = (2**(es+2))*(posit_width-2)+1;
localparam integer log_nb_accum = posit_width-1;
localparam integer nq = nqmin + log_nb_accum;
localparam integer binary_point_position = (nqmin-1)/2;
localparam integer bpp_lsb = binary_point_position - FRACTION_WIDTH;

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
logic [SCALE_WIDTH-1:0]  latched_scale;

logic zero_in;
logic NaR_in;
logic sign_in;
logic [FRACTION_WIDTH-1:0] fraction_in;
logic [SCALE_WIDTH-1:0]  scale_in;

// pipeline control signals
localparam integer PIPELEN = 2;
logic [PIPELEN-1:0] stage_en;
logic [PIPELEN-1:0] stage_clr;
logic [PIPELEN-1:0] staged;

logic [PIPELEN:0] sow;
logic [PIPELEN:0] eow;

// Shift condition: downstream module ready for receive, 
// or current module not ready to send
assign process_en = rtr_i | ~rts_o_int;

// Receive condition: current module ready for receive, 
// and upstream module ready to send
assign receive_en = rts_i & rtr_o_int;

//    _____ __               
//   / ___// /___ __   _____ 
//   \__ \/ / __ `/ | / / _ \
//  ___/ / / /_/ /| |/ /  __/
// /____/_/\__,_/ |___/\___/ 

always_ff @( posedge clk or negedge rst_n ) begin
    if ( ~rst_n ) begin
        latched <= 0;
        latched_zero_i <= 0;
        latched_sign_i <= 0;
        latched_NaR_i <= 0;
        latched_sow_i <= 0;
        latched_eow_i <= 0;
        latched_fraction <= 0;
        latched_scale <= 0;
    end
    else begin
       if ( receive_en & ~process_en ) begin
           latched <= 1;
           latched_NaR_i <= NaR_i;
           latched_zero_i <= zero_i;
           latched_sow_i <= sow_i;
           latched_eow_i <= eow_i;
           latched_sign_i <= sign_i;
           latched_fraction <= fraction;
           latched_scale <= scale;
       end
       else if ( process_en ) begin
           latched <= 0;
       end
       rtr_o_int <= process_en;
    end
end
assign rtr_o = rtr_o_int;

//     ____  _            ___          
//    / __ \(_)___  ___  / (_)___  ___ 
//   / /_/ / / __ \/ _ \/ / / __ \/ _ \
//  / ____/ / /_/ /  __/ / / / / /  __/
// /_/   /_/ .___/\___/_/_/_/ /_/\___/ 
//        /_/                          

// mux to select latched data if present
assign fraction_in = (latched)? latched_fraction : fraction;
assign scale_in    = (latched)? latched_scale    : scale;
assign sign_in     = (latched)? latched_sign_i   : sign_i;
assign NaR_in      = (latched)? latched_NaR_i    : NaR_i;
assign zero_in     = (latched)? latched_zero_i   : zero_i;
assign sow[0]      = (latched)? latched_sow_i    : sow_i;
assign eow[0]      = (latched)? latched_eow_i    : eow_i;

//    ___
//   <  /
//   / / 
//  / /  
// /_/   
      
// accept 1 datum if pipeline works and upstream module is able to provide or latched is present
assign stage_en[0] = process_en & ( receive_en | latched );
// clear first stage when pipeline works and upstream module is unable to provide data and no latched data present
assign stage_clr[0] = process_en & ( ~receive_en & ~latched );

logic signed [127:0] shift_register;
logic sign_r1;
logic [FRACTION_WIDTH:0] frac_hidden; // not -1 because of hidden bit
assign frac_hidden = {1'b1, fraction_in};

always_ff @( posedge clk or negedge rst_n ) begin
    if ( ~rst_n ) begin
         staged[0]   <= 0;
         sow[1]      <= 0;
         eow[1]      <= 0;
         shift_register <= 0;
         sign_r1 <= 0;
    end
    else begin
        if ( stage_en[0] ) begin
            staged[0] <= 1;
            sow[1]    <= sow[0];
            eow[1]    <= eow[0];
            // handle negative scale
            if (scale_in[SCALE_WIDTH-1]) begin
                shift_register <= (frac_hidden >> -(bpp_lsb + $signed(scale_in)) );
            end
            else begin
                shift_register <= (frac_hidden << (bpp_lsb + $signed(scale_in)) );
            end
            sign_r1 <= sign_in;
        end
        else if ( stage_clr[0] ) begin
            staged[0] <= 0;
        end
    end
end

//    ___ 
//   |__ \
//   __/ /
//  / __/ 
// /____/ 

assign stage_en[1]  =  staged[0] & process_en;
assign stage_clr[1] = ~staged[0] & process_en;

logic  signed [127:0] quire_r;

always_ff @( posedge clk or negedge rst_n ) begin
    if ( ~rst_n ) begin
         staged[1] <= 0;
         sow[2]    <= 0;
         eow[2]    <= 0;
         quire_r   <= 0;
    end
    else begin
        if ( stage_en[1] ) begin
            staged[1] <= 1;
            sow[2]    <= sow[1];
            eow[2]    <= eow[1];
            quire_r   <= (sign_r1) ?  quire_r - shift_register :
                                      quire_r + shift_register;
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

endmodule                       