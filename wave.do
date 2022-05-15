onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /test_biphase_encoder/clock
add wave -noupdate /test_biphase_encoder/reset
add wave -noupdate -divider Output
add wave -noupdate /test_biphase_encoder/dut/first_half_begun
add wave -noupdate /test_biphase_encoder/dut/second_half_begun
add wave -noupdate /test_biphase_encoder/dut/next_bit_index
add wave -noupdate /test_biphase_encoder/dbg_current_bit
add wave -noupdate /test_biphase_encoder/dbg_first_half
add wave -noupdate -divider {Biphase Encoder}
add wave -noupdate /test_biphase_encoder/busy_out
add wave -noupdate /test_biphase_encoder/biphase_out
add wave -noupdate -divider {Test Driver}
add wave -noupdate /test_biphase_encoder/data_ready
add wave -noupdate /test_biphase_encoder/round_num
add wave -noupdate /test_biphase_encoder/start_delay
add wave -noupdate -divider {Biphase Decoder}
add wave -noupdate /test_biphase_encoder/biphase_to_nrz/biphase_in
add wave -noupdate /test_biphase_encoder/biphase_to_nrz/nrz_out
add wave -noupdate /test_biphase_encoder/biphase_to_nrz/clock_out
add wave -noupdate /test_biphase_encoder/biphase_to_nrz/data_received
add wave -noupdate /test_biphase_encoder/biphase_to_nrz/framing_error
add wave -noupdate /test_biphase_encoder/biphase_to_nrz/glitch_ignored
add wave -noupdate /test_biphase_encoder/biphase_to_nrz/counter_overflow
add wave -noupdate /test_biphase_encoder/biphase_to_nrz/counter
add wave -noupdate -divider {UART Decoder}
add wave -noupdate -color {Dark Orchid} /test_biphase_encoder/dbg_current_bit
add wave -noupdate /test_biphase_encoder/uart_rx/r_Rx_Data
add wave -noupdate /test_biphase_encoder/uart_rx/r_Clock_Count
add wave -noupdate /test_biphase_encoder/uart_rx/r_Bit_Index
add wave -noupdate -radix binary /test_biphase_encoder/uart_rx/state
add wave -noupdate /test_biphase_encoder/uart_rx/data_valid
add wave -noupdate -color White -radix binary -radixshowbase 1 /test_biphase_encoder/uart_rx/data_byte
add wave -noupdate -color Gray60 -radix binary /test_biphase_encoder/data_in
add wave -noupdate -radix binary /test_biphase_encoder/next_to_send
add wave -noupdate -divider {All Together}
add wave -noupdate /test_biphase_encoder/last_sent_to_encoder
add wave -noupdate /test_biphase_encoder/biphase_out_delayed
add wave -noupdate /test_biphase_encoder/nrz_out
add wave -noupdate -color {Dark Orchid} /test_biphase_encoder/dbg_current_bit_delayed
add wave -noupdate /test_biphase_encoder/uart_data_byte
add wave -noupdate /test_biphase_encoder/uart_data_valid
add wave -noupdate /test_biphase_encoder/data_ready
add wave -noupdate /test_biphase_encoder/busy_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {35950000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 271
configure wave -valuecolwidth 70
configure wave -justifyvalue left
configure wave -signalnamewidth 2
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {32089577 ps} {37966783 ps}
