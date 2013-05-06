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
 -- Interface Name    : syn_pxl_xfr_intf
 -- Author            : mammenx
 -- Function          : This interface defines the set of signals to transfer
                        pixel information from module to module
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

interface syn_pxl_xfr_intf  #(
                              parameter       WIDTHX= syn_gpu_pkg::P_X_W,
                              parameter       WIDTHY= syn_gpu_pkg::P_Y_W
                            )

                            (input  logic clk_ir, rst_il);


  import  syn_global_pkg::P_16B_W;
  import  syn_gpu_pkg::pxl_ycbcr_t;
  import  syn_gpu_pkg::pxl_hsi_t;

  //Logic signals
  //pxl_ycbcr_t         pxl;  //structure containing pixel data
  pxl_hsi_t           pxl;  //structure containing pixel data
  logic               pxl_wr_valid;   //1->pixel data is valid for write
  logic               pxl_rd_valid;   //1->pixel data is valid for read
  logic               ready;          //1->Slave is ready to accept pixel data
  logic [WIDTHX-1:0]  posx;
  logic [WIDTHY-1:0]  posy;
  logic [P_16B_W-1:0] misc_info_dist; //Used by anti aliaser
  logic [P_16B_W-1:0] misc_info_norm; //Used by anti aliaser


  //Modports
  modport   master  (
                      output  pxl,
                      output  pxl_wr_valid,
                      output  pxl_rd_valid,
                      output  posx,
                      output  posy,
                      output  misc_info_dist,
                      output  misc_info_norm,
                      input   ready
                    );

  modport   slave   (
                      input   pxl,
                      input   pxl_wr_valid,
                      input   pxl_rd_valid,
                      input   posx,
                      input   posy,
                      input   misc_info_dist,
                      input   misc_info_norm,
                      output  ready
                    );


endinterface  //  syn_pxl_xfr_intf
