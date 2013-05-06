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
 -- Module Name       : syn_gpu
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : Top level GPU (Grapheme) block
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_gpu (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf           cr_intf,      //Clock Reset Interface

  syn_lb_intf                     lb_intf,    //DATA_W=32, ADDR_W=8

  sram_acc_intf                   sram_intf         //Interface to SRAM

  //--------------------- Misc Ports (Logic)  -----------

                );

//----------------------- Global parameters Declarations ------------------


//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------


//----------------------- Internal Wire Declarations ----------------------


//----------------------- Internal Interface Declarations -----------------
  mulberry_bus_intf               mul_bus_intf(cr_intf.clk_ir,  cr_intf.rst_sync_l);
  syn_pxl_xfr_intf                core2anti_alias_intf(cr_intf.clk_ir, cr_intf.rst_sync_l);
  syn_pxl_xfr_intf                core2pxl_gw_intf(cr_intf.clk_ir, cr_intf.rst_sync_l);
  syn_pxl_xfr_intf                anti_alias2pxl_gw_intf(cr_intf.clk_ir, cr_intf.rst_sync_l);
  syn_pxl_xfr_intf                pxl_gw2core_intf(cr_intf.clk_ir, cr_intf.rst_sync_l);
  syn_anti_alias_status_intf      anti_alias_stat_intf(cr_intf.clk_ir, cr_intf.rst_sync_l);



//----------------------- Start of Code -----------------------------------

  /*  Instantiating sub modules */
  syn_gpu_core              syn_gpu_core_inst
  (

    .cr_intf                (cr_intf),

    .lb_intf                (lb_intf),

    .mul_bus_intf           (mul_bus_intf.gpu_core_mp),

    .anti_alias_intf        (core2anti_alias_intf.master),

    .pxl_gw_tx_intf         (core2pxl_gw_intf.master),

    .pxl_gw_rx_intf         (pxl_gw2core_intf.slave),

    .anti_alias_stat_intf   (anti_alias_stat_intf.lb_mp)

  );

  syn_gpu_anti_aliaser      syn_gpu_anti_aliaser_inst
  (

    .cr_intf                (cr_intf),

    .pxl_ingr_intf          (core2anti_alias_intf.slave),

    .pxl_egr_intf           (anti_alias2pxl_gw_intf.master),

    .mul_bus_intf           (mul_bus_intf.anti_alias_mp),

    .lb_stat_intf           (anti_alias_stat_intf.anti_alias_mp)

  );

  syn_gpu_div               syn_gpu_div_inst
  (

    .cr_intf                (cr_intf),

    .mulbry_bus_intf        (mul_bus_intf.div_mp)

  );

  syn_gpu_mul               syn_gpu_mul_inst
  (

    .cr_intf                (cr_intf),

    .mulbry_bus_intf        (mul_bus_intf.mul_mp)

  );

  syn_gpu_rand              syn_gpu_rand_inst
  (

    .cr_intf                (cr_intf),

    .mulbry_bus_intf        (mul_bus_intf.rand_mp)

  );

  syn_gpu_pxl_gw            syn_gpu_pxl_gw_inst
  (

    .cr_intf                (cr_intf),

    .anti_alias_intf        (anti_alias2pxl_gw_intf.slave),

    .gpu_core_intf          (core2pxl_gw_intf.slave),

    .gw2gpu_core_intf       (pxl_gw2core_intf.master),

    .sram_intf              (sram_intf)

  );


endmodule // syn_gpu
