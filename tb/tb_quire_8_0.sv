////////////////////////////////////////////////////////////////////////////////
// 
// Company: BSC
// Author: lledoux
//
// Create Date: 08/07/2019
// Module Name: tb_quire_8_0
// Description:
//     Specific test bench for quire N:8 ES:0
//
////////////////////////////////////////////////////////////////////////////////

import posit_defines::*;

module tb_quire_8_0();

    parameter CLK_PERIOD      = 2;
    parameter CLK_HALF_PERIOD = CLK_PERIOD / 2;
    
    localparam integer NB_DATA = 10;
    localparam  INPUT_BASE_PATH = "/home/lledoux/Desktop/PhD/fpga/P9_OPC/my_posits/tb";
    localparam  INPUT_PATH = "/quire_8_0_input_values.raw";
    localparam  READ_B_OR_H = "B";
    
    localparam integer POSIT_WIDTH = 8;
    localparam integer POSIT_ES = 0;
    localparam integer LOG_NB_ACCUM = 15;
    localparam integer IS_PROD_ACCUM = 1;
    localparam integer FRACTION_WIDTH_AFTER_MULT  = (`GET_FRACTION_WIDTH(POSIT_WIDTH, POSIT_ES, 1));
    localparam integer SCALE_WIDTH_AFTER_MULT     = (`GET_SCALE_WIDTH(POSIT_WIDTH, POSIT_ES, 1));
    localparam integer QUIRE_WIDTH                = (`GET_QUIRE_SIZE(POSIT_WIDTH, POSIT_ES, LOG_NB_ACCUM));
    
    localparam integer DATA_WIDTH = FRACTION_WIDTH_AFTER_MULT + SCALE_WIDTH_AFTER_MULT + 3; // frac + scale + zero + nar + sign
    
    //----------------------------------------------------------------
    // Signals, clocks, and reset
    //----------------------------------------------------------------

    logic tb_clk;
    logic tb_reset_n;

    // file (posits denormalized) read
    logic s_axis_in_aclk;
    logic s_axis_in_tready;
    logic s_axis_in_aresetn;
    logic s_axis_in_tvalid;
    logic [DATA_WIDTH-1:0] s_axis_in_tdata;
    logic [(DATA_WIDTH/8)-1:0] s_axis_in_tstrb;
    logic s_axis_in_tlast;
    logic sow_i;
    
    // input fields
    logic [FRACTION_WIDTH_AFTER_MULT-1:0] fraction;
    logic [SCALE_WIDTH_AFTER_MULT-1:0] scale;
    logic zero;
    logic sign;
    logic NaR;
    
    // output
    logic rts_o;
    logic eow_o;
    logic sow_o;
    logic [QUIRE_WIDTH-1:0] quire_o;

    axi_stream_generator_from_file #
    (
        .WIDTH       ( DATA_WIDTH           ),
        .base_path   ( INPUT_BASE_PATH      ),
        .path        ( INPUT_PATH           ),
        .nb_data     ( NB_DATA              ),
        .READ_B_OR_H ( READ_B_OR_H          )
    )
    axi_stream_generator_inst 
    (

       .rst_n         ( tb_reset_n       ),
       // Starts an axi_stream transaction
       .start         ( s_axis_in_tready ),

       // axi stream ports
       .m_axis_clk    ( tb_clk           ),
       .m_axis_tvalid ( s_axis_in_tvalid ),
       .m_axis_tdata  ( s_axis_in_tdata  ),
       .m_axis_tstrb  ( s_axis_in_tstrb  ),
       .m_axis_tlast  ( s_axis_in_tlast  )
    );

    // logic for sow
    logic s_axis_in_tvalid_r;
    always_ff @(posedge tb_clk or negedge tb_reset_n) begin
        if ( ~tb_reset_n ) begin
            s_axis_in_tvalid_r <= 0;
        end
        else begin
            s_axis_in_tvalid_r <= s_axis_in_tvalid;
        end
    end
    assign sow_i   = s_axis_in_tvalid & ~s_axis_in_tvalid_r;


    assign fraction = s_axis_in_tdata[FRACTION_WIDTH_AFTER_MULT-1:0];
    assign scale    = s_axis_in_tdata[FRACTION_WIDTH_AFTER_MULT +: SCALE_WIDTH_AFTER_MULT];
    assign zero     = s_axis_in_tdata[DATA_WIDTH-2];
    assign sign     = s_axis_in_tdata[DATA_WIDTH-1];
    assign NaR      = s_axis_in_tdata[DATA_WIDTH-3];

    // INSTANCIATE DUT
    quire #(
        .POSIT_WIDTH   ( POSIT_WIDTH   ),
        .POSIT_ES      ( POSIT_ES      ),
        .LOG_NB_ACCUM  ( LOG_NB_ACCUM  ),
        .IS_PROD_ACCUM ( IS_PROD_ACCUM )
    ) quire_8_0_inst(
    
            // System signals
            .clk      ( tb_clk           ),
            .rst_n    ( tb_reset_n       ),
    
            // Slave side
            .rtr_o    ( s_axis_in_tready ),
            .rts_i    ( s_axis_in_tvalid ),
            .sow_i    ( sow_i            ),
            .eow_i    ( s_axis_in_tlast  ),
            .fraction ( fraction         ),
            .scale    ( scale            ),
            .zero_i   ( zero             ),
            .sign_i   ( sign             ),
            .NaR_i    ( NaR              ),
 
            // Master side
            .rtr_i    ( 1                ), // always ready since it is a test bench
            .rts_o    ( rts_o            ),
            .eow_o    ( eow_o            ),
            .sow_o    ( sow_o            ),
            .data_o   ( quire_o          )
    
        );


    //----------------------------------------------------------------
    // clk_gen
    //
    // Always running clock generator process.
    //----------------------------------------------------------------

    initial tb_clk = 0;
    always #CLK_HALF_PERIOD tb_clk = !tb_clk;

    //----------------------------------------------------------------
    // reset_dut()
    //
    // Toggle reset to put the DUT into a well known state.
    //----------------------------------------------------------------
    task reset_dut;
        begin
            $display("*** Toggle reset.");
            tb_reset_n = 0;
            #(100 * CLK_PERIOD);
            tb_reset_n = 1;
        end
    endtask // reset_dut

    //----------------------------------------------------------------
    // init_sim()
    //
    // All the init part
    //----------------------------------------------------------------
    task init_sim;
        begin
            $display("*** init sim.");
            tb_clk = 0;
            tb_reset_n = 1;
        end
    endtask // reset_dut

    //----------------------------------------------------------------
    // init sim
    //----------------------------------------------------------------
    initial begin

        assign s_axis_in_aclk    = tb_clk;
        assign s_axis_in_aresetn = tb_reset_n;

        init_sim();
        reset_dut();
    end

endmodule
