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
 -- Module Name       : syn_gpu_lf_cntrlr
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This module maintains the read/write pixel pointers
                        to access the GPU FF in SRAM memory as a LIFO/Stack.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_gpu_lf_cntrlr (

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
  parameter   P_PTR_INC_DEC_VAL = 4;
  //parameter   P_FF_END_POSX   = (((P_FF_SIZE*1024*8)/P_PXL_HSI_W)  % P_CANVAS_W)  - P_PTR_INC_DEC_VAL;
  //parameter   P_FF_END_POSY   = P_FF_START_POSY + ((P_FF_SIZE*1024*8)/(P_CANVAS_W*P_PXL_HSI_W));
  parameter   P_FF_END_POSX   = P_CANVAS_W  - 4;
  parameter   P_FF_END_POSY   = P_FF_START_POSY + ((P_FF_SIZE*1024*8)/(P_CANVAS_W*P_PXL_HSI_W)) - 1;
  localparam  P_OCC_CNTR_SIZE = $clog2(P_FF_SIZE*1024);


//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------
  point_t                     ptr_f;


//----------------------- Internal Wire Declarations ----------------------
  logic                       valid_wr_c;
  logic                       valid_rd_c;

//----------------------- Start of Code -----------------------------------

  //Check if vaild read/write
  assign  valid_wr_c  = ff_intf.wr_en & ~ff_intf.full;
  assign  valid_rd_c  = ff_intf.rd_en & ~ff_intf.empty;

  //Calculate the next rd/wr addresses

  /*  Pointer & Status Logic */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : wptr_logic
    if(~cr_intf.rst_sync_l)
    begin
      ptr_f.x                 <=  P_FF_START_POSX;
      ptr_f.y                 <=  P_FF_START_POSY;

      ff_intf.full            <=  1'b0;
      ff_intf.empty           <=  1'b1;
    end
    else
    begin
      case({valid_wr_c,valid_rd_c})

        2'b00 : 
        begin
          ptr_f               <=  ptr_f;
        end

        2'b01 :
        begin
          if(ptr_f.x  ==  P_FF_START_POSX)
          begin
            ptr_f.x           <=  P_FF_END_POSX;
            ptr_f.y           <=  ptr_f.y - 1'b1;
          end
          else
          begin
            ptr_f.x           <=  ptr_f.x - 3'd4;
            ptr_f.y           <=  ptr_f.y;
          end
        end

        2'b10 :
        begin
          if(ptr_f.x  ==  P_FF_END_POSX)
          begin
            ptr_f.x           <=  P_FF_START_POSX;
            ptr_f.y           <=  ptr_f.y + 1'b1;
          end
          else
          begin
            ptr_f.x           <=  ptr_f.x + 3'd4;
            ptr_f.y           <=  ptr_f.y;
          end
        end

        2'b11 : 
        begin
          ptr_f               <=  ptr_f;
        end

      endcase


      if(ff_intf.empty)
      begin
        ff_intf.empty <=  ~valid_wr_c;
      end
      else
      begin
        ff_intf.empty <=  ((ff_intf.waddr.x ==  P_FF_START_POSX  + P_PTR_INC_DEC_VAL) &
                          (ff_intf.waddr.y  ==  P_FF_START_POSY)) ? valid_rd_c  & ~valid_wr_c : ff_intf.empty;
      end

      if(ff_intf.full)
      begin
        ff_intf.full  <=  ~valid_rd_c;
      end
      else
      begin
        ff_intf.full  <=  ((ff_intf.waddr.x ==  P_FF_END_POSX) &
                          (ff_intf.waddr.y  ==  P_FF_END_POSY))   ? ~valid_rd_c  & valid_wr_c : ff_intf.full;
      end
    end
  end

  always_comb
  begin
    ff_intf.waddr = ptr_f;


    if(ff_intf.empty)
    begin
      ff_intf.raddr.x = P_FF_START_POSX;
      ff_intf.raddr.y = P_FF_START_POSY;
    end
    else if(ff_intf.waddr.x ==  P_FF_START_POSX)
    begin
      ff_intf.raddr.x = P_FF_END_POSX;
      ff_intf.raddr.y = ff_intf.waddr.y - 1'b1;
    end
    else
    begin
      ff_intf.raddr.x = ff_intf.waddr.x - 3'd4;
      ff_intf.raddr.y = ff_intf.waddr.y;
    end
  end

endmodule // syn_gpu_lf_cntrlr
