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
 -- Test Name         : syn_acortex_base_test
 -- Author            : mammenx
 -- Function          : Base test that instantiates the acortex env & makes
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

class syn_acortex_base_test extends ovm_test;


    parameter LB_DATA_W = 32;
    parameter LB_ADDR_W = 12;
    parameter type  LB_SEQ_ITEM_T = syn_lb_seq_item#(LB_DATA_W,LB_ADDR_W);
    parameter type  LB_SEQR_T     = syn_lb_seqr#(LB_SEQ_ITEM_T);
    parameter type  PCM_SEQ_ITEM_T= syn_pcm_seq_item;
    parameter type  ADC_SEQR_T    = syn_acortex_codec_adc_seqr#(PCM_SEQ_ITEM_T);

    parameter I2C_DATA_W          = 16;
    parameter CODEC_REG_MAP_W     = 9;

    `ovm_component_utils(syn_acortex_base_test)

    //Declare environment
    syn_acortex_env   env;


    syn_i2c_config_seq#(I2C_DATA_W,LB_SEQ_ITEM_T,LB_SEQR_T)   i2c_config_seq;

    OVM_FILE  f;
    ovm_table_printer printer;


    /*  Constructor */
    function new (string name="syn_acortex_base_test", ovm_component parent=null);
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

      env = new("syn_acortex_env", this);

      i2c_config_seq  = syn_i2c_config_seq#(I2C_DATA_W,LB_SEQ_ITEM_T,LB_SEQR_T)::type_id::create("i2c_config_seq");

      printer = new();
      printer.knobs.name_width  = 50; //width of Name collumn
      printer.knobs.type_width  = 50; //width of Type collumn
      printer.knobs.size_width  = 5;  //width of Size collumn
      printer.knobs.value_width = 30; //width of Value collumn
      printer.knobs.depth = -1;       //print all levels

      ovm_report_info(get_full_name(),"End of build",OVM_LOW);
    endfunction : build


    /*  Connect */
    function  void  connect();
      super.connect();

      ovm_report_info(get_full_name(),"Start of connect",OVM_LOW);

      //Make connections from DUT to TB components
      this.env.lb_agent.drvr.intf   = $root.syn_acortex_tb_top.lb_tb_intf;
      this.env.lb_agent.mon.intf    = $root.syn_acortex_tb_top.lb_tb_intf;

      this.env.codec_agent.adc_drvr.intf    = $root.syn_acortex_tb_top.wm8731_intf;
      this.env.codec_agent.adc_mon.intf     = $root.syn_acortex_tb_top.wm8731_intf;
      this.env.codec_agent.dac_mon.intf     = $root.syn_acortex_tb_top.wm8731_intf;
      this.env.codec_agent.i2c_mon.intf     = $root.syn_acortex_tb_top.wm8731_intf;
      this.env.codec_agent.i2c_slave.intf   = $root.syn_acortex_tb_top.wm8731_intf;

      this.env.pcm_mem_agent.drvr.intf  = $root.syn_acortex_tb_top.pcm_mem_tb_intf;
      this.env.pcm_mem_agent.mon.intf   = $root.syn_acortex_tb_top.pcm_mem_tb_intf;

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


    virtual task  setup_codec(int bps = 32);
      int bps_val;

      /*
      if(this.env.wm8731_reg_map.set_field("format", 'b11)  !=  syn_reg_map#(CODEC_REG_MAP_W)::SUCCESS)
      begin
        ovm_report_fatal(get_name(),{"Could not find field \"format\" !!!"},OVM_LOW);
      end

      i2c_config_seq.poll_en  = 1;
      i2c_config_seq.i2c_data = ((this.env.wm8731_reg_map.get_addr("format") & 'h7f) <<  9) +
                                (this.env.wm8731_reg_map.get_reg("format") & 'h1ff);
      i2c_config_seq.start(this.env.lb_agent.seqr);

      #1;
      */

      if(bps  ==  32)
        bps_val = 'b11;
      else
        bps_val = 'd0;

      if(this.env.wm8731_reg_map.set_field("iwl", bps_val)  !=  syn_reg_map#(CODEC_REG_MAP_W)::SUCCESS)
      begin
        ovm_report_fatal(get_name(),{"Could not find field \"iwl\" !!!"},OVM_LOW);
      end

      i2c_config_seq.poll_en  = 1;
      i2c_config_seq.i2c_data = ((this.env.wm8731_reg_map.get_addr("iwl") & 'h7f) <<  9) +
                                (this.env.wm8731_reg_map.get_reg("iwl") & 'h1ff);
      i2c_config_seq.start(this.env.lb_agent.seqr);

      #1;

    endtask : setup_codec

endclass : syn_acortex_base_test
