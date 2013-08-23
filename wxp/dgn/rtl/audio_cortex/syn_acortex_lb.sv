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
 -- Module Name       : syn_acortex_lb
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This block decodes addresses to the various
                        sub blocks of ACORTEX.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_acortex_lb (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf           cr_intf,      //Clock Reset Interface

  syn_lb_intf                     lb_intf,        //data=32, addr=12

  syn_acortex_lb_bus_intf         acortex_lb_intf //data=32, addr=8

  //--------------------- Misc Ports (Logic)  -----------

                );

//----------------------- Global parameters Declarations ------------------
  `include  "syn_acortex_reg_map.sv"

  parameter   P_LB_DATA_W           = P_32B_W;
  parameter   P_LB_ADDR_W           = P_12B_W;

  parameter   P_ACORTEX_LB_DATA_W   = P_32B_W;
  parameter   P_ACORTEX_LB_ADDR_W   = P_8B_W;
  localparam  P_BLK_CODE_W          = P_LB_ADDR_W - P_ACORTEX_LB_ADDR_W;


//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------


//----------------------- Internal Wire Declarations ----------------------
  logic [P_BLK_CODE_W-1:0]    blk_code_w;

//----------------------- Internal Interface Declarations -----------------



//----------------------- Start of Code -----------------------------------

  //Extract the block code from the LB address
  assign  blk_code_w  = lb_intf.addr[P_LB_ADDR_W-1  -:  P_BLK_CODE_W];

  //Generate the Read/Write enables for each sub-block
  assign  acortex_lb_intf.i2cm_wr_en    = (blk_code_w ==  ACORTEX_I2CM_CODE)    ? lb_intf.wr_en : 1'b0;
  assign  acortex_lb_intf.i2cm_rd_en    = (blk_code_w ==  ACORTEX_I2CM_CODE)    ? lb_intf.rd_en : 1'b0;

  assign  acortex_lb_intf.cmux_wr_en    = (blk_code_w ==  ACORTEX_CMUX_CODE)    ? lb_intf.wr_en : 1'b0;
  assign  acortex_lb_intf.cmux_rd_en    = (blk_code_w ==  ACORTEX_CMUX_CODE)    ? lb_intf.rd_en : 1'b0;

  assign  acortex_lb_intf.wmdrvr_wr_en  = (blk_code_w ==  ACORTEX_WMDRVR_CODE)  ? lb_intf.wr_en : 1'b0;
  assign  acortex_lb_intf.wmdrvr_rd_en  = (blk_code_w ==  ACORTEX_WMDRVR_CODE)  ? lb_intf.rd_en : 1'b0;

  assign  acortex_lb_intf.acache_wr_en  = (blk_code_w ==  ACORTEX_ACACHE_CODE)  ? lb_intf.wr_en : 1'b0;
  assign  acortex_lb_intf.acache_rd_en  = (blk_code_w ==  ACORTEX_ACACHE_CODE)  ? lb_intf.rd_en : 1'b0;

  //Assign data & address
  assign  acortex_lb_intf.lbm_addr      = lb_intf.addr[P_ACORTEX_LB_ADDR_W-1:0];
  assign  acortex_lb_intf.lbm_wr_data   = lb_intf.wr_data;


  //Responses
  assign  lb_intf.wr_valid    =   acortex_lb_intf.lbm_wr_valid;
  assign  lb_intf.rd_valid    =   acortex_lb_intf.lbm_rd_valid;
  assign  lb_intf.rd_data     =   acortex_lb_intf.lbm_rd_data;

endmodule // syn_acortex_lb
