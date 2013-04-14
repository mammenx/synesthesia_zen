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
 -- Component Name    : syn_vcortex_tb_top
 -- Author            : mammenx
 -- Function          : TB top module which instantiates vcortex DUT.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/


`ifndef __SYN_VCORTEX_TB_TOP
`define __SYN_VCORTEX_TB_TOP

  /////////////////////////////////////////////////////
  // Importing OVM Packages                          //
  /////////////////////////////////////////////////////

  `include "ovm.svh"
  import ovm_pkg::*;

  `timescale  1ns/100ps

  module syn_vcortex_tb_top();

    parameter LB_DATA_W = 32;
    parameter LB_ADDR_W = 12;
    parameter VGA_RES_W = 4;


    `include  "vcortex_tb.list"


    //Clock Reset signals
    logic   sys_clk_50;
    logic   sys_rst;



    //Interfaces
    syn_clk_rst_sync_intf             cr_intf(sys_clk_50,sys_rst);

    syn_lb_intf#(LB_DATA_W,LB_ADDR_W) lb_intf(sys_clk_50,sys_rst);
    //syn_lb_intf                       lb_intf(sys_clk_50,sys_rst);
    //defparam  lb_intf.DATA_W  = LB_DATA_W;
    //defparam  lb_intf.ADDR_W  = LB_ADDR_W;

    syn_sram_mem_intf                 sram_mem_intf(sys_clk_50,sys_rst);

    syn_vga_intf#(VGA_RES_W)          vga_intf(sys_clk_50,sys_rst);
    //syn_vga_intf                      vga_intf(sys_clk_50,sys_rst);
    //defparam  vga_intf.WIDTH  = VGA_RES_W;


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
  syn_vcortex   syn_vcortex_inst
  (
    .cr_intf        (cr_intf.sync),   //Clock Reset Interface

    .lb_intf        (lb_intf.slave),  //DATA_W=32, ADDR_W=12

    .sram_mem_intf  (sram_mem_intf.mp),

    .vga_intf       (vga_intf.mp)

  );



    initial
    begin
      #1;
      run_test();
    end

  endmodule

`endif
