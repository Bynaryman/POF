`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: LEDOUX Louis
// 
// Create Date: 12/18/2018 10:58:16 AM
// Design Name: 
// Module Name: tb_normalize_quire
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


module tb_normalize_quire();

    localparam CLK_PERIOD      = 2;
    localparam CLK_HALF_PERIOD = CLK_PERIOD / 2;

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
    logic [127:0] s_axis_in_tdata;
    logic [7:0] s_axis_in_tstrb;
    logic s_axis_in_tlast;
    logic sow_i;
    logic [15:0] posit_o;
  
    

    
    axi_stream_generator_from_file  #
    (
        .WIDTH       ( 128 ),
        .path        ("quire128_16_1_out.txt"),
        .nb_data     ( 10  ),
        .READ_B_OR_H ( "B" )
    ) axi_stream_generator_inst
    (
    
        // Starts an axi_stream transaction
        .start                        ( s_axis_in_tready ),  //  in std_logic; 
        
        // axi stream ports
        .m_axis_clk                   ( tb_clk           ),  // in  std_logic;
        .m_axis_tvalid                ( s_axis_in_tvalid ),  //  out std_logic;
        .m_axis_tdata                 ( s_axis_in_tdata  ),  //  out std_logic_vector(31 downto 0);
        .m_axis_tstrb                 ( s_axis_in_tstrb  ),  //  out std_logic_vector(3 downto 0);
        .m_axis_tlast                 ( s_axis_in_tlast  )   //  out std_logic  
    );

    
    // tmp hack
    assign s_axis_in_tready = 1;

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
    
    // instanciate DUT normalize QUIRE
    posit_normalize_quire # 
    (
        .QUIRE_IN_WIDTH  ( 128 ),
        .POSIT_OUT_WIDTH ( 16  ),
        .POSIT_IN_WIDTH  ( 16  ),
        .POSIT_IN_ES     ( 1   )
    ) posit_normalize_quire_128_inst
    (
        // System signals
        .clk     ( tb_clk     ),
        .rst_n   ( tb_reset_n ),
        
        // SLAVE SIDE
        
        // control signals
        .rtr_o   ( ),
        .rts_i   ( ),
        .sow_i   ( ),
        .eow_i   ( ),
        
        .quire_i ( s_axis_in_tdata ) ,
        
        
        // MASTER SIDE
            
        // control signals
        .rtr_i   ( ),
        .rts_o   ( ),
        .eow_o   ( ),
        .sow_o   ( ),
        
        .posit_o ( posit_o ) 
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
