// Copyright 2022 Douglas P. Fields, Jr. All Rights Reserved.

`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// This doesn't work in Questa for some reason. vlog-2892 errors.
`default_nettype none // Disable implicit creation of undeclared nets
`endif


module c5g_symenc(

  //////////// CLOCK //////////
	input logic         CLOCK_125_p,
	input logic         CLOCK_50_B5B,
	input logic         CLOCK_50_B6A,
	input logic         CLOCK_50_B7A,
	input logic         CLOCK_50_B8A,
  
	//////////// LED //////////
	output logic [7:0]  LEDG,
	output logic [9:0]  LEDR,
  
	//////////// KEY //////////
	input  logic        CPU_RESET_n,
	input  logic [3:0]  KEY,
  
	//////////// SW //////////
	input  logic [9:0]  SW,
  
	//////////// SEG7 //////////
	output logic [6:0]  HEX0,
	output logic [6:0]  HEX1,
  
	//////////// Uart to USB //////////
	input  logic        UART_RX,
	output logic        UART_TX,
  
	//////////// SRAM //////////
	output logic [17:0] SRAM_A,
	output logic        SRAM_CE_n,
	inout  wire  [15:0] SRAM_D,
	output logic        SRAM_LB_n,
	output logic        SRAM_OE_n,
	output logic        SRAM_UB_n,
	output logic        SRAM_WE_n,

	//////////// SDCARD //////////
	output logic        SD_CLK,
	inout  logic        SD_CMD,
	inout  wire  [3:0]	SD_DAT,
  
	//////////// GPIO, GPIO connect to GPIO Default //////////
	inout  wire  [35:0] GPIO 
	// 22-35 are HEX2-3
	// 0,2 are dedicated clock inputs
	// 3-18 are Arduino I/O
	// 16, 18 are PLL clock outputs
);

// =======================================================
// Signal declarations

// Main signals throughout the board
logic clock;
logic reset;

// Reimplement HEX2-3 from GPIO
logic [6:0] HEX2, HEX3;

// 7 Segment outputs
logic [6:0] ss0, ss1, ss2, ss3;

// The output of 75 kHz biphase encoded RS422 transmit to the CPU
logic biphase_out;
logic biphase_busy;

// Conversion of our biphase signal to UART signal
logic uart_out;

// Our "Faux Mouse" inputs
logic mouse_direction_up;
logic mouse_direction_down;
logic mouse_direction_left;
logic mouse_direction_right;
logic mouse_button_left;
logic mouse_button_middle;
logic mouse_button_right;
logic [2:0] mouse_speed;

// Outputs from the faux mouse encoder
// which are also inputs to the biphase encoder.
logic mouse_data_ready;
logic [7:0] mouse_data;

// The input to the 4 digit hex display
logic [15:0] hexin;

// ======================================================
// DEFAULTS (remove if using these pins)

// Output pins (not used for monitoring... yet)
assign LEDG[1] = '0;
assign LEDG[4] = '0;
assign LEDR[6:4] = '0;

assign UART_TX = '0;
assign {SRAM_A, SRAM_CE_n, SRAM_LB_n, SRAM_OE_n, SRAM_UB_n, SRAM_WE_n} = '0;
assign SD_CLK = '0;

// Bidi pins - set them to high impedance
assign SRAM_D = 'z;
assign {SD_CMD, SD_DAT} = 'z;

// GPIO 35-22 used for HEX2-3
// GPIO 5 = Biphase encoded data stream out
// GPIO 6 = UART encoded data stream out
// GPIO 15-12 = mouse direction button input
assign GPIO[21:16] = 'z;
assign GPIO[11:7] = 'z;
assign GPIO[4:0] = 'z;

// =======================================================
// Main clock and reset

assign clock = CLOCK_50_B5B;
assign reset = ~KEY[0];

// =======================================================
// Hex encoders

// Our HEX2-3 overlap with GPIO;
assign GPIO[28:22] = HEX2;
assign GPIO[35:29] = HEX3;

// Terasic wires their 7 segment hex displays backwards, so a positive
// signal turns off the LED.
assign HEX0 = ~ss0;
assign HEX1 = ~ss1;
assign HEX2 = ~ss2;
assign HEX3 = ~ss3;

// Show data on hex 0-3
seven_segment hex0 (
  .num(hexin[3:0]),
  .hex(ss0)
);
seven_segment hex1 (
  .num(hexin[7:4]),
  .hex(ss1)
);
seven_segment hex2 (
  .num(hexin[11:8]),
  .hex(ss2)
);
seven_segment hex3 (
  .num(hexin[15:12]),
  .hex(ss3)
);

/////////////////////////////////////////////////////////
// Faux mouse to Symbolics encoder

faux_mouse_to_symbolics mouse_encoder (
	.clock, .reset,

	// "Faux mouse" inputs
  .mouse_up(mouse_direction_up),
  .mouse_down(mouse_direction_down),
  .mouse_left(mouse_direction_left),
  .mouse_right(mouse_direction_right),
  .button_left(mouse_button_left),
  .button_middle(mouse_button_middle),
  .button_right(mouse_button_right),
  .mouse_speed,

	// Is the biphase output encoder busy?
  .busy(biphase_busy),

	// What should we send via the biphase encoder
  .data_ready(mouse_data_ready),
  .data_out(mouse_data)
);


/////////////////////////////////////////////////////////
// Biphase encoder (using the mouse data)

biphase_encoder biphase_enc (
  .clk(clock),
  .rst(reset),

  // Inputs from the mouse encoder
  .data_ready(mouse_data_ready), 
	.data_in(mouse_data),

  // Our encoded data stream output
	.busy(biphase_busy),
  .biphase_out(biphase_out),

  // Unneeded
  .clock_out(), 

  // TODO: Debugging outputs
  .dbg_first_half(), .dbg_current_bit()
);

///////////////////////////////////////////////////////////
// Wire up biphase decoder and send the decoded UART
// information to another external GPIO (module biphase_to_nrz).
// (This seems easier to do than to add UART output to the
// biphase encoder.)

biphase_to_nrz biphase_uart (
  .clk(clock),
  .rst(reset),

	// Inputs
  .biphase_in_raw(biphase_out),

	// Outputs
  .nrz_out(uart_out),
	// Unused outputs
  .clock_out(),
  .data_received(),
  .framing_error(),
  .glitch_ignored(),

	// Debugging outputs
  .counter_overflow()
);


///////////////////////////////////////////////////////////
// GPIO Inputs & Outputs

// Hook up our encoder to send to the RS422 UART input
assign GPIO[5] = biphase_out;
// And also a debugging output of the same data (a few clocks delayed)
// in UART format (but still 75 kHz)
assign GPIO[6] = uart_out;

// Our "faux mouse" input

// 4 directional buttons from a Digilent PmodBTN
//   https://digilent.com/shop/pmod-btn-4-user-pushbuttons/
//   0 = up, 1 = right, 2 = left, 3 = down
//   Fully debounced and Schmitt-triggered
//   Logic high when pressed
// mapped to GPIO 12-15
assign mouse_direction_up    = GPIO[12];
assign mouse_direction_down  = GPIO[15];
assign mouse_direction_left  = GPIO[14];
assign mouse_direction_right = GPIO[13];

// Use the mouse buttons from the console of the FPGA board.
// Logic LOW when pressed (unlike the above).
assign mouse_button_left   = ~KEY[3];
assign mouse_button_middle = ~KEY[2];
assign mouse_button_right  = ~KEY[1];

// The speed is set in binary from the first three switches
assign mouse_speed = SW[9:7];
assign hexin[15:3] = '0;
assign hexin[2:0] = mouse_speed;


// Monitor the inputs and outputs on the LEDS
assign LEDG[0] = reset;
assign LEDG[7] = mouse_button_left;
assign LEDG[6] = mouse_button_middle;
assign LEDG[5] = mouse_button_right;
// Direction LEDs in the hjkl order (LDUR)
assign LEDR[3] = mouse_direction_left;
assign LEDR[2] = mouse_direction_down;
assign LEDR[1] = mouse_direction_up;
assign LEDR[0] = mouse_direction_right;
assign LEDR[9:7] = mouse_speed;

assign LEDG[2] = biphase_out;
assign LEDG[3] = uart_out;


endmodule


`ifdef IS_QUARTUS // Defined in Assignments -> Settings -> ... -> Verilog HDL Input
// Restore the default_nettype to prevent side effects
// See: https://front-end-verification.blogspot.com/2010/10/implicit-net-declartions-in-verilog-and.html
// and: https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_presentation.pdf
`default_nettype wire // turn implicit nets on again to avoid side-effects
`endif
