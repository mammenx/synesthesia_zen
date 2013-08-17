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

  syn_pxl_xfr_intf                gpu_core_intf,    //Interface from GPU Core

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

  logic [P_GPU_SRAM_ADDR_W-1:0]   posy_mul10_c;

  logic                       gpu_core_pxl_pos_valid_c;


//----------------------- Start of Code -----------------------------------

  //Check that the pixel is in valid range
  assign  gpu_core_pxl_pos_valid_c    = (gpu_core_intf.posx   < P_CANVAS_W) & (gpu_core_intf.posy   < P_CANVAS_H);

  //Interface to SRAM ACC Bus
  always_comb
  begin : sram_acc_bus_intf_logic
    //Pixel addr in SRAM = (posy * 640) + posx
    posy_mul10_c              =   {gpu_core_intf.posy,3'd0} + {2'd0,gpu_core_intf.posy,1'b0};

    sram_intf.gpu_addr        =   {posy_mul10_c,6'd0} + gpu_core_intf.posx;
    sram_intf.gpu_rd_en       =   gpu_core_intf.pxl_rd_valid;
    //sram_intf.gpu_wr_en       =   gpu_core_intf.pxl_wr_valid  & gpu_core_pxl_pos_valid_c;
    sram_intf.gpu_wr_en       =   gpu_core_intf.pxl_wr_valid;
    sram_intf.gpu_wr_data     =   gpu_core_intf.pxl;
    gpu_core_intf.ready       =   gpu_core_pxl_pos_valid_c  ? sram_intf.gpu_rdy
                                                            : gpu_core_intf.pxl_rd_valid  | gpu_core_intf.pxl_wr_valid;
  end

  //Send data read from SRAM to GPU Core
  always@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin
    if(~cr_intf.rst_sync_l)
    begin
      gpu_core_intf.rd_pxl    <=  '{default:0};
      gpu_core_intf.rd_rdy    <=  0;
    end
    else
    begin
      gpu_core_intf.rd_rdy    <=  sram_intf.gpu_rd_valid;
      gpu_core_intf.rd_pxl    <=  sram_intf.gpu_rd_data;
    end
  end


  /*  For TB Sniffers */
  //synthesis translate_off
  syn_pxl_xfr_tb_intf#(pxl_hsi_t,P_X_W,P_Y_W)  ingr_sniff_intf(cr_intf.clk_ir, cr_intf.rst_sync_l);

  always@(*)
  begin
    ingr_sniff_intf.pxl           = gpu_core_intf.pxl;
    ingr_sniff_intf.pxl_wr_valid  = gpu_core_intf.pxl_wr_valid;
    ingr_sniff_intf.pxl_rd_valid  = gpu_core_intf.pxl_rd_valid;
    ingr_sniff_intf.posx          = gpu_core_intf.posx;
    ingr_sniff_intf.posy          = gpu_core_intf.posy;
    ingr_sniff_intf.rd_rdy        = gpu_core_intf.rd_rdy;
    ingr_sniff_intf.rd_pxl        = gpu_core_intf.rd_pxl;
  end

  //synthesis translate_on

endmodule // syn_gpu_pxl_gw
