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

# References