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
 -- Module Name       : syn_gpu_pxl_gw
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This module converts the pixel, posx & posy values
                        into SRAM data & addresses, which are interfaced
                        to the SRAM_ACC_BUS. This conversion is based on
                        640x480 resolution.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_gpu_pxl_gw (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf           cr_intf,      //Clock Reset Interface

  syn_pxl_xfr_intf                anti_alias_intf,  //Interface from Anti-Alias block

  syn_pxl_xfr_intf                gpu_core_intf,    //Interface from GPU Core

  syn_pxl_xfr_intf                gw2gpu_core_intf, //Interface to GPU Core, for read data

  sram_acc_intf                   sram_intf         //Interface to SRAM

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
  pxl_hsi_t                   pxl_c;
  logic                       pxl_wr_valid_c;
  logic                       pxl_rd_valid_c;
  logic [P_X_W-1:0]           posx_c;
  logic [P_Y_W-1:0]           posy_c;

  logic [P_GPU_SRAM_ADDR_W-7:0]   posy_mul10_c;

  logic                       gpu_core_pxl_pos_valid_c;
  logic                       anti_alias_pxl_pos_valid_c;



//----------------------- Start of Code -----------------------------------

  //Check that the pixel is in valid range
  assign  gpu_core_pxl_pos_valid_c    = (gpu_core_intf.posx   < P_CANVAS_W) & (gpu_core_intf.posy   < P_CANVAS_H);
  assign  anti_alias_pxl_pos_valid_c  = (anti_alias_intf.posx < P_CANVAS_W) & (anti_alias_intf.posy < P_CANVAS_H);

  //Mux between antialias & gpu cores
  always_comb
  begin : antialias_gpu_mux_logic
    if(gpu_core_intf.pxl_wr_valid | gpu_core_intf.pxl_rd_valid) //highest priority
    begin
      pxl_c                   =   gpu_core_intf.pxl;
      pxl_wr_valid_c          =   gpu_core_intf.pxl_wr_valid  & gpu_core_pxl_pos_valid_c;
      pxl_rd_valid_c          =   gpu_core_intf.pxl_rd_valid;
      posx_c                  =   gpu_core_intf.posx;
      posy_c                  =   gpu_core_intf.posy;

      anti_alias_intf.ready   =   1'b0;
      gpu_core_intf.ready     =   sram_intf.gpu_rdy | ~gpu_core_pxl_pos_valid_c;
    end
    else
    begin
      pxl_c                   =   anti_alias_intf.pxl;
      pxl_wr_valid_c          =   anti_alias_intf.pxl_wr_valid  & anti_alias_pxl_pos_valid_c;
      pxl_rd_valid_c          =   anti_alias_intf.pxl_rd_valid;
      posx_c                  =   anti_alias_intf.posx;
      posy_c                  =   anti_alias_intf.posy;

      anti_alias_intf.ready   =   sram_intf.gpu_rdy | ~anti_alias_pxl_pos_valid_c;
      gpu_core_intf.ready     =   1'b0;
    end
  end

  //Interface to SRAM ACC Bus
  always_comb
  begin : sram_acc_bus_intf_logic
    //Pixel addr in SRAM = (posy * 640) + posx
    posy_mul10_c              =   {posy_c,3'd0} + {posy_c,1'b0};

    sram_intf.gpu_addr        =   {posy_mul10_c,6'd0} + posx_c;
    sram_intf.gpu_rd_en       =   pxl_rd_valid_c;
    sram_intf.gpu_wr_en       =   pxl_wr_valid_c;
    sram_intf.gpu_wr_data     =   pxl_c;
  end

  //Send data read from SRAM to GPU Core
  always@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin
    if(~cr_intf.rst_sync_l)
    begin
      gw2gpu_core_intf.posx   <=  0;
      gw2gpu_core_intf.posy   <=  0;
    end
    else
    begin
      if(pxl_rd_valid_c)
      begin
        gw2gpu_core_intf.posx <=  posx_c;
        gw2gpu_core_intf.posy <=  posy_c;
      end
    end
  end

  assign  gw2gpu_core_intf.pxl_rd_valid   = sram_intf.gpu_rd_valid;
  assign  gw2gpu_core_intf.pxl            = sram_intf.gpu_rd_data;
  assign  gw2gpu_core_intf.pxl_wr_valid   = 1'b0;
  assign  gw2gpu_core_intf.misc_info_dist = 0;
  assign  gw2gpu_core_intf.misc_info_norm = 0;

endmodule // syn_gpu_pxl_gw
