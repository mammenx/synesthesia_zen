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
 -- Component Name    : syn_pcm_mem_agent
 -- Author            : mammenx 
 -- Function          : PCM Memory Agent.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_PCM_MEM_AGENT
`define __SYN_PCM_MEM_AGENT

  class syn_pcm_mem_agent #(
                              parameter NUM_SAMPLES   = 128,
                              parameter type  PCM_PKT_TYPE  = syn_pcm_seq_item,
                              parameter type  INTF_TYPE     = virtual syn_pcm_mem_intf
                          ) extends ovm_component;

    /*  Register with factory */
    `ovm_component_utils(syn_pcm_mem_agent#(NUM_SAMPLES,PCM_PKT_TYPE,INTF_TYPE))


    //Declare Seqr, Drvr, Mon, Sb objects
    syn_pcm_mem_drvr#(NUM_SAMPLES,PCM_PKT_TYPE,INTF_TYPE)     drvr;
    syn_pcm_mem_seqr#(PCM_PKT_TYPE)                           seqr;
    syn_pcm_mem_mon#(NUM_SAMPLES,PCM_PKT_TYPE,INTF_TYPE)      mon;


    OVM_FILE  f;


    /*  Constructor */
    function new(string name  = "syn_pcm_mem_agent", ovm_component parent = null);
      super.new(name, parent);
    endfunction: new


    /*  Build */
    function void build();
      super.build();

      f = $fopen({"./logs/",get_full_name(),".log"},  "w");

      set_report_default_file(f);
      set_report_severity_action(OVM_INFO,  OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_WARNING, OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_ERROR,  OVM_COUNT | OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_FATAL,  OVM_EXIT | OVM_DISPLAY | OVM_LOG);

      ovm_report_info(get_name(),"Start of build ",OVM_LOW);

      //Build Seqr, Drvr, Mon, Sb objects using Factory
      drvr  = syn_pcm_mem_drvr#(NUM_SAMPLES,PCM_PKT_TYPE,INTF_TYPE)::type_id::create("syn_pcm_mem_drvr",  this);
      seqr  = syn_pcm_mem_seqr#(PCM_PKT_TYPE)::type_id::create("syn_pcm_mem_seqr",  this);
      mon   = syn_pcm_mem_mon#(NUM_SAMPLES,PCM_PKT_TYPE,INTF_TYPE)::type_id::create("syn_pcm_mem_mon",  this);

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction


    /*  Connect */
    function void connect();
      super.connect();

      ovm_report_info(get_name(),"START of connect ",OVM_LOW);

        //Make port connections
        drvr.seq_item_port.connect(seqr.seq_item_export);

      ovm_report_info(get_name(),"END of connect ",OVM_LOW);
    endfunction


    /*  Disable Agent */
    function  void  disable_agent();

      mon.enable  = 0;
      drvr.enable = 0;

      ovm_report_info(get_name(),"Disabled myself & kids ...",OVM_LOW);

    endfunction : disable_agent



  endclass  : syn_pcm_mem_agent

`endif
