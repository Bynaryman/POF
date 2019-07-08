`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/11/2018 05:46:15 PM
// Design Name: 
// Module Name: tb_weights_ROM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: test bench for weights generation from ROM
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_weights_ROM();


    parameter CLK_PERIOD      = 2;
    parameter CLK_HALF_PERIOD = CLK_PERIOD / 2;
    parameter POSIT_WIDTH     = 16;
    parameter NB_WEIGHTS      = 784; // MNIST example (28*28) 
    
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
    logic [(POSIT_WIDTH/8)-1:0] s_axis_in_tstrb;
    logic s_axis_in_tlast;
    logic sow_i;
    logic rts_o;
    logic eow_o;
    logic sow_o;
    
    logic [POSIT_WIDTH-1:0] posit_o;
    
    // logic for address generation
    logic [log2(NB_WEIGHTS)-1:0] address_i;
    
    axi_stream_generator_from_file #
    (
       .WIDTH     ( log2(NB_WEIGHTS) ),
       .base_path ( "/home/lledoux/Desktop/PhD/fpga/my_posits/my_posits.srcs/sim_1/new/" ),
       .path      ( "address.txt"    ),
       .nb_data   ( NB_WEIGHTS       )
    )
    axi_stream_generator_inst 
    (
         
       // Starts an axi_stream transaction
       .start                        ( s_axis_in_tready ),  //  in std_logic; 
   
       // axi stream ports
       .m_axis_clk                   ( tb_clk           ),  //  in  std_logic;
       .m_axis_tvalid                ( s_axis_in_tvalid ),  //  out std_logic;
       .m_axis_tdata                 ( address_i        ),  //  out std_logic_vector(31 downto 0);
       .m_axis_tstrb                 ( s_axis_in_tstrb  ),  //  out std_logic_vector(3 downto 0);
       .m_axis_tlast                 ( s_axis_in_tlast  )   //  out std_logic  
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
    weights_ROM #
    (
        .DELAY       ( 2                ),
        .PATH        ( "/home/lledoux/Desktop/PhD/ML/C/mnist-3lnn/hidden_weights/hidden_weights_1" ),
        .POSIT_WIDTH ( POSIT_WIDTH      ),
        .NB_WEIGHTS  ( NB_WEIGHTS       )
    )
    weights_ROM_inst
    (
        // System signals
        .clk         ( tb_clk           ),
        .rst_n       ( tb_reset_n       ),
        
        // SLAVE SIDE
        
        // control signals
        .rtr_o       ( s_axis_in_tready ),
        .rts_i       ( s_axis_in_tvalid ),
        .sow_i       ( sow_i            ),
        .eow_i       ( s_axis_in_tlast  ),
        // add
        .address_i   ( address_i        ),
        
        // MASTER SIDE
                
        // control signals
        .rtr_i       ( 1                ), // simulate a downstream module always ready
        .rts_o       ( rts_o            ),
        .eow_o       ( eow_o            ),
        .sow_o       ( sow_o            ),
        // posit out
        .posit_o     ( posit_o          )
        
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
