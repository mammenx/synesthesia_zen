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
 -- Module Name       : syn_gpu_ff_cntrlr
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This module maintains the read/write pixel pointers
                        to access the GPU FF in SRAM memory.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_gpu_ff_cntrlr (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf           cr_intf,      //Clock Reset Interface

  syn_gpu_ff_cntrlr_intf          ff_intf       //Interface to host/master

  //--------------------- Misc Ports (Logic)  -----------

                );

//----------------------- Global parameters Declarations ------------------
  import  syn_global_pkg::*;
  import  syn_gpu_pkg::*;

  parameter   P_FF_SIZE       = 212;        //In KBytes
  parameter   P_FF_START_POSX = 0;
  parameter   P_FF_START_POSY = P_CANVAS_H; //Frame buffer extends to {P_CANVAS_W-1,P_CANVAS_H-1}
  parameter   P_FF_END_POSX   = (((P_FF_SIZE*1024*8)/P_PXL_HSI_W)  % P_CANVAS_W)  - 4;
  parameter   P_FF_END_POSY   = P_FF_START_POSY + ((P_FF_SIZE*1024*8)/(P_CANVAS_W*P_PXL_HSI_W));


//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------
  point_t                     wptr_f;
  point_t                     rptr_f;
  logic                       wptr_zone_f;
  logic                       rptr_zone_f;
  logic                       empty_f;
  logic                       full_f;

//----------------------- Internal Wire Declarations ----------------------
  logic                       valid_write_c;
  logic                       valid_read_c;
  logic                       wrap_wptr_x_c;
  logic                       wrap_wptr_y_c;
  point_t                     wptr_nxt_c;
  logic                       wrap_rptr_x_c;
  logic                       wrap_rptr_y_c;
  point_t                     rptr_nxt_c;


//----------------------- Start of Code -----------------------------------

  //Check if valid read/write
  assign  valid_read_c        = ff_intf.rd_en  & ~ff_intf.empty;
  assign  valid_write_c       = ff_intf.wr_en  & ~ff_intf.full;

  //Check if wptr needs to be wrapped
  assign  wrap_wptr_x_c       = (wptr_f.x[P_X_W-1:0]  ==  P_FF_END_POSX)  ? valid_write_c : 1'b0;
  assign  wrap_wptr_y_c       = (wptr_f.y[P_Y_W-1:0]  ==  P_FF_END_POSY)  ? wrap_wptr_x_c : 1'b0;
  //Calculate the next value of wptr
  assign  wptr_nxt_c.x[P_X_W-1:0] = wrap_wptr_x_c ? P_FF_START_POSX : wptr_f.x[P_X_W-1:0] + {valid_write_c,2'b0};
  assign  wptr_nxt_c.y[P_Y_W-1:0] = wrap_wptr_y_c ? P_FF_START_POSY : wptr_f.y[P_Y_W-1:0] + wrap_wptr_x_c;

  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : wptr_logic
    if(~cr_intf.rst_sync_l)
    begin
      wptr_f.x                <=  P_FF_START_POSX;
      wptr_f.y                <=  P_FF_START_POSY;
      wptr_zone_f             <=  0;
    end
    else
    begin
      wptr_f                  <=  wptr_nxt_c;

      wptr_zone_f             <=  wptr_zone_f ^ wrap_wptr_y_c;
    end
  end

  //Check if rptr needs to be wrapped
  assign  wrap_rptr_x_c       = (rptr_f.x[P_X_W-1:0]  ==  P_FF_END_POSX)  ? valid_read_c  : 1'b0;
  assign  wrap_rptr_y_c       = (rptr_f.y[P_Y_W-1:0]  ==  P_FF_END_POSY)  ? wrap_rptr_x_c : 1'b0;
  //Calculate the next value of rptr
  assign  rptr_nxt_c.x[P_X_W-1:0] = wrap_rptr_x_c ? P_FF_START_POSX : rptr_f.x[P_X_W-1:0] + {valid_read_c,2'b0};
  assign  rptr_nxt_c.y[P_Y_W-1:0] = wrap_rptr_y_c ? P_FF_START_POSY : rptr_f.y[P_Y_W-1:0] + wrap_rptr_x_c;

  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : rptr_logic
    if(~cr_intf.rst_sync_l)
    begin
      rptr_f.x                <=  P_FF_START_POSX;
      rptr_f.y                <=  P_FF_START_POSY;
      rptr_zone_f             <=  0;
    end
    else
    begin
      rptr_f                  <=  rptr_nxt_c;

      rptr_zone_f             <=  rptr_zone_f ^ wrap_rptr_y_c;
    end
  end


  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : full_empty_logic
    if(~cr_intf.rst_sync_l)
    begin
      full_f                  <=  0;
      empty_f                 <=  1;
    end
    else
    begin
      full_f                  <=  (wptr_nxt_c ==  rptr_nxt_c) ? wptr_zone_f ^ rptr_zone_f     : 1'b0;

      empty_f                 <=  (wptr_nxt_c ==  rptr_nxt_c) ? ~(wptr_zone_f ^ rptr_zone_f)  : 1'b0;
    end
  end

  //assign outputs
  assign  ff_intf.empty  = empty_f;
  assign  ff_intf.full   = full_f;
  assign  ff_intf.waddr  = wptr_f;
  assign  ff_intf.raddr  = rptr_f;

endmodule // syn_gpu_ff_cntrlr
