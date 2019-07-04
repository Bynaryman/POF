`timescale 1ns / 1ps
`default_nettype none
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
// Alternative version of positron that does not store weight in local ROM,
// but receives as input. 5 Stages pipeline engine
//
// ---------------------------------------------------------------------------------------------
//
//                     +---+      +---+         +---+
//                w[i] |   | w[i] |   |         |   |
//              +----->|   |----->|   |         |   |
//              |      |   |      |   |         |   |
//              |      +---+      |   |         |   |        +---+         +---+
//  {w[i],x[i]} |                 |   | mult[i] |   | acc[i] |   | norm[i] |   | sigm[i] 
// -------------+                 |   |-------->|   |------->|   |-------->|   |-------->
//              |                 |   |         |   |        |   |         |   |
//              |      +---+      |   |         |   |        +---+         +---+
//              | x[i] |   | x[i] |   |         |   |
//              +----->|   |----->|   |         |   |
//                     |   |      |   |         |   |
//                     +---+      +-^-+         +-^-+
//
//
//
//                    STAGE 1    STAGE 2       STAGE 3      STAGE 4        STAGE 5
// ---------------------------------------------------------------------------------------------
//
// Description of stages :
//
//  Stage 1 : 0 clk
//      Extract part of a posit aka denormalisation
//
//  Stage 2 : 1 clk
//      Multiplication of denormalised posits, the result is denormalised
//      posit with twice fract bits, and +1 scale bits
//
//  Stage 3 : 2 clk
//      Exact accumulation in a Quire
//
//  Stage 4 : 0 clk
//      Normalisation of Quire. Supposed to perform a Rounding scheme like :
//        - truncation : DONE
//        - nearest : "round to nearest, tie to nearest even" : TODO
//        - stochastic rounding : TODO
//
//  Stage 5 : 0 clk
//    perform basic fast sigmoid
// --------------------------------------------------------------------------------------------

import posit_defines::*;

module positron_wo_delay_weights#
(
    parameter integer POSIT_WIDTH = 16,
    parameter integer POSIT_ES = 1,
    parameter integer LOG_NB_ACCUM = 15
)
(
    // System signals
    input  wire clk,
    input  wire rst_n,

    // SLAVE SIDE

    // control signals
    output logic rtr_o,
    input  wire rts_i,
    input  wire sow_i,
    input  wire eow_i,

    input wire [(2*POSIT_WIDTH)-1:0] data_i,  // the weight and the activation arrive in the same word
                                               // LSB posit is activation
                                               // MSB posit is weight


    // MASTER SIDE

    // control signals
    input  wire rtr_i,
    output logic rts_o,
    output logic eow_o,
    
    output logic [POSIT_WIDTH-1:0] posit_o 
);

// local parameters
localparam integer FRACTION_WIDTH_BEFORE_MULT = (`GET_FRACTION_WIDTH(POSIT_WIDTH, POSIT_ES, 0));
localparam integer SCALE_WIDTH_BEFORE_MULT    = (`GET_SCALE_WIDTH(POSIT_WIDTH, POSIT_ES, 0));
localparam integer FRACTION_WIDTH_AFTER_MULT  = (`GET_FRACTION_WIDTH(POSIT_WIDTH, POSIT_ES, 1));
localparam integer SCALE_WIDTH_AFTER_MULT     = (`GET_SCALE_WIDTH(POSIT_WIDTH, POSIT_ES, 1));
localparam integer QUIRE_WIDTH                = (`GET_QUIRE_SIZE(POSIT_WIDTH, POSIT_ES, LOG_NB_ACCUM));
localparam integer UNPACKED_SIZE              = FRACTION_WIDTH_BEFORE_MULT +
                                                SCALE_WIDTH_BEFORE_MULT +
                                                1 + 1 + 1;  // fraction + scale + inf + zero + sign
localparam integer SIGN_POS = UNPACKED_SIZE - 1;
localparam integer NAR_POS  = UNPACKED_SIZE - 2;
localparam integer ZERO_POS = UNPACKED_SIZE - 3;
`define SCALE_POS [UNPACKED_SIZE - 4 : FRACTION_WIDTH_BEFORE_MULT]
`define FRACTION_POS [FRACTION_WIDTH_BEFORE_MULT-1 : 0]

// signals

// extraction
logic sign_activation, sign_weight;
logic NaR_activation, NaR_weight;
logic zero_activation, zero_weight;
logic [SCALE_WIDTH_BEFORE_MULT-1:0] scale_activation, scale_weight;
logic [FRACTION_WIDTH_BEFORE_MULT-1:0] fraction_activation, fraction_weight;

// delay
logic delay_weight_denorm_rtr_o, delay_activation_denorm_rtr_o;
logic delay_weight_denorm_rts_o, delay_activation_denorm_rts_o;
logic delay_weight_denorm_eow_o, delay_activation_denorm_eow_o;
logic delay_weight_denorm_sow_o, delay_activation_denorm_sow_o;
logic [UNPACKED_SIZE-1:0] delay_weight_denorm_data_o, delay_activation_denorm_data_o;

// posit mult
logic posit_mult_ready;
logic posit_mult_valid;
logic posit_mult_eow_o;
logic posit_mult_sow_o;
logic [FRACTION_WIDTH_AFTER_MULT-1:0] posit_mult_fraction_o;
logic [SCALE_WIDTH_AFTER_MULT-1:0] posit_mult_scale_o;
logic posit_mult_NaR_o;  
logic posit_mult_sign_o;
logic posit_mult_zero_o;

// quire
logic quire_ready;
logic quire_valid;
logic quire_eow_o;
logic quire_sow_o;
logic [QUIRE_WIDTH-1:0] quire_data_o;
logic quire_NaR_o;

// delay
logic delay_quire_rts_o, delay_norm_rts_o;
logic delay_quire_sow_o, delay_norm_sow_o;
logic delay_quire_eow_o, delay_norm_eow_o;
logic delay_quire_rtr_o, delay_norm_rtr_o;
logic [QUIRE_WIDTH-1:0] delay_quire_data_o;
logic [POSIT_WIDTH-1:0] delay_norm_data_o;

// normalization
logic [POSIT_WIDTH-1:0] normalization_posit_o;

// activation function : sigmoid
logic [POSIT_WIDTH-1:0] sigmoid_posit_o;

//    _____ __               
//   / ___// /___ __   _____ 
//   \__ \/ / __ `/ | / / _ \
//  ___/ / / /_/ /| |/ /  __/
// /____/_/\__,_/ |___/\___/ 

assign rtr_o = delay_weight_denorm_rtr_o & delay_activation_denorm_rtr_o; 


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
    .posit_word_i ( data_i[(2*POSIT_WIDTH)-1:POSIT_WIDTH] ),

    // out
    .sign         ( sign_weight     ),
    .inf          ( NaR_weight      ),
    .zero         ( zero_weight     ),
    .scale        ( scale_weight    ),
    .fraction     ( fraction_weight )
);

// extract activation positron delayed
posit_data_extract #(
    .POSIT_WIDTH ( POSIT_WIDTH ),
    .POSIT_ES    ( POSIT_ES    )
)
extract_activation_positron(

    // in
    .posit_word_i ( data_i[POSIT_WIDTH-1:0] ),

    // out
    .sign         ( sign_activation        ),
    .inf          ( NaR_activation         ),
    .zero         ( zero_activation        ),
    .scale        ( scale_activation       ),
    .fraction     ( fraction_activation    )
);

//        __     __           
//   ____/ /__  / /___ ___  __
//  / __  / _ \/ / __ `/ / / /
// / /_/ /  __/ / /_/ / /_/ / 
// \__,_/\___/_/\__,_/\__, /  
//                   /____/   
pipeline #(
    .DATA_WIDTH ( UNPACKED_SIZE ),
    .DELAY      ( 2             )
)
delay_weight_denorm (
    // System 
    .clk      ( clk   ),
    .rst_n    ( rst_n ),
    
    // Slave 
    .rtr_o    ( delay_weight_denorm_rtr_o ),
    .rts_i    ( rts_i                     ),
    .eow_i    ( eow_i                     ),
    .sow_i    ( sow_i                     ),
    .data_i   ( {sign_weight, NaR_weight, zero_weight, scale_weight, fraction_weight} ),

    // Master
    .rtr_i    ( posit_mult_ready           ),
    .rts_o    ( delay_weight_denorm_rts_o  ),
    .sow_o    ( delay_weight_denorm_sow_o  ),
    .eow_o    ( delay_weight_denorm_eow_o  ),
    .data_o   ( delay_weight_denorm_data_o )
);

pipeline #(
    .DATA_WIDTH ( UNPACKED_SIZE ),
    .DELAY      ( 2             )
)
delay_activation_denorm (
    // System 
    .clk      ( clk   ),
    .rst_n    ( rst_n ),
    
    // Slave 
    .rtr_o    ( delay_activation_denorm_rtr_o ),
    .rts_i    ( rts_i                         ),
    .eow_i    ( eow_i                         ),
    .sow_i    ( sow_i                         ),
    .data_i   ( {sign_activation, NaR_activation, zero_activation, scale_activation, fraction_activation} ),

    // Master
    .rtr_i    ( posit_mult_ready               ),
    .rts_o    ( delay_activation_denorm_rts_o  ),
    .sow_o    ( delay_activation_denorm_sow_o  ),
    .eow_o    ( delay_activation_denorm_eow_o  ),
    .data_o   ( delay_activation_denorm_data_o )
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
    .clk   ( clk                           ),
    .rst_n ( rst_n                         ),
    
    // SLAVE SIDE
    
    // control signals
    .rtr_o ( posit_mult_ready              ),
    .rts_i ( delay_activation_denorm_rts_o ),
    .sow_i ( delay_activation_denorm_sow_o ),
    .eow_i ( delay_activation_denorm_eow_o ),
    
    // input posit 1
    .fraction_i1 ( delay_activation_denorm_data_o`FRACTION_POS ),
    .scale_i1    ( delay_activation_denorm_data_o`SCALE_POS    ),
    .NaR_i1      ( delay_activation_denorm_data_o[NAR_POS]     ),
    .zero_i1     ( delay_activation_denorm_data_o[ZERO_POS]    ),
    .sign_i1     ( delay_activation_denorm_data_o[SIGN_POS]    ),
   
    // input posit 2
    .fraction_i2 ( delay_weight_denorm_data_o`FRACTION_POS ),
    .scale_i2    ( delay_weight_denorm_data_o`SCALE_POS    ),
    .NaR_i2      ( delay_weight_denorm_data_o[NAR_POS]     ),
    .zero_i2     ( delay_weight_denorm_data_o[ZERO_POS]    ),
    .sign_i2     ( delay_weight_denorm_data_o[SIGN_POS]    ),
    
    // MASTER SIDE
    
    // control signals
    .rtr_i       ( quire_ready           ),
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

//    ____        _         
//   / __ \__  __(_)_______ 
//  / / / / / / / / ___/ _ \
// / /_/ / /_/ / / /  /  __/
// \___\_\__,_/_/_/   \___/ 

quire #
(
    .POSIT_WIDTH   ( POSIT_WIDTH  ),
    .POSIT_ES      ( POSIT_ES     ),
    .LOG_NB_ACCUM  ( LOG_NB_ACCUM ),
    .IS_PROD_ACCUM ( 1            )
)
quire_prod_accum_inst (
    
    // System signals
    .clk      ( clk                   ),
    .rst_n    ( rst_n                 ),

    // Slave side
    .rtr_o    ( quire_ready           ),
    .rts_i    ( posit_mult_valid      ),
    .sow_i    ( posit_mult_sow_o      ),
    .eow_i    ( posit_mult_eow_o      ),
    .fraction ( posit_mult_fraction_o ),
    .scale    ( posit_mult_scale_o    ),
    .sign_i   ( posit_mult_sign_o     ),
    .zero_i   ( posit_mult_zero_o     ),
    .NaR_i    ( posit_mult_NaR_o      ),
    
    // Master side
    .rtr_i    ( delay_quire_rtr_o     ),
    .rts_o    ( quire_valid           ),
    .eow_o    ( quire_eow_o           ),
    .sow_o    ( quire_sow_o           ),
    .data_o   ( quire_data_o          ),
    .NaR_o    ( quire_NaR_o           )

);

//        __     __           
//   ____/ /__  / /___ ___  __
//  / __  / _ \/ / __ `/ / / /
// / /_/ /  __/ / /_/ / /_/ / 
// \__,_/\___/_/\__,_/\__, /  
//                   /____/   
pipeline #(
    .DATA_WIDTH ( QUIRE_WIDTH ),
    .DELAY      ( 2           )
)
delay_quire (
    // System 
    .clk      ( clk                ),
    .rst_n    ( rst_n              ),
    
    // Slave 
    .rtr_o    ( delay_quire_rtr_o  ),
    .rts_i    ( quire_valid        ),
    .eow_i    ( quire_eow_o        ),
    .sow_i    ( quire_sow_o        ),
    .data_i   ( quire_data_o       ),

    // Master
    .rtr_i    ( delay_norm_rtr_o   ),
    .rts_o    ( delay_quire_rts_o  ),
    .sow_o    ( delay_quire_sow_o  ),
    .eow_o    ( delay_quire_eow_o  ),
    .data_o   ( delay_quire_data_o )
);


//     _   __                           ___             __  _           
//    / | / /___  _________ ___  ____ _/ (_)___  ____ _/ /_(_)___  ____ 
//   /  |/ / __ \/ ___/ __ `__ \/ __ `/ / /_  / / __ `/ __/ / __ \/ __ \
//  / /|  / /_/ / /  / / / / / / /_/ / / / / /_/ /_/ / /_/ / /_/ / / / /
// /_/ |_/\____/_/  /_/ /_/ /_/\__,_/_/_/ /___/\__,_/\__/_/\____/_/ /_/ 

posit_normalize_quire #
(
    .QUIRE_IN_WIDTH  ( QUIRE_WIDTH ),
    .POSIT_OUT_WIDTH ( POSIT_WIDTH ),
    .POSIT_IN_WIDTH  ( POSIT_WIDTH ),
    .POSIT_IN_ES     ( POSIT_ES    )
)
posit_normalize_quire_inst (
    // SLAVE SIDE   
    .quire_i ( delay_quire_data_o    ),
    
    // MASTER SIDE    
    .posit_o ( normalization_posit_o )

);
//        __     __           
//   ____/ /__  / /___ ___  __
//  / __  / _ \/ / __ `/ / / /
// / /_/ /  __/ / /_/ / /_/ / 
// \__,_/\___/_/\__,_/\__, /  
//                   /____/   

pipeline #(
    .DATA_WIDTH ( POSIT_WIDTH ),
    .DELAY      ( 2           )
)
delay_norm (
    // System 
    .clk      ( clk                   ),
    .rst_n    ( rst_n                 ),
    
    // Slave 
    .rtr_o    ( delay_norm_rtr_o      ),
    .rts_i    ( delay_quire_rts_o     ),
    .eow_i    ( delay_quire_eow_o     ),
    .sow_i    ( delay_quire_sow_o     ),
    .data_i   ( normalization_posit_o ),

    // Master
    .rtr_i    ( rtr_i                 ),
    .rts_o    ( delay_norm_rts_o      ),
    .sow_o    ( delay_norm_sow_o      ),
    .eow_o    ( delay_norm_eow_o      ),
    .data_o   ( delay_norm_data_o     )
);

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
    .posit_i ( delay_norm_data_o ),
    .posit_o ( sigmoid_posit_o   )
);

//                          __           
//    ____ ___  ____ ______/ /____  _____
//   / __ `__ \/ __ `/ ___/ __/ _ \/ ___/
//  / / / / / / /_/ (__  ) /_/  __/ /    
// /_/ /_/ /_/\__,_/____/\__/\___/_/     

// assign rts_o       = quire_eow_o & quire_valid;
// assign eow_o       = quire_eow_o;
// assign posit_o     = sigmoid_posit_o;
assign rts_o   = delay_norm_eow_o & delay_norm_rts_o;
assign eow_o   = delay_norm_eow_o;
assign posit_o = sigmoid_posit_o;

endmodule

`default_nettype wire