// Copyright 2022 Douglas P. Fields, Jr. All Rights Reserved.

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// This doesn't work in Questa/ModelSim for some reason.
`default_nettype none // Disable implicit creation of undeclared nets
`endif


// Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps

module test_biphase_encoder();

// Simulator generated clock & reset
logic  clock;
logic  reset;

// Last byte sent to the encoder
logic [7:0] last_sent_to_encoder;

`ifndef IS_QUARTUS
// QUARTUS DOES NOT SUPPORT SYSTEM VERILOG QUEUES
// Queue of bytes sent to the encoder (to check against bytes received
// by the decoder).
logic [7:0] encoder_queue [$];
`endif

// generate clock to sequence tests
always begin
  // 50 Mhz (one full cycle every 20 ticks at 1ns per tick per above)
  #10 clock <= ~clock;
end

// Shared parameters for the test
localparam ENCODER_SHORT_PULSE = 10;
localparam DECODER_SHORT_PULSE = 7; // 75%-ish of the encoder length
localparam DECODER_IGNORE_PULSE = 3;

localparam SEND_CHARS = 10_000;
localparam SEND_COUNTER_LEN = $clog2(SEND_CHARS);

// Should we output non-error messages?
localparam [0:0] SHOW_OUTPUT = '0; // '0 or '1

//////////////////////////////////////////////////////////////
// Our device under test - the biphase encoder

// Create our device under test (biphase encoder)
logic biphase_out;
logic busy_out;
logic dbg_first_half;
logic dbg_current_bit;

// What we're sending
logic data_ready;
logic [7:0] data_in;

biphase_encoder #(
  // We don't need to do 75 kHz; we can do much faster for our simulator
  .SHORT_PULSE(ENCODER_SHORT_PULSE)
) dut ( // Device Under Test
  .clk(clock),
  .rst(reset),

  // Assert when !busy_out
  .data_ready,
  // Data is sent LSB first
  .data_in,

  // Our encoded data stream output
  .biphase_out,

  .clock_out(),   // TODO
  .busy(busy_out),

  // Debugging outputs
  .dbg_first_half, 
  .dbg_current_bit
);

// Delay the biphase out by a while to make it match with
// the NRZ decoded, so we can see them together in the
// output graph

localparam NRZ_SYNCHRONIZER_LENGTH = 2;
localparam BIPHASE_TO_NRZ_DELAY = 
  2 * ENCODER_SHORT_PULSE + // Length of a bit 
  NRZ_SYNCHRONIZER_LENGTH + // NRZ input synchronizer
  1; // ?? Regular latency for biphase decoder?

// Shift from LSB to MSB
logic [BIPHASE_TO_NRZ_DELAY-1:0] b2n_delay;
logic biphase_out_delayed;

always_ff @(posedge clock) begin
  b2n_delay = {b2n_delay[BIPHASE_TO_NRZ_DELAY-2:0], biphase_out};
end

assign biphase_out_delayed = b2n_delay[BIPHASE_TO_NRZ_DELAY-1];

// If we wanted, we could now do a comparison between the
// biphase_out_delayed and the nrz_out as they are now
// cycle-for-cycle saying the same thing in biphase and NRZ encoding.

// Now do the same thing with the current bit debug output to more
// easily compare with the NRZ out.
localparam DCB_DELAY =  // DCB = dbg_current_bit
  3 * ENCODER_SHORT_PULSE + // Length of a bit plus half bit lookahead
  NRZ_SYNCHRONIZER_LENGTH + // NRZ input synchronizer
  1; // ?? Regular latency for biphase decoder?

logic [DCB_DELAY-1:0] dcb_delay;
logic dbg_current_bit_delayed;

always_ff @(posedge clock) begin
  dcb_delay = {dcb_delay[DCB_DELAY-2:0], dbg_current_bit};
end

assign dbg_current_bit_delayed = dcb_delay[DCB_DELAY-1];

///////////////////////////////////////////////////////////////
// Let's see if we can decode the biphase, and then run the
// NRZ through a UART...

logic nrz_out;            // The logic level output (feed into UART decoder)
logic nrz_data_received;  // pulses when we have a valid nrz_out complete bit
logic nrz_framing_error;  // Pulses when we notice a biphase framing error
logic nrz_glitch_ignored; // Pulses when we notice a glitch (short biphase pulse)
logic dbg_nrz_counter_overflow;

biphase_to_nrz #(
  .SHORT_PULSE(DECODER_SHORT_PULSE),
  .IGNORE_PULSE(DECODER_IGNORE_PULSE)
) biphase_to_nrz (
  .clk(clock),
  .rst(reset),

  // Inputs - remember that the decoder puts the input
  // through a synchronizer chain (irrelevant for simulation,
  // but important for avoiding real-world metastability) that
  // adds a few cycles of latency before decoding.
  .biphase_in_raw(biphase_out),

  // Outputs
  .nrz_out,
  .clock_out(), // TODO
  .data_received(nrz_data_received),
  .framing_error(nrz_framing_error),
  .glitch_ignored(nrz_glitch_ignored),

  // Debugging outputs
  .counter_overflow(dbg_nrz_counter_overflow)
);

always_ff @(posedge clock) begin
  if (nrz_framing_error)
    $display("NRZ framing error    @ ", $time);
  if (nrz_glitch_ignored)
    $display("NRZ glitch ignored   @ ", $time);
  if (dbg_nrz_counter_overflow)
    $display("NRZ counter overflow @ ", $time);
end


///////////////////////////////////////////////////////////////
// Attempt to decode the NRZ out as 8-N-1 UART data.

logic uart_data_valid;
logic [7:0] uart_data_byte;

logic [SEND_COUNTER_LEN-1:0] received_count = '0;
logic [SEND_COUNTER_LEN-1:0] received_errors = '0;

uart_rx #(
  .CLKS_PER_BIT(2 * ENCODER_SHORT_PULSE)
) uart_rx (
  .clock(clock), // Not sure why Quartus gave me an error with just .clock,
  .reset(reset),

  // Inputs
  .rx_uart(nrz_out),

  // Outputs
  .data_valid(uart_data_valid),
  .data_byte(uart_data_byte),

  // Debugging
  .state() // Intentional no-connection
);

always_ff @(posedge clock) begin
  if (uart_data_valid) begin
    // Compare received byte to the last one sent & not received
`ifndef IS_QUARTUS
    // (QUARTUS does not support SystemVerilog queues)
    if (SHOW_OUTPUT)
      $display("UART data received   @ ", $time, "           - DATA - ", 
               uart_data_byte, " R - EXPECTED: ", encoder_queue[$],
               "   DIFF: ", (encoder_queue[$] - uart_data_byte));

    // Check for reception errors
    if (uart_data_byte != encoder_queue[$]) begin
      received_errors <= received_errors + 1'b1;
      $display("UART data *ERROR*    @ ", $time, "           - DATA - ", 
               uart_data_byte, " R - EXPECTED: ", encoder_queue[$],
               "   DIFF: ", (encoder_queue[$] - uart_data_byte),
               " ***************");
    end

    // Pop the byte off the encoder queue
    // (cast to void as we're not using the encoded value)
    void'(encoder_queue.pop_back());
`endif
    received_count <= received_count + 1'b1;
  end
end


///////////////////////////////////////////////////////////////
// Data driver for the test.
// We want to test asserting the data_ready signal at all possible
// points in the biphase encoder cycle. Since it uses a short pulse
// of 10, it has 20 possible start points, so we will use 2^5 delay count
// after busy is de-asserted to cover all the possibilities.


// Send after a certain number of cycle delay
logic [7:0] start_delay;
logic [7:0] random_delay;
logic       last_busy_out;
logic [7:0] next_to_send;

// Send a random byte every time it is not busy,
// after waiting a random number of cycles.
always_ff @(posedge clock) begin

  last_busy_out <= busy_out;

  if (!reset) begin

    if (!busy_out) begin

      if (last_busy_out) begin
        // We just got unbusy, cleared to send in a bit
        random_delay = $urandom();
        if (SHOW_OUTPUT)
          $display("Moving to next round @ ", $time, 
                   " delay: ", random_delay);
        start_delay <= random_delay;
      end else begin
        // Wait until we send it
        start_delay <= start_delay - 5'b1;
      end

      if (start_delay == 0) begin
        next_to_send = $urandom();
        if (SHOW_OUTPUT)
          $display("Starting to send     @ ", $time, " ", 
                   "          - DATA - ", next_to_send, " T");
        // Send the data!
        data_ready <= '1;
        data_in <= next_to_send;
        last_sent_to_encoder <= next_to_send;
`ifndef IS_QUARTUS
        // (QUARTUS does not support SystemVerilog queues)
        encoder_queue.push_front(next_to_send);
`endif
      end

    end else begin
      // The system is busy right now so...
      data_ready <= '0;
    end // !busy_out

  end else begin
    // Reset
    data_ready <= '0;
    start_delay <= 8'b0001_0000;
  end

end // Send different bytes after different delays

///////////////////////////////////////////////////////////////
// Reset driver and end of test handler

// initialize test with a reset for 22 ns
initial begin
  $display("Starting Simulation  @ ", $time);
  clock <= 1'b0;
  reset <= 1'b1; 
  #22; reset <= 1'b0;

  // Stop the simulation in due course.
  // TODO: Stop simulation after N errors or Y characters.
  /*
  #500_000;
  $display("Ending simulation    @ ", $time);
  $stop; // $stop = breakpoint
  // DO NOT USE $finish; it will exit Questa!!!
  */
end

always @(posedge clock) begin
  // Check for simulation end
  if (received_count >= SEND_CHARS) begin
    $display("Ending simulation    @ ", $time);
    $display("Received count: ", received_count);
    $display("Received errors: ", received_errors);
    $stop; // Breakpoint - do not use $finish as it will exit Questa
  end
end


endmodule



`ifdef IS_QUARTUS
`default_nettype wire // Restore default
`endif