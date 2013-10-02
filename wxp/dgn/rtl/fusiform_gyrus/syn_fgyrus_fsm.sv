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
  import  syn_global_pkh::*;
  import  syn_fft_pkg::*;

  parameter P_LB_DATA_W         = P_32B_W;
  parameter P_LB_ADDR_W         = 12;

  parameter P_NUM_SAMPLES       = 128;
  localparam  P_SAMPLE_CNTR_W   = $clog2(P_NUM_SAMPLES*2);
  parameter P_WIN_RAM_DATA_W    = P_32B_W;
  parameter P_TWDL_RAM_DATA_W   = P_32B_W;
  parameter P_CORDIC_RAM_DATA_W = P_16B_W;
  parameter P_PST_VEC_W         = 8;
  parameter P_MEM_RD_DEL        = 2;
  parameter P_BUT_DEL           = 4;
  localparam  P_DEC_WIN_PIPE_L  = P_MEM_RD_DEL+1+P_BUT_DEL+1;

  `include  "syn_fgyrus_reg_map.sv"

  typedef enum  logic {NORMAL=0,CONFIG=1} fgyrus_mode_t;

//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------
  logic                       fgyrus_en_f;
  fgyrus_mode_t               fgyrus_mode_f;
  logic [3:0]                 fgyrus_post_norm_f;
  logic [7:0]                 fgyrus_config_addr_f;
  logic [P_SAMPLE_CNTR_W-1:0] fgyrus_cache_addr_f;

  logic [P_PST_VEC_W-1:0]     pst_vec_f;
  logic                       wait_for_end_f;
  logic [P_SAMPLE_CNTR_W-1:0] sample_rcntr_f;
  logic [P_SAMPLE_CNTR_W-1:0] sample_wcntr_f;


  genvar  i;

//----------------------- Internal Wire Declarations ----------------------
  logic                       fgyrus_busy_c;

  logic [P_SAMPLE_CNTR_W-2:0] sample_rcntr_rev_w;
  logic                       decimate_ovr_c;

//----------------------- Internal Interface Declarations -----------------


//----------------------- FSM Declarations --------------------------------
enum  logic [2:0] { IDLE_S=0,
                    DECIMATE_WINDOW_S,
                    FFT_S,
                    CORDIC_S,
                    ABS_S,
                  } fsm_pstate, next_state;


//----------------------- Start of Code -----------------------------------

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
      fgyrus_config_addr_f    <=  0;
      fgyrus_cache_addr_f     <=  0;
    end
    else
    begin
      if(lb_intf.wr_en)
      begin
        fgyrus_en_f           <=  (lb_intf.addr ==  {FGYRUS_REG_CODE,FGYRUS_CONTROL_REG_ADDR})  ? lb_intf.wr_data[0]  : fgyrus_en_f;

        fgyrus_mode_f         <=  (lb_intf.addr ==  {FGYRUS_REG_CODE,FGYRUS_CONTROL_REG_ADDR})  ? fgyrus_mode_t'(lb_intf.wr_data[1])  : fgyrus_mode_f;

        fgyrus_post_norm_f    <=  (lb_intf.addr ==  {FGYRUS_REG_CODE,FGYRUS_POST_NORM_REG_ADDR})? lb_intf.wr_data[3:0]: fgyrus_post_norm_f;

        fgyrus_config_addr_f  <=  (lb_intf.addr ==  {FGYRUS_REG_CODE,FGYRUS_CONFIG_ADDR})       ? lb_intf.wr_data[7:0]: fgyrus_config_addr_f;

        fgyrus_cache_addr_f   <=  (lb_intf.addr ==  {FGYRUS_REG_CODE,FGYRUS_FFT_CACHE_ADDR}     ? lb_intf.wr_data[P_SAMPLE_CNTR_W-1:0]  : fgyrus_cache_addr_f;
      end

      lb_intf.wr_valid        <=  lb_intf.wr_en;

      case(lb_intf.addr[P_LB_ADDR_W-1  -:  4])

        FGYRUS_REG_CODE :
        begin
          case(lb_intf.addr[7:0])

            FGYRUS_CONTROL_REG_ADDR   : lb_intf.rd_data <=  {{P_LB_DATA_W-2{1'b0}}, fgyrus_mode_f,fgyrus_en_f};
            FGYRUS_STATUS_REG_ADDR    : lb_intf.rd_data <=  {{P_LB_DATA_W-1{1'b0}}, fgyrus_busy_c};
            FGYRUS_POST_NORM_REG_ADDR : lb_intf.rd_data <=  {{P_LB_DATA_W-4{1'b0}}, fgyrus_post_norm_f};
            FGYRUS_CONFIG_ADDR        : lb_intf.rd_data <=  {{P_LB_DATA_W-8{1'b0}}, fgyrus_config_addr_f};
            default                   : lb_intf.rd_data <=  'hdeadbabe;

          endcase
        end

        FGYRUS_FFT_CACHE_RAM_CODE :
          lb_intf.rd_data     <=  cache_intf.hst_rd_data;

        FGYRUS_TWDLE_RAM_CODE :

        FGYRUS_CORDIC_RAM_CODE  :

        FGYRUS_WIN_RAM_CODE :
          lb_intf.rd_data     <=  win_ram_intf.rdata;

        default  : lb_intf.rd_data    <=  'hdeadbabe;
      endcase

      lb_intf.rd_valid        <=  lb_intf.rd_en;
    end
  end

  //Check if FSM is busy or not
  assign  fgyrus_busy_c = (fsm_pstate ==  IDLE_S) ? : 1'b0  : 1'b1;


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

      end

      CORDIC_S  :
      begin

      end

      ABS_S :
      begin

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
          pst_vec_f[0]        <=  ~pst_vec_f[0];
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
            wait_for_end_f    <=  (&sample_rcntr_f) ? 1'b1  : 1'b0;
          end

          sample_wcntr_f      <=  sample_wcntr_f  + (but_intf.res_rdy & pst_vec_f[0]);  //to be checked !!!!!!!!!
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
  assign  pcm_rchnnl_intf.addr    = sample_rcntr_rev_w;
  assign  pcm_rchnnl_intf.wr_data = 0;
  assign  pcm_rchnnl_intf.wren    = 0;
  assign  pcm_rchnnl_intf.rd_en   = ~pst_vec_f[0];
  assign  pcm_lchnnl_intf.addr    = sample_rcntr_rev_w;
  assign  pcm_lchnnl_intf.wr_data = 0;
  assign  pcm_lchnnl_intf.wren    = 0;
  assign  pcm_lchnnl_intf.rd_en   = ~pst_vec_f[0];

  /*  Window Mem Interface Logic  */
  assign  win_ram_intf.addr       = (fgyrus_mode_f  ==  CONFIG) ? fgyrus_config_addr_f[6:0] : sample_rcntr_rev_w;
  assign  win_ram_intf.wr_data    = lb_intf.wr_data;
  assign  win_ram_intf.wren       = (lb_intf.addr[P_LB_ADDR_W-1 -= 4] ==  FGYRUS_WIN_RAM_CODE)  ? lb_intf.wr_en : 1'b0;
  assign  win_ram_intf.rd_en      = ~pst_vec_f[0];

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
    end
    else
    begin
      case(fsm_pstate)

        IDLE_S  :
        begin
          but_intf.sample_rdy   <=  0;
        end

        DECIMATE_WINDOW_S :
        begin
          but_intf.sample_a.re  <=  0;
          but_intf.sample_a.im  <=  0;

          but_intf.sample_b.re  <=  sample_wcntr_f[P_SAMPLE_CNTR_W-1] ? pcm_rchnnl_intf.rdata : pcm_lchnnl_intf.rdata;
          but_intf.sample_b.im  <=  0;

          but_intf.twdl.re      <=  win_ram_intf.rdata;
          but_intf.twdl.im      <=  0;

          but_intf.sample_rdy   <=  win_ram_intf.rd_valid & pcm_lchnnl_intf.rd_valid  & pcm_rchnnl_intf.rd_valid;
        end

      endcase
    end
  end

  /*  FFT Cache Interface Logic */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : but_intf_logic
    if(~cr_intf.rst_sync_l)
    begin
      cache_intf.wr_en        <=  0;
      cache_intf.rd_en        <=  0;
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
          cache_intf.wr_en    <=  but_intf.res_rdy  & pst_vec_f[0]; //check!!!!!!!!!!!
        end
      endcase
    end
  end

  assign  cache_intf.wr_sample  = but_intf.res;
  assign  cache_intf.waddr      = sample_wcntr_f;
  assign  cache_intf.raddr      = sample_rcntr_f;

  assign  cache_intf.hst_addr   = fgyrus_cache_addr_f;
  assign  cache_intf.hst_wr_data= lb_intf.wr_data;
  assign  cache_intf.hst_wr_en  = (lb_intf.addr[P_LB_ADDR_W-1 -:  4]  ==  FGYRUS_FFT_CACHE_RAM_CODE)  ? lb_intf.wr_en : 1'b0;
  assign  cache_intf.hst_rd_en  = 0;


endmodule // syn_fgyrus_fsm
