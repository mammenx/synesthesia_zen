#vdel -all -lib work
#vlib work
#vmap work work

vlog -incr -f dgn.list +define+SIMULATION -sv -incr -timescale "1ns / 10ps"  -l  compile.dgn.log
vlog -f verif.list +define+SIMULATION -sv -incr -timescale "1ns / 10ps"  -l  compile.verif.log
