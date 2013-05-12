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
 -- Module Name       : syn_gpu_anti_aliaser
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This module receives pixel data generated from
                        GPU Core (specifically Euclid) and applies anti-alias
                        filter based on distance & normalization factors.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_gpu_anti_aliaser (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf       cr_intf,      //Clock Reset Interface

  syn_pxl_xfr_intf            pxl_ingr_intf,  //Interface from GPU Core

  syn_pxl_xfr_intf            pxl_egr_intf,   //Interface to Pixel GW

  mulberry_bus_intf           mul_bus_intf,  //Interface to mulberry bus peripherals

  syn_anti_alias_status_intf  lb_stat_intf   //LB Status interface

  //--------------------- Misc Ports (Logic)  -----------

                );

//----------------------- Global parameters Declarations ------------------
  import  syn_global_pkg::*;
  import  syn_gpu_pkg::*;

  parameter P_INGR_BFFR_DATA_GAP_W  = P_64B_W - (8 + P_X_W  + P_Y_W + P_32B_W);
  parameter P_INGR_BFFR_DEPTH       = 128;
  localparam  P_INGR_BFFR_USED_W    = $clog2(P_INGR_BFFR_DEPTH);


//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------


//----------------------- Internal Wire Declarations ----------------------
  logic [P_64B_W-1:0]         ingr_bffr_wr_data_w;
  logic [P_64B_W-1:0]         ingr_bffr_rd_data_w;
  logic [P_INGR_BFFR_USED_W-1:0]  ingr_bffr_used_w;

  //pxl_ycbcr_t                 ingr_pxl_w;
  pxl_hsi_t                   ingr_pxl_w;
  logic [P_X_W-1:0]           ingr_posx_w;
  logic [P_Y_W-1:0]           ingr_posy_w;
  logic [P_16B_W-1:0]         ingr_dist_w;
  logic [P_16B_W-1:0]         ingr_norm_w;
  logic                       ingr_data_rdy_n_w;
  logic                       ingr_bffr_rd_ack_c;

  logic [P_INTENSITY_W-1:0]   norm_i_w;

//----------------------- FSM Declarations --------------------------------
enum  logic [1:0] { IDLE_S,
                    MUL_DIST_LUMA_S,
                    DIV_RES_NORM_S,
                    XMT_RES_S
                  }  fsm_pstate, next_state;


//----------------------- Start of Code -----------------------------------

  /*  Instantiate Ingress buffer & associated logic */
  assign  ingr_bffr_wr_data_w = { {P_INGR_BFFR_DATA_GAP_W{1'b0}},
                                  pxl_ingr_intf.pxl,
                                  pxl_ingr_intf.posx,
                                  pxl_ingr_intf.posy,
                                  pxl_ingr_intf.misc_info_dist,
                                  pxl_ingr_intf.misc_info_norm
                                };

  assign  pxl_ingr_intf.ready = ~(&ingr_bffr_used_w[P_INGR_BFFR_USED_W-1:3]);

  ff_64x128_fwft  ingr_bffr_inst
  (
    .aclr         (~cr_intf.rst_sync_l),
    .clock        (cr_intf.clk_ir),
    .data         (ingr_bffr_wr_data_w),
    .rdreq        (ingr_bffr_rd_ack_c),
    .wrreq        (pxl_ingr_intf.pxl_wr_valid),
    .empty        (ingr_data_rdy_n_w),
    .full         (),
    .q            (ingr_bffr_rd_data_w),
    .usedw        (ingr_bffr_used_w)
  );

  //Seperate out the individual fields from ingr_bffr_rd_data_w
  assign  { ingr_pxl_w,
            ingr_posx_w,
            ingr_posy_w,
            ingr_dist_w,
            ingr_norm_w
          }                   = ingr_bffr_rd_data_w[P_64B_W-P_INGR_BFFR_DATA_GAP_W-1:0];


  /*
    * Main FSM Logic
  */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : fsm_seq_logic
    if(~cr_intf.rst_sync_l)
    begin
      fsm_pstate              <=  IDLE_S;
    end
    else
    begin
      fsm_pstate              <=  next_state;
    end
  end

  always_comb
  begin : fsm_nxt_state_logic
    next_state                =   fsm_pstate;

    case(fsm_pstate)

      IDLE_S  :
      begin
        if(~ingr_data_rdy_n_w)
        begin
          next_state          =   ingr_norm_w[P_16B_W-1]  ? MUL_DIST_LUMA_S
                                                          : DIV_RES_NORM_S  ;
        end
      end

      MUL_DIST_LUMA_S :
      begin
        if(mul_bus_intf.anti_alias_res_valid)
        begin
          next_state          =   DIV_RES_NORM_S;
        end
      end

      DIV_RES_NORM_S  :
      begin
        if(mul_bus_intf.anti_alias_res_valid  | ~ingr_norm_w[P_16B_W-1])
        begin
          next_state          =   XMT_RES_S;
        end
      end

      XMT_RES_S :
      begin
        if(pxl_egr_intf.ready)
        begin
          next_state          =   IDLE_S;
        end
      end

    endcase
  end


  /*  Mulberry bus interface logic  */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : mul_bus_intf_logic
    if(~cr_intf.rst_sync_l)
    begin
      mul_bus_intf.anti_alias_sid       <=  SID_IDLE;
      mul_bus_intf.anti_alias_req_data  <=  {P_32B_W{1'b0}};
    end
    else
    begin
      case(fsm_pstate)

        IDLE_S  :
        begin
          if(~ingr_data_rdy_n_w & ingr_norm_w[P_16B_W-1])
          begin
            mul_bus_intf.anti_alias_sid                         <=  SID_MUL;
          end

          mul_bus_intf.anti_alias_req_data[P_16B_W-1:0]       <=  {1'b0,ingr_norm_w[P_16B_W-2:0]} -   ingr_dist_w;
          mul_bus_intf.anti_alias_req_data[P_32B_W-1:P_16B_W] <=  { {P_16B_W-P_INTENSITY_W{1'b0}},
                                                                    ingr_pxl_w.i
                                                                  };
        end

        MUL_DIST_LUMA_S :
        begin
          if(mul_bus_intf.anti_alias_req_rdy)
          begin
            mul_bus_intf.anti_alias_sid       <=  SID_IDLE;
          end
          else if(mul_bus_intf.anti_alias_res_valid)
          begin
            mul_bus_intf.anti_alias_sid       <=  SID_DIV;
            mul_bus_intf.anti_alias_req_data  <=  { mul_bus_intf.anti_alias_res[P_16B_W-1:0],
                                                    {1'b0,ingr_norm_w[P_16B_W-2:0]}
                                                  };
          end
        end

        DIV_RES_NORM_S  :
        begin
          if(mul_bus_intf.anti_alias_req_rdy)
          begin
            mul_bus_intf.anti_alias_sid       <=  SID_IDLE;
          end
        end

      endcase
    end
  end


  //Extract the normalised Intensity value
  assign  norm_i_w            = mul_bus_intf.anti_alias_res[P_16B_W +:  P_INTENSITY_W];

  /*  Pixel GW interface logic  */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : pxl_gw_intf_logic
    if(~cr_intf.rst_sync_l)
    begin
      pxl_egr_intf.pxl            <=  '{default:0};
      pxl_egr_intf.pxl_wr_valid   <=  1'b0;
      pxl_egr_intf.posx           <=  0;
      pxl_egr_intf.posy           <=  0;
    end
    else
    begin
      pxl_egr_intf.posx           <=  ingr_posx_w;
      pxl_egr_intf.posy           <=  ingr_posy_w;
      //pxl_egr_intf.pxl.cb         <=  ingr_pxl_w.cb;
      //pxl_egr_intf.pxl.cr         <=  ingr_pxl_w.cr;
      pxl_egr_intf.pxl.h          <=  ingr_pxl_w.h;
      pxl_egr_intf.pxl.s          <=  ingr_pxl_w.s;

      case(fsm_pstate)

        DIV_RES_NORM_S  :
        begin
          if(~ingr_norm_w[P_16B_W-1])
          begin
            pxl_egr_intf.pxl.i    <=  {P_INTENSITY_W{1'b1}} - pxl_egr_intf.pxl.i;

            pxl_egr_intf.pxl_wr_valid <=  1'b1;
          end
          else if(mul_bus_intf.anti_alias_res_valid)
          begin
            //pxl_egr_intf.pxl.i    <=  ~ingr_norm_w[P_16B_W-1] ? {P_INTENSITY_W{1'b1}} - norm_i_w
            //                                                  : norm_i_w  ;
            pxl_egr_intf.pxl.i    <=  norm_i_w;

            pxl_egr_intf.pxl_wr_valid <=  1'b1;
          end
        end

        XMT_RES_S :
        begin
          pxl_egr_intf.pxl_wr_valid   <=  ~pxl_egr_intf.ready;
        end

      endcase
    end
  end

  assign  pxl_egr_intf.pxl_rd_valid     = 1'b0;
  assign  pxl_egr_intf.misc_info_dist   = 0;
  assign  pxl_egr_intf.misc_info_norm   = 0;

  //Pop this entry from Ingress buffer
  assign  ingr_bffr_rd_ack_c  = pxl_egr_intf.pxl_wr_valid & pxl_egr_intf.ready;

  //Bring out misc status signals to LB
  assign  lb_stat_intf.job_que_empty  = ingr_data_rdy_n_w;

endmodule // syn_gpu_anti_aliaser
