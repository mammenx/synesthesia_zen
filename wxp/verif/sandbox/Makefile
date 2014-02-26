#TEST_NAME=syn_vcortex_base_test
#TEST_NAME=syn_vcortex_gpu_draw_line_test
#TEST_NAME=syn_vcortex_gpu_draw_bezier_test
#TEST_NAME=syn_vcortex_gpu_fill_test
#TEST_NAME=syn_vcortex_host_acc_test
#TEST_NAME=syn_vcortex_vga_test

#TEST_NAME=syn_acortex_base_test
#TEST_NAME=syn_acortex_i2c_test
TEST_NAME=syn_acortex_pcm_test
#TEST_NAME=syn_acortex_adc_cap_test

#TEST_NAME=syn_fgyrus_base_test
#TEST_NAME=syn_fgyrus_data_paths_test
#TEST_NAME=syn_fgyrus_mem_acc_test

#TEST_NAME=syn_sram_acc_base_test
#TEST_NAME=syn_sram_acc_test

#TB_TOP=syn_vcortex_tb_top
TB_TOP=syn_acortex_tb_top
#TB_TOP=syn_fgyrus_tb_top
#TB_TOP=syn_sram_acc_tb_top

MSIM_DIR=/altera/modelsim_ase
MSIM_INC_DIR=$(MSIM_DIR)/include
MSIM_WIN32_DIR=$(MSIM_DIR)/linuxaloem

OVL_DEFINES=+define+OVL_ASSERT_ON +define+OVL_INIT_MSG +define+OVL_VERILOG

PPM_FILES=$(shell find ./snaps/ -name "*.ppm")

all: clean show_dir dgn tb dpi dll sim

clean:
	rm -rf work
	rm -rf logs
	rm -rf snaps
	rm -f *.ini transcript* *.wlf *.obj *.log *.h *.dll *.so *.ppm *.raw *.gif
	mkdir logs
	mkdir snaps
	vlib work
	vmap work work

git:
	rm -rf work
	rm -rf logs
	rm -rf snaps
	rm -f *.ini transcript* *.wlf *.obj *.log *.h *.dll *.so *.ppm *.raw

show_dir:
	echo  MSIM_DIR : $(MSIM_DIR)
	echo  MSIM_INC_DIR : $(MSIM_INC_DIR)
	echo  MSIM_WIN32_DIR : $(MSIM_WIN32_DIR)

dgn:
	echo Compiling Design
	vlog -incr -f dgn.list  +define+SIMULATION +define+USE_GPU_LF_CNTRLR $(OVL_DEFINES) -sv -timescale "1ns / 10ps"  -l  compile.dgn.log

tb:
	echo  Compiling TB
	vlog -f verif.list +define+SIMULATION +define+USE_GPU_LF_CNTRLR $(OVL_DEFINES) -sv -incr -timescale "1ns / 10ps"  -l  compile.verif.log

dpi:
	echo  Compiling DPI-C files
	gcc -m32 -c -g -fPIC ../tb/dpi/ppm.c -o ppm.obj
	gcc -m32 -c -g -fPIC ../tb/dpi/raw.c -o raw.obj
	gcc -m32 -c -g -fPIC ../tb/dpi/fft.c -o fft.obj
	gcc -m32 -c -g -fPIC ../tb/dpi/syn_dpi.c -o syn_dpi.obj -I$(MSIM_INC_DIR)

dll:
	echo  Building DLLs
	gcc -m32 -shared -g -Bsymbolic -I. -I$(MSIM_INC_DIR) -L.  -L../tb/dpi -L$(MSIM_WIN32_DIR) -o syn_dpi_lib.so syn_dpi.obj ppm.obj raw.obj fft.obj

sim:
	echo  Running test : $(TEST_NAME)
	vsim -c -novopt +OVM_TESTNAME=$(TEST_NAME) -sv_lib syn_dpi_lib $(TB_TOP) +define+SIMULATION +define+USE_GPU_LF_CNTRLR $(OVL_DEFINES) -l transcript.txt -permit_unmatched_virtual_intf -do "add wave -r /*;run -all"
	cat transcript.txt | grep "OVL.*assert" > assert.log
	echo	"*************** Assertion Log - assert.log  **************"
	cat assert.log

gif:
	echo Generating gif animation
	convert -delay 100 -size 640x480 $(PPM_FILES) -loop 0 frm_bffr.gif

gui:
	vsim vsim.wlf
