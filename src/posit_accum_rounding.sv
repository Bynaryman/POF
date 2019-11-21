`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: LEDOUX Louis
// 
// Create Date: 19/11/2019 09:51:52 AM
// Design Name: 
// Module Name: posit_accum_rounding
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
//    version of the adder with 3 stages
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

import posit_defines::*;

module posit_accum_rounding # (
    parameter integer POSIT_WIDTH = 8,
    parameter integer POSIT_ES    = 0,
    parameter rounding_type ROUNDING_MODE = RNTE
)
(
    // System
    input wire clk,
    input wire rst_n,

    // SLAVE SIDE
    pd_control_if.slave operand,
   
    
    // MASTER SIDE
    output wire rts_o,
    output wire sow_o,
    output wire eow_o,
    output logic [POSIT_WIDTH-1:0] data_o,
    input wire rtr_i
);

if ( (POSIT_WIDTH - POSIT_ES -3 ) < 1) $fatal("adder for posit w/o fraction still under devlopment");

localparam integer scale_width_b    = get_scale_width(POSIT_WIDTH, POSIT_ES, NORMAL);
localparam integer fraction_width_b = get_fraction_width(POSIT_WIDTH, POSIT_ES, NORMAL);
localparam integer scale_width_a    = get_scale_width(POSIT_WIDTH, POSIT_ES, AADD);
localparam integer fraction_width_a = get_fraction_width(POSIT_WIDTH, POSIT_ES, AADD);
localparam integer MAX_SCALE        = $clog2(2**(2**POSIT_ES)**(POSIT_WIDTH-2));

// signal state control
logic process_en;
logic receive_en;
logic rtr_o_int;
logic rts_o_int;

// signal latched inputs
// control
logic latched;
logic latched_sow_i;
logic latched_eow_i;

// posit summand
logic signed [scale_width_b-1:0]  latched_scale_i1;
logic [fraction_width_b-1:0] latched_fraction_i1;
logic latched_zero_i1;
logic latched_NaR_i1;
logic latched_sign_i1;
logic latched_guard_i1;
logic latched_round_i1;
logic latched_sticky_i1;
logic signed [scale_width_b-1:0]  scale_in1;
logic [fraction_width_b-1:0] fraction_in1;
logic zero_in1;
logic NaR_in1;
logic sign_in1;
logic guard_in1;
logic round_in1;
logic sticky_in1;

// posit 2
logic signed [scale_width_b-1:0] scale_accum;
logic [fraction_width_b-1:0] fraction_accum;
logic zero_accum;
logic NaR_accum;
logic sign_accum;
logic guard_accum;
logic round_accum;
logic sticky_accum;


// pipeline control signals
localparam integer PIPELEN = 3;
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
assign receive_en = operand.rts & rtr_o_int;

//    _____ __               
//   / ___// /___ __   _____ 
//   \__ \/ / __ `/ | / / _ \
//  ___/ / / /_/ /| |/ /  __/
// /____/_/\__,_/ |___/\___/ 

always_ff @( posedge clk or negedge rst_n ) begin
    if ( ~rst_n ) begin
        latched             <= 0;
        latched_sow_i       <= 0;
        latched_eow_i       <= 0;
        latched_zero_i1     <= 0;
        latched_sign_i1     <= 0;
        latched_NaR_i1      <= 0;
        latched_fraction_i1 <= 0;
        latched_scale_i1    <= 0;
        latched_guard_i1    <= 0;
        latched_round_i1    <= 0;
        latched_sticky_i1   <= 0;
    end
    else begin
       if ( receive_en & ~process_en ) begin
           latched             <= 1;
           latched_sow_i       <= operand.sow; 
           latched_eow_i       <= operand.eow;
           latched_fraction_i1 <= operand.fraction;
           latched_scale_i1    <= operand.scale;
           latched_NaR_i1      <= operand.NaR;
           latched_zero_i1     <= operand.zero;
           latched_sign_i1     <= operand.sign;
           latched_guard_i1    <= operand.guard;
           latched_round_i1    <= operand.round;
           latched_sticky_i1   <= operand.sticky;
       end
       else if ( process_en ) begin
           latched <= 0;
       end
       rtr_o_int <= process_en;
    end
end
assign operand.rtr = rtr_o_int;

//     ____  _            ___          
//    / __ \(_)___  ___  / (_)___  ___ 
//   / /_/ / / __ \/ _ \/ / / __ \/ _ \
//  / ____/ / /_/ /  __/ / / / / /  __/
// /_/   /_/ .___/\___/_/_/_/ /_/\___/ 
//        /_/                          

// mux to select latched data if present
assign sow[0]       = (latched)? latched_sow_i       : operand.sow; 
assign eow[0]       = (latched)? latched_eow_i       : operand.eow;
assign fraction_in1 = (latched)? latched_fraction_i1 : operand.fraction;
assign scale_in1    = (latched)? latched_scale_i1    : operand.scale;
assign sign_in1     = (latched)? latched_sign_i1     : operand.sign;
assign NaR_in1      = (latched)? latched_NaR_i1      : operand.NaR;
assign zero_in1     = (latched)? latched_zero_i1     : operand.zero;
assign guard_in1    = (latched)? latched_guard_i1    : operand.guard;
assign round_in1    = (latched)? latched_round_i1    : operand.round;
assign sticky_in1   = (latched)? latched_sticky_i1   : operand.sticky;

//    ___
//   <  /
//   / / 
//  / /  
// /_/   
      
// accept 1 datum if pipeline works and upstream module is able to provide or latched is present
assign stage_en[0] = process_en & ( receive_en | latched );
// clear first stage when pipeline works and upstream module is unable to provide data and no latched data present
assign stage_clr[0] = process_en & ( ~receive_en & ~latched );


// signals_pp1
// summand signals
logic signed [scale_width_b-1:0]  scale_in1_pp1;
logic [fraction_width_b-1:0] fraction_in1_pp1;
logic zero_in1_pp1;
logic NaR_in1_pp1;
logic sign_in1_pp1;
logic guard_in1_pp1;
logic round_in1_pp1;
logic sticky_in1_pp1;

always_ff @( posedge clk or negedge rst_n ) begin
    if ( ~rst_n ) begin
         staged[0]        <= 0;
         sow[1]           <= 0;
         eow[1]           <= 0;
         fraction_in1_pp1 <= 0; 
         scale_in1_pp1    <= 0; 
         sign_in1_pp1     <= 0; 
         NaR_in1_pp1      <= 0; 
         zero_in1_pp1     <= 0; 
         guard_in1_pp1    <= 0; 
         round_in1_pp1    <= 0; 
         sticky_in1_pp1   <= 0; 
    end
    else begin
        if ( stage_en[0] ) begin
            staged[0]        <= 1;
            sow[1]           <= sow[0];
            eow[1]           <= eow[0];
            fraction_in1_pp1 <= fraction_in1; 
            scale_in1_pp1    <= scale_in1; 
            sign_in1_pp1     <= sign_in1; 
            NaR_in1_pp1      <= NaR_in1; 
            zero_in1_pp1     <= zero_in1; 
            guard_in1_pp1    <= guard_in1; 
            round_in1_pp1    <= round_in1; 
            sticky_in1_pp1   <= sticky_in1; 
        end
        else if ( stage_clr[0] ) begin
            staged[0] <= 0;
        end
    end
end

always_comb begin
    if ( ~rst_n | sow[1] ) begin
        fraction_accum   = 0; 
        scale_accum      = 0; 
        sign_accum       = 0; 
        NaR_accum        = 0; 
        zero_accum       = 1; 
        guard_accum      = 0; 
        round_accum      = 0; 
        sticky_accum     = 0; 
    end
    else begin
        fraction_accum   = accum_if.fraction ; 
        scale_accum      = accum_if.scale    ; 
        sign_accum       = accum_if.sign     ; 
        NaR_accum        = accum_if.NaR      ; 
        zero_accum       = accum_if.zero     ; 
        guard_accum      = accum_if.guard    ; 
        round_accum      = accum_if.round    ; 
        sticky_accum     = accum_if.sticky   ; 
    end
end

// part 1
// comparison of inputs and muxes to determine the small(s) and large(l) operand 
logic op1_gt_op2;
logic signed [scale_width_b-1:0] sop_scale, lop_scale;
logic [fraction_width_b-1:0] sop_fraction, lop_fraction;
logic lzero, szero;
logic lsign, ssign;
logic saturation;
always_comb begin
    if (scale_in1_pp1 > scale_accum) begin
        op1_gt_op2 = 1'b1;
    end 
    else if (scale_in1_pp1 < scale_accum) begin
        op1_gt_op2 = 1'b0;
    end
    else begin  // scales are equal, compare mantissas
        op1_gt_op2 = fraction_in1_pp1 >= fraction_accum;
    end
end
assign saturation = (scale_in1_pp1 == MAX_SCALE) & (scale_accum == MAX_SCALE); // if both exp are at max, they should clamp
always_comb begin
    if (op1_gt_op2) begin
        sop_scale = scale_accum;
        lop_scale = scale_in1_pp1;
        sop_fraction = fraction_accum;
        lop_fraction = fraction_in1_pp1;
        lzero = zero_in1_pp1;
        szero = zero_accum;
        lsign = sign_in1_pp1;
        ssign = sign_accum;
    end else begin
        sop_scale = scale_in1_pp1;
        lop_scale = scale_accum;
        sop_fraction = fraction_in1_pp1;
        lop_fraction = fraction_accum;
        lzero = zero_accum;
        szero = zero_in1_pp1;
        lsign = sign_accum;
        ssign = sign_in1_pp1;
    end
end

// part 2
// compute the shift amount to align significands based on scale diff
// 1 bit more than scale in for overflow cases
logic signed [scale_width_b:0] shift_amount;
assign shift_amount = lop_scale - sop_scale;

// part 3
// shift to right the sop by shift_amounts
// aligned fraction is +3 (GRS) + 1(hidden bit) bits
logic [fraction_width_b-1+3+1:0] sop_fraction_aligned_grs;
sticky_shifter #(
    .DATA_WIDTH ( fraction_width_b+1   ),
    .MAX_STAGES ( 2**(scale_width_b)-1 )
) sticky_shifter_inst (
    .a ( {~szero, sop_fraction}   ),
    .b ( shift_amount             ),
    .c ( sop_fraction_aligned_grs )
);


//    ___ 
//   |__ \
//   __/ /
//  / __/ 
// /____/ 

assign stage_en[1]  =  staged[0] & process_en;
assign stage_clr[1] = ~staged[0] & process_en;

// signals_pp2
logic [fraction_width_b-1+3+1:0] sop_fraction_aligned_grs_pp2;
logic op_pp2;
logic [fraction_width_b-1+3+1:0] lop_pp2;
logic signed [scale_width_b-1:0] lop_scale_pp2;
logic saturation_pp2;
logic lsign_pp2;
logic NaR_in1_pp2;
logic NaR_in2_pp2;
logic zero_in1_pp2;
logic zero_in2_pp2;
always_ff @( posedge clk or negedge rst_n ) begin
    if ( ~rst_n ) begin
         staged[1]   <= 0;
         sow[2]      <= 0;
         eow[2]      <= 0;
         sop_fraction_aligned_grs_pp2 <= 0;
         op_pp2 <= 0;
         lop_pp2 <= 0;
         lop_scale_pp2 <= 0;
         saturation_pp2 <= 0;
         lsign_pp2 <= 0;
         NaR_in1_pp2 <= 0;
         NaR_in2_pp2 <= 0;
         zero_in1_pp2 <= 0;
         zero_in2_pp2 <= 0;
    end
    else begin
        if ( stage_en[1] ) begin
            staged[1] <= 1;
            sow[2]    <= sow[1];
            eow[2]    <= eow[1];
            sop_fraction_aligned_grs_pp2 <= sop_fraction_aligned_grs;
            op_pp2 <= sign_in1_pp1 ~^ sign_accum;
            lop_pp2 <= {~lzero, lop_fraction, {3'b0}};
            lop_scale_pp2 <= lop_scale;
            saturation_pp2 <= saturation;
            lsign_pp2 <= lsign;
            NaR_in1_pp2 <= NaR_in1_pp1;
            NaR_in2_pp2 <= NaR_accum;
            zero_in1_pp2 <= zero_in1_pp1;
            zero_in2_pp2 <= zero_accum;
        end
        else if ( stage_clr[1] ) begin
            staged[1] <= 0;
        end
    end
end

// part 4
// perform the operation depending on signs
logic [fraction_width_b-1+3+1:0] sop, lop;
logic [fraction_width_b-1+3+1+1:0] tmp_op_res; // +5 bits : grs hidden overflow
assign lop = lop_pp2;
assign sop = sop_fraction_aligned_grs_pp2;
assign tmp_op_res = (op_pp2)?  lop + sop : lop - sop;

// part 5
// detect overflow of mantissa eventually adjust scale and mantissa
logic mantissa_overflow;
assign mantissa_overflow = tmp_op_res[fraction_width_b-1+3+1+1];


// part 6
//  renormalize mantissa if necessary
logic [fraction_width_b-1+3+1+1:0] normalized_op_res;
logic [$clog2($bits(normalized_op_res))-1:0] hidden_pos;
LOD_N #(
    .C_N($bits(normalized_op_res))
) hidden_bit_counter(
    .in(tmp_op_res),
    .out(hidden_pos)
);

logic signed [scale_width_b-1:0] final_scale;
assign final_scale = (mantissa_overflow)? $signed(lop_scale_pp2) + $unsigned(~saturation_pp2) : (~tmp_op_res[fraction_width_b-1+3+1]?  ($signed(lop_scale_pp2) - $signed(hidden_pos) + $signed(1'b1)) : $signed(lop_scale_pp2));

//assign normalized_matissa_OVF = (mantissa_overflow)? tmp_op_res  : tmp_op_res << 1;
assign normalized_op_res = tmp_op_res << (hidden_pos + 1);

//     _   __      ____ 
//    / | / / __  / __ \
//   /  |/ /_/ /_/ / / /
//  / /|  /_  __/ /_/ / 
// /_/ |_/ /_/ /_____/  
                     
logic [POSIT_WIDTH-1:0] posit_normalized;
pd_control_if #( 
    .POSIT_WIDTH ( POSIT_WIDTH ),
    .POSIT_ES    ( POSIT_ES    ),
    .PD_TYPE     ( AADD        )
) normalized();

pd_control_if #( 
    .POSIT_WIDTH ( POSIT_WIDTH ),
    .POSIT_ES    ( POSIT_ES    ),
    .PD_TYPE     ( AADD        )
) accum_if();

assign normalized.guard  = normalized_op_res[$bits(normalized_op_res)-fraction_width_b-1];
assign normalized.round  = normalized_op_res[$bits(normalized_op_res)-fraction_width_b-2];
assign normalized.sticky = |normalized_op_res[$bits(normalized_op_res)-fraction_width_b-3:0];
assign normalized.NaR = NaR_in1_pp2 | NaR_in2_pp2;
assign normalized.sign = lsign_pp2;
assign normalized.scale = final_scale;
assign normalized.fraction = normalized_op_res[($bits(normalized_op_res)-1)-:fraction_width_b];
assign normalized.zero = (zero_in1_pp2 & zero_in2_pp2) | ~|tmp_op_res; //(hidden_pos >= $bits(sop_fraction_aligned_grs));

posit_normalize_I # ( 
    .POSIT_WIDTH   ( POSIT_WIDTH   ),
    .POSIT_ES      ( POSIT_ES      ),
    .PD_TYPE       ( AADD          ),
    .ROUNDING_MODE ( ROUNDING_MODE )
) opC_normalizer (
    .denormalized ( normalized       ),
    .posit_word_o ( posit_normalized )
);

posit_denormalize_I # ( 
    .POSIT_WIDTH ( POSIT_WIDTH ),
    .POSIT_ES    ( POSIT_ES    )
) opB_denormalizer (
    .posit_word_i ( posit_normalized ),
    .denormalized ( accum_if         )
);

//    _____
//   |__  /
//    /_ <
//  ___/ /
// /____/

assign stage_en[2]  =  staged[1] & process_en;
assign stage_clr[2] = ~staged[1] & process_en;

// signals_pp3
logic [POSIT_WIDTH-1:0] posit_normalized_pp3;
always_ff @( posedge clk or negedge rst_n ) begin
    if ( ~rst_n ) begin
         staged[2]            <= 0;
         sow[3]               <= 0;
         eow[3]               <= 0;
         posit_normalized_pp3 <= 0;
    end
    else begin
        if ( stage_en[2] ) begin
            staged[2]            <= 1;
            sow[3]               <= sow[2];
            eow[3]               <= eow[2];
            posit_normalized_pp3 <= posit_normalized;
        end
        else if ( stage_clr[2] ) begin
            staged[2] <= 0;
        end
    end
end


//                          __           
//    ____ ___  ____ ______/ /____  _____
//   / __ `__ \/ __ `/ ___/ __/ _ \/ ___/
//  / / / / / / /_/ (__  ) /_/  __/ /    
// /_/ /_/ /_/\__,_/____/\__/\___/_/     

assign rts_o_int = staged[PIPELEN-1];
assign rts_o     = rts_o_int;
assign eow_o     = eow[PIPELEN];
assign sow_o     = sow[PIPELEN];
assign data_o    = posit_normalized_pp3;
endmodule

`default_nettype wire
