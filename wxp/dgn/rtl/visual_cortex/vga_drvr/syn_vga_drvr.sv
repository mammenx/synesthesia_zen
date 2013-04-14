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
 -- Module Name       : syn_vga_drvr
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This is the VGA Driver top module.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_vga_drvr (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf       cr_intf,      //Clock Reset Interface

  sram_acc_intf               sram_intf,

  syn_lb_intf                 lb_intf,      //DATA_W=32,  ADDR_W=8

  syn_vga_intf                vga_intf

  //--------------------- Misc Ports (Logic)  -----------

                );

//----------------------- Global parameters Declarations ------------------
  import  syn_global_pkg::*;
  import  syn_gpu_pkg::*;


//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------


//----------------------- Internal Wire Declarations ----------------------


//----------------------- Internal Interface Declarations -----------------
  syn_vga_drvr_lb_intf        vga_lb_intf(cr_intf.clk_ir, cr_intf.rst_sync_l);
  ff_intf#(P_8B_W)            lbffr2fsm_intf(cr_intf.clk_ir, cr_intf.rst_sync_l);




//----------------------- Start of Code -----------------------------------

  //Instantiating modules
  syn_vga_lb  syn_vga_lb_inst
  (

    .cr_intf      (cr_intf),

    .lb_intf      (lb_intf),

    .vga_lb_intf  (vga_lb_intf.lb)

  );

  syn_vga_line_bffr syn_vga_line_bffr_inst
  (

    .cr_intf      (cr_intf),

    .sram_intf    (sram_intf),

    .fsm_intf     (lbffr2fsm_intf.rd_only_slave),

    .lb_intf      (vga_lb_intf.line_bffr)

  );

  syn_vga_fsm   syn_vga_fsm_inst
  (

    .cr_intf      (cr_intf),

    .lbffr_intf   (lbffr2fsm_intf.rd_only),

    .vga_intf     (vga_intf),

    .lb_intf      (vga_lb_intf.fsm)

  );


endmodule // syn_vga_drvr
