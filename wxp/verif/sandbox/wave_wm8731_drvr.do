radix -hex
onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Literal /syn_acortex_tb_top/lb_intf/DATA_W
add wave -noupdate -format Literal /syn_acortex_tb_top/lb_intf/ADDR_W
add wave -noupdate -format Logic /syn_acortex_tb_top/lb_intf/clk_ir
add wave -noupdate -format Logic /syn_acortex_tb_top/lb_intf/rst_il
add wave -noupdate -format Logic /syn_acortex_tb_top/lb_intf/rd_en
add wave -noupdate -format Logic /syn_acortex_tb_top/lb_intf/wr_en
add wave -noupdate -format Literal /syn_acortex_tb_top/lb_intf/addr
add wave -noupdate -format Logic /syn_acortex_tb_top/lb_intf/wr_valid
add wave -noupdate -format Literal /syn_acortex_tb_top/lb_intf/wr_data
add wave -noupdate -format Logic /syn_acortex_tb_top/lb_intf/rd_valid
add wave -noupdate -format Literal /syn_acortex_tb_top/lb_intf/rd_data
add wave -noupdate -format Logic /syn_acortex_tb_top/wm8731_intf/rst_il
add wave -noupdate -format Logic /syn_acortex_tb_top/wm8731_intf/mclk
add wave -noupdate -format Logic /syn_acortex_tb_top/wm8731_intf/bclk
add wave -noupdate -format Logic /syn_acortex_tb_top/wm8731_intf/adc_dat
add wave -noupdate -format Logic /syn_acortex_tb_top/wm8731_intf/adc_lrc
add wave -noupdate -format Logic /syn_acortex_tb_top/wm8731_intf/dac_dat
add wave -noupdate -format Logic /syn_acortex_tb_top/wm8731_intf/dac_lrc
add wave -noupdate -format Logic /syn_acortex_tb_top/wm8731_intf/scl
add wave -noupdate -format Logic /syn_acortex_tb_top/wm8731_intf/sda
add wave -noupdate -format Logic /syn_acortex_tb_top/wm8731_intf/sda_o
add wave -noupdate -format Logic /syn_acortex_tb_top/wm8731_intf/sda_tb_en
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_wm8731_drvr_inst/adc_en_f
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_wm8731_drvr_inst/dac_en_f
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_wm8731_drvr_inst/fs_div_val_f
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_wm8731_drvr_inst/bps_f
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_wm8731_drvr_inst/bclk_gen_vec_f
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_wm8731_drvr_inst/fs_cntr_f
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_wm8731_drvr_inst/lpcm_shift_reg_f
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_wm8731_drvr_inst/rpcm_shift_reg_f
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_wm8731_drvr_inst/bit_idx_f
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_wm8731_drvr_inst/drvr_fsm_idle_c
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_wm8731_drvr_inst/bclk_half_tck_w
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_wm8731_drvr_inst/bclk_full_tck_w
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_wm8731_drvr_inst/end_of_fs_c
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_wm8731_drvr_inst/last_bit_idx_c
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_wm8731_drvr_inst/end_of_channel_c
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_wm8731_drvr_inst/fsm_pstate
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_wm8731_drvr_inst/next_state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {464 ps} 0}
configure wave -namecolwidth 150
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
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {453737550 ps}
