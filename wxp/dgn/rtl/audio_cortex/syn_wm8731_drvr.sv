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
 -- Module Name       : syn_wm8731_drvr
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This module has logic for interfacing with the
                        ADC/DAC of WM8731 codec.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_wm8731_drvr (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf           cr_intf,      //Clock Reset Interface

  syn_acortex_lb_bus_intf         lb_intf,

  syn_wm8731_intf                 wm8731_intf,

  syn_pcm_xfr_intf                aud_cache_ingr_intf,  //slave, for DAC

  syn_pcm_xfr_intf                aud_cache_egr_intf    //master, for ADC

  //--------------------- Misc Ports (Logic)  -----------

                );

//----------------------- Global parameters Declarations ------------------
  import  syn_global_pkg::*;
  import  syn_audio_pkg::*;

  `include  "syn_acortex_reg_map.sv"

  parameter   P_LB_DATA_W           = P_16B_W;
  parameter   P_LB_ADDR_W           = P_8B_W;

  parameter   P_FS_DIV_VAL_W        = 11;
  parameter   P_BCLK_GEN_VEC_W      = P_8B_W;
  localparam  P_BCLK_GEN_MID_TAP    = P_BCLK_GEN_VEC_W  / 2;
  localparam  P_BIT_IDX_W           = $clog2(P_32B_W);

//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------
  logic                       adc_en_f;
  logic                       dac_en_f;
  logic [P_FS_DIV_VAL_W-1:0]  fs_div_val_f;
  bps_t                       bps_f;

  logic [P_BCLK_GEN_VEC_W-1:0]  bclk_gen_vec_f;

  logic [P_FS_DIV_VAL_W-1:0]  fs_cntr_f;

  logic [P_32B_W-1:0]         lpcm_shift_reg_f;
  logic [P_32B_W-1:0]         rpcm_shift_reg_f;
  logic [P_BIT_IDX_W-1:0]     bit_idx_f;

//----------------------- Internal Wire Declarations ----------------------
  logic                       drvr_fsm_idle_c;

  logic                       bclk_half_tck_w;
  logic                       bclk_full_tck_w;

  logic                       end_of_fs_c;

  logic                       last_bit_idx_c;
  logic                       end_of_channel_c;

//----------------------- Internal Interface Declarations -----------------


//----------------------- FSM Declarations --------------------------------
enum  logic [2:0] {
                    IDLE_S  = 3'd0,
                    START_S,
                    LCHANNEL_S,
                    RCHANNEL_S,
                    WAIT_FOR_FS_S
                  } fsm_pstate, next_state;


//----------------------- Start of Code -----------------------------------

  /*  Local Bus Logic */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : lb_logic
   if(~cr_intf.rst_sync_l)
   begin
     lb_intf.wmdrvr_wr_valid  <=  0;
     lb_intf.wmdrvr_rd_valid  <=  0;
     lb_intf.wmdrvr_rd_data   <=  0;

     adc_en_f                 <=  0;
     dac_en_f                 <=  0;
     fs_div_val_f             <=  0;
     bps_f                    <=  BPS_32;
   end
   else
   begin
     if(lb_intf.wmdrvr_wr_en)
     begin
       dac_en_f               <=  (lb_intf.wmdrvr_addr  ==  ACORTEX_WMDRVR_CTRL_REG_ADDR)   ? lb_intf.wmdrvr_wr_data[0] : dac_en_f;

       adc_en_f               <=  (lb_intf.wmdrvr_addr  ==  ACORTEX_WMDRVR_CTRL_REG_ADDR)   ? lb_intf.wmdrvr_wr_data[1] : adc_en_f;

       bps_f                  <=  (lb_intf.wmdrvr_addr  ==  ACORTEX_WMDRVR_CTRL_REG_ADDR)   ? bps_t'(lb_intf.wmdrvr_wr_data[2]) : bps_f;

       fs_div_val_f           <=  (lb_intf.wmdrvr_addr  ==  ACORTEX_WMDRVR_FS_DIV_REG_ADDR) ? lb_intf.wmdrvr_wr_data[P_FS_DIV_VAL_W-1:0]
                                                                                            : fs_div_val_f;
     end

     lb_intf.wmdrvr_wr_valid    <=  lb_intf.wmdrvr_wr_en;


     case(lb_intf.wmdrvr_addr)

       ACORTEX_WMDRVR_CTRL_REG_ADDR   : lb_intf.wmdrvr_rd_data  <=  {{P_LB_DATA_W-3{1'b0}},bps_f,adc_en_f,dac_en_f};

       ACORTEX_WMDRVR_STATUS_REG_ADDR : lb_intf.wmdrvr_rd_data  <=  {{P_LB_DATA_W-1{1'b0}},drvr_fsm_idle_c};

       ACORTEX_WMDRVR_FS_DIV_REG_ADDR : lb_intf.wmdrvr_rd_data  <=  {{P_LB_DATA_W-P_FS_DIV_VAL_W{1'b0}},fs_div_val_f};

       default  : lb_intf.wmdrvr_rd_data  <=  'hdead;
     endcase

     lb_intf.wmdrvr_rd_valid    <=  lb_intf.wmdrvr_rd_en;
   end
 end

  /*
    * BCLK Generation logic
    * BCLK freq is fixed @6.25MHz even though parameterized
    * BCLK freq can be calculated as (CLK_FREQ / P_BCLK_GEN_VEC_W)
  */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : bclk_gen_logic
    if(~cr_intf.rst_sync_l)
    begin
      wm8731_intf.bclk     <=  0;

      bclk_gen_vec_f          <=  {{P_BCLK_GEN_VEC_W-1{1'b0}},  1'b1};  //one hot
    end
    else
    begin
      if(drvr_fsm_idle_c)
      begin
        bclk_gen_vec_f        <=  {{P_BCLK_GEN_VEC_W-1{1'b0}},  1'b1};  //one hot
      end
      else
      begin
        bclk_gen_vec_f        <=  {bclk_gen_vec_f[P_BCLK_GEN_VEC_W-2:0],bclk_gen_vec_f[P_BCLK_GEN_VEC_W-1]};
      end

      if(~adc_en_f  & ~dac_en_f)
      begin
        wm8731_intf.bclk   <=  0;
      end
      else if(bclk_half_tck_w)
      begin
        wm8731_intf.bclk   <=  1'b1;
      end
      else if(bclk_full_tck_w)
      begin
        wm8731_intf.bclk   <=  1'b0;
      end
      else
      begin
        wm8731_intf.bclk   <=  wm8731_intf.bclk;
      end
    end
  end

  //Tap the half & full ticks of BCLK
  assign  bclk_half_tck_w = bclk_gen_vec_f[P_BCLK_GEN_MID_TAP-1];
  assign  bclk_full_tck_w = bclk_gen_vec_f[P_BCLK_GEN_VEC_W-1];

  /*  Sequential part of FSM  */
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

  /*  Combinational part of FSM */
  always_comb
  begin : fsm_comb_logic
    next_state  =   fsm_pstate;

    case(fsm_pstate)

      IDLE_S  :
      begin
        if(dac_en_f | adc_en_f)
        begin
          next_state          =   START_S;
        end
      end

      START_S :
      begin
        if(bclk_full_tck_w)
        begin
          next_state          =   LCHANNEL_S;
        end
      end

      LCHANNEL_S  :
      begin
        if(end_of_channel_c)
        begin
          next_state          =   RCHANNEL_S;
        end
      end

      RCHANNEL_S  :
      begin
        if(end_of_channel_c)
        begin
          next_state          =   WAIT_FOR_FS_S;
        end
      end

      WAIT_FOR_FS_S :
      begin
        if(end_of_fs_c)
        begin
          if(dac_en_f | adc_en_f)
          begin
            next_state        =   START_S;
          end
          else
          begin
            next_state        =   IDLE_S;
          end
        end
      end

    endcase
  end

  //Check if full channel has been processed
  assign  end_of_channel_c  = last_bit_idx_c  & bclk_full_tck_w;

  //Check if the fsm is in IDLE state or not
  assign  drvr_fsm_idle_c = (fsm_pstate ==  IDLE_S) ? 1'b1  : 1'b0;

  /*
    * FS Counter Logic
  */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : fs_cntr_logic
    if(~cr_intf.rst_sync_l)
    begin
      fs_cntr_f               <=  0;
    end
    else
    begin
      if(drvr_fsm_idle_c  | end_of_fs_c)
      begin
        fs_cntr_f             <=  0;
      end
      else
      begin
        fs_cntr_f             <=  fs_cntr_f + bclk_full_tck_w;
      end
    end
  end

  //Check if the fs_cntr has reached the max value
  assign  end_of_fs_c = (fs_cntr_f  ==  fs_div_val_f) ? 1'b1  : 1'b0;

  /*
    * PCM Data Shift Register logic
    * Same register set is used to hold both DAC & ADC data
  */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : shift_reg_logic
    if(~cr_intf.rst_sync_l)
    begin
      lpcm_shift_reg_f        <=  0;
      rpcm_shift_reg_f        <=  0;
      bit_idx_f               <=  0;
    end
    else
    begin
      if(aud_cache_ingr_intf.ack)
      begin
        lpcm_shift_reg_f      <=  aud_cache_ingr_intf.pcm_data.lchnnl;
        rpcm_shift_reg_f      <=  aud_cache_ingr_intf.pcm_data.rchnnl;
      end
      //else if(aud_cache_ingr_intf.pcm_data_valid)
      else
      begin
        lpcm_shift_reg_f      <=  (fsm_pstate ==  LCHANNEL_S) & bclk_half_tck_w ? {lpcm_shift_reg_f[P_32B_W-2:0],wm8731_intf.adc_dat} : lpcm_shift_reg_f;
        rpcm_shift_reg_f      <=  (fsm_pstate ==  RCHANNEL_S) & bclk_half_tck_w ? {rpcm_shift_reg_f[P_32B_W-2:0],wm8731_intf.adc_dat} : rpcm_shift_reg_f;
      end

      if((fsm_pstate  ==  LCHANNEL_S) | (fsm_pstate == RCHANNEL_S))
      begin
        bit_idx_f             <=  bit_idx_f + bclk_full_tck_w;
      end
      else
      begin
        bit_idx_f             <=  0;
      end
    end
  end

  //Check if the last bit is being processed
  assign  last_bit_idx_c  = (bps_f  ==  BPS_32) ? &bit_idx_f[4:0] : &bit_idx_f[3:0];

  //Assignments to Audio Cache interfaces
  assign  aud_cache_ingr_intf.ack = (fsm_pstate ==  START_S)  ? aud_cache_ingr_intf.pcm_data_valid  & dac_en_f  & bclk_half_tck_w : 1'b0;

  assign  aud_cache_egr_intf.pcm_data_valid   = (fsm_pstate ==  RCHANNEL_S) ? adc_en_f  & end_of_channel_c  : 1'b0;
  assign  aud_cache_egr_intf.pcm_data.lchnnl  = (bps_f  ==  BPS_16) ? {{P_16B_W{lpcm_shift_reg_f[P_16B_W-1]}},  lpcm_shift_reg_f[P_16B_W-1:0]}  : lpcm_shift_reg_f;
  assign  aud_cache_egr_intf.pcm_data.rchnnl  = (bps_f  ==  BPS_16) ? {{P_16B_W{rpcm_shift_reg_f[P_16B_W-1]}},  rpcm_shift_reg_f[P_16B_W-1:0]}  : rpcm_shift_reg_f;

  /*
    * DAC Output Logic
  */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : dac_output_logic
    if(~cr_intf.rst_sync_l)
    begin
      wm8731_intf.adc_lrc     <=  0;
      wm8731_intf.dac_lrc     <=  0;
      wm8731_intf.dac_dat     <=  0;
    end
    else
    begin
      wm8731_intf.adc_lrc     <=  (fsm_pstate ==  START_S)  ? adc_en_f  : 1'b0;

      wm8731_intf.dac_lrc     <=  (fsm_pstate ==  START_S)  ? dac_en_f  & aud_cache_ingr_intf.pcm_data_valid  : 1'b0;

      if(aud_cache_ingr_intf.pcm_data_valid & bclk_full_tck_w)
      begin
        case(fsm_pstate)

          START_S :
          begin
            wm8731_intf.dac_dat   <=  (bps_f  ==  BPS_16) ? lpcm_shift_reg_f[P_16B_W-1] : lpcm_shift_reg_f[P_32B_W-1];
          end

          LCHANNEL_S  :
          begin
            if(end_of_channel_c)
            begin
              wm8731_intf.dac_dat <=  (bps_f  ==  BPS_16) ? rpcm_shift_reg_f[P_16B_W-1] : rpcm_shift_reg_f[P_32B_W-1];
            end
            else
            begin
              wm8731_intf.dac_dat <=  (bps_f  ==  BPS_16) ? lpcm_shift_reg_f[P_16B_W-1] : lpcm_shift_reg_f[P_32B_W-1];
            end
          end

          RCHANNEL_S  :
          begin
            if(end_of_channel_c)
            begin
              wm8731_intf.dac_dat <=  0;
            end
            else
            begin
              wm8731_intf.dac_dat <=  (bps_f  ==  BPS_16) ? rpcm_shift_reg_f[P_16B_W-1] : rpcm_shift_reg_f[P_32B_W-1];
            end
          end

          default : wm8731_intf.dac_dat <=  0;

        endcase
      end
    end
  end

endmodule // syn_wm8731_drvr
