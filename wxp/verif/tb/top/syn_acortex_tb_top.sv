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
 -- Component Name    : syn_acortex_tb_top
 -- Author            : mammenx
 -- Function          : TB top module which instantiates acortex DUT.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/


`ifndef __SYN_ACORTEX_TB_TOP
`define __SYN_ACORTEX_TB_TOP

  /////////////////////////////////////////////////////
  // Importing OVM Packages                          //
  /////////////////////////////////////////////////////

  `include "ovm.svh"
  import ovm_pkg::*;

  `timescale  1ns/100ps

  module syn_acortex_tb_top();

    parameter LB_DATA_W = 32;
    parameter LB_ADDR_W = 12;
    parameter PCM_MEM_DATA_W  = 32;
    parameter PCM_MEM_ADDR_W  = 7;


    `include  "acortex_tb.list"


    //Clock Reset signals
    logic   sys_clk_50;
    logic   sys_clk_100;
    logic   sys_rst;



    //Interfaces
    syn_clk_rst_sync_intf             cr_intf(sys_clk_50,sys_rst);
    syn_clk_rst_sync_intf             fgyrus_cr_intf(sys_clk_100,sys_rst);

    syn_lb_intf#(LB_DATA_W,LB_ADDR_W) lb_intf(sys_clk_50,sys_rst);

    syn_lb_tb_intf#(LB_DATA_W,LB_ADDR_W) lb_tb_intf(sys_clk_50,sys_rst, lb_intf.wr_valid, lb_intf.rd_valid, lb_intf.rd_data);

    syn_wm8731_intf                   wm8731_intf(sys_rst);

    mem_intf#(PCM_MEM_DATA_W,PCM_MEM_ADDR_W)  lpcm_mem_intf(sys_clk_100,rst_il);
    mem_intf#(PCM_MEM_DATA_W,PCM_MEM_ADDR_W)  rpcm_mem_intf(sys_clk_100,rst_il);
    syn_pcm_mem_intf#(PCM_MEM_DATA_W,PCM_MEM_ADDR_W)  pcm_mem_tb_intf(sys_clk_100,rst_il);

    syn_clk_vec_intf#(4)    clk_vec_intf(4'd0);

    //Assigning LB signals from TB to DUT
    assign  lb_intf.rd_en     = lb_tb_intf.rd_en;
    assign  lb_intf.wr_en     = lb_tb_intf.wr_en;
    assign  lb_intf.wr_data   = lb_tb_intf.wr_data;
    assign  lb_intf.addr      = lb_tb_intf.addr;

    //Assigning signals from TB to DUT
    assign  lpcm_mem_intf.addr    = pcm_mem_tb_intf.pcm_addr;
    assign  lpcm_mem_intf.wdata   = pcm_mem_tb_intf.lpcm_wdata;
    assign  lpcm_mem_intf.wren    = pcm_mem_tb_intf.pcm_wren;
    assign  lpcm_mem_intf.rden    = pcm_mem_tb_intf.pcm_rden;

    assign  rpcm_mem_intf.addr    = pcm_mem_tb_intf.pcm_addr;
    assign  rpcm_mem_intf.wdata   = pcm_mem_tb_intf.rpcm_wdata;
    assign  rpcm_mem_intf.wren    = pcm_mem_tb_intf.pcm_wren;
    assign  rpcm_mem_intf.rden    = pcm_mem_tb_intf.pcm_rden;

    assign  pcm_mem_tb_intf.lpcm_rdata = lpcm_mem_intf.rdata;
    assign  pcm_mem_tb_intf.rpcm_rdata = rpcm_mem_intf.rdata;
    assign  pcm_mem_tb_intf.pcm_rd_valid  = lpcm_mem_intf.rd_valid  | rpcm_mem_intf.rd_valid;

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
      sys_rst   = 1;

      #123;

      sys_rst   = 0;

      #321;

      sys_rst   = 1;

    end



    /*  DUT */
  syn_acortex               syn_acortex_inst
  (

    .cr_intf                (cr_intf.sync),

    .lb_intf                (lb_intf.slave),

    .wm8731_intf            (wm8731_intf),

    .fgyrus_cr_intf         (fgyrus_cr_intf.sync),

    .fgyrus_lchnnl_mem_intf (lpcm_mem_intf.slave),

    .fgyrus_rchnnl_mem_intf (rpcm_mem_intf.slave),

    .fgyrus_pcm_data_rdy_oh (pcm_mem_tb_intf.pcm_data_rdy),

    .clk_vec_intf           (clk_vec_intf.dut)
  );



    initial
    begin
      #1;
      run_test();
    end

  endmodule

`endif
