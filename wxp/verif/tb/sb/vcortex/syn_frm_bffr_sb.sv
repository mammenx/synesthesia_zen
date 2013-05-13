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
`ovm_analysis_imp_decl(_lb)
`ovm_analysis_imp_decl(_sram)
`ovm_analysis_imp_decl(_pxlgw_ingr)

  import  syn_gpu_pkg::*;
  import  syn_image_pkg::syn_calc_shade;

  class syn_frm_bffr_sb #(type  LB_PKT_TYPE = syn_lb_seq_item#(32,16),
                          type  SRAM_PKT_TYPE = syn_lb_seq_item#(16,18),
                          type  PXL_XFR_PKT_TYPE = syn_gpu_pxl_xfr_seq_item#(pxl_hsi_t)
                        ) extends ovm_scoreboard;

    `include  "syn_vcortex_reg_map.sv"

    /*  Register with Factory */
    `ovm_component_param_utils(syn_frm_bffr_sb#(LB_PKT_TYPE, SRAM_PKT_TYPE,PXL_XFR_PKT_TYPE))


    //Ports
    ovm_analysis_imp_sram#(SRAM_PKT_TYPE,syn_frm_bffr_sb#(LB_PKT_TYPE,SRAM_PKT_TYPE,PXL_XFR_PKT_TYPE))  SramMon2SB_Port;
    ovm_analysis_imp_lb#(LB_PKT_TYPE,syn_frm_bffr_sb#(LB_PKT_TYPE,SRAM_PKT_TYPE,PXL_XFR_PKT_TYPE))  LbMon2SB_Port;
    ovm_analysis_imp_pxlgw_ingr#(PXL_XFR_PKT_TYPE,syn_frm_bffr_sb#(LB_PKT_TYPE,SRAM_PKT_TYPE,PXL_XFR_PKT_TYPE))  PxlGwSinffer2SB_Port;

    OVM_FILE  f;

    //Shadow register to hold the value of the GPU JOB BFFR registers
    syn_reg_map#(32)  gpu_reg_set;

    //Queue to hold pending expected frame buffer write transactions
    SRAM_PKT_TYPE frm_bffr_pending_xtns[$];

    //Queue to hold sram write xtns
    SRAM_PKT_TYPE sram_wr_xtns[$];

    //Queue to hold sniffed scents
    PXL_XFR_PKT_TYPE  pxlgw_xtns[$];

    //Mailbox to hold gpu_draw_jobs
    mailbox#(gpu_draw_job_t)  gpu_draw_job_mb;


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

      SramMon2SB_Port = new("SramMon2SB_Port", this);
      LbMon2SB_Port = new("LbMon2SB_Port", this);
      PxlGwSinffer2SB_Port  = new("PxlGwSinffer2SB_Port", this);

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

      gpu_draw_job_mb = new(1);

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction

    /*
      * Write Sniffed xtns
      * This function will be called each time the pxlgw_ingr_sniffer writes to PxlGwSinffer2SB_Port
    */
    virtual function void write_pxlgw_ingr(input PXL_XFR_PKT_TYPE pkt);
      ovm_report_info({get_name(),"[write_pxlgw_ingr]"},$psprintf("Received pkt\n%s",pkt.sprint()),OVM_LOW);

      //Push to queue
      pxlgw_xtns.push_back(pkt);

    endfunction :write_pxlgw_ingr 

    /*
      * Write Sent Pkt
      * This function will be called each time a pkt is written into [ovm_analysis_imp_lb]LbMon2SB_Port
    */
    virtual function void write_lb(input LB_PKT_TYPE  pkt);
      ovm_report_info({get_name(),"[write_lb]"},$psprintf("Received pkt\n%s",pkt.sprint()),OVM_LOW);

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

    endfunction : write_lb

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

        if(gpu_draw_job_mb.try_put(draw_job))
          ovm_report_info({get_name(),"[extract_gpu_job]"},$psprintf("Placed GPU Draw Job into gpu_draw_job_mb"),OVM_LOW);
        else
          ovm_report_fatal({get_name(),"[extract_gpu_job]"},$psprintf("Could not place GPU Draw Job into gpu_draw_job_mb!"),OVM_LOW);

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


    /*  Task to process a draw job & derive the set of pixel writes */
    virtual task  process_draw_job;
      int x0,y0,x1,y1,dx,dy,sx,sy,err,e2;
      gpu_draw_job_t  job;
      PXL_XFR_PKT_TYPE  actual_xtn;
      PXL_XFR_PKT_TYPE  exptd_xtn;
      string  res;

      ovm_report_info({get_name(),"[process_draw_job]"},$psprintf("Start of process_draw_job"),OVM_LOW);

      forever
      begin
        ovm_report_info({get_name(),"[process_draw_job]"},$psprintf("Waiting on gpu_draw_job_mb"),OVM_LOW);
        gpu_draw_job_mb.get(job);

        ovm_report_info({get_name(),"[process_draw_job]"},$psprintf("Processing job :\n%s",sprint_gpu_draw_job(job)),OVM_LOW);

        $cast(x0, job.x0);
        $cast(y0, job.y0);
        $cast(x1, job.x1);
        $cast(y1, job.y1);

        if(x0 > x1)
        begin
          dx  = x0  - x1;
          sx  = -1;
        end
        else
        begin
          dx  = x1  - x0;
          sx  = 1;
        end

        if(y0 > y1)
        begin
          dy  = y0  - y1;
          sy  = -1;
        end
        else
        begin
          dy  = y1  - y0;
          sy  = 1;
        end

        err = dx  - dy;

        ovm_report_info({get_name(),"[process_draw_job]"},$psprintf("dx : %1d, dy : %1d, sx : %1d, sy : %1d",dx,dy,sx,sy),OVM_LOW);

        while(1)
        begin
          ovm_report_info({get_name(),"[process_draw_job]"},$psprintf("Waiting for sniffer"),OVM_LOW);
          while(!pxlgw_xtns.size())  #1;

          actual_xtn  = new();
          actual_xtn  = pxlgw_xtns.pop_front();
          ovm_report_info({get_name(),"[process_draw_job]"},$psprintf("Received sniffer xtn :\n%s",actual_xtn.sprint()),OVM_LOW);

          exptd_xtn       = new();
          exptd_xtn.posx  = x0;
          exptd_xtn.posy  = y0;
          exptd_xtn.pxl   = job.color;
          exptd_xtn.xtn   = PXL_WRITE;

          res = actual_xtn.check(exptd_xtn);

          if(res  ==  "")
            ovm_report_info({get_name(),"[process_draw_job]"},$psprintf("PxlGw XTN Valid"),OVM_LOW);
          else
            ovm_report_error({get_name(),"[process_draw_job]"},$psprintf("PxlGw XTN Invalid %s",res),OVM_LOW);

          putPixel(exptd_xtn);

          e2  = 2*err;

          if((x0  ==  x1) &&  (y0 ==  y1))
          begin
            break;
          end

          if(e2 + dy  > 0)
          begin
            err     -=  dy;
            x0      +=  sx;
          end

          if(e2 - dx  < 0)
          begin
            err     +=  dx;
            y0      +=  sy;
          end
        end

        ovm_report_info({get_name(),"[process_draw_job]"},$psprintf("End of job %s",sprint_gpu_draw_job(job)),OVM_LOW);
      end
    endtask: process_draw_job

    //Function to convert pixel coordinates to frame buffer address & push into queue
    function  void  putPixel(PXL_XFR_PKT_TYPE pkt);
      SRAM_PKT_TYPE pkt_sram;

      if((pkt.posx  >=  P_CANVAS_W) ||  (pkt.posy >=  P_CANVAS_H))  return;
      if((pkt.posx  <   0)          ||  (pkt.posy <   0))           return;

      pkt_sram       = new();
      pkt_sram.addr  = new[1];
      pkt_sram.data  = new[1];
      pkt_sram.lb_xtn  = WRITE;

      pkt_sram.addr[0] = ((pkt.posy*P_CANVAS_W)  + pkt.posx)/2;

      //ovm_report_info({get_name(),"[putPixel]"},$psprintf("x : %1d, y : %1d, pxl[h s i] : %1d %1d %1d",pkt.posx,pkt.posy,pkt.pxl.h,pkt.pxl.s,pkt.pxl.i),OVM_LOW);

      if((pkt.posx % 2)  ==  0)  //LB
      begin
        //$cast(pkt_sram.data,{8'dx,pxl});
        pkt_sram.data[0][7:0]  = pkt.pxl;
        pkt_sram.data[0][15:8] = 'd0;
      end
      else  //UB
      begin
        //$cast(pkt_sram.data,{pxl,8'dx});
        pkt_sram.data[0][7:0]  = 'd0;
        pkt_sram.data[0][15:8] = pkt.pxl;
      end

      frm_bffr_pending_xtns.push_back(pkt_sram);
      ovm_report_info({get_name(),"[putPixel]"},$psprintf("Pushed sram_pkt to frm_bffr_pending_xtns [size=%1d] :\n%s",frm_bffr_pending_xtns.size,pkt_sram.sprint()),OVM_LOW);

    endfunction : putPixel

    /*
      * Write Rcvd Pkt
      * This function will be called each time a pkt is written into [ovm_analysis_imp_sram]SramMon2SB_Port
    */
    virtual function void write_sram(input SRAM_PKT_TYPE pkt);
      ovm_report_info({get_name(),"[write_sram]"},$psprintf("Received pkt\n%s",pkt.sprint()),OVM_LOW);

      sram_wr_xtns.push_back(pkt);
    endfunction : write_sram


    /*
      * Function to check the validity of each SRAM write
    */
    task check_sram_writes();
      SRAM_PKT_TYPE exptd_pkt,actual_pkt;

      ovm_report_info({get_name(),"[check_sram_writes]"},"Start of check_sram_writes",OVM_LOW);

      forever
      begin
        //Wait for items to arrive in sent & rcvd queues
        ovm_report_info({get_name(),"[check_sram_writes]"},"Waiting on sram_wr_xtns queue ...",OVM_LOW);
        while(!sram_wr_xtns.size())  #1;

        if(!frm_bffr_pending_xtns.size())
        begin
          actual_pkt  = sram_wr_xtns.pop_front();
          ovm_report_error({get_name(),"[check_sram_writes]"},$psprintf("frm_bffr_pending_xtns queue is empty. Unexpected SRAM write \n%s",actual_pkt.sprint()),OVM_LOW);
        end
        else
        begin
          //Extract pkts from front of queues
          actual_pkt  = sram_wr_xtns.pop_front();
          exptd_pkt   = frm_bffr_pending_xtns.pop_front();

          //Process, compare, check ...
          if(exptd_pkt.check(actual_pkt))
          begin
            ovm_report_info({get_name(),"[check_sram_writes]"},"SRAM Write is valid",OVM_LOW);
          end
          else
          begin
            ovm_report_error({get_name(),"[check_sram_writes]"},"SRAM Write is invalid",OVM_LOW);
          end
        end
      end

    endtask : check_sram_writes


    /*  Run */
    virtual task  run();
      ovm_report_info({get_name(),"[run]"},"Start of run",OVM_LOW);

      fork
        begin
          check_sram_writes();
        end

        begin
          process_draw_job();
        end
      join

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
