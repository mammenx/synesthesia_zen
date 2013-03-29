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
 -- Module Name       : syn_gpu_rand
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This block contains an pseudo-random number
                        generator connected to the mulberry bus. The
                        algorithm used is PRBS31.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_gpu_rand (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf           cr_intf,      //Clock Reset Interface

  mulberry_bus_intf               mulbry_bus_intf  //Mulberry bus interface


  //--------------------- Misc Ports (Logic)  -----------

                );

//----------------------- Global parameters Declarations ------------------
  import  syn_global_pkg::*;
  import  syn_gpu_pkg::*;

  parameter   P_PRBS_W      = 31;
  parameter   P_DELAY_VAL   = 8;  //should be non zero
  localparam  P_DELAY_CNTR_W= $clog2(P_DELAY_VAL);

//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------
  logic [P_PRBS_W-1:0]        prbs_f;
  logic [P_DELAY_CNTR_W-1:0]  delay_cntr_f;
  mid_t                       rand_req_mid_f;

//----------------------- Internal Wire Declarations ----------------------
  logic                       rand_req_valid_c;
  logic                       rst_prbs_c;
  logic                       update_rand_rsp_c;

//----------------------- Internal Interface Declarations -----------------



//----------------------- Start of Code -----------------------------------

  //Check for valid MID code
  assign  rand_req_valid_c    = (mulbry_bus_intf.rand_req_mid  ==  MID_IDLE) ? 1'b0  : 1'b1;

  //PRBS should never be stuck at zero
  assign  rst_prbs_c          = (prbs_f ==  0)  ? 1'b1  : 1'b0;

  /*  Main Pipeline */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : main_pipeline_logic
    if(~cr_intf.rst_sync_l)
    begin
      prbs_f                  <=  {P_PRBS_W{1'b1}};
      delay_cntr_f            <=  0;
      rand_req_mid_f          <=  MID_IDLE;

      mulbry_bus_intf.rand_busy     <=  0;
      mulbry_bus_intf.rand_rsp_mid  <=  MID_IDLE;
    end
    else
    begin
      //Register valid MID
      if(rand_req_valid_c)
      begin
        rand_req_mid_f        <=  mulbry_bus_intf.rand_req_mid;
      end

      if(rand_req_valid_c)
      begin
        delay_cntr_f          <=  P_DELAY_VAL;
      end
      else if(mulbry_bus_intf.rand_busy)
      begin
        delay_cntr_f          <=  delay_cntr_f  - 1'b1;
      end

      if(rst_prbs_c)
      begin
        prbs_f                <=  {P_PRBS_W{1'b1}};
      end
      else if(rand_req_valid_c)
      begin
        prbs_f                <=  {prbs_f[29:0],(prbs_f[30]^prbs_f[27])};
      end

      if(mulbry_bus_intf.rand_busy)  //wait for delay counter to reach zero
      begin
        mulbry_bus_intf.rand_busy    <=  (delay_cntr_f ==  0)  ? 1'b0  : 1'b1;
      end
      else  //wait for valid request
      begin
        mulbry_bus_intf.rand_busy    <=  rand_req_valid_c;
      end

      mulbry_bus_intf.rand_rsp_mid  <=  update_rand_rsp_c ? rand_req_mid_f
                                                          : MID_IDLE;
    end
  end

  assign  update_rand_rsp_c   = (delay_cntr_f ==  0)  ? mulbry_bus_intf.rand_busy : 1'b0;

  assign  mulbry_bus_intf.rand_rsp_data = {1'b0,prbs_f};

endmodule // syn_gpu_rand
