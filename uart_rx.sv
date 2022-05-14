// FROM: https://www.nandland.com/vhdl/modules/module-uart-serial-port-rs232.html
//
// Modifications by Douglas P. Fields, Jr.:
// 1. Convert to System Verilog; address all compile/synthesis warnings
// 2. Add reset
// 3. Expand the clock to 12 bits from 8
// 4. TODO: Add an assertion that CLKS_PER_BIT is less than the 12 bit counter
// 5. Reformat

//////////////////////////////////////////////////////////////////////
// File Downloaded from http://www.nandland.com
//////////////////////////////////////////////////////////////////////
// This file contains the UART Receiver.  This receiver is able to
// receive 8 bits of serial data, one start bit, one stop bit,
// and no parity bit.  When receive is complete o_rx_dv will be
// driven high for one clock cycle.
// 
// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (Frequency of clock)/(Frequency of UART)
// Example: 10 MHz Clock, 115200 baud UART
// (10000000)/(115200) = 87
  
module uart_rx #(
  parameter CLKS_PER_BIT
) (
  input  logic       clock,
  input  logic       reset,
  input  logic       rx_uart,
  output logic       data_valid,
  output logic [7:0] data_byte,

  // Debugging outputs
  output logic [2:0] state
);
  
localparam s_IDLE         = 3'b000;
localparam s_RX_START_BIT = 3'b001;
localparam s_RX_DATA_BITS = 3'b010;
localparam s_RX_STOP_BIT  = 3'b011;
localparam s_CLEANUP      = 3'b100;
 
logic           r_Rx_Data_R = 1'b1;
logic           r_Rx_Data   = 1'b1;
 
logic [11:0]    r_Clock_Count = 0;
logic [2:0]     r_Bit_Index   = 0; //8 bits total
logic [7:0]     r_Rx_Byte     = 0;
logic           r_Rx_DV       = 0;
logic [2:0]     r_SM_Main     = 0;

// Debugging outputs
assign state = r_SM_Main;

 
assign data_valid = r_Rx_DV;
assign data_byte = r_Rx_Byte;

 
// Purpose: Double-register the incoming data.
// This allows it to be used in the UART RX Clock Domain.
// (It removes problems caused by metastability)
always_ff @(posedge clock) begin
  r_Rx_Data_R <= rx_uart;
  r_Rx_Data   <= r_Rx_Data_R;
end

 
// Purpose: Control RX state machine
always_ff @(posedge clock) begin
    
  if (reset)
    r_SM_Main <= s_IDLE;

  else case (r_SM_Main)
    s_IDLE: begin
      r_Rx_DV       <= 1'b0;
      r_Clock_Count <= 0;
      r_Bit_Index   <= 0;
        
      if (r_Rx_Data == 1'b0)          // Start bit detected
        r_SM_Main <= s_RX_START_BIT;
      else
        r_SM_Main <= s_IDLE;
    end
      
    // Check middle of start bit to make sure it's still low
    s_RX_START_BIT: begin
      if (r_Clock_Count == (CLKS_PER_BIT-1)/2) begin
        if (r_Rx_Data == 1'b0) begin
          r_Clock_Count <= 0;  // reset counter, found the middle
          r_SM_Main     <= s_RX_DATA_BITS;
        end else
          r_SM_Main <= s_IDLE;
      end else begin
        r_Clock_Count <= r_Clock_Count + 12'b1;
        r_SM_Main     <= s_RX_START_BIT;
      end
    end // case: s_RX_START_BIT
      
      
    // Wait CLKS_PER_BIT-1 clock cycles to sample serial data
    s_RX_DATA_BITS: begin
      if (r_Clock_Count < CLKS_PER_BIT-1) begin
        r_Clock_Count <= r_Clock_Count + 12'b1;
        r_SM_Main     <= s_RX_DATA_BITS;
      end else begin
        r_Clock_Count          <= 0;
        r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;
          
        // Check if we have received all bits
        if (r_Bit_Index < 7) begin
          r_Bit_Index <= r_Bit_Index + 3'b1;
          r_SM_Main   <= s_RX_DATA_BITS;
        end else begin
          r_Bit_Index <= 0;
          r_SM_Main   <= s_RX_STOP_BIT;
        end
      end
    end // case: s_RX_DATA_BITS
  
  
    // Receive Stop bit.  Stop bit = 1
    s_RX_STOP_BIT: begin
      // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
      if (r_Clock_Count < CLKS_PER_BIT-1) begin
        r_Clock_Count <= r_Clock_Count + 3'b1;
        r_SM_Main     <= s_RX_STOP_BIT;
      end else begin
        r_Rx_DV       <= 1'b1;
        r_Clock_Count <= 0;
        r_SM_Main     <= s_CLEANUP;
      end
    end // case: s_RX_STOP_BIT
  
      
    // Stay here 1 clock
    s_CLEANUP: begin
      r_SM_Main <= s_IDLE;
      r_Rx_DV   <= 1'b0;
    end
      
      
    default:
      r_SM_Main <= s_IDLE;
      
  endcase
end // always_ff
 
endmodule // uart_rx