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
 -- Module Name       : syn_fgyrus
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : Top level Fusiform Gyrus.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_fgyrus (

  //--------------------- Misc Ports (Logic)  -----------
  syn_clk_rst_sync_intf   cr_intf,  //Clock Reset Interface

  syn_lb_intf             lb_intf,  //slave, data=32, addr=12

  input logic             pcm_rdy_ih,

  mem_intf                pcm_lchnnl_intf,  //master, DATA_W=32, ADDR_W=7

  mem_intf                pcm_rchnnl_intf   //master, DATA_W=32, ADDR_W=7

  //--------------------- Interfaces --------------------


                );

//----------------------- Global parameters Declarations ------------------


//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------


//----------------------- Internal Wire Declarations ----------------------


//----------------------- Internal Interface Declarations -----------------
  mem_intf#(32,7)             win_ram_intf(cr_intf.clk_ir,  cr_intf.rst_sync_l);
  mem_intf#(32,7)             twdl_ram_intf(cr_intf.clk_ir,  cr_intf.rst_sync_l);
  mem_intf#(16,8)             cordic_ram_intf(cr_intf.clk_ir,  cr_intf.rst_sync_l);
  syn_fft_cache_intf#(32,8)   fft_cache_intf(cr_intf.clk_ir,  cr_intf.rst_sync_l);
  syn_but_intf                but_intf(cr_intf.clk_ir,  cr_intf.rst_sync_l);

//----------------------- FSM Declarations --------------------------------



//----------------------- Start of Code -----------------------------------

  syn_fgyrus_fsm  syn_fgyrus_fsm_inst
  (

    .cr_intf          (cr_intf),

    .lb_intf          (lb_intf),

    .but_intf         (but_intf.master),

    .pcm_rdy_ih       (pcm_rdy_ih),

    .pcm_lchnnl_intf  (pcm_lchnnl_intf),

    .pcm_rchnnl_intf  (pcm_rchnnl_intf),

    .win_ram_intf     (win_ram_intf.master),

    .twdl_ram_intf    (twdl_ram_intf.master),

    .cordic_ram_intf  (cordic_ram_intf.master),

    .cache_intf       (fft_cache_intf.master)

  );

  syn_but_wing  syn_but_wing_inst
  (

    .cr_intf    (cr_intf),

    .but_intf   (but_intf.slave)

  );

  syn_fgyrus_fft_cache  syn_fgyrus_fft_cache_inst
  (

    .cr_intf        (cr_intf),

    .cache_intf     (fft_cache_intf.slave)

  );

  win_ram       win_ram_inst
  (
    .clock      (cr_intf.clk_ir),
    .data       (win_ram_intf.wdata),
    .rdaddress  (win_ram_intf.addr),
    .wraddress  (win_ram_intf.addr),
    .wren       (win_ram_intf.wren),
    .q          (win_ram_intf.rdata)
  );

  cordic_ram    cordic_ram_inst
  (
    .data       (cordic_ram_intf.wdata),
    .rdaddress  (cordic_ram_intf.addr),
    .rdclock    (cr_intf.clk_ir),
    .wraddress  (cordic_ram_intf.addr),
    .wrclock    (cr_intf.clk_ir),
    .wren       (cordic_ram_intf.wren),
    .q          (cordic_ram_intf.rdata)
  );

  twiddle_ram   twiddle_ram_inst
  (
    .clock      (cr_intf.clk_ir),
    .data       (twdl_ram_intf.wdata),
    .rdaddress  (twdl_ram_intf.addr),
    .wraddress  (twdl_ram_intf.addr),
    .wren       (twdl_ram_intf.wren),
    .q          (twdl_ram_intf.rdata)
  );

endmodule // syn_fgyrus
