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
 -- Component Name    : syn_cortex_env
 -- Author            : mammenx
 -- Function          : This environment has all the components for Cortex
                        block.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/


`ifndef __SYN_CORTEX_ENV
`define __SYN_CORTEX_ENV


  class syn_cortex_env extends ovm_env;

    //Parameters
    parameter       CORTEX_LB_DATA_W   = 32;
    parameter       CORTEX_LB_ADDR_W   = 16;
    parameter type  CORTEX_LB_PKT_T    = syn_lb_seq_item#(CORTEX_LB_DATA_W,CORTEX_LB_ADDR_W);
    parameter type  CORTEX_LB_DRVR_INTF_T  = virtual syn_lb_tb_intf#(CORTEX_LB_DATA_W,CORTEX_LB_ADDR_W);
    parameter type  CORTEX_LB_MON_INTF_T   = virtual syn_lb_tb_intf#(CORTEX_LB_DATA_W,CORTEX_LB_ADDR_W);


    /*  Register with factory */
    `ovm_component_utils(syn_cortex_env)


    //Declare agents, scoreboards
    syn_lb_agent#(CORTEX_LB_DATA_W,CORTEX_LB_ADDR_W,CORTEX_LB_PKT_T,CORTEX_LB_DRVR_INTF_T,CORTEX_LB_MON_INTF_T)  lb_agent;

    syn_acortex_env     acortex_env;
    syn_fgyrus_env      fgyrus_env;
    syn_vcortex_env     vcortex_env;


    OVM_FILE  f;


    /*  Constructor */
    function new(string name  = "syn_cortex_env", ovm_component parent = null);
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

      lb_agent      = syn_lb_agent#(CORTEX_LB_DATA_W,CORTEX_LB_ADDR_W,CORTEX_LB_PKT_T,CORTEX_LB_DRVR_INTF_T,CORTEX_LB_MON_INTF_T)::type_id::create("lb_agent",  this);

      acortex_env   = syn_acortex_env::type_id::create("acortex_env", this);
      fgyrus_env    = syn_fgyrus_env::type_id::create("fgyrus_env", this);
      vcortex_env   = syn_vcortex_env::type_id::create("vcortex_env", this);

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction


    /*  Connect */
    function void connect();
      super.connect();

      ovm_report_info(get_name(),"START of connect ",OVM_LOW);

      //Configure agents
      this.acortex_env.lb_agent.drvr.enable = 0;
      this.vcortex_env.lb_agent.drvr.enable = 0;

      this.acortex_env.pcm_mem_agent.drvr.enable  = 0;
      this.fgyrus_env.pcm_mem_agent.drvr.enable   = 0;

      ovm_report_info(get_name(),"END of connect ",OVM_LOW);
    endfunction



  endclass  : syn_cortex_env

`endif
