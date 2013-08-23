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
 -- Module Name       : syn_audio_cache
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This block maintains buffers for storing PCM data
                        & providing access to WMDRVR & FGYRUS blocks.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_audio_cache (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf           cr_intf,      //Clock Reset Interface

  syn_acortex_lb_bus_intf         lb_intf,

  syn_pcm_xfr_intf                wmdrvr_ingr_intf,  //slave

  syn_pcm_xfr_intf                wmdrvr_egr_intf,   //master

  //Fgyrus side
  syn_clk_rst_sync_intf           fgyrus_cr_intf,    //Clock Reset Interface

  mem_intf                        fgyrus_mem_intf,   //slave


  //--------------------- Misc Ports (Logic)  -----------
  fgyrus_pcm_data_rdy_oh

                );

//----------------------- Global parameters Declarations ------------------
  import  syn_global_pkg::*;
  import  syn_audio_pkg::*;

  `include  "syn_acortex_reg_map.sv"

  parameter   P_LB_DATA_W           = P_32B_W;
  parameter   P_LB_ADDR_W           = P_8B_W;

  parameter   P_PCM_RAM_DATA_W      = P_32B_W;
  parameter   P_PCM_RAM_ADDR_W      = 7;

//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------
  output                      fgyrus_pcm_data_rdy_oh;

//----------------------- Output Register Declaration ---------------------
  logic                       fgyrus_pcm_data_rdy_oh;


//----------------------- Internal Register Declarations ------------------
  acache_mode_t               acache_mode_f;
  logic                       start_cap_f;

  logic [P_PCM_RAM_ADDR_W-1:0]  ingr_addr_f;
  logic [P_PCM_RAM_ADDR_W-1:0]  egr_addr_f;
  logic                         bffr_sel_1_n_2_f;
  logic                         ingr_addr_inc_en_f;
  logic                         egr_data_rdy_f;


//----------------------- Internal Wire Declarations ----------------------
  logic                         switch_bffrs_c;

  logic [P_PCM_RAM_ADDR_W-1:0]  pbffr_lchnnl_1a_addr_c;
  logic [P_PCM_RAM_DATA_W-1:0]  pbffr_lchnnl_1a_wdata_c;
  logic                         pbffr_lchnnl_1a_wren_c;
  logic [P_PCM_RAM_DATA_W-1:0]  pbffr_lchnnl_1a_rdata_w;

  logic [P_PCM_RAM_ADDR_W-1:0]  pbffr_lchnnl_1b_addr_c;
  logic [P_PCM_RAM_DATA_W-1:0]  pbffr_lchnnl_1b_wdata_c;
  logic                         pbffr_lchnnl_1b_wren_c;
  logic [P_PCM_RAM_DATA_W-1:0]  pbffr_lchnnl_1b_rdata_w;

  logic [P_PCM_RAM_ADDR_W-1:0]  pbffr_rchnnl_1a_addr_c;
  logic [P_PCM_RAM_DATA_W-1:0]  pbffr_rchnnl_1a_wdata_c;
  logic                         pbffr_rchnnl_1a_wren_c;
  logic [P_PCM_RAM_DATA_W-1:0]  pbffr_rchnnl_1a_rdata_w;

  logic [P_PCM_RAM_ADDR_W-1:0]  pbffr_rchnnl_1b_addr_c;
  logic [P_PCM_RAM_DATA_W-1:0]  pbffr_rchnnl_1b_wdata_c;
  logic                         pbffr_rchnnl_1b_wren_c;
  logic [P_PCM_RAM_DATA_W-1:0]  pbffr_rchnnl_1b_rdata_w;

  logic [P_PCM_RAM_ADDR_W-1:0]  pbffr_lchnnl_2a_addr_c;
  logic [P_PCM_RAM_DATA_W-1:0]  pbffr_lchnnl_2a_wdata_c;
  logic                         pbffr_lchnnl_2a_wren_c;
  logic [P_PCM_RAM_DATA_W-1:0]  pbffr_lchnnl_2a_rdata_w;

  logic [P_PCM_RAM_ADDR_W-1:0]  pbffr_lchnnl_2b_addr_c;
  logic [P_PCM_RAM_DATA_W-1:0]  pbffr_lchnnl_2b_wdata_c;
  logic                         pbffr_lchnnl_2b_wren_c;
  logic [P_PCM_RAM_DATA_W-1:0]  pbffr_lchnnl_2b_rdata_w;

  logic [P_PCM_RAM_ADDR_W-1:0]  pbffr_rchnnl_2a_addr_c;
  logic [P_PCM_RAM_DATA_W-1:0]  pbffr_rchnnl_2a_wdata_c;
  logic                         pbffr_rchnnl_2a_wren_c;
  logic [P_PCM_RAM_DATA_W-1:0]  pbffr_rchnnl_2a_rdata_w;

  logic [P_PCM_RAM_ADDR_W-1:0]  pbffr_rchnnl_2b_addr_c;
  logic [P_PCM_RAM_DATA_W-1:0]  pbffr_rchnnl_2b_wdata_c;
  logic                         pbffr_rchnnl_2b_wren_c;
  logic [P_PCM_RAM_DATA_W-1:0]  pbffr_rchnnl_2b_rdata_w;

//----------------------- Internal Interface Declarations -----------------



//----------------------- Start of Code -----------------------------------

  /*  Local Bus Logic */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : lb_logic
    if(~cr_intf.rst_sync_l)
    begin
      lb_intf.acache_wr_valid <=  0;
      lb_intf.acache_rd_valid <=  0;
      lb_intf.acache_rd_data  <=  0;

      acache_mode_f           <=  NORMAL;
      start_cap_f             <=  0;
    end
    else
    begin
      if(lb_intf.acache_wr_en)
      begin
        acache_mode_f         <=  (lb_intf.acache_addr  ==  ACORTEX_ACACHE_CTRL_REG_ADDR) ? acache_mode_t'(lb_intf.acache_wr_data[0])
                                                                                          : acache_mode_f;

        start_cap_f           <=  (lb_intf.acache_addr  ==  ACORTEX_ACACHE_CTRL_REG_ADDR) ? lb_intf.acache_wr_data[0] : 1'b0;
      end
      else
      begin
        acache_mode_f         <=  acache_mode_f;
        start_cap_f           <=  1'b0;
      end

      lb_intf.acache_wr_valid <=  lb_intf.acache_wr_en;


      case(lb_intf.acache_addr)

        ACORTEX_ACACHE_CTRL_REG_ADDR  : lb_intf.acache_rd_data  <=  {{P_LB_DATA_W-1{1'b0}},  acache_mode_f};

        default  : lb_intf.acache_rd_data <=  'hdeadbabe;
      endcase

      lb_intf.acache_rd_valid <=  lb_intf.acache_rd_en;
    end
  end

  /*  Address logic */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : addr_logic
    if(~cr_intf.rst_sync_l)
    begin
      ingr_addr_f             <=  0;
      egr_addr_f              <=  0;

      bffr_sel_1_n_2_f        <=  1'b1;  //Start with 1
      ingr_addr_inc_en_f      <=  1'b1;
      egr_data_rdy_f          <=  0;

      fgyrus_pcm_data_rdy_oh  <=  0;
    end
    else
    begin
      ingr_addr_f             <=  start_cap_f ? 'd0 : ingr_addr_f + (wmdrvr_ingr_intf.pcm_data_valid  & ingr_addr_inc_en_f);

      egr_addr_f              <=  egr_addr_f  + (wmdrvr_egr_intf.ack  & egr_data_rdy_f);

      bffr_sel_1_n_2_f        <=  switch_bffrs_c  ? ~bffr_sel_1_n_2_f : bffr_sel_1_n_2_f;

      if(acache_mode_f  ==  NORMAL)
      begin
        ingr_addr_inc_en_f    <=  1'b1;
      end
      else  //CAPTURE
      begin
        if(~ingr_addr_inc_en_f)
        begin
          ingr_addr_inc_en_f  <=  start_cap_f;
        end
        else
        begin
          ingr_addr_inc_en_f  <=  ~switch_bffrs_c;
        end
      end

      if(acache_mode_f  ==  NORMAL)
      begin
        egr_data_rdy_f        <=  egr_data_rdy_f  | switch_bffrs_c;
      end
      else  //CAPTURE
      begin
        egr_data_rdy_f        <=  0;
      end

      fgyrus_pcm_data_rdy_oh  <=  (acache_mode_f  ==  NORMAL) ? switch_bffrs_c  : 1'b0;
    end
  end

  //Check when to switch buffers
  assign switch_bffrs_c = (ingr_addr_f  ==  {P_PCM_RAM_ADDR_W{1'b1}}  ? wmdrvr_ingr_intf.pcm_data_valid : 1'b0;


  //Mux Port A signals
  always_comb
  begin : port_a_mux_logic
    if(bffr_sel_1_n_2_f)
    begin
      //Buffer 1 is used by ingress & buffer 2 by egress
      pbffr_lchnnl_1a_addr_c          =   ingr_addr_f;
      pbffr_lchnnl_1a_wdata_c         =   wmdrvr_ingr_intf.pcm_data;
      pbffr_lchnnl_1a_wren_c          =   wmdrvr_ingr_intf.pcm_data_valid;
      wmdrvr_ingr_intf.ack            =   wmdrvr_ingr_intf.pcm_data_valid;

      pbffr_lchnnl_2a_addr_c          =   egr_addr_f;
      pbffr_lchnnl_2a_wdata_c         =   0;
      pbffr_lchnnl_2a_wren_c          =   0;
      wmdrvr_egr_intf.pcm_data        =   pbffr_lchnnl_2a_rdata_w;
      wmdrvr_egr_intf.pcm_data_valid  =   1'b1;
    end
    else
    begin
      //Buffer 2 is used by ingress & buffer 1 by egress
      pbffr_lchnnl_2a_addr_c          =   ingr_addr_f;
      pbffr_lchnnl_2a_wdata_c         =   wmdrvr_ingr_intf.pcm_data;
      pbffr_lchnnl_2a_wren_c          =   wmdrvr_ingr_intf.pcm_data_valid;
      wmdrvr_ingr_intf.ack            =   wmdrvr_ingr_intf.pcm_data_valid;

      pbffr_lchnnl_1a_addr_c          =   egr_addr_f;
      pbffr_lchnnl_1a_wdata_c         =   0;
      pbffr_lchnnl_1a_wren_c          =   0;
      wmdrvr_egr_intf.pcm_data        =   pbffr_lchnnl_1a_rdata_w;
      wmdrvr_egr_intf.pcm_data_valid  =   1'b1;
    end
  end

  //Mux Port B signals
  always_comb
  begin : port_b_mux_logic
    pbffr_lchnnl_1b_addr_c            =   fgyrus_mem_intf.addr;
    pbffr_lchnnl_1b_wdata_c           =   fgyrus_mem_intf.wdata;
    pbffr_lchnnl_1b_wren_c            =   fgyrus_mem_intf.wren;

    pbffr_lchnnl_2b_addr_c            =   fgyrus_mem_intf.addr;
    pbffr_lchnnl_2b_wdata_c           =   fgyrus_mem_intf.wdata;
    pbffr_lchnnl_2b_wren_c            =   fgyrus_mem_intf.wren;

    if(~bffr_sel_1_n_2_f)
    begin
      //Buffer 1 is used by fgyrus
      fgyrus_mem_intf.rdata           =   pbffr_lchnnl_1b_rdata_w;
    end
    else
    begin
      //Buffer 2 is used by fgyrus
      fgyrus_mem_intf.rdata           =   pbffr_lchnnl_2b_rdata_w;
    end
  end

  /*  Instantiate PCM Buffer set 1  */
  pcm_sample_ram  pcm_bffr_lchnnl_1_inst
  (
    .aclr_a       (~cr_intf.rst_il),
    .clock_a      (cr_intf.clk_ir),
    .address_a    (pbffr_lchnnl_1a_addr_c),
    .data_a       (pbffr_lchnnl_1a_wdata_c),
    .wren_a       (pbffr_lchnnl_1a_wren_c),
    .q_a          (pbffr_lchnnl_1a_rdata_w),

    .aclr_b       (~fgyrus_cr_intf.rst_il),
    .clock_b      (fgyrus_cr_intf.clk_ir),
    .address_b    (pbffr_lchnnl_1b_addr_c),
    .data_b       (pbffr_lchnnl_1b_wdata_c),
    .wren_b       (pbffr_lchnnl_1b_wren_c),
    .q_b          (pbffr_lchnnl_1b_rdata_w)
  );

  pcm_sample_ram  pcm_bffr_rchnnl_1_inst
  (
    .aclr_a       (~cr_intf.rst_il),
    .clock_a      (cr_intf.clk_ir),
    .address_a    (pbffr_rchnnl_1a_addr_c),
    .data_a       (pbffr_rchnnl_1a_wdata_c),
    .wren_a       (pbffr_rchnnl_1a_wren_c),
    .q_a          (pbffr_rchnnl_1a_rdata_w),

    .aclr_b       (~fgyrus_cr_intf.rst_il),
    .clock_b      (fgyrus_cr_intf.clk_ir),
    .address_b    (pbffr_rchnnl_1b_addr_c),
    .data_b       (pbffr_rchnnl_1b_wdata_c),
    .wren_b       (pbffr_rchnnl_1b_wren_c),
    .q_b          (pbffr_rchnnl_1b_rdata_w)
  );

  /*  Instantiate PCM Buffer set 2  */
  pcm_sample_ram  pcm_bffr_lchnnl_2_inst
  (
    .aclr_a       (~cr_intf.rst_il),
    .clock_a      (cr_intf.clk_ir),
    .address_a    (pbffr_lchnnl_2a_addr_c),
    .data_a       (pbffr_lchnnl_2a_wdata_c),
    .wren_a       (pbffr_lchnnl_2a_wren_c),
    .q_a          (pbffr_lchnnl_2a_rdata_w),

    .aclr_b       (~fgyrus_cr_intf.rst_il),
    .clock_b      (fgyrus_cr_intf.clk_ir),
    .address_b    (pbffr_lchnnl_2b_addr_c),
    .data_b       (pbffr_lchnnl_2b_wdata_c),
    .wren_b       (pbffr_lchnnl_2b_wren_c),
    .q_b          (pbffr_lchnnl_2b_rdata_w)
  );

  pcm_sample_ram  pcm_bffr_rchnnl_2_inst
  (
    .aclr_a       (~cr_intf.rst_il),
    .clock_a      (cr_intf.clk_ir),
    .address_a    (pbffr_rchnnl_2a_addr_c),
    .data_a       (pbffr_rchnnl_2a_wdata_c),
    .wren_a       (pbffr_rchnnl_2a_wren_c),
    .q_a          (pbffr_rchnnl_2a_rdata_w),

    .aclr_b       (~fgyrus_cr_intf.rst_il),
    .clock_b      (fgyrus_cr_intf.clk_ir),
    .address_b    (pbffr_rchnnl_2b_addr_c),
    .data_b       (pbffr_rchnnl_2b_wdata_c),
    .wren_b       (pbffr_rchnnl_2b_wren_c),
    .q_b          (pbffr_rchnnl_2b_rdata_w)
  );

endmodule // syn_audio_cache
