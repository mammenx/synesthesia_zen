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
 -- Test Name         : syn_sram_acc_base_test
 -- Author            : mammenx
 -- Function          : Base test that instantiates the sram acc env & makes
                        connections from DUT to TB interfaces.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/


import  syn_env_pkg::*;

class syn_sram_acc_base_test extends ovm_test;

    parameter       SRAM_DATA_W = 16;
    parameter       SRAM_ADDR_W = 18;
    parameter type  SRAM_SEQ_ITEM_T = syn_lb_seq_item#(SRAM_DATA_W,SRAM_ADDR_W);
    parameter type  SRAM_INTF_T = virtual syn_sram_mem_intf.TB;
    parameter type  SRAM_SEQR_T     = syn_sram_seqr#(SRAM_SEQ_ITEM_T);

    parameter       VGA_AGENT_ADDR_W  = SRAM_ADDR_W;
    parameter       VGA_AGENT_DATA_W  = SRAM_DATA_W;
    parameter type  VGA_AGENT_PKT_T   = syn_lb_seq_item#(VGA_AGENT_DATA_W,VGA_AGENT_ADDR_W);
    parameter type  VGA_AGENT_SEQR_T  = syn_sram_acc_seqr#(VGA_AGENT_PKT_T);

    parameter       GPU_AGENT_ADDR_W  = SRAM_ADDR_W+1;
    parameter       GPU_AGENT_DATA_W  = SRAM_DATA_W/2;
    parameter type  GPU_AGENT_PKT_T   = syn_lb_seq_item#(GPU_AGENT_DATA_W,GPU_AGENT_ADDR_W);
    parameter type  GPU_AGENT_SEQR_T  = syn_sram_acc_seqr#(GPU_AGENT_PKT_T);


    syn_fb_init_seq#(SRAM_SEQ_ITEM_T,SRAM_SEQR_T)   fb_init_seq;

    `ovm_component_utils(syn_sram_acc_base_test)

    //Declare environment
    syn_sram_acc_env   env;


    OVM_FILE  f;
    ovm_table_printer printer;


    /*  Constructor */
    function new (string name="syn_sram_acc_base_test", ovm_component parent=null);
        super.new (name, parent);
    endfunction : new 


    /*  Build */
    function  void  build();
      super.build();

      f = $fopen({"./logs/",get_full_name(),".log"});

      set_report_default_file(f);
      set_report_severity_action(OVM_INFO,  OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_WARNING, OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_ERROR,  OVM_COUNT | OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_FATAL,  OVM_EXIT | OVM_DISPLAY | OVM_LOG);


      ovm_report_info(get_full_name(),"Start of build",OVM_LOW);

      env = new("syn_sram_acc_env", this);

      printer = new();
      printer.knobs.name_width  = 50; //width of Name collumn
      printer.knobs.type_width  = 50; //width of Type collumn
      printer.knobs.size_width  = 5;  //width of Size collumn
      printer.knobs.value_width = 30; //width of Value collumn
      printer.knobs.depth = -1;       //print all levels


      fb_init_seq = syn_fb_init_seq#(SRAM_SEQ_ITEM_T,SRAM_SEQR_T)::type_id::create("fb_init_seq");

      ovm_report_info(get_full_name(),"End of build",OVM_LOW);
    endfunction : build


    /*  Connect */
    function  void  connect();
      super.connect();

      ovm_report_info(get_full_name(),"Start of connect",OVM_LOW);

      //Make connections from DUT to TB components
      this.env.sram_agent.mon.intf   = $root.syn_sram_acc_tb_top.sram_mem_intf;
      this.env.sram_agent.drvr.intf  = $root.syn_sram_acc_tb_top.sram_mem_intf;

      this.env.vga_sram_agent.drvr.intf =  $root.syn_sram_acc_tb_top.vga_sram_acc_intf;
      this.env.vga_sram_agent.mon.intf  =  $root.syn_sram_acc_tb_top.vga_sram_acc_intf;

      this.env.gpu_sram_agent.drvr.intf =  $root.syn_sram_acc_tb_top.gpu_sram_acc_intf;
      this.env.gpu_sram_agent.mon.intf  =  $root.syn_sram_acc_tb_top.gpu_sram_acc_intf;

      ovm_report_info(get_full_name(),"End of connect",OVM_LOW);
    endfunction : connect


    /*  End of Elaboration  */
    function void end_of_elaboration();
      ovm_report_info(get_full_name(),"End_of_elaboration", OVM_LOG);


      ovm_report_info(get_full_name(),$psprintf("OVM Hierarchy -\n%s",  this.sprint(printer)), OVM_LOG);
      print();
    endfunction


    /*  Run */
    virtual task run ();

      ovm_report_info(get_full_name(),"Start of run",OVM_LOW);

      env.sprint();

      #1000;


      global_stop_request();

      ovm_report_info(get_full_name(),"End of run",OVM_LOW);
    endtask : run 


    virtual task  init_fb(input fb_init_mode_t  fb_init_mode=STATIC);
      ovm_report_info({get_full_name(),"[init_fb]"},$psprintf("Start of init_fb with mode:%s",fb_init_mode.name),OVM_LOW);

      fb_init_seq.init_mode = fb_init_mode;
      fb_init_seq.start(this.env.sram_agent.seqr);

      ovm_report_info({get_full_name(),"[init_fb]"},"End of init_fb",OVM_LOW);
    endtask : init_fb



endclass : syn_sram_acc_base_test
