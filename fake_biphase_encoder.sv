// Copyright 2022 Douglas P. Fields, Jr. All Rights Reserved.

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// This doesn't work in Questa for some reason. vlog-2892 errors.
`default_nettype none // Disable implicit creation of undeclared nets
`endif

// This is a fake version of the biphase_encoder that
// pretends to send stuff - but doesn't actually send
// anything. It just asserts the busy and sends some
// debugging outputs, for use in a test bench.

module fake_biphase_encoder #(
  parameter SHORT_PULSE = 333 // 6⅔ µs at 50MHz
) (
  input logic clk,  // system-wide clock
  input logic rst,  // system-wide reset

  input logic       data_ready,
  input logic [7:0] data_in,

  output logic busy = '0,

  // Debugging outputs
  output logic       dbg_start_bit = '0,
  output logic       dbg_stop_bit = '0,
  output logic [7:0] dbg_data_bits = 'X
);

localparam LONG_PULSE = SHORT_PULSE * 2;
localparam COUNTER_SIZE = $clog2(LONG_PULSE);
localparam COUNTER_1 = { {(COUNTER_SIZE-1){1'b0}}, 1'b1};
localparam COUNTER_START = LONG_PULSE[COUNTER_SIZE-1:0] - 1'b1;

logic [COUNTER_SIZE-1:0] counter;
logic [3:0] bit_counter;
logic [7:0] data_to_send;

always_ff @(posedge clk) begin

  // We always keep our counter going down.
  if (rst || counter == 0)
    counter <= COUNTER_START;
  else
    counter <= counter - COUNTER_1;

  // Our state machine for faking a send
  if (rst) begin
    busy <= '0;
    dbg_start_bit <= '0;
    dbg_stop_bit <= '0;
    dbg_data_bits <= 'X;
  
  end else if (!busy) begin
    // We're idling; wait for the data_ready.

    if (data_ready) begin
      data_to_send <= data_in;
      bit_counter <= 4'd11; // Meaning we are waiting for counter 0 to send a bit
      busy <= '1;
    end

  end else if (counter == 0) begin

    // We're in the midst of sending a packet
    // 11 = waiting to send from previous bit
    // 10 = start bit
    // 9-2 = sending data
    // 1 = stop bit
    // 0 = we're now idle
    //
    // We only do work when our counter is zero
    assert(busy);

    bit_counter <= bit_counter - 4'd1;

    // Check the old value (the new value is one less due to above)
    if (bit_counter == 4'd11)
      // Begin sending the start bit
      dbg_start_bit <= '1;
    else if (bit_counter == 4'd2) begin
      // Begin sending the stop bit
      dbg_data_bits <= 'X;
      dbg_stop_bit <= '1;
    end else if (bit_counter == 4'd1) begin
      // And now we're done
      dbg_stop_bit <= '0;
      busy <= '0;
    end else begin
      // We need to send our data bits
      dbg_start_bit <= '0;
      dbg_data_bits <= data_to_send;
    end
    
  end // state machine

end // always_ff on the clock


endmodule


`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// Restore the default_nettype to prevent side effects
// See: https://front-end-verification.blogspot.com/2010/10/implicit-net-declartions-in-verilog-and.html
// and: https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_presentation.pdf
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif
