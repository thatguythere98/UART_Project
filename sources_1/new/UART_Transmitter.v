`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:
// Design Name: UART Transmitter
// Module Name: tx
// Project Name: UART Project
// Target Devices: Cmod A7 35T FPGA
// Tool Versions: Vivado 2024.1
// Description:
//      UART Transmitter module that serially sends an 8-bit data word over the 'tx' line.
//      It implements a state machine to handle the transmission of start bit, data bits,
//      and stop bit using a 16x oversampled baud rate clock.
//
// Dependencies:
//      None
//
// Revision History:
//      Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module tx
  #(
     parameter DATA_WIDTH = 8,     // Number of data bits per word
     parameter STOP_BITS = 1       // Number of stop bits
   )
   (

     input wire      clk,         // System clock
     input wire      rst,         // Active-low reset signal
     input wire [DATA_WIDTH-1:0] din,        // Data input (data to be transmitted)
     input wire      tx_start,    // Transmission start signal (initiates data transmission)
     input wire      sample_tick, // Baud rate clock (16x the baud rate, used for precise bit timing)
     input wire [1:0] parity_mode, // Parity select (00 = no parity, 01 = even parity, 10 = odd parity)

     output reg tx,               // UART transmit output (serial data output)
     output reg tx_done           // Transmission done signal (indicates when transmission is complete)
   );

  // State Machine States
  localparam [2:0] IDLE   = 3'b000;  // Idle state: Waiting for tx_start signal
  localparam [2:0] START  = 3'b001;  // Start bit state: Transmitting the start bit
  localparam [2:0] DATA   = 3'b010;  // Data state: Transmitting the 8 data bits
  localparam [2:0] STOP   = 3'b011;  // Stop bit state: Transmitting the stop bit
  localparam [2:0] PARITY = 3'b100;  // Parity state: Transmitting the parity bit


  reg [2:0] state, next_state;             // Registers to hold the current and next state of the state machine
  reg [DATA_WIDTH-1:0] data_in, next_data_in;         // Register to hold the data to be transmitted
  reg [2:0] index, next_index;             // Register to track the current bit being transmitted (0 to 7)
  reg [3:0] sample_count, next_sample_count; // Register to count samples (0 to 15) within a single bit period
  reg [1:0] stop_bit_count, next_stop_bit_count; // Counter for stop bits
  reg next_tx;
  reg parity_bit;
  reg parity_enabled;                    // Register to hold the next state of the tx output


  // Determine whether parity is enabled
  always @(*)
  begin
    parity_enabled = (parity_mode != 2'b00);  // Parity is enabled if parity_mode is not 00 (no parity)
  end

  // Compute parity bit based on parity_mode and data_in
  always @(*)
  begin
    if (parity_mode == 2'b01)
    begin
      // Even parity
      parity_bit = ^data_in;  // XOR all bits for even parity
    end
    else if (parity_mode == 2'b10)
    begin
      // Odd parity
      parity_bit = ~(^data_in);  // XOR all bits and invert for odd parity
    end
    else
    begin
      // No parity, parity bit is unused
      parity_bit = 1'b0;
    end
  end


  // State register update on clock edge or reset
  always @(posedge clk)
  begin
    if (rst)
    begin
      state          <= IDLE;          // On reset, go to idle state
      sample_count   <= 4'b0;          // Reset sample counter
      index          <= 3'b0;          // Reset bit index counter
      data_in        <= {DATA_WIDTH{1'b0}}; // Clear data register
      stop_bit_count <= 2'b0;  // Reset stop bit counter
      tx             <= 1'b1;          // Set tx to idle state (high)
    end
    else
    begin
      state          <= next_state;    // Update to next state
      sample_count   <= next_sample_count; // Update sample counter
      index          <= next_index;    // Update bit index counter
      tx             <= next_tx;       // Update tx output
      stop_bit_count <= next_stop_bit_count; // Update stop bit counter
      data_in        <= next_data_in;  // Update data register
    end
  end

  // State machine for UART transmission
  always @(*)
  begin
    // Default assignments for next state and outputs
    next_state        = state;         // Default to hold current state
    next_sample_count = sample_count;  // Default to hold current sample count
    next_index        = index;         // Default to hold current bit index
    next_tx           = tx;            // Default to hold current tx output
    next_data_in      = data_in;       // Default to hold current data
    next_stop_bit_count = stop_bit_count;
    tx_done           = 1'b0;          // Clear tx_done flag by default

    case (state)
      IDLE:
      begin
        next_tx = 1'b1;  // Set tx to idle state (high)
        if (tx_start == 1'b1)
        begin
          next_data_in    = din;           // Load data to be transmitted
          next_sample_count = 4'd0;
          next_state = START;         // Move to start bit state
        end
      end

      START:
      begin
        if (sample_tick)
        begin
          next_tx = 1'b0;  // Transmit start bit (low)
          if (sample_count == 4'd15)
          begin
            next_state        = DATA;  // Move to data transmission state
            next_sample_count = 4'd0;  // Reset sample count for the first data bit
          end
          else
          begin
            next_sample_count = sample_count + 1'b1; // Increment sample counter
          end
        end
      end

      DATA:
      begin
        if (sample_tick)
        begin
          next_tx = data_in[index];  // Transmit current bit from data_in
          if (sample_count == 4'd15)
          begin
            next_sample_count = 4'd0;  // Reset sample count for next bit
            if (index == DATA_WIDTH-1)
            begin   // If all 8 bits are transmitted
              next_index = 3'd0;       // Reset bit index
              if (parity_enabled)
              begin
                next_state = PARITY;  // Move to parity state if parity is enabled
              end
              else
              begin
                next_state = STOP;    // Otherwise move to stop state
              end
            end
            else
            begin
              next_index = index + 1'b1;  // Move to next bit
            end
          end
          else
          begin
            next_sample_count = sample_count + 1'b1; // Increment sample counter
          end
        end
      end

      PARITY:
      begin
        if (sample_tick)
        begin
          next_tx = parity_bit;  // Transmit parity bit
          if (sample_count == 4'd15)
          begin
            next_sample_count = 4'd0;
            next_state = STOP;
          end
          else
          begin
            next_sample_count = sample_count + 1'b1;
          end
        end
      end

      STOP:
      begin
        if (sample_tick)
        begin
          next_tx = 1'b1;  // Transmit stop bit (high)
          if (sample_count == 4'd15)
          begin
            if (stop_bit_count == (STOP_BITS - 1))
            begin
              next_state = IDLE;  // Transmission complete, return to IDLE state
              tx_done = 1'b1;     // Set tx_done flag
            end
            else
            begin
              next_stop_bit_count = stop_bit_count + 1'b1; // Continue transmitting stop bits
            end
          end
          else
          begin
            next_sample_count = sample_count + 1'b1; // Increment sample counter
          end
        end
      end

      default:
      begin
        next_state = IDLE;  // Default to idle state in case of invalid state
      end
    endcase
  end

endmodule
