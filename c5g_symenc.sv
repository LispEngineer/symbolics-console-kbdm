// Copyright 2022 Douglas P. Fields, Jr. All Rights Reserved.

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

//=======================================================
//  REG/WIRE declarations

// Main signals throughout the board
logic clock;
logic reset;

// Reimplement HEX2-3 from GPIO
logic [6:0] HEX2, HEX3;

// 7 Segment outputs
logic [6:0] ss0, ss1, ss2, ss3;


// ======================================================
// DEFAULTS (remove if using these pins)

// Output pins
assign LEDG = '0;
assign LEDR = '0;
assign UART_TX = '0;
assign {SRAM_A, SRAM_CE_n, SRAM_LB_n, SRAM_OE_n, SRAM_UB_n, SRAM_WE_n} = '0;
assign SD_CLK = '0;

// Bidi pins - set them to high impedance
assign SRAM_D = 'z;
assign {SD_CMD, SD_DAT} = 'z;
// Rest of GPIO used for HEX2-3
assign GPIO[21:0] = 'z;

//=======================================================
//  Structural coding

// Pick our main clock and reset
assign clock = CLOCK_50_B5B;
assign reset = ~KEY[0];

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
  .num(4'hA),
  .hex(ss0)
);
seven_segment hex1 (
  .num(4'hB),
  .hex(ss1)
);
seven_segment hex2 (
  .num(4'hF),
  .hex(ss2)
);
seven_segment hex3 (
  .num(4'hD),
  .hex(ss3)
);





endmodule
