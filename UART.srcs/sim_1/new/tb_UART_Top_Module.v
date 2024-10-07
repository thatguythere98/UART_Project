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

module UART_Top_tb;

  // Signals
  reg clk;
  reg rst;
  reg tx_fifo_wr_en;
  reg rx_fifo_rd_en;
  reg [7:0] Tx_fifo_din;
  wire tx;
  wire Tx_fifo_full;
  wire Rx_fifo_full;
  wire Rx_fifo_empty;
  wire [7:0] Rx_fifo_dout;
  wire locked;  // Expose locked signal to wait for clock wizard

  // Instantiate the UART_Top module
  UART_Top uut (
             .clk(clk),
             .rst(rst),
             .tx_fifo_wr_en(tx_fifo_wr_en),
             .rx_fifo_rd_en(rx_fifo_rd_en),
             .tx_fifo_din(Tx_fifo_din),
             .rx(tx),  // Loopback connection for testing
             .tx(tx),
             .tx_fifo_full(Tx_fifo_full),
             .rx_fifo_full(Rx_fifo_full),
             .rx_fifo_empty(Rx_fifo_empty),
             .rx_fifo_dout(Rx_fifo_dout),
             .locked(locked)  // Monitor the locked signal in the testbench
           );

  // Clock generation
  initial
  begin
    clk = 0;
    forever
      #41.67 clk = ~clk;  // 12 MHz clock (period = 83.33 ns, half period = 41.67 ns)
  end

  // Test sequence
  initial
  begin
    // Initial setup
    rst = 1;
    tx_fifo_wr_en = 0;
    rx_fifo_rd_en = 0;
    Tx_fifo_din = 8'd0;

    #200;  // Wait for 200ns
    rst = 0;  // Deassert reset

    // Wait for the Clock Wizard to lock
    wait(locked == 1);  // Wait until the clock is stable and locked

    // Start sending data
    #100;
    Tx_fifo_din = 8'hA5;  // Example data to transmit
    tx_fifo_wr_en = 1;  // Enable write to Tx FIFO
    #135.63;  // Wait for one clock cycle (7.3728 MHz)
    tx_fifo_wr_en = 0;  // Disable write

    // Wait for transmission to complete
    wait(uut.tx_done == 1);
    #135.63;  // Wait one more clock cycle to ensure reception is complete

    // Read from Rx FIFO
    rx_fifo_rd_en = 1;
    #135.63;  // Wait for one clock cycle
    rx_fifo_rd_en = 0;

    // Wait and observe received data
    #500;

    // Additional tests can be added here...

    $finish;  // End the simulation
  end

endmodule
