onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /test_faux_mouse_to_symbolics/clock
add wave -noupdate /test_faux_mouse_to_symbolics/reset
add wave -noupdate -divider {Mouse Inputs}
add wave -noupdate /test_faux_mouse_to_symbolics/mouse_up
add wave -noupdate /test_faux_mouse_to_symbolics/mouse_down
add wave -noupdate /test_faux_mouse_to_symbolics/mouse_left
add wave -noupdate /test_faux_mouse_to_symbolics/mouse_right
add wave -noupdate /test_faux_mouse_to_symbolics/button_left
add wave -noupdate /test_faux_mouse_to_symbolics/button_middle
add wave -noupdate /test_faux_mouse_to_symbolics/button_right
add wave -noupdate /test_faux_mouse_to_symbolics/mouse_speed
add wave -noupdate -divider {Mouse Outputs}
add wave -noupdate /test_faux_mouse_to_symbolics/mouse_data_ready
add wave -noupdate /test_faux_mouse_to_symbolics/mouse_data
add wave -noupdate -divider {Biphase Encoder}
add wave -noupdate /test_faux_mouse_to_symbolics/biphase_encoder_busy
add wave -noupdate /test_faux_mouse_to_symbolics/fake_biphase_encoder/data_ready
add wave -noupdate /test_faux_mouse_to_symbolics/fake_biphase_encoder/data_in
add wave -noupdate /test_faux_mouse_to_symbolics/fake_biphase_encoder/dbg_start_bit
add wave -noupdate /test_faux_mouse_to_symbolics/fake_biphase_encoder/dbg_stop_bit
add wave -noupdate /test_faux_mouse_to_symbolics/fake_biphase_encoder/dbg_data_bits
add wave -noupdate /test_faux_mouse_to_symbolics/fake_biphase_encoder/counter
add wave -noupdate /test_faux_mouse_to_symbolics/fake_biphase_encoder/bit_counter
add wave -noupdate /test_faux_mouse_to_symbolics/fake_biphase_encoder/data_to_send
add wave -noupdate -divider {Faux Mouse Internals}
add wave -noupdate /test_faux_mouse_to_symbolics/SHORT_PULSE
add wave -noupdate /test_faux_mouse_to_symbolics/dut/SHORT_PULSE
add wave -noupdate /test_faux_mouse_to_symbolics/dut/delay_by_speed/SHORT_PULSE
add wave -noupdate /test_faux_mouse_to_symbolics/dut/current_buttons
add wave -noupdate /test_faux_mouse_to_symbolics/dut/current_direction
add wave -noupdate /test_faux_mouse_to_symbolics/dut/current_delay
add wave -noupdate /test_faux_mouse_to_symbolics/dut/last_sent_buttons
add wave -noupdate /test_faux_mouse_to_symbolics/dut/min_delay_counter
add wave -noupdate /test_faux_mouse_to_symbolics/dut/move_delay_counter
add wave -noupdate /test_faux_mouse_to_symbolics/dut/next_min_delay_counter
add wave -noupdate /test_faux_mouse_to_symbolics/dut/next_move_delay_counter
add wave -noupdate /test_faux_mouse_to_symbolics/dut/cannot_move
add wave -noupdate /test_faux_mouse_to_symbolics/dut/cannot_send
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {7430000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 317
configure wave -valuecolwidth 100
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
WaveRestoreZoom {0 ps} {48920771 ps}
