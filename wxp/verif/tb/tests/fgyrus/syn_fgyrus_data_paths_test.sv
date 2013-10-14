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
 -- Test Name         : syn_fgyrus_data_paths_test
 -- Author            : mammenx
 -- Function          : This test checks the basic data paths & pipelines
                        in Fgyrus.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

import  syn_fft_pkg::*;

class syn_fgyrus_data_paths_test extends syn_fgyrus_base_test;

    `ovm_component_utils(syn_fgyrus_data_paths_test)

    //Sequences
    syn_pcm_mem_load_seq#(super.PCM_SEQ_ITEM_T,super.PCM_SEQR_T)  pcm_mem_load_seq;
    syn_fgyrus_config_seq#(super.LB_SEQ_ITEM_T,super.LB_SEQR_T)   fgyrus_config_seq;


    OVM_FILE  f;

    /*  Constructor */
    function new (string name="syn_fgyrus_data_paths_test", ovm_component parent=null);
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

      fgyrus_config_seq = syn_fgyrus_config_seq#(super.LB_SEQ_ITEM_T,super.LB_SEQR_T)::type_id::create("fgyrus_config_seq");
      pcm_mem_load_seq  = syn_pcm_mem_load_seq#(super.PCM_SEQ_ITEM_T,super.PCM_SEQR_T)::type_id::create("pcm_mem_load_seq");

      ovm_report_info(get_full_name(),"End of build",OVM_LOW);
    endfunction : build


    /*  Connect */
    function  void  connect();
      super.connect();

      ovm_report_info(get_full_name(),"Start of connect",OVM_LOW);


      ovm_report_info(get_full_name(),"End of connect",OVM_LOW);
    endfunction : connect


    /*  End of Elaboration  */
    function void end_of_elaboration();
      super.end_of_elaboration();
    endfunction


    /*  Run */
    virtual task run ();
      ovm_report_info(get_full_name(),"Start of run",OVM_LOW);

      super.env.sprint();

      #500;

      fgyrus_config_seq.fgyrus_en   = 1;
      fgyrus_config_seq.fgyrus_mode = syn_fft_pkg::NORMAL;
      fgyrus_config_seq.fgyrus_post_norm  = 0;

      fgyrus_config_seq.start(super.env.lb_agent.seqr);

      #100ns;

      //  pcm_mem_load_seq.pcm_pkt.pcm_data = new[128];
      //  pcm_mem_load_seq.pcm_pkt.pcm_data[0].lchnnl = $random;
      //  pcm_mem_load_seq.pcm_pkt.pcm_data[0].rchnnl = $random;

      //  foreach(pcm_mem_load_seq.pcm_pkt.pcm_data[i])
      //  begin
      //    pcm_mem_load_seq.pcm_pkt.pcm_data[i].lchnnl = pcm_mem_load_seq.pcm_pkt.pcm_data[0].lchnnl;
      //    pcm_mem_load_seq.pcm_pkt.pcm_data[i].rchnnl = pcm_mem_load_seq.pcm_pkt.pcm_data[0].rchnnl;
      //  end

      pcm_mem_load_seq.pcm_pkt.fill_inc(128,0,1);
      pcm_mem_load_seq.start(super.env.pcm_mem_agent.seqr);

      #150us;

      ovm_report_info(get_name(),"Calling global_stop_request().....",OVM_LOW);
      global_stop_request();

      ovm_report_info(get_full_name(),"End of run",OVM_LOW);
    endtask : run


endclass : syn_fgyrus_data_paths_test
