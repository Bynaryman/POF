`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: LEDOUX Louis
// 
// Create Date: 01/10/2019 02:59:11 PM
// Design Name: 
// Module Name: tb_adder
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

module tb_adder();

    parameter CLK_PERIOD      = 2;
    parameter CLK_HALF_PERIOD = CLK_PERIOD / 2;
    
    localparam integer POSIT_WIDTH = 8;
    localparam integer POSIT_ES = 0;

    localparam string BASE_PATH   = "/home/lledoux/Desktop/PhD/fpga/P9_OPC/my_posits/tb/vectors/";
    
    localparam string INPUT_PATH  = "adder_input_vector.txt0";   // input vector generated by python
    localparam string OUTPUT_PATH = "adder_output_vector.txt0";  // output vector generated by python
    
    localparam integer NB_TEST = 10710;
    
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
    logic [2*POSIT_WIDTH-1:0] s_axis_in_tdata;  // reading operand A and B at once. A POSIT_WIDTH MSB
    logic [(2*POSIT_WIDTH/8)-1:0] s_axis_in_tstrb;
    logic s_axis_in_tlast;
    logic sow_i;
    //logic rts_o;
    //logic eow_o;
    //logic sow_o;
    logic [POSIT_WIDTH-1:0] posit_o;
    
    // Read as stream the input vector
    axi_stream_generator_from_file #
    (
        .WIDTH       ( 2*POSIT_WIDTH ),  // reading operand A and B at once. A POSIT_WIDTH MSB
        .base_path   ( BASE_PATH     ),
        .path        ( INPUT_PATH    ),
        .nb_data     ( NB_TEST       ),
        .READ_B_OR_H ( "B"           )
    )
    axi_stream_generator_inst 
    (
       
       .rst_n         ( tb_reset_n       ),
       // Starts an axi_stream transaction
       .start         ( tb_reset_n       ),  //  in std_logic; 
    
       // axi stream ports
       .m_axis_clk    ( tb_clk           ),  //  in  std_logic;
       .m_axis_tvalid ( s_axis_in_tvalid ),  //  out std_logic;
       .m_axis_tdata  ( s_axis_in_tdata  ),  //  out std_logic_vector(31 downto 0);
       .m_axis_tstrb  ( s_axis_in_tstrb  ),  //  out std_logic_vector(3 downto 0);
       .m_axis_tlast  ( s_axis_in_tlast  )   //  out std_logic  
    );
    
    // Read as full memory output vector for comparisons
    logic [POSIT_WIDTH-1:0] output_vector [0:NB_TEST-1];
    initial $readmemb({BASE_PATH, OUTPUT_PATH}, output_vector);

    
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
    
    logic [31:0] counter;
    always_ff @(posedge tb_clk or negedge tb_reset_n) begin
        if ( ~tb_reset_n ) begin
            counter <= 0;
        end
        else if ( s_axis_in_tvalid ) begin
            if ( sow_i ) begin
                counter <= 1;
            end
            else if ( counter ==  NB_TEST-1) begin
                counter <= 0;
            end
            else begin
                counter <= counter + 1;
            end
        end
    end
    
    // instanciate DUT, interfaces, denormalize and nomalize + roundig <=> FULL adder
    pd #( 
        .POSIT_WIDTH ( POSIT_WIDTH ),
        .POSIT_ES    ( POSIT_ES    ),
        .PD_TYPE     ( NORMAL )
    ) opA();
    
    pd #( 
        .POSIT_WIDTH ( POSIT_WIDTH ),
        .POSIT_ES    ( POSIT_ES    ),
        .PD_TYPE     ( NORMAL      )
    ) opB();
    
    posit_denormalize_I # ( 
        .POSIT_WIDTH ( POSIT_WIDTH ),
        .POSIT_ES    ( POSIT_ES    )
    ) opA_denormalizer (
        .posit_word_i ( s_axis_in_tdata[2*POSIT_WIDTH-1:POSIT_WIDTH] ),  // MSB half
        .denormalized ( opA )
    );
    
    posit_denormalize_I # ( 
        .POSIT_WIDTH ( POSIT_WIDTH ),
        .POSIT_ES    ( POSIT_ES    )
    ) opB_denormalizer (
        .posit_word_i ( s_axis_in_tdata[POSIT_WIDTH-1:0] ),  // LSB half
        .denormalized ( opB )
    );
    
    pd #( 
        .POSIT_WIDTH ( POSIT_WIDTH ),
        .POSIT_ES    ( POSIT_ES    ),
        .PD_TYPE     ( AADD        )
    ) opC();
    
    posit_adder #( 
        .POSIT_WIDTH ( POSIT_WIDTH ),
        .POSIT_ES    ( POSIT_ES    )
    ) posit_adder_inst (
        .operand1 ( opA ),
        .operand2 ( opB ),
        .result   ( opC )
    );
    
    posit_normalize_I # ( 
        .POSIT_WIDTH   ( POSIT_WIDTH ),
        .POSIT_ES      ( POSIT_ES    ),
        .PD_TYPE       ( AADD        ),
        .ROUNDING_MODE ( RNTE        )
    ) opC_normalizer (
        .denormalized ( opC     ),
        .posit_word_o ( posit_o )
    );
    
    always_ff @(posedge tb_clk or negedge tb_reset_n) begin
        if (tb_reset_n) begin
            if (posit_o[POSIT_WIDTH-1:0] !== output_vector[counter][POSIT_WIDTH-1:0] & s_axis_in_tvalid) begin
                $display("@", $time, " obtained: %b, expected: %b", posit_o[POSIT_WIDTH-1:0], output_vector[counter][POSIT_WIDTH-1:0]);
                $finish();
            end     
        end
    end
     
        

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
            #(200 * CLK_PERIOD);
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
