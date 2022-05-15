// Copyright 2022 Douglas P. Fields, Jr. All Rights Reserved.

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// This doesn't work in Questa for some reason. vlog-2892 errors.
`default_nettype none // Disable implicit creation of undeclared nets
`endif

// This sends 8-bit bytes out over biphase_out including one start
// bit (logic 0, SPACING, two short pulses) and one stop bit
// (logic 1, MARKING, one long pulse). The bits are sent LSB first.

// Interface:
// 0. If reset is asserted, biphase and clock will be stopped; biphase will
//    be set to logic high and clock to logic low.
//    TODO: Should busy be asserted during reset?
// 1. When busy is asserted, the encoder is sending a byte out over
//    the wire. busy will be de-asserted as soon as the second half of the
//    stop bit is sent. This allows for the next byte to be sent without
//    any intervening idle marking bits.
// 2. When busy is NOT asserted, and data_ready is NOT asserted,
//    the encoder is IDLE and will be MARKING (sending 1's) as
//    alternating "long pulses" of length 2x the SHORT_PULSE duration.
// 3. When busy is NOT asserted, and data_ready IS asserted,
//    the data_in will be read into a buffer and the byte to be sent
//    will be begun as soon as possible:
//    a. If data_in is asserted in the first half of a bit, the start
//       bit will be sent during the current bit period, that may have already
//       started up to a half bit time ago.
//    b. If data_in is asserted in the second half of a bit, the start
//       bit will be sent in the next bit.

// Implementation Notes:
// 1. When we're busy, we watch for changes in the first half flag. 
//    When it changes from first to second half, we decide what to do in
//    our state machine.
// 2. When we're not busy, we immediately become busy and the system\
//    "just works" at the right time.

module biphase_encoder #(
  parameter SHORT_PULSE = 333 // 6⅔ µs at 50MHz
) (
  input logic clk,  // system-wide clock
  input logic rst,  // system-wide reset

  input logic       data_ready,
  input logic [7:0] data_in,

  output logic biphase_out, // data output (balanced except during reset)
  output logic clock_out,   // the generated clock (probably not useful)
  output logic busy,        // TODO: When asserted, we cannot accept any data

  // Debugging outputs
  output logic dbg_first_half,
  output logic dbg_current_bit
);

localparam COUNTER_SIZE = $clog2(SHORT_PULSE);
localparam COUNTER_1 = { {(COUNTER_SIZE-1){1'b0}}, 1'b1};
localparam COUNTER_START = SHORT_PULSE[COUNTER_SIZE-1:0] - 1'b1;

// Our half-bit counter
logic [COUNTER_SIZE-1:0] out_counter = '0;
logic [COUNTER_SIZE-1:0] next_out_counter; // combinational

// The bits we're sending, in the order we're sending
// them from LSB to MSB, including start and stop bits.
logic [9:0] bits_out;

// The bit number we're going to send when the next
// bit starts (of 10 bits). So, when this is 10, we've
// just sent the last bit.
logic [3:0] next_bit_index;

localparam [3:0] LAST_BIT_INDEX = 10;
localparam IDLE_BIT_OUTPUT = 1'b1; // Marking - long pulses
localparam START_BIT = 1'b0; // Spacing
localparam STOP_BIT = 1'b1;

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

// Watch where we are in our biphase output
logic prev_first_half; // Last cycle's first_half flag
// Combinatoral checks with prev & current first_half
logic first_half_begun;
logic second_half_begun;
assign first_half_begun = first_half && !prev_first_half;
assign second_half_begun = prev_first_half && !first_half;

//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
// This is our output routine, lowest level.
always_ff @(posedge clk) begin

  if (rst) begin
    // Otherwise these don't get initial values in simulation
    // despite these getting default 0 values in their registers
    // from the FPGA.
    biphase_out <= '1;
    clock_out <= '0;
    first_half <= '1;
    out_counter <= '0;

  end else if (out_counter == '0) begin
    // Start counting down again for our next half-bit
    out_counter <= COUNTER_START;

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


//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
// Our output state machine.
always_ff @(posedge clk) begin

  prev_first_half <= first_half;

  if (rst) begin ///////////////////////////////////////////////// RESET
    // We are marking when we're in reset (idle)
    current_bit <= IDLE_BIT_OUTPUT;

    // TODO: Should we be busy when reseting?
    // If we're busy, we have to remember to deassert busy
    // once reset ends, so that's probably a bad idea.
    busy <= '0;

  end else if (busy) begin /////////////////////////////////////// BUSY

    // When we're busy, we change the current_bit to send at the 
    // beginning of every second half.
    if (second_half_begun) begin
      if (next_bit_index == LAST_BIT_INDEX) begin
        // We have completed all bit sending and we can de-assert busy.
        busy <= '0;
        current_bit <= IDLE_BIT_OUTPUT;
        // Yes, this means one cycle of latency until we check for
        // data_ready but I'm really not worried about it.

      end else begin
        // We need to send the next bit
        current_bit <= bits_out[next_bit_index];
        // And advance so we handle the next bit after that
        next_bit_index <= next_bit_index + 4'd1;

      end
    end

  end else if (data_ready) begin ///////////////////////////////// STARTING

    assert (!busy);
    busy <= '1;

    // We have to start sending the requested bits, including the
    // start and stop bits.

    // TODO: These are constants, presumably they will be optimized away,
    // or we could move them to a combinational assign/always_comb block.
    bits_out[0] <= START_BIT;
    bits_out[9] <= STOP_BIT;
    /*
    // Ugh. Streaming operator is not recognized in Quartus 21.
    bits_out[8:1] <= {<<{data_in}}; // streaming operator to reverse bits
    // We don't want to reverse the bits anyway in the current implementation.
    */
    bits_out[8:1] = data_in;

    // Indicate which bit we're sending now
    current_bit <= START_BIT;
    next_bit_index <= 4'd1; // The next bit index to send

    // FIXME: We obviously never use bits_out[0] so maybe elide it -
    // or maybe the compiler will do that for us.

  end else begin ///////////////////////////////////////////////// IDLE
    assert (!busy);
    assert (!data_ready);
    current_bit <= IDLE_BIT_OUTPUT; // which should already be the case

  end //////////////////////////////////////////////////////////// STATE MACHINE

end

endmodule


`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// Restore the default_nettype to prevent side effects
// See: https://front-end-verification.blogspot.com/2010/10/implicit-net-declartions-in-verilog-and.html
// and: https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_presentation.pdf
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif
