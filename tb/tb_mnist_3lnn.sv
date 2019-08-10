`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: LEDOUX Louis
// 
// Create Date: 01/11/2019 12:01:34 PM
// Design Name: 
// Module Name: tb_mnist_3lnn
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
//////////////////////////////////////////////////////////////////////////////////


module tb_mnist_3lnn( );

    parameter CLK_PERIOD      = 2;
    parameter CLK_HALF_PERIOD = CLK_PERIOD / 2;
    
    localparam integer POSIT_WIDTH = 4;
    localparam integer POSIT_ES    = 0;
    
    localparam integer NB_HIDDEN_UPSTREAM_POSITRON = 784;
    localparam integer NB_HIDDEN_POSITRON = 20;
    localparam integer NB_OUTPUT_UPSTREAM_POSITRON = NB_HIDDEN_POSITRON;
    localparam integer NB_OUTPUT_POSITRON = 10;
    
    localparam string INPUT_PICTURE_PATH = "/home/lledoux/Desktop/PhD/ML/C/mnist-3lnn/posits_raw_for_tb_and_inf/2pic_to_classify_4b.raw";
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
    logic [POSIT_WIDTH-1:0] s_axis_in_tdata;
    logic [(POSIT_WIDTH+7/8)-1:0] s_axis_in_tstrb;
    logic s_axis_in_tlast;
    
    // hidden
    logic hidden_rts_o;
    logic hidden_eow_o;
    logic [POSIT_WIDTH-1:0] hidden_posit_o;
    
    // output
    logic output_rtr_o;
    logic output_rts_o;
    logic output_eow_o;
    logic [POSIT_WIDTH-1:0] output_posit_o;

    axi_stream_generator_from_file #
    (
        .WIDTH ( POSIT_WIDTH ),
        .base_path ( INPUT_PICTURE_PATH ),
        .path ( "" ),
        .nb_data ( 2*NB_HIDDEN_UPSTREAM_POSITRON ),
        .READ_B_OR_H ( "H" )
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
        .clk      ( tb_clk         ),
        .rst_n    ( tb_reset_n     ),
        
        // SLAVE SIDE
        
        // control signals
        .rtr_o    ( s_axis_in_tready ),
        .rts_i    ( s_axis_in_tvalid ),
        .eow_i    ( s_axis_in_tlast  ),
        
        .posit_i  ( s_axis_in_tdata ),
        
        
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
        .clk      ( tb_clk         ),
        .rst_n    ( tb_reset_n     ),
        
        // SLAVE SIDE
        
        // control signals
        .rtr_o    ( output_rtr_o   ),
        .rts_i    ( hidden_rts_o   ),
        .eow_i    ( hidden_eow_o   ),
        
        .posit_i  ( hidden_posit_o ),
        
        
        // MASTER SIDE
            
        // control signals
        .rtr_i    ( 1              ), // emulate DMA always ready
        .rts_o    ( output_rts_o   ),
        .eow_o    ( output_eow_o   ),
        
        .posit_o  ( output_posit_o )
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
