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
 -- Test Name         : syn_vcortex_gpu_draw_line_test
 -- Author            : mammenx
 -- Function          : This test generates different Draw Line jobs to GPU
                        and stimulates the euclid module.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

import  syn_gpu_pkg::*;

class syn_vcortex_gpu_draw_line_test extends syn_vcortex_base_test;

    `ovm_component_utils(syn_vcortex_gpu_draw_line_test)

    //Sequences
    syn_gpu_enable_seq#(super.LB_SEQ_ITEM_T,super.LB_SEQR_T)          gpu_en_seq;
    syn_gpu_draw_job_config_seq#(super.LB_SEQ_ITEM_T,super.LB_SEQR_T) gpu_draw_job_seq;
    syn_poll_gpu_status_seq#(super.LB_SEQ_ITEM_T,super.LB_SEQR_T)     gpu_status_poll_seq;


    OVM_FILE  f;

    /*  Constructor */
    function new (string name="syn_vcortex_gpu_draw_line_test", ovm_component parent=null);
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

      gpu_en_seq          = syn_gpu_enable_seq#(super.LB_SEQ_ITEM_T,super.LB_SEQR_T)::type_id::create("gpu_en_seq");
      gpu_draw_job_seq    = syn_gpu_draw_job_config_seq#(super.LB_SEQ_ITEM_T,super.LB_SEQR_T)::type_id::create("gpu_draw_job_config_seq");
      gpu_status_poll_seq = syn_poll_gpu_status_seq#(super.LB_SEQ_ITEM_T,super.LB_SEQR_T)::type_id::create("gpu_status_poll_seq");
      

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

      super.init_fb();

      #500;

      gpu_en_seq.start(super.env.lb_agent.seqr);

      #1000;

      //Build Job
      gpu_draw_job_seq.job.shape  = LINE;
      gpu_draw_job_seq.job.x0     = 0;
      gpu_draw_job_seq.job.y0     = 0;
      gpu_draw_job_seq.job.x1     = P_CANVAS_W-1;
      gpu_draw_job_seq.job.y1     = P_CANVAS_H-1;
      //gpu_draw_job_seq.job.x1     = 10;
      //gpu_draw_job_seq.job.y1     = 10;
      //$cast(gpu_draw_job_seq.job.color, $random);
      gpu_draw_job_seq.job.color.h  = 0;
      gpu_draw_job_seq.job.color.s  = 3;
      gpu_draw_job_seq.job.color.i  = 15;
      $cast(gpu_draw_job_seq.job.width, $random);

      gpu_draw_job_seq.start(super.env.lb_agent.seqr);


      gpu_status_poll_seq.start(super.env.lb_agent.seqr);

      #1us;

      ovm_report_info(get_name(),"Calling global_stop_request().....",OVM_LOW);
      global_stop_request();

      ovm_report_info(get_full_name(),"End of run",OVM_LOW);
    endtask : run 

endclass : syn_vcortex_gpu_draw_line_test
