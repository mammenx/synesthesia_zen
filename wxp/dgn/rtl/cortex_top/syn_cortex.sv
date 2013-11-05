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
 -- Module Name       : syn_cortex
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This is the Cortex Acceleration Engine top module.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_cortex (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf           cortex_cr_intf,      //Clock Reset Interface

  syn_clk_rst_sync_intf           fft_cache_cr_intf,   //Clock Reset Interface

  syn_lb_intf                     cortex_lb_intf,      //data=32, addr=16

  syn_lb_intf                     fft_cache_lb_intf,   //data=32, addr=12

  syn_wm8731_intf                 wm8731_intf,

  syn_clk_vec_intf                clk_vec_intf,

  syn_sram_mem_intf               sram_mem_intf,

  syn_vga_intf                    vga_intf

                );

//----------------------- Global parameters Declarations ------------------

  parameter   P_NUM_CLOCKS          = 4;
  parameter   P_ACACHE_DWIDTH       = 32;
  parameter   P_ACACHE_AWIDTH       = 7;

  `include  "syn_cortex_reg_map.sv"

//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------


//----------------------- Internal Wire Declarations ----------------------
  logic                       pcm_data_rdy_w;

  logic                       acortex_addr_dec_c;
  logic                       vcortex_addr_dec_c;

//----------------------- Internal Interface Declarations -----------------
  mem_intf#(P_ACACHE_DWIDTH,P_ACACHE_AWIDTH)  acache_lchnnl_intf(cortex_cr_intf.clk_ir,cortex_cr_intf.rst_sync_l);
  mem_intf#(P_ACACHE_DWIDTH,P_ACACHE_AWIDTH)  acache_rchnnl_intf(cortex_cr_intf.clk_ir,cortex_cr_intf.rst_sync_l);

  syn_lb_intf#(32,12)         acortex_lb_intf(cortex_cr_intf.clk_ir,cortex_cr_intf.rst_sync_l);
  syn_lb_intf#(32,12)         vcortex_lb_intf(cortex_cr_intf.clk_ir,cortex_cr_intf.rst_sync_l);

//----------------------- FSM Declarations --------------------------------



//----------------------- Start of Code -----------------------------------

  /*  Mux Acortex LB xtns */
  assign  acortex_addr_dec_c  = (cortex_lb_intf.addr[15:12] ==  ACORTEX_BLK)  ? 1'b1  : 1'b0;
  assign  vcortex_addr_dec_c  = (cortex_lb_intf.addr[15:12] ==  VCORTEX_BLK)  ? 1'b1  : 1'b0;

  assign  acortex_lb_intf.rd_en   = cortex_lb_intf.rd_en  & acortex_addr_dec_c;
  assign  acortex_lb_intf.wr_en   = cortex_lb_intf.wr_en  & acortex_addr_dec_c;
  assign  acortex_lb_intf.addr    = cortex_lb_intf.addr[12:0];
  assign  acortex_lb_intf.wr_data = cortex_lb_intf.wr_data;

  assign  vcortex_lb_intf.rd_en   = cortex_lb_intf.rd_en  & vcortex_addr_dec_c;
  assign  vcortex_lb_intf.wr_en   = cortex_lb_intf.wr_en  & vcortex_addr_dec_c;
  assign  vcortex_lb_intf.addr    = cortex_lb_intf.addr[12:0];
  assign  vcortex_lb_intf.wr_data = cortex_lb_intf.wr_data;

  assign  cortex_lb_intf.wr_valid = acortex_lb_intf.wr_valid  | vcortex_lb_intf.wr_valid;
  assign  cortex_lb_intf.rd_valid = acortex_lb_intf.rd_valid  | vcortex_lb_intf.rd_valid;
  assign  cortex_lb_intf.rd_data  = acortex_lb_intf.rd_valid  ? acortex_lb_intf.rd_data : vcortex_lb_intf.rd_data;


  /*  Audio Cortex Instantiation  */
  syn_acortex               acortex_inst
  (

    .cr_intf                (cortex_cr_intf),

    .lb_intf                (acortex_lb_intf),

    .wm8731_intf            (wm8731_intf),

    .clk_vec_intf           (clk_vec_intf),

    .fgyrus_cr_intf         (fft_cache_cr_intf),

    .fgyrus_lchnnl_mem_intf (acache_lchnnl_intf.slave),

    .fgyrus_rchnnl_mem_intf (acache_rchnnl_intf.slave),

    .fgyrus_pcm_data_rdy_oh (pcm_data_rdy_w)

  );
  defparam  acortex_inst.P_NUM_CLOCKS = P_NUM_CLOCKS;


  /*  Fusiform Gyrus Instantiation  */
  syn_fgyrus          fgyrus_inst
  (

    .cr_intf          (fft_cache_cr_intf),

    .lb_intf          (fft_cache_lb_intf),

    .pcm_rdy_ih       (pcm_data_rdy_w),

    .pcm_lchnnl_intf  (acache_lchnnl_intf.master),

    .pcm_rchnnl_intf  (acache_rchnnl_intf.master)

  );


  /*  Visual Cortex Instantiation */
  syn_vcortex       vcortex_inst
  (

    .cr_intf        (cortex_cr_intf),

    .lb_intf        (vcortex_lb_intf),

    .sram_mem_intf  (sram_mem_intf),

    .vga_intf       (vga_intf)

  );

endmodule // syn_cortex
