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
 -- Component Name    : syn_fgyrus_env
 -- Author            : mammenx
 -- Function          : This environment holds all the agents needed to
                        interact with Fgyrus.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/


`ifndef __SYN_FGYRUS_ENV
`define __SYN_FGYRUS_ENV


  class syn_fgyrus_env extends ovm_env;

    //Parameters
    parameter       LB_DATA_W   = 32;
    parameter       LB_ADDR_W   = 12;
    parameter type  LB_PKT_T    = syn_lb_seq_item#(LB_DATA_W,LB_ADDR_W);
    parameter type  LB_DRVR_INTF_T  = virtual syn_lb_tb_intf#(LB_DATA_W,LB_ADDR_W);
    parameter type  LB_MON_INTF_T   = virtual syn_lb_tb_intf#(LB_DATA_W,LB_ADDR_W);

    parameter type  PCM_PKT_TYPE  = syn_pcm_seq_item;
    parameter       NUM_PCM_SAMPLES   = 128;
    parameter type  PCM_MEM_INTF_TYPE = virtual syn_pcm_mem_intf#(32,7,2);

    /*  Register with factory */
    `ovm_component_utils(syn_fgyrus_env)


    //Declare agents, scoreboards
    syn_lb_agent#(LB_DATA_W,LB_ADDR_W,LB_PKT_T,LB_DRVR_INTF_T,LB_MON_INTF_T)  lb_agent;
    syn_pcm_mem_agent#(NUM_PCM_SAMPLES,PCM_PKT_TYPE,PCM_MEM_INTF_TYPE)        pcm_mem_agent;


    OVM_FILE  f;


    /*  Constructor */
    function new(string name  = "syn_fgyrus_env", ovm_component parent = null);
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

      lb_agent      = syn_lb_agent#(LB_DATA_W,LB_ADDR_W,LB_PKT_T,LB_DRVR_INTF_T,LB_MON_INTF_T)::type_id::create("lb_agent",  this);
      pcm_mem_agent = syn_pcm_mem_agent#(NUM_PCM_SAMPLES,PCM_PKT_TYPE,PCM_MEM_INTF_TYPE)::type_id::create("pcm_mem_agent",  this);

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction


    /*  Connect */
    function void connect();
      super.connect();

      ovm_report_info(get_name(),"START of connect ",OVM_LOW);

        this.pcm_mem_agent.drvr.mode_master_n_slave  = 1;  //configure as master

      ovm_report_info(get_name(),"END of connect ",OVM_LOW);
    endfunction



  endclass  : syn_fgyrus_env

`endif
