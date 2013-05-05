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
 -- Module Name       : syn_gpu_core
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This module contains the core GPU logic blocks.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_gpu_core (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf           cr_intf,      //Clock Reset Interface

  syn_lb_intf                     lb_intf,    //DATA_W=32, ADDR_W=8

  mulberry_bus_intf               mul_bus_intf,

  syn_pxl_xfr_intf                anti_alias_intf,

  syn_pxl_xfr_intf                pxl_gw_tx_intf,

  syn_pxl_xfr_intf                pxl_gw_rx_intf

  //--------------------- Misc Ports (Logic)  -----------

                );

//----------------------- Global parameters Declarations ------------------
  import  syn_global_pkg::*;
  import  syn_gpu_pkg::*;

  `include  "syn_vcortex_reg_map.sv"

//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------
  logic                       gpu_en_f;
  action_t                    gpu_job_action_f; //same as GPU_JPB_BFFR_0
  logic [P_16B_W-1:0]         gpu_job_bffr_1_f;
  logic [P_16B_W-1:0]         gpu_job_bffr_2_f;
  logic [P_16B_W-1:0]         gpu_job_bffr_3_f;
  logic [P_16B_W-1:0]         gpu_job_bffr_4_f;
  logic [P_16B_W-1:0]         gpu_job_bffr_5_f;
  logic [P_16B_W-1:0]         gpu_job_bffr_6_f;
  logic [P_16B_W-1:0]         gpu_job_bffr_7_f;

  logic                       gpu_job_start_f;

//----------------------- Internal Wire Declarations ----------------------


//----------------------- Internal Interface Declarations -----------------
  syn_gpu_core_job_intf       gpu_job_intf(cr_intf.clk_ir, cr_intf.rst_sync_l);
  syn_pxl_xfr_intf            euclid_anti_alias_intf(cr_intf.clk_ir, cr_intf.rst_sync_l);

//----------------------- Start of Code -----------------------------------

  /*  Local Bus logic */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : lb_logic
    if(~cr_intf.rst_sync_l)
    begin
      gpu_en_f                <=  0;
      gpu_job_action_f        <=  DRAW;
      gpu_job_bffr_1_f        <=  0;
      gpu_job_bffr_2_f        <=  0;
      gpu_job_bffr_3_f        <=  0;
      gpu_job_bffr_4_f        <=  0;
      gpu_job_bffr_5_f        <=  0;
      gpu_job_bffr_6_f        <=  0;
      gpu_job_bffr_7_f        <=  0;

      gpu_job_start_f         <=  0;

      lb_intf.wr_valid        <=  0;
      lb_intf.rd_valid        <=  0;
      lb_intf.rd_data         <=  0;
    end
    else
    begin
      //Write logic
      if(lb_intf.wr_en)
      begin
        unique  case(lb_intf.addr)

          VCORTEX_GPU_CONTROL_REG_ADDR    : gpu_en_f          <=  lb_intf.wr_data[0];
          VCORTEX_GPU_JOB_BFFR_0_REG_ADDR : gpu_job_action_f  <=  action_t'(lb_intf.wr_data[1:0]);
          VCORTEX_GPU_JOB_BFFR_1_REG_ADDR : gpu_job_bffr_1_f  <=  lb_intf.wr_data[P_16B_W-1:0];
          VCORTEX_GPU_JOB_BFFR_2_REG_ADDR : gpu_job_bffr_2_f  <=  lb_intf.wr_data[P_16B_W-1:0];
          VCORTEX_GPU_JOB_BFFR_3_REG_ADDR : gpu_job_bffr_3_f  <=  lb_intf.wr_data[P_16B_W-1:0];
          VCORTEX_GPU_JOB_BFFR_4_REG_ADDR : gpu_job_bffr_4_f  <=  lb_intf.wr_data[P_16B_W-1:0];
          VCORTEX_GPU_JOB_BFFR_5_REG_ADDR : gpu_job_bffr_5_f  <=  lb_intf.wr_data[P_16B_W-1:0];
          VCORTEX_GPU_JOB_BFFR_6_REG_ADDR : gpu_job_bffr_6_f  <=  lb_intf.wr_data[P_16B_W-1:0];
          VCORTEX_GPU_JOB_BFFR_7_REG_ADDR : gpu_job_bffr_7_f  <=  lb_intf.wr_data[P_16B_W-1:0];

        endcase
      end

      lb_intf.wr_valid        <=  lb_intf.wr_en;

      gpu_job_start_f         <=  (lb_intf.addr ==  VCORTEX_GPU_JOB_BFFR_0_REG_ADDR)  ? lb_intf.wr_en
                                                                                      : 1'b0;

      //Read Logic
      if(lb_intf.rd_en)
      begin
        case(lb_intf.addr)

          VCORTEX_GPU_CONTROL_REG_ADDR    : lb_intf.rd_data <=  {{P_32B_W-1{1'b0}},gpu_en_f};
          VCORTEX_GPU_STATUS_REG_ADDR     : lb_intf.rd_data <=  {{P_32B_W-1{1'b0}},gpu_job_intf.euclid_busy};
          VCORTEX_GPU_JOB_BFFR_0_REG_ADDR : lb_intf.rd_data <=  {{P_32B_W-2{1'b0}},gpu_job_action_f};
          VCORTEX_GPU_JOB_BFFR_1_REG_ADDR : lb_intf.rd_data <=  {{P_16B_W{1'b0}},gpu_job_bffr_1_f};
          VCORTEX_GPU_JOB_BFFR_2_REG_ADDR : lb_intf.rd_data <=  {{P_16B_W{1'b0}},gpu_job_bffr_2_f};
          VCORTEX_GPU_JOB_BFFR_3_REG_ADDR : lb_intf.rd_data <=  {{P_16B_W{1'b0}},gpu_job_bffr_3_f};
          VCORTEX_GPU_JOB_BFFR_4_REG_ADDR : lb_intf.rd_data <=  {{P_16B_W{1'b0}},gpu_job_bffr_4_f};
          VCORTEX_GPU_JOB_BFFR_5_REG_ADDR : lb_intf.rd_data <=  {{P_16B_W{1'b0}},gpu_job_bffr_5_f};
          VCORTEX_GPU_JOB_BFFR_6_REG_ADDR : lb_intf.rd_data <=  {{P_16B_W{1'b0}},gpu_job_bffr_6_f};
          VCORTEX_GPU_JOB_BFFR_7_REG_ADDR : lb_intf.rd_data <=  {{P_16B_W{1'b0}},gpu_job_bffr_7_f};

          default : lb_intf.rd_data       <=  32'hdeadbabe;

        endcase
      end

      lb_intf.rd_valid        <=  lb_intf.rd_en;
    end
  end

  /*  Mapping Job interface components to LB registers  */
  assign  gpu_job_intf.euclid_job_start         = (gpu_job_action_f ==  DRAW) ? gpu_job_start_f : 1'b0;
  assign  gpu_job_intf.euclid_job_data.shape    = shape_t'(gpu_job_bffr_1_f[1:0]);
  assign  gpu_job_intf.euclid_job_data.x0       = gpu_job_bffr_2_f[P_X_W-1:0];
  assign  gpu_job_intf.euclid_job_data.y0       = gpu_job_bffr_3_f[P_Y_W-1:0];
  assign  gpu_job_intf.euclid_job_data.x1       = gpu_job_bffr_4_f[P_X_W-1:0];
  assign  gpu_job_intf.euclid_job_data.y1       = gpu_job_bffr_5_f[P_Y_W-1:0];
  assign  gpu_job_intf.euclid_job_data.color    = gpu_job_bffr_6_f[(P_LUM_W + P_CHRM_W + P_CHRM_W)-1:0];
  assign  gpu_job_intf.euclid_job_data.width    = gpu_job_bffr_7_f[3:0];


  /*  Instantiating Sub Modules */
  syn_gpu_core_euclid   syn_gpu_core_euclid_inst
  (

    .cr_intf            (cr_intf),

    .job_intf           (gpu_job_intf.euclid),

    .alias_intf         (euclid_anti_alias_intf.master)

  );


  /*  Muxing Anti-Alias, Pixel GW interfaces between the engine selected  */
  always_comb
  begin : engine_mux_logic
    if(gpu_job_action_f ==  DRAW)
    begin
      anti_alias_intf.pxl             =  euclid_anti_alias_intf.pxl;
      anti_alias_intf.pxl_wr_valid    =  euclid_anti_alias_intf.pxl_wr_valid;
      anti_alias_intf.pxl_rd_valid    =  euclid_anti_alias_intf.pxl_rd_valid;
      anti_alias_intf.posx            =  euclid_anti_alias_intf.posx;
      anti_alias_intf.posy            =  euclid_anti_alias_intf.posy;
      anti_alias_intf.misc_info_dist  =  euclid_anti_alias_intf.misc_info_dist;
      anti_alias_intf.misc_info_norm  =  euclid_anti_alias_intf.misc_info_norm;
      euclid_anti_alias_intf.ready    =  anti_alias_intf.ready;
    end
    else
    begin
      anti_alias_intf.pxl             =  0;
      anti_alias_intf.pxl_wr_valid    =  0;
      anti_alias_intf.pxl_rd_valid    =  0;
      anti_alias_intf.posx            =  0;
      anti_alias_intf.posy            =  0;
      anti_alias_intf.misc_info_dist  =  0;
      anti_alias_intf.misc_info_norm  =  0;
      euclid_anti_alias_intf.ready    =  0;

    end
  end

  assign  pxl_gw_tx_intf.pxl              =  0;
  assign  pxl_gw_tx_intf.pxl_wr_valid     =  0;
  assign  pxl_gw_tx_intf.pxl_rd_valid     =  0;
  assign  pxl_gw_tx_intf.posx             =  0;
  assign  pxl_gw_tx_intf.posy             =  0;
  assign  pxl_gw_tx_intf.misc_info_dist   =  0;
  assign  pxl_gw_tx_intf.misc_info_norm   =  0;

  assign  pxl_gw_rx_intf.ready            =  0;

  assign  mul_bus_intf.gpu_core_sid       = SID_IDLE;
  assign  mul_bus_intf.gpu_core_req_data  = 0;

endmodule // syn_gpu_core
