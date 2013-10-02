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
 -- Module Name       : syn_fgyrus_fft_cache
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This module maintains a ping-pong buffer to hold
                        FFT data that can be accessed by both Host & FSM.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_fgyrus_fft_cache (

  //--------------------- Misc Ports (Logic)  -----------
  syn_clk_rst_sync_intf   cr_intf,  //Clock Reset Interface

  syn_fft_cache_intf      cache_intf  //slave


  //--------------------- Interfaces --------------------


                );

//----------------------- Global parameters Declarations ------------------
  import  syn_global_pkh::*;
  import  syn_fft_pkg::*;

  parameter P_BFFR_DATA_W       = 32;
  parameter P_BFFR_ADDR_W       = 8;
  parameter P_BFFR_RDELAY_W     = 2;


//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------
  logic                       hst_bffr_sel_f;

  logic [P_BFFR_RDELAY_W-1:0] fsm_rdel_vec_f;
  logic [P_BFFR_RDELAY_W-1:0] hst_rdel_vec_f;

//----------------------- Internal Wire Declarations ----------------------
  logic [P_BFFR_DATA_W-1:0]   fft_real_bffr0_wdata_c;
  logic [P_BFFR_ADDR_W-1:0]   fft_real_bffr0_raddr_c;
  logic [P_BFFR_ADDR_W-1:0]   fft_real_bffr0_waddr_c;
  logic                       fft_real_bffr0_wren_c;
  logic [P_BFFR_DATA_W-1:0]   fft_real_bffr0_rdata_w;

  logic [P_BFFR_DATA_W-1:0]   fft_real_bffr1_wdata_c;
  logic [P_BFFR_ADDR_W-1:0]   fft_real_bffr1_raddr_c;
  logic [P_BFFR_ADDR_W-1:0]   fft_real_bffr1_waddr_c;
  logic                       fft_real_bffr1_wren_c;
  logic [P_BFFR_DATA_W-1:0]   fft_real_bffr1_rdata_w;

  logic [P_BFFR_DATA_W-1:0]   fft_im_bffr_wdata_w;
  logic [P_BFFR_ADDR_W-1:0]   fft_im_bffr_raddr_w;
  logic [P_BFFR_ADDR_W-1:0]   fft_im_bffr_waddr_w;
  logic                       fft_im_bffr_wren_w;
  logic [P_BFFR_DATA_W-1:0]   fft_im_bffr_rdata_w;


//----------------------- Start of Code -----------------------------------

  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : hst_bffr_sel_logic
    if(~cr_intf.rst_sync_l)
    begin
      hst_bffr_sel_f          <=  0;
      fsm_rdel_vec_f          <=  0;
      hst_rdel_vec_f          <=  0;
    end
    else
    begin
      hst_bffr_sel_f          <=  cache_intf.fft_done ? ~hst_bffr_sel_f : hst_bffr_sel_f;

      fsm_rdel_vec_f          <=  {fsm_rdel_vec_f[P_BFFR_RDELAY_W-2:0],cache_intf.rd_en};
      hst_rdel_vec_f          <=  {hst_rdel_vec_f[P_BFFR_RDELAY_W-2:0],cache_intf.hst_rd_en};
    end
  end

  always_comb
  begin : fft_bffr_mux_logic
    fft_im_bffr_wdata_w       =   cache_intf.wr_sample.im;
    fft_im_bffr_raddr_w       =   cache_intf.raddr;
    fft_im_bffr_waddr_w       =   cache_intf.waddr;
    fft_im_bffr_wren_w        =   cache_intf.wr_en;
    cache_intf.rd_valid       =   fsm_rdel_vec_f[P_BFFR_RDELAY_W-1];
    cache_intf.rd_sample.im   =   fft_im_bffr_rdata_w;

    cache_intf.hst_rd_valid   =   hst_rdel_vec_f[P_BFFR_RDELAY_W-1];

    if(hst_bffr_sel_f)
    begin
      fft_real_bffr0_wdata_c  =   cache_intf.wr_sample.re;
      fft_real_bffr0_raddr_c  =   cache_intf.raddr;
      fft_real_bffr0_waddr_c  =   cache_intf.waddr;
      fft_real_bffr0_wren_c   =   cache_intf.wr_en;
      cache_intf.rd_sample.re =   fft_real_bffr0_rdata_w;

      fft_real_bffr1_wdata_c  =   cache_intf.hst_wr_data;
      fft_real_bffr1_raddr_c  =   cache_intf.hst_addr;
      fft_real_bffr1_waddr_c  =   cache_intf.hst_addr;
      fft_real_bffr1_wren_c   =   cache_intf.hst_wr_en;
      cache_intf.hst_rd_data  =   fft_real_bffr1_rdata_w;
    end
    else
    begin
      fft_real_bffr1_wdata_c  =   cache_intf.wr_sample.re;
      fft_real_bffr1_raddr_c  =   cache_intf.raddr;
      fft_real_bffr1_waddr_c  =   cache_intf.waddr;
      fft_real_bffr1_wren_c   =   cache_intf.wr_en;
      cache_intf.rd_sample.re =   fft_real_bffr1_rdata_w;

      fft_real_bffr0_wdata_c  =   cache_intf.hst_wr_data;
      fft_real_bffr0_raddr_c  =   cache_intf.hst_addr;
      fft_real_bffr0_waddr_c  =   cache_intf.hst_addr;
      fft_real_bffr0_wren_c   =   cache_intf.hst_wr_en;
      cache_intf.hst_rd_data  =   fft_real_bffr0_rdata_w;
    end
  end

  ram_2xM4K_32bW_256D   fft_real_bffr0_inst
  (
    .clock              (cr_intf.clk_ir),
    .data               (fft_real_bffr0_wdata_c),
    .rdaddress          (fft_real_bffr0_raddr_c),
    .wraddress          (fft_real_bffr0_waddr_c),
    .wren               (fft_real_bffr0_wren_c),
    .q                  (fft_real_bffr0_rdata_w)
  );

  ram_2xM4K_32bW_256D   fft_real_bffr1_inst
  (
    .clock              (cr_intf.clk_ir),
    .data               (fft_real_bffr1_wdata_c),
    .rdaddress          (fft_real_bffr1_raddr_c),
    .wraddress          (fft_real_bffr1_waddr_c),
    .wren               (fft_real_bffr1_wren_c),
    .q                  (fft_real_bffr1_rdata_w)
  );

  ram_2xM4K_32bW_256D   fft_im_bffr_inst
  (
    .clock              (cr_intf.clk_ir),
    .data               (fft_im_bffr_wdata_w),
    .rdaddress          (fft_im_bffr_raddr_w),
    .wraddress          (fft_im_bffr_waddr_w),
    .wren               (fft_im_bffr_wren_w),
    .q                  (fft_im_bffr_rdata_w)
  );

endmodule // syn_fgyrus_fft_cache
