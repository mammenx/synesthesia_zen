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
 -- Component Name    : syn_sram_agent
 -- Author            : mammenx
 -- Function          : This agent contains components which drive & monitor
                        the SRAM interface.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_SRAM_AGENT
`define __SYN_SRAM_AGENT

  class syn_sram_agent  #(parameter DATA_W  = 16,
                          parameter ADDR_W  = 18,
                          type  PKT_TYPE    = syn_lb_seq_item,
                          type  INTF_TYPE   = virtual syn_sram_mem_intf.TB
                        ) extends ovm_component;

    /*  Register with factory */
    `ovm_component_param_utils(syn_sram_agent#(DATA_W,ADDR_W,PKT_TYPE,INTF_TYPE))


    //Declare Seqr, Drvr, Mon, Sb objects
    syn_sram_drvr#(DATA_W,ADDR_W,PKT_TYPE,INTF_TYPE)    drvr;
    syn_sram_mon#(DATA_W,ADDR_W,PKT_TYPE,INTF_TYPE)     mon;
    syn_sram_seqr#(PKT_TYPE)                            seqr;


    OVM_FILE  f;


    /*  Constructor */
    function new(string name  = "syn_sram_agent", ovm_component parent = null);
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
      drvr  = syn_sram_drvr#(DATA_W,ADDR_W,PKT_TYPE,INTF_TYPE)::type_id::create("syn_sram_drvr",  this);
      mon   = syn_sram_mon#(DATA_W,ADDR_W,PKT_TYPE,INTF_TYPE)::type_id::create("syn_sram_mon",  this);
      seqr  = syn_sram_seqr#(PKT_TYPE)::type_id::create("syn_sram_seqr",  this);

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
      seqr.enable = 0;

      ovm_report_info(get_name(),"Disabled myself & kids ...",OVM_LOW);
    endfunction : disable_agent



  endclass  : syn_sram_agent

`endif
