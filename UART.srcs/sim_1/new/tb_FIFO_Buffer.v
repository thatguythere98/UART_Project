`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:
// Design Name:
// Module Name:
// Project Name:
// Target Devices:
// Tool Versions:
// Description: Testbench, not up to date.
//
// Dependencies: 
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module tb_FIFO;
  //parameters

  parameter DATA_WIDTH = 8;
  parameter ADDR_WIDTH = 4;

  //signals
  reg clk;
  reg rst;
  reg wr_en;
  reg rd_en;
  reg [DATA_WIDTH-1:0] data_in;
  wire [DATA_WIDTH-1:0] data_out;
  wire full;
  wire empty;

  //instantiate FIFO

  fifo #(DATA_WIDTH, ADDR_WIDTH) dut (
         .clk  (clk),
         .rst  (rst),
         .wr_en(wr_en),
         .rd_en(rd_en),
         .data (data_in),
         .dout (data_out),
         .full (full),
         .empty(empty)
       );


  //Clock
  always #5 clk = ~clk;

  //Initial Block
  initial
  begin
    clk = 0;
    rst = 1;
    wr_en = 0;
    rd_en = 0;
    data_in = 0;

    //reset
    #10;
    rst = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;

    //Write to FIFO
    #10;
    wr_en   = 1;
    data_in = 8'hA1;
    #10;
    //rd_en = 1;
    data_in = 8'hFF;
    #10;
    data_in = 8'h00;
    #10;
    data_in = 8'h53;
    #10;
    wr_en = 0;

    //read from FIFO
    #10;
    rd_en = 1;
    #100;
    rd_en = 0;





    #100;
    $stop;

  end



endmodule
