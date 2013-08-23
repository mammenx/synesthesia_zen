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
 -- Component Name    : syn_vga_agent
 -- Author            : mammenx
 -- Function          : This agent contains components which monitor
                        the vga interface.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_VGA_AGENT
`define __SYN_VGA_AGENT

  class syn_vga_agent #(parameter LINE_LENGTH = 640,
                        parameter FRAME_LENGTH= 480,
                        type  PKT_TYPE    = syn_vga_seq_item,
                        type  INTF_TYPE   = virtual syn_vga_intf.TB
                      ) extends ovm_component;

    /*  Register with factory */
    `ovm_component_param_utils(syn_vga_agent#(LINE_LENGTH,FRAME_LENGTH,PKT_TYPE,INTF_TYPE))


    //Declare Seqr, Drvr, Mon, Sb objects
    syn_vga_mon#(LINE_LENGTH,FRAME_LENGTH,PKT_TYPE,INTF_TYPE) mon;


    OVM_FILE  f;


    /*  Constructor */
    function new(string name  = "syn_vga_agent", ovm_component parent = null);
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
      mon   = syn_vga_mon#(LINE_LENGTH,FRAME_LENGTH,PKT_TYPE,INTF_TYPE)::type_id::create("syn_vga_mon",  this);

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction


    /*  Connect */
    function void connect();
      super.connect();

      ovm_report_info(get_name(),"START of connect ",OVM_LOW);

        //Make port connections

      ovm_report_info(get_name(),"END of connect ",OVM_LOW);
    endfunction


    /*  Disable Agent */
    function  void  disable_agent();

      mon.enable  = 0;

      ovm_report_info(get_name(),"Disabled myself & kids ...",OVM_LOW);
    endfunction : disable_agent



  endclass  : syn_vga_agent

`endif
