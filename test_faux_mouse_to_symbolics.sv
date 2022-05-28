// Copyright 2022 Douglas P. Fields, Jr. All Rights Reserved.

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// This doesn't work in Questa/ModelSim for some reason.
`default_nettype none // Disable implicit creation of undeclared nets
`endif


// Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps

module test_faux_mouse_to_symbolics();

// Simulator generated clock & reset
logic  clock;
logic  reset;

// generate clock to sequence tests
always begin
  // 50 Mhz (one full cycle every 20 ticks at 1ns per tick per above)
  #10 clock <= ~clock;
end

// Should we output non-error messages?
localparam [0:0] SHOW_OUTPUT = '0; // '0 or '1

// How long our half-bit lengths are (short for simulation)
localparam SHORT_PULSE = 5;

//////////////////////////////////////////////////////////////
// Our device under test - the biphase encoder

// Create our device under test (biphase encoder)
logic biphase_encoder_busy;

// What we're going to send to biphase encoder
logic       mouse_data_ready;
logic [7:0] mouse_data;

// Our mouse inputs
logic       mouse_up;
logic       mouse_down;
logic       mouse_left;
logic       mouse_right;
logic       button_left;
logic       button_middle;
logic       button_right;
logic [2:0] mouse_speed;

faux_mouse_to_symbolics #(
  .SHORT_PULSE(SHORT_PULSE)
) dut (
  .clock, .reset,

  .mouse_up, .mouse_down,
  .mouse_left, .mouse_right,
  .button_left, .button_middle, .button_right,
  .mouse_speed,

  .busy(biphase_encoder_busy),
  .data_ready(mouse_data_ready),
  .data_out(mouse_data)
);


fake_biphase_encoder #(
  .SHORT_PULSE(SHORT_PULSE)
) fake_biphase_encoder ( // Device Under Test
  .clk(clock),
  .rst(reset),

  // Inputs
  .data_ready(mouse_data_ready),
  .data_in(mouse_data),

  // Outputs
  .busy(biphase_encoder_busy),

  // Debugging outputs
  .dbg_start_bit(), .dbg_stop_bit(), .dbg_data_bits()
);


///////////////////////////////////////////////////////////////
// Reset driver and end of test handler

// initialize test with a reset for 22 ns
initial begin
  $display("Starting Simulation  @ ", $time);
  clock <= 1'b0;
  reset <= 1'b1; 
  #22; 
  
  reset <= 1'b0;

  // Set what commands we are sending
  mouse_up <= '1;
  mouse_down <= '0;
  mouse_left <= '0;
  mouse_right <= '0;

  button_left <= '0;
  button_right <= '0;
  button_middle <= '0;

  mouse_speed <= 3'd0;

  // Stop the simulation in due course.
  #50_000;
  $display("Ending simulation    @ ", $time);
  $stop; // $stop = breakpoint
  // DO NOT USE $finish; it will exit Questa!!!
end


endmodule



`ifdef IS_QUARTUS
`default_nettype wire // Restore default
`endif