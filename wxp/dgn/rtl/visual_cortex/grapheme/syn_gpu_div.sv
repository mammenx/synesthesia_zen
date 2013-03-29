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
 -- Module Name       : syn_gpu_div
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This module implements an 8b/8b divider. Both
                        quotient & remainder are calculated.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_gpu_div (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf           cr_intf,      //Clock Reset Interface

  mulberry_bus_intf               mulbry_bus_intf  //Mulberry bus interface

  //--------------------- Misc Ports (Logic)  -----------

                );

//----------------------- Global parameters Declarations ------------------
  import  syn_global_pkg::*;
  import  syn_gpu_pkg::*;

//----------------------- Input Declarations ------------------------------

//----------------------- Output Declarations -----------------------------

//----------------------- Internal Register Declarations ------------------
  logic [P_16B_W-1:0]         dividend_f;
  logic [P_16B_W-1:0]         divisor_f;
  mid_t                       div_req_mid_f;

//----------------------- Internal Wire Declarations ----------------------
  logic                       div_req_valid_c;
  logic                       rad4_div_rdy_w;
  logic                       rad4_div_load_c;
  logic                       update_rsp_mid_c;

//----------------------- Internal Interface Declarations -----------------


//----------------------- Start of Code -----------------------------------

  //Check for valid MID code
  assign  div_req_valid_c     = (mulbry_bus_intf.div_req_mid  ==  MID_IDLE) ? 1'b0  : 1'b1;

  /*  Main Pipeline */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : main_pipeline_logic
    if(~cr_intf.rst_sync_l)
    begin
      dividend_f              <=  0;
      divisor_f               <=  0;
      div_req_mid_f           <=  MID_IDLE;

      mulbry_bus_intf.div_busy    <=  0;
      mulbry_bus_intf.div_rsp_mid <=  MID_IDLE;
    end
    else
    begin
      //Register mulberry bus signals
      if(div_req_valid_c)
      begin
        dividend_f            <=  mulbry_bus_intf.div_req_data[(P_16B_W*2)-1:P_16B_W];
        divisor_f             <=  mulbry_bus_intf.div_req_data[P_16B_W:0];
        div_req_mid_f         <=  mulbry_bus_intf.div_req_mid;
      end

      if(mulbry_bus_intf.div_busy)  //wait for ready signal for rad4_div
      begin
        mulbry_bus_intf.div_busy  <=  ~rad4_div_rdy_w;
      end
      else  //wait for valid request
      begin
        mulbry_bus_intf.div_busy  <=  div_req_valid_c;
      end

      mulbry_bus_intf.div_rsp_mid <=  update_rsp_mid_c  ? div_req_mid_f : MID_IDLE;
    end
  end

  assign  update_rsp_mid_c    = rad4_div_rdy_w  & mulbry_bus_intf.div_busy;

  //Radix 4 divider module
  divider_rad4  divider_rad4_inst
  (
    .clk        (cr_intf.clk_ir),
    .rst        (~cr_intf.rst_sync_l),
    .load       (rad4_div_load_c),
    .n          (dividend_f),
    .d          (divisor_f),
    .q          (mulbry_bus_intf.div_rsp_data[(2*P_16B_W)-1:P_16B_W]),
    .r          (mulbry_bus_intf.div_rsp_data[P_16B_W-1:0]),
    .ready      (rad4_div_rdy_w)
  );
  defparam  divider_rad4_inst.WIDTH_N = 16;
  defparam  divider_rad4_inst.WIDTH_D = 16;
  

endmodule // syn_gpu_div
