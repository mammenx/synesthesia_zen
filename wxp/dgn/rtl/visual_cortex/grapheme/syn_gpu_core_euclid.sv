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
  parameter P_BEZIER_FF_DEPTH   = 512;
  localparam  P_BEZIER_FF_OCC_W = $clog2(P_BEZIER_FF_DEPTH);
  parameter P_BEZIER_FF_DATA_W  = 64;
  localparam  P_BEZIER_POINTS_W = 3*(P_X_W+P_Y_W);

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

  logic                       wait_for_bzff_init_f;
  point_t                     m0_f;
  point_t                     m1_f;
  point_t                     m2_f;
  logic [3:0]                 bz_pst_vec_f;
  logic                       bz_pop_valid_f;
  logic                       bz_push_valid_f;
  logic [3:0]                 bz_depth_f;

//----------------------- Internal Wire Declarations ----------------------
  logic                       start_ljob_c;
  point_t                     ljob_p0_c;
  point_t                     ljob_p1_c;

  logic                       start_bjob_c;

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
  logic                       nstate_idle_c;
  logic                       pstate_idle_c;

  logic                       bzff_empty_w;
  logic                       bzff_full_w;
  logic [P_BEZIER_FF_DATA_W-1:0]  bzff_rdata_w;
  logic [P_BEZIER_FF_DATA_W-1:0]  bzff_wdata_c;
  logic [P_BEZIER_FF_OCC_W-1:0]   bzff_occ_w;
  point_t                     bzp0_w;
  point_t                     bzp1_w;
  point_t                     bzp2_w;
  point_t                     bzff_p0_w;
  point_t                     bzff_p1_w;
  point_t                     bzff_p2_w;
  logic [3:0]                 bzff_depth_w;
  logic [P_X_W:0]             p0x_plus_p1x_c;
  logic [P_X_W:0]             p1x_plus_p2x_c;
  logic [P_X_W+1:0]           m0x_plus_m1x_c;
  logic [P_Y_W:0]             p0y_plus_p1y_c;
  logic [P_Y_W:0]             p1y_plus_p2y_c;
  logic [P_Y_W+1:0]           m0y_plus_m1y_c;
  logic                       skip_push_c;

//----------------------- FSM Declarations --------------------------------
enum  logic [1:0] { IDLE_S, 
                    INIT_VARS_S,
                    DRAW_LINE_S
                  } lfsm_pstate, lfsm_nstate;

enum  logic [1:0] { BZ_IDLE_S, 
                    BZ_DRAW_BEZIER_S,
                    BZ_WAIT_FOR_LINE0_S,
                    BZ_WAIT_FOR_LINE1_S
                  } bfsm_pstate, bfsm_nstate;


//----------------------- Start of Code -----------------------------------

  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : fsm_seq_logic
    if(~cr_intf.rst_sync_l)
    begin
      lfsm_pstate              <=  IDLE_S;
      bfsm_pstate              <=  BZ_IDLE_S;
    end
    else
    begin
      lfsm_pstate              <=  lfsm_nstate;
      bfsm_pstate              <=  bfsm_nstate;
    end
  end

  //Line job inputs
  always_comb
  begin : ljob_data_init_mux_comb_logic
    if(job_intf.euclid_job_data.shape ==  LINE)
    begin
      start_ljob_c      =   job_intf.euclid_job_start;
    end
    else if(bfsm_pstate ==  BZ_DRAW_BEZIER_S)  //wait for trigger from BZ Pipe
    begin
      start_ljob_c      =   (|bz_pst_vec_f[2:1])  & skip_push_c;
    end
    else
    begin
      start_ljob_c      =   1'b0;
    end

    if(job_intf.euclid_job_data.shape ==  LINE)
    begin
      ljob_p0_c.x       =   job_intf.euclid_job_data.x0;
      ljob_p0_c.y       =   job_intf.euclid_job_data.y0;
      ljob_p1_c.x       =   job_intf.euclid_job_data.x1;
      ljob_p1_c.y       =   job_intf.euclid_job_data.y1;
    end
    else if(bz_pst_vec_f[1])
    begin
      ljob_p0_c         =   bzff_p0_w;
      ljob_p1_c         =   bzff_p1_w;
    end
    else if(bz_pst_vec_f[2])
    begin
      ljob_p0_c         =   start_ljob_c  ? bzff_p1_w : bzff_p0_w;
      ljob_p1_c         =   start_ljob_c  ? bzff_p2_w : bzff_p1_w;
    end
    else
    begin
      ljob_p0_c         =   bzff_p1_w;
      ljob_p1_c         =   bzff_p2_w;
    end
  end

  always_comb
  begin : lfsm_nstate_logic
    lfsm_nstate                =   lfsm_pstate;

    case(lfsm_pstate)

      IDLE_S  :
      begin
        if(start_ljob_c)
        begin
          lfsm_nstate   = INIT_VARS_S;
        end
      end

      INIT_VARS_S :
      begin
        lfsm_nstate     = DRAW_LINE_S;
      end

      DRAW_LINE_S :
      begin
        if(line_drw_ovr_c)
        begin
          lfsm_nstate  = IDLE_S;
        end
      end

    endcase
  end

  //Bezer Job inputs
  assign  start_bjob_c        =   (job_intf.euclid_job_data.shape ==  BEZIER) ? job_intf.euclid_job_start : 1'b0;

  always_comb
  begin : bfsm_nstate_logic
    bfsm_nstate                =   bfsm_pstate;

    case(bfsm_pstate)

      BZ_IDLE_S  :
      begin
        if(start_bjob_c)
        begin
          bfsm_nstate   = BZ_DRAW_BEZIER_S;
        end
      end

      BZ_DRAW_BEZIER_S :
      begin
        if(~wait_for_bzff_init_f)
        begin
          if(bzff_occ_w ==  0)
          begin
            bfsm_nstate   = BZ_IDLE_S;
          end
          if(bz_pst_vec_f[1]  & skip_push_c)
          begin
            bfsm_nstate   = BZ_WAIT_FOR_LINE0_S;
          end
          else if(bz_pst_vec_f[2]  & skip_push_c)
          begin
            bfsm_nstate   = BZ_WAIT_FOR_LINE1_S;
          end
        end
      end

      BZ_WAIT_FOR_LINE0_S  :
      begin
        if(line_drw_ovr_c)
        begin
          bfsm_nstate   = BZ_DRAW_BEZIER_S;
        end
      end

      BZ_WAIT_FOR_LINE1_S  :
      begin
        if(line_drw_ovr_c)
        begin
          bfsm_nstate   = BZ_DRAW_BEZIER_S;
        end
      end

    endcase
  end


  //Check if x1>x0, y1>y0
  assign  sx_c  = (ljob_p1_c.x  > ljob_p0_c.x)  ? 1'b1  : 1'b0;
  assign  sy_c  = (ljob_p1_c.y  > ljob_p0_c.y)  ? 1'b1  : 1'b0;

  //calculate abs(x1-x0), abs(y1-y0)
  assign  dx_c  = sx_c  ? (ljob_p1_c.x  - ljob_p0_c.x)
                        : (ljob_p0_c.x  - ljob_p1_c.x);

  assign  dy_c  = sy_c  ? (ljob_p1_c.y  - ljob_p0_c.y)
                        : (ljob_p0_c.y  - ljob_p1_c.y);

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
  assign  line_drw_ovr_c  = (pxl_out_posx_f ==  ljob_p1_c.x)  &
                            (pxl_out_posy_f ==  ljob_p1_c.y)  &
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

      if(lfsm_pstate ==  DRAW_LINE_S)
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
      case(lfsm_pstate)

        IDLE_S  :
        begin
          pxl_out_valid_f     <=  1'b0;
          pxl_out_posx_f      <=  pxl_out_posx_f;
          pxl_out_posy_f      <=  pxl_out_posy_f;
        end

        INIT_VARS_S :
        begin
          //pxl_out_valid_f     <=  (job_intf.euclid_job_data.shape ==  LINE) ? 1'b1  : 1'b0;
          pxl_out_valid_f     <=  1'b1;
          pxl_out_color_f     <=  job_intf.euclid_job_data.color;

          dx_minus_dy_f       <=  {1'b0,dx_f} + dy_2comp_c; //dx - dy

          pxl_out_posx_f      <=  ljob_p0_c.x;
          pxl_out_posy_f      <=  ljob_p0_c.y;
        end

        DRAW_LINE_S :
        begin
          //pxl_out_valid_f     <=  ~line_drw_ovr_c & pxlgw_intf.ready;
          pxl_out_valid_f     <=  ~line_drw_ovr_c;

          if(pipe_rdy_c)
          begin
            case(1'b1)

              incr_x_c  : pxl_out_posx_f  <=  pxl_out_posx_f  + 1'b1;

              decr_x_c  : pxl_out_posx_f  <=  pxl_out_posx_f  - 1'b1;

            endcase

            case(1'b1)

              incr_y_c  : pxl_out_posy_f  <=  pxl_out_posy_f  + 1'b1;

              decr_y_c  : pxl_out_posy_f  <=  pxl_out_posy_f  - 1'b1;

            endcase
          end
        end

      endcase
    end
  end

  //Check if the current FSM is idle
  assign  nstate_idle_c  = (job_intf.euclid_job_data.shape ==  LINE)  ? (lfsm_nstate  ==  IDLE_S)
                                                                      : (bfsm_nstate  ==  BZ_IDLE_S) ;

  assign  pstate_idle_c  = (job_intf.euclid_job_data.shape ==  LINE)  ? (lfsm_pstate  ==  IDLE_S)
                                                                      : (bfsm_pstate  ==  BZ_IDLE_S) ;

  //Feedback to Job interface
  assign  job_intf.euclid_busy      = ~pstate_idle_c;
  assign  job_intf.euclid_job_done  = job_intf.euclid_busy  & nstate_idle_c;

  //Assigning Alias interface outputs
  assign  pxlgw_intf.pxl            = pxl_out_color_f;
  assign  pxlgw_intf.pxl_rd_valid   = 1'b0;
  assign  pxlgw_intf.posx           = pxl_out_posx_f;
  assign  pxlgw_intf.posy           = pxl_out_posy_f;
  assign  pxlgw_intf.pxl_wr_valid   = pxl_out_valid_f;
  assign  pxlgw_intf.misc_info_norm = 0;
  assign  pxlgw_intf.misc_info_dist = 0;


  /*
    * Bezier operations
    *
    *         P1
    *         /\
    *        /  \
    *   M0  + -+-+  M1
    *      /  M2  \
    *     /        \
    * P0 /          \ P2
  */

  assign  {bzff_p0_w,bzff_p1_w,bzff_p2_w} = bzff_rdata_w[P_BEZIER_POINTS_W-1:0];
  assign  bzff_depth_w                    = bzff_rdata_w[P_BEZIER_FF_DATA_W-1:P_BEZIER_FF_DATA_W-4];

  //Calculate midpoints
  assign  p0x_plus_p1x_c  = {1'b0,bzff_p0_w.x}  + {1'b0,bzff_p1_w.x};
  assign  p1x_plus_p2x_c  = {1'b0,bzff_p1_w.x}  + {1'b0,bzff_p2_w.x};
  //assign  m0x_plus_m1x_c  = {2'd0,bzff_p0_w.x[P_X_W-1:1]} + {1'b0,bzff_p1_w.x}  + {2'd0,bzff_p2_w.x[P_X_W-1:1]};
  assign  m0x_plus_m1x_c  = {1'b0,m0_f.x} + {1'b0,m1_f.x};

  assign  p0y_plus_p1y_c  = {1'b0,bzff_p0_w.y}  + {1'b0,bzff_p1_w.y};
  assign  p1y_plus_p2y_c  = {1'b0,bzff_p1_w.y}  + {1'b0,bzff_p2_w.y};
  //assign  m0y_plus_m1y_c  = {2'd0,bzff_p0_w.y[P_Y_W-1:1]} + {1'b0,bzff_p1_w.y}  + {2'd0,bzff_p2_w.y[P_Y_W-1:1]};
  assign  m0y_plus_m1y_c  = {1'b0,m0_f.y} + {1'b0,m1_f.y};

  //Check if new set of points need to be pushed back into bzff
  assign  skip_push_c     = (bzff_depth_w ==  job_intf.euclid_job_data.bzdepth) ? 1'b1  : 1'b0;

  always_ff@(posedge  cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : bezier_logic
    if(~cr_intf.rst_sync_l)
    begin
      wait_for_bzff_init_f    <=  0;
      m0_f                    <=  0;
      m1_f                    <=  0;
      m2_f                    <=  0;
      bz_pst_vec_f            <=  0;
      bz_pop_valid_f          <=  0;
      bz_push_valid_f         <=  0;
      bz_depth_f              <=  0;
    end
    else
    begin
      case(bfsm_pstate)

        BZ_IDLE_S  :
        begin
          bz_push_valid_f     <=  start_bjob_c; //push the initial points into the bezier fifo
          bz_pop_valid_f      <=  0;
          bz_pst_vec_f        <=  4'b0001;
          bz_depth_f          <=  0;   
          wait_for_bzff_init_f<=  1'b1;
        end

        BZ_DRAW_BEZIER_S :
        begin
          wait_for_bzff_init_f<=  1'b0;

          m0_f.x              <=  p0x_plus_p1x_c[P_X_W:1];
          m1_f.x              <=  p1x_plus_p2x_c[P_X_W:1];
          m2_f.x              <=  m0x_plus_m1x_c[P_X_W:1];
          m0_f.y              <=  p0y_plus_p1y_c[P_Y_W:1];
          m1_f.y              <=  p1y_plus_p2y_c[P_Y_W:1];
          m2_f.y              <=  m0y_plus_m1y_c[P_Y_W:1];
          bz_depth_f          <=  bzff_depth_w  + 1'b1;

          /*  Wait for BZFF to have data  */
          bz_pst_vec_f[0]     <=  bz_pst_vec_f[3] | (bz_pst_vec_f[0]  & bzff_empty_w);

          /*  Wait 1clk for m0,m1 & depth to calculate */
          bz_pst_vec_f[1]     <=  bz_pst_vec_f[0] & ~bzff_empty_w;

          /*  Wait 1clk for m2 to calculate; can push first subset {p0,m0,m2} */
          bz_pst_vec_f[2]     <=  bz_pst_vec_f[1];

          /*  Can push second subset {m2,m1,p2} */
          bz_pst_vec_f[3]     <=  bz_pst_vec_f[2];

          bz_push_valid_f     <=  (|bz_pst_vec_f[2:1])  & ~skip_push_c;
          
          bz_pop_valid_f      <=  bz_pst_vec_f[2] & ~skip_push_c;
        end

        BZ_WAIT_FOR_LINE0_S  :
        begin
          bz_push_valid_f     <=  0;
          bz_pop_valid_f      <=  0;
        end

        BZ_WAIT_FOR_LINE1_S  :
        begin
          bz_push_valid_f     <=  0;
          bz_pop_valid_f      <=  line_drw_ovr_c;
        end

      endcase
    end
  end

  assign  bzp0_w.x  = job_intf.euclid_job_data.x0;
  assign  bzp1_w.x  = job_intf.euclid_job_data.x1;
  assign  bzp2_w.x  = job_intf.euclid_job_data.x2;
  assign  bzp0_w.y  = job_intf.euclid_job_data.y0;
  assign  bzp1_w.y  = job_intf.euclid_job_data.y1;
  assign  bzp2_w.y  = job_intf.euclid_job_data.y2;

  //Pack data into Bezier FIFO
  always_comb
  begin : bezier_wdata_logic
    bzff_wdata_c  = 0;

    bzff_wdata_c[P_BEZIER_FF_DATA_W-1:P_BEZIER_FF_DATA_W-4] = bz_depth_f;

    if(bz_pst_vec_f[2])
    begin
      bzff_wdata_c[P_BEZIER_POINTS_W-1:0] = {bzff_p0_w,m0_f,m2_f};
    end
    else if(bz_pst_vec_f[3])
    begin
      bzff_wdata_c[P_BEZIER_POINTS_W-1:0] = {m2_f,m1_f,bzff_p2_w};
    end
    else
    begin
      bzff_wdata_c[P_BEZIER_POINTS_W-1:0] = {bzp0_w,bzp1_w,bzp2_w};
    end
  end


  /*  Instantiate Bezier FIFO */
  ff_64x512_fwft  bezier_ff_inst
  (
    .aclr         (~cr_intf.rst_sync_l),
    .clock        (cr_intf.clk_ir),
    .data         (bzff_wdata_c),
    .rdreq        (bz_pop_valid_f),
    .wrreq        (bz_push_valid_f),
    .empty        (bzff_empty_w),
    .full         (bzff_full_w),
    .q            (bzff_rdata_w),
    .usedw        (bzff_occ_w)
  );


endmodule // syn_gpu_core_euclid
