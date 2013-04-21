@echo off


SETLOCAL

echo Cleaning Up Workspace
if exist work (
    rmdir /S /Q work 2> nul
)

if exist logs (
    rmdir /S /Q logs 2> nul
)

del /f /q *.ini
del /f /q transcript*
del /f /q *.wlf
del /f /q *.obj
del /f /q *.log

mkdir logs

rem set TEST_NAME=syn_vcortex_base_test
set TEST_NAME=syn_vcortex_gpu_draw_line_test


vlib work
vmap work work

echo  Compiling Design
vlog -incr -f dgn.list +define+SIMULATION -sv -incr -timescale "1ns / 10ps"  -l  compile.dgn.log
echo  Compiling TB
vlog -f verif.list +define+SIMULATION -sv -incr -timescale "1ns / 10ps"  -l  compile.verif.log
echo  Running test : %TEST_NAME%
vsim -c -novopt +OVM_TESTNAME=%TEST_NAME%  syn_vcortex_tb_top +define+SIMULATION -l transcript.txt -permit_unmatched_virtual_intf -do "add wave -r /*;run -all"


pause
