`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:
// Design Name: Baud Generator
// Module Name: baud_generator
// Project Name: UART Project
// Target Devices: Cmod A7 35T FPGA
// Tool Versions: Vivado 2024.1
// Description:
//      This module generates a baud rate signal based on the selected divider value.
//      It expects a 11.0592 MHz clock input and outputs a signal that is 16 times the
//      selected baud rate. Supported baud rates are 9600, 19200, 38400, 57600, and
//      115200.
//
// Dependencies:
//      None
//
// Revision History:
//      Revision 0.01 - File Created
//
// Additional Comments:
//
//
//////////////////////////////////////////////////////////////////////////////////

module baud_generator (
    input wire       clk,            // System clock
    input wire       rst,            // Synchronous reset
    input wire [2:0] sel,            // Baud rate selection
    output reg       baud16x_out     // Output signal at 16x the baud rate
  );

  // Internal signals
  reg [6:0] count, next_count;                // Counter for generating baud16x_out
  reg [6:0] divider_calc, next_divider_calc;  // Divider value based on selected baud rate
  reg next_baud16x_out;                       // Next state for baud16x_out

  // Define constants for divider values for 11.0592 MHz clock
  localparam [11:0] DIV_9600   = 12'd72;
  localparam [11:0] DIV_19200  = 12'd36;
  localparam [11:0] DIV_38400  = 12'd18;
  localparam [11:0] DIV_57600  = 12'd12;
  localparam [11:0] DIV_115200 = 12'd6;

  // Baud rate divider selection logic
  always @(*)
  begin
    case (sel)
      3'b000:
        next_divider_calc = DIV_9600;     // 9600 baud
      3'b001:
        next_divider_calc = DIV_19200;    // 19200 baud
      3'b010:
        next_divider_calc = DIV_38400;    // 38400 baud
      3'b011:
        next_divider_calc = DIV_57600;    // 57600 baud
      3'b100:
        next_divider_calc = DIV_115200;   // 115200 baud
      default:
        next_divider_calc = DIV_9600;    // Default to 9600 baud
    endcase
  end

  // Combinational logic for counter and baud16x_out
  always @(*)
  begin
    // Default values
    next_count = count;
    next_baud16x_out = 1'b0;   // Default output low

    // Check if counter reaches the divider value
    if (count >= (divider_calc - 1))
    begin
      next_count = 12'd0;          // Reset counter
      next_baud16x_out = 1'b1;     // Pulse the baud16x_out signal
    end
    else
    begin
      next_count = count + 1;      // Increment counter
      next_baud16x_out = 1'b0;     // Keep output low
    end
  end

  // Sequential logic to update registers
  always @(posedge clk)
  begin
    if (rst)
    begin
      count        <= 12'd0;         // Reset counter
      baud16x_out  <= 1'b0;          // Reset baud16x_out
      divider_calc <= DIV_9600;      // Default divider for 9600 baud
    end
    else
    begin
      count        <= next_count;       // Update counter
      baud16x_out  <= next_baud16x_out; // Update baud16x_out
      divider_calc <= next_divider_calc; // Update divider based on selection
    end
  end

endmodule
