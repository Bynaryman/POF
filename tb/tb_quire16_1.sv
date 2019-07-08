`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/22/2018 05:13:44 PM
// Design Name: 
// Module Name: tb_quire16_1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//     test bench for quire 16 bits exponent size 1
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_quire16_1();

    parameter CLK_PERIOD      = 2;
    parameter CLK_HALF_PERIOD = CLK_PERIOD / 2;
    
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
    logic [31:0] s_axis_in_tdata;
    logic [3:0] s_axis_in_tstrb;
    logic s_axis_in_tlast;
    logic sow_i;
    logic rts_o;
    logic eow_o;
    logic sow_o;
    
    logic [5:0] scale;
    logic [11:0]fraction;
    logic sign;
    logic NaR;
    logic zero;
    logic [127:0] quire_out;

    
    // instanciate axi stream generator
    // axi_stream_generator axi_stream_generator_inst (
    //  
    //    // Starts an axi_stream transaction
    //    .start                        ( s_axis_in_tready ),  //  in std_logic; 
    // 
    //    // axi stream ports
    //    .m_axis_clk                   ( tb_clk           ),  // in  std_logic;
    //    .m_axis_tvalid                ( s_axis_in_tvalid ),  //  out std_logic;
    //    .m_axis_tdata                 ( s_axis_in_tdata  ),  //  out std_logic_vector(31 downto 0);
    //    .m_axis_tstrb                 ( s_axis_in_tstrb  ),  //  out std_logic_vector(3 downto 0);
    //    .m_axis_tlast                 ( s_axis_in_tlast  )   //  out std_logic  
    // );
     
     axi_stream_generator_from_file axi_stream_generator_inst 
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

    assign scale    = s_axis_in_tdata[5:0];
    assign fraction = s_axis_in_tdata[17:6];
    assign sign     = s_axis_in_tdata[20];
    assign NaR      = s_axis_in_tdata[18];
    assign zero     = s_axis_in_tdata[19];
    
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
    quire16_1 quire16_1_inst(

        // System signals
        .clk      ( tb_clk                ),
        .rst_n    ( tb_reset_n            ),

        // Slave side
        .rtr_o    ( s_axis_in_tready      ),
        .rts_i    ( s_axis_in_tvalid      ),
        .sow_i    ( sow_i                 ),
        .eow_i    ( s_axis_in_tlast       ),
        .fraction ( fraction              ),
        .scale    ( scale                 ),
        .zero_i   ( zero                  ),
        .sign_i   ( sign                  ),
        .NaR_i    ( NaR                   ),

        // Master side
        .rtr_i    ( 1                     ), // always ready since it is a test bench
        .rts_o    ( rts_o                 ),
        .eow_o    ( eow_o                 ),
        .sow_o    ( sow_o                 ),
        .data_o   ( quire_out             )

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
