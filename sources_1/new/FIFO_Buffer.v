`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:
// Design Name: FIFO Buffer
// Module Name: fifo
// Project Name: UART Project
// Target Devices: Cmod A7 35T FPGA
// Tool Versions: Vivado 2024.1
// Description:
//      Parameterizable FIFO buffer used for UART transmit and receive operations.
//      The depth and data width are determined by parameters `ADDR_WIDTH` and
//      `DATA_WIDTH` respectively. The module manages read and write pointers,
//      tracks the FIFO state (full or empty), and handles simultaneous read/write.
//
// Dependencies:
//      None
//
// Revision History:
//      Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module fifo #(
    parameter DATA_WIDTH = 8,  // Data width (number of bits per data word)
    parameter ADDR_WIDTH = 4   // Address width (determines FIFO depth)
  ) (
    input wire                  clk,     // System clock
    input wire                  rst,     // Synchronous reset
    input wire                  wr_en,   // Write enable
    input wire                  rd_en,   // Read enable
    input wire [DATA_WIDTH-1:0] data,    // Data input bus

    output wire [DATA_WIDTH-1:0] dout,   // Data output bus
    output wire                  full,   // FIFO full flag
    output wire                  empty   // FIFO empty flag
  );

  // Calculate FIFO depth based on address width
  localparam DEPTH = 1 << ADDR_WIDTH;

  // Memory array for storing data (block RAM preferred)
  reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  // Registers for write pointer, read pointer, and count (with an extra bit for full/empty detection)
  reg [ADDR_WIDTH-1:0] wr_ptr, next_wr_ptr;
  reg [ADDR_WIDTH-1:0] rd_ptr, next_rd_ptr;
  reg [ADDR_WIDTH:0] fifo_cnt, next_fifo_cnt;  // One extra bit for full/empty status tracking

  // Combinational outputs
  assign full  = (fifo_cnt == DEPTH);   // Full flag when FIFO count reaches depth
  assign empty = (fifo_cnt == 0);       // Empty flag when FIFO count is zero
  assign dout = mem[rd_ptr];            // Output the data at the read pointer

  // Sequential logic to update FIFO state (pointers, count, and memory)
  always @(posedge clk)
  begin
    if (rst)
    begin
      // Reset the pointers and counter on synchronous reset
      wr_ptr <= 0;
      rd_ptr <= 0;
      fifo_cnt <= 0;
    end
    else
    begin
      // Update the state based on the next state logic
      wr_ptr <= next_wr_ptr;
      rd_ptr <= next_rd_ptr;
      fifo_cnt <= next_fifo_cnt;
    end
  end

  // Synchronous memory write operation
  always @(posedge clk)
  begin
    if (!rst && wr_en && !full)
    begin
      mem[wr_ptr] <= data;  // Write data to memory if write enabled and FIFO is not full
    end
  end

  // Combinational logic for next pointer values and FIFO count
  always @(*)
  begin
    // Default to retaining the current state
    next_wr_ptr = wr_ptr;
    next_rd_ptr = rd_ptr;
    next_fifo_cnt = fifo_cnt;

    // Handle simultaneous read and write
    if (wr_en && rd_en)
    begin
      if (!empty)
      begin
        next_rd_ptr = rd_ptr + 1;  // Increment read pointer
      end
      if (!full)
      begin
        next_wr_ptr = wr_ptr + 1;  // Increment write pointer
      end
    end
    // Handle write-only operation
    else if (wr_en && !full)
    begin
      next_wr_ptr = wr_ptr + 1;      // Increment write pointer
      next_fifo_cnt = fifo_cnt + 1;  // Increment FIFO count
    end
    // Handle read-only operation
    else if (rd_en && !empty)
    begin
      next_rd_ptr = rd_ptr + 1;      // Increment read pointer
      next_fifo_cnt = fifo_cnt - 1;  // Decrement FIFO count
    end
  end

endmodule
