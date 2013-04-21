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
 -- Component Name    : syn_vcortex_env
 -- Author            : mammenx
 -- Function          : Vcortex level environment.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/


`ifndef __SYN_VCORTEX_ENV
`define __SYN_VCORTEX_ENV


  class syn_vcortex_env extends ovm_env;

    //Parameters
    parameter       LB_DATA_W   = 32;
    parameter       LB_ADDR_W   = 12;
    parameter type  LB_PKT_T    = syn_lb_seq_item#(LB_DATA_W,LB_ADDR_W);
    //parameter type  LB_DRVR_INTF_T  = virtual syn_lb_intf#(LB_DATA_W,LB_ADDR_W);
    //parameter type  LB_MON_INTF_T   = virtual syn_lb_intf#(LB_DATA_W,LB_ADDR_W);
    parameter type  LB_DRVR_INTF_T  = virtual syn_lb_tb_intf#(LB_DATA_W,LB_ADDR_W);
    parameter type  LB_MON_INTF_T   = virtual syn_lb_tb_intf#(LB_DATA_W,LB_ADDR_W);

    parameter       SRAM_DATA_W = 16;
    parameter       SRAM_ADDR_W = 18;
    parameter type  SRAM_PKT_T  = syn_lb_seq_item#(SRAM_DATA_W,SRAM_ADDR_W);
    parameter type  SRAM_INTF_T = virtual syn_sram_mem_intf.TB;


    /*  Register with factory */
    `ovm_component_utils(syn_vcortex_env)


    //Declare agents, scoreboards
    syn_lb_agent#(LB_DATA_W,LB_ADDR_W,LB_PKT_T,LB_DRVR_INTF_T,LB_MON_INTF_T)  lb_agent;
    syn_sram_agent#(SRAM_DATA_W,SRAM_ADDR_W,SRAM_PKT_T,SRAM_INTF_T)   sram_agent;
    syn_frm_bffr_sb#(LB_PKT_T,SRAM_PKT_T)                             frm_bffr_sb;

    OVM_FILE  f;



    function new(string name  = "syn_vcortex_env", ovm_component parent = null);
      super.new(name, parent);
    endfunction: new


    /*  Build */
    function void build();
      super.build();

      f = $fopen({"./logs/",get_full_name(),".log"});

      set_report_default_file(f);
      set_report_severity_action(OVM_INFO,  OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_WARNING, OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_ERROR,  OVM_COUNT | OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_FATAL,  OVM_EXIT | OVM_DISPLAY | OVM_LOG);

      ovm_report_info(get_name(),"Start of build ",OVM_LOW);

      lb_agent    = syn_lb_agent#(LB_DATA_W,LB_ADDR_W,LB_PKT_T,LB_DRVR_INTF_T,LB_MON_INTF_T)::type_id::create("lb_agent",  this);
      sram_agent  = syn_sram_agent#(SRAM_DATA_W,SRAM_ADDR_W,SRAM_PKT_T,SRAM_INTF_T)::type_id::create("sram_agent",  this);
      frm_bffr_sb = syn_frm_bffr_sb#(LB_PKT_T,SRAM_PKT_T)::type_id::create("frm_bffr_sb", this);

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction


    /*  Connect */
    function void connect();
      super.connect();

      ovm_report_info(get_name(),"START of connect ",OVM_LOW);

      lb_agent.mon.Mon2Sb_port.connect(frm_bffr_sb.Mon_sent_2Sb_port);
      sram_agent.mon.Mon2Sb_port.connect(frm_bffr_sb.Mon_rcvd_2Sb_port);

      ovm_report_info(get_name(),"END of connect ",OVM_LOW);
    endfunction



  endclass  : syn_vcortex_env

`endif
