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
del /f /q *.h
del /f /q *.obj
del /f /q *.dll
del /f /q *.ppm
del /f /q *.raw

mkdir logs

rem set TEST_NAME=syn_vcortex_base_test
rem set TEST_NAME=syn_vcortex_gpu_draw_line_test
rem set TEST_NAME=syn_vcortex_gpu_draw_bezier_test
rem set TEST_NAME=syn_vcortex_gpu_fill_test
rem set TEST_NAME=syn_vcortex_host_acc_test
rem set TEST_NAME=syn_vcortex_vga_test

rem set TEST_NAME=syn_acortex_base_test
rem set TEST_NAME=syn_acortex_i2c_test
rem set TEST_NAME=syn_acortex_pcm_test
set TEST_NAME=syn_acortex_adc_cap_test

rem set TB_TOP=syn_vcortex_tb_top
set TB_TOP=syn_acortex_tb_top

set MSIM_DIR=C:\altera\11.1sp2\modelsim_ase
set MSIM_INC_DIR=%MSIM_DIR%\include
set MSIM_WIN32_DIR=%MSIM_DIR%\win32aloem

echo  MSIM_DIR : %MSIM_DIR%
echo  MSIM_INC_DIR : %MSIM_INC_DIR%
echo  MSIM_WIN32_DIR : %MSIM_WIN32_DIR%

vlib work
vmap work work

rem pause

echo  Compiling Design
vlog -incr -f dgn.list +define+SIMULATION -sv -incr -timescale "1ns / 10ps"  -l  compile.dgn.log
echo  Compiling TB
vlog -f verif.list +define+SIMULATION -sv -incr -timescale "1ns / 10ps"  -l  compile.verif.log

echo  Compiling DPI-C files
gcc -c -g ../tb/dpi/ppm.c -o ppm.obj
gcc -c -g ../tb/dpi/raw.c -o raw.obj
gcc -c -g ../tb/dpi/syn_dpi.c -o syn_dpi.obj -I%MSIM_INC_DIR%

echo  Building DLLs
gcc -shared -g -Bsymbolic -I. -I%MSIM_INC_DIR% -L.  -L../tb/dpi -L%MSIM_WIN32_DIR% -o syn_dpi_lib.dll syn_dpi.obj ppm.obj raw.obj -lmtipli

echo  Running test : %TEST_NAME%
vsim -c -novopt +OVM_TESTNAME=%TEST_NAME% -sv_lib syn_dpi_lib %TB_TOP% +define+SIMULATION -l transcript.txt -permit_unmatched_virtual_intf -do "add wave -r /*;run -all"


pause
