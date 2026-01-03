set dir_name "work"

if {[file isdirectory $dir_name]} {
    puts "Directory $dir_name found. Deleting..."
    vdel -all $dir_name
} else {
    puts "Directory $dir_name does not exist."
}

vlib work

vcom -2008 -work work ../src/top_pkg.vhd
vcom -2008 -work work ../src/day_1_solution_pkg.vhd
vcom -2008 -work work ../src/day_1_solution_modulo_input.vhd
vcom -2008 -work work ../src/day_1_solution.vhd
vcom -2008 -work work tb_top_modulo.vhd
