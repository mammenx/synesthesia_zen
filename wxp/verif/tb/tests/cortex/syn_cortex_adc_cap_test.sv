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
 -- Test Name         : syn_cortex_adc_cap_test
 -- Author            : mammenx
 -- Function          : This test generates PCM data on the WM Driver interface
                        and checks that Cortex is able to capture the ADC samples
                        and perform FFT.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/


import  syn_env_pkg::*;

class syn_cortex_adc_cap_test extends syn_cortex_base_test;


    `ovm_component_utils(syn_cortex_adc_cap_test)

    //Sequences
    syn_wm8731_drvr_config_seq#(super.CORTEX_LB_SEQ_ITEM_T,super.CORTEX_LB_SEQR_T)  wm8731_drvr_config_seq;
    syn_codec_adc_load_seq#(super.PCM_SEQ_ITEM_T,super.ADC_SEQR_T)          adc_load_seq;
    syn_adc_cap_seq#(super.CORTEX_LB_SEQ_ITEM_T,super.CORTEX_LB_SEQR_T)             adc_cap_seq;


    OVM_FILE  f;


    /*  Constructor */
    function new (string name="syn_cortex_adc_cap_test", ovm_component parent=null);
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

      wm8731_drvr_config_seq  = syn_wm8731_drvr_config_seq#(super.CORTEX_LB_SEQ_ITEM_T,super.CORTEX_LB_SEQR_T)::type_id::create("wm8731_drvr_config_seq");
      adc_load_seq            = syn_codec_adc_load_seq#(super.PCM_SEQ_ITEM_T,super.ADC_SEQR_T)::type_id::create("adc_load_seq");
      adc_cap_seq             = syn_adc_cap_seq#(super.CORTEX_LB_SEQ_ITEM_T,super.CORTEX_LB_SEQR_T)::type_id::create("adc_cap_seq");

      ovm_report_info(get_full_name(),"End of build",OVM_LOW);
    endfunction : build


    /*  Connect */
    function  void  connect();
      super.connect();

      ovm_report_info(get_full_name(),"Start of connect",OVM_LOW);

        super.env.acortex_env.codec_agent.i2c_slave.update_reg_map_en = 1;

      ovm_report_info(get_full_name(),"End of connect",OVM_LOW);
    endfunction : connect


    /*  End of Elaboration  */
    function void end_of_elaboration();
      ovm_report_info(get_full_name(),"End_of_elaboration", OVM_LOG);

    endfunction


    /*  Run */
    virtual task run ();

      ovm_report_info(get_full_name(),"Start of run",OVM_LOW);

      super.env.sprint();

      super.setup_codec(32);

      #500;

      adc_load_seq.pcm_pkt.fill_sin(256,  4000, 10000,  48000);

      wm8731_drvr_config_seq.dac_en = 1;
      wm8731_drvr_config_seq.adc_en = 1;
      wm8731_drvr_config_seq.bps    = BPS_32;
      wm8731_drvr_config_seq.fs_div_val = 70; //not as per fs

      fork
        begin
          adc_load_seq.start(super.env.acortex_env.codec_agent.adc_seqr);
        end

        begin
          #100;
          wm8731_drvr_config_seq.start(super.env.lb_agent.seqr);
        end
      join_any

      adc_cap_seq.start(super.env.lb_agent.seqr);

      #10;

      for(int i=0; i<128; i++)
      begin
        if(adc_cap_seq.cap_pkt.data[i]  !=  adc_load_seq.pcm_pkt.pcm_data[i].rchnnl)
          ovm_report_error(get_name(),$psprintf("Mismatch in ADC CAP rchnnl data[%1d] | Expected 0x%x, Actual 0x%x",i,adc_load_seq.pcm_pkt.pcm_data[i].rchnnl,adc_cap_seq.cap_pkt.data[i]),OVM_LOW);

        if(adc_cap_seq.cap_pkt.data[i+128]  !=  adc_load_seq.pcm_pkt.pcm_data[i].lchnnl)
          ovm_report_error(get_name(),$psprintf("Mismatch in ADC CAP lchnnl data[%1d] | Expected 0x%x, Actual 0x%x",i,adc_load_seq.pcm_pkt.pcm_data[i].lchnnl,adc_cap_seq.cap_pkt.data[i+128]),OVM_LOW);
      end

      ovm_report_info(get_name(),"Calling global_stop_request().....",OVM_LOW);
      global_stop_request();

      ovm_report_info(get_full_name(),"End of run",OVM_LOW);
    endtask : run 


endclass : syn_cortex_adc_cap_test
