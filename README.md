# Symbolics Console to CPU emulator

*Copyright 2022 Douglas P. Fields, Jr. All Rights Reserved.*

# Biphase output

* 75 kHz = 13⅓ µs
  * 666⅔ cycles at 50 MHz - call it 666 cycles
* Mark/1 = long pulse
* Space/0 = two short pulses
  * 333 cycles at 50 MHz
* Idle = marking (1's)
* Encoding = 1 start bit, 8 data bits, 1 stop bit

This encoding is then converted to RS-422 logic levels and sent to the CPU.



# Notes on Test Harness

Ensure Quartus Settings -> Simulation shows `Questa Intel FPGA`

Do not use `$finish;` in your simulation - it will quit Questa
and you will have to do everything below all over again!

* Run Questa: `Tools -> Run Simulation Tool -> RTL Simulation...`
* Compile -> Compile... -> `test_biphase_encoder.sv`, Click `Compile`
  * Then close Compile window by clicking `Done`
* Now it appears in `Library` under `work -> test_biphase_encoder`
* Right click `test_biphase_encoder` and select "Simulate"


* Now you see a window `sim - Default` that replaced the `Library` window
* Highlight the `test_i2c` line in `sim`, and it shows all the `Objects`
  in another window.
* Select all the signals (`Objects`) and right click, `Add Wave`
* Simulate -> Run -> Run 100
  * Or Run -All then it will go until `$stop` (or `$finish` - do not say YES)
* If you edit anything, go back to `Library`, right click `Recompile`
* To restart simulation: `Simulate -> Restart...`
* You can save your waves
* You can load saved waves with File -> Load -> Macro File... and then
  choose `test1-wave.do`

Setting up Quartus to load the Test Harness in Questa
* See [Quick Start](https://www.intel.com/content/www/us/en/docs/programmable/703090/21-1/simulation-quick-start.html)
  documentation section 1.2, figures 3-4
* Quartus: Assignments -> Settings -> EDA Tool Settings -> Simulation
* NativeLink Settings -> Compile test bench
* Click `Test Benches...` then `New`
* Add a name (e.g., `testbench_1`) and specify the `test_i2c` as top-level module
* Add the file `test_i2c.sv` and mark it as SystemVerilog
* NOW, when you run the `RTL Simulation` it will open this by default.
* You will still need to save the waves as you like them and reload them (per above).
* When you change things, you still have to right-click & `Recompile` in the `Library`
  * This is a long command in `VSIM ##>` prompt
* Then you can type at the `VSIM ##>` prompt `restart -f ; run -all`


Misc
* If you accidentally create a Wave Window Pane: `Wave -> Delete Window Pane`
* Questa PDF documentation is in the `Help` menu
* [See here](https://verificationacademy.com/forums/systemverilog/error-suppressible-vlog-7061-alwaysff-modelsim) for some information on the vlog-7061 Questa error

# References