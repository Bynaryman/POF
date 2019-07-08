`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/28/2019 02:28:12 PM
// Design Name: 
// Module Name: tb_axis_8b_to_4b
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


module tb_axis_8b_to_4b();

    parameter CLK_PERIOD      = 2;
    parameter CLK_HALF_PERIOD = CLK_PERIOD / 2;
    
    localparam integer IN_WIDTH  = 8;
    localparam integer OUT_WIDTH = 4;
        
    localparam string INPUT_VALUES_PATH = "/home/lledoux/Desktop/PhD/fpga/my_posits/my_posits.srcs/sim_1/new/8_to_4_values.raw";
    
    
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
    logic [IN_WIDTH-1:0] s_axis_in_tdata;
    logic s_axis_in_tlast;
    
    // out DUT signals
    logic rts_o;
    logic sow_o;
    logic eow_o;
    logic [OUT_WIDTH-1:0] data_o;
    

    axi_stream_generator_from_file #
    (
        .WIDTH ( IN_WIDTH ),
        .base_path ( INPUT_VALUES_PATH ),
        .path ( "" ),
        .nb_data ( 3 ),
        .READ_B_OR_H ( "H" )
    )
    axi_stream_generator_inst 
    (
       .rst_n ( tb_reset_n),
       // Starts an axi_stream transaction
       .start         ( s_axis_in_tready ),  //  in std_logic; 
    
       // axi stream ports
       .m_axis_clk    ( tb_clk           ),  //  in  std_logic;
       .m_axis_tvalid ( s_axis_in_tvalid ),  //  out std_logic;
       .m_axis_tdata  ( s_axis_in_tdata  ),  //  out std_logic_vector(31 downto 0);
       .m_axis_tstrb  (                  ),  //  out std_logic_vector(3 downto 0);
       .m_axis_tlast  ( s_axis_in_tlast  )   //  out std_logic  
    );
    
    // logic for sow
    logic s_axis_in_tvalid_r;
    logic sow_i;
    always_ff @(posedge tb_clk or negedge tb_reset_n) begin
        if ( ~tb_reset_n ) begin
            s_axis_in_tvalid_r <= 0;
        end
        else begin
            s_axis_in_tvalid_r <= s_axis_in_tvalid;
        end
    end
    assign sow_i   = s_axis_in_tvalid & ~s_axis_in_tvalid_r;
    
    pkt_txbusif #(
        .DATAi_W        ( IN_WIDTH  ),
        .DATAo_W        ( OUT_WIDTH ),
        .FIFO_DEPTH     ( 8         ),
        .FIFO_LOG_DEPTH ( 3         )
    ) pkt_txbusif_inst
    (
        // System signals
        .clk   ( tb_clk      ),
        .rst_n ( tb_reset_n  ),
                
        // Slave
        .off_rtr   ( s_axis_in_tready ),
        .iff_rts   ( s_axis_in_tvalid ),
        .iff_sow   (             ),
        .iff_eow   ( s_axis_in_tlast  ),
        .iff_data  ( s_axis_in_tdata  ),
        
        // Master
        .rtr_i  ( 1      ),
        .rts_o  ( rts_o  ),
        .sow_o  ( sow_o  ),
        .eow_o  ( eow_o  ),
        .data_o ( data_o )
        
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
