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
 -- Module Name       : syn_gpu_core_euclid
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This module contains logic required to render
                        straight lines, circles & ellipses.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_gpu_core_euclid (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf           cr_intf,      //Clock Reset Interface

  syn_gpu_core_job_intf           job_intf,     //Job queue interface

  syn_pxl_xfr_intf                pxlgw_intf    //Interface to Pixel Gateway block


  //--------------------- Misc Ports (Logic)  -----------

                );

//----------------------- Global parameters Declarations ------------------
  import  syn_global_pkg::*;
  import  syn_gpu_pkg::*;

  parameter P_IDX_W   = (P_X_W  > P_Y_W)  ? P_X_W + 1 : P_Y_W + 1;

//----------------------- Internal Register Declarations ------------------
  logic [P_IDX_W-1:0]         dx_f;
  logic [P_IDX_W-1:0]         dy_f;
  logic                       sx_f;
  logic                       sy_f;
  logic [P_IDX_W:0]           err_f;  //signed
  logic                       steep_c;
  logic [P_IDX_W:0]           dx_minus_dy_f;

  logic                       pxl_out_valid_f;
  logic [P_X_W-1:0]           pxl_out_posx_f;
  logic [P_Y_W-1:0]           pxl_out_posy_f;
  pxl_hsi_t                   pxl_out_color_f;

//----------------------- Internal Wire Declarations ----------------------
  logic [P_IDX_W-1:0]         dx_c;
  logic [P_IDX_W-1:0]         dy_c;
  logic [P_IDX_W:0]           dy_2comp_c;   //signed
  logic [P_IDX_W:0]           dx_2comp_c;   //signed
  logic [P_IDX_W+1:0]         e2_w;         //signed
  logic [P_IDX_W+1:0]         e2_plus_dy_c; //signed
  logic [P_IDX_W+1:0]         e2_minus_dx_c;//signed
  logic                       sx_c;
  logic                       sy_c;
  logic                       incr_x_c;
  logic                       incr_y_c;
  logic                       decr_x_c;
  logic                       decr_y_c;

  logic                       pipe_rdy_c;
  logic                       line_drw_ovr_c;

//----------------------- FSM Declarations --------------------------------
enum  logic [1:0] { IDLE_S, 
                    INIT_VARS_S,
                    DRAW_LINE_S
                  } fsm_pstate, next_state;



//----------------------- Start of Code -----------------------------------

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

    unique  case(fsm_pstate)

      IDLE_S  :
      begin
        if(job_intf.euclid_job_start)
        begin
          next_state  = INIT_VARS_S;
        end
      end

      INIT_VARS_S :
      begin
        case(job_intf.euclid_job_data.shape)

          LINE    :   next_state  = DRAW_LINE_S;

          default :   next_state  = IDLE_S;

        endcase
      end

      DRAW_LINE_S :
      begin
        if(line_drw_ovr_c)
        begin
          next_state  = IDLE_S;
        end
      end

    endcase
  end


  //Check if x1>x0, y1>y0
  assign  sx_c  = (job_intf.euclid_job_data.x1  > job_intf.euclid_job_data.x0)  ? 1'b1  : 1'b0;
  assign  sy_c  = (job_intf.euclid_job_data.y1  > job_intf.euclid_job_data.y0)  ? 1'b1  : 1'b0;

  //calculate abs(x1-x0), abs(y1-y0)
  assign  dx_c  = sx_c  ? (job_intf.euclid_job_data.x1  - job_intf.euclid_job_data.x0)
                        : (job_intf.euclid_job_data.x0  - job_intf.euclid_job_data.x1);

  assign  dy_c  = sy_c  ? (job_intf.euclid_job_data.y1  - job_intf.euclid_job_data.y0)
                        : (job_intf.euclid_job_data.y0  - job_intf.euclid_job_data.y1);

  //Calculate 2's compliments of dx, dy
  assign  dx_2comp_c  = {1'b1,~dx_f}  + 1'b1;
  assign  dy_2comp_c  = {1'b1,~dy_f}  + 1'b1;

  //Calculate e2=2*err
  assign  e2_w        = {err_f,1'b0};

  //Calculate e2+dy
  assign  e2_plus_dy_c  = e2_w  + {2'b0,dy_f};

  //Calculate e2-dx
  assign  e2_minus_dx_c = e2_w  + {dx_2comp_c[P_IDX_W],dx_2comp_c};

  //Decide whether to increment/decrement x & y pixel indexes
  assign  incr_x_c  = sx_f  & ~e2_plus_dy_c[P_IDX_W+1];
  assign  decr_x_c  = ~sx_f & ~e2_plus_dy_c[P_IDX_W+1];

  assign  incr_y_c  = sy_f  & e2_minus_dx_c[P_IDX_W+1];
  assign  decr_y_c  = ~sy_f & e2_minus_dx_c[P_IDX_W+1];

  //Check if end of line is reached
  assign  line_drw_ovr_c  = (pxl_out_posx_f ==  job_intf.euclid_job_data.x1)  &
                            (pxl_out_posy_f ==  job_intf.euclid_job_data.y1)  &
                            pxl_out_valid_f & pxlgw_intf.ready    ;

  always_ff@(posedge  cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : bressenham_line_logic
    if(~cr_intf.rst_sync_l)
    begin
      sx_f                    <=  0;
      sy_f                    <=  0;
      dx_f                    <=  0;
      dy_f                    <=  0;
      err_f                   <=  0;
    end
    else
    begin
      sx_f                    <=  sx_c;
      sy_f                    <=  sy_c;

      dx_f                    <=  dx_c;
      dy_f                    <=  dy_c;

      if(fsm_pstate ==  DRAW_LINE_S)
      begin
        if(pipe_rdy_c)
        begin
          case({e2_plus_dy_c[P_IDX_W+1],e2_minus_dx_c[P_IDX_W+1]})

            2'b00 : err_f     <=  err_f + dy_2comp_c;

            2'b01 : err_f     <=  err_f + {1'b0,dx_f} + dy_2comp_c;

            2'b10 : err_f     <=  err_f;

            2'b11 : err_f     <=  err_f + {1'b0,dx_f};

          endcase
        end
        else
        begin
          err_f               <=  err_f;
        end
      end
      else
      begin
        err_f                 <=  {1'b0,dx_f} + dy_2comp_c; //err = dx - dy
      end
    end
  end


  //Generate combined signal to halt pipeline on BP
  assign  pipe_rdy_c          =   pxlgw_intf.ready  & pxl_out_valid_f;

  //Calculate if the slope is >1 or not
  assign  steep_c             =   dx_minus_dy_f[P_IDX_W];

  /*
    * Pixel Output Logic
  */
  always_ff@(posedge  cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : pixel_output_logic
    if(~cr_intf.rst_sync_l)
    begin
      pxl_out_valid_f         <=  0;
      pxl_out_posx_f          <=  0;
      pxl_out_posy_f          <=  0;
      pxl_out_color_f         <=  '{default:0};

      dx_minus_dy_f           <=  0;
    end
    else
    begin
      unique  case(fsm_pstate)

        IDLE_S  :
        begin
          pxl_out_valid_f     <=  1'b0;
          pxl_out_posx_f      <=  pxl_out_posx_f;
          pxl_out_posy_f      <=  pxl_out_posy_f;
        end

        INIT_VARS_S :
        begin
          pxl_out_valid_f     <=  1'b1;
          pxl_out_color_f     <=  job_intf.euclid_job_data.color;

          dx_minus_dy_f       <=  {1'b0,dx_f} + dy_2comp_c; //dx - dy

          unique  case(job_intf.euclid_job_data.shape)

            LINE  :
            begin
              pxl_out_posx_f  <=  job_intf.euclid_job_data.x0;
              pxl_out_posy_f  <=  job_intf.euclid_job_data.y0;
            end

          endcase
        end

        DRAW_LINE_S :
        begin
          pxl_out_valid_f     <=  ~line_drw_ovr_c & pxlgw_intf.ready;

          if(pipe_rdy_c)
          begin
            unique  case(1'b1)

              incr_x_c  : pxl_out_posx_f  <=  pxl_out_posx_f  + 1'b1;

              decr_x_c  : pxl_out_posx_f  <=  pxl_out_posx_f  - 1'b1;

            endcase

            unique  case(1'b1)

              incr_y_c  : pxl_out_posy_f  <=  pxl_out_posy_f  + 1'b1;

              decr_y_c  : pxl_out_posy_f  <=  pxl_out_posy_f  - 1'b1;

            endcase
          end
        end

      endcase
    end
  end

  //Feedback to Job interface
  assign  job_intf.euclid_busy      = (fsm_pstate !=  IDLE_S) ? 1'b1  : 1'b0;
  assign  job_intf.euclid_job_done  = job_intf.euclid_busy  & (next_state ==  IDLE_S);

  //Assigning Alias interface outputs
  assign  pxlgw_intf.pxl            = pxl_out_color_f;
  assign  pxlgw_intf.pxl_rd_valid   = 1'b0;
  assign  pxlgw_intf.posx           = pxl_out_posx_f;
  assign  pxlgw_intf.posy           = pxl_out_posy_f;
  assign  pxlgw_intf.pxl_wr_valid   = pxl_out_valid_f;
  assign  pxlgw_intf.misc_info_norm = 0;
  assign  pxlgw_intf.misc_info_dist = 0;

endmodule // syn_gpu_core_euclid
