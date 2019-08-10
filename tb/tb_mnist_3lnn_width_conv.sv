`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/15/2019 03:07:35 PM
// Design Name: 
// Module Name: tb_mnist_3lnn_width_conv
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
//    include the down conv and widden
//
//    file_8b -> 8b_to_4b -> hidden_layer -> output_layer -> 4b_to_8b
//
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_mnist_3lnn_width_conv();

    parameter CLK_PERIOD      = 2;
    parameter CLK_HALF_PERIOD = CLK_PERIOD / 2;
    
    localparam integer STREAM_WIDTH = 8;
    localparam integer POSIT_WIDTH  = 4;
    localparam integer POSIT_ES     = 0;
    
    localparam integer NB_HIDDEN_UPSTREAM_POSITRON = 784;
    localparam integer NB_HIDDEN_POSITRON = 20;
    localparam integer NB_OUTPUT_UPSTREAM_POSITRON = NB_HIDDEN_POSITRON;
    localparam integer NB_OUTPUT_POSITRON = 10;
    
    localparam string INPUT_PICTURE_PATH = "/home/lledoux/Desktop/PhD/ML/C/mnist-3lnn/posits_raw_for_tb_and_inf/2pic_to_classify_4b_concat_8b.raw";
    localparam string BASE_PATH_HIDDEN   = "/home/lledoux/Desktop/PhD/ML/C/mnist-3lnn/hidden_weights_4_0/hidden_weights_";
    localparam string BASE_PATH_OUTPUT   = "/home/lledoux/Desktop/PhD/ML/C/mnist-3lnn/output_weights_4_0/output_weights_";
    
    
    //----------------------------------------------------------------
    // Signals, clocks, and reset
    //----------------------------------------------------------------
 
    logic tb_clk;
    logic tb_reset_n;
    
    // file (picture) read
    logic s_axis_in_aclk;
    logic s_axis_in_tready;
    logic s_axis_in_aresetn;
    logic s_axis_in_tvalid;
    logic [STREAM_WIDTH-1:0] s_axis_in_tdata;
    logic s_axis_in_tstrb;
    logic s_axis_in_tlast;
    
    // width down converter
    logic width_down_conv_rts_o = 0;
    logic width_down_conv_eow_o = 0;
    logic [POSIT_WIDTH-1:0]width_down_conv_data_o;
    
    // hidden
    logic hidden_rtr_o = 0;
    logic hidden_rts_o = 0;
    logic hidden_eow_o = 0;
    logic [POSIT_WIDTH-1:0] hidden_posit_o;
    
    // output
    logic output_rtr_o = 0;
    logic output_rts_o = 0;
    logic output_eow_o = 0;
    logic [POSIT_WIDTH-1:0] output_posit_o;
    
    // width widden
    logic width_widden_rtr_o = 0;
    logic width_widden_rts_o = 0;
    logic width_widden_eow_o = 0;
    logic [STREAM_WIDTH-1:0] width_widden_data_o;
    

    axi_stream_generator_from_file #
    (
        .WIDTH ( STREAM_WIDTH ),
        .base_path ( INPUT_PICTURE_PATH ),
        .path ( "" ),
        .nb_data ( 2*NB_HIDDEN_UPSTREAM_POSITRON /2 ), // 2 pics but each octet codes 2 posits
        .READ_B_OR_H ( "B" )
    )
    axi_stream_generator_inst 
    (
       
       .rst_n         ( tb_reset_n       ),  
       // Starts an axi_stream transaction
       .start         ( s_axis_in_tready ),  //  in std_logic; 
    
       // axi stream ports
       .m_axis_clk    ( tb_clk           ),  //  in  std_logic;
       .m_axis_tvalid ( s_axis_in_tvalid ),  //  out std_logic;
       .m_axis_tdata  ( s_axis_in_tdata  ),  //  out std_logic_vector(31 downto 0);
       .m_axis_tstrb  ( s_axis_in_tstrb  ),  //  out std_logic_vector(3 downto 0);
       .m_axis_tlast  ( s_axis_in_tlast  )   //  out std_logic  
    );
    
    pkt_txbusif #(
        .DATAi_W        ( STREAM_WIDTH ),
        .DATAo_W        ( POSIT_WIDTH  ),
        .FIFO_DEPTH     ( 8            ),
        .FIFO_LOG_DEPTH ( 3            )
    ) pkt_txbusif_inst
    (
        // System signals
        .clk       ( tb_clk                 ),
        .rst_n     ( tb_reset_n             ),
        
        .ieng_act  ( 1                      ),
                
        // Slave
        .off_rtr   ( s_axis_in_tready       ),
        .iff_rts   ( s_axis_in_tvalid       ),
        .iff_sow   ( 0                      ),
        .iff_eow   ( s_axis_in_tlast        ),
        .iff_data  ( s_axis_in_tdata        ),
        
        // Master
        .rtr_i     ( hidden_rtr_o           ),
        .rts_o     ( width_down_conv_rts_o  ),
        .sow_o     (                        ),
        .eow_o     ( width_down_conv_eow_o  ),
        .data_o    ( width_down_conv_data_o )
        
    );

    
    // instanciate layers
    positron_layer #
    (
        .NB_UPSTREAM_POSITRON ( NB_HIDDEN_UPSTREAM_POSITRON ),
        .WEIGHTS_BASE_PATH    ( BASE_PATH_HIDDEN            ),
        .NB_POSITRON          ( NB_HIDDEN_POSITRON          ),
        .POSIT_WIDTH          ( POSIT_WIDTH                 ),
        .POSIT_ES             ( POSIT_ES                    )
    )
    positron_hidden_layer_inst(
        // System signals
        .clk      ( tb_clk                 ),
        .rst_n    ( tb_reset_n             ),
        
        // SLAVE SIDE
        
        // control signals
        .rtr_o    ( hidden_rtr_o           ),
        .rts_i    ( width_down_conv_rts_o  ),
        .eow_i    ( width_down_conv_eow_o  ),
        
        .posit_i  ( width_down_conv_data_o ),
        
        
        // MASTER SIDE
            
        // control signals
        .rtr_i    ( output_rtr_o   ),
        .rts_o    ( hidden_rts_o   ),
        .eow_o    ( hidden_eow_o   ),
        
        .posit_o  ( hidden_posit_o )
    );
    
    positron_layer #
    (
        .NB_UPSTREAM_POSITRON ( NB_OUTPUT_UPSTREAM_POSITRON ),
        .WEIGHTS_BASE_PATH    ( BASE_PATH_OUTPUT            ),
        .NB_POSITRON          ( NB_OUTPUT_POSITRON          ),
        .POSIT_WIDTH          ( POSIT_WIDTH                 ),
        .POSIT_ES             ( POSIT_ES                    )
    )
    positron_output_layer_inst(
        // System signals
        .clk      ( tb_clk             ),
        .rst_n    ( tb_reset_n         ),
        
        // SLAVE SIDE
        
        // control signals
        .rtr_o    ( output_rtr_o       ),
        .rts_i    ( hidden_rts_o       ),
        .eow_i    ( hidden_eow_o       ),
        
        .posit_i  ( hidden_posit_o     ),
        
        
        // MASTER SIDE
            
        // control signals
        .rtr_i    ( width_widden_rtr_o ),
        .rts_o    ( output_rts_o       ),
        .eow_o    ( output_eow_o       ),
        
        .posit_o  ( output_posit_o     )
    );
    
    width_widden #(
        .DATAi_W ( POSIT_WIDTH  ),
        .DATAo_W ( STREAM_WIDTH )
    ) width_widden_inst
    (
        // System signals
        .clk    ( tb_clk              ),
        .rst_n  ( tb_reset_n          ),
                
        // Slave
        .rtr_o  ( width_widden_rtr_o  ),
        .rts_i  ( output_rts_o        ),
        .sow_i  ( 0                   ),
        .eow_i  ( output_eow_o        ),
        .data_i ( output_posit_o      ),
        
        // Master
        .rtr_i  ( 1                   ),  // simulate DMA always ready
        .rts_o  ( width_widden_rts_o  ),
        .sow_o  (                     ),
        .eow_o  ( width_widden_eow_o  ),
        .data_o ( width_widden_data_o ),
        .oerr   ( )
        
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
            #(100 * CLK_HALF_PERIOD);
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
