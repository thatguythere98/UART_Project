`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:
// Design Name: UART System Controller
// Module Name: uart_system_controller
// Project Name: UART Project
// Target Devices: Cmod A7 35T FPGA
// Tool Versions: Vivado 2024.1
// Description:
//      This module acts as the top-level for routing UART signals between the
//      FPGA and external devices. It includes clock management, FIFO control,
//      signal debounce, and baud rate selection. At present this module simply
//      reroutes a message recieved by the fpga back to its source.
//
// Dependencies:
//      UART_Top, SignalDebounce, BaudSel, Clock Wizard
//
// Revision History:
//      Revision 0.01 - File Created
//
// Notes:
//      At present this module expects a 12 MHz clock input to the clock wizard,
//      and 11.0592 MHz clock input for the UART interface provided by the clock wizard.
//////////////////////////////////////////////////////////////////////////////////

module uart_system_controller
  #(
     parameter DATA_WIDTH = 8,   // Number of data bits
     parameter STOP_BITS = 1,    // Number of stop bits
     parameter FIFO_DEPTH = 256  // FIFO depth
   )
   (
     input wire clk,           // Main clock input
     input wire rst,           // Reset input, active low
     input wire sel,           // Baud rate selection input
     input wire rx,            // UART RX input

     output wire tx,           // UART TX output
     output wire [1:0] led     // 2 LEDs for visual feedback
   );

  // Define constants for parity selection
  localparam [1:0] NO_PARITY = 2'b00;  // Parity state: Transmitting the parity bit
  localparam [1:0] EVEN_PARITY = 2'b01;  // Parity state: Transmitting the parity bit
  localparam [1:0] ODD_PARITY = 2'b10;  // Parity state: Transmitting the parity bit

  // Internal signal declarations
  wire [DATA_WIDTH-1:0] tx_fifo_din;     // Data input to TX FIFO
  wire tx_fifo_full;          // TX FIFO full flag
  wire rx_fifo_empty;         // RX FIFO empty flag
  wire debounced_sel;         // Debounced select button signal
  wire debounced_rst;         // Debounced reset button signal
  wire [2:0] baud_sel;        // Baud rate selection
  wire locked;                // Clock wizard lock status
  wire clk_out1;              // Clock output from the clock wizard
  wire system_reset;          // Combined reset signal

  // Assign system reset as either debounced reset or clock lock failure
  assign system_reset = debounced_rst | ~locked;

  // Control logic for FIFO read and write enables
  wire tx_fifo_wr_en = ~tx_fifo_full & ~rx_fifo_empty; // Write to TX FIFO when it's not full and RX FIFO is not empty
  wire rx_fifo_rd_en = tx_fifo_wr_en;                  // Read from RX FIFO at the same time we write to TX FIFO

  // Clock wizard instantiation (generates clk_out1(11.056 MHz) from the input clock)
  clk_wiz_0 clk_wiz_inst (
              .clk_out1(clk_out1),       // Output clock
              .locked(locked),           // Lock status
              .clk_in1(clk)              // Input clock
            );

  // UART Top-level module instantiation
  uart_top #(
             .DATA_WIDTH(DATA_WIDTH),
             .STOP_BITS(STOP_BITS),
             .FIFO_DEPTH(FIFO_DEPTH)
           ) uart_top_inst (
             .clk(clk_out1),            // System clock
             .rst(system_reset),        // System reset
             .sel(baud_sel),            // Baud rate select
             .parity_mode(NO_PARITY), // Pass parity_mode to the top module
             .tx_fifo_wr_en(tx_fifo_wr_en),  // Write enable for TX FIFO
             .rx_fifo_rd_en(rx_fifo_rd_en),  // Read enable for RX FIFO
             .tx_fifo_din(tx_fifo_din),  // Data input to TX FIFO
             .rx(rx),                   // RX signal from external device
             .tx(tx),                   // TX signal to external device
             .tx_fifo_full(tx_fifo_full),// TX FIFO full flag
             .rx_fifo_full(),           // RX FIFO full flag
             .rx_fifo_empty(rx_fifo_empty), // RX FIFO empty flag
             .rx_fifo_dout(tx_fifo_din)  // Data output from RX FIFO to TX FIFO input
           );

  // Debounce reset signal
  signal_debounce reset_debounce_inst (
                    .clk(clk_out1),            // System clock
                    .button_in(rst),           // Asynchronous reset input
                    .button_out(debounced_rst) // Debounced reset output
                  );

  // Debounce baud select button signal
  signal_debounce baud_select_debounce_inst (
                    .clk(clk_out1),            // System clock
                    .button_in(sel),           // Asynchronous select button input
                    .button_out(debounced_sel) // Debounced select output
                  );

  // Baud rate selection module instantiation
  baud_sel baud_sel_inst (
             .clk(clk_out1),            // System clock
             .rst(system_reset),        // System reset
             .button_in(debounced_sel), // Debounced select button signal
             .sel(baud_sel)             // Selected baud rate
           );

  // Assign debounced button signals to LEDs for visual feedback
  assign led[0] = debounced_rst; // LED 0 lights up when reset is pressed
  assign led[1] = debounced_sel; // LED 1 lights up when baud rate select is pressed

endmodule
