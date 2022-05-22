// Copyright 2022 Douglas P. Fields, Jr. All Rights Reserved.

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// This doesn't work in Questa for some reason. vlog-2892 errors.
`default_nettype none // Disable implicit creation of undeclared nets
`endif

// This is a "faux mouse" to Symbolics encoder, so that we can
// test sending mouse signals to the console via the biphase
// encoder without having a real mouse.
//
// Inputs: 
// * 4 buttons for the four cardinal directions
// * 3 buttons for the mouse buttons
// * 3 switches (or a 3-bit integer) input for the mouse speed;
//   0 is the fastest (least delay)
// * Encoder busy signal
// * The usual clock & (positive) reset
//
// Outputs:
// * Data ready (For encoder) signal
// * data signal
//
// Parameters:
// * SHORT_PULSE = half bit-length for the biphase encoder, for
//   use in determining how long to wait between sending mouse
//   signals.
//
// Considerations:
// * The Symbolics console seems to send at most one mouse byte every
//   every 32 bit lengths. Since the bit length is 10 bits (8 data, 
//   each 1 stop/start), that means we have to wait 22 bit lengths before
//   we try to send another one. This may be unnecessary for the CPU,
//   but that's what the console does by observation.
// * This naively assumes that there is nothing else sending to the
//   CPU and is effectively connected directly to the CPU biphase encoder.
// * Every time we have a chance to send a byte, we will send either:
//   1. The mouse buttons have changed state
//   2. The mouse pointer is moving
// * If both opposing directions are "pushed" then we will not send motion
//   in either direction.
// * Console sometimes sends 0 for all four directions on a mouse move
//   command. Not sure yet why. (TODO: Figure that out.)
//
// Implementation:
// * When we want to send a byte, if things aren't busy, then 
//   we assert our byte ready (and set the
//   desired output data) and then go idle for the minimum retransmit
//   length.
// * After sending a move byte, we start a counter for when we could
//   send the next move byte, dependent on the mouse speed.
//   When the counter hits zero, we can send another move byte,
//   assuming any move buttons are down.
// * We prioritize sending button status change bytes.
//
// State:
// * Last button status sent
// * Timer since last anything sent (so we don't send more than
//   the minimum; we can send once zero
// * Timer until we can send a mouse move event; this gets set to
//   the current mouse move speed when we send a move command.

// FIXME: Have a parameter shared between both modules on the
// length of the delay_by_speed. How do we do this without letting
// that value escape this file?

localparam MOVE_DELAY_SIZE = 24;
localparam MOVE_DELAY_SIZE_MAX = MOVE_DELAY_SIZE - 1;
localparam MOVE_DELAY_1 = { {(MOVE_DELAY_SIZE-1){1'b0}}, 1'b1 };

// This module simply shows the minimum delay
// as adjusted by the pulse length.
// Returns a MOVE_DELAY_SIZE-bit value (the current highest value
// is only 20 bits long with the default SHORT_PULSE).
module delay_by_speed #(
  parameter SHORT_PULSE = 333
) (
  input  logic [2:0]  mouse_speed,
  output logic [MOVE_DELAY_SIZE_MAX:0] delay_count
);

localparam DELAY_BASE = SHORT_PULSE * 2 * 32; 

// These are arbitrarily defined
localparam MIN_DELAY = DELAY_BASE      - 1;
localparam DELAY_1   = DELAY_BASE * 2  - 1;
localparam DELAY_2   = DELAY_BASE * 4  - 1;
localparam DELAY_3   = DELAY_BASE * 6  - 1;
localparam DELAY_4   = DELAY_BASE * 8  - 1;
localparam DELAY_5   = DELAY_BASE * 12 - 1;
localparam DELAY_6   = DELAY_BASE * 16 - 1;
localparam MAX_DELAY = DELAY_BASE * 32 - 1;

always_comb
  case (mouse_speed)
    3'd0: delay_count    = MIN_DELAY[MOVE_DELAY_SIZE_MAX:0];
    3'd2: delay_count    = DELAY_2  [MOVE_DELAY_SIZE_MAX:0];
    3'd1: delay_count    = DELAY_1  [MOVE_DELAY_SIZE_MAX:0];
    3'd3: delay_count    = DELAY_3  [MOVE_DELAY_SIZE_MAX:0];
    3'd4: delay_count    = DELAY_4  [MOVE_DELAY_SIZE_MAX:0];
    3'd5: delay_count    = DELAY_5  [MOVE_DELAY_SIZE_MAX:0];
    3'd6: delay_count    = DELAY_6  [MOVE_DELAY_SIZE_MAX:0];
    3'd7: delay_count    = MAX_DELAY[MOVE_DELAY_SIZE_MAX:0];
    default: delay_count = MIN_DELAY[MOVE_DELAY_SIZE_MAX:0];
  endcase

endmodule


module faux_mouse_to_symbolics #(
  parameter SHORT_PULSE = 333 // 6⅔ µs at 50MHz
) (
  input logic clock,  // system-wide clock
  input logic reset,  // system-wide reset

  // User inputs
  input  logic       mouse_up,
  input  logic       mouse_down,
  input  logic       mouse_left,
  input  logic       mouse_right,
  input  logic       button_left,
  input  logic       button_middle,
  input  logic       button_right,
  input  logic [2:0] mouse_speed,

  // I/O to the biphase encoder
  input  logic       busy,
  output logic       data_ready,
  output logic [7:0] data_out
);

localparam COUNTER_SIZE = $clog2(SHORT_PULSE);
localparam COUNTER_1 = { {(COUNTER_SIZE-1){1'b0}}, 1'b1};
localparam COUNTER_START = SHORT_PULSE[COUNTER_SIZE-1:0] - 1'b1;

// Minimum delay for any two sends
localparam MIN_DELAY = SHORT_PULSE * 2 * 32;
localparam MIN_DELAY_SIZE = $clog2(MIN_DELAY);
localparam MIN_DELAY_1 = { {(MIN_DELAY_SIZE-1){1'b0}}, 1'b1 };
localparam MIN_DELAY_START = MIN_DELAY[MIN_DELAY_SIZE-1:0] - 1'b1;

// What buttons are currently down
logic [2:0] current_buttons;
assign current_buttons = {button_left, button_middle, button_right};

// What direction we want to move, if any;
// don't simultaneously assert opposing directions
logic [3:0] current_direction; // LRUD - see protocol.md
always_comb begin
  current_direction[3] = mouse_left  && !mouse_right;
  current_direction[2] = mouse_right && !mouse_left;
  current_direction[1] = mouse_up    && !mouse_down;
  current_direction[0] = mouse_down  && !mouse_up;
end

// How long do we delay if we move?
logic [MOVE_DELAY_SIZE_MAX:0] current_delay;
// This module is combinational, so it's like an always_comb.
delay_by_speed #(
  .SHORT_PULSE(SHORT_PULSE) // can't do just .SHORT_PULSE with Quartus 21.1
) delay_by_speed (
  .mouse_speed,
  .delay_count(current_delay)
);

// What was the last sent button press
logic [2:0] last_sent_buttons = '0;

// Delay counters
logic [MIN_DELAY_SIZE-1:0] min_delay_counter;
logic [MOVE_DELAY_SIZE_MAX:0] move_delay_counter;

// Next value for each counter (current minus 1)
logic [MIN_DELAY_SIZE-1:0] next_min_delay_counter;
logic [MOVE_DELAY_SIZE_MAX:0] next_move_delay_counter;
assign next_min_delay_counter  = min_delay_counter  - MIN_DELAY_1;
assign next_move_delay_counter = move_delay_counter - MOVE_DELAY_1;

// can we not move (is the move counter not 0)?
logic cannot_move;
assign cannot_move = move_delay_counter != 0;

// can we not send anything (min delay not 0)?
logic cannot_send;
assign cannot_send = min_delay_counter != 0;

always @(posedge clock) begin

  if (reset) begin
    min_delay_counter <= MIN_DELAY_START;
    move_delay_counter <= MIN_DELAY_START;
    last_sent_buttons <= '0;
    data_ready <= '0;

  end else if (busy) begin
    // The encoder is busy, so there is nothing for us to do
    // but wait our turn.
    if (cannot_send)
      min_delay_counter <= next_min_delay_counter;
    if (cannot_move)
      move_delay_counter <= next_move_delay_counter;
    
    data_ready <= '0;

  end else if (data_ready) begin
    // We want to send data, but the encoder didn't yet
    // start transmitting it (isn't busy), so let's just wait for it
    // to become busy.

    // DO NOTHING about our counters.
    // If our current command is a not a move command, though, we
    // could decrement our move delay counter if we wanted.
    assert(!busy);

    // TODO: We should track how often this happens, and how long
    // it happens for, if we care.

  end else if (cannot_send) begin
    // We just recently sent something, so we can't do anything yet
    // until our next reasonable opportunity. 

    assert(!data_ready); // We're not waiting to start sending something
    min_delay_counter <= next_min_delay_counter;
    if (cannot_move)
      move_delay_counter <= next_move_delay_counter;


  end else if (current_buttons != last_sent_buttons) begin
    // We have to send some button presses.
    // This takes precedence over sending mouse movement
    // codes.

    // Set the data_out (see protocol.md in c5g_symdec)
    // for a mouse button change.
    data_out <= {
      1'b1,   // always 1
      3'b000, // mouse button command
      // next nibble: LMRF (F = fourth button, not implemented)
      current_buttons,
      1'b0 // fourth button;
    };
    data_ready <= '1;
    last_sent_buttons <= current_buttons;
    min_delay_counter <= MIN_DELAY_START;

    // We still have to update our move delay counter, but
    if (cannot_move)
      move_delay_counter <= next_move_delay_counter;

  end else if (!cannot_move && current_direction != '0) begin
    // We want to move a certain direction and can do it
    // based upon our previous speed.

    // Set the data_out (see protocol.md in c5g_symdec)
    // for a mouse move
    data_out <= {
      1'b1,   // always 1
      3'b001, // mouse button command
      // next nibble: LRUD
      current_direction
    };
    data_ready <= '1;
    min_delay_counter <= MIN_DELAY_START;
    move_delay_counter <= current_delay;

  end // Mouse handling "state machine"

end // always clock



endmodule


`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// Restore the default_nettype to prevent side effects
// See: https://front-end-verification.blogspot.com/2010/10/implicit-net-declartions-in-verilog-and.html
// and: https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_presentation.pdf
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif
