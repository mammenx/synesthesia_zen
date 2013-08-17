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
 -- Test Name         : syn_vcortex_gpu_fill_test
 -- Author            : mammenx
 -- Function          : This test generates different Fill jobs to GPU
                        and stimulates the picasso module.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

import  syn_gpu_pkg::*;

class syn_vcortex_gpu_fill_test extends syn_vcortex_base_test;

    `ovm_component_utils(syn_vcortex_gpu_fill_test)

    //Sequences
    syn_gpu_enable_seq#(super.LB_SEQ_ITEM_T,super.LB_SEQR_T)          gpu_en_seq;
    syn_gpu_fill_job_config_seq#(super.LB_SEQ_ITEM_T,super.LB_SEQR_T) gpu_fill_job_seq;
    syn_poll_gpu_status_seq#(super.LB_SEQ_ITEM_T,super.LB_SEQR_T)     gpu_status_poll_seq;


    OVM_FILE  f;

    /*  Constructor */
    function new (string name="syn_vcortex_gpu_fill_test", ovm_component parent=null);
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
      gpu_fill_job_seq    = syn_gpu_fill_job_config_seq#(super.LB_SEQ_ITEM_T,super.LB_SEQR_T)::type_id::create("gpu_fill_job_config_seq");
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
      int i;

      ovm_report_info(get_full_name(),"Start of run",OVM_LOW);

      super.env.sprint();

      super.init_fb();

      #500;

      gpu_en_seq.start(super.env.lb_agent.seqr);

      #1000;

      //Build Job
      gpu_fill_job_seq.job.fill_color.h  = 0;
      gpu_fill_job_seq.job.fill_color.s  = 3;
      gpu_fill_job_seq.job.fill_color.i  = 15;
      gpu_fill_job_seq.job.line_color.h  = 1;
      gpu_fill_job_seq.job.line_color.s  = 3;
      gpu_fill_job_seq.job.line_color.i  = 15;
      gpu_fill_job_seq.job.x0 = (P_CANVAS_W/3) + 2;
      gpu_fill_job_seq.job.y0 = (P_CANVAS_H/3) + 2;

      //Draw polygon
      draw_poly(gpu_fill_job_seq.job.line_color);

      //Start Job
      gpu_fill_job_seq.start(super.env.lb_agent.seqr);

      fork
        begin
          gpu_status_poll_seq.start(super.env.lb_agent.seqr);
        end

        //begin
        //  i = 0;

        //  repeat(200)
        //  begin
        //    @($root.syn_vcortex_tb_top.sys_clk_50 iff $root.syn_vcortex_tb_top.syn_vcortex_inst.syn_gpu_inst.syn_gpu_core_inst.syn_gpu_core_picasso_inst.fsm_pstate != 'd2);
        //    @($root.syn_vcortex_tb_top.sys_clk_50 iff $root.syn_vcortex_tb_top.syn_vcortex_inst.syn_gpu_inst.syn_gpu_core_inst.syn_gpu_core_picasso_inst.fsm_pstate == 'd2);

        //    ovm_report_info(get_name(),$psprintf("Loop:%1d",i),OVM_LOW);
        //  end
        //end
      join_any

      #100ns;

      ovm_report_info(get_name(),"Calling global_stop_request().....",OVM_LOW);
      global_stop_request();

      ovm_report_info(get_full_name(),"End of run",OVM_LOW);
    endtask : run

    //Function to draw a polygon in frame buffer
    function  void  draw_poly(pxl_hsi_t pxl);
      /*  square  */

      for(int i=0, j=0; i<10; i++)  //horizontal1
        write_pxl(pxl,i+(P_CANVAS_W/3),j+(P_CANVAS_H/3));

      for(int i=0, j=10; i<10; i++)  //horizontal2
        write_pxl(pxl,i+(P_CANVAS_W/3),j+(P_CANVAS_H/3));

      for(int i=0, j=0; j<10; j++)  //vertical1
        write_pxl(pxl,i+(P_CANVAS_W/3),j+(P_CANVAS_H/3));

      for(int i=10, j=0; j<10; j++)  //vertical2
        write_pxl(pxl,i+(P_CANVAS_W/3),j+(P_CANVAS_H/3));

    endfunction : draw_poly

    //Function to write pixel to a particular position in the frame buffer
    function  void  write_pxl(input pxl_hsi_t pxl,  input int x,y);
      int addr  = (y*640) + x;
      int msb_n_lsb = addr  % 2;
      addr  = addr  >>  1;

      mod_fb(pxl,addr,msb_n_lsb);
    endfunction : write_pxl

    //function to modify the frame buffer contents via back door access
    function  void mod_fb(input pxl_hsi_t pxl, input int addr,msb_n_lsb);
      bit [SRAM_DATA_W-1:0] tmp;

      tmp = super.env.sram_agent.drvr.frm_bffr[addr];

      if(msb_n_lsb) //modify MSB
      begin
        $cast(tmp[SRAM_DATA_W-1:SRAM_DATA_W/2],pxl);
      end
      else  //modify LSB
      begin
        $cast(tmp[(SRAM_DATA_W/2)-1:0],pxl);
      end

      super.env.sram_agent.drvr.frm_bffr[addr]  = tmp;
    endfunction : mod_fb

endclass : syn_vcortex_gpu_fill_test
