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
 -- Interface Name    : syn_pxl_xfr_tb_intf
 -- Author            : mammenx
 -- Function          : This interface defines the set of signals to transfer
                        pixel information from module to module.
                        Used by sniffers.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

interface syn_pxl_xfr_tb_intf  #(
                              parameter type  PIXEL_TYPE  = syn_gpu_pkg::pxl_hsi_t,
                              parameter       WIDTHX= syn_gpu_pkg::P_X_W,
                              parameter       WIDTHY= syn_gpu_pkg::P_Y_W
                            )

                            (input  logic clk_ir, rst_il);

  //Logic signals
  PIXEL_TYPE          pxl;  //structure containing pixel data
  logic               pxl_wr_valid;   //1->pixel data is valid for write
  logic               pxl_rd_valid;   //1->pixel data is valid for read
  logic [WIDTHX-1:0]  posx;
  logic [WIDTHY-1:0]  posy;

  //Clocking block
  clocking  cb@(posedge  clk_ir);
    default input #2ns output #2ns;

    input pxl;
    input pxl_wr_valid;
    input pxl_rd_valid;
    input posx;
    input posy;

  endclocking : cb

  //Modports
  modport   tb  (clocking  cb, input rst_il, clk_ir);


endinterface  //  syn_pxl_xfr_tb_intf
