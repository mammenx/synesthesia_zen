onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/gpu_job_intf/clk_ir
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/gpu_job_intf/rst_il
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/gpu_job_intf/euclid_job_start
add wave -noupdate -format Literal /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/gpu_job_intf/euclid_job_data
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/gpu_job_intf/euclid_busy
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/gpu_job_intf/euclid_job_done
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/gpu_job_intf/picasso_job_start
add wave -noupdate -format Literal /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/gpu_job_intf/picasso_job_data
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/gpu_job_intf/picasso_busy
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/gpu_job_intf/picasso_job_done
add wave -noupdate -format Literal /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/picasso_pxlgw_intf/WIDTHX
add wave -noupdate -format Literal /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/picasso_pxlgw_intf/WIDTHY
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/picasso_pxlgw_intf/clk_ir
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/picasso_pxlgw_intf/rst_il
add wave -noupdate -format Literal /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/picasso_pxlgw_intf/pxl
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/picasso_pxlgw_intf/pxl_wr_valid
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/picasso_pxlgw_intf/pxl_rd_valid
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/picasso_pxlgw_intf/ready
add wave -noupdate -format Literal /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/picasso_pxlgw_intf/posx
add wave -noupdate -format Literal /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/picasso_pxlgw_intf/posy
add wave -noupdate -format Literal /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/picasso_pxlgw_intf/misc_info_dist
add wave -noupdate -format Literal /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/picasso_pxlgw_intf/misc_info_norm
add wave -noupdate -format Literal /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/picasso_pxlgw_intf/rd_pxl
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/picasso_pxlgw_intf/rd_rdy
add wave -noupdate -format Literal /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/gpu_ff_intf/WIDTHX
add wave -noupdate -format Literal /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/gpu_ff_intf/WIDTHY
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/gpu_ff_intf/clk_ir
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/gpu_ff_intf/rst_il
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/gpu_ff_intf/wr_en
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/gpu_ff_intf/rd_en
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/gpu_ff_intf/empty
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/gpu_ff_intf/full
add wave -noupdate -format Literal /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/gpu_ff_intf/waddr
add wave -noupdate -format Literal /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/gpu_ff_intf/raddr
add wave -noupdate -format Literal /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/syn_gpu_core_picasso_inst/pst_vec_f
add wave -noupdate -format Literal /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/syn_gpu_core_picasso_inst/ptr_tmp_f
add wave -noupdate -format Literal /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/syn_gpu_core_picasso_inst/ptr_rd_cntr_f
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/syn_gpu_core_picasso_inst/gpu_ff_wr_valid_c
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/syn_gpu_core_picasso_inst/gpu_ff_rd_valid_c
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/syn_gpu_core_picasso_inst/border_color_found_c
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/syn_gpu_core_picasso_inst/fill_color_found_c
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/syn_gpu_core_picasso_inst/skip_pxl_c
add wave -noupdate -format Logic /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/syn_gpu_core_picasso_inst/last_loc_read_c
add wave -noupdate -format Literal /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/syn_gpu_core_picasso_inst/fsm_pstate
add wave -noupdate -format Literal /syn_vcortex_tb_top/syn_vcortex_inst/syn_gpu_inst/syn_gpu_core_inst/syn_gpu_core_picasso_inst/next_state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {369901000 ps} 0}
configure wave -namecolwidth 334
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
WaveRestoreZoom {242782618 ps} {497019382 ps}
