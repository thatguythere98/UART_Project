`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:
// Design Name: UART Top Module
// Module Name: UART_Top
// Project Name: UART Project
// Target Devices: Cmod A7 35T FPGA
// Tool Versions: Vivado 2024.1
// Description:
//      This module integrates the UART transmit, receive, and FIFO logic. It
//      connects to an external UART interface and manages the data flow using
//      FIFOs. The baud rate is controlled via the `BaudGenerator` module.
//
// Dependencies:
//      BaudGenerator, Tx, Rx, FIFO modules.
//
// Revision History:
//      Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module uart_top  #(
    parameter DATA_WIDTH = 8,     // Number of data bits
    parameter STOP_BITS = 1,      // Number of stop bits
    parameter FIFO_DEPTH = 256    // FIFO depth (can be adjusted by setting ADDR_WIDTH)
  )(
    input wire        clk,            // System clock
    input wire        rst,            // System reset, active high
    input wire [2:0]  sel,            // Baud rate selection
    input wire [1:0]  parity_mode,    // Parity mode select (00 = no parity, 01 = even parity, 10 = odd parity)

    // FIFO control signals
    input wire        tx_fifo_wr_en,  // Write enable for Tx FIFO
    input wire        rx_fifo_rd_en,  // Read enable for Rx FIFO
    input wire [DATA_WIDTH-1:0]  tx_fifo_din,    // Data input to Tx FIFO
    input wire        rx,             // UART receive line

    // Output signals
    output wire       tx,             // UART transmit line
    output wire       tx_fifo_full,   // Tx FIFO full flag
    output wire       rx_fifo_full,   // Rx FIFO full flag
    output wire       rx_fifo_empty,  // Rx FIFO empty flag
    output wire [DATA_WIDTH-1:0] rx_fifo_dout    // Received data output
  );

  // Internal signals
  wire baud16x_out;                   // 16x oversampling baud rate clock
  wire tx_done;                       // Tx module done signal
  wire rx_done;                       // Rx module done signal
  wire [DATA_WIDTH-1:0] rx_data;                 // Data from Rx module
  wire [DATA_WIDTH-1:0] tx_dout;                 // Data from Tx FIFO to Tx module
  wire tx_fifo_empty;                 // Tx FIFO empty flag

  // Instantiate BaudGenerator for baud rate selection
  baud_generator baud_gen (
                   .rst(rst),
                   .clk(clk),
                   .sel(sel),
                   .baud16x_out(baud16x_out)       // 16x baud rate clock output
                 );

  // Instantiate Tx FIFO for storing data to be transmitted
  fifo #(
         .DATA_WIDTH(DATA_WIDTH),                 // 8-bit data width
         .ADDR_WIDTH($clog2(FIFO_DEPTH))                  // 256-depth FIFO
       ) tx_fifo (
         .clk(clk),
         .rst(rst),
         .wr_en(tx_fifo_wr_en),           // Write enable
         .rd_en(tx_done),                 // Read when transmission is done
         .data(tx_fifo_din),              // Data input
         .dout(tx_dout),                  // Data output to Tx module
         .full(tx_fifo_full),             // Tx FIFO full flag
         .empty(tx_fifo_empty)            // Tx FIFO empty flag
       );

  // Instantiate UART Tx (transmit) module
  tx #(
       .DATA_WIDTH(DATA_WIDTH),   // Parameterized data width
       .STOP_BITS(STOP_BITS)      // Parameterized stop bits
     ) uart_tx (
       .clk(clk),
       .rst(rst),
       .din(tx_dout),                   // Data from Tx FIFO
       .tx_start(~tx_fifo_empty),       // Start transmission if FIFO is not empty
       .sample_tick(baud16x_out),       // 16x baud rate clock for sampling
       .parity_mode(parity_mode),       // Parity mode select
       .tx(tx),                         // UART transmit line
       .tx_done(tx_done)                // Transmission done signal
     );

  // Instantiate Rx FIFO for storing received data
  fifo #(
         .DATA_WIDTH(DATA_WIDTH),                 // 8-bit data width
         .ADDR_WIDTH($clog2(FIFO_DEPTH))                  // 256-depth FIFO
       ) rx_fifo (
         .clk(clk),
         .rst(rst),
         .wr_en(rx_done),                 // Write when receiving is done
         .rd_en(rx_fifo_rd_en),           // Read enable
         .data(rx_data),                  // Data input from Rx module
         .dout(rx_fifo_dout),             // Data output to external logic
         .full(rx_fifo_full),             // Rx FIFO full flag
         .empty(rx_fifo_empty)            // Rx FIFO empty flag
       );

  // Instantiate UART Rx (receive) module
  rx #(
       .DATA_WIDTH(DATA_WIDTH),   // Parameterized data width
       .STOP_BITS(STOP_BITS)      // Parameterized stop bits
     ) uart_rx (
       .clk(clk),
       .rst(rst),
       .rx(rx),                         // UART receive line
       .sample_tick(baud16x_out),       // 16x baud rate clock for sampling
       .parity_mode(parity_mode),       // Parity mode select
       .dout(rx_data),                  // Data output to Rx FIFO
       .rx_done(rx_done),                // Reception done signal
       .parity_error()                  // Parity error flag (connect to where needed)
     );
endmodule
