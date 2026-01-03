onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top_modulo/clk
add wave -noupdate /tb_top_modulo/rst
add wave -noupdate /tb_top_modulo/valid_i
add wave -noupdate /tb_top_modulo/last_i
add wave -noupdate /tb_top_modulo/keep_i
add wave -noupdate -expand /tb_top_modulo/rotate_i
add wave -noupdate /tb_top_modulo/moduloed_input_array_r
add wave -noupdate -radix unsigned /tb_top_modulo/moduloed_input_array_head_r
add wave -noupdate /tb_top_modulo/moduloed_input_array_tail_r
add wave -noupdate -expand /tb_top_modulo/day_1_solution_modulo_input_inst/rotate_moduloed_o
add wave -noupdate /tb_top_modulo/day_1_solution_modulo_input_inst/input_record_array_r(0)
add wave -noupdate /tb_top_modulo/day_1_solution_modulo_input_inst/input_record_array_r(1)
add wave -noupdate /tb_top_modulo/day_1_solution_modulo_input_inst/input_record_array_r(2)
add wave -noupdate /tb_top_modulo/day_1_solution_modulo_input_inst/input_record_array_r(3)
add wave -noupdate /tb_top_modulo/day_1_solution_modulo_input_inst/input_record_array_x(0)
add wave -noupdate /tb_top_modulo/day_1_solution_modulo_input_inst/input_record_array_x(1)
add wave -noupdate /tb_top_modulo/day_1_solution_modulo_input_inst/input_record_array_x(2)
add wave -noupdate /tb_top_modulo/day_1_solution_modulo_input_inst/input_record_array_x(3)
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {179594 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 205
configure wave -valuecolwidth 473
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {93409 ps}
