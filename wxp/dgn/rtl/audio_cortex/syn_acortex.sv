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
 -- Module Name       : syn_acortex
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : Audio Cortex top module.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_acortex (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf           cr_intf,      //Clock Reset Interface

  syn_lb_intf                     lb_intf,      //data=32, addr=12

  syn_wm8731_intf                 wm8731_intf,

  syn_clk_vec_intf                clk_vec_intf,

  //Fgyrus side
  syn_clk_rst_sync_intf           fgyrus_cr_intf,    //Clock Reset Interface

  mem_intf                        fgyrus_lchnnl_mem_intf,   //slave

  mem_intf                        fgyrus_rchnnl_mem_intf,   //slave

  //--------------------- Misc Ports (Logic)  -----------
  output logic  fgyrus_pcm_data_rdy_oh

                );

//----------------------- Global parameters Declarations ------------------

  parameter   P_NUM_CLOCKS          = 4;

//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------
  //logic                       fgyrus_pcm_data_rdy_oh;

//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------


//----------------------- Internal Wire Declarations ----------------------


//----------------------- Internal Interface Declarations -----------------
  syn_acortex_lb_bus_intf     acortex_lb_bus_intf(cr_intf.clk_ir, cr_intf.rst_sync_l);
  syn_pcm_xfr_intf            wmdrvr2acache_pcm_intf(cr_intf.clk_ir,  cr_intf.rst_sync_l);
  syn_pcm_xfr_intf            acache2wmdrvr_pcm_intf(cr_intf.clk_ir,  cr_intf.rst_sync_l);


//----------------------- Start of Code -----------------------------------

  /*  Instantiate submodules  */
  syn_acortex_lb      syn_acortex_lb_inst
  (

    .cr_intf          (cr_intf),

    .lb_intf          (lb_intf),

    .acortex_lb_intf  (acortex_lb_bus_intf.lbm)

  );

  syn_i2c_master      syn_i2c_master_inst
  (

    .cr_intf          (cr_intf),

    .wm8731_intf      (wm8731_intf.i2c),

    .lb_intf          (acortex_lb_bus_intf.i2cm)

  );

  syn_clk_mux         syn_clk_mux_inst
  (

    .cr_intf          (cr_intf),

    .lb_intf          (acortex_lb_bus_intf.cmux),

    .wm8731_intf      (wm8731_intf.cmux),

    .clk_vec_intf     (clk_vec_intf)

  );
  defparam  syn_clk_mux_inst.P_NUM_CLOCKS = P_NUM_CLOCKS;

  syn_wm8731_drvr         syn_wm8731_drvr_inst
  (

    .cr_intf              (cr_intf),

    .lb_intf              (acortex_lb_bus_intf.wmdrvr),

    .wm8731_intf          (wm8731_intf.wmdrvr),

    .aud_cache_ingr_intf  (acache2wmdrvr_pcm_intf.slave),

    .aud_cache_egr_intf   (wmdrvr2acache_pcm_intf.master)

  );

  syn_audio_cache         syn_acache_inst
  (

    .cr_intf                (cr_intf),

    .lb_intf                (acortex_lb_bus_intf.acache),

    .wmdrvr_ingr_intf       (wmdrvr2acache_pcm_intf.slave),

    .wmdrvr_egr_intf        (acache2wmdrvr_pcm_intf.master),

    .fgyrus_cr_intf         (fgyrus_cr_intf),

    .fgyrus_lchnnl_mem_intf (fgyrus_lchnnl_mem_intf),

    .fgyrus_rchnnl_mem_intf (fgyrus_rchnnl_mem_intf),

    .fgyrus_pcm_data_rdy_oh (fgyrus_pcm_data_rdy_oh)

  );

endmodule // syn_acortex
