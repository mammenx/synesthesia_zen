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
 -- Module Name       : syn_fgyrus_fsm
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This block is where FFT transform is implemented.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_fgyrus_fsm (

  //--------------------- Misc Ports (Logic)  -----------
  syn_clk_rst_sync_intf   cr_intf,  //Clock Reset Interface

  syn_lb_intf             lb_intf,  //slave, data=32, addr=12

  syn_but_intf            but_intf, //master

  input logic             pcm_rdy_ih,

  mem_intf                pcm_lchnnl_intf,  //master, DATA_W=32, ADDR_W=7

  mem_intf                pcm_rchnnl_intf,  //master, DATA_W=32, ADDR_W=7

  mem_intf                win_ram_intf,     //master, DATA_W=32, ADDR_W=7

  mem_intf                twdl_ram_intf,    //master, DATA_W=32, ADDR_W=7

  mem_intf                cordic_ram_intf,  //master, DATA_W=16, ADDR_W=8

  syn_fft_cache_intf      cache_intf        //master, DATA_W=32, ADDR_W=8

  //--------------------- Interfaces --------------------


                );

//----------------------- Global parameters Declarations ------------------
  import  syn_global_pkg::*;
  import  syn_fft_pkg::*;

  parameter P_LB_DATA_W         = P_32B_W;
  parameter P_LB_ADDR_W         = 12;

  parameter P_NUM_SAMPLES       = 128;
  localparam  P_SAMPLE_CNTR_W   = $clog2(P_NUM_SAMPLES*2);
  parameter P_WIN_RAM_DATA_W    = P_32B_W;
  parameter P_TWDL_RAM_DATA_W   = P_32B_W;
  parameter P_CORDIC_RAM_DATA_W = P_16B_W;
  parameter P_DIV_W             = P_32B_W;
  parameter P_PST_VEC_W         = 8;
  parameter P_MEM_RD_DEL        = 2;
  parameter P_BUT_DEL           = 4;
  localparam  P_DEC_WIN_PIPE_L  = P_MEM_RD_DEL+1+P_BUT_DEL+1;
  localparam  P_NUM_FFT_STAGES  = $clog2(P_NUM_SAMPLES);  //should be 7
  localparam  P_LB_DEL          = P_MEM_RD_DEL;
  localparam  P_LB_ADDR_DEL_W   = P_LB_DEL*P_LB_ADDR_W;

  `include  "syn_fgyrus_reg_map.sv"


//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------
  logic [(2*P_LB_DEL)-1:0]    lb_del_vec_f;
  logic [P_LB_ADDR_DEL_W-1:0] lb_addr_del_vec_f;
  logic                       fgyrus_en_f;
  fgyrus_mode_t               fgyrus_mode_f;
  logic [3:0]                 fgyrus_post_norm_f;
  logic                       but_bffr_ovrflow_f;
  logic                       but_bffr_underflw_f;
  logic [P_MEM_RD_DEL-1:0]    rchnnl_n_lchnnl_f;

  logic [P_PST_VEC_W-1:0]     pst_vec_f;
  logic                       wait_for_end_f;
  logic [P_SAMPLE_CNTR_W-1:0] sample_rcntr_f;
  logic [P_SAMPLE_CNTR_W-1:0] sample_wcntr_f;

  logic [P_NUM_FFT_STAGES-1:0]  fft_stage_rd_f;
  logic [P_SAMPLE_CNTR_W-1:0] fft_stage_rd_bound_f;
  logic [P_NUM_FFT_STAGES-1:0]  fft_stage_wr_f;
  logic [P_SAMPLE_CNTR_W-1:0] fft_stage_wr_bound_f;

  logic                       div_load_f;
  logic [P_DIV_W-1:0]         div_n_f;
  logic [P_DIV_W-1:0]         div_d_f;
  logic                       div_norm_f;
  logic                       div_d_is_null_f;

  logic [6:0]                 twdl_addr_f;
  logic [7:0]                 cordic_addr_f;

  genvar  i;

//----------------------- Internal Wire Declarations ----------------------
  logic [P_LB_ADDR_W-1:0]     lb_del_addr_w;
  logic                       fgyrus_busy_c;

  logic [P_SAMPLE_CNTR_W-2:0] sample_rcntr_rev_w;
  logic                       decimate_ovr_c;

  logic                       wrap_inc_fft_rcntr_c;
  logic                       fft_stage_rd_ovr_c;
  logic                       fft_rd_ovr_c;

  logic                       wrap_inc_fft_wcntr_c;
  logic                       fft_stage_wr_ovr_c;
  logic                       fft_wr_ovr_c;

  logic                       cordic_ovr_c;
  logic                       abs_ovr_c;

  logic [P_DIV_W-1:0]         div_res_q_w;
  logic [P_DIV_W-1:0]         div_res_r_w;
  logic                       div_res_rdy_w;
  logic                       div_res_almost_done_w;
  logic [P_DIV_W-1:0]         div_res_q_norm_c;


//----------------------- Internal Interface Declarations -----------------


//----------------------- FSM Declarations --------------------------------
enum  logic [2:0] { IDLE_S=0,
                    DECIMATE_WINDOW_S,
                    FFT_S,
                    CORDIC_S,
                    ABS_S
                  } fsm_pstate, next_state;


//----------------------- Start of Code -----------------------------------

  assign  lb_del_addr_w = lb_addr_del_vec_f[P_LB_ADDR_DEL_W-1 -:  P_LB_ADDR_W];

  /*  Local Bus Logic */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : lb_logic
    if(~cr_intf.rst_sync_l)
    begin
      lb_intf.wr_valid        <=  0;
      lb_intf.rd_valid        <=  0;
      lb_intf.rd_data         <=  0;

      fgyrus_en_f             <=  0;
      fgyrus_mode_f           <=  NORMAL;  //normal
      fgyrus_post_norm_f      <=  0;  //No normalization
      but_bffr_ovrflow_f      <=  0;
      but_bffr_underflw_f     <=  0;

      lb_del_vec_f            <=  0;
      lb_addr_del_vec_f       <=  0;
    end
    else
    begin
      lb_del_vec_f            <=  {lb_del_vec_f[(2*P_LB_DEL)-3:0],  lb_intf.wr_en,  lb_intf.rd_en};
      lb_addr_del_vec_f       <=  {lb_addr_del_vec_f[P_LB_ADDR_DEL_W-P_LB_ADDR_W-1:0],  lb_intf.addr};

      if(lb_intf.wr_en)
      begin
        fgyrus_en_f           <=  (lb_intf.addr ==  {FGYRUS_REG_CODE,FGYRUS_CONTROL_REG_ADDR})  ? lb_intf.wr_data[0]  : fgyrus_en_f;

        fgyrus_mode_f         <=  (lb_intf.addr ==  {FGYRUS_REG_CODE,FGYRUS_CONTROL_REG_ADDR})  ? fgyrus_mode_t'(lb_intf.wr_data[1])  : fgyrus_mode_f;

        fgyrus_post_norm_f    <=  (lb_intf.addr ==  {FGYRUS_REG_CODE,FGYRUS_POST_NORM_REG_ADDR})? lb_intf.wr_data[3:0]: fgyrus_post_norm_f;
      end

      lb_intf.wr_valid        <=  lb_del_vec_f[(2*P_LB_DEL)-1];

      but_bffr_ovrflow_f      <=  but_bffr_ovrflow_f  | but_intf.bffr_ovrflw;
      but_bffr_underflw_f     <=  but_bffr_underflw_f | but_intf.bffr_underflw;

      case(lb_del_addr_w[P_LB_ADDR_W-1  -:  4])

        FGYRUS_REG_CODE :
        begin
          case(lb_del_addr_w[7:0])

            FGYRUS_CONTROL_REG_ADDR   : lb_intf.rd_data <=  {{P_LB_DATA_W-2{1'b0}}, fgyrus_mode_f,fgyrus_en_f};
            FGYRUS_STATUS_REG_ADDR    : lb_intf.rd_data <=  {{P_LB_DATA_W-3{1'b0}}, but_bffr_ovrflow_f,but_bffr_underflw_f,fgyrus_busy_c};
            FGYRUS_POST_NORM_REG_ADDR : lb_intf.rd_data <=  {{P_LB_DATA_W-4{1'b0}}, fgyrus_post_norm_f};
            default                   : lb_intf.rd_data <=  'hdeadbabe;

          endcase
        end

        FGYRUS_FFT_CACHE_RAM_CODE :
          lb_intf.rd_data     <=  cache_intf.hst_rd_data;

        FGYRUS_TWDLE_RAM_CODE :
          lb_intf.rd_data     <=  twdl_ram_intf.rdata;

        FGYRUS_CORDIC_RAM_CODE  :
          lb_intf.rd_data     <=  {{P_16B_W{1'b0}}, cordic_ram_intf.rdata};

        FGYRUS_WIN_RAM_CODE :
          lb_intf.rd_data     <=  win_ram_intf.rdata;

        default  : lb_intf.rd_data    <=  'hdeadbabe;
      endcase

      lb_intf.rd_valid        <=  lb_del_vec_f[(2*P_LB_DEL)-2];
    end
  end

  //Check if FSM is busy or not
  assign  fgyrus_busy_c = (fsm_pstate ==  IDLE_S) ?1'b0  : 1'b1;


  /*  FSM Sequential Logic  */
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

  /*  FSm Combinational Logic */
  always_comb
  begin : fsm_comb_logic
    next_state  = fsm_pstate;

    case(fsm_pstate)

      IDLE_S  :
      begin
        if(fgyrus_en_f  & pcm_rdy_ih  & (fgyrus_mode_f  ==  NORMAL))
        begin
          next_state  = DECIMATE_WINDOW_S;
        end
      end

      DECIMATE_WINDOW_S :
      begin
        if(decimate_ovr_c)
        begin
          next_state  = FFT_S;
        end
      end

      FFT_S :
      begin
        if(fft_wr_ovr_c)
        begin
          next_state  = CORDIC_S;
        end
      end

      CORDIC_S  :
      begin
        if(cordic_ovr_c)
        begin
          next_state  = ABS_S;
        end
      end

      ABS_S :
      begin
        if(abs_ovr_c)
        begin
          next_state  = IDLE_S;
        end
      end

    endcase
  end


  /*  PST Vector Logic  */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : pst_vec_logic
    if(~cr_intf.rst_sync_l)
    begin
      pst_vec_f               <=  0;
    end
    else
    begin
      case(fsm_pstate)

        IDLE_S  :
        begin
          pst_vec_f           <=  0;
        end

        DECIMATE_WINDOW_S :
        begin
          pst_vec_f[0]        <=  decimate_ovr_c  ? 1'b0  : ~pst_vec_f[0];
        end

        FFT_S :
        begin
          pst_vec_f[0]        <=  fft_wr_ovr_c  ? 1'b0    : ~pst_vec_f[0];
        end

        CORDIC_S  :
        begin
          pst_vec_f[2:0]      <=  {pst_vec_f[1:0],cache_intf.rd_valid};

          pst_vec_f[3]        <=  div_res_rdy_w;
        end

        ABS_S :
        begin
          pst_vec_f[2:0]      <=  {pst_vec_f[1:0],cache_intf.rd_valid};

          pst_vec_f[3]        <=  div_res_rdy_w;
        end

      endcase
    end
  end


  /*  Sample counter logic  */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : sample_cntr_logic
    if(~cr_intf.rst_sync_l)
    begin
      wait_for_end_f          <=  0;
      sample_rcntr_f          <=  0;
      sample_wcntr_f          <=  0;
    end
    else
    begin
      case(fsm_pstate)

        IDLE_S  :
        begin
          sample_rcntr_f      <=  0;
          sample_wcntr_f      <=  0;
          wait_for_end_f      <=  0;
        end

        DECIMATE_WINDOW_S :
        begin
          sample_rcntr_f      <=  wait_for_end_f  ? 0 : sample_rcntr_f + pst_vec_f[0];

          if(wait_for_end_f)  //wait for decimate over signal
          begin
            wait_for_end_f    <=  ~decimate_ovr_c;
          end
          else  //wait for last sample read
          begin
            wait_for_end_f    <=  (&sample_rcntr_f) ? pst_vec_f[0]  : 1'b0;
          end

          sample_wcntr_f      <=  sample_wcntr_f  + cache_intf.wr_en;
        end

        FFT_S :
        begin
          if(wait_for_end_f)  //wait for decimate over signal
          begin
            wait_for_end_f    <=  ~fft_wr_ovr_c;
          end
          else  //wait for last sample read
          begin
            wait_for_end_f    <=  fft_rd_ovr_c;
          end

          sample_rcntr_f[P_SAMPLE_CNTR_W-2:0] <=  (fft_stage_rd_ovr_c | wait_for_end_f) ? 0
                                                                      : sample_rcntr_f[P_SAMPLE_CNTR_W-2:0] +
                                                                        fft_stage_rd_f +
                                                                        wrap_inc_fft_rcntr_c;

          sample_rcntr_f[P_SAMPLE_CNTR_W-1]   <=  ~fft_rd_ovr_c &
                                                      (sample_rcntr_f[P_SAMPLE_CNTR_W-1]  |
                                                        (fft_stage_rd_f[P_NUM_FFT_STAGES-1]  & fft_stage_rd_ovr_c));


          if(cache_intf.wr_en)
          begin
            sample_wcntr_f[P_SAMPLE_CNTR_W-2:0] <=  fft_stage_wr_ovr_c  ? 0
                                                                        : sample_wcntr_f[P_SAMPLE_CNTR_W-2:0] +
                                                                          fft_stage_wr_f +
                                                                          wrap_inc_fft_wcntr_c;

            sample_wcntr_f[P_SAMPLE_CNTR_W-1]   <=  ~fft_wr_ovr_c &
                                                        (sample_wcntr_f[P_SAMPLE_CNTR_W-1]  |
                                                          (fft_stage_wr_f[P_NUM_FFT_STAGES-1]  & fft_stage_wr_ovr_c));
          end
        end

        CORDIC_S  : 
        begin
          if(wait_for_end_f)  //wait for over signal
          begin
            wait_for_end_f    <=  ~cordic_ovr_c;
          end
          else  //wait for last sample read
          begin
            wait_for_end_f    <=  &cache_intf.raddr;
          end

          sample_rcntr_f      <=  sample_rcntr_f  + pst_vec_f[3];
          sample_wcntr_f      <=  sample_wcntr_f  + cache_intf.wr_en;
        end

        ABS_S : 
        begin
          if(wait_for_end_f)  //wait for decimate over signal
          begin
            wait_for_end_f    <=  ~abs_ovr_c;
          end
          else  //wait for last sample read
          begin
            wait_for_end_f    <=  &cache_intf.raddr;
          end

          sample_rcntr_f      <=  sample_rcntr_f  + (div_res_almost_done_w  & ~wait_for_end_f);
          sample_wcntr_f      <=  sample_wcntr_f  + cache_intf.wr_en;
        end

      endcase
    end
  end

  //Check for end of decimation
  assign  decimate_ovr_c  = (&sample_wcntr_f) ? cache_intf.wr_en  : 1'b0;

  //Bit reversed version of sample counter
  generate
    for (i=0; i < P_SAMPLE_CNTR_W-1; i=i+1)
    begin : BIT_REV
      assign  sample_rcntr_rev_w[i]  = sample_rcntr_f[P_SAMPLE_CNTR_W-2-i];
    end
  endgenerate

  /*  PCM Mem Interface Logic */
  assign  pcm_rchnnl_intf.addr    = (fsm_pstate ==  DECIMATE_WINDOW_S)  ? sample_rcntr_rev_w  : 0;
  assign  pcm_rchnnl_intf.wdata   = 0;
  assign  pcm_rchnnl_intf.wren    = 0;
  assign  pcm_rchnnl_intf.rden    = (fsm_pstate ==  DECIMATE_WINDOW_S)  ? ~pst_vec_f[0] & ~wait_for_end_f : 1'b0;
  assign  pcm_lchnnl_intf.addr    = (fsm_pstate ==  DECIMATE_WINDOW_S)  ? sample_rcntr_rev_w  : 0;
  assign  pcm_lchnnl_intf.wdata   = 0;
  assign  pcm_lchnnl_intf.wren    = 0;
  assign  pcm_lchnnl_intf.rden    = (fsm_pstate ==  DECIMATE_WINDOW_S)  ? ~pst_vec_f[0] & ~wait_for_end_f : 1'b0;

  /*  Window Mem Interface Logic  */
  assign  win_ram_intf.addr       = (fgyrus_mode_f  ==  CONFIG) ? lb_intf.addr[6:0] :
                                      ((fsm_pstate  ==  DECIMATE_WINDOW_S)  ? sample_rcntr_rev_w  : 0);
  assign  win_ram_intf.wdata      = lb_intf.wr_data;
  assign  win_ram_intf.wren       = (lb_intf.addr[P_LB_ADDR_W-1 -: 4] ==  FGYRUS_WIN_RAM_CODE)  ? lb_intf.wr_en : 1'b0;
  assign  win_ram_intf.rden       = (fsm_pstate ==  DECIMATE_WINDOW_S)  ? ~pst_vec_f[0] : 1'b0;

  /*  FFT Stage Counter Logic */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : fft_stage_logic
    if(~cr_intf.rst_sync_l)
    begin
      fft_stage_rd_f          <=  1;  //One hot
      fft_stage_rd_bound_f    <=  (P_NUM_SAMPLES-1);
      fft_stage_wr_f          <=  1;  //One hot
      fft_stage_wr_bound_f    <=  (P_NUM_SAMPLES-1);
    end
    else
    begin
      if(fsm_pstate ==  FFT_S)
      begin
        if(fft_stage_rd_ovr_c)
        begin
          if(fft_stage_rd_f[P_NUM_FFT_STAGES-1])
          begin
            fft_stage_rd_f        <=  1;
            fft_stage_rd_bound_f  <=  (P_NUM_SAMPLES-1);
          end
          else
          begin
            fft_stage_rd_f        <=  {fft_stage_rd_f[P_NUM_FFT_STAGES-2:0],1'b0};
            fft_stage_rd_bound_f  <=  fft_stage_rd_bound_f  - fft_stage_rd_f;
          end
        end

        if(fft_stage_wr_ovr_c)
        begin
          if(fft_stage_wr_f[P_NUM_FFT_STAGES-1])
          begin
            fft_stage_wr_f        <=  1;
            fft_stage_wr_bound_f  <=  (P_NUM_SAMPLES-1);
          end
          else
          begin
            fft_stage_wr_f        <=  {fft_stage_wr_f[P_NUM_FFT_STAGES-2:0],1'b0};
            fft_stage_wr_bound_f  <=  fft_stage_wr_bound_f  - fft_stage_wr_f;
          end
        end
      end
      else
      begin
        fft_stage_rd_f        <=  1;
        fft_stage_rd_bound_f  <=  (P_NUM_SAMPLES-1);
        fft_stage_wr_f        <=  1;
        fft_stage_wr_bound_f  <=  (P_NUM_SAMPLES-1);
      end
    end
  end

  //Check when to wrap the FFT sample counter
  assign  wrap_inc_fft_rcntr_c  = (sample_rcntr_f[P_SAMPLE_CNTR_W-2:0]  >=  fft_stage_rd_bound_f)  ? 1'b1  : 1'b0;
  assign  wrap_inc_fft_wcntr_c  = (sample_wcntr_f[P_SAMPLE_CNTR_W-2:0]  >=  fft_stage_wr_bound_f)  ? cache_intf.wr_en  : 1'b0;

  //Check for end of FFT stage
  assign  fft_stage_rd_ovr_c    = &sample_rcntr_f[P_SAMPLE_CNTR_W-2:0];
  assign  fft_stage_wr_ovr_c    = &sample_wcntr_f[P_SAMPLE_CNTR_W-2:0]  & cache_intf.wr_en;

  //Check if all samples have been FFT'd
  assign  fft_rd_ovr_c          = fft_stage_rd_ovr_c  & sample_rcntr_f[P_SAMPLE_CNTR_W-1] & fft_stage_rd_f[P_NUM_FFT_STAGES-1];
  assign  fft_wr_ovr_c          = fft_stage_wr_ovr_c  & sample_wcntr_f[P_SAMPLE_CNTR_W-1] & fft_stage_wr_f[P_NUM_FFT_STAGES-1];


  /*  Butterfly Interface Logic */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : but_intf_logic
    if(~cr_intf.rst_sync_l)
    begin
      but_intf.sample_a.re    <=  0;
      but_intf.sample_a.im    <=  0;
      but_intf.sample_b.re    <=  0;
      but_intf.sample_b.im    <=  0;
      but_intf.twdl.re        <=  0;
      but_intf.twdl.im        <=  0;
      but_intf.sample_rdy     <=  0;

      rchnnl_n_lchnnl_f       <=  0;
    end
    else
    begin
      case(fsm_pstate)

        IDLE_S  :
        begin
          but_intf.sample_rdy   <=  0;
          rchnnl_n_lchnnl_f     <=  0;
        end

        DECIMATE_WINDOW_S :
        begin
          rchnnl_n_lchnnl_f     <=  decimate_ovr_c  ? 1'b0  : {rchnnl_n_lchnnl_f[P_MEM_RD_DEL-2:0], sample_rcntr_f[P_SAMPLE_CNTR_W-1]};

          but_intf.sample_a.re  <=  0;
          but_intf.sample_a.im  <=  0;

          but_intf.sample_b.re  <=  rchnnl_n_lchnnl_f ? pcm_rchnnl_intf.rdata : pcm_lchnnl_intf.rdata;
          but_intf.sample_b.im  <=  0;

          but_intf.twdl.re      <=  win_ram_intf.rdata[P_FFT_TWDL_W-1:0];
          but_intf.twdl.im      <=  0;

          but_intf.sample_rdy   <=  win_ram_intf.rd_valid & pcm_lchnnl_intf.rd_valid  & pcm_rchnnl_intf.rd_valid;
        end

        FFT_S :
        begin
          but_intf.sample_a.re  <=  but_intf.sample_b.re;
          but_intf.sample_a.im  <=  but_intf.sample_b.im;

          but_intf.sample_b.re  <=  cache_intf.rd_sample.re;
          but_intf.sample_b.im  <=  cache_intf.rd_sample.im;

          but_intf.twdl.re      <=  twdl_ram_intf.rdata[P_16B_W +:  P_FFT_TWDL_W];
          but_intf.twdl.im      <=  twdl_ram_intf.rdata[P_FFT_TWDL_W-1:0];

          but_intf.sample_rdy   <=  twdl_ram_intf.rd_valid  & cache_intf.rd_valid & pst_vec_f[0];
        end

      endcase
    end
  end

  /*  FFT Cache Interface Logic */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : fft_cache_intf_logic
    if(~cr_intf.rst_sync_l)
    begin
      cache_intf.wr_en        <=  0;
      cache_intf.rd_en        <=  0;
      cache_intf.wr_sample.re <=  0;
      cache_intf.wr_sample.im <=  0;
    end
    else
    begin
      case(fsm_pstate)

        IDLE_S  :
        begin
          cache_intf.wr_en    <=  0;
          cache_intf.rd_en    <=  0;
        end

        DECIMATE_WINDOW_S :
        begin
          cache_intf.wr_en    <=  but_intf.res_rdy  & ~pst_vec_f[0];
          cache_intf.wr_sample<=  but_intf.res;

          cache_intf.rd_en    <=  decimate_ovr_c;
        end

        FFT_S :
        begin
          cache_intf.rd_en    <=  fft_wr_ovr_c  ? 1'b1  : ~wait_for_end_f;

          cache_intf.wr_en    <=  but_intf.res_rdy;
          cache_intf.wr_sample<=  but_intf.res;
        end

        CORDIC_S  :
        begin
          cache_intf.rd_en    <=  cordic_ovr_c  | (pst_vec_f[3] & ~wait_for_end_f);

          cache_intf.wr_en    <=  cordic_ram_intf.rd_valid;
          cache_intf.wr_sample.re <=  cache_intf.rd_sample.re;
          cache_intf.wr_sample.im <=  {{P_16B_W{1'b0}}, cordic_ram_intf.rdata};
        end

        ABS_S :
        begin
          cache_intf.rd_en    <=  div_res_almost_done_w & ~wait_for_end_f;

          cache_intf.wr_en    <=  div_res_rdy_w;
          cache_intf.wr_sample.re <=  div_res_q_norm_c;
          cache_intf.wr_sample.im <=  0;
        end
      endcase
    end
  end

  assign  cache_intf.waddr      = sample_wcntr_f;
  assign  cache_intf.raddr      = sample_rcntr_f;

  assign  cache_intf.hst_addr   = lb_intf.addr[7:0];
  assign  cache_intf.hst_wr_data= lb_intf.wr_data;
  assign  cache_intf.hst_wr_en  = (lb_intf.addr[P_LB_ADDR_W-1 -:  4]  ==  FGYRUS_FFT_CACHE_RAM_CODE)  ? lb_intf.wr_en : 1'b0;
  assign  cache_intf.hst_rd_en  = 0;
  assign  cache_intf.fft_done   = (fsm_pstate ==  ABS_S)  ? abs_ovr_c : 1'b0;


  /*  Twiddle RAM Address Logic */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : twdl_ram_addr_logic
    if(~cr_intf.rst_sync_l)
    begin
      twdl_addr_f             <= 1;
    end
    else
    begin
      case(fsm_pstate)

        FFT_S :
        begin
          twdl_addr_f         <=  (fft_stage_rd_ovr_c & fft_stage_rd_f[P_NUM_FFT_STAGES-1]) ? 1
                                    : twdl_addr_f  + wrap_inc_fft_rcntr_c;
        end

        default :
        begin
          twdl_addr_f         <=  1;
        end

      endcase
    end
  end

  assign  twdl_ram_intf.addr  = (fgyrus_mode_f  ==  CONFIG) ? lb_intf.addr[6:0] : twdl_addr_f;
  assign  twdl_ram_intf.rden  = (fsm_pstate ==  FFT_S)  ? ~wait_for_end_f : 1'b0;
  assign  twdl_ram_intf.wren  = (lb_intf.addr[P_LB_ADDR_W-1 -:  4]  ==  FGYRUS_TWDLE_RAM_CODE)  ? lb_intf.wr_en : 1'b0;
  assign  twdl_ram_intf.wdata = lb_intf.wr_data;


  /*  Divider Feeder Pipe */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : div_feeder_logic
    if(~cr_intf.rst_sync_l)
    begin
      div_load_f              <=  0;
      div_n_f                 <=  0;
      div_d_f                 <=  0;
      div_norm_f              <=  0;
      div_d_is_null_f         <=  0;
    end
    else
    begin
      if(fsm_pstate ==  IDLE_S)
      begin
        div_load_f            <=  0;
        div_norm_f            <=  0;
        div_d_is_null_f       <=  0;
      end
      else
      begin
        div_load_f            <=  pst_vec_f[2];

        if(div_d_is_null_f)
        begin
          div_d_is_null_f     <=  ~div_res_rdy_w;
        end
        else if(pst_vec_f[1])
        begin
          div_d_is_null_f     <=  ~(|div_d_f);
        end

        if(div_norm_f)
        begin
          div_norm_f          <=  ~div_res_rdy_w;
        end
        else if(pst_vec_f[1])
        begin
          div_norm_f          <=  ~(|div_n_f[P_DIV_W-1:P_16B_W]);
        end
      end

      if((fsm_pstate  ==  CORDIC_S) | (fsm_pstate ==  ABS_S))
      begin
        case(1'b1)  //synthesis full_case parallel_case

          cache_intf.rd_valid : //register the numerator & denominator
          begin
            div_n_f           <=  (fsm_pstate ==  CORDIC_S) ? cache_intf.rd_sample.im : cache_intf.rd_sample.re;
            div_d_f           <=  (fsm_pstate ==  CORDIC_S) ? cache_intf.rd_sample.re : cache_intf.rd_sample.im;
          end

          pst_vec_f[0]  : //convert to positive integer
          begin
            div_n_f           <=  div_n_f[P_DIV_W-1]  ? ~div_n_f  + 1'b1  : div_n_f;
            div_d_f           <=  div_d_f[P_DIV_W-1]  ? ~div_d_f  + 1'b1  : div_d_f;
          end

          pst_vec_f[2]  : //normalise numerator
          begin
            div_n_f           <=  div_norm_f  ? {div_n_f[P_16B_W-1:0],{P_16B_W{1'b0}}}  : div_norm_f;
          end

        endcase
      end
    end
  end

  //Normalise the div result
  always_comb
  begin : div_res_norm_logic
    if(fsm_pstate ==  ABS_S)  //Here, the final result has to be multiplied by 16b
    begin                     //If its already normalized during loading, leave as is
      div_res_q_norm_c  = div_norm_f  ? div_res_q_w : {div_res_q_w[P_16B_W-1:0],  {P_16B_W{1'b0}}};
    end
    else
    begin
      div_res_q_norm_c  = div_norm_f  ? {{P_16B_W{1'b0}}, div_res_q_w[P_DIV_W-1:P_16B_W]} : div_res_q_w;
    end
  end

  /*  Cordic RAM Address logic  */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : cordic_ram_addr_logic
    if(~cr_intf.rst_sync_l)
    begin
      cordic_addr_f           <=  0;
      cordic_ram_intf.rden    <=  0;
    end
    else
    begin
      if((fsm_pstate ==  CORDIC_S) & div_res_rdy_w)
      begin
        cordic_addr_f         <=  (div_d_is_null_f  | (|div_res_q_norm_c[P_DIV_W-1:8]))  ? 8'hff //infinity case
                                                                                    : div_res_q_norm_c[7:0];
      end

      cordic_ram_intf.rden    <=  (fsm_pstate ==  CORDIC_S) ? div_res_rdy_w : 1'b0;
    end
  end

  assign  cordic_ram_intf.addr  = (fgyrus_mode_f  ==  CONFIG) ? lb_intf.addr[7:0] : cordic_addr_f;
  assign  cordic_ram_intf.wren  = (lb_intf.addr[P_LB_ADDR_W-1 -:  4]  ==  FGYRUS_CORDIC_RAM_CODE) ? lb_intf.wr_en : 1'b0;
  assign  cordic_ram_intf.wdata = lb_intf.wr_data[P_CORDIC_RAM_DATA_W-1:0];

  //Check for end of CORDIC & ABS stages
  assign  cordic_ovr_c  = (&cache_intf.waddr)  & cache_intf.wr_en;
  assign  abs_ovr_c     = cordic_ovr_c;


  /* Instantiate divider module */
  divider_rad4    div_rad4_inst
  (
    .clk          (cr_intf.clk_ir),
    .rst          (~cr_intf.rst_sync_l),
    .load         (div_load_f),
    .n            (div_n_f),
    .d            (div_d_f),
    .q            (div_res_q_w),
    .r            (div_res_r_w),
    .ready        (div_res_rdy_w),
    .almost_done  (div_res_almost_done_w)
  );

  defparam  div_rad4_inst.WIDTH_N = P_DIV_W;
  defparam  div_rad4_inst.WIDTH_D = P_DIV_W;

endmodule // syn_fgyrus_fsm
