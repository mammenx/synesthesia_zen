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
 -- Component Name    : syn_frm_bffr_sb
 -- Author            : mammenx
 -- Function          : This scoreboard receives GPU local bus transactions
                        and decodes them into GPU job info. Once GPU job is
                        triggered, the set of pixel modifications to the
                        frame buffer are generated. Pixel writes made to the
                        frame buffer by the GPU DUT are compared against this
                        set & checked for correctness.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_FRM_BFFR_SB
`define __SYN_FRM_BFFR_SB

//Implicit port declarations
`ovm_analysis_imp_decl(_rcvd_pkt)
`ovm_analysis_imp_decl(_sent_pkt)

  import  syn_gpu_pkg::*;

  class syn_frm_bffr_sb #(type  SENT_PKT_TYPE = syn_lb_seq_item,
                          type  RCVD_PKT_TYPE = syn_lb_seq_item
                        ) extends ovm_scoreboard;

    `include  "syn_vcortex_reg_map.sv"

    /*  Register with Factory */
    `ovm_component_param_utils(syn_frm_bffr_sb#(SENT_PKT_TYPE, RCVD_PKT_TYPE))


    //Ports
    ovm_analysis_imp_sent_pkt #(SENT_PKT_TYPE,syn_frm_bffr_sb#(SENT_PKT_TYPE,RCVD_PKT_TYPE))  Mon_sent_2Sb_port;
    ovm_analysis_imp_rcvd_pkt #(RCVD_PKT_TYPE,syn_frm_bffr_sb#(SENT_PKT_TYPE,RCVD_PKT_TYPE))  Mon_rcvd_2Sb_port;

    OVM_FILE  f;

    //Shadow register to hold the value of the GPU JOB BFFR registers
    syn_reg_map#(32)  gpu_reg_set;

    //Queue to hold pending expected frame buffer write transactions
    RCVD_PKT_TYPE frm_bffr_pending_xtns[$];

    //Queue to hold sram write xtns
    RCVD_PKT_TYPE sram_wr_xtns[$];


    /*  Constructor */
    function new(string name = "syn_frm_bffr_sb", ovm_component parent);
      super.new(name, parent);
    endfunction : new


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

      Mon_sent_2Sb_port = new("Mon_sent_2Sb_port", this);
      Mon_rcvd_2Sb_port = new("Mon_rcvd_2Sb_port", this);

      //gpu_reg_set  = new("gpu_reg_set", this);
      gpu_reg_set = syn_reg_map#(32)::type_id::create("gpu_reg_set",  this);
      gpu_reg_set.create_field("gpu_en",VCORTEX_GPU_CONTROL_REG_ADDR,0,0);
      gpu_reg_set.create_field("gpu_job_bffr_0",VCORTEX_GPU_JOB_BFFR_0_REG_ADDR,0,31);
      gpu_reg_set.create_field("gpu_job_bffr_1",VCORTEX_GPU_JOB_BFFR_1_REG_ADDR,0,31);
      gpu_reg_set.create_field("gpu_job_bffr_2",VCORTEX_GPU_JOB_BFFR_2_REG_ADDR,0,31);
      gpu_reg_set.create_field("gpu_job_bffr_3",VCORTEX_GPU_JOB_BFFR_3_REG_ADDR,0,31);
      gpu_reg_set.create_field("gpu_job_bffr_4",VCORTEX_GPU_JOB_BFFR_4_REG_ADDR,0,31);
      gpu_reg_set.create_field("gpu_job_bffr_5",VCORTEX_GPU_JOB_BFFR_5_REG_ADDR,0,31);
      gpu_reg_set.create_field("gpu_job_bffr_6",VCORTEX_GPU_JOB_BFFR_6_REG_ADDR,0,31);
      gpu_reg_set.create_field("gpu_job_bffr_7",VCORTEX_GPU_JOB_BFFR_7_REG_ADDR,0,31);

      frm_bffr_pending_xtns = '{};  //clear the queue

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction


    /*
      * Write Sent Pkt
      * This function will be called each time a pkt is written into [ovm_analysis_imp_sent_pkt]Mon_sent_2Sb_port
    */
    virtual function void write_sent_pkt(input SENT_PKT_TYPE  pkt);
      ovm_report_info({get_name(),"[write_sent_pkt]"},$psprintf("Received pkt\n%s",pkt.sprint()),OVM_LOW);

      //Update shadow registers
      if((pkt.lb_xtn  ==  WRITE)  ||  (pkt.lb_xtn ==  BURST_WRITE))
      begin
        foreach(pkt.addr[i])
        begin
          gpu_reg_set.set_reg(pkt.addr[i], pkt.data[i]);

          if((pkt.addr[i] ==  VCORTEX_GPU_JOB_BFFR_0_REG_ADDR)  &&  (gpu_reg_set.get_field("gpu_en")  ==  1))
          begin
            extract_gpu_job();
          end
        end
      end

    endfunction : write_sent_pkt

    function  string  sprint_gpu_draw_job(gpu_draw_job_t job);
      string  res = "gpu_draw_job :\n";

      if(job.shape  ==  LINE)         res = {res,"Shape : LINE\n"};
      else if(job.shape  ==  CIRCLE)  res = {res,"Shape : CIRCLE\n"};

      res = {res,$psprintf("X0 : %1d\n",job.x0)};
      res = {res,$psprintf("Y0 : %1d\n",job.y0)};
      res = {res,$psprintf("X1 : %1d\n",job.x1)};
      res = {res,$psprintf("Y1 : %1d\n",job.y1)};
      res = {res,$psprintf("Color : 0x%1x\n",job.color)};
      res = {res,$psprintf("Width : %d\n",job.width)};

      return  res;
    endfunction : sprint_gpu_draw_job

    /*  Function  to extract GPU job contents from shadow register set  */
    function  void  extract_gpu_job();
      bit [31:0]  tmp_reg;
      action_t    action;
      gpu_draw_job_t  draw_job;
      gpu_fill_job_t  fill_job;


      $cast(action, gpu_reg_set.get_field("gpu_job_bffr_0"));

      if(action ==  DRAW)
      begin
        //$cast(draw_job.shape, gpu_reg_set.get_field("gpu_job_bffr_1"));
        //$cast(draw_job.x0,    gpu_reg_set.get_field("gpu_job_bffr_2"));
        //$cast(draw_job.y0,    gpu_reg_set.get_field("gpu_job_bffr_3"));
        //$cast(draw_job.x1,    gpu_reg_set.get_field("gpu_job_bffr_4"));
        //$cast(draw_job.y1,    gpu_reg_set.get_field("gpu_job_bffr_5"));
        //$cast(draw_job.color, gpu_reg_set.get_field("gpu_job_bffr_6"));
        //$cast(draw_job.width, gpu_reg_set.get_field("gpu_job_bffr_7"));
        draw_job.shape    = shape_t'(gpu_reg_set.get_field("gpu_job_bffr_1") & 2'b11);
        draw_job.x0       = gpu_reg_set.get_field("gpu_job_bffr_2") & {P_X_W{1'b1}};
        draw_job.y0       = gpu_reg_set.get_field("gpu_job_bffr_3") & {P_Y_W{1'b1}};
        draw_job.x1       = gpu_reg_set.get_field("gpu_job_bffr_4") & {P_X_W{1'b1}};
        draw_job.y1       = gpu_reg_set.get_field("gpu_job_bffr_5") & {P_Y_W{1'b1}};
        draw_job.color    = gpu_reg_set.get_field("gpu_job_bffr_6");
        draw_job.width    = gpu_reg_set.get_field("gpu_job_bffr_7");


        ovm_report_info({get_name(),"[extract_gpu_job]"},$psprintf("Start of extract_gpu_job : \n%s",  sprint_gpu_draw_job(draw_job)),OVM_LOW);

        process_draw_job(draw_job);

        ovm_report_info({get_name(),"[extract_gpu_job]"},$psprintf("Contents of frm_bffr_pending_xtns ...\n%s",sprint_frm_bffr_pending_xtns()),OVM_LOW);
      end
      else
      begin
        ovm_report_warning({get_name(),"[extract_gpu_job]"},$psprintf("Unidentified GPU action %s",action.name()),OVM_LOW);
      end
    endfunction : extract_gpu_job

    function  string  sprint_frm_bffr_pending_xtns();
      string  res = "";

      foreach(frm_bffr_pending_xtns[i])
        res = {res,$psprintf("[%1d] ----->\n%s\n",i,frm_bffr_pending_xtns[i].sprint())};

        return  res;
    endfunction : sprint_frm_bffr_pending_xtns


    /*  Function to process a draw job & derive the set of pixel writes */
    function  process_draw_job(gpu_draw_job_t job);
      int dx,dy,sx,sy,err,v1,e2;

      if(job.x0 > job.x1)
      begin
        dx  = job.x0  - job.x1;
        sx  = -1;
      end
      else
      begin
        dx  = job.x1  - job.x0;
        sx  = 1;
      end

      if(job.y0 > job.y1)
      begin
        dy  = job.y0  - job.y1;
        sy  = -1;
      end
      else
      begin
        dy  = job.y1  - job.y0;
        sy  = 1;
      end

      err = dx  - dy;
      v1  = dx  - dy;

      while(1)
      begin
        e2  = 2*err;

        if(dx >=  dy)
        begin
          if(v1 > e2)
          begin
            job.color.i = ((v1-e2)/dx)*job.color.i;
            putPixel(job.x0,job.y0,job.color);
            job.color.i = 15  - job.color.i;
            putPixel(job.x0,job.y0+1,job.color);
          end
          else
          begin
            job.color.i = ((e2-v1)/dx)*job.color.i;
            putPixel(job.x0,job.y0,job.color);
            job.color.i = 15  - job.color.i;
            putPixel(job.x0,job.y0-1,job.color);
          end
        end
        else
        begin
          if(v1 < e2)
          begin
            job.color.i = ((e2-v1)/dx)*job.color.i;
            putPixel(job.x0,job.y0,job.color);
            job.color.i = 15  - job.color.i;
            putPixel(job.x0+1,job.y0,job.color);
          end
          else
          begin
            job.color.i = ((v1-e2)/dx)*job.color.i;
            putPixel(job.x0,job.y0,job.color);
            job.color.i = 15  - job.color.i;
            putPixel(job.x0-1,job.y0,job.color);
          end
        end

        if((job.x0  ==  job.x1) &&  (job.y0 ==  job.y1))
        begin
          break;
        end

        if(e2 + dy  > 0)
        begin
          err     -=  dy;
          job.x0  +=  sx;
        end

        if(e2 - dx  < 0)
        begin
          err     +=  dx;
          job.y0  +=  sy;
        end
      end

    endfunction : process_draw_job

    //Function to convert pixel coordinates to frame buffer address & push into queue
    function  void  putPixel(int x, int y, pxl_ycbcr_t pxl);
      RCVD_PKT_TYPE pkt = new();
      pkt.addr  = new[1];
      pkt.data  = new[1];
      pkt.lb_xtn  = WRITE;

      pkt.addr[0] = ((y*P_CANVAS_W)  + x)/2;

      if(x  % 2)
      begin
        //$cast(pkt.data,{8'dx,pxl});
        pkt.data[0][7:0]  = pxl;
        pkt.data[0][15:0] = 'dx;
      end
      else
      begin
        //$cast(pkt.data,{pxl,8'dx});
        pkt.data[0][7:0]  = 'dx;
        pkt.data[0][15:0] = pxl;
      end

      frm_bffr_pending_xtns.push_back(pkt);

    endfunction : putPixel

    /*
      * Write Rcvd Pkt
      * This function will be called each time a pkt is written into [ovm_analysis_imp_rcvd_pkt]Mon_rcvd_2Sb_port
    */
    virtual function void write_rcvd_pkt(input RCVD_PKT_TYPE pkt);
      ovm_report_info({get_name(),"[write_rcvd_pkt]"},$psprintf("Received pkt\n%s",pkt.sprint()),OVM_LOW);

      sram_wr_xtns.push_back(pkt);
    endfunction : write_rcvd_pkt


    /*  Run */
    task run();
      RCVD_PKT_TYPE exptd_pkt,actual_pkt;

      ovm_report_info({get_name(),"[run]"},"Start of run",OVM_LOW);

      forever
      begin
        //Wait for items to arrive in sent & rcvd queues
        ovm_report_info({get_name(),"[run]"},"Waiting on sram_wr_xtns queue ...",OVM_LOW);
        while(!sram_wr_xtns.size())  #1;

        if(!frm_bffr_pending_xtns.size())
        begin
          actual_pkt  = sram_wr_xtns.pop_front();
          ovm_report_error({get_name(),"[run]"},$psprintf("frm_bffr_pending_xtns queue is empty. Unexpected SRAM write \n%s",actual_pkt.sprint()),OVM_LOW);
        end
        else
        begin
          //Extract pkts from front of queues
          actual_pkt  = sram_wr_xtns.pop_front();
          exptd_pkt   = frm_bffr_pending_xtns.pop_front();

          //Process, compare, check ...
          if(exptd_pkt.check(actual_pkt))
          begin
            ovm_report_info({get_name(),"[run]"},"SRAM Write is valid",OVM_LOW);
          end
          else
          begin
            ovm_report_error({get_name(),"[run]"},"SRAM Write is invalid",OVM_LOW);
          end
        end
      end

    endtask : run


    /*  Report  */
    virtual function void report();
      if(frm_bffr_pending_xtns.size())
        ovm_report_error({get_name(),"[report]"},$psprintf("[%d] xtns left in frm_bffr_pending_xtns queue", frm_bffr_pending_xtns.size()),OVM_LOW);

      if(sram_wr_xtns.size())
        ovm_report_error({get_name(),"[report]"},$psprintf("[%d] xtns left in sram_wr_xtns  queue", sram_wr_xtns.size()),OVM_LOW);

      ovm_report_info({get_type_name(),"[report]"},$psprintf("Report -\n%s", this.sprint()), OVM_LOW);
    endfunction : report

  endclass : syn_frm_bffr_sb

`endif
