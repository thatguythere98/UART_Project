`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:
// Design Name: UART Reciever
// Module Name: rx
// Project Name: UART Project
// Target Devices: Cmod A7 35T FPGA
// Tool Versions: Vivado 2024.1
// Description:
//      UART Receiver module that captures serial data on the 'rx' line
//      and outputs an 8-bit word when a complete byte has been received.
//
// Dependencies: None
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module rx
  #(
     parameter DATA_WIDTH = 8,     // Number of data bits per word
     parameter STOP_BITS = 1       // Number of stop bits
   )
   (

     input wire clk,         // System clock
     input wire rst,         // Active-low reset
     input wire rx,          // UART receive line
     input wire sample_tick, // Baud rate clock (16x the baud rate, used for precise bit sampling)
     input wire [1:0] parity_mode, // Parity select (00 = no parity, 01 = even parity, 10 = odd parity)

     output wire [DATA_WIDTH-1:0] dout, // Data output (received data)
     output reg rx_done,      // Reception done flag (indicates a complete byte has been received)
     output reg parity_error        // Parity error flag
   );

  // State Machine States
  localparam [2:0] IDLE    = 3'b000;  // Idle state: Waiting for start bit
  localparam [2:0] START   = 3'b001;  // Start bit state: Verifies start bit
  localparam [2:0] RECEIVE = 3'b010;  // Receive state: Shifts in 8 data bits
  localparam [2:0] STOP    = 3'b011;  // Stop bit state: Verifies stop bit
  localparam [2:0] PARITY  = 3'b100;  // Parity state: Transmitting the parity bit

  // Internal Registers
  reg [2:0] state, next_state;               // State registers
  reg [DATA_WIDTH-1:0] data_in, next_data_in;           // Data registers for receiving bytes
  reg [2:0] bit_index, next_bit_index;       // Bit index for tracking received bits
  reg [3:0] sample_count, next_sample_count; // Sample count within a single bit period
  reg [1:0] stop_bit_count, next_stop_bit_count; // Counter for stop bits
  reg rx_sync, rx_sync2; // Two-stage synchronization registers for rx line
  reg received_parity_bit;
  reg parity_enabled;

  // Determine whether parity is enabled
  always @(*)
  begin
    parity_enabled = (parity_mode != 2'b00);  // Parity is enabled if parity_mode is not 00 (no parity)
  end

  // Synchronization of the rx input
  always @(posedge clk)
  begin
    rx_sync  <= rx;        // First synchronization register
    rx_sync2 <= rx_sync;   // Second synchronization register
  end

  // State register update on clock edge or reset
  always @(posedge clk)
  begin
    if (rst)
    begin
      state          <= IDLE;          // On reset, go to IDLE state
      sample_count   <= 4'b0;          // Reset the sample counter
      bit_index      <= 3'b0;          // Reset the bit index counter
      data_in        <= {DATA_WIDTH{1'b0}}; // Clear data register
      stop_bit_count <= 2'b0;  // Reset stop bit counter
      parity_error = 1'b0;
    end
    else
    begin
      state          <= next_state;    // Update to the next state
      sample_count   <= next_sample_count; // Update the sample counter
      bit_index      <= next_bit_index; // Update the bit index counter
      data_in        <= next_data_in;  // Update the data register with the next data value
      stop_bit_count <= next_stop_bit_count; // Update stop bit counter
    end
  end

  // State machine for UART reception
  always @(*)
  begin
    // Default assignments for next state and outputs
    next_state          = state;         // Default to hold current state
    next_sample_count   = sample_count;  // Default to hold current sample count
    next_bit_index      = bit_index;     // Default to hold current bit index
    next_data_in        = data_in;       // Default to hold current data
    rx_done             = 1'b0;          // Clear rx_done flag by default
    next_stop_bit_count = stop_bit_count;
    parity_error = 1'b0;

    case (state)
      IDLE:
      begin
        if (~rx_sync2)
        begin  // Start bit detected (rx line goes low)
          next_state        = START;         // Move to START state to verify start bit
          next_sample_count = 4'b0;          // Reset the sample counter for start bit sampling
          next_bit_index    = 3'b0;          // Reset the bit index for receiving data bits
        end
      end

      START:
      begin
        if (sample_tick)
        begin  // Sample the rx line on every sample_tick
          if (sample_count == 4'd7)
          begin  // Midpoint of the start bit (halfway through)
            if (~rx_sync2)
            begin  // Confirm that rx is still low (valid start bit)
              next_state        = RECEIVE;  // Start receiving data bits
              next_sample_count = 4'b0;     // Reset sample count for the first data bit
            end
            else
            begin
              next_state = IDLE;  // Invalid start bit (rx went high), return to IDLE state
            end
          end
          else
          begin
            next_sample_count = sample_count + 1'b1; // Increment sample counter to reach midpoint
          end
        end
      end

      RECEIVE:
      begin
        if (sample_tick)
        begin  // Sample the rx line on every sample_tick
          if (sample_count == 4'd15)
          begin  // Midpoint of each data bit (sample the bit value)
            next_sample_count = 4'b0;       // Reset sample counter for next bit
            next_data_in = {rx_sync2, data_in[DATA_WIDTH-1:1]};  // Shift in received bit
            if (bit_index == DATA_WIDTH-1)
            begin    // If all 8 bits are received (bit index reaches 7)
              if (parity_enabled)
              begin
                next_state = PARITY;
              end
              else
              begin
                next_state = STOP;
              end
            end
            else
            begin
              next_bit_index = bit_index + 1'b1; // Otherwise, move to the next bit
            end
          end
          else
          begin
            next_sample_count = sample_count + 1'b1; // Increment sample counter to reach midpoint
          end
        end
      end

      PARITY:
      begin
        if (sample_tick)
        begin
          if (sample_count == 4'd15)
          begin
            received_parity_bit = rx_sync2;  // Sample parity bit at midpoint
            // Check parity
            if (parity_mode == 2'b01 && (^data_in != received_parity_bit))
            begin
              parity_error = 1'b1;  // Even parity error
            end
            else if (parity_mode == 2'b10 && (~^data_in != received_parity_bit))
            begin
              parity_error = 1'b1;  // Odd parity error
            end
            next_state = STOP;  // Move to STOP state after checking parity
            next_sample_count = 4'b0;  // Reset sample counter for stop bit
          end
          else
          begin
            next_sample_count = sample_count + 1'b1;  // Increment sample counter
          end
        end
      end

      STOP:
      begin
        if (sample_tick)
        begin  // Sample the rx line on every sample_tick
          if (sample_count == 4'd15)
          begin  // Midpoint of the stop bit (should be high)
            if (rx_sync2)
            begin  // Confirm stop bit
              if (stop_bit_count == (STOP_BITS - 1))
              begin
                next_state = IDLE;
                rx_done = 1'b1;  // Reception done
              end
              else
              begin
                next_stop_bit_count = stop_bit_count + 1'b1; // Check for additional stop bits
              end
            end
            else
            begin
              next_state = IDLE;  // If stop bit is not high, return to IDLE (error handling can be added here)
            end
          end
          else
          begin
            next_sample_count = sample_count + 1'b1; // Increment sample counter to reach midpoint
          end
        end
      end

      default:
      begin
        next_state = IDLE;  // Default to IDLE state if an invalid state is encountered
      end
    endcase
  end

  // Data output assignment
  assign dout = data_in;

endmodule
