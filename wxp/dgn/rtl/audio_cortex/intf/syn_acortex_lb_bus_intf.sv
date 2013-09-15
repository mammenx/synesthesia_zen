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
 -- Interface Name    : syn_acortex_lb_bus_intf
 -- Author            : mammenx
 -- Function          : This interface holds the fabric for ACORTEX Local
                        Bus.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

interface syn_acortex_lb_bus_intf #(
                                    parameter LB_ADDR_W         = 8,
                                    parameter LB_MASTER_DATA_W  = 32,
                                    parameter I2C_MASTER_DATA_W = 16,
                                    parameter CLK_MUX_DATA_W    = 16,
                                    parameter WM8731_DRVR_DATA_W= 16,
                                    parameter AUDIO_CACHE_DATA_W= 32
                                  )

                                  (input logic clk_ir, rst_il);

  //LB Master
  logic [LB_ADDR_W-1:0]         lbm_addr;
  logic                         lbm_wr_valid;
  logic [LB_MASTER_DATA_W-1:0]  lbm_wr_data;
  logic                         lbm_rd_valid;
  logic [LB_MASTER_DATA_W-1:0]  lbm_rd_data;


  //I2C Master
  logic                         i2cm_rd_en;
  logic                         i2cm_wr_en;
  logic [LB_ADDR_W-1:0]         i2cm_addr;
  logic                         i2cm_wr_valid;
  logic [I2C_MASTER_DATA_W-1:0] i2cm_wr_data;
  logic                         i2cm_rd_valid;
  logic [I2C_MASTER_DATA_W-1:0] i2cm_rd_data;


  //Clock Mux
  logic                         cmux_rd_en;
  logic                         cmux_wr_en;
  logic [LB_ADDR_W-1:0]         cmux_addr;
  logic                         cmux_wr_valid;
  logic [CLK_MUX_DATA_W-1:0]    cmux_wr_data;
  logic                         cmux_rd_valid;
  logic [CLK_MUX_DATA_W-1:0]    cmux_rd_data;


  //WM8731 Driver
  logic                         wmdrvr_rd_en;
  logic                         wmdrvr_wr_en;
  logic [LB_ADDR_W-1:0]         wmdrvr_addr;
  logic                         wmdrvr_wr_valid;
  logic [WM8731_DRVR_DATA_W-1:0]wmdrvr_wr_data;
  logic                         wmdrvr_rd_valid;
  logic [WM8731_DRVR_DATA_W-1:0]wmdrvr_rd_data;

  //Audio Cache
  logic                         acache_rd_en;
  logic                         acache_wr_en;
  logic [LB_ADDR_W-1:0]         acache_addr;
  logic                         acache_wr_valid;
  logic [AUDIO_CACHE_DATA_W-1:0]acache_wr_data;
  logic                         acache_rd_valid;
  logic [AUDIO_CACHE_DATA_W-1:0]acache_rd_data;


  //Modports
  modport lbm     (
                    output  i2cm_wr_en,
                    output  i2cm_rd_en,
                    output  cmux_wr_en,
                    output  cmux_rd_en,
                    output  wmdrvr_wr_en,
                    output  wmdrvr_rd_en,
                    output  acache_wr_en,
                    output  acache_rd_en,
                    output  lbm_addr,
                    output  lbm_wr_data,

                    input   lbm_wr_valid,
                    input   lbm_rd_valid,
                    input   lbm_rd_data
                  );

  modport i2cm    (
                    input   i2cm_rd_en,
                    input   i2cm_wr_en,
                    input   i2cm_addr,
                    input   i2cm_wr_data,

                    output  i2cm_wr_valid,
                    output  i2cm_rd_valid,
                    output  i2cm_rd_data
                  );

  modport cmux    (
                    input   cmux_rd_en,
                    input   cmux_wr_en,
                    input   cmux_addr,
                    input   cmux_wr_data,

                    output  cmux_wr_valid,
                    output  cmux_rd_valid,
                    output  cmux_rd_data
                  );

  modport wmdrvr  (
                    input   wmdrvr_rd_en,
                    input   wmdrvr_wr_en,
                    input   wmdrvr_addr,
                    input   wmdrvr_wr_data,

                    output  wmdrvr_wr_valid,
                    output  wmdrvr_rd_valid,
                    output  wmdrvr_rd_data
                  );

  modport acache  (
                    input   acache_rd_en,
                    input   acache_wr_en,
                    input   acache_addr,
                    input   acache_wr_data,

                    output  acache_wr_valid,
                    output  acache_rd_valid,
                    output  acache_rd_data
                  );


  /*  Misc logic  */
  assign  i2cm_addr   = lbm_addr;
  assign  cmux_addr   = lbm_addr;
  assign  wmdrvr_addr = lbm_addr;
  assign  acache_addr = lbm_addr;

  assign  i2cm_wr_data    = lbm_wr_data[I2C_MASTER_DATA_W-1:0];
  assign  cmux_wr_data    = lbm_wr_data[CLK_MUX_DATA_W-1:0];
  assign  wmdrvr_wr_data  = lbm_wr_data[WM8731_DRVR_DATA_W-1:0];
  assign  acache_wr_data  = lbm_wr_data[AUDIO_CACHE_DATA_W-1:0];

  assign  lbm_wr_valid    = i2cm_wr_valid | cmux_wr_valid | wmdrvr_wr_valid | acache_wr_valid;
  assign  lbm_rd_valid    = i2cm_rd_valid | cmux_rd_valid | wmdrvr_rd_valid | acache_rd_valid;

  always_comb
  begin : acortex_lb_rd_data_mux_logic
    if(i2cm_rd_valid)
    begin
      lbm_rd_data = {{LB_MASTER_DATA_W-I2C_MASTER_DATA_W{1'b0}},  i2cm_rd_data};
    end
    else if(cmux_rd_valid)
    begin
      lbm_rd_data = {{LB_MASTER_DATA_W-CLK_MUX_DATA_W{1'b0}},     cmux_rd_data};
    end
    else if(wmdrvr_rd_valid)
    begin
      lbm_rd_data = {{LB_MASTER_DATA_W-WM8731_DRVR_DATA_W{1'b0}}, wmdrvr_rd_data};
    end
    else  //acache_rd_valid
    begin
      //lbm_rd_data = {{LB_MASTER_DATA_W-AUDIO_CACHE_DATA_W{1'b0}}, acache_rd_data};
      lbm_rd_data[AUDIO_CACHE_DATA_W-1:0] = acache_rd_data;
    end
  end

endinterface  //  syn_acortex_lb_bus_intf
