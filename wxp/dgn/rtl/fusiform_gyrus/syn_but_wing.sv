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
 -- Module Name       : syn_but_wing
 -- Author            : mammenx
 -- Associated modules: complex_mult
 -- Function          : This block implements a simple FFT butterfly, which
                        accepts two input samples & twiddle factor.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_but_wing (

  syn_clk_rst_sync_intf   cr_intf,  //Clock Reset Interface

  syn_but_intf            but_intf  //slave

);

//----------------------- Global parameters Declarations ------------------
  import  syn_fft_pkg::*;

  parameter P_MUL_LAT         = 3;  //Multiplier latency
  parameter P_BUTTERFLY_RES_W = 42;
  

  /*  not exposed outside */
  localparam  P_PST_W         = P_MUL_LAT + 2;
  localparam  P_DIV           = P_FFT_TWDL_W  - 2;

//----------------------- Input Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------
  logic   [P_PST_W-1:0]       pst_vec_f;

  logic   [P_FFT_SAMPLE_W:0]  mul_res_norm_im_f;
  logic   [P_FFT_SAMPLE_W:0]  mul_res_norm_real_f;
  logic   [P_FFT_SAMPLE_W:0]  mul_res_inv_im_f;
  logic   [P_FFT_SAMPLE_W:0]  mul_res_inv_real_f;

//----------------------- Internal Wire Declarations ----------------------
  logic   [P_BUTTERFLY_RES_W-1:0]     mul_res_im_w;
  logic   [P_BUTTERFLY_RES_W-1:0]     mul_res_real_w;

  logic   [P_BUTTERFLY_RES_W-1:0]     mul_res_norm_im_w;
  logic   [P_BUTTERFLY_RES_W-1:0]     mul_res_norm_real_w;

  logic   [P_FFT_SAMPLE_W:0]       mul_res_inv_im_c;
  logic   [P_FFT_SAMPLE_W:0]       mul_res_inv_real_c;

  logic   [P_FFT_SAMPLE_W+1:0]     data_0_real_c;
  logic   [P_FFT_SAMPLE_W+1:0]     data_0_im_c;
  logic   [P_FFT_SAMPLE_W+1:0]     data_1_real_c;
  logic   [P_FFT_SAMPLE_W+1:0]     data_1_im_c;

  logic   [(P_FFT_SAMPLE_W*2)-1:0] bffr_rd_data_w;
  logic   [(P_FFT_SAMPLE_W*2)-1:0] bffr_wr_data_w;
  fft_sample_t                     bffr_sample_a_w;
  logic                            bffr_full_w;
  logic                            bffr_empty_w;


//----------------------- Start of Code -----------------------------------

  /*
    *               Butterfly Structure
    *
    *              +------+                           +---+
    * sample_a  ---|buffer|-------------------------->| + |--------------->
    *              +------+                   \   /   +---+   data_0_out
    *                                          \ /
    *                                           X
    *                               +----------/ \
    *                              /              \
    *               +---+         /       +----+   \
    *               | m |        /        |    |    \ +---+   data_1_out
    * sample_b  --->| u |---------------->| -1 |----->| + |--------------->
    *               | l |                 |    |      +---+
    * twiddle   --->| t |                 +----+
    *               +---+
    *
  */

  /*
    * PST vector generation logic
  */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : pst_vec_logic
    if(~cr_intf.rst_sync_l)
    begin
      pst_vec_f               <=  {P_PST_W{1'b0}};
    end
    else
    begin
      pst_vec_f[0]            <=  but_intf.sample_rdy;

      pst_vec_f[P_PST_W-1:1]  <=  pst_vec_f[P_PST_W-2:0]; //shift register
    end
  end

  //Normalize the multiplier output - division
  assign  mul_res_norm_im_w   =   {{P_DIV{mul_res_im_w[P_BUTTERFLY_RES_W-1]}},    mul_res_im_w[P_BUTTERFLY_RES_W-1:P_DIV]};
  assign  mul_res_norm_real_w =   {{P_DIV{mul_res_real_w[P_BUTTERFLY_RES_W-1]}},  mul_res_real_w[P_BUTTERFLY_RES_W-1:P_DIV]};

  //Calculating negative value of multiplier output - 2's compliment
  assign  mul_res_inv_im_c    =   ~mul_res_norm_im_w[P_FFT_SAMPLE_W:0]   + 1'b1;
  assign  mul_res_inv_real_c  =   ~mul_res_norm_real_w[P_FFT_SAMPLE_W:0] + 1'b1;

  /*
    * Intermediate Stage
  */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : pipe_stage1_logic
    if(~cr_intf.rst_sync_l)
    begin
      mul_res_norm_im_f       <=  {P_FFT_SAMPLE_W+1{1'b0}};
      mul_res_norm_real_f     <=  {P_FFT_SAMPLE_W+1{1'b0}};
      mul_res_inv_im_f        <=  {P_FFT_SAMPLE_W+1{1'b0}};
      mul_res_inv_real_f      <=  {P_FFT_SAMPLE_W+1{1'b0}};
    end
    else
    begin
      mul_res_norm_im_f       <=  mul_res_norm_im_w[P_FFT_SAMPLE_W:0];
      mul_res_norm_real_f     <=  mul_res_norm_real_w[P_FFT_SAMPLE_W:0];
      mul_res_inv_im_f        <=  mul_res_inv_im_c;
      mul_res_inv_real_f      <=  mul_res_inv_real_c;
    end
  end

  //Final Stage sum
  assign  data_0_real_c = {{2{bffr_sample_a_w.re[P_FFT_SAMPLE_W-1]}},bffr_sample_a_w.re}  + {{2{mul_res_norm_real_f[P_FFT_SAMPLE_W]}},mul_res_norm_real_f[P_FFT_SAMPLE_W-1:0]};
  assign  data_0_im_c   = {{2{bffr_sample_a_w.im[P_FFT_SAMPLE_W-1]}},bffr_sample_a_w.im}  + {{2{mul_res_norm_im_f[P_FFT_SAMPLE_W]}},mul_res_norm_im_f[P_FFT_SAMPLE_W-1:0]};
  assign  data_1_real_c = {{2{bffr_sample_a_w.re[P_FFT_SAMPLE_W-1]}},bffr_sample_a_w.re}  + {{2{mul_res_inv_real_f[P_FFT_SAMPLE_W]}},mul_res_inv_real_f[P_FFT_SAMPLE_W-1:0]};
  assign  data_1_im_c   = {{2{bffr_sample_a_w.im[P_FFT_SAMPLE_W-1]}},bffr_sample_a_w.im}  + {{2{mul_res_inv_im_f[P_FFT_SAMPLE_W]}},mul_res_inv_im_f[P_FFT_SAMPLE_W-1:0]};


  /*
    * Output Data Muxing Logic
    * data_0 will come first followed data_1
  */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : output_logic
    if(~cr_intf.rst_sync_l)
    begin
      but_intf.res.re         <=  {P_FFT_SAMPLE_W{1'b0}};
      but_intf.res.im         <=  {P_FFT_SAMPLE_W{1'b0}};
      but_intf.res_rdy        <=  1'b0;
    end
    else
    begin
      if(pst_vec_f[P_MUL_LAT])
      begin
        but_intf.res.re       <=  data_0_real_c[P_FFT_SAMPLE_W-1:0];
        but_intf.res.im       <=  data_0_im_c[P_FFT_SAMPLE_W-1:0];
      end
      else if(pst_vec_f[P_MUL_LAT+1])
      begin
        but_intf.res.re       <=  data_1_real_c[P_FFT_SAMPLE_W-1:0];
        but_intf.res.im       <=  data_1_im_c[P_FFT_SAMPLE_W-1:0];
      end

      but_intf.res_rdy        <=  |(pst_vec_f[P_MUL_LAT+1:P_MUL_LAT]);
    end
  end

  /*
    * Instantiating Multiplier
  */
  complex_mult    complex_mult_inst
  (
	  .aclr         (~cr_intf.rst_sync_l),  //active high port
	  .clock        (cr_intf.clk_ir),
	  .dataa_imag   (but_intf.sample_b.im),
	  .dataa_real   (but_intf.sample_b.re),
	  .datab_imag   (but_intf.twdl.im),
	  .datab_real   (but_intf.twdl.re),
	  .result_imag  (mul_res_im_w),
	  .result_real  (mul_res_real_w)
  );


  /*
    * Instantiating Fifo
  */
  ff_64x128_fwft  buffer_inst
  (
	  .aclr         (~cr_intf.rst_sync_l),
	  .clock        (cr_intf.clk_ir),
	  .data         (bffr_wr_data_w),
	  .rdreq        (pst_vec_f[P_MUL_LAT]),
	  .wrreq        (but_intf.sample_rdy),
	  .empty        (bffr_empty_w),
	  .full         (bffr_full_w),
	  .q            (bffr_rd_data_w),
	  .usedw        ()
  );

  assign  bffr_wr_data_w      = {but_intf.sample_a.re,  but_intf.sample_a.im};

  assign  bffr_sample_a_w.re  = bffr_rd_data_w[(P_FFT_SAMPLE_W*2)-1:P_FFT_SAMPLE_W];
  assign  bffr_sample_a_w.im  = bffr_rd_data_w[P_FFT_SAMPLE_W-1:0];

  //Generate Over/Under flow conditions
  assign  but_intf.bffr_ovrflw    = but_intf.sample_rdy & bffr_full_w;
  assign  but_intf.bffr_underflw  = pst_vec_f[P_MUL_LAT]  & bffr_empty_w;

endmodule // syn_but_wing
