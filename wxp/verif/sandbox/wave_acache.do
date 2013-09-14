radix -hex
onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /syn_acortex_tb_top/cr_intf/clk_ir
add wave -noupdate -format Logic /syn_acortex_tb_top/cr_intf/rst_sync_l
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
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/fgyrus_pcm_data_rdy_oh
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/acache_mode_f
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/start_cap_f
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/cap_done_f
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/ingr_addr_f
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/egr_addr_f
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/cap_lpcm_n_rpcm_f
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/bffr_sel_1_n_2_f
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/ingr_addr_inc_en_f
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/egr_data_rdy_f
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/lpcm_rd_del_f
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/rpcm_rd_del_f
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/host_rst_l_c
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/local_rst_l_c
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/switch_bffrs_c
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_lchnnl_1a_addr_c
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_lchnnl_1a_wdata_c
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_lchnnl_1a_wren_c
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_lchnnl_1a_rdata_w
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_lchnnl_1b_addr_c
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_lchnnl_1b_wdata_c
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_lchnnl_1b_wren_c
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_lchnnl_1b_rdata_w
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_rchnnl_1a_addr_c
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_rchnnl_1a_wdata_c
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_rchnnl_1a_wren_c
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_rchnnl_1a_rdata_w
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_rchnnl_1b_addr_c
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_rchnnl_1b_wdata_c
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_rchnnl_1b_wren_c
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_rchnnl_1b_rdata_w
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_lchnnl_2a_addr_c
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_lchnnl_2a_wdata_c
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_lchnnl_2a_wren_c
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_lchnnl_2a_rdata_w
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_lchnnl_2b_addr_c
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_lchnnl_2b_wdata_c
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_lchnnl_2b_wren_c
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_lchnnl_2b_rdata_w
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_rchnnl_2a_addr_c
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_rchnnl_2a_wdata_c
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_rchnnl_2a_wren_c
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_rchnnl_2a_rdata_w
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_rchnnl_2b_addr_c
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_rchnnl_2b_wdata_c
add wave -noupdate -format Logic /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_rchnnl_2b_wren_c
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/pbffr_rchnnl_2b_rdata_w
add wave -noupdate -format Literal /syn_acortex_tb_top/syn_acortex_inst/syn_acache_inst/cap_rdata_c
add wave -noupdate -format Logic /syn_acortex_tb_top/fgyrus_cr_intf/clk_ir
add wave -noupdate -format Logic /syn_acortex_tb_top/fgyrus_cr_intf/rst_sync_l
add wave -noupdate -format Literal /syn_acortex_tb_top/pcm_mem_tb_intf/DATA_W
add wave -noupdate -format Literal /syn_acortex_tb_top/pcm_mem_tb_intf/ADDR_W
add wave -noupdate -format Logic /syn_acortex_tb_top/pcm_mem_tb_intf/clk_ir
add wave -noupdate -format Logic /syn_acortex_tb_top/pcm_mem_tb_intf/rst_il
add wave -noupdate -format Logic /syn_acortex_tb_top/pcm_mem_tb_intf/pcm_data_rdy
add wave -noupdate -format Literal /syn_acortex_tb_top/pcm_mem_tb_intf/pcm_addr
add wave -noupdate -format Literal /syn_acortex_tb_top/pcm_mem_tb_intf/lpcm_wdata
add wave -noupdate -format Literal /syn_acortex_tb_top/pcm_mem_tb_intf/rpcm_wdata
add wave -noupdate -format Logic /syn_acortex_tb_top/pcm_mem_tb_intf/pcm_wren
add wave -noupdate -format Logic /syn_acortex_tb_top/pcm_mem_tb_intf/pcm_rden
add wave -noupdate -format Literal /syn_acortex_tb_top/pcm_mem_tb_intf/lpcm_rdata
add wave -noupdate -format Literal /syn_acortex_tb_top/pcm_mem_tb_intf/rpcm_rdata
add wave -noupdate -format Logic /syn_acortex_tb_top/pcm_mem_tb_intf/pcm_rd_valid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {518946772 ps} 0}
configure wave -namecolwidth 268
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
WaveRestoreZoom {0 ps} {3073541100 ps}
