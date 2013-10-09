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
  import  syn_global_pkg::*;
  import  syn_fft_pkg::*;

  parameter P_LB_DATA_W         = P_32B_W;
  parameter P_LB_ADDR_W         = 12;

  parameter P_MEM_RD_DEL        = 2;

//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------
  logic [P_MEM_RD_DEL-1:0]    win_ram_rdel_vec_f;
  logic [P_MEM_RD_DEL-1:0]    twdl_ram_rdel_vec_f;
  logic [P_MEM_RD_DEL-1:0]    cordic_ram_rdel_vec_f;

//----------------------- Internal Wire Declarations ----------------------


//----------------------- Internal Interface Declarations -----------------
  mem_intf#(32,7)             win_ram_intf(cr_intf.clk_ir,  cr_intf.rst_sync_l);
  mem_intf#(32,7)             twdl_ram_intf(cr_intf.clk_ir,  cr_intf.rst_sync_l);
  mem_intf#(16,8)             cordic_ram_intf(cr_intf.clk_ir,  cr_intf.rst_sync_l);
  syn_fft_cache_intf#(32,8)   fft_cache_intf(cr_intf.clk_ir,  cr_intf.rst_sync_l);
  syn_but_intf                but_intf(cr_intf.clk_ir,  cr_intf.rst_sync_l);

//----------------------- FSM Declarations --------------------------------



//----------------------- Start of Code -----------------------------------


  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : rd_rdy_logic
    if(~cr_intf.rst_sync_l)
    begin
      win_ram_rdel_vec_f      <=  0;
      twdl_ram_rdel_vec_f     <=  0;
      cordic_ram_rdel_vec_f   <=  0;
    end
    else
    begin
      win_ram_rdel_vec_f      <=  {win_ram_rdel_vec_f[P_MEM_RD_DEL-2:0],  win_ram_intf.rden};
      twdl_ram_rdel_vec_f     <=  {twdl_ram_rdel_vec_f[P_MEM_RD_DEL-2:0], twdl_ram_intf.rden};
      cordic_ram_rdel_vec_f   <=  {cordic_ram_rdel_vec_f[P_MEM_RD_DEL-2:0], cordic_ram_intf.rden};
    end
  end

  assign  win_ram_intf.rd_valid     = win_ram_rdel_vec_f[P_MEM_RD_DEL-1];
  assign  twdl_ram_intf.rd_valid    = twdl_ram_rdel_vec_f[P_MEM_RD_DEL-1];
  assign  cordic_ram_intf.rd_valid  = cordic_ram_rdel_vec_f[P_MEM_RD_DEL-1];


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
