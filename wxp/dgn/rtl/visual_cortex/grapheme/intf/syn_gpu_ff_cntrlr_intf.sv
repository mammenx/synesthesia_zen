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
 -- Interface Name    : syn_gpu_ff_cntrlr_intf
 -- Author            : mammenx
 -- Function          : This defines the set of signals for interfacing to
                        the GPU FF Controller module.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

interface syn_gpu_ff_cntrlr_intf  #(
                                      parameter WIDTHX  = syn_gpu_pkg::P_X_W,
                                      parameter WIDTHY  = syn_gpu_pkg::P_Y_W
                                  )

                                  (input logic clk_ir,rst_il);

  import  syn_gpu_pkg::point_t;

  //Logic signals
  logic               wr_en;
  logic               rd_en;
  logic               empty;
  logic               full;
  point_t             waddr;
  point_t             raddr;

  //Modports
  modport cntrlr  (
                    input   wr_en,
                    input   rd_en,
                    output  empty,
                    output  full,
                    output  waddr,
                    output  raddr
                  );

  modport master  (
                    output  wr_en,
                    output  rd_en,
                    input   empty,
                    input   full,
                    input   waddr,
                    input   raddr
                  );


endinterface  //  syn_gpu_ff_cntrlr_intf
