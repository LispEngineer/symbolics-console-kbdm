# Symbolics Console to CPU emulator

*Copyright 2022 Douglas P. Fields, Jr. All Rights Reserved.*

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

* Biphase Encoder underway with test harness; incomplete!

# TODO

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

# References

* [Quartus Verilog HDL Synthesis Attributes](https://www.intel.com/content/www/us/en/programmable/quartushelp/17.0/hdl/vlog/vlog_file_dir.htm)
* [Verilog $display details](https://www.chipverify.com/verilog/verilog-display-tasks)
