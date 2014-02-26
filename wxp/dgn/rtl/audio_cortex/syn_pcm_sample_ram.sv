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
 -- Module Name       : syn_pcm_sample_ram
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This module is a wrapper for the PCM ram which can
                        be accessed from both acortex & fgyrus blocks.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_pcm_sample_ram (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf           acortex_cr_intf,      //Clock Reset Interface
  mem_intf                        acortex_lmem_intf,    //Slave
  mem_intf                        acortex_rmem_intf,    //Slave

  syn_clk_rst_sync_intf           fgyrus_cr_intf,       //Clock Reset Interface
  mem_intf                        fgyrus_lmem_intf,     //Slave
  mem_intf                        fgyrus_rmem_intf      //Slave

  //--------------------- Misc Ports (Logic)  -----------

                );

//----------------------- Global parameters Declarations ------------------
  import  syn_global_pkg::*;

  parameter P_MEM_DATA_W    = P_32B_W;
  parameter P_MEM_ADDR_W    = 7;
  parameter P_RAM_RDELAY    = 2;

//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------
  logic                       ram_1_n_0_f;
  logic [P_RAM_RDELAY-1:0]    acortex_lrd_del_vec_f;
  logic [P_RAM_RDELAY-1:0]    acortex_rrd_del_vec_f;

  logic [P_RAM_RDELAY-1:0]    fgyrus_lrd_del_vec_f;
  logic [P_RAM_RDELAY-1:0]    fgyrus_rrd_del_vec_f;

//----------------------- Internal Wire Declarations ----------------------
  logic [P_MEM_DATA_W-1:0]    lchannel_0_wdata_w;
  logic [P_MEM_ADDR_W-1:0]    lchannel_0_waddr_w;
  logic                       lchannel_0_wren_c;
  logic [P_MEM_ADDR_W-1:0]    lchannel_0_raddr_w;
  logic [P_MEM_DATA_W-1:0]    lchannel_0_rdata_w;

  logic [P_MEM_DATA_W-1:0]    lchannel_1_wdata_w;
  logic [P_MEM_ADDR_W-1:0]    lchannel_1_waddr_w;
  logic                       lchannel_1_wren_c;
  logic [P_MEM_ADDR_W-1:0]    lchannel_1_raddr_w;
  logic [P_MEM_DATA_W-1:0]    lchannel_1_rdata_w;

  logic [P_MEM_DATA_W-1:0]    rchannel_0_wdata_w;
  logic [P_MEM_ADDR_W-1:0]    rchannel_0_waddr_w;
  logic                       rchannel_0_wren_c;
  logic [P_MEM_ADDR_W-1:0]    rchannel_0_raddr_w;
  logic [P_MEM_DATA_W-1:0]    rchannel_0_rdata_w;

  logic [P_MEM_DATA_W-1:0]    rchannel_1_wdata_w;
  logic [P_MEM_ADDR_W-1:0]    rchannel_1_waddr_w;
  logic                       rchannel_1_wren_c;
  logic [P_MEM_ADDR_W-1:0]    rchannel_1_raddr_w;
  logic [P_MEM_DATA_W-1:0]    rchannel_1_rdata_w;

  logic [P_MEM_DATA_W-1:0]    lchannel_2_wdata_w;
  logic [P_MEM_ADDR_W-1:0]    lchannel_2_waddr_w;
  logic                       lchannel_2_wren_c;
  logic [P_MEM_ADDR_W-1:0]    lchannel_2_raddr_w;
  logic [P_MEM_DATA_W-1:0]    lchannel_2_rdata_w;

  logic [P_MEM_DATA_W-1:0]    rchannel_2_wdata_w;
  logic [P_MEM_ADDR_W-1:0]    rchannel_2_waddr_w;
  logic                       rchannel_2_wren_c;
  logic [P_MEM_ADDR_W-1:0]    rchannel_2_raddr_w;
  logic [P_MEM_DATA_W-1:0]    rchannel_2_rdata_w;

  logic [P_MEM_DATA_W-1:0]    lchannel_3_wdata_w;
  logic [P_MEM_ADDR_W-1:0]    lchannel_3_waddr_w;
  logic                       lchannel_3_wren_c;
  logic [P_MEM_ADDR_W-1:0]    lchannel_3_raddr_w;
  logic [P_MEM_DATA_W-1:0]    lchannel_3_rdata_w;

  logic [P_MEM_DATA_W-1:0]    rchannel_3_wdata_w;
  logic [P_MEM_ADDR_W-1:0]    rchannel_3_waddr_w;
  logic                       rchannel_3_wren_c;
  logic [P_MEM_ADDR_W-1:0]    rchannel_3_raddr_w;
  logic [P_MEM_DATA_W-1:0]    rchannel_3_rdata_w;

  logic                       ram_1_n_0_sync_w;


//----------------------- Internal Interface Declarations -----------------




//----------------------- Start of Code -----------------------------------

  /*
    * Mux between the RAM blocks
  */
  always_ff@(posedge acortex_cr_intf.clk_ir, negedge acortex_cr_intf.rst_sync_l)
  begin
    if(~acortex_cr_intf.rst_sync_l)
    begin
      ram_1_n_0_f             <=  0;
      acortex_lrd_del_vec_f   <=  0;
      acortex_rrd_del_vec_f   <=  0;
    end
    else
    begin
      ram_1_n_0_f             <=  (&acortex_lmem_intf.addr) & acortex_lmem_intf.wren  ? ~ram_1_n_0_f
                                                                                      : ram_1_n_0_f;

      acortex_lrd_del_vec_f   <=  {acortex_lrd_del_vec_f[P_RAM_RDELAY-2:0],acortex_lmem_intf.rden};
      acortex_rrd_del_vec_f   <=  {acortex_rrd_del_vec_f[P_RAM_RDELAY-2:0],acortex_rmem_intf.rden};
    end
  end


  always_ff@(posedge acortex_cr_intf.clk_ir, negedge acortex_cr_intf.rst_sync_l)
  begin
    if(~acortex_cr_intf.rst_sync_l)
    begin
      fgyrus_lrd_del_vec_f   <=  0;
      fgyrus_rrd_del_vec_f   <=  0;
    end
    else
    begin
      fgyrus_lrd_del_vec_f   <=  {fgyrus_lrd_del_vec_f[P_RAM_RDELAY-2:0],fgyrus_lmem_intf.rden};
      fgyrus_rrd_del_vec_f   <=  {fgyrus_rrd_del_vec_f[P_RAM_RDELAY-2:0],fgyrus_rmem_intf.rden};
    end
  end

  //Synchronize ram select to fgyrus clk
  dd_sync   sync_inst
  (
    .clk_ir     (fgyrus_cr_intf.clk_ir),
    .rst_il     (fgyrus_cr_intf.rst_sync_l),

    .signal_id  (ram_1_n_0_f),

    .signal_od  (ram_1_n_0_sync_w)
  );


  always_comb
  begin
    lchannel_0_wdata_w        = acortex_lmem_intf.wdata;
    lchannel_0_waddr_w        = acortex_lmem_intf.addr;
    lchannel_0_raddr_w        = fgyrus_lmem_intf.addr;

    lchannel_1_wdata_w        = acortex_lmem_intf.wdata;
    lchannel_1_waddr_w        = acortex_lmem_intf.addr;
    lchannel_1_raddr_w        = fgyrus_lmem_intf.addr;

    rchannel_0_wdata_w        = acortex_rmem_intf.wdata;
    rchannel_0_waddr_w        = acortex_rmem_intf.addr;
    rchannel_0_raddr_w        = fgyrus_rmem_intf.addr;

    rchannel_1_wdata_w        = acortex_rmem_intf.wdata;
    rchannel_1_waddr_w        = acortex_rmem_intf.addr;
    rchannel_1_raddr_w        = fgyrus_rmem_intf.addr;

    acortex_lmem_intf.rd_valid= acortex_lrd_del_vec_f[P_RAM_RDELAY-1];
    acortex_rmem_intf.rd_valid= acortex_rrd_del_vec_f[P_RAM_RDELAY-1];

    lchannel_2_wdata_w        = acortex_lmem_intf.wdata;
    lchannel_2_waddr_w        = acortex_lmem_intf.addr;
    lchannel_2_raddr_w        = acortex_lmem_intf.addr;

    rchannel_2_wdata_w        = acortex_rmem_intf.wdata;
    rchannel_2_waddr_w        = acortex_rmem_intf.addr;
    rchannel_2_raddr_w        = acortex_rmem_intf.addr;

    lchannel_3_wdata_w        = acortex_lmem_intf.wdata;
    lchannel_3_waddr_w        = acortex_lmem_intf.addr;
    lchannel_3_raddr_w        = acortex_lmem_intf.addr;

    rchannel_3_wdata_w        = acortex_rmem_intf.wdata;
    rchannel_3_waddr_w        = acortex_rmem_intf.addr;
    rchannel_3_raddr_w        = acortex_rmem_intf.addr;


    if(ram_1_n_0_f) //RAM_1/3 is for Acortex, RAM_0 for fgyrus
    begin
      lchannel_0_wren_c       = 1'b0;
      lchannel_1_wren_c       = acortex_lmem_intf.wren;
      lchannel_2_wren_c       = 1'b0;
      lchannel_3_wren_c       = acortex_lmem_intf.wren;
      acortex_lmem_intf.rdata = lchannel_2_rdata_w;

      rchannel_0_wren_c       = 1'b0;
      rchannel_1_wren_c       = acortex_rmem_intf.wren;
      rchannel_2_wren_c       = 1'b0;
      rchannel_1_wren_c       = acortex_rmem_intf.wren;
      acortex_rmem_intf.rdata = rchannel_2_rdata_w;
    end
    else  //RAM_0/2 is for Acortex, RAM_1 for fgyrus
    begin
      lchannel_0_wren_c       = acortex_lmem_intf.wren;
      lchannel_1_wren_c       = 1'b0;
      lchannel_2_wren_c       = acortex_lmem_intf.wren;
      lchannel_3_wren_c       = 1'b0;
      acortex_lmem_intf.rdata = lchannel_3_rdata_w;

      rchannel_0_wren_c       = acortex_rmem_intf.wren;
      rchannel_1_wren_c       = 1'b0;
      rchannel_2_wren_c       = acortex_rmem_intf.wren;
      rchannel_1_wren_c       = 1'b0;
      acortex_rmem_intf.rdata = rchannel_3_rdata_w;
    end

    if(ram_1_n_0_sync_w)
    begin
      fgyrus_lmem_intf.rdata  = lchannel_0_rdata_w;
      fgyrus_rmem_intf.rdata  = rchannel_0_rdata_w;
    end
    else
    begin
      fgyrus_lmem_intf.rdata  = lchannel_1_rdata_w;
      fgyrus_rmem_intf.rdata  = rchannel_1_rdata_w;
    end
  end

  assign  fgyrus_lmem_intf.rd_valid = fgyrus_lrd_del_vec_f[P_RAM_RDELAY-1];
  assign  fgyrus_rmem_intf.rd_valid = fgyrus_rrd_del_vec_f[P_RAM_RDELAY-1];


  /*  Instantiate RAMs  */
  ram_1xM4K_32bW_128D_dualclock   ram_0_lchannel_inst
  (
    .data         (lchannel_0_wdata_w),
    .rd_aclr      (~fgyrus_cr_intf.rst_sync_l),
    .rdaddress    (lchannel_0_raddr_w),
    .rdclock      (fgyrus_cr_intf.clk_ir),
    .wraddress    (lchannel_0_waddr_w),
    .wrclock      (acortex_cr_intf.clk_ir),
    .wren         (lchannel_0_wren_c),
    .q            (lchannel_0_rdata_w)
  );

  ram_1xM4K_32bW_128D_dualclock   ram_1_lchannel_inst
  (
    .data         (lchannel_1_wdata_w),
    .rd_aclr      (~fgyrus_cr_intf.rst_sync_l),
    .rdaddress    (lchannel_1_raddr_w),
    .rdclock      (fgyrus_cr_intf.clk_ir),
    .wraddress    (lchannel_1_waddr_w),
    .wrclock      (acortex_cr_intf.clk_ir),
    .wren         (lchannel_1_wren_c),
    .q            (lchannel_1_rdata_w)
  );

  ram_1xM4K_32bW_128D_dualclock   ram_0_rchannel_inst
  (
    .data         (rchannel_0_wdata_w),
    .rd_aclr      (~fgyrus_cr_intf.rst_sync_l),
    .rdaddress    (rchannel_0_raddr_w),
    .rdclock      (fgyrus_cr_intf.clk_ir),
    .wraddress    (rchannel_0_waddr_w),
    .wrclock      (acortex_cr_intf.clk_ir),
    .wren         (rchannel_0_wren_c),
    .q            (rchannel_0_rdata_w)
  );

  ram_1xM4K_32bW_128D_dualclock   ram_1_rchannel_inst
  (
    .data         (rchannel_1_wdata_w),
    .rd_aclr      (~fgyrus_cr_intf.rst_sync_l),
    .rdaddress    (rchannel_1_raddr_w),
    .rdclock      (fgyrus_cr_intf.clk_ir),
    .wraddress    (rchannel_1_waddr_w),
    .wrclock      (acortex_cr_intf.clk_ir),
    .wren         (rchannel_1_wren_c),
    .q            (rchannel_1_rdata_w)
  );

  ram_1xM4K_32bW_128D ram_2_lchannel_inst
  (
    .aclr             (~acortex_cr_intf.rst_sync_l),
    .clock            (acortex_cr_intf.clk_ir),
    .data             (lchannel_2_wdata_w),
    .rdaddress        (lchannel_2_raddr_w),
    .wraddress        (lchannel_2_waddr_w),
    .wren             (lchannel_2_wren_c),
    .q                (lchannel_2_rdata_w)
  );

  ram_1xM4K_32bW_128D ram_2_rchannel_inst
  (
    .aclr             (~acortex_cr_intf.rst_sync_l),
    .clock            (acortex_cr_intf.clk_ir),
    .data             (rchannel_2_wdata_w),
    .rdaddress        (rchannel_2_raddr_w),
    .wraddress        (rchannel_2_waddr_w),
    .wren             (rchannel_2_wren_c),
    .q                (rchannel_2_rdata_w)
  );

  ram_1xM4K_32bW_128D ram_3_lchannel_inst
  (
    .aclr             (~acortex_cr_intf.rst_sync_l),
    .clock            (acortex_cr_intf.clk_ir),
    .data             (lchannel_3_wdata_w),
    .rdaddress        (lchannel_3_raddr_w),
    .wraddress        (lchannel_3_waddr_w),
    .wren             (lchannel_3_wren_c),
    .q                (lchannel_3_rdata_w)
  );

  ram_1xM4K_32bW_128D ram_3_rchannel_inst
  (
    .aclr             (~acortex_cr_intf.rst_sync_l),
    .clock            (acortex_cr_intf.clk_ir),
    .data             (rchannel_3_wdata_w),
    .rdaddress        (rchannel_3_raddr_w),
    .wraddress        (rchannel_3_waddr_w),
    .wren             (rchannel_3_wren_c),
    .q                (rchannel_3_rdata_w)
  );



endmodule // syn_pcm_sample_ram
