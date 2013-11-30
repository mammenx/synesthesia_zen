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
 -- Module Name       : syn_vcortex
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This is the VCORTEX top level block. The vcortex
                        lb decoding is also done here.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_vcortex (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf       cr_intf,      //Clock Reset Interface

  syn_lb_intf                 lb_intf,    //DATA_W=32, ADDR_W=12

  syn_sram_mem_intf           sram_mem_intf,

  syn_vga_intf                vga_intf


  //--------------------- Misc Ports (Logic)  -----------

                );

//----------------------- Global parameters Declarations ------------------
  import  syn_global_pkg::*;
  import  syn_gpu_pkg::*;
  `include  "syn_vcortex_reg_map.sv"


//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------


//----------------------- Internal Wire Declarations ----------------------
  logic [3:0]                 block_code_w;
  logic                       gpu_code_sel_c;
  logic                       vga_code_sel_c;
  logic                       vga_rst_lc;

//----------------------- Internal Interface Declarations -----------------
  sram_acc_intf#(16,18,2)     sram_bus_intf(cr_intf.clk_ir, cr_intf.rst_sync_l);
  syn_lb_intf#(32,8)          gpu_lb_intf(cr_intf.clk_ir, cr_intf.rst_sync_l);
  syn_lb_intf#(32,8)          vga_lb_intf(cr_intf.clk_ir, cr_intf.rst_sync_l);
  syn_clk_rst_sync_intf       vga_cr_intf(cr_intf.clk_ir, vga_rst_lc);


//----------------------- Start of Code -----------------------------------

  //Decoding LB transactions
  assign  block_code_w        = lb_intf.addr[11:8];
  assign  gpu_code_sel_c      = (block_code_w ==  VCORTEX_GPU_CODE) ? 1'b1  : 1'b0;
  assign  vga_code_sel_c      = (block_code_w ==  VCORTEX_VGA_CODE) ? 1'b1  : 1'b0;

  assign  gpu_lb_intf.rd_en   = lb_intf.rd_en & gpu_code_sel_c;
  assign  gpu_lb_intf.wr_en   = lb_intf.wr_en & gpu_code_sel_c;
  assign  gpu_lb_intf.addr    = lb_intf.addr[7:0];
  assign  gpu_lb_intf.wr_data = lb_intf.wr_data;

  assign  vga_lb_intf.rd_en   = lb_intf.rd_en & vga_code_sel_c;
  assign  vga_lb_intf.wr_en   = lb_intf.wr_en & vga_code_sel_c;
  assign  vga_lb_intf.addr    = lb_intf.addr[7:0];
  assign  vga_lb_intf.wr_data = lb_intf.wr_data;

  assign  lb_intf.wr_valid    = gpu_lb_intf.wr_valid  | vga_lb_intf.wr_valid;
  assign  lb_intf.rd_valid    = gpu_lb_intf.rd_valid  | vga_lb_intf.rd_valid;
  assign  lb_intf.rd_data     = gpu_lb_intf.rd_valid  ? gpu_lb_intf.rd_data : vga_lb_intf.rd_data;

  //A write to VCORTEX_VGA_RESET_REG_ADDR generates a reset
  assign  vga_rst_lc  = cr_intf.rst_sync_l  & ~((lb_intf.addr[11:0] ==  {VCORTEX_VGA_CODE,VCORTEX_VGA_RESET_REG_ADDR})  & lb_intf.wr_en);

  //always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  //begin : seq_logic
  // if(~cr_intf.rst_sync_l)
  // begin
  //   lb_intf.wr_valid         <=  0;
  //   lb_intf.rd_valid         <=  0;
  //   lb_intf.rd_data          <=  0;
  // end
  // else
  // begin
  //   lb_intf.wr_valid         <=  gpu_lb_intf.wr_valid  | vga_lb_intf.wr_valid;
  //   lb_intf.rd_valid         <=  gpu_lb_intf.rd_valid  | vga_lb_intf.rd_valid;
  //   lb_intf.rd_data          <=  gpu_lb_intf.rd_valid  ? gpu_lb_intf.rd_data : vga_lb_intf.rd_data;
  // end
  //end

  //Instantiating modules
  syn_gpu   syn_gpu_inst
  (

    .cr_intf    (cr_intf),

    .lb_intf    (gpu_lb_intf.slave),

    .sram_intf  (sram_bus_intf.gpu)

  );

  syn_vga_drvr    syn_vga_drvr_inst
  (

    .cr_intf      (cr_intf),

    .sram_intf    (sram_bus_intf.vga),

    .lb_intf      (vga_lb_intf.slave),

    .vga_intf     (vga_intf)

  );

  syn_sram_mem_drvr syn_sram_mem_drvr_inst
  (

    .cr_intf        (cr_intf),

    .sram_bus_intf  (sram_bus_intf.sram),

    .sram_mem_intf  (sram_mem_intf)

  );


  /*  SRAM Debug capture RAM  */
  ram_2xM4K_32bW_256D   sram_debug_ram_inst
  (
    .clock              (),
    .data               (),
    .rdaddress          (),
    .wraddress          (),
    .wren               (),
    .q                  ()
  );


endmodule // syn_vcortex
