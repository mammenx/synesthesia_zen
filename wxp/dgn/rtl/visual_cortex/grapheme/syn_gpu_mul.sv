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
 -- Module Name       : syn_gpu_mul
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This block implements a 16x16 unsigned multiplier
                        connected to the mulberry bus.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_gpu_mul (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf           cr_intf,      //Clock Reset Interface

  mulberry_bus_intf               mulbry_bus_intf  //Mulberry bus interface

  //--------------------- Misc Ports (Logic)  -----------

                );

//----------------------- Global parameters Declarations ------------------
  import  syn_global_pkg::*;
  import  syn_gpu_pkg::*;

  parameter   P_DELAY_VAL   = 8;  //should be non zero
  localparam  P_DELAY_CNTR_W= $clog2(P_DELAY_VAL);

//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------
  mid_t                       reg_mid_f;
  logic [P_16B_W-1:0]         reg_a_f;
  logic [P_16B_W-1:0]         reg_b_f;
  logic [P_DELAY_CNTR_W-1:0]  delay_cntr_f;

//----------------------- Internal Wire Declarations ----------------------
  logic                       mul_req_valid_c;
  logic [P_32B_W-1:0]         mul_res_w;

//----------------------- Internal Interface Declarations -----------------



//----------------------- Start of Code -----------------------------------

  //Check for valid MID code
  assign  mul_req_valid_c     = (mulbry_bus_intf.mul_req_mid  ==  MID_IDLE) ? 1'b0  : 1'b1;

  /*  Main Pipeline */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : main_pipeline_logic
    if(~cr_intf.rst_sync_l)
    begin
      reg_mid_f               <=  MID_IDLE;
      reg_a_f                 <=  0;
      reg_b_f                 <=  0;
      delay_cntr_f            <=  0;

      mulbry_bus_intf.mul_busy        <=  0;
      mulbry_bus_intf.mul_rsp_data    <=  0;
      mulbry_bus_intf.mul_rsp_mid     <=  MID_IDLE;
    end
    else
    begin
      //Register data & MID from mulberry bus
      if(mul_req_valid_c)
      begin
        reg_mid_f             <=  mulbry_bus_intf.mul_req_mid;
        reg_a_f               <=  mulbry_bus_intf.mul_req_data[(2*P_16B_W)-1:P_16B_W];
        reg_b_f               <=  mulbry_bus_intf.mul_req_data[P_16B_W-1:0];
      end

      if(mul_req_valid_c)
      begin
        delay_cntr_f          <=  P_DELAY_VAL;
      end
      else if(mulbry_bus_intf.mul_busy)
      begin
        delay_cntr_f          <=  delay_cntr_f  - 1'b1;
      end

      if(mulbry_bus_intf.mul_busy)  //wait for delay counter to reach zero
      begin
        mulbry_bus_intf.mul_busy    <=  (delay_cntr_f ==  0)  ? 1'b0  : 1'b1;
      end
      else  //wait for valid request
      begin
        mulbry_bus_intf.mul_busy    <=  mul_req_valid_c;
      end

      mulbry_bus_intf.mul_rsp_data  <=  mul_res_w;

      mulbry_bus_intf.mul_rsp_mid   <=  (delay_cntr_f ==  0)  ? reg_mid_f : MID_IDLE;
    end
  end


  //Multiplier block
  mult_16x16_unsigned   mult_16x16_unsigned_inst
  (
	  .dataa              (reg_a_f),
	  .datab              (reg_b_f),
	  .result             (mul_res_w)
  );

endmodule // syn_gpu_mul
