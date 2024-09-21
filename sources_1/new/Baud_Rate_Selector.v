`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:
// Design Name: Baud Rate Selector
// Module Name: baud_sel
// Project Name: UART Project
// Target Devices: Cmod A7 35T FPGA
// Tool Versions: Vivado 2024.1
// Description:
//      This module toggles between different baud rates with each button press.
//      It loops back to the lowest baud rate (9600) after reaching the highest
//      baud rate (115200). The design supports 5 baud rates, with selections
//      mapped to `sel`.
//
// Dependencies:
//      None
//
// Revision History:
//      Revision 0.01 - File Created
//
//////////////////////////////////////////////////////////////////////////////////

module baud_sel(
    input wire clk,           // System clock
    input wire rst,           // System reset, active high
    input wire button_in,     // Button input for toggling baud rate
    output reg [2:0] sel      // Baud rate selection output (3-bit encoding)
  );

  // Internal signal to store the previous state of button_in
  reg button_last = 0;
  // Detect rising edge of button press
  wire button_pressed = (button_in && !button_last);

  // Baud rate selection logic
  always @(posedge clk)
  begin
    if (rst)
    begin
      sel <= 3'b000;  // Reset to 9600 baud (first rate)
    end
    else if (button_pressed)
    begin
      if (sel == 3'b100)  // If max baud rate (115200) is reached, wrap back to 9600
        sel <= 3'b000;
      else
        sel <= sel + 1;   // Increment to the next baud rate
    end
    // Update the last button state for edge detection
    button_last <= button_in;
  end

endmodule
