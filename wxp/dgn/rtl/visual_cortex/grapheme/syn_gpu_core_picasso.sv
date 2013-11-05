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
 -- Module Name       : syn_gpu_core_picasso
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This module deals with Polygon filling logic.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_gpu_core_picasso (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf           cr_intf,      //Clock Reset Interface

  syn_gpu_core_job_intf           job_intf,     //Job queue interface

  syn_gpu_ff_cntrlr_intf          gpu_ff_intf,  //Interface to GPU_FF

  syn_pxl_xfr_intf                pxlgw_intf    //Interface to Pixel Gateway block


  //--------------------- Misc Ports (Logic)  -----------

                );

//----------------------- Global parameters Declarations ------------------
  import  syn_global_pkg::*;
  import  syn_gpu_pkg::*;

  localparam  P_PST_VEC_LEN   = 8;

//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------
  logic [P_PST_VEC_LEN-1:0]   pst_vec_f;
  point_t                     ptr_tmp_f;
  logic [1:0]                 ptr_rd_cntr_f;

//----------------------- Internal Wire Declarations ----------------------
  logic                       gpu_ff_wr_valid_c;
  logic                       gpu_ff_rd_valid_c;

  logic                       border_color_found_c;
  logic                       fill_color_found_c;
  logic                       skip_pxl_c;

  logic                       last_loc_read_c;


//----------------------- FSM Declarations --------------------------------
enum  logic [2:0] {
                    IDLE_S  = 3'd0,
                    INIT_GPU_FF_S,
                    WRITE_P0,
                    READ_P1,
                    READ_P2,
                    READ_P3,
                    READ_P4
                  } fsm_pstate, next_state;

//----------------------- Start of Code -----------------------------------

  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : fsm_seq_logic
    if(~cr_intf.rst_sync_l)
    begin
      fsm_pstate               <=  IDLE_S;
    end
    else
    begin
      fsm_pstate               <=  next_state;
    end
  end

  always_comb
  begin : fsm_comb_logic
    next_state    =   fsm_pstate;

    case(fsm_pstate)

      IDLE_S  :
      begin
        if(job_intf.picasso_job_start)
        begin
          next_state          =   INIT_GPU_FF_S;
        end
      end

      INIT_GPU_FF_S :
      begin
        if(pst_vec_f[4] & pxlgw_intf.ready)
        begin
          next_state          =   WRITE_P0;
        end
      end

      WRITE_P0  :
      begin
        if(pst_vec_f[6] & pxlgw_intf.ready)
        begin
          next_state          =   READ_P1;
        end
      end

      READ_P1 :
      begin
        if(skip_pxl_c | (pst_vec_f[6] & pxlgw_intf.ready))
        begin
          next_state          =   READ_P2;
        end
      end

      READ_P2 :
      begin
        if(skip_pxl_c | (pst_vec_f[6] & pxlgw_intf.ready))
        begin
          next_state          =   READ_P3;
        end
      end

      READ_P3 :
      begin
        if(skip_pxl_c | (pst_vec_f[6] & pxlgw_intf.ready))
        begin
          next_state          =   READ_P4;
        end
      end

      READ_P4 :
      begin
        if(skip_pxl_c | (pst_vec_f[6] & pxlgw_intf.ready))
        begin
          if(gpu_ff_intf.empty)
          begin
            next_state        =   IDLE_S;
          end
          else
          begin
            next_state        =   WRITE_P0;
          end
        end
      end

    endcase
  end

  //Generate status & job done indications
  assign  job_intf.picasso_busy     = (fsm_pstate ==  IDLE_S) ? 1'b0  : 1'b1;
  assign  job_intf.picasso_job_done = (fsm_pstate !=  IDLE_S) & (next_state ==  IDLE_S);


  //Generate signals for valid read/write to gpu_ff
  assign  gpu_ff_wr_valid_c   = gpu_ff_intf.wr_en & ~gpu_ff_intf.full;
  assign  gpu_ff_rd_valid_c   = gpu_ff_intf.rd_en & ~gpu_ff_intf.empty;

  //Check if boundry color is found
  assign  border_color_found_c  = (pxlgw_intf.rd_pxl  ==  job_intf.picasso_job_data.line_color) ? pxlgw_intf.rd_rdy : 1'b0;

  //Check if skip oundry color is found
  assign  fill_color_found_c    = (pxlgw_intf.rd_pxl  ==  job_intf.picasso_job_data.fill_color) ? pxlgw_intf.rd_rdy : 1'b0;

  //Generate signal to skip this pixel
  assign  skip_pxl_c  = pxlgw_intf.rd_rdy & ( (pxlgw_intf.rd_pxl  ==  job_intf.picasso_job_data.line_color) |
                                              (pxlgw_intf.rd_pxl  ==  job_intf.picasso_job_data.fill_color)   );

  //Check if the last pxl data has been read
  assign  last_loc_read_c     = &ptr_rd_cntr_f  & pxlgw_intf.rd_rdy;

  /*  Pixel Pipeline  */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : pxl_pipeline_logic
    if(~cr_intf.rst_sync_l)
    begin
      gpu_ff_intf.wr_en       <=  0;
      gpu_ff_intf.rd_en       <=  0;

      pxlgw_intf.pxl          <=  0;
      pxlgw_intf.pxl_wr_valid <=  0;
      pxlgw_intf.pxl_rd_valid <=  0;
      pxlgw_intf.posx         <=  0;
      pxlgw_intf.posy         <=  0;

      pst_vec_f               <=  0;
      ptr_tmp_f               <=  0;
      ptr_rd_cntr_f           <=  0;
    end
    else
    begin
      case(fsm_pstate)

        IDLE_S  :
        begin
          gpu_ff_intf.wr_en       <=  job_intf.picasso_job_start;
          gpu_ff_intf.rd_en       <=  0;
          pxlgw_intf.pxl_wr_valid <=  0;
          pxlgw_intf.pxl_rd_valid <=  0;
          pst_vec_f               <=  {{P_PST_VEC_LEN-1{1'b0}},job_intf.picasso_job_start};
          ptr_rd_cntr_f           <=  0;
        end

        INIT_GPU_FF_S :
        begin
          //Get the next available wptr
          gpu_ff_intf.wr_en       <=  gpu_ff_intf.wr_en & gpu_ff_intf.full; //de assert wr_en once valid

          if(pst_vec_f[4])
          begin
            pst_vec_f             <=  {{P_PST_VEC_LEN-1{1'b0}},pxlgw_intf.ready};
          end
          else
          begin
            pst_vec_f[4:0]        <=  (gpu_ff_wr_valid_c  | pxlgw_intf.ready) ? {pst_vec_f[3:0],1'b0}
                                                                              : pst_vec_f;
          end

          //Write seed point to SRAM memory @ wptr + 0,1,2,3
          if(pst_vec_f[0])  //write x0 lsb
          begin
            pxlgw_intf.pxl        <=  job_intf.picasso_job_data.x0[P_PXL_HSI_W-1:0];
            pxlgw_intf.posx       <=  gpu_ff_intf.waddr.x;
            pxlgw_intf.posy       <=  gpu_ff_intf.waddr.y;
            pxlgw_intf.pxl_wr_valid <=  gpu_ff_wr_valid_c;
          end
          else if(pst_vec_f[1]) //write x0 msb
          begin
            pxlgw_intf.pxl        <=  {{(2*P_PXL_HSI_W - P_X_W){1'b0}}, job_intf.picasso_job_data.x0[P_X_W-1:P_PXL_HSI_W]};
            pxlgw_intf.posx       <=  pxlgw_intf.posx + pxlgw_intf.ready;
          end
          else if(pst_vec_f[2]) //write y0 lsb
          begin
            pxlgw_intf.pxl        <=  job_intf.picasso_job_data.y0[P_PXL_HSI_W-1:0];
            pxlgw_intf.posx       <=  pxlgw_intf.posx + pxlgw_intf.ready;
          end
          else if(pst_vec_f[3]) //write y0 msb
          begin
            pxlgw_intf.pxl        <=  {{(2*P_PXL_HSI_W - P_Y_W){1'b0}}, job_intf.picasso_job_data.y0[P_Y_W-1:P_PXL_HSI_W]};
            pxlgw_intf.posx       <=  pxlgw_intf.posx + pxlgw_intf.ready;
          end
          else  //pst_vec_f[4]
          begin
            pxlgw_intf.pxl_wr_valid <=  ~pxlgw_intf.ready;
          end

          gpu_ff_intf.rd_en       <=  pst_vec_f[4]  & pxlgw_intf.ready;
        end

        WRITE_P0  :
        begin
          //Get next rptr
          gpu_ff_intf.rd_en       <=  gpu_ff_intf.rd_en & gpu_ff_intf.empty;

          
          if(pst_vec_f[6] & pxlgw_intf.ready)
          begin
            pst_vec_f             <=  {{P_PST_VEC_LEN-1{1'b0}},pxlgw_intf.ready};
          end
          else
          begin
            pst_vec_f[3:0]        <=  (gpu_ff_rd_valid_c  | pxlgw_intf.ready) ? {pst_vec_f[2:0],1'b0}
                                                                              : pst_vec_f[3:0];

            pst_vec_f[4]          <=  pst_vec_f[4]  ? ~last_loc_read_c  : pst_vec_f[3];  //hold this signal until all the 4 locs have been read in
            pst_vec_f[5]          <=  pst_vec_f[4]  & last_loc_read_c;
            pst_vec_f[6]          <=  pst_vec_f[6]  ? pxlgw_intf.ready  : pst_vec_f[5];
          end

          //Read point from SRAM memory @ rptr + 0,1,2,3
          if(pst_vec_f[0])  //read x0 lsb
          begin
            pxlgw_intf.pxl_rd_valid <=  gpu_ff_rd_valid_c;
            pxlgw_intf.posx       <=  gpu_ff_intf.raddr.x;
            pxlgw_intf.posy       <=  gpu_ff_intf.raddr.y;
          end
          else if(pst_vec_f[1]) //write x0 msb
          begin
            pxlgw_intf.posx       <=  pxlgw_intf.posx + pxlgw_intf.ready;
          end
          else if(pst_vec_f[2]) //write y0 lsb
          begin
            pxlgw_intf.posx       <=  pxlgw_intf.posx + pxlgw_intf.ready;
          end
          else if(pst_vec_f[3]) //write y0 msb
          begin
            pxlgw_intf.posx       <=  pxlgw_intf.posx + pxlgw_intf.ready;
          end
          else if(pst_vec_f[4])
          begin
            pxlgw_intf.pxl_rd_valid <=  pxlgw_intf.pxl_rd_valid ? ~pxlgw_intf.ready : 1'b0;
          end
          else if(pst_vec_f[5])
          begin
            pxlgw_intf.pxl_wr_valid <=  1'b1;
            pxlgw_intf.posx         <=  ptr_tmp_f.x;
            pxlgw_intf.posy         <=  ptr_tmp_f.y;
            pxlgw_intf.pxl          <=  job_intf.picasso_job_data.fill_color;
          end
          else  // if(pst_vec_f[6])
          begin
            pxlgw_intf.pxl_wr_valid <=  ~pxlgw_intf.ready;
            pxlgw_intf.pxl_rd_valid <=  pxlgw_intf.ready;
            pxlgw_intf.posx         <=  ptr_tmp_f.x + pxlgw_intf.ready;
            pxlgw_intf.posy         <=  ptr_tmp_f.y;
          end

          //Build point read from SRAM
          if(pxlgw_intf.rd_rdy)
          begin
            ptr_rd_cntr_f           <=  ptr_rd_cntr_f + 1'b1;

            unique  case(ptr_rd_cntr_f)

              2'd0  : ptr_tmp_f.x[P_PXL_HSI_W-1:0]        <=  pxlgw_intf.rd_pxl;
              2'd1  : ptr_tmp_f.x[P_X_W-1:P_PXL_HSI_W]    <=  pxlgw_intf.rd_pxl[P_X_W-P_PXL_HSI_W-1:0];
              2'd2  : ptr_tmp_f.y[P_PXL_HSI_W-1:0]        <=  pxlgw_intf.rd_pxl;
              2'd3  : ptr_tmp_f.y[P_Y_W-1:P_PXL_HSI_W]    <=  pxlgw_intf.rd_pxl[P_Y_W-P_PXL_HSI_W-1:0];
            endcase
          end
          else if(pst_vec_f[6])
          begin
            ptr_tmp_f.x             <=  ptr_tmp_f.x + pxlgw_intf.ready;
          end
        end

        READ_P1 :
        begin
          if(skip_pxl_c | (pst_vec_f[6] & pxlgw_intf.ready))
          begin
            pst_vec_f               <=  {{P_PST_VEC_LEN-1{1'b0}},1'b1};
          end
          else
          begin
            pst_vec_f[6:0]          <=  (pxlgw_intf.ready | pxlgw_intf.rd_rdy | gpu_ff_wr_valid_c)  ? {pst_vec_f[5:0],1'b0} : pst_vec_f[6:0];
          end

          if(pst_vec_f[0])  //wait for read accept
          begin
            pxlgw_intf.pxl_rd_valid <=  ~pxlgw_intf.ready;
          end
          else if(pst_vec_f[1]) //wait for read results
          begin
            gpu_ff_intf.wr_en       <=  pxlgw_intf.rd_rdy ? ~skip_pxl_c : 1'b0;

            if(skip_pxl_c)
            begin
              pxlgw_intf.pxl_rd_valid <=  1'b1;
              pxlgw_intf.posx         <=  ptr_tmp_f.x - 1'b1;
              pxlgw_intf.posy         <=  ptr_tmp_f.y - 1'b1;
              ptr_tmp_f.x             <=  ptr_tmp_f.x - 1'b1;
              ptr_tmp_f.y             <=  ptr_tmp_f.y - 1'b1;
            end
          end
          else if(pst_vec_f[2]) //wait for nxt available wptr
          begin
            gpu_ff_intf.wr_en       <=  gpu_ff_intf.full;

            pxlgw_intf.pxl          <=  ptr_tmp_f.x[P_PXL_HSI_W-1:0];
            pxlgw_intf.posx         <=  gpu_ff_intf.waddr.x;
            pxlgw_intf.posy         <=  gpu_ff_intf.waddr.y;
            pxlgw_intf.pxl_wr_valid <=  gpu_ff_wr_valid_c;
          end
          else if(pst_vec_f[3]) //write x0 msb
          begin
            pxlgw_intf.pxl        <=  {{(2*P_PXL_HSI_W - P_X_W){1'b0}}, ptr_tmp_f.x[P_X_W-1:P_PXL_HSI_W]};
            pxlgw_intf.posx       <=  pxlgw_intf.posx + pxlgw_intf.ready;
          end
          else if(pst_vec_f[4]) //write y0 lsb
          begin
            pxlgw_intf.pxl        <=  ptr_tmp_f.y[P_PXL_HSI_W-1:0];
            pxlgw_intf.posx       <=  pxlgw_intf.posx + pxlgw_intf.ready;
          end
          else if(pst_vec_f[5]) //write y0 msb
          begin
            pxlgw_intf.pxl        <=  {{(2*P_PXL_HSI_W - P_Y_W){1'b0}}, ptr_tmp_f.y[P_Y_W-1:P_PXL_HSI_W]};
            pxlgw_intf.posx       <=  pxlgw_intf.posx + pxlgw_intf.ready;
          end
          else  //pst_vec_f[6]
          begin
            pxlgw_intf.pxl_wr_valid <=  ~pxlgw_intf.ready;
            pxlgw_intf.pxl_rd_valid <=  pxlgw_intf.ready;
            pxlgw_intf.posx         <=  ptr_tmp_f.x - pxlgw_intf.ready;
            pxlgw_intf.posy         <=  ptr_tmp_f.y - pxlgw_intf.ready;
            ptr_tmp_f.x             <=  ptr_tmp_f.x - pxlgw_intf.ready;
            ptr_tmp_f.y             <=  ptr_tmp_f.y - pxlgw_intf.ready;
          end
        end

        READ_P2 :
        begin
          if(skip_pxl_c | (pst_vec_f[6] & pxlgw_intf.ready))
          begin
            pst_vec_f               <=  {{P_PST_VEC_LEN-1{1'b0}},1'b1};
          end
          else
          begin
            pst_vec_f[6:0]          <=  (pxlgw_intf.ready | pxlgw_intf.rd_rdy | gpu_ff_wr_valid_c)  ? {pst_vec_f[5:0],1'b0} : pst_vec_f[6:0];
          end

          if(pst_vec_f[0])  //wait for read accept
          begin
            pxlgw_intf.pxl_rd_valid <=  ~pxlgw_intf.ready;
          end
          else if(pst_vec_f[1]) //wait for read results
          begin
            gpu_ff_intf.wr_en       <=  pxlgw_intf.rd_rdy ? ~skip_pxl_c : 1'b0;

            if(skip_pxl_c)
            begin
              pxlgw_intf.pxl_rd_valid <=  1'b1;
              pxlgw_intf.posx         <=  ptr_tmp_f.x - 1'b1;
              pxlgw_intf.posy         <=  ptr_tmp_f.y + 1'b1;
              ptr_tmp_f.x             <=  ptr_tmp_f.x - 1'b1;
              ptr_tmp_f.y             <=  ptr_tmp_f.y + 1'b1;
            end
          end
          else if(pst_vec_f[2]) //wait for nxt available wptr
          begin
            gpu_ff_intf.wr_en       <=  gpu_ff_intf.full;

            pxlgw_intf.pxl          <=  ptr_tmp_f.x[P_PXL_HSI_W-1:0];
            pxlgw_intf.posx         <=  gpu_ff_intf.waddr.x;
            pxlgw_intf.posy         <=  gpu_ff_intf.waddr.y;
            pxlgw_intf.pxl_wr_valid <=  gpu_ff_wr_valid_c;
          end
          else if(pst_vec_f[3]) //write x0 msb
          begin
            pxlgw_intf.pxl        <=  {{(2*P_PXL_HSI_W - P_X_W){1'b0}}, ptr_tmp_f.x[P_X_W-1:P_PXL_HSI_W]};
            pxlgw_intf.posx       <=  pxlgw_intf.posx + pxlgw_intf.ready;
          end
          else if(pst_vec_f[4]) //write y0 lsb
          begin
            pxlgw_intf.pxl        <=  ptr_tmp_f.y[P_PXL_HSI_W-1:0];
            pxlgw_intf.posx       <=  pxlgw_intf.posx + pxlgw_intf.ready;
          end
          else if(pst_vec_f[5]) //write y0 msb
          begin
            pxlgw_intf.pxl        <=  {{(2*P_PXL_HSI_W - P_Y_W){1'b0}}, ptr_tmp_f.y[P_Y_W-1:P_PXL_HSI_W]};
            pxlgw_intf.posx       <=  pxlgw_intf.posx + pxlgw_intf.ready;
          end
          else  //pst_vec_f[6]
          begin
            pxlgw_intf.pxl_wr_valid <=  ~pxlgw_intf.ready;
            pxlgw_intf.pxl_rd_valid <=  pxlgw_intf.ready;
            pxlgw_intf.posx         <=  ptr_tmp_f.x - pxlgw_intf.ready;
            pxlgw_intf.posy         <=  ptr_tmp_f.y + pxlgw_intf.ready;
            ptr_tmp_f.x             <=  ptr_tmp_f.x - pxlgw_intf.ready;
            ptr_tmp_f.y             <=  ptr_tmp_f.y + pxlgw_intf.ready;
          end
        end

        READ_P3 :
        begin
          if(skip_pxl_c | (pst_vec_f[6] & pxlgw_intf.ready))
          begin
            pst_vec_f               <=  {{P_PST_VEC_LEN-1{1'b0}},1'b1};
          end
          else
          begin
            pst_vec_f[6:0]          <=  (pxlgw_intf.ready | pxlgw_intf.rd_rdy | gpu_ff_wr_valid_c)  ? {pst_vec_f[5:0],1'b0} : pst_vec_f[6:0];
          end

          if(pst_vec_f[0])  //wait for read accept
          begin
            pxlgw_intf.pxl_rd_valid <=  ~pxlgw_intf.ready;
          end
          else if(pst_vec_f[1]) //wait for read results
          begin
            gpu_ff_intf.wr_en       <=  pxlgw_intf.rd_rdy ? ~skip_pxl_c : 1'b0;

            if(skip_pxl_c)
            begin
              pxlgw_intf.pxl_rd_valid <=  1'b1;
              pxlgw_intf.posx         <=  ptr_tmp_f.x + 1'b1;
              pxlgw_intf.posy         <=  ptr_tmp_f.y + 1'b1;
              ptr_tmp_f.x             <=  ptr_tmp_f.x + 1'b1;
              ptr_tmp_f.y             <=  ptr_tmp_f.y + 1'b1;
            end
          end
          else if(pst_vec_f[2]) //wait for nxt available wptr
          begin
            gpu_ff_intf.wr_en       <=  gpu_ff_intf.full;

            pxlgw_intf.pxl          <=  ptr_tmp_f.x[P_PXL_HSI_W-1:0];
            pxlgw_intf.posx         <=  gpu_ff_intf.waddr.x;
            pxlgw_intf.posy         <=  gpu_ff_intf.waddr.y;
            pxlgw_intf.pxl_wr_valid <=  gpu_ff_wr_valid_c;
          end
          else if(pst_vec_f[3]) //write x0 msb
          begin
            pxlgw_intf.pxl        <=  {{(2*P_PXL_HSI_W - P_X_W){1'b0}}, ptr_tmp_f.x[P_X_W-1:P_PXL_HSI_W]};
            pxlgw_intf.posx       <=  pxlgw_intf.posx + pxlgw_intf.ready;
          end
          else if(pst_vec_f[4]) //write y0 lsb
          begin
            pxlgw_intf.pxl        <=  ptr_tmp_f.y[P_PXL_HSI_W-1:0];
            pxlgw_intf.posx       <=  pxlgw_intf.posx + pxlgw_intf.ready;
          end
          else if(pst_vec_f[5]) //write y0 msb
          begin
            pxlgw_intf.pxl        <=  {{(2*P_PXL_HSI_W - P_Y_W){1'b0}}, ptr_tmp_f.y[P_Y_W-1:P_PXL_HSI_W]};
            pxlgw_intf.posx       <=  pxlgw_intf.posx + pxlgw_intf.ready;
          end
          else  //pst_vec_f[6]
          begin
            pxlgw_intf.pxl_wr_valid <=  ~pxlgw_intf.ready;
            pxlgw_intf.pxl_rd_valid <=  pxlgw_intf.ready;
            pxlgw_intf.posx         <=  ptr_tmp_f.x + pxlgw_intf.ready;
            pxlgw_intf.posy         <=  ptr_tmp_f.y + pxlgw_intf.ready;
            ptr_tmp_f.x             <=  ptr_tmp_f.x + pxlgw_intf.ready;
            ptr_tmp_f.y             <=  ptr_tmp_f.y + pxlgw_intf.ready;
          end
        end

        READ_P4 :
        begin
          if(skip_pxl_c | (pst_vec_f[6] & pxlgw_intf.ready))
          begin
            pst_vec_f               <=  {{P_PST_VEC_LEN-1{1'b0}},1'b1};
          end
          else
          begin
            pst_vec_f[6:0]          <=  (pxlgw_intf.ready | pxlgw_intf.rd_rdy | gpu_ff_wr_valid_c)  ? {pst_vec_f[5:0],1'b0} : pst_vec_f[6:0];
          end

          if(pst_vec_f[0])  //wait for read accept
          begin
            pxlgw_intf.pxl_rd_valid <=  ~pxlgw_intf.ready;
          end
          else if(pst_vec_f[1]) //wait for read results
          begin
            gpu_ff_intf.wr_en       <=  pxlgw_intf.rd_rdy ? ~skip_pxl_c : 1'b0;

            gpu_ff_intf.rd_en       <=  skip_pxl_c;
          end
          else if(pst_vec_f[2]) //wait for nxt available wptr
          begin
            gpu_ff_intf.wr_en       <=  gpu_ff_intf.full;

            pxlgw_intf.pxl          <=  ptr_tmp_f.x[P_PXL_HSI_W-1:0];
            pxlgw_intf.posx         <=  gpu_ff_intf.waddr.x;
            pxlgw_intf.posy         <=  gpu_ff_intf.waddr.y;
            pxlgw_intf.pxl_wr_valid <=  gpu_ff_wr_valid_c;
          end
          else if(pst_vec_f[3]) //write x0 msb
          begin
            pxlgw_intf.pxl        <=  {{(2*P_PXL_HSI_W - P_X_W){1'b0}}, ptr_tmp_f.x[P_X_W-1:P_PXL_HSI_W]};
            pxlgw_intf.posx       <=  pxlgw_intf.posx + pxlgw_intf.ready;
          end
          else if(pst_vec_f[4]) //write y0 lsb
          begin
            pxlgw_intf.pxl        <=  ptr_tmp_f.y[P_PXL_HSI_W-1:0];
            pxlgw_intf.posx       <=  pxlgw_intf.posx + pxlgw_intf.ready;
          end
          else if(pst_vec_f[5]) //write y0 msb
          begin
            pxlgw_intf.pxl        <=  {{(2*P_PXL_HSI_W - P_Y_W){1'b0}}, ptr_tmp_f.y[P_Y_W-1:P_PXL_HSI_W]};
            pxlgw_intf.posx       <=  pxlgw_intf.posx + pxlgw_intf.ready;
          end
          else  //pst_vec_f[6]
          begin
            pxlgw_intf.pxl_wr_valid <=  ~pxlgw_intf.ready;
            gpu_ff_intf.rd_en       <=  pxlgw_intf.ready;
          end
        end

      endcase
    end
  end

  assign  pxlgw_intf.misc_info_dist   = 0;
  assign  pxlgw_intf.misc_info_norm   = 0;

endmodule // syn_gpu_core_picasso
