// Copyright 2022 Douglas P. Fields, Jr. All Rights Reserved.

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// This doesn't work in Questa for some reason. vlog-2892 errors.
`default_nettype none // Disable implicit creation of undeclared nets
`endif

module biphase_encoder #(
  parameter SHORT_PULSE = 333 // 6⅔ µs at 50MHz
) (
  input logic clk,  // system-wide clock
  input logic rst,  // system-wide reset

  input logic       data_ready,
  input logic [7:0] data_in,

  output logic biphase_out, // NRZ data output
  output logic clock_out,
  output logic busy,        // TODO

  // Debugging outputs
  output logic dbg_first_half,
  output logic dbg_current_bit
);

initial clock_out = '0;

localparam COUNTER_SIZE = $clog2(SHORT_PULSE);
localparam COUNTER_1 = { {(COUNTER_SIZE-1){1'b0}}, 1'b1};

// Our half-bit counter
logic [COUNTER_SIZE-1:0] out_counter = '0;
logic [COUNTER_SIZE-1:0] next_out_counter; // combinational

// Are we sending the first half of the current bit?
// This gets toggled every time the counter is 0
logic first_half;
assign dbg_first_half = first_half;

// What bit are we currently sending?
// Remember:
// 1 = long pulse (both halves don't toggle output)
// 2 = 2x short pulse (second half toggles output)
logic current_bit;
assign dbg_current_bit = current_bit;

assign next_out_counter = out_counter - COUNTER_1;

// This is our output routine, lowest level.
always_ff @(posedge clk) begin

  if (out_counter == '0) begin
    // Start counting down again for our next half-bit
    out_counter <= SHORT_PULSE[COUNTER_SIZE-1:0];

    if (first_half) begin
      // We always toggle our output at the beginning...
      biphase_out <= ~biphase_out;
      // And our clock output is always toggling every LONG (2x SHORT) pulses
      clock_out <= ~clock_out;
    end else if (current_bit == '0)
      // If we are half way through, we need to toggle our
      // output if we are sending a 0 (spacing).
      biphase_out <= ~biphase_out;

  end else begin
    // We are in stable state, just wait till the next toggle
    out_counter <= next_out_counter;

    // TODO: Should this be "next_out_counter == '0" OR "out_counter == COUNTER 1" ???
    if (next_out_counter == '0)
      // Toggle the first_half same time as counter is 0
      first_half <= ~first_half;
  end

end // biphase output - lowest level


// Our output state machine. We only do things
// every time our counter reaches 0 AND we're in the first half
always_ff @(posedge clk) begin

  if (rst) begin
    // We are marking when we're in reset (idle)
    current_bit = '1;

    // TODO: Should we be busy when reseting?
    busy = '1;

    // TODO: Move the state machine to IDLE

  end else if (out_counter == '0) begin
    current_bit = ~current_bit;
  end

end

endmodule


`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// Restore the default_nettype to prevent side effects
// See: https://front-end-verification.blogspot.com/2010/10/implicit-net-declartions-in-verilog-and.html
// and: https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_presentation.pdf
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif
