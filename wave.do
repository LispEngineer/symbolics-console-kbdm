onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /test_biphase_encoder/clock
add wave -noupdate /test_biphase_encoder/reset
add wave -noupdate /test_biphase_encoder/dbg_first_half
add wave -noupdate /test_biphase_encoder/busy_out
add wave -noupdate -divider Output
add wave -noupdate /test_biphase_encoder/dut/first_half_begun
add wave -noupdate /test_biphase_encoder/dut/second_half_begun
add wave -noupdate /test_biphase_encoder/dut/next_bit_index
add wave -noupdate /test_biphase_encoder/dbg_current_bit
add wave -noupdate -divider Biphase
add wave -noupdate /test_biphase_encoder/biphase_out
add wave -noupdate -divider Driver
add wave -noupdate /test_biphase_encoder/data_ready
add wave -noupdate /test_biphase_encoder/round_num
add wave -noupdate /test_biphase_encoder/start_delay
add wave -noupdate /test_biphase_encoder/data_in
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {687417 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 258
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
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
WaveRestoreZoom {0 ps} {262072843 ps}
