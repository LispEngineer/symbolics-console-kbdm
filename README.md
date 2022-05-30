# Symbolics Console to CPU emulator

*Copyright 2022 Douglas P. Fields, Jr. All Rights Reserved.*

# Cyclone V GX Inputs & Outputs

Inputs used for the faux mouse:
* Button 0: reset
  * Note, the manual calls these "keys" and they are logic LOW when pressed
* Buttons 3-1: Left, middle, right mouse buttons
* GPIO 5: Biphase output to console
* GPIO 6: Non-biphase output (for debugging by a UART decoder)
* GPIO 15-12: "Mouse" direction control buttons
  * Using Digilent Pmod BTN, logic HIGH when pressed
* Switches 9-7: "Mouse" speed

LED outputs:
* Green 0: reset
* Green 7-5: Mouse buttons
* Red 3-0: Mouse direction buttons
* Red 9-7: Mouse speed
* Hex display: Mouse speed setting (0 is fastest, 7 is slowest)
* Green 2, 3: Biphase, UART outputs

Some notes on this board's GPIO:
* 0, 2 = Dedicated clock inputs
* 3-18 = also on Arduino header
* 16, 18 = PLL clock outputs
* 22-35 = HEX 2-3


# Block Diagram

PS/2 mouse initializer -> PS/2 mouse decoder -> 
PS/2 mouse event FIFO -> PS/2 to Symbolics mouse event converter -> 
Symbolics mouse event FIFO

PS/2 Keyboard decoder -> PS/2 keyboard event FIFO -> 
PS/2 to Symbolics keyboard event converter -> Symbolics keyboard FIFO

Symbolics [mouse / keyboard] FIFOs -> FIFO aribter ->
Console data out FIFO -> FIFO to serial converter -> Biphase encoder ->
RS-422 hardware layer -> ...and finally... Symbolics CPU

# Biphase output

* 75 kHz = 13⅓ µs
  * 666⅔ cycles at 50 MHz - call it 666 cycles (really 667, but that's not divisible by 2)
* Mark/1 = long pulse
* Space/0 = two short pulses
  * 333⅓ cycles at 50 MHz - call it 333 cycles
* Idle = marking (1's)
* Encoding = 1 start bit, 8 data bits, 1 stop bit

This encoding is then converted to RS-422 logic levels and sent to the CPU.

# Status

* Simple mouse emulator (4 directions & 3 buttons & several speeds)
  * "Faux" mouse encoder: complete
  * Simple waveform test harness for "faux" mouse encoder: complete
  * Actual inputs for mouse encoder: UNSTARTED
    * External button de-bouncer
    * Speed selector using rotary encoder (optional) vs. three switches
  * Output to RS422 sender for biphase encoded mouse data: UNSTARTED
  * Duplicated mouse data sent out as non-biphase UART: UNSTARTED
    (to monitor on the Analog Discovery 2 before attaching the real CPU)
  * Testing the faux mouse
* Biphase Encoder: complete
  * Test harness including decoder: complete

# TODO

* Add a UART non-biphase out from the biphase encoder?
  (So that a regular UART decoder can see the biphase data.)
  This may be harder than it seems simply because the encoder can decide to change
  the output bit half way through it (and does take advantage of that).
* Add a FIFO tied to the biphase encoder
  * This can be relatively small as it will be fed from two upstream FIFOs
  * This will be a single-byte FIFO
* Add two FIFOs for Symbolics keyboard and mouse events that feed into the biphase encoder FIFO
  * The keyboard FIFO should have priority in the arbiter feeding two into one
  * The keyboard FIFO can be small (people don't type too fast), but it's two bytes wide
  * The mouse FIFO probably needs to be reasonably large but it's just one byte wide
  * The arbiter needs to take one keyboard FIFO entry of two bytes and turn it into
    two biphase encoder FIFO entries of one byte
* Add PS/2 mouse decoder that feeds into a PS/2 mouse event FIFO
  * These are read by a PS/2 to Symbolics mouse event controller
  * Which then feeds into the Symbolics mouse FIFO
* Add PS/2 keyboard decoder that feeds into a PS/2 keyboard event FIFO
  * These events are read by a PS/2 to Symbolics keyboard event controller
  * Which feeds into the Symbolics keyboard FIFO

## TODONE

* `DONE` Expand the biphase encoder tests to send all possible bytes
  with a variety of delays between
  them and make sure that they all get received correctly.
  * Only make output if there are test failures.


# Notes on Test Harness

Ensure Quartus Settings -> Simulation shows `Questa Intel FPGA`

Do not use `$finish;` in your simulation - it will quit Questa
and you will have to do everything below all over again!

Setting up Quartus to load the Test Harness in Questa:
* See [Quick Start](https://www.intel.com/content/www/us/en/docs/programmable/703090/21-1/simulation-quick-start.html)
  documentation section 1.2, figures 3-4
* Quartus: Assignments -> Settings -> EDA Tool Settings -> Simulation
* NativeLink Settings -> Compile test bench
* Click `Test Benches...` then `New`
* Add a name (e.g., `testbench_1`) and specify `test_biphase_encoder` as top-level module
* Add the file `test_biphase_encoder.sv` and mark it as SystemVerilog
* NOW, when you run the `RTL Simulation` it will open this by default.
* You will still need to save the waves as you like them and reload them (per below).

To actually run the simulation:
* Run Questa: `Tools -> Run Simulation Tool -> RTL Simulation...`
* Compile -> Compile... -> `test_biphase_encoder.sv`, Click `Compile`
  * Then close Compile window by clicking `Done`
* Now it appears in `Library` under `work -> test_biphase_encoder`
* Right click `test_biphase_encoder` and select "Simulate"
* Now you see a window `sim - Default` that replaced the `Library` window
* Highlight the `test_biphase_encoder` line in `sim`, and it shows all the `Objects`
  in another window.
* Select all the signals (`Objects`) and right click, `Add Wave`
  * Note: This may not be necessary if Questa/Quartus defaulted to showing them
* Simulate -> Run -> Run 100
  * Or Run -All then it will go until `$stop` (if you use `$finish` - do not say YES!!)
* If you edit anything, go back to `Library`, right click `Recompile`
* To restart simulation: `Simulate -> Restart...`
* You can save your waves
* You can load saved waves with File -> Load -> Macro File... and then
  choose `test1-wave.do`
* When you change things, you still have to right-click & `Recompile` in the `Library`
  * This is a long command in `VSIM ##>` prompt
* Then you can type at the `VSIM ##>` prompt `restart -f ; run -all`

Misc
* If you accidentally create a Wave Window Pane: `Wave -> Delete Window Pane`
* Questa PDF documentation is in the `Help` menu
* [See here](https://verificationacademy.com/forums/systemverilog/error-suppressible-vlog-7061-alwaysff-modelsim) for some information on the vlog-7061 Questa error
* To stop Questa/ModelSim from opening up the source file in its internal editor
  when `$stop` is encountered:
  * Tools -> Edit preference -> By Name -> Source -> OpenOnBreak: Set to '0' 
  * [Source](https://www.edaboard.com/threads/modelsim-error-assertion-causes-file-to-open.246441/)

## Test Implementation Notes

* Why is the test harness `data_ready` signal being asserted for two cycles? (If you look
  at the simulator output.)
  * We assert `data_ready`
  * Next cycle, biphase encoder sees it, asserts `busy_out`
  * Next cycle, we see `busy_out`, de-assert `data_ready` - hence two cycles
* We use a SystemVerilog queue to store the bytes we (think we) send, to compare
  with the bytes from the UART receiver, because sometimes the latency of sending
  two characters quickly is faster than the UART can decode one.
  * This happens when the delay between transmitter sends becomes less
    than the latency of the UART byte decoder, which is at least 22
    cycles for NRZ decoder and some more for UART. In practice once
    the delay gets down to 24 it transmits the next byte faster than the
    total decoder latency.
* We send random bytes after random delays over and over again, and make sure
  that the biphase decoded, UART decoded bytes received are the same.


# Debugging Notes

Notes to self to pick up mental state next time if I have to stop
in the middle of a debugging session.

Note on using the Altera USB-Blaster and the Digilent Analog Discovery 2:
These two things cannot be plugged into the computer simultaneously, or
the Altera/Quartus FPGA programmer will not see the FPGA. Apparently they
use the same FTDI chip or something. I have gotten it to work accidentally
once; I imagine the USB enumerator put them in a different order or something,
but in general, you need to unplug the Analog Discovery 2 if you want to use
the USB interface to the Cyclone V GX Starter Kit.

## Fixed bugs

*Key realization*
* The biphase out long pulse length is 22, instead of the expected 20 clocks!!!
  * FIX: The counter was counting from N to 0, instead of N-1 to 0, causing it to
    run for one additional cycle (oops, typical off-by-one error).

# References

* [Quartus Verilog HDL Synthesis Attributes](https://www.intel.com/content/www/us/en/programmable/quartushelp/17.0/hdl/vlog/vlog_file_dir.htm)
* [Verilog $display details](https://www.chipverify.com/verilog/verilog-display-tasks)
* [Visual Studio Code Color Themes](https://code.visualstudio.com/docs/getstarted/themes)
  * Add this to `settings.json` to make the editor background pure black:
  ```
    "workbench.colorCustomizations": {
      "editor.background": "#000000"
    }
  ```
* SystemVerilog Queues 
  [Reference_1](https://www.chipverify.com/systemverilog/systemverilog-queues)
  [Reference_2](https://verificationguide.com/systemverilog/systemverilog-queue/)
  * [Void casts](https://verificationacademy.com/forums/systemverilog/treating-stand-alone-use-function-implicit-void-cast)
* Digilent [Pmod BTN](https://digilent.com/shop/pmod-btn-4-user-pushbuttons/)