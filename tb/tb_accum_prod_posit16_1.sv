`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: Ledoux Louis
// 
// Create Date: 11/30/2018 10:09:44 AM
// Design Name: 
// Module Name: tb_accum_prod_posit16_1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: test bench chaining posit16_1 mult and accumulate after
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_accum_prod_posit16_1();

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
    logic [63:0] s_axis_in_tdata;
    logic [7:0] s_axis_in_tstrb;
    logic s_axis_in_tlast;
    logic sow_i;
    logic rts_o;
    logic eow_o;
    logic sow_o;
    
    // input signals
    logic [5:0] scale1, scale2;
    logic [11:0]fraction1, fraction2;
    logic sign1, sign2;
    logic NaR1, NaR2;
    logic zero1, zero2;
    
    // output signals from multiplication
    logic [6:0] scale_o;
    logic [25:0] fraction_o;
    logic sign_o;
    logic NaR_o;
    logic zero_o;
    
    // output signals from accumulation
    logic sow_accum_o;
    logic eow_accum_o;
    logic rts_accum_o;
    logic tready_accum;
    logic [127:0] quire_o;
    
    axi_stream_generator_from_file  #
    (
        .WIDTH(64),
        .path("posits_inputs_mult16_1.txt")
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

    
    assign scale1    = s_axis_in_tdata[5:0];
    assign fraction1 = s_axis_in_tdata[17:6];
    assign sign1     = s_axis_in_tdata[20];
    assign NaR1      = s_axis_in_tdata[18];
    assign zero1     = s_axis_in_tdata[19];
   
    // add 32 bit offset for the second posit
    assign scale2    = s_axis_in_tdata[5+32:0+32];
    assign fraction2 = s_axis_in_tdata[17+32:6+32];
    assign sign2     = s_axis_in_tdata[20+32];
    assign NaR2      = s_axis_in_tdata[18+32];
    assign zero2     = s_axis_in_tdata[19+32];

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
    
    // instanciate DUT posit mult
    posit_mult_16_1 posit_mult_16_1(
    
        // System signals
        .clk         ( tb_clk           ),
        .rst_n       ( tb_reset_n       ),
        
        // SLAVE SIDE
        
        // control signals
        .rtr_o       ( s_axis_in_tready ),
        .rts_i       ( s_axis_in_tvalid ),
        .sow_i       ( sow_i            ),
        .eow_i       ( s_axis_in_tlast  ),
        
        // input posit 1
        .fraction_i1 ( fraction1        ),
        .scale_i1    ( scale1           ),
        .NaR_i1      ( NaR1             ),
        .zero_i1     ( zero1            ),
        .sign_i1     ( sign1            ),
       
        // input posit 2
        .fraction_i2 ( fraction2        ),
        .scale_i2    ( scale2           ),
        .NaR_i2      ( NaR2             ),
        .zero_i2     ( zero2            ),
        .sign_i2     ( sign2            ),
        
        // MASTER SIDE
        
        // control signals
        .rtr_i       ( tready_accum     ),
        .rts_o       ( rts_o            ),
        .eow_o       ( eow_o            ),
        .sow_o       ( sow_o            ),
        
        // output posit
        .fraction_o  ( fraction_o       ),
        .scale_o     ( scale_o          ),
        .NaR_o       ( NaR_o            ),
        .sign_o      ( sign_o           ),
        .zero_o      ( zero_o           )
    
    );
    
    
    // instanciate DUT
    quire16_1  #
    (
        .FRACTION_WIDTH ( 26 ),
        .SCALE_WIDTH    ( 7  )
    )
    quire16_1_inst(

        // System signals
        .clk      ( tb_clk                ),
        .rst_n    ( tb_reset_n            ),

        // Slave side
        .rtr_o    ( tready_accum          ),
        .rts_i    ( rts_o                 ),
        .sow_i    ( sow_o                 ),
        .eow_i    ( eow_o                 ),
        .fraction ( fraction_o            ),
        .scale    ( scale_o               ),
        .zero_i   ( zero_o                ),
        .sign_i   ( sign_o                ),
        .NaR_i    ( NaR_o                 ),

        // Master side
        .rtr_i    ( 1                     ), // always ready since it is a test bench
        .rts_o    ( rts_accum_o           ),
        .eow_o    ( eow_accum_o           ),
        .sow_o    ( sow_accum_o           ),
        .data_o   ( quire_o               )

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
