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

module tb_SignalDebounce;

  // Inputs
  reg clk;
  reg button_in;

  // Outputs
  wire out;

  // Instantiate the Device Under Test (DUT)
  SignalDebounce DUT (
                   .clk(clk),
                   .button_in(button_in),
                   .button_out(out)
                 );

  // Clock generation (12 MHz clock)
  always
  begin
    #41.67 clk = ~clk;  // 12 MHz clock => 83.33 ns period, so half-period is 41.67 ns
  end

  initial
  begin
    // Initialize the clock and button input
    clk = 0;
    button_in = 0; // Active-high button, so 0 is idle (not pressed)

    // Test case 1: Button pressed, held, and released with bouncing

    #50_000_000; // Wait 50 ms
    button_in = 1; // Button press (active-high)
    // Simulate bounce for 10 ms
    repeat(10)
    begin
      #500_000;
      button_in = 0; // Simulate bounce (0.5 ms low)
      #500_000;
      button_in = 1; // Simulate bounce (0.5 ms high)
    end

    #100_000_000; // Hold button for 100 ms
    button_in = 0; // Button release (goes idle)
    // Simulate bounce for 10 ms
    repeat(10)
    begin
      #500_000;
      button_in = 1; // Simulate bounce (0.5 ms high)
      #500_000;
      button_in = 0; // Simulate bounce (0.5 ms low)
    end

    // Test case 2: Quick button press and release with bounce

    #10_000_000; // Wait 10 ms
    button_in = 1; // Quick press (active-high)
    // Simulate bounce for 10 ms
    repeat(10)
    begin
      #500_000;
      button_in = 0; // Simulate bounce (0.5 ms low)
      #500_000;
      button_in = 1; // Simulate bounce (0.5 ms high)
    end

    #5_000_000; // Hold for 5 ms
    button_in = 0; // Quick release (idle)
    // Simulate bounce for 10 ms
    repeat(10)
    begin
      #500_000;
      button_in = 1; // Simulate bounce (0.5 ms high)
      #500_000;
      button_in = 0; // Simulate bounce (0.5 ms low)
    end

    // Finish simulation
    #100_000_000; // Wait for 100 ms
    $finish;
  end
endmodule
