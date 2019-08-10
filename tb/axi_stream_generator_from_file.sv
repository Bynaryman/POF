`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BSC
// Engineer: Ledoux Louis
// 
// Create Date: 11/27/2018 11:35:24 AM
// Design Name: 
// Module Name: axi_stream_generator_from_file
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Generate (push) data with axi stream protocol from a txt file.
//               Aims to help for test bench to test axi stream compliant modules
//
// Example 1) posit 16,1
// data[31:0] = 31.......20...19..18.........17.........6......5......0
//            = 000000:sign:zero:NaR:fraction11:fraction0:scale5:scale0
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module axi_stream_generator_from_file #
(
    parameter WIDTH = 32,
    parameter string base_path = "/home/lledoux/Desktop/PhD/fpga/my_posits/my_posits.srcs/sim_1/new/",
    parameter string path = "quire_inputs_maxminpos.txt",
    parameter integer nb_data = 16,
    parameter READ_B_OR_H = "H"
)
(
    input wire rst_n,
    input wire start,

    input  wire m_axis_clk,
    output logic m_axis_tvalid,
    output logic [WIDTH-1:0] m_axis_tdata,
    output logic [(WIDTH+7/8)-1:0]m_axis_tstrb,
    output logic m_axis_tlast
);  
  typedef enum logic [1:0] { IDLE, SEND_STREAM } State;
  
  State sm_state = IDLE;
  
  // Axi Stream internal signals
  logic tvalid;
  logic tlast;
  logic [WIDTH-1:0] tdata;
  
  
  assign m_axis_tdata  = tdata;
  assign m_axis_tvalid = tvalid;
  assign m_axis_tstrb  = {(WIDTH+7/8){1'b1}};
  assign m_axis_tlast  = tlast;
  
  // file data
  logic [WIDTH-1:0] file_data [nb_data-1:0];
  if (READ_B_OR_H == "H") begin
      initial $readmemh({base_path, path}, file_data);
  end
  else if (READ_B_OR_H == "B") begin
      initial $readmemb({base_path, path}, file_data);
  end
  logic [$clog2(nb_data)-1:0] counter;
  
  always_ff @(posedge m_axis_clk) begin
      if ( ~rst_n ) begin
          sm_state <= IDLE;
      end
      else begin
          case (sm_state)
              IDLE: begin
                  tvalid <= 0;
                  tlast  <= 0;
                  tdata  <= 0;
                  counter <= 0;
                  if (start) begin
                      sm_state <= SEND_STREAM;
                  end
              end
              
              SEND_STREAM: begin
                  tvalid <= 1;
                  tdata  <= file_data[counter];
                  if ( start ) begin
                      counter <= counter + 1;
                  end
//                  if ( start ) begin
//                      tdata <= file_data[counter];
//                  end
                  if ( ~start ) begin
                      tdata <= file_data[counter-1];
                  end
                  if (counter == nb_data-1) begin
                      tlast <= 1;
                      sm_state <= IDLE;
                  end
              end    
              
              default: begin
                  sm_state <= IDLE;
              end
          endcase
      end
  end
  
endmodule
