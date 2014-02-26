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

  mem_intf                        fgyrus_lchnnl_mem_intf,   //slave

  mem_intf                        fgyrus_rchnnl_mem_intf,   //slave

  //--------------------- Misc Ports (Logic)  -----------
  output  logic fgyrus_pcm_data_rdy_oh

                );

//----------------------- Global parameters Declarations ------------------
  import  syn_global_pkg::*;
  import  syn_audio_pkg::*;

  `include  "syn_acortex_reg_map.sv"

  parameter   P_LB_DATA_W           = P_32B_W;
  parameter   P_LB_ADDR_W           = P_8B_W;

  parameter   P_PCM_RAM_DATA_W      = P_32B_W;
  parameter   P_PCM_RAM_ADDR_W      = 7;

  parameter   P_RAM_RD_DELAY        = 2;

//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------
  //output                      fgyrus_pcm_data_rdy_oh;

//----------------------- Output Register Declaration ---------------------
  //logic                       fgyrus_pcm_data_rdy_oh;


//----------------------- Internal Register Declarations ------------------
  acache_mode_t               acache_mode_f;
  logic                       start_cap_f;
  logic                       cap_done_f;
  logic [P_PCM_RAM_ADDR_W:0]  cap_addr_f;

  logic [P_PCM_RAM_ADDR_W-1:0]  addr_f;
  logic                         addr_inc_en_f;

//----------------------- Internal Wire Declarations ----------------------
  logic                       host_rst_l_c;
  logic                       local_rst_l_c;

  logic                       switch_bffrs_c;

  logic                         adc_cap_wr_en_c;
  logic [P_PCM_RAM_DATA_W-1:0]  adc_lcap_rdata_w;
  logic [P_PCM_RAM_DATA_W-1:0]  adc_rcap_rdata_w;

//----------------------- Internal Interface Declarations -----------------
  syn_clk_rst_sync_intf       local_cr_intf(cr_intf.clk_ir,local_rst_l_c);
  mem_intf#(P_PCM_RAM_DATA_W,P_PCM_RAM_ADDR_W)  pcm_lmem_intf(cr_intf.clk_ir,local_rst_l_c);
  mem_intf#(P_PCM_RAM_DATA_W,P_PCM_RAM_ADDR_W)  pcm_rmem_intf(cr_intf.clk_ir,local_rst_l_c);


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
      cap_done_f              <=  0;
      cap_addr_f              <=  0;
    end
    else
    begin
      if(lb_intf.acache_wr_en)
      begin
        acache_mode_f         <=  (lb_intf.acache_addr  ==  ACORTEX_ACACHE_CTRL_REG_ADDR) ? acache_mode_t'(lb_intf.acache_wr_data[0])
                                                                                          : acache_mode_f;

        start_cap_f           <=  (lb_intf.acache_addr  ==  ACORTEX_ACACHE_CTRL_REG_ADDR) ? lb_intf.acache_wr_data[0] : 1'b0;

        cap_addr_f            <=  (lb_intf.acache_addr  ==  ACORTEX_ACACHE_CAP_NO_ADDR)   ? lb_intf.acache_wr_data[P_PCM_RAM_ADDR_W:0]
                                                                                          : cap_addr_f;
      end
      else
      begin
        acache_mode_f         <=  acache_mode_f;
        start_cap_f           <=  1'b0;
        cap_addr_f            <=  cap_addr_f;
      end

      lb_intf.acache_wr_valid <=  lb_intf.acache_wr_en;

      if(acache_mode_f  ==  CAPTURE)
      begin
        if(cap_done_f)
        begin
          cap_done_f          <=  ~start_cap_f;
        end
        else
        begin
          cap_done_f          <=  switch_bffrs_c;
        end
      end
      else
      begin
        cap_done_f            <=  0;
      end

      case(lb_intf.acache_addr)

        ACORTEX_ACACHE_CTRL_REG_ADDR  : lb_intf.acache_rd_data  <=  {{P_LB_DATA_W-1{1'b0}},  acache_mode_f};

        ACORTEX_ACACHE_STATUS_REG_ADDR: lb_intf.acache_rd_data  <=  {{P_LB_DATA_W-1{1'b0}},  cap_done_f};

        ACORTEX_ACACHE_CAP_NO_ADDR    : lb_intf.acache_rd_data  <=  {{P_LB_DATA_W-P_PCM_RAM_ADDR_W-1{1'b0}},  cap_addr_f};

        ACORTEX_ACACHE_CAP_DATA_ADDR  : lb_intf.acache_rd_data  <=  cap_addr_f[P_PCM_RAM_ADDR_W]  ?
                                                                      adc_rcap_rdata_w  : adc_lcap_rdata_w;

        default  : lb_intf.acache_rd_data <=  'hdeadbabe;
      endcase

      lb_intf.acache_rd_valid <=  lb_intf.acache_rd_en;
    end
  end

  //Host reset logic
  assign  host_rst_l_c  = (lb_intf.acache_addr  ==  ACORTEX_ACACHE_HST_RST_ADDR)  ? ~lb_intf.acache_wr_en : 1'b1;

  //combined reset logic
  assign  local_rst_l_c = cr_intf.rst_sync_l  & host_rst_l_c;


  /*
    * Address logic
  */
  always_ff@(posedge cr_intf.clk_ir, negedge local_rst_l_c)
  begin : addr_logic
    if(~local_rst_l_c)
    begin
      addr_f                  <=  0;
      addr_inc_en_f           <=  1;

      wmdrvr_egr_intf.pcm_data_valid  <=  0;
    end
    else
    begin
      addr_f                <=  addr_f  + (wmdrvr_ingr_intf.pcm_data_valid  & addr_inc_en_f);

      if(acache_mode_f  ==  NORMAL)
      begin
        addr_inc_en_f       <=  1;

        wmdrvr_egr_intf.pcm_data_valid  <=  wmdrvr_egr_intf.pcm_data_valid  | switch_bffrs_c;
      end
      else  //Capture
      begin
        wmdrvr_egr_intf.pcm_data_valid  <=  0;

        if(start_cap_f)
        begin
          addr_inc_en_f       <=  1;
        end
        else
        begin
          addr_inc_en_f       <=  addr_inc_en_f & ~switch_bffrs_c;
        end
      end
    end
  end

  assign  switch_bffrs_c  = (&addr_f) & wmdrvr_ingr_intf.pcm_data_valid;

  assign  wmdrvr_ingr_intf.ack  = wmdrvr_ingr_intf.pcm_data_valid;

  assign  pcm_lmem_intf.addr    = addr_f[P_PCM_RAM_ADDR_W-1:0];
  assign  pcm_lmem_intf.wdata   = wmdrvr_ingr_intf.pcm_data.lchnnl;
  assign  pcm_lmem_intf.wren    = wmdrvr_ingr_intf.pcm_data_valid & addr_inc_en_f;
  assign  pcm_lmem_intf.rden    = wmdrvr_egr_intf.ack;

  assign  pcm_rmem_intf.addr    = addr_f[P_PCM_RAM_ADDR_W-1:0];
  assign  pcm_rmem_intf.wdata   = wmdrvr_ingr_intf.pcm_data.rchnnl;
  assign  pcm_rmem_intf.wren    = wmdrvr_ingr_intf.pcm_data_valid & addr_inc_en_f;
  assign  pcm_rmem_intf.rden    = wmdrvr_egr_intf.ack;

  assign  wmdrvr_egr_intf.pcm_data.lchnnl = pcm_lmem_intf.rdata;
  assign  wmdrvr_egr_intf.pcm_data.rchnnl = pcm_rmem_intf.rdata;

  /*
    * Instantiate PCM Sample RAM
  */
  syn_pcm_sample_ram  pcm_sample_ram_inst
  (

    .acortex_cr_intf  (local_cr_intf.sync),
    .acortex_lmem_intf(pcm_lmem_intf.slave),
    .acortex_rmem_intf(pcm_rmem_intf.slave),

    .fgyrus_cr_intf   (fgyrus_cr_intf),
    .fgyrus_lmem_intf (fgyrus_lchnnl_mem_intf),
    .fgyrus_rmem_intf (fgyrus_rchnnl_mem_intf)

  );

  dd_sync   fgyrus_pcm_data_rdy_sync_inst
  (
    .clk_ir     (fgyrus_cr_intf.clk_ir),
    .rst_il     (fgyrus_cr_intf.rst_sync_l),

    .signal_id  (switch_bffrs_c),

    .signal_od  (fgyrus_pcm_data_rdy_oh)
  );


  assign  adc_cap_wr_en_c = (acache_mode_f  ==  CAPTURE)  ? wmdrvr_ingr_intf.pcm_data_valid & addr_inc_en_f
                                                          : 1'b0;

  ram_1xM4K_32bW_128D adc_lcap_ram_inst
  (
    .aclr         (~local_rst_l_c),
    .clock        (cr_intf.clk_ir),
    .data         (wmdrvr_ingr_intf.pcm_data.lchnnl),
    .rdaddress    (cap_addr_f[P_PCM_RAM_ADDR_W-1:0]),
    .wraddress    (addr_f),
    .wren         (adc_cap_wr_en_c),
    .q            (adc_lcap_rdata_w)
  );

  ram_1xM4K_32bW_128D adc_rcap_ram_inst
  (
    .aclr         (~local_rst_l_c),
    .clock        (cr_intf.clk_ir),
    .data         (wmdrvr_ingr_intf.pcm_data.rchnnl),
    .rdaddress    (cap_addr_f[P_PCM_RAM_ADDR_W-1:0]),
    .wraddress    (addr_f),
    .wren         (adc_cap_wr_en_c),
    .q            (adc_rcap_rdata_w)
  );



endmodule // syn_audio_cache
