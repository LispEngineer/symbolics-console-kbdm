// Copyright 2022 Douglas P. Fields, Jr. All Rights Reserved.

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// This doesn't work in Questa/ModelSim for some reason.
`default_nettype none // Disable implicit creation of undeclared nets
`endif


// Tick at 1ns (using #<num>) to a precision of 0.1ns (100ps)
`timescale 1 ns / 100 ps
// This makes for approximately 320ns between I2C clock pulses when
// things are running stable-state.
module test_biphase_encoder();

// Simulator generated clock & reset
logic  clock;
logic  reset;

// generate clock to sequence tests
always begin
  // 50 Mhz (one full cycle every 20 ticks at 1ns per tick per above)
  #10 clock <= ~clock;
end

// Create our device under test (biphase encoder)
logic biphase_out;
logic dbg_first_half;
logic dbg_current_bit;

biphase_encoder #(
  // We don't need to do 75 kHz; we can do much faster for our simulator
  .SHORT_PULSE(10)
) dut ( // Device Under Test
  .clk(clock),
  .rst(reset),

  // TODO
  .data_ready('0), .data_in('0),

  // Our encoded data stream output
  .biphase_out,

  // TODO
  .clock_out(), .busy(),

  // Debugging outputs
  .dbg_first_half, 
  .dbg_current_bit
);


// initialize test with a reset for 22 ns
initial begin
  $display("Starting Simulation @ ", $time);
  clock <= 1'b0;
  reset <= 1'b1; 
  #22; reset <= 1'b0;
  // Stop the simulation at appropriate point
  #501;
  $display("Ending simulation @ ", $time);
  $stop; // $stop = breakpoint
  // DO NOT USE $finish; it will exit Questa!!!
end

endmodule



`ifdef IS_QUARTUS
`default_nettype wire // Restore default
`endif