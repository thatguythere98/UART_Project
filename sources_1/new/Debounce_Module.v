`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 
// Design Name: Debounce Module
// Module Name: signal_debounce
// Project Name: UART Project
// Target Devices: Cmod A7 35T FPGA
// Tool Versions: Vivado 2024.1
// Description:
//      This module implements a debounce mechanism for a button input. It
//      synchronizes the button input to the clock domain and counts clock cycles
//      to filter out bouncing effects.
//
// Dependencies:
//      None
//
// Revision History:
//      Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module signal_debounce (
    input wire clk,            // System clock
    input wire button_in,      // Asynchronous button input
    output reg button_out = 0  // Debounced button output
  );

  // Internal registers for synchronizing button input and debouncing
  reg button_sync;             // First synchronization stage
  reg button_sync2;            // Second synchronization stage
  reg [17:0] counter;          // Counter to filter bouncing
  wire button_max_count;       // Signal to check if counter has reached its max

  // Assign the max count signal to indicate when the counter is fully set (all bits are 1)
  assign button_max_count = &counter;

  // Synchronize the button input to the clock domain using two flip-flops
  always @(posedge clk)
  begin
    button_sync <= button_in;  // First synchronization register
    button_sync2 <= button_sync; // Second synchronization register
  end

  // Debouncing logic: increment the counter if input changes, reset counter otherwise
  always @(posedge clk)
  begin
    if (button_sync2 == button_out)
    begin
      counter <= 0;            // Reset counter if input is stable
    end
    else
    begin
      counter <= counter + 1;   // Increment counter if input changes
    end

    // Update button output once the counter has reached its maximum value
    if (button_max_count)
    begin
      button_out <= button_sync2;
    end
  end

endmodule
