`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: LEDOUX Louis
// 
// Create Date: 01/07/2019 10:05:41 AM
// Design Name: 
// Module Name: tb_positron
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

import posit_defines::*;

module tb_positron();

    parameter CLK_PERIOD      = 2;
    parameter CLK_HALF_PERIOD = CLK_PERIOD / 2;
    
    localparam integer POSIT_WIDTH = 16;
    localparam integer POSIT_ES = 0;
    localparam integer NB_UPSTREAM_POSITRON = 784;
    localparam string BASE_PATH   = "/home/lledoux/Desktop/PhD/fpga/my_posits/my_posits.srcs/sim_1/new/";
    localparam string INPUT_PATH  = "positrons_input.txt";
    localparam string WEIGHT_PATH = "positrons_weight.txt";
    
    //----------------------------------------------------------------
    // Signals, clocks, and reset
    //----------------------------------------------------------------
 
    logic tb_clk;
    logic tb_reset_n;
    
    logic start = 0;

    logic s_axis_in_aclk;
    logic s_axis_in_tready;
    logic s_axis_in_aresetn;
    logic s_axis_in_tvalid;
    logic [POSIT_WIDTH-1:0] s_axis_in_tdata;
    logic [(POSIT_WIDTH/8)-1:0] s_axis_in_tstrb;
    logic s_axis_in_tlast;
    logic sow_i;
    logic rts_o;
    logic eow_o;
    logic sow_o;
    logic [POSIT_WIDTH-1:0] posit_o;
    
        
    axi_stream_generator_from_file #
    (
        .WIDTH ( POSIT_WIDTH ),
        .base_path ( "/home/lledoux/Desktop/PhD/ML/C/mnist-3lnn/hidden_weights/hidden_weights_0" ),
        .path ( "" ),
        .nb_data ( NB_UPSTREAM_POSITRON ),
        .READ_B_OR_H ( "B" )
    )
    axi_stream_generator_inst 
    (
         
       // Starts an axi_stream transaction
       .start         ( s_axis_in_tready ),  //  in std_logic; 
    
       // axi stream ports
       .m_axis_clk    ( tb_clk           ),  //  in  std_logic;
       .m_axis_tvalid ( s_axis_in_tvalid ),  //  out std_logic;
       .m_axis_tdata  ( s_axis_in_tdata  ),  //  out std_logic_vector(31 downto 0);
       .m_axis_tstrb  ( s_axis_in_tstrb  ),  //  out std_logic_vector(3 downto 0);
       .m_axis_tlast  ( s_axis_in_tlast  )   //  out std_logic  
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
    
    // instanciate DUT
    positron#
    (
        .POSIT_WIDTH          ( POSIT_WIDTH          ),
        .POSIT_ES             ( POSIT_ES             ),
        .WEIGHTS_BASE_PATH    ( "/home/lledoux/Desktop/PhD/ML/C/mnist-3lnn/hidden_weights/hidden_weights_0" ),
        .WEIGHTS_FILE_NUMBER  ( ""          ),
        .NB_UPSTREAM_POSITRON ( NB_UPSTREAM_POSITRON ),
        .LOG_NB_ACCUM         ( 15                   )
    )
    positron_inst(
    
        // System signals
        .clk     ( tb_clk           ),
        .rst_n   ( tb_reset_n       ),
        
        // SLAVE SIDE
        
        // control signals
        .rtr_o   ( s_axis_in_tready ),
        .rts_i   ( s_axis_in_tvalid ),
        .sow_i   ( sow_i            ),
        .eow_i   ( s_axis_in_tlast  ),
        
        .posit_i ( s_axis_in_tdata  ),
        
        
        // MASTER SIDE
            
        // control signals
        .rtr_i   ( 1'b1             ),
        .rts_o   ( rts_o            ),
        .eow_o   ( eow_o            ),
        .sow_o   ( sow_o            ),
        
        .posit_o ( posit_o          )
    );

    //----------------------------------------------------------------
    // clk_gen
    //
    // Always running clock generator process.
    //----------------------------------------------------------------
    always
    begin : clk_gen
        #CLK_HALF_PERIOD;
        tb_clk = !tb_clk;
    end // clk_gen
    

    //----------------------------------------------------------------
    // reset_dut()
    //
    // Toggle reset to put the DUT into a well known state.
    //----------------------------------------------------------------
    task reset_dut;
        begin
            $display("*** Toggle reset.");
            tb_reset_n = 0;
            #(2 * CLK_PERIOD);
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

        reset_dut();
        init_sim();
        
        start = 1;
        
    end
    
endmodule