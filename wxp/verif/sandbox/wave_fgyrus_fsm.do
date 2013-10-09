onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Literal /syn_fgyrus_tb_top/lb_intf/DATA_W
add wave -noupdate -format Literal /syn_fgyrus_tb_top/lb_intf/ADDR_W
add wave -noupdate -format Logic /syn_fgyrus_tb_top/lb_intf/clk_ir
add wave -noupdate -format Logic /syn_fgyrus_tb_top/lb_intf/rst_il
add wave -noupdate -format Logic /syn_fgyrus_tb_top/lb_intf/rd_en
add wave -noupdate -format Logic /syn_fgyrus_tb_top/lb_intf/wr_en
add wave -noupdate -format Literal /syn_fgyrus_tb_top/lb_intf/addr
add wave -noupdate -format Logic /syn_fgyrus_tb_top/lb_intf/wr_valid
add wave -noupdate -format Literal /syn_fgyrus_tb_top/lb_intf/wr_data
add wave -noupdate -format Logic /syn_fgyrus_tb_top/lb_intf/rd_valid
add wave -noupdate -format Literal /syn_fgyrus_tb_top/lb_intf/rd_data
add wave -noupdate -format Literal /syn_fgyrus_tb_top/pcm_mem_tb_intf/DATA_W
add wave -noupdate -format Literal /syn_fgyrus_tb_top/pcm_mem_tb_intf/ADDR_W
add wave -noupdate -format Literal /syn_fgyrus_tb_top/pcm_mem_tb_intf/RD_DELAY
add wave -noupdate -format Logic /syn_fgyrus_tb_top/pcm_mem_tb_intf/clk_ir
add wave -noupdate -format Logic /syn_fgyrus_tb_top/pcm_mem_tb_intf/rst_il
add wave -noupdate -format Logic /syn_fgyrus_tb_top/pcm_mem_tb_intf/pcm_data_rdy
add wave -noupdate -format Literal /syn_fgyrus_tb_top/pcm_mem_tb_intf/pcm_addr
add wave -noupdate -format Literal /syn_fgyrus_tb_top/pcm_mem_tb_intf/lpcm_wdata
add wave -noupdate -format Literal /syn_fgyrus_tb_top/pcm_mem_tb_intf/rpcm_wdata
add wave -noupdate -format Logic /syn_fgyrus_tb_top/pcm_mem_tb_intf/pcm_wren
add wave -noupdate -format Logic /syn_fgyrus_tb_top/pcm_mem_tb_intf/pcm_rden
add wave -noupdate -format Literal /syn_fgyrus_tb_top/pcm_mem_tb_intf/lpcm_rdata
add wave -noupdate -format Literal /syn_fgyrus_tb_top/pcm_mem_tb_intf/rpcm_rdata
add wave -noupdate -format Logic /syn_fgyrus_tb_top/pcm_mem_tb_intf/pcm_rd_valid
add wave -noupdate -format Literal /syn_fgyrus_tb_top/pcm_mem_tb_intf/pcm_raddr
add wave -noupdate -format Literal /syn_fgyrus_tb_top/pcm_mem_tb_intf/pcm_raddr_del
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/win_ram_intf/RAM_DATA_W
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/win_ram_intf/RAM_ADDR_W
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/win_ram_intf/clk_ir
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/win_ram_intf/rst_il
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/win_ram_intf/addr
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/win_ram_intf/wdata
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/win_ram_intf/wren
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/win_ram_intf/rden
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/win_ram_intf/rdata
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/win_ram_intf/rd_valid
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/fft_cache_intf/DATA_W
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/fft_cache_intf/ADDR_W
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/fft_cache_intf/clk_ir
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/fft_cache_intf/rst_il
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/fft_cache_intf/wr_sample
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/fft_cache_intf/wr_en
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/fft_cache_intf/waddr
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/fft_cache_intf/raddr
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/fft_cache_intf/raddr_norm
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/fft_cache_intf/rd_sample
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/fft_cache_intf/rd_en
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/fft_cache_intf/rd_valid
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/fft_cache_intf/fft_done
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/fft_cache_intf/hst_wr_data
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/fft_cache_intf/hst_wr_en
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/fft_cache_intf/hst_addr
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/fft_cache_intf/hst_rd_en
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/fft_cache_intf/hst_rd_data
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/fft_cache_intf/hst_rd_valid
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/twdl_ram_intf/RAM_DATA_W
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/twdl_ram_intf/RAM_ADDR_W
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/twdl_ram_intf/clk_ir
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/twdl_ram_intf/rst_il
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/twdl_ram_intf/addr
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/twdl_ram_intf/wdata
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/twdl_ram_intf/wren
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/twdl_ram_intf/rden
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/twdl_ram_intf/rdata
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/twdl_ram_intf/rd_valid
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/but_intf/clk_ir
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/but_intf/rst_il
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/but_intf/sample_a
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/but_intf/sample_b
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/but_intf/twdl
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/but_intf/sample_rdy
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/but_intf/res
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/but_intf/res_rdy
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/pcm_rdy_ih
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/fgyrus_en_f
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/fgyrus_mode_f
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/fgyrus_post_norm_f
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/fgyrus_config_addr_f
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/fgyrus_cache_addr_f
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/rchnnl_n_lchnnl_f
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/pst_vec_f
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/wait_for_end_f
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/sample_rcntr_f
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/sample_wcntr_f
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/fft_stage_rd_f
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/fft_stage_rd_bound_f
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/fft_stage_wr_f
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/fft_stage_wr_bound_f
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/fgyrus_busy_c
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/sample_rcntr_rev_w
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/decimate_ovr_c
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/wrap_inc_fft_rcntr_c
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/fft_stage_rd_ovr_c
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/fft_rd_ovr_c
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/wrap_inc_fft_wcntr_c
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/fft_stage_wr_ovr_c
add wave -noupdate -format Logic /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/fft_wr_ovr_c
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/fsm_pstate
add wave -noupdate -format Literal /syn_fgyrus_tb_top/syn_fgyrus_inst/syn_fgyrus_fsm_inst/next_state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2163202 ps} 0}
configure wave -namecolwidth 264
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
WaveRestoreZoom {0 ps} {11257050 ps}
radix -hex
