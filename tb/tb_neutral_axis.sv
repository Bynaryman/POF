`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/27/2018 09:51:32 PM
// Design Name: 
// Module Name: tb_neutral_axis
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


module tb_neutral_axis();

parameter CLK_PERIOD      = 2;
parameter CLK_HALF_PERIOD = CLK_PERIOD / 2;

    //----------------------------------------------------------------
    // Signals, clocks, and reset
    //----------------------------------------------------------------
 
    logic tb_clk;
    logic tb_reset_n;
    
    logic start = 0;
    
    logic m_axis_out_aclk;
    logic m_axis_out_tready;;
    logic m_axis_out_aresetn;
    logic m_axis_out_tvalid;
    logic [31:0] m_axis_out_tdata;
    logic [3:0] m_axis_out_tstrb;
    logic m_axis_out_tlast;
    
    logic s_axis_in_aclk;
    logic s_axis_in_tready;
    logic s_axis_in_aresetn;
    logic s_axis_in_tvalid;
    logic [31:0] s_axis_in_tdata;
    logic [3:0] s_axis_in_tstrb;
    logic s_axis_in_tlast;
    
    //----------------------------------------------------------------
    // AXI Stream signals generator
    //----------------------------------------------------------------
     axi_stream_generator axi_stream_generator_inst (
     
       // Starts an axi_stream transaction
       .start                        ( start             ),  //  in std_logic; 
   
       // axi stream ports
       .m_axis_clk                   ( tb_clk            ),  // in  std_logic;
       .m_axis_tvalid                ( s_axis_in_tvalid ),  //  out std_logic;
       .m_axis_tdata                 ( s_axis_in_tdata  ),  //  out std_logic_vector(31 downto 0);
       .m_axis_tstrb                 ( s_axis_in_tstrb  ),  //  out std_logic_vector(3 downto 0);
       .m_axis_tlast                 ( s_axis_in_tlast  )   //  out std_logic  
     );

    //----------------------------------------------------------------
    // Device Under Test.
    //----------------------------------------------------------------
    neutral_axis_v1_0 # (
        // Parameters of Axi Slave Bus Interface S_AXIS_IN
        .C_S_AXIS_IN_TDATA_WIDTH     ( 32 ),

        // Parameters of Axi Master Bus Interface M_AXIS_OUT
        .C_M_AXIS_OUT_TDATA_WIDTH    ( 32 ),
        .C_M_AXIS_OUT_START_COUNT    ( 32 ),

        // Parameters of Axi Slave Bus Interface S_AXI_LITE_IN
        .C_S_AXI_LITE_IN_DATA_WIDTH  ( 32 ),
        .C_S_AXI_LITE_IN_ADDR_WIDTH  ( 4  )
    ) dut_inst (
        
        // Ports of Axi Slave Bus Interface S_AXIS_IN
        .s_axis_in_aclk              ( s_axis_in_aclk     ),
        .s_axis_in_aresetn           ( s_axis_in_aresetn  ),
        .s_axis_in_tready            ( s_axis_in_tready   ),
        .s_axis_in_tdata             ( s_axis_in_tdata    ),
        .s_axis_in_tstrb             ( s_axis_in_tstrb    ),
        .s_axis_in_tlast             ( s_axis_in_tlast    ),
        .s_axis_in_tvalid            ( s_axis_in_tvalid   ),

        // Ports of Axi Master Bus Interface M_AXIS_OUT
        .m_axis_out_aclk             ( m_axis_out_aclk    ),
        .m_axis_out_aresetn          ( m_axis_out_aresetn ),
        .m_axis_out_tvalid           ( m_axis_out_tvalid  ),
        .m_axis_out_tdata            ( m_axis_out_tdata   ),
        .m_axis_out_tstrb            ( m_axis_out_tstrb   ),
        .m_axis_out_tlast            ( m_axis_out_tlast   ),
        .m_axis_out_tready           ( m_axis_out_tready  ),

        // Ports of Axi Slave Bus Interface S_AXI_LITE_IN
        .s_axi_lite_in_aclk          (    ),
        .s_axi_lite_in_aresetn       (    ),
        .s_axi_lite_in_awaddr        (    ),
        .s_axi_lite_in_awprot        (    ),
        .s_axi_lite_in_awvalid       (    ),
        .s_axi_lite_in_awready       (    ),
        .s_axi_lite_in_wdata         (    ),
        .s_axi_lite_in_wstrb         (    ),
        .s_axi_lite_in_wvalid        (    ),
        .s_axi_lite_in_wready        (    ),
        .s_axi_lite_in_bresp         (    ),
        .s_axi_lite_in_bvalid        (    ),
        .s_axi_lite_in_bready        (    ),
        .s_axi_lite_in_araddr        (    ),
        .s_axi_lite_in_arprot        (    ),
        .s_axi_lite_in_arvalid       (    ),
        .s_axi_lite_in_arready       (    ),
        .s_axi_lite_in_rdata         (    ),
        .s_axi_lite_in_rresp         (    ),
        .s_axi_lite_in_rvalid        (    ),
        .s_axi_lite_in_rready        (    )
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
    
        assign m_axis_out_aclk    = tb_clk;
        assign m_axis_out_aresetn = tb_reset_n;
        assign s_axis_in_aclk    = tb_clk;
        assign s_axis_in_aresetn = tb_reset_n;
        
        assign m_axis_out_tready  = 1'b1;
        
        reset_dut();
        init_sim();
        
        start = 1;
        
    end

endmodule
