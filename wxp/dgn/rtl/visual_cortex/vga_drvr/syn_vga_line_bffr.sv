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
 -- Module Name       : syn_vga_line_bffr
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This block contains logic that reads pixel data
                        from SRAM & buffers it. The buffer size is meant to
                        accomodate ~2 lines (1280 pixels) of data.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_vga_line_bffr (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf       cr_intf,      //Clock Reset Interface

  sram_acc_intf               sram_intf,

  ff_intf                     fsm_intf,     //DATA_W=8, FWFT

  syn_vga_drvr_lb_intf        lb_intf


  //--------------------- Misc Ports (Logic)  -----------

                );

//----------------------- Global parameters Declarations ------------------
  import  syn_global_pkg::*;
  import  syn_gpu_pkg::*;

  localparam  P_BFFR_SIZE     = 4*4096;
  localparam  P_BFFR_DATA_W   = 16;
  localparam  P_BFFR_OCC_W    = $clog2(P_BFFR_SIZE  / P_BFFR_DATA_W);
  parameter   P_BFFR_LMARK    = (P_CANVAS_W * (P_LUM_W  + P_CHRM_W  + P_CHRM_W) / P_BFFR_DATA_W);
  parameter   P_BFFR_HMARK    = (P_BFFR_SIZE  / P_BFFR_DATA_W)  - 16;
  parameter   P_LAST_FRAME_BFFR_ADDR  = ((P_CANVAS_W * P_CANVAS_H) / 2) - 1;

//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------
  logic                       bffr_rd_ms_sel_f;

//----------------------- Internal Wire Declarations ----------------------
  logic                       wrap_sram_addr_c;
  logic                       inc_sram_addr_c;

  logic [P_BFFR_DATA_W-1:0]   bffr_ram_rd_data_w;
  logic                       bffr_empty_w;
  logic                       bffr_full_w;
  logic [P_BFFR_OCC_W-1:0]    bffr_occ_w;
  logic                       bffr_afull_c;


//----------------------- Start of Code -----------------------------------

  //Check if SRAM address needs to be wrapped around
  assign  wrap_sram_addr_c    = (sram_intf.vga_addr ==  P_LAST_FRAME_BFFR_ADDR) ? inc_sram_addr_c : 1'b0;

  //Logic for incrementing SRAM address
  assign  inc_sram_addr_c     = sram_intf.vga_rd_en & sram_intf.vga_rdy;

  /*  SRAM Interfacing logic  */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : sram_intf_logic
    if(~cr_intf.rst_sync_l)
    begin
      sram_intf.vga_addr      <=  0;
      sram_intf.vga_rd_en     <=  1'b0;
    end
    else
    begin
      sram_intf.vga_rd_en     <=  lb_intf.vga_drvr_en & ~bffr_afull_c;

      if(wrap_sram_addr_c)
      begin
        sram_intf.vga_addr    <=  0;
      end
      else
      begin
        sram_intf.vga_addr    <=  sram_intf.vga_addr  + inc_sram_addr_c;
      end
    end
  end


  /*  Buffer management logic */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : bffr_mgmnt_logic
    if(~cr_intf.rst_sync_l)
    begin
      bffr_rd_ms_sel_f        <=  1'b0;
    end
    else
    begin
      if(fsm_intf.ff_rd_en)
      begin
        bffr_rd_ms_sel_f      <=  ~bffr_rd_ms_sel_f;
      end
    end
  end


  /*  Instantiating Line buffer */
  ff_4xM4k_fwft   vga_line_bffr_ff_inst
  (
    .aclr         (~cr_intf.rst_sync_l),
    .clock        (cr_intf.clk_ir),
    .data         (sram_intf.vga_rd_data),
    .rdreq        (fsm_intf.ff_rd_en  & bffr_rd_ms_sel_f),
    .wrreq        (sram_intf.vga_rd_valid),
    .empty        (bffr_empty_w),
    .full         (bffr_full_w),
    .q            (bffr_ram_rd_data_w),
    .usedw        (bffr_occ_w)
  );

  assign  fsm_intf.ff_rd_data = bffr_rd_ms_sel_f  ? bffr_ram_rd_data_w[P_BFFR_DATA_W-1:P_8B_W]
                                                  : bffr_ram_rd_data_w[P_8B_W-1:0];

  assign  fsm_intf.ff_empty   = (bffr_occ_w >=  P_BFFR_LMARK) ? 1'b0  : 1'b1;

  assign  bffr_afull_c        = (bffr_occ_w >=  P_BFFR_HMARK) ? 1'b1  : 1'b0;

  assign  lb_intf.bffr_overflow   = sram_intf.vga_rd_valid  & bffr_full_w;
  assign  lb_intf.bffr_underflow  = fsm_intf.ff_rd_en & fsm_intf.ff_empty;

endmodule // syn_vga_line_bffr
