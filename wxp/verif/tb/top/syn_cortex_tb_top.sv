/*
 --------------------------------------------------------------------------
   Synesthesia - Copyright (C) 2012 Gregory Matthew James.

   This file is part of Synesthesia.

   Synesthesia is free; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   Synesthesia is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program. If not, see <http://www.gnu.org/licenses/>.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------
 -- Project Code      : synesthesia
 -- Component Name    : syn_cortex_tb_top
 -- Author            : mammenx
 -- Function          : TB top module which instantiates cortex DUT.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/


`ifndef __SYN_CORTEX_TB_TOP
`define __SYN_CORTEX_TB_TOP

  /////////////////////////////////////////////////////
  // Importing OVM Packages                          //
  /////////////////////////////////////////////////////

  `include "ovm.svh"
  import ovm_pkg::*;

  `timescale  1ns/100ps

  `include  "assert_change.vlib"

  module syn_cortex_tb_top();

    parameter LB_DATA_W = 32;
    parameter CORTEX_LB_ADDR_W = 16;
    parameter FGYRUS_LB_ADDR_W = 12;
    parameter PCM_MEM_DATA_W  = 32;
    parameter PCM_MEM_ADDR_W  = 7;
    parameter P_VGA_HVALID_W        = 640;
    parameter P_VGA_HFP_W           = 16;
    parameter P_VGA_HSYNC_W         = 96;
    parameter P_VGA_HBP_W           = 48;
    localparam  P_VGA_HTOTAL_W      = P_VGA_HVALID_W  + P_VGA_HFP_W + P_VGA_HSYNC_W + P_VGA_HBP_W;
    parameter P_VGA_VVALID_W        = 480;
    parameter P_VGA_VFP_W           = 10;
    parameter P_VGA_VSYNC_W         = 2;
    parameter P_VGA_VBP_W           = 33;
    localparam  P_VGA_VTOTAL_W      = P_VGA_VVALID_W  + P_VGA_VFP_W + P_VGA_VSYNC_W + P_VGA_VBP_W;
    parameter VGA_RES_W             = 4;
 

    `include  "cortex_tb.list"
    `include  "syn_cortex_reg_map.sv"


    //Clock Reset signals
    logic   sys_clk_50;
    logic   sys_clk_100;
    logic   vga_pxl_clk;
    logic   sys_rst;



    //Interfaces
    syn_clk_rst_sync_intf             cr_50MHz_intf(sys_clk_50,sys_rst);
    syn_clk_rst_sync_intf             cr_100MHz_intf(sys_clk_100,sys_rst);

    syn_lb_intf#(LB_DATA_W,CORTEX_LB_ADDR_W) cortex_lb_intf(sys_clk_50,sys_rst);
    syn_lb_tb_intf#(LB_DATA_W,CORTEX_LB_ADDR_W) cortex_lb_tb_intf(sys_clk_50,sys_rst, cortex_lb_intf.wr_valid, cortex_lb_intf.rd_valid, cortex_lb_intf.rd_data);

    syn_lb_intf#(LB_DATA_W,FGYRUS_LB_ADDR_W) fgyrus_lb_intf(sys_clk_100,sys_rst);
    syn_lb_tb_intf#(LB_DATA_W,FGYRUS_LB_ADDR_W) fgyrus_lb_tb_intf(sys_clk_50,sys_rst, fgyrus_lb_intf.wr_valid, fgyrus_lb_intf.rd_valid, fgyrus_lb_intf.rd_data);

    syn_wm8731_intf                   wm8731_intf(sys_rst);

    syn_clk_vec_intf#(4)    clk_vec_intf(4'd0);

    syn_pcm_mem_intf#(PCM_MEM_DATA_W,PCM_MEM_ADDR_W,2)  pcm_mem_tb_intf(sys_clk_100,sys_rst);

    syn_sram_mem_intf                 sram_mem_intf(sys_clk_50,sys_rst);

    syn_vga_intf#(VGA_RES_W)          vga_intf(vga_pxl_clk,sys_rst);

    //Assigning LB signals from TB to DUT
    assign  cortex_lb_intf.rd_en     = cortex_lb_tb_intf.rd_en;
    assign  cortex_lb_intf.wr_en     = cortex_lb_tb_intf.wr_en;
    assign  cortex_lb_intf.wr_data   = cortex_lb_tb_intf.wr_data;
    assign  cortex_lb_intf.addr      = cortex_lb_tb_intf.addr;

    assign  fgyrus_lb_intf.rd_en     = fgyrus_lb_tb_intf.rd_en;
    assign  fgyrus_lb_intf.wr_en     = fgyrus_lb_tb_intf.wr_en;
    assign  fgyrus_lb_intf.wr_data   = fgyrus_lb_tb_intf.wr_data;
    assign  fgyrus_lb_intf.addr      = fgyrus_lb_tb_intf.addr;

    //Assigning internal Acortex PCM memory signals to tb intf
    assign  pcm_mem_tb_intf.pcm_addr      = syn_cortex_inst.acache_lchnnl_intf.addr;
    assign  pcm_mem_tb_intf.pcm_wren      = syn_cortex_inst.acache_lchnnl_intf.wren | syn_cortex_inst.acache_rchnnl_intf.wren;
    assign  pcm_mem_tb_intf.pcm_rden      = syn_cortex_inst.acache_lchnnl_intf.rden | syn_cortex_inst.acache_rchnnl_intf.rden;
    assign  pcm_mem_tb_intf.lpcm_wdata    = syn_cortex_inst.acache_lchnnl_intf.wdata;
    assign  pcm_mem_tb_intf.rpcm_wdata    = syn_cortex_inst.acache_rchnnl_intf.wdata;
    assign  pcm_mem_tb_intf.lpcm_rdata    = syn_cortex_inst.acache_lchnnl_intf.rdata;
    assign  pcm_mem_tb_intf.rpcm_rdata    = syn_cortex_inst.acache_rchnnl_intf.rdata;
    assign  pcm_mem_tb_intf.pcm_rd_valid  = syn_cortex_inst.acache_lchnnl_intf.rd_valid | syn_cortex_inst.acache_rchnnl_intf.rd_valid;


    /////////////////////////////////////////////////////
    // Clock, Reset Generation                         //
    /////////////////////////////////////////////////////
    initial
    begin
      sys_clk_50    = 1;

      #111;

      forever #10ns sys_clk_50  = ~sys_clk_50;
    end

    initial
    begin
      sys_clk_100   = 1;

      #100;

      forever #5ns sys_clk_100  = ~sys_clk_100;
    end

    initial
    begin
      vga_pxl_clk = 1;

      @(posedge sys_rst);

      forever
      begin
        @(posedge sys_clk_50);
        vga_pxl_clk = ~vga_pxl_clk;
      end
    end

    initial
    begin
      sys_rst   = 1;

      #123;

      sys_rst   = 0;

      #321;

      sys_rst   = 1;

    end



    /*  DUT */
  syn_cortex            syn_cortex_inst
  (

    .cortex_cr_intf     (cr_50MHz_intf.sync),

    .fft_cache_cr_intf  (cr_100MHz_intf.sync),

    .cortex_lb_intf     (cortex_lb_intf.slave),

    .fft_cache_lb_intf  (fgyrus_lb_intf.slave),

    .wm8731_intf        (wm8731_intf),

    .clk_vec_intf       (clk_vec_intf.dut),

    .sram_mem_intf      (sram_mem_intf.mp),

    .vga_intf           (vga_intf.mp)

  );

    bit hsync_n_1d,vsync_n_1d;

    always@(posedge vga_intf.clk_ir,negedge vga_intf.rst_il)
    begin
      if(~vga_intf.rst_il)
      begin
        hsync_n_1d  <=  1;
        vsync_n_1d  <=  1;
      end
      else
      begin
        hsync_n_1d  <=  vga_intf.hsync_n;
        vsync_n_1d  <=  (~vga_intf.hsync_n  & hsync_n_1d) ? vga_intf.vsync_n  : vsync_n_1d;
      end
    end

    /*  HSYNC Assertions  */
    assert_change
      #(  `OVL_ERROR,           //severity_level
          1,                    //width
          P_VGA_HVALID_W,       //num_cks
          `OVL_ERROR_ON_NEW_START,  //action_on_new_start
          `OVL_ASSERT,          //property_type
          "assert_hsync_low_err", //msg
          `OVL_COVER_NONE       //coverage_level
      )
    assert_hsync_low
      (   vga_intf.clk_ir,  //clk
          vga_intf.rst_il,  //reset_n
          (~vga_intf.hsync_n & hsync_n_1d),  //start_event: negedge of hsync_n
          vga_intf.hsync_n   //test_expr:  monitor hsync_n
      );

    assert_change
      #(  `OVL_ERROR,           //severity_level
          1,                    //width
          (P_VGA_HBP_W+P_VGA_HVALID_W+P_VGA_HFP_W),       //num_cks
          `OVL_ERROR_ON_NEW_START,  //action_on_new_start
          `OVL_ASSERT,          //property_type
          "assert_hsync_high_err", //msg
          `OVL_COVER_NONE       //coverage_level
      )
    assert_hsync_high
      (   vga_intf.clk_ir,  //clk
          vga_intf.rst_il,  //reset_n
          (vga_intf.hsync_n & ~hsync_n_1d),  //start_event: posedge of hsync_n
          vga_intf.hsync_n   //test_expr:  monitor hsync_n
      );

    /*  VSYNC Assertions  */
    assert_change
      #(  `OVL_ERROR,           //severity_level
          1,                    //width
          P_VGA_VSYNC_W,       //num_cks
          `OVL_ERROR_ON_NEW_START,  //action_on_new_start
          `OVL_ASSERT,          //property_type
          "assert_vsync_low_err", //msg
          `OVL_COVER_NONE       //coverage_level
      )
    assert_vsync_low
      (   (~vga_intf.hsync_n & hsync_n_1d),  //clk
          vga_intf.rst_il,  //reset_n
          (~vga_intf.vsync_n & vsync_n_1d),  //start_event: negedge of vsync_n
          vga_intf.vsync_n   //test_expr:  monitor vsync_n
      );

    assert_change
      #(  `OVL_ERROR,           //severity_level
          1,                    //width
          (P_VGA_VBP_W+P_VGA_VVALID_W+P_VGA_VFP_W),       //num_cks
          `OVL_ERROR_ON_NEW_START,  //action_on_new_start
          `OVL_ASSERT,          //property_type
          "assert_vsync_high_err", //msg
          `OVL_COVER_NONE       //coverage_level
      )
    assert_vsync_high
      (   (~vga_intf.hsync_n & hsync_n_1d),  //clk
          vga_intf.rst_il,  //reset_n
          (vga_intf.vsync_n & ~vsync_n_1d),  //start_event: posedge of vsync_n
          vga_intf.vsync_n   //test_expr:  monitor vsync_n
      );



    initial
    begin
      #1;
      run_test();
    end

  endmodule

`endif
