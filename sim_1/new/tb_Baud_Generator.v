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

module BaudGenerator_tb;

  reg clk = 0;
  reg rst;
  reg [2:0] sel;
  wire baud16x_out;

  // Instantiate the BaudGenerator module
  BaudGenerator dut (
                  .rst(rst),
                  .clk(clk),
                  .sel(sel),
                  .baud16x_out(baud16x_out)
                );

  // Clock generation
  always #67.815 clk = ~clk;  // 7.3728 MHz clock

  // Task to check pulse timing with tolerance
  task check_pulse_time;
    input [31:0] expected_pulse_ns;
    input [31:0] tolerance;
    reg [31:0] pulse_time;
    reg [31:0] last_pulse_time;
    begin
      // Wait for the first rising edge of baud16x_out
      @(posedge baud16x_out);
      last_pulse_time = $time;

      // Wait for the 16th rising edge
      repeat (16) @(posedge baud16x_out);
      pulse_time = $time - last_pulse_time;

      $display("Expected period for 16 cycles = %0d ns, Measured period = %0d ns",
               expected_pulse_ns, pulse_time);
      if (pulse_time >= (expected_pulse_ns - tolerance) && pulse_time <= (expected_pulse_ns + tolerance))
      begin
        $display("Pulse time matches expected value.");
      end
      else
      begin
        $display("ERROR: Pulse time mismatch! Expected %0d ns, got %0d ns", expected_pulse_ns,
                 pulse_time);
      end
    end
  endtask

  initial
  begin
    // Initialize signals
    rst = 1;
    sel = 3'b000;  // Start with 9600 baud rate

    // Reset the module
    #100;
    rst = 0;

    // Wait for a few clock cycles for stabilization
    #1000;

    // Check pulse time for 9600 baud
    // Measured pulse time for 9600 baud (16x) = 97650 ns
    check_pulse_time(104166.67, 10);  // 10 ns tolerance

    // Change baud rate to 19200
    sel = 3'b001;
    #1000;
    // Measured pulse time for 19200 baud (16x) = 48825 ns
    check_pulse_time(52083.33, 10);

    // Change baud rate to 38400
    sel = 3'b010;
    #1000;
    // Measured pulse time for 38400 baud (16x) = 24405 ns
    check_pulse_time(26041.67, 10);

    // Change baud rate to 57600
    sel = 3'b011;
    #1000;
    // Measured pulse time for 57600 baud (16x) = 16260 ns
    check_pulse_time(17361.11, 10);

    // Change baud rate to 115200
    sel = 3'b100;
    #1000;
    // Measured pulse time for 115200 baud (16x) = 8130 ns
    check_pulse_time(8680.56, 10);

    // Finish simulation
    $finish;
  end

endmodule
