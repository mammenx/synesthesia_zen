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
 -- Component Name    : syn_sram_acc_env
 -- Author            : mammenx
 -- Function          : This class contains all the components for verifying
                        sram_acc_bus.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/


`ifndef __SYN_SRAM_ACC_ENV
`define __SYN_SRAM_ACC_ENV


  class syn_sram_acc_env extends ovm_env;

    //Parameters
    parameter       SRAM_DATA_W = 16;
    parameter       SRAM_ADDR_W = 18;
    parameter type  SRAM_PKT_T  = syn_lb_seq_item#(SRAM_DATA_W,SRAM_ADDR_W);
    parameter type  SRAM_INTF_T = virtual syn_sram_mem_intf.TB;

    parameter       VGA_AGENT_ADDR_W  = SRAM_ADDR_W;
    parameter       VGA_AGENT_DATA_W  = SRAM_DATA_W;
    parameter type  VGA_AGENT_PKT_T   = syn_lb_seq_item#(VGA_AGENT_DATA_W,VGA_AGENT_ADDR_W);
    parameter type  VGA_AGENT_INTF_T  = virtual syn_sram_acc_agent_intf#(VGA_AGENT_DATA_W,VGA_AGENT_ADDR_W);

    parameter       GPU_AGENT_ADDR_W  = SRAM_ADDR_W;
    parameter       GPU_AGENT_DATA_W  = SRAM_DATA_W;
    parameter type  GPU_AGENT_PKT_T   = syn_lb_seq_item#(GPU_AGENT_DATA_W,GPU_AGENT_ADDR_W);
    parameter type  GPU_AGENT_INTF_T  = virtual syn_sram_acc_agent_intf#(GPU_AGENT_DATA_W,GPU_AGENT_ADDR_W);


    /*  Register with factory */
    `ovm_component_utils(syn_sram_acc_env)


    //Declare agents, scoreboards
    syn_sram_agent#(SRAM_DATA_W,SRAM_ADDR_W,SRAM_PKT_T,SRAM_INTF_T)   sram_agent;
    syn_sram_acc_agent#(VGA_AGENT_DATA_W,VGA_AGENT_ADDR_W,VGA_AGENT_PKT_T,VGA_AGENT_INTF_T,VGA_AGENT_INTF_T)  vga_sram_agent;
    syn_sram_acc_agent#(GPU_AGENT_DATA_W,GPU_AGENT_ADDR_W,GPU_AGENT_PKT_T,GPU_AGENT_INTF_T,GPU_AGENT_INTF_T)  gpu_sram_agent;


    OVM_FILE  f;


    /*  Constructor */
    function new(string name  = "syn_sram_acc_env", ovm_component parent = null);
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

      sram_agent  = syn_sram_agent#(SRAM_DATA_W,SRAM_ADDR_W,SRAM_PKT_T,SRAM_INTF_T)::type_id::create("sram_agent",  this);
      vga_sram_agent  = syn_sram_acc_agent#(VGA_AGENT_DATA_W,VGA_AGENT_ADDR_W,VGA_AGENT_PKT_T,VGA_AGENT_INTF_T,VGA_AGENT_INTF_T)::type_id::create("vga_sram_agent",  this);
      gpu_sram_agent  = syn_sram_acc_agent#(GPU_AGENT_DATA_W,GPU_AGENT_ADDR_W,GPU_AGENT_PKT_T,GPU_AGENT_INTF_T,GPU_AGENT_INTF_T)::type_id::create("gpu_sram_agent",  this);

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction


    /*  Connect */
    function void connect();
      super.connect();

      ovm_report_info(get_name(),"START of connect ",OVM_LOW);


      ovm_report_info(get_name(),"END of connect ",OVM_LOW);
    endfunction



  endclass  : syn_sram_acc_env

`endif
