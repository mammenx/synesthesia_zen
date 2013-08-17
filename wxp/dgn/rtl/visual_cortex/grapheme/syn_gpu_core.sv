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

  mulberry_bus_intf               mul_bus_gpu_intf,

  mulberry_bus_intf               mul_bus_lb_intf,

  syn_pxl_xfr_intf                pxl_gw_intf

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
  logic [P_16B_W-1:0]         gpu_job_bffr_8_f;
  logic [P_16B_W-1:0]         gpu_job_bffr_9_f;

  logic                       gpu_job_start_f;
  logic                       host_acc_rd_job_start_f;
  logic                       host_acc_wr_job_start_f;
  logic                       host_acc_done_f;
  logic                       host_mul_job_done_f;

//----------------------- Internal Wire Declarations ----------------------
  host_acc_job_t              host_acc_job_w;

  sid_t                       decoded_sid_c;

//----------------------- Internal Interface Declarations -----------------
  syn_gpu_core_job_intf       gpu_job_intf(cr_intf.clk_ir, cr_intf.rst_sync_l);
  syn_pxl_xfr_intf            euclid_pxlgw_intf(cr_intf.clk_ir, cr_intf.rst_sync_l);
  syn_pxl_xfr_intf            picasso_pxlgw_intf(cr_intf.clk_ir, cr_intf.rst_sync_l);
  syn_gpu_ff_cntrlr_intf      gpu_ff_intf(cr_intf.clk_ir, cr_intf.rst_sync_l);

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
      gpu_job_bffr_8_f        <=  0;
      gpu_job_bffr_9_f        <=  0;

      gpu_job_start_f         <=  0;
      host_acc_rd_job_start_f <=  0;
      host_acc_wr_job_start_f <=  0;

      lb_intf.wr_valid        <=  0;
      lb_intf.rd_valid        <=  0;
      lb_intf.rd_data         <=  0;

      host_acc_done_f         <=  1;
      host_mul_job_done_f     <=  1;
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
          VCORTEX_GPU_JOB_BFFR_8_REG_ADDR : gpu_job_bffr_8_f  <=  lb_intf.wr_data[P_16B_W-1:0];
          VCORTEX_GPU_JOB_BFFR_9_REG_ADDR : gpu_job_bffr_9_f  <=  lb_intf.wr_data[P_16B_W-1:0];

        endcase
      end
      else
      begin
        if(gpu_job_action_f ==  DEBUG)
        begin
          gpu_job_bffr_4_f    <=  pxl_gw_intf.rd_rdy  ? pxl_gw_intf.rd_pxl  : gpu_job_bffr_4_f;
        end

        if(gpu_job_action_f  ==  MULBRY)
        begin
          gpu_job_bffr_2_f    <=  mul_bus_lb_intf.gpu_lb_res_valid  ? mul_bus_lb_intf.gpu_lb_res[P_16B_W-1:0] : gpu_job_bffr_2_f;
          gpu_job_bffr_3_f    <=  mul_bus_lb_intf.gpu_lb_res_valid  ? mul_bus_lb_intf.gpu_lb_res[P_32B_W-1:P_16B_W] : gpu_job_bffr_3_f;
        end
      end

      lb_intf.wr_valid        <=  lb_intf.wr_en;

      gpu_job_start_f         <=  (lb_intf.addr ==  VCORTEX_GPU_JOB_BFFR_0_REG_ADDR)  ? lb_intf.wr_en
                                                                                      : 1'b0;

      host_acc_rd_job_start_f <=  gpu_job_start_f & (gpu_job_action_f ==  DEBUG)  & host_acc_job_w.read_n_write;
      host_acc_wr_job_start_f <=  gpu_job_start_f & (gpu_job_action_f ==  DEBUG)  & ~host_acc_job_w.read_n_write;

      if(host_acc_done_f)
      begin //wait for host access job
        host_acc_done_f       <=  (gpu_job_action_f ==  DEBUG)  ? ~gpu_job_start_f  : host_acc_done_f;
      end
      else
      begin //wait for completion of job
        host_acc_done_f       <=  host_acc_job_w.read_n_write ? pxl_gw_intf.rd_rdy  : pxl_gw_intf.ready;
      end

      if(host_mul_job_done_f)
      begin //wait for host mulberry job
        host_mul_job_done_f   <=  (gpu_job_action_f ==  MULBRY)  ? ~gpu_job_start_f  : host_mul_job_done_f;
      end
      else
      begin //wait for completion of job
        host_mul_job_done_f   <=   mul_bus_lb_intf.gpu_lb_res_valid;
      end


      //Read Logic
      if(lb_intf.rd_en)
      begin
        case(lb_intf.addr)

          VCORTEX_GPU_CONTROL_REG_ADDR    : lb_intf.rd_data <=  {{P_32B_W-1{1'b0}},gpu_en_f};
          VCORTEX_GPU_STATUS_REG_ADDR     : lb_intf.rd_data <=  { {P_32B_W-5{1'b0}},
                                                                  host_mul_job_done_f,
                                                                  host_acc_done_f,
                                                                  gpu_job_intf.picasso_busy,
                                                                  gpu_job_intf.euclid_busy
                                                                };
          VCORTEX_GPU_JOB_BFFR_0_REG_ADDR : lb_intf.rd_data <=  {{P_32B_W-2{1'b0}},gpu_job_action_f};
          VCORTEX_GPU_JOB_BFFR_1_REG_ADDR : lb_intf.rd_data <=  {{P_16B_W{1'b0}},gpu_job_bffr_1_f};
          VCORTEX_GPU_JOB_BFFR_2_REG_ADDR : lb_intf.rd_data <=  {{P_16B_W{1'b0}},gpu_job_bffr_2_f};
          VCORTEX_GPU_JOB_BFFR_3_REG_ADDR : lb_intf.rd_data <=  {{P_16B_W{1'b0}},gpu_job_bffr_3_f};
          VCORTEX_GPU_JOB_BFFR_4_REG_ADDR : lb_intf.rd_data <=  {{P_16B_W{1'b0}},gpu_job_bffr_4_f};
          VCORTEX_GPU_JOB_BFFR_5_REG_ADDR : lb_intf.rd_data <=  {{P_16B_W{1'b0}},gpu_job_bffr_5_f};
          VCORTEX_GPU_JOB_BFFR_6_REG_ADDR : lb_intf.rd_data <=  {{P_16B_W{1'b0}},gpu_job_bffr_6_f};
          VCORTEX_GPU_JOB_BFFR_7_REG_ADDR : lb_intf.rd_data <=  {{P_16B_W{1'b0}},gpu_job_bffr_7_f};
          VCORTEX_GPU_JOB_BFFR_8_REG_ADDR : lb_intf.rd_data <=  {{P_16B_W{1'b0}},gpu_job_bffr_8_f};
          VCORTEX_GPU_JOB_BFFR_9_REG_ADDR : lb_intf.rd_data <=  {{P_16B_W{1'b0}},gpu_job_bffr_9_f};

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
  assign  gpu_job_intf.euclid_job_data.x2       = gpu_job_bffr_6_f[P_X_W-1:0];
  assign  gpu_job_intf.euclid_job_data.y2       = gpu_job_bffr_7_f[P_Y_W-1:0];
  assign  gpu_job_intf.euclid_job_data.color    = gpu_job_bffr_8_f[(P_LUM_W + P_CHRM_W + P_CHRM_W)-1:0];
  assign  gpu_job_intf.euclid_job_data.bzdepth  = gpu_job_bffr_9_f[3:0];

  assign  gpu_job_intf.picasso_job_start            = (gpu_job_action_f ==  FILL) ? gpu_job_start_f : 1'b0;
  assign  gpu_job_intf.picasso_job_data.fill_color  = gpu_job_bffr_1_f[(P_LUM_W + P_CHRM_W + P_CHRM_W)-1:0];
  assign  gpu_job_intf.picasso_job_data.line_color  = gpu_job_bffr_2_f[(P_LUM_W + P_CHRM_W + P_CHRM_W)-1:0];
  assign  gpu_job_intf.picasso_job_data.x0          = gpu_job_bffr_3_f[P_X_W-1:0];
  assign  gpu_job_intf.picasso_job_data.y0          = gpu_job_bffr_4_f[P_Y_W-1:0];

  assign  host_acc_job_w.read_n_write           = gpu_job_bffr_1_f[0];
  assign  host_acc_job_w.x                      = gpu_job_bffr_2_f[P_X_W-1:0];
  assign  host_acc_job_w.y                      = gpu_job_bffr_3_f[P_Y_W-1:0];
  assign  host_acc_job_w.pxl                    = gpu_job_bffr_4_f[(P_LUM_W + P_CHRM_W + P_CHRM_W)-1:0];
  

  /*  Instantiating Sub Modules */
  syn_gpu_core_euclid   syn_gpu_core_euclid_inst
  (

    .cr_intf            (cr_intf),

    .job_intf           (gpu_job_intf.euclid),

    .pxlgw_intf         (euclid_pxlgw_intf.master)

  );

  syn_gpu_core_picasso  syn_gpu_core_picasso_inst
  (

    .cr_intf            (cr_intf),

    .job_intf           (gpu_job_intf.picasso),

    .gpu_ff_intf        (gpu_ff_intf.master),

    .pxlgw_intf         (picasso_pxlgw_intf.master)

  );

  syn_gpu_ff_cntrlr     syn_gpu_ff_cntrlr_inst
  (

    .cr_intf            (cr_intf),

    .ff_intf            (gpu_ff_intf.cntrlr)

  );

  /*  Muxing Pixel GW interface between the engines selected  */
  always_comb
  begin : engine_mux_logic
    if(gpu_job_action_f ==  DRAW)
    begin
      pxl_gw_intf.pxl              =  euclid_pxlgw_intf.pxl;
      pxl_gw_intf.pxl_wr_valid     =  euclid_pxlgw_intf.pxl_wr_valid;
      pxl_gw_intf.pxl_rd_valid     =  euclid_pxlgw_intf.pxl_rd_valid;
      pxl_gw_intf.posx             =  euclid_pxlgw_intf.posx;
      pxl_gw_intf.posy             =  euclid_pxlgw_intf.posy;
      pxl_gw_intf.misc_info_dist   =  euclid_pxlgw_intf.misc_info_dist;
      pxl_gw_intf.misc_info_norm   =  euclid_pxlgw_intf.misc_info_norm;

      euclid_pxlgw_intf.ready      =  pxl_gw_intf.ready;
      euclid_pxlgw_intf.rd_pxl     =  pxl_gw_intf.rd_pxl;
      euclid_pxlgw_intf.rd_rdy     =  pxl_gw_intf.rd_rdy;

      picasso_pxlgw_intf.ready     =  0;
      picasso_pxlgw_intf.rd_pxl    =  0;
      picasso_pxlgw_intf.rd_rdy    =  0;
    end
    else if(gpu_job_action_f  ==  FILL)
    begin
      pxl_gw_intf.pxl              =  picasso_pxlgw_intf.pxl;
      pxl_gw_intf.pxl_wr_valid     =  picasso_pxlgw_intf.pxl_wr_valid;
      pxl_gw_intf.pxl_rd_valid     =  picasso_pxlgw_intf.pxl_rd_valid;
      pxl_gw_intf.posx             =  picasso_pxlgw_intf.posx;
      pxl_gw_intf.posy             =  picasso_pxlgw_intf.posy;
      pxl_gw_intf.misc_info_dist   =  picasso_pxlgw_intf.misc_info_dist;
      pxl_gw_intf.misc_info_norm   =  picasso_pxlgw_intf.misc_info_norm;

      picasso_pxlgw_intf.ready     =  pxl_gw_intf.ready;
      picasso_pxlgw_intf.rd_pxl    =  pxl_gw_intf.rd_pxl;
      picasso_pxlgw_intf.rd_rdy    =  pxl_gw_intf.rd_rdy;

      euclid_pxlgw_intf.ready      =  0;
      euclid_pxlgw_intf.rd_pxl     =  0;
      euclid_pxlgw_intf.rd_rdy     =  0;
    end
    else  //Host access
    begin
      pxl_gw_intf.pxl              =  host_acc_job_w.pxl;
      pxl_gw_intf.pxl_wr_valid     =  host_acc_wr_job_start_f;
      pxl_gw_intf.pxl_rd_valid     =  host_acc_rd_job_start_f;
      pxl_gw_intf.posx             =  host_acc_job_w.x;
      pxl_gw_intf.posy             =  host_acc_job_w.y;
      pxl_gw_intf.misc_info_dist   =  0;
      pxl_gw_intf.misc_info_norm   =  0;

      picasso_pxlgw_intf.ready     =  0;
      picasso_pxlgw_intf.rd_pxl    =  0;
      picasso_pxlgw_intf.rd_rdy    =  0;

      euclid_pxlgw_intf.ready      =  0;
      euclid_pxlgw_intf.rd_pxl     =  0;
      euclid_pxlgw_intf.rd_rdy     =  0;
    end
  end

  assign  mul_bus_gpu_intf.gpu_core_sid       = SID_IDLE;
  assign  mul_bus_gpu_intf.gpu_core_req_data  = 0;


  always_comb
  begin : sid_decode_logic
    case(gpu_job_bffr_1_f[1:0])

      2'd0    : decoded_sid_c = SID_IDLE;
      2'd1    : decoded_sid_c = SID_RAND;
      2'd2    : decoded_sid_c = SID_MUL;
      default : decoded_sid_c = SID_DIV;

    endcase
  end

  /*  Host access to mulberry bus  */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : mul_bus_acc_logic
    if(~cr_intf.rst_sync_l)
    begin
      mul_bus_lb_intf.gpu_lb_sid    <=  SID_IDLE;
    end
    else
    begin
      if(mul_bus_lb_intf.gpu_lb_sid ==  SID_IDLE)
      begin //wait for trigger to access mulberry bus
        if(gpu_job_start_f  & (gpu_job_action_f ==  MULBRY))
        begin
          mul_bus_lb_intf.gpu_lb_sid<=  decoded_sid_c;
        end
      end
      else
      begin //wait for job to complete
        if(mul_bus_lb_intf.gpu_lb_req_rdy)
        begin
          mul_bus_lb_intf.gpu_lb_sid<=  SID_IDLE;
        end
      end
    end
  end

  assign  mul_bus_lb_intf.gpu_lb_req_data = {gpu_job_bffr_3_f,gpu_job_bffr_2_f};

endmodule // syn_gpu_core
