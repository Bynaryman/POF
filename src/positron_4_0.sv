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
// ---------------------------------------------------------------------------------------------
//
//              +--------+    +---+      +---+         +---+
//              | WEIGHT |    |   | w[i] |   |         |   |
//              |  ROM   |--->|   |----->|   |         |   |
//              |        |    |   |      |   |         |   |
//              +----^---+    +---+      |   |         |   |        +---+         +---+
//                                       |   | mult[i] |   | acc[i] |   | norm[i] |   | sigm[i] 
//                                       |   |-------->|   |------->|   |-------->|   |-------->
//                                       |   |         |   |        |   |         |   |
//               +-------+    +---+      |   |         |   |        +---+         +---+
//               | DELAY |    |   | x[i] |   |         |   |
//       x[i]--->|       |--->|   |----->|   |         |   |
//               |       |    |   |      |   |         |   |
//               +---^---+    +---+      +-^-+         +-^-+
//
//
//
//              STAGE 1      STAGE 2    STAGE 3       STAGE 4     STAGE 5       STAGE6
// ---------------------------------------------------------------------------------------------
//
// Description of stages :
//
//  Stage 1 : N clks (default 2)
//      Read weight corresponding to the i_th activation coming. ROM has delay
//      for hight throughput therefore the activation is also delayed 
//
//  Stage 2 : 0 clk
//      Extract part of a posit aka denormalisation
//
//  Stage 3 : 1 clk
//      Multiplication of denormalised posits, the result is denormalised
//      posit with twice fract bits, and +1 scale bits
//
//  Stage 4 : 2 clk
//      Exact accumulation in a Quire
//
//  Stage 5 : 0 clk
//      Normalisation of Quire. Supposed to perform a Rounding scheme like :
//        - truncation : DONE
//        - nearest : "round to nearest, tie to nearest even" : TODO
//        - stochastic rounding : TODO
//
//  Stage 6 : 0 clk
//    perform basic fast sigmoid
// --------------------------------------------------------------------------------------------

import posit_defines::*;

module positron_4_0#
(
    parameter integer POSIT_WIDTH = 4,
    parameter integer POSIT_ES = 0,
    parameter WEIGHTS_BASE_PATH = "",
    parameter WEIGHTS_FILE_NUMBER = "",
    parameter integer NB_UPSTREAM_POSITRON = 784,
    parameter integer LOG_NB_ACCUM = 10
)
(
    // System signals
    input  logic clk,
    input  logic rst_n,
    
    // SLAVE SIDE
    
    // control signals
    output logic rtr_o,
    input  logic rts_i,
    input  logic sow_i,
    input  logic eow_i,
    
    input logic [POSIT_WIDTH-1:0] posit_i ,
    
    
    // MASTER SIDE
        
    // control signals
    input  logic rtr_i,
    output logic rts_o,
    output logic eow_o,
    
    output logic [POSIT_WIDTH-1:0] posit_o 
);

// local parameters
localparam integer DELAY_READ_ROM = 2;
localparam integer FRACTION_WIDTH_BEFORE_MULT = 2;
localparam integer SCALE_WIDTH_BEFORE_MULT    = 3;
localparam integer FRACTION_WIDTH_AFTER_MULT  = 4; // 2*2
localparam integer SCALE_WIDTH_AFTER_MULT     = 4; // does not grow since es=0, and never overflow
localparam integer QUIRE_WIDTH                = 19; // recompute TODO

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

// extraction
logic sign_input, sign_weight;
logic NaR_input, NaR_weight;
logic zero_input, zero_weight;
logic [SCALE_WIDTH_BEFORE_MULT-1:0] scale_input, scale_weight;
logic [FRACTION_WIDTH_BEFORE_MULT-1:0] fraction_input, fraction_weight;

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

// normalization
logic [POSIT_WIDTH-1:0] normalization_posit_o;

// activation function : sigmoid
logic [POSIT_WIDTH-1:0] sigmoid_posit_o;

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
   .rtr_i     ( quire_ready         ),
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
    .DATA_WIDTH ( POSIT_WIDTH    ),
    .DELAY      ( DELAY_READ_ROM )
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
    .rtr_i  ( quire_ready            ),
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

// posit_mult #
// (
//     .POSIT_WIDTH ( POSIT_WIDTH ),
//     .POSIT_ES    ( POSIT_ES    )
// )
// posit_mult_inst (
// 
//     // System signals
//     .clk   ( clk                         ),
//     .rst_n ( rst_n                       ),
//     
//     // SLAVE SIDE
//     
//     // control signals
//     .rtr_o ( posit_mult_ready            ),
//     .rts_i ( weights_rom_valid           ),
//     .sow_i ( weights_rom_sow_o           ),
//     .eow_i ( weights_rom_eow_o           ),
//     
//     // input posit 1
//     .fraction_i1 ( fraction_input        ),
//     .scale_i1    ( scale_input           ),
//     .NaR_i1      ( NaR_input             ),
//     .zero_i1     ( zero_input            ),
//     .sign_i1     ( sign_input            ),
//    
//     // input posit 2
//     .fraction_i2 ( fraction_weight       ),
//     .scale_i2    ( scale_weight          ),
//     .NaR_i2      ( NaR_weight            ),
//     .zero_i2     ( zero_weight           ),
//     .sign_i2     ( sign_weight           ),
//     
//     // MASTER SIDE
//     
//     // control signals
//     .rtr_i       ( quire_ready           ),
//     .rts_o       ( posit_mult_valid      ),
//     .eow_o       ( posit_mult_eow_o      ),
//     .sow_o       ( posit_mult_sow_o      ),
//     
//     // output posit
//     .fraction_o  ( posit_mult_fraction_o ), 
//     .scale_o     ( posit_mult_scale_o    ),
//     .NaR_o       ( posit_mult_NaR_o      ),
//     .sign_o      ( posit_mult_sign_o     ),
//     .zero_o      ( posit_mult_zero_o     )
// 
// );

posit_mult_4_0 posit_mult_inst (

    // SLAVE SIDE
    
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

quire_4_0 #
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
    .rtr_o      ( quire_ready           ),
    .rts_i      ( weights_rom_valid     ),
    .sow_i      ( weights_rom_sow_o     ),
    .eow_i      ( weights_rom_eow_o     ),
    .fraction_i ( posit_mult_fraction_o ),
    .scale_i    ( posit_mult_scale_o    ),
    .sign_i     ( posit_mult_sign_o     ),
    .zero_i     ( posit_mult_zero_o     ),
    .NaR_i      ( posit_mult_NaR_o      ),
    
    // Master side
    .rtr_i      ( rtr_i                 ),
    .rts_o      ( quire_valid           ),
    .eow_o      ( quire_eow_o           ),
    .sow_o      ( quire_sow_o           ),
    .data_o     ( quire_data_o          ),
    .NaR_o      ( quire_NaR_o           )

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
    .quire_i ( quire_data_o          ),
    
    // MASTER SIDE    
    .posit_o ( normalization_posit_o )

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
    .posit_i ( normalization_posit_o ),
    .posit_o ( sigmoid_posit_o       )
);

//                          __           
//    ____ ___  ____ ______/ /____  _____
//   / __ `__ \/ __ `/ ___/ __/ _ \/ ___/
//  / / / / / / /_/ (__  ) /_/  __/ /    
// /_/ /_/ /_/\__,_/____/\__/\___/_/     

assign rts_o       = quire_eow_o & quire_valid;
assign eow_o       = quire_eow_o;
assign posit_o     = sigmoid_posit_o;


endmodule

