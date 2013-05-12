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
 -- Interface Name    : mulberry_bus_intf
 -- Author            : mammenx
 -- Function          : This block encapsulates all the signals & logic
                        related to the mulberry bus.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

interface mulberry_bus_intf  #(parameter  P_BUS_DATA_W=32)  (input logic  clk_ir, rst_il);

  import  syn_gpu_pkg::*;

  //Logic signals
  logic                     gpu_lb_req_rdy;
  sid_t                     gpu_lb_sid;
  logic [P_BUS_DATA_W-1:0]  gpu_lb_req_data;
  logic                     gpu_lb_res_valid;
  logic [P_BUS_DATA_W-1:0]  gpu_lb_res;

  logic                     gpu_core_req_rdy;
  sid_t                     gpu_core_sid;
  logic [P_BUS_DATA_W-1:0]  gpu_core_req_data;
  logic                     gpu_core_res_valid;
  logic [P_BUS_DATA_W-1:0]  gpu_core_res;

  logic                     anti_alias_req_rdy;
  sid_t                     anti_alias_sid;
  logic [P_BUS_DATA_W-1:0]  anti_alias_req_data;
  logic                     anti_alias_res_valid;
  logic [P_BUS_DATA_W-1:0]  anti_alias_res;

  logic                     rand_busy;
  logic [P_BUS_DATA_W-1:0]  rand_req_data;
  mid_t                     rand_req_mid;
  logic [P_BUS_DATA_W-1:0]  rand_rsp_data;
  mid_t                     rand_rsp_mid;

  logic                     div_busy;
  logic [P_BUS_DATA_W-1:0]  div_req_data;
  mid_t                     div_req_mid;
  logic [P_BUS_DATA_W-1:0]  div_rsp_data;
  mid_t                     div_rsp_mid;

  logic                     mul_busy;
  logic [P_BUS_DATA_W-1:0]  mul_req_data;
  mid_t                     mul_req_mid;
  logic [P_BUS_DATA_W-1:0]  mul_rsp_data;
  mid_t                     mul_rsp_mid;


  //Modports
  modport gpu_lb_mp  (
                    input   gpu_lb_req_rdy,
                    output  gpu_lb_sid,
                    output  gpu_lb_req_data,
                    input   gpu_lb_res_valid,
                    input   gpu_lb_res
                  );

  modport gpu_core_mp  (
                    input   gpu_core_req_rdy,
                    output  gpu_core_sid,
                    output  gpu_core_req_data,
                    input   gpu_core_res_valid,
                    input   gpu_core_res
                  );

  modport anti_alias_mp  (
                    input   anti_alias_req_rdy,
                    output  anti_alias_sid,
                    output  anti_alias_req_data,
                    input   anti_alias_res_valid,
                    input   anti_alias_res
                  );

  modport rand_mp  (
                  output  rand_busy,
                  input   rand_req_data,
                  input   rand_req_mid,
                  output  rand_rsp_data,
                  output  rand_rsp_mid
                );

  modport mul_mp  (
                  output  mul_busy,
                  input   mul_req_data,
                  input   mul_req_mid,
                  output  mul_rsp_data,
                  output  mul_rsp_mid
                );

  modport div_mp  (
                  output  div_busy,
                  input   div_req_data,
                  input   div_req_mid,
                  output  div_rsp_data,
                  output  div_rsp_mid
                );

  /*
    * Arbitration Logic
    * Based on logic that most probable sources of requests get least priority
    * Recomended that each master issue requests in pulses to prevent GPU pipe race
    * GPU_LB >  GPU_CORE  > ANTI_ALIAS
  */

  logic gpu_lb_req_rdy_c;
  logic gpu_core_req_rdy_c;
  logic anti_alias_req_rdy_c;

  logic rand_rsp_rdy_c;
  logic div_rsp_rdy_c;
  logic mul_rsp_rdy_c;

  mid_t                     curr_master_c;
  sid_t                     target_slave_c;
  logic                     target_slave_busy_c;
  logic [P_BUS_DATA_W-1:0]  target_slave_req_data_c;

  mid_t                     rsp_master_c;
  logic [P_BUS_DATA_W-1:0]  rsp_data_c;
  logic [P_BUS_DATA_W-1:0]  rsp_data_f;

  //Check if the masters have placed a valid transaction on the bus
  assign  gpu_lb_req_rdy_c      = (gpu_lb_sid ==  SID_IDLE)     ? 1'b0  : 1'b1;
  assign  gpu_core_req_rdy_c    = (gpu_core_sid ==  SID_IDLE)   ? 1'b0  : 1'b1;
  assign  anti_alias_req_rdy_c  = (anti_alias_sid ==  SID_IDLE) ? 1'b0  : 1'b1;

  //Select the master that has access on the bus now
  //Need to modify this so that in case a master tries to access a slave that
  //is busy, then priority will be given to the next master etc.
  always_comb
  begin : current_master_select_logic
    if(gpu_lb_req_rdy_c)
    begin
      curr_master_c = MID_GPU_LB;
    end
    else if(gpu_core_req_rdy_c)
    begin
      curr_master_c = MID_GPU_CORE;
    end
    else if(anti_alias_req_rdy_c)
    begin
      curr_master_c = MID_ANTI_ALIAS;
    end
    else
    begin
      curr_master_c = MID_IDLE;
    end
  end

  //Select target slave based on master priority & slave busy status
  always_comb
  begin : target_slave_select_logic
    unique  case(curr_master_c)

      MID_IDLE        : target_slave_c  = SID_IDLE;
      MID_GPU_LB      : target_slave_c  = gpu_lb_sid;
      MID_GPU_CORE    : target_slave_c  = gpu_core_sid;
      MID_ANTI_ALIAS  : target_slave_c  = anti_alias_sid;

    endcase
  end

  //Check if the target slave is busy or not
  always_comb
  begin : target_slave_busy_chk_logic
    unique  case(target_slave_c)

      SID_IDLE  : target_slave_busy_c = 1'b0;
      SID_RAND  : target_slave_busy_c = rand_busy;
      SID_MUL   : target_slave_busy_c = mul_busy;
      SID_DIV   : target_slave_busy_c = div_busy;

    endcase
  end

  //Select the request data to be sent to target slave
  always_comb
  begin : target_req_data_select_logic
    unique  case(curr_master_c)

      MID_IDLE        : target_slave_req_data_c = {P_BUS_DATA_W{1'b0}};
      MID_GPU_LB      : target_slave_req_data_c = gpu_lb_req_data;
      MID_GPU_CORE    : target_slave_req_data_c = gpu_core_req_data;
      MID_ANTI_ALIAS  : target_slave_req_data_c = anti_alias_req_data;

    endcase
  end

  //Check if the slave responses are ready
  assign  rand_rsp_rdy_c = (rand_rsp_mid ==  MID_IDLE) ? 1'b0  : 1'b1;
  assign  div_rsp_rdy_c  = (div_rsp_mid  ==  MID_IDLE) ? 1'b0  : 1'b1;
  assign  mul_rsp_rdy_c  = (mul_rsp_mid  ==  MID_IDLE) ? 1'b0  : 1'b1;

  //Mux the target response data & master
  always_comb
  begin : rsp_mid_data_mux_logic
    rsp_master_c  = MID_IDLE;
    rsp_data_c    = {P_BUS_DATA_W{1'b0}};

    case(1'b1)

      rand_rsp_rdy_c  :
      begin
        rsp_master_c  = rand_rsp_mid;
        rsp_data_c    = rand_rsp_data;
      end

      div_rsp_rdy_c  :
      begin
        rsp_master_c  = div_rsp_mid;
        rsp_data_c    = div_rsp_data;
      end

      mul_rsp_rdy_c  :
      begin
        rsp_master_c  = mul_rsp_mid;
        rsp_data_c    = mul_rsp_data;
      end

      default :
      begin
        rsp_master_c  = MID_IDLE;
        rsp_data_c    = 0;
      end

    endcase
  end

  //Give slave busy feedback to current master
  assign  gpu_lb_req_rdy      = (curr_master_c  ==  MID_GPU_LB)     ? ~target_slave_busy_c  : 1'b0;
  assign  gpu_core_req_rdy    = (curr_master_c  ==  MID_GPU_CORE)   ? ~target_slave_busy_c  : 1'b0;
  assign  anti_alias_req_rdy  = (curr_master_c  ==  MID_ANTI_ALIAS) ? ~target_slave_busy_c  : 1'b0;

  //Assign MID & request data to slaves
  assign  rand_req_data = target_slave_req_data_c;
  assign  rand_req_mid  = (target_slave_c ==  SID_RAND) ? curr_master_c : MID_IDLE;

  assign  mul_req_data  = target_slave_req_data_c;
  assign  mul_req_mid   = (target_slave_c ==  SID_MUL)  ? curr_master_c : MID_IDLE;

  assign  div_req_data  = target_slave_req_data_c;
  assign  div_req_mid   = (target_slave_c ==  SID_DIV)  ? curr_master_c : MID_IDLE;

  //Route the responses back to the correct master
  always_ff@(posedge clk_ir, negedge  rst_il)
  begin : fsm_seq_logic
    if(~rst_il)
    begin
      gpu_lb_res_valid        <=  0;
      gpu_core_res_valid      <=  0;
      anti_alias_res_valid    <=  0;

      rsp_data_f              <=  0;
    end
    else
    begin
      gpu_lb_res_valid        <= (rsp_master_c ==  MID_GPU_LB)     ? 1'b1  : 1'b0;
      gpu_core_res_valid      <= (rsp_master_c ==  MID_GPU_CORE)   ? 1'b1  : 1'b0;
      anti_alias_res_valid    <= (rsp_master_c ==  MID_ANTI_ALIAS) ? 1'b1  : 1'b0;

      rsp_data_f              <=  rsp_data_c;
    end
  end

  assign  gpu_lb_res          = rsp_data_f;
  assign  gpu_core_res        = rsp_data_f;
  assign  anti_alias_res      = rsp_data_f;

endinterface  //  mulberry_bus_intf
