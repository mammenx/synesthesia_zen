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
 -- Component Name    : syn_sram_acc_tb_top
 -- Author            : mammenx
 -- Function          : TB top module which instantiates sram acc DUT.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/


`ifndef __SYN_SRAM_ACC_TB_TOP
`define __SYN_SRAM_ACC_TB_TOP

  /////////////////////////////////////////////////////
  // Importing OVM Packages                          //
  /////////////////////////////////////////////////////

  `include "ovm.svh"
  import ovm_pkg::*;

  `timescale  1ns/100ps

  module syn_sram_acc_tb_top();

    `include  "sram_acc_tb.list"

    //Parameters
    parameter       SRAM_DATA_W = 16;
    parameter       SRAM_ADDR_W = 18;
    parameter type  SRAM_PKT_T  = syn_lb_seq_item#(SRAM_DATA_W,SRAM_ADDR_W);
    parameter type  SRAM_INTF_T = virtual syn_sram_mem_intf.TB;

    parameter       VGA_AGENT_ADDR_W  = SRAM_ADDR_W;
    parameter       VGA_AGENT_DATA_W  = SRAM_DATA_W;
    parameter type  VGA_AGENT_PKT_T   = syn_lb_seq_item#(VGA_AGENT_DATA_W,VGA_AGENT_ADDR_W);
    parameter type  VGA_AGENT_INTF_T  = virtual syn_sram_acc_agent_intf#(VGA_AGENT_DATA_W,VGA_AGENT_ADDR_W);

    parameter       GPU_AGENT_ADDR_W  = SRAM_ADDR_W+1;
    parameter       GPU_AGENT_DATA_W  = SRAM_DATA_W/2;
    parameter type  GPU_AGENT_PKT_T   = syn_lb_seq_item#(GPU_AGENT_DATA_W,GPU_AGENT_ADDR_W);
    parameter type  GPU_AGENT_INTF_T  = virtual syn_sram_acc_agent_intf#(GPU_AGENT_DATA_W,GPU_AGENT_ADDR_W);


    //Clock Reset signals
    logic   sys_clk_50;
    logic   sys_rst;
    logic   vga_pxl_clk;



    //Interfaces
    syn_sram_acc_agent_intf#(VGA_AGENT_DATA_W,VGA_AGENT_ADDR_W) vga_sram_acc_intf(
                                                                                  .clk_ir(sys_clk_50),
                                                                                  .rst_il(sys_rst)
                                                                                 );

    assign  vga_sram_acc_intf.rdy       = sram_acc_bus.vga_rdy;
    assign  vga_sram_acc_intf.rd_valid  = sram_acc_bus.vga_rd_valid;
    assign  vga_sram_acc_intf.rd_data   = sram_acc_bus.vga_rd_data;
    assign  sram_acc_bus.vga_rd_en      = vga_sram_acc_intf.rd_en;
    //assign  sram_acc_bus.vga_wr_en      = vga_sram_acc_intf.wr_en;
    //assign  sram_acc_bus.vga_wr_data    = vga_sram_acc_intf.wr_data;
    assign  sram_acc_bus.vga_addr       = vga_sram_acc_intf.addr;

     syn_sram_acc_agent_intf#(GPU_AGENT_DATA_W,GPU_AGENT_ADDR_W) gpu_sram_acc_intf(
                                                                                  .clk_ir(sys_clk_50),
                                                                                  .rst_il(sys_rst)
                                                                                 );

    assign  gpu_sram_acc_intf.rdy       = sram_acc_bus.gpu_rdy;
    assign  gpu_sram_acc_intf.rd_valid  = sram_acc_bus.gpu_rd_valid;
    assign  gpu_sram_acc_intf.rd_data   = sram_acc_bus.gpu_rd_data;
    assign  sram_acc_bus.gpu_rd_en      = gpu_sram_acc_intf.rd_en;
    assign  sram_acc_bus.gpu_wr_en      = gpu_sram_acc_intf.wr_en;
    assign  sram_acc_bus.gpu_wr_data    = gpu_sram_acc_intf.wr_data;
    assign  sram_acc_bus.gpu_addr       = gpu_sram_acc_intf.addr;



    syn_sram_mem_intf                 sram_mem_intf(sys_clk_50,sys_rst);

    syn_clk_rst_sync_intf             cr_intf(sys_clk_50,sys_rst);




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
      sys_rst   = 1;

      #123;

      sys_rst   = 0;

      #321;

      sys_rst   = 1;

    end


    /*  DUT */
    syn_sram_mem_drvr syn_sram_mem_drvr_inst
    (
      .cr_intf        (cr_intf.sync),

      .sram_bus_intf  (sram_acc_bus.sram),

      .sram_mem_intf  (sram_mem_intf.mp)
    );


    sram_acc_intf#(SRAM_DATA_W,SRAM_ADDR_W,2)  sram_acc_bus(sys_clk_50,sys_rst);
    //sram_acc_intf  sram_acc_bus(sys_clk_50,sys_rst);


    initial
    begin
      #1;
      run_test();
    end






  endmodule

`endif
