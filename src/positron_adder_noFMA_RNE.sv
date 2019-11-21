`default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: LEDOUX Louis
// 
// Create Date: 12/11/2018 12:07:03 PM
// Design Name: 
// Module Name: positron
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
// A positron is a pipeline engine of 6 stages
//
// ----------------------------------------------------------------------------------------------------------
//                                                 
//
//                                                                               +---+ 
//                                                                               |   |
//                                                               +---------------| D |
//                                                               |               |   |
//         +--------+    +---+      +---+                        |  +---+        +---+
//         | WEIGHT |    |   | w[i] |   |                        |  |   |          ^
//         |  ROM   |--->| D |----->|   |                        +->|   |          |
//         |        |    |   |      |   |                           |   |          |
//         +----^---+    +---+      |   |   +---+    +---+          |   |        +---+         +---+
//                                  |   |   |   |    |   |  mult[i] | + | acc[i] |   | norm[i] |   | sigm[i] 
//                                  | * |---| N |--->| D |--------->|   |------->| N |-------->| S |-------->
//                                  |   |   |   |    |   |          |   |        |   |         |   |
//          +-------+    +---+      |   |   +---+    +---+          |   |        +---+         +---+
//          | DELAY |    |   | x[i] |   |                           |   | 
//  x[i]--->|       |--->| D |----->|   |                           +-^-+  
//          |       |    |   |      |   |                 
//          +---^---+    +---+      +-^-+                 
//
//                                                        
//
//         STAGE 1      STAGE 2    STAGE 3   STAGE 4 STAGE 5       STAGE 6       STAGE 7     STAGE 8
// -----------------------------------------------------------------------------------------------------------
//
// Description of stages :
//
//  Stage 1 : N clks (default 2)
//      Read weight corresponding to the i_th activation coming. ROM has delay
//      for hight throughput therefore the activation is also delayed 
//
//  Stage 2 : 0 clk (comb)
//      Extract part of a posit aka denormalisation
//
//  Stage 3 : 1 clk
//      Multiplication of denormalised posits, the result is denormalised
//      posit with twice fract bits, and +1 scale bits
//
//  Stage 4 : 0 clk (comb)
//      NO FMA so we round after mult and also allows to have same size bus
//      for adder
//
//  Stage 5 : 0 clk (comb)
//      Extract part of a posit aka denormalisation
//
//  Stage 6 : 0 clk (comb)
//      TODO(lledoux): clock this
//      accumulation performed with an adder
//
//  Stage 7 : 0 clk (comb)
//      Normalisation of Accumulation
//        - nearest : "round to nearest, tie to nearest even"
//
//  Stage 8 : 0 clk (comb)
//     perform basic fast sigmoid based on a shift
// --------------------------------------------------------------------------------------------

import posit_defines::*;

module positron_adder_noFMA_RNE#
(
    parameter integer POSIT_WIDTH = 8,
    parameter integer POSIT_ES = 0,
    parameter WEIGHTS_BASE_PATH = "",
    parameter WEIGHTS_FILE_NUMBER = "",
    parameter integer NB_UPSTREAM_POSITRON = 784,
    parameter integer LOG_NB_ACCUM = 15
)
(
    // System signals
    input  wire clk,
    input  wire rst_n,
    
    // SLAVE SIDE
    
    // control signals
    output logic rtr_o,
    input  wire  rts_i,
    input  wire  sow_i,
    input  wire  eow_i,
    
    input  wire [POSIT_WIDTH-1:0] posit_i,
    
    
    // MASTER SIDE
        
    // control signals
    input  wire  rtr_i,
    output logic rts_o,
    output logic eow_o,
    
    output logic [POSIT_WIDTH-1:0] posit_o 
);

// local parameters
localparam integer DELAY_READ_ROM = 2;
localparam integer FRACTION_WIDTH_BEFORE_MULT = get_fraction_width(POSIT_WIDTH, POSIT_ES, NORMAL);
localparam integer SCALE_WIDTH_BEFORE_MULT    = get_scale_width(POSIT_WIDTH, POSIT_ES, NORMAL); 
localparam integer FRACTION_WIDTH_AFTER_MULT  = get_fraction_width(POSIT_WIDTH, POSIT_ES, AMULT);
localparam integer SCALE_WIDTH_AFTER_MULT     = get_scale_width(POSIT_WIDTH, POSIT_ES, AMULT);
localparam integer FRACTION_WIDTH_AFTER_ADD   = get_fraction_width(POSIT_WIDTH, POSIT_ES, AADD);
localparam integer SCALE_WIDTH_AFTER_ADD      = get_scale_width(POSIT_WIDTH, POSIT_ES, AADD);
localparam rounding_type ROUNDING_MODE        = RNTE;
// signals

// weights rom
logic weights_rom_ready;
logic weights_rom_valid;
logic weights_rom_eow_o;
logic weights_rom_sow_o;
logic [log2(NB_UPSTREAM_POSITRON)-1:0] weights_rom_addr;
logic [POSIT_WIDTH-1:0] weights_rom_posit_o;

// pipeline delay
logic pipeline_delay_ready;
logic [POSIT_WIDTH-1:0] pipeline_delay_posit_o;
logic pipeline_delay_valid;
logic pipeline_delay_eow_o;
logic pipeline_delay_sow_o;

// extraction w/o interface
logic sign_input, sign_weight;
logic NaR_input, NaR_weight;
logic zero_input, zero_weight;
logic [SCALE_WIDTH_BEFORE_MULT-1:0] scale_input, scale_weight;
logic [FRACTION_WIDTH_BEFORE_MULT-1:0] fraction_input, fraction_weight;

// posit mult w/o interface
logic posit_mult_ready;
logic posit_mult_valid;
logic posit_mult_eow_o;
logic posit_mult_sow_o;
logic [FRACTION_WIDTH_AFTER_MULT-1:0] posit_mult_fraction_o;
logic [SCALE_WIDTH_AFTER_MULT-1:0] posit_mult_scale_o;
logic posit_mult_NaR_o;  
logic posit_mult_sign_o;
logic posit_mult_zero_o;

// mult norm and rounding RNE
pd_control_if #(
    .POSIT_WIDTH ( POSIT_WIDTH ),
    .POSIT_ES    ( POSIT_ES    ),
    .PD_TYPE     ( AMULT       )
) prod_rne_I();
logic [POSIT_WIDTH-1:0] prod_rne;

// extracted components after rounding 
pd_control_if #(
    .POSIT_WIDTH ( POSIT_WIDTH ),
    .POSIT_ES    ( POSIT_ES    ),
    .PD_TYPE     ( NORMAL      )
) extracted_mult_rne_I();

// extracted components of accum
pd_control_if #(
    .POSIT_WIDTH ( POSIT_WIDTH ),
    .POSIT_ES    ( POSIT_ES    ),
    .PD_TYPE     ( NORMAL      )
) extracted_accum_I();

// addition
pd_control_if #(
    .POSIT_WIDTH ( POSIT_WIDTH ),
    .POSIT_ES    ( POSIT_ES    ),
    .PD_TYPE     ( AADD        )
) accumulation_I();


// normalization and rounding of accum
// logic [POSIT_WIDTH-1:0] vdp;

// sigmoid
logic [POSIT_WIDTH-1:0] sigmoid;

//    _____ __               
//   / ___// /___ __   _____ 
//   \__ \/ / __ `/ | / / _ \
//  ___/ / / /_/ /| |/ /  __/
// /____/_/\__,_/ |___/\___/ 

assign rtr_o = weights_rom_ready & pipeline_delay_ready;


//  _       __     _       __    __          ____  ____  __  ___
// | |     / /__  (_)___ _/ /_  / /______   / __ \/ __ \/  |/  /
// | | /| / / _ \/ / __ `/ __ \/ __/ ___/  / /_/ / / / / /|_/ / 
// | |/ |/ /  __/ / /_/ / / / / /_(__  )  / _, _/ /_/ / /  / /  
// |__/|__/\___/_/\__, /_/ /_/\__/____/  /_/ |_|\____/_/  /_/   
//               /____/                                         

// address generation
always_ff @( posedge clk or negedge rst_n ) begin
    if ( ~rst_n ) begin
        weights_rom_addr <= 0;
    end
    else if ( rts_i &  weights_rom_ready ) begin
        if ( sow_i ) begin
            weights_rom_addr <= 1;
        end
        else if ( eow_i ) begin
            weights_rom_addr <= 0;
        end
        else begin
            weights_rom_addr <= weights_rom_addr + 1;
        end
    end
end


// ROM instanciation
weights_ROM #
(
    .DELAY       ( DELAY_READ_ROM                           ),
    .PATH        ( {WEIGHTS_BASE_PATH, WEIGHTS_FILE_NUMBER} ),
    .POSIT_WIDTH ( POSIT_WIDTH                              ),
    .NB_WEIGHTS  ( NB_UPSTREAM_POSITRON                     )
)
weights_ROM_inst (
   // System signals
   .clk       ( clk                 ),
   .rst_n     ( rst_n               ),
   
   // SLAVE SIDE
   
   // control signals
   .rtr_o     ( weights_rom_ready   ),
   .rts_i     ( rts_i               ),
   .sow_i     ( sow_i               ),
   .eow_i     ( eow_i               ),
   // addr
   .address_i ( weights_rom_addr    ),
   
   // MASTER SIDE
           
   // control signals
   .rtr_i     ( posit_mult_ready    ),
   .rts_o     ( weights_rom_valid   ),
   .eow_o     ( weights_rom_eow_o   ),
   .sow_o     ( weights_rom_sow_o   ),
   // posit out
   .posit_o   ( weights_rom_posit_o )
);


//     ____       __               _____   __
//    / __ \___  / /___ ___  __   /  _/ | / /
//   / / / / _ \/ / __ `/ / / /   / //  |/ / 
//  / /_/ /  __/ / /_/ / /_/ /  _/ // /|  /  
// /_____/\___/_/\__,_/\__, /  /___/_/ |_/   
//                    /____/                 

pipeline #
(
    .DELAY      ( DELAY_READ_ROM         ),
    .DATA_TYPE  ( logic[POSIT_WIDTH-1:0] )
)
pipeline_inst(
    // System signals
    .clk    ( clk                    ),
    .rst_n  ( rst_n                  ),
    
    // SLAVE SIDE
    
    // control signals
   .rtr_o   ( pipeline_delay_ready   ),
   .rts_i   ( rts_i                  ),
   .sow_i   ( sow_i                  ),
   .eow_i   ( eow_i                  ),
    // data in
    .data_i ( posit_i                ),
    
    // MASTER SIDE
            
    // control signals
    .rtr_i  ( posit_mult_ready       ),
    .rts_o  ( pipeline_delay_valid   ),
    .eow_o  ( pipeline_delay_eow_o   ),
    .sow_o  ( pipeline_delay_sow_o   ),
    // data out
    .data_o ( pipeline_delay_posit_o )
);

//     ____             _ __     ______     __                  __ 
//    / __ \____  _____(_) /_   / ____/  __/ /__________ ______/ /_
//   / /_/ / __ \/ ___/ / __/  / __/ | |/_/ __/ ___/ __ `/ ___/ __/
//  / ____/ /_/ (__  ) / /_   / /____>  </ /_/ /  / /_/ / /__/ /_  
// /_/    \____/____/_/\__/  /_____/_/|_|\__/_/   \__,_/\___/\__/  

// extract weight
posit_data_extract #(
    .POSIT_WIDTH ( POSIT_WIDTH ),
    .POSIT_ES    ( POSIT_ES    )
)
extract_weight(

    // in
    .posit_word_i ( weights_rom_posit_o ),

    // out
    .sign         ( sign_weight         ),
    .inf          ( NaR_weight          ),
    .zero         ( zero_weight         ),
    .scale        ( scale_weight        ),
    .fraction     ( fraction_weight     )
);

// extract input positron delayed
posit_data_extract #(
    .POSIT_WIDTH ( POSIT_WIDTH ),
    .POSIT_ES    ( POSIT_ES    )
)
extract_input_positron(

    // in
    .posit_word_i ( pipeline_delay_posit_o ),

    // out
    .sign         ( sign_input             ),
    .inf          ( NaR_input              ),
    .zero         ( zero_input             ),
    .scale        ( scale_input            ),
    .fraction     ( fraction_input         )
);

//     ____             _ __     __  ___      ____ 
//    / __ \____  _____(_) /_   /  |/  /_  __/ / /_
//   / /_/ / __ \/ ___/ / __/  / /|_/ / / / / / __/
//  / ____/ /_/ (__  ) / /_   / /  / / /_/ / / /_  
// /_/    \____/____/_/\__/  /_/  /_/\__,_/_/\__/  

posit_mult #
(
    .POSIT_WIDTH ( POSIT_WIDTH ),
    .POSIT_ES    ( POSIT_ES    )
)
posit_mult_inst (

    // System signals
    .clk   ( clk                         ),
    .rst_n ( rst_n                       ),
    
    // SLAVE SIDE
    
    // control signals
    .rtr_o ( posit_mult_ready            ),
    .rts_i ( weights_rom_valid           ),
    .sow_i ( weights_rom_sow_o           ),
    .eow_i ( weights_rom_eow_o           ),
    
    // input posit 1
    .fraction_i1 ( fraction_input        ),
    .scale_i1    ( scale_input           ),
    .NaR_i1      ( NaR_input             ),
    .zero_i1     ( zero_input            ),
    .sign_i1     ( sign_input            ),
   
    // input posit 2
    .fraction_i2 ( fraction_weight       ),
    .scale_i2    ( scale_weight          ),
    .NaR_i2      ( NaR_weight            ),
    .zero_i2     ( zero_weight           ),
    .sign_i2     ( sign_weight           ),
    
    // MASTER SIDE
    
    // control signals
    .rtr_i       ( extracted_mult_rne_I.rtr ),
    .rts_o       ( posit_mult_valid      ),
    .eow_o       ( posit_mult_eow_o      ),
    .sow_o       ( posit_mult_sow_o      ),
    
    // output posit
    .fraction_o  ( posit_mult_fraction_o ), 
    .scale_o     ( posit_mult_scale_o    ),
    .NaR_o       ( posit_mult_NaR_o      ),
    .sign_o      ( posit_mult_sign_o     ),
    .zero_o      ( posit_mult_zero_o     )

);

//     __  ___      ____     ____  _   ________
//    /  |/  /_  __/ / /_   / __ \/ | / / ____/
//   / /|_/ / / / / / __/  / /_/ /  |/ / __/   
//  / /  / / /_/ / / /_   / _, _/ /|  / /___   
// /_/  /_/\__,_/_/\__/  /_/ |_/_/ |_/_____/   

// we round after the mult, so nothing is "fused"

// build interface with components
assign prod_rne_I.scale    = posit_mult_scale_o;
assign prod_rne_I.fraction = posit_mult_fraction_o;
assign prod_rne_I.NaR      = posit_mult_NaR_o;
assign prod_rne_I.sign     = posit_mult_sign_o;
assign prod_rne_I.zero     = posit_mult_zero_o;
assign prod_rne_I.guard    = 1'b0;
assign prod_rne_I.round    = 1'b0;
assign prod_rne_I.sticky   = 1'b0;

// rounding
posit_normalize_I # ( 
    .POSIT_WIDTH   ( POSIT_WIDTH   ),
    .POSIT_ES      ( POSIT_ES      ),
    .PD_TYPE       ( AMULT         ),
    .ROUNDING_MODE ( ROUNDING_MODE )
) mult_normalizer (
    .denormalized ( prod_rne_I ),
    .posit_word_o ( prod_rne   )
);

//     ______     __                  __ 
//    / ____/  __/ /__________ ______/ /_
//   / __/ | |/_/ __/ ___/ __ `/ ___/ __/
//  / /____>  </ /_/ /  / /_/ / /__/ /_  
// /_____/_/|_|\__/_/   \__,_/\___/\__/  

posit_denormalize_I # ( 
    .POSIT_WIDTH ( POSIT_WIDTH ),
    .POSIT_ES    ( POSIT_ES    )
) mult_denormalizer (
    .posit_word_i ( prod_rne             ),
    .denormalized ( extracted_mult_rne_I )
);

//     ___       __    __         
//    /   | ____/ /___/ /__  _____
//   / /| |/ __  / __  / _ \/ ___/
//  / ___ / /_/ / /_/ /  __/ /    
// /_/  |_\__,_/\__,_/\___/_/     

assign extracted_mult_rne_I.rts = posit_mult_valid;
assign extracted_mult_rne_I.sow = posit_mult_sow_o;
assign extracted_mult_rne_I.eow = posit_mult_eow_o;
logic accum_rts_o;
logic accum_sow_o;
logic accum_eow_o;
logic [POSIT_WIDTH-1:0] accum_data_o;
logic accum_rtr_i;
posit_accum_rounding #( 
    .POSIT_WIDTH   ( POSIT_WIDTH   ),
    .POSIT_ES      ( POSIT_ES      ),
    .ROUNDING_MODE ( ROUNDING_MODE )
) posit_adder_inst (
    .clk     ( clk                  ),
    .rst_n   ( rst_n                ),
    .operand ( extracted_mult_rne_I ),
    .rts_o   ( accum_rts_o  ),
    .sow_o   ( accum_sow_o  ),
    .eow_o   ( accum_eow_o  ),
    .data_o  ( accum_data_o ),
    .rtr_i   ( accum_rtr_i  )
);

// logic [FRACTION_WIDTH_AFTER_ADD+SCALE_WIDTH_AFTER_ADD+6-1:0] in_ff;
// assign in_ff = {
//     accumulation_I.scale,
//     accumulation_I.fraction,
//     accumulation_I.NaR,
//     accumulation_I.sign,
//     accumulation_I.zero,
//     accumulation_I.guard,
//     accumulation_I.round,
//     accumulation_I.sticky
// };
// logic [FRACTION_WIDTH_AFTER_ADD+SCALE_WIDTH_AFTER_ADD+6-1:0] out_ff;
// pipeline #
// (
//     .DELAY      ( 1                       ),
//     .DATA_TYPE  ( logic [FRACTION_WIDTH_AFTER_ADD+SCALE_WIDTH_AFTER_ADD+6-1:0] )
// )
// add_accum_ff_inst(
//     // System signals
//     .clk    ( clk                    ),
//     .rst_n  ( rst_n                  ),
//     
//     // SLAVE SIDE
//     
//     // control signals
//    .rtr_o   ( add_ff_rtr_o     ),
//    .rts_i   ( posit_mult_valid ),
//    .sow_i   ( posit_mult_sow_o ),
//    .eow_i   ( posit_mult_eow_o ),
//     // data in
//     .data_i ( in_ff     ),
//     
//     // MASTER SIDE
//             
//     // control signals
//     .rtr_i  ( rtr_i        ),
//     .rts_o  ( add_ff_rts_o ),
//     .eow_o  ( add_ff_eow_o ),
//     .sow_o  ( add_ff_sow_o ),
//     // data out
//     .data_o ( out_ff       )
// );
// 
// assign accumulation_ff_I.scale    = out_ff[($bits(out_ff)-1)-:SCALE_WIDTH_AFTER_ADD];
// assign accumulation_ff_I.fraction = out_ff[6+:FRACTION_WIDTH_AFTER_ADD];
// assign accumulation_ff_I.NaR      = out_ff[5];
// assign accumulation_ff_I.sign     = out_ff[4];
// assign accumulation_ff_I.zero     = out_ff[3];
// assign accumulation_ff_I.guard    = out_ff[2];
// assign accumulation_ff_I.round    = out_ff[1];
// assign accumulation_ff_I.sticky   = out_ff[0];
 
//     ___       __    __   ____  _   ________
//    /   | ____/ /___/ /  / __ \/ | / / ____/
//   / /| |/ __  / __  /  / /_/ /  |/ / __/   
//  / ___ / /_/ / /_/ /  / _, _/ /|  / /___   
// /_/  |_\__,_/\__,_/  /_/ |_/_/ |_/_____/   

// rounding
// posit_normalize_I # ( 
//     .POSIT_WIDTH   ( POSIT_WIDTH ),
//     .POSIT_ES      ( POSIT_ES    ),
//     .PD_TYPE       ( AADD        ),
//     .ROUNDING_MODE ( RNTE        )
// ) add_normalizer (
//     .denormalized ( accumulation_I    ),
//     .posit_word_o ( vdp               )
// );
// 
// //     ______     __                  __ 
// //    / ____/  __/ /__________ ______/ /_
// //   / __/ | |/_/ __/ ___/ __ `/ ___/ __/
// //  / /____>  </ /_/ /  / /_/ / /__/ /_  
// // /_____/_/|_|\__/_/   \__,_/\___/\__/  
// 
// logic [POSIT_WIDTH-1:0]vdp_rst;
// assign vdp_rst = (posit_mult_sow_o) ? 0 : vdp;
// posit_denormalize_I # ( 
//     .POSIT_WIDTH ( POSIT_WIDTH ),
//     .POSIT_ES    ( POSIT_ES    )
// ) add_denormalizer (
//     .posit_word_i ( vdp_rst           ),
//     .denormalized ( extracted_accum_I )
// );

//    _____ _                       _     __
//   / ___/(_)___ _____ ___  ____  (_)___/ /
//   \__ \/ / __ `/ __ `__ \/ __ \/ / __  / 
//  ___/ / / /_/ / / / / / / /_/ / / /_/ /  
// /____/_/\__, /_/ /_/ /_/\____/_/\__,_/   
//        /____/                            

sigmoid #
(
    .POSIT_WIDTH ( POSIT_WIDTH )
)
sigmoid_inst (
    .posit_i ( accum_data_o  ),
    .posit_o ( sigmoid )
);

//     __  ___           __           
//    /  |/  /___ ______/ /____  _____
//   / /|_/ / __ `/ ___/ __/ _ \/ ___/
//  / /  / / /_/ (__  ) /_/  __/ /    
// /_/  /_/\__,_/____/\__/\___/_/     

assign accum_rtr_i = rtr_i;
assign rts_o       = accum_eow_o & accum_rts_o;
assign eow_o       = accum_eow_o;
assign posit_o     = sigmoid;
                                   
endmodule
`default_nettype wire
