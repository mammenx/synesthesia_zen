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
`ovm_analysis_imp_decl(_pxlgw_egr)

  import  syn_gpu_pkg::*;
  import  syn_image_pkg::syn_calc_shade;

  class syn_frm_bffr_sb #(type  LB_PKT_TYPE = syn_lb_seq_item#(32,16),
                          type  SRAM_PKT_TYPE = syn_lb_seq_item#(16,18),
                          type  PXL_XFR_PKT_TYPE = syn_gpu_pxl_xfr_seq_item#(pxl_hsi_t),
                          type  SRAM_DRVR_TYPE = syn_sram_drvr,
                          parameter SRAM_DATA_W = 16
                        ) extends ovm_scoreboard;

    `include  "syn_vcortex_reg_map.sv"

    /*  Register with Factory */
    `ovm_component_param_utils(syn_frm_bffr_sb#(LB_PKT_TYPE, SRAM_PKT_TYPE,PXL_XFR_PKT_TYPE,SRAM_DRVR_TYPE,SRAM_DATA_W))


    //Ports
    ovm_analysis_imp_sram#(SRAM_PKT_TYPE,syn_frm_bffr_sb#(LB_PKT_TYPE,SRAM_PKT_TYPE,PXL_XFR_PKT_TYPE,SRAM_DRVR_TYPE,SRAM_DATA_W))  SramMon2SB_Port;
    ovm_analysis_imp_lb#(LB_PKT_TYPE,syn_frm_bffr_sb#(LB_PKT_TYPE,SRAM_PKT_TYPE,PXL_XFR_PKT_TYPE,SRAM_DRVR_TYPE,SRAM_DATA_W))  LbMon2SB_Port;
    ovm_analysis_imp_pxlgw_ingr#(PXL_XFR_PKT_TYPE,syn_frm_bffr_sb#(LB_PKT_TYPE,SRAM_PKT_TYPE,PXL_XFR_PKT_TYPE,SRAM_DRVR_TYPE,SRAM_DATA_W))  PxlGwSinfferIngr2SB_Port;
    ovm_analysis_imp_pxlgw_egr#(PXL_XFR_PKT_TYPE,syn_frm_bffr_sb#(LB_PKT_TYPE,SRAM_PKT_TYPE,PXL_XFR_PKT_TYPE,SRAM_DRVR_TYPE,SRAM_DATA_W))   PxlGwSinfferEgr2SB_Port;

    OVM_FILE  f;

    //Shadow register to hold the value of the GPU JOB BFFR registers
    syn_reg_map#(32)  gpu_reg_set;

    //Queue to hold pending expected frame buffer write transactions
    SRAM_PKT_TYPE frm_bffr_pending_xtns[$];

    //Queue to hold sram read/write xtns
    SRAM_PKT_TYPE sram_wr_xtns[$];
    SRAM_PKT_TYPE sram_rd_xtns[$];

    //Queue to hold sniffed scents
    PXL_XFR_PKT_TYPE  pxlgw_ingr_xtns[$];
    PXL_XFR_PKT_TYPE  pxlgw_egr_xtns[$];

    //Mailbox to hold gpu_draw_jobs
    mailbox#(gpu_draw_job_t)  gpu_draw_line_job_mb;
    mailbox#(gpu_draw_job_t)  gpu_draw_bezier_job_mb;

    //Mailbox to hold gpu_fill_jobs
    mailbox#(gpu_fill_job_t)  gpu_fill_job_mb;

    typedef struct  packed  {
      point_t p0;
      point_t p1;
      point_t p2;
      int     depth;
    } bz_set_t;

    //queue to hold bezier_gen points
    bz_set_t  bezier_points_q[$];

    //for fill job processing
    point_t fill_job_q[$];

    //GPU FF variables
    int gpu_ff_wptr,  gpu_ff_rptr;
    const int gpu_ff_size = (212  * 1024  * 8)  / (4  * 8); //number of pointers that can be stored


    SRAM_DRVR_TYPE sram_drvr; //Needs to be connected to the sram_agent.drvr

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
      PxlGwSinfferIngr2SB_Port  = new("PxlGwSinfferIngr2SB_Port", this);
      PxlGwSinfferEgr2SB_Port   = new("PxlGwSinfferEgr2SB_Port", this);

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
      gpu_reg_set.create_field("gpu_job_bffr_8",VCORTEX_GPU_JOB_BFFR_8_REG_ADDR,0,31);
      gpu_reg_set.create_field("gpu_job_bffr_9",VCORTEX_GPU_JOB_BFFR_9_REG_ADDR,0,31);

      frm_bffr_pending_xtns = '{};  //clear the queue

      //gpu_draw_line_job_mb    = new(1);
      gpu_draw_line_job_mb    = new();
      gpu_draw_bezier_job_mb  = new(1);
      gpu_fill_job_mb         = new(1);

      //set gpu_ff pointers
      gpu_ff_wptr   = (P_CANVAS_W * P_CANVAS_H) / 2;
      gpu_ff_rptr   = (P_CANVAS_W * P_CANVAS_H) / 2;

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction

    /*
      * Write Sniffed xtns
      * This function will be called each time the pxlgw_sniffer writes to PxlGwSinfferIngr2SB_Port
    */
    virtual function void write_pxlgw_ingr(input PXL_XFR_PKT_TYPE pkt);
      ovm_report_info({get_name(),"[write_pxlgw_ingr]"},$psprintf("Received pkt\n%s",pkt.sprint()),OVM_LOW);

      //Push to queue
      pxlgw_ingr_xtns.push_back(pkt);

    endfunction :write_pxlgw_ingr 

    /*
      * Write Sniffed xtns
      * This function will be called each time the pxlgw_sniffer writes to PxlGwSinfferEgr2SB_Port
    */
    virtual function void write_pxlgw_egr(input PXL_XFR_PKT_TYPE pkt);
      ovm_report_info({get_name(),"[write_pxlgw_egr]"},$psprintf("Received pkt\n%s",pkt.sprint()),OVM_LOW);

      //Push to queue
      pxlgw_egr_xtns.push_back(pkt);

    endfunction :write_pxlgw_egr

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
      else if(job.shape  ==  BEZIER)  res = {res,"Shape : BEZIER\n"};

      res = {res,$psprintf("X0 : %1d\n",job.x0)};
      res = {res,$psprintf("Y0 : %1d\n",job.y0)};
      res = {res,$psprintf("X1 : %1d\n",job.x1)};
      res = {res,$psprintf("Y1 : %1d\n",job.y1)};
      res = {res,$psprintf("X2 : %1d\n",job.x2)};
      res = {res,$psprintf("Y2 : %1d\n",job.y2)};
      res = {res,$psprintf("Color : 0x%1x\n",job.color)};
      res = {res,$psprintf("Width : %d\n",job.bzdepth)};

      return  res;
    endfunction : sprint_gpu_draw_job

    function  string  sprint_gpu_fill_job(gpu_fill_job_t job);
      string  res = "gpu_fill_job :\n";

      res = {res,$psprintf("Fill Color: 0x%1x\n",job.fill_color)};
      res = {res,$psprintf("Line Color: 0x%1x\n",job.line_color)};
      res = {res,$psprintf("X0 : %1d\n",job.x0)};
      res = {res,$psprintf("Y0 : %1d\n",job.y0)};

      return  res;
    endfunction : sprint_gpu_fill_job

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
        draw_job.x2       = gpu_reg_set.get_field("gpu_job_bffr_6") & {P_X_W{1'b1}};
        draw_job.y2       = gpu_reg_set.get_field("gpu_job_bffr_7") & {P_Y_W{1'b1}};
        draw_job.color    = gpu_reg_set.get_field("gpu_job_bffr_8");
        draw_job.bzdepth  = gpu_reg_set.get_field("gpu_job_bffr_9");


        ovm_report_info({get_name(),"[extract_gpu_job]"},$psprintf("Start of extract_gpu_job : \n%s",  sprint_gpu_draw_job(draw_job)),OVM_LOW);

        if(draw_job.shape == LINE)
        begin
          if(gpu_draw_line_job_mb.try_put(draw_job))
            ovm_report_info({get_name(),"[extract_gpu_job]"},$psprintf("Placed GPU Draw Job into gpu_draw_line_job_mb"),OVM_LOW);
          else
            ovm_report_fatal({get_name(),"[extract_gpu_job]"},$psprintf("Could not place GPU Draw Job into gpu_draw_line_job_mb!"),OVM_LOW);
        end
        else if(draw_job.shape == BEZIER)
        begin
          if(gpu_draw_bezier_job_mb.try_put(draw_job))
            ovm_report_info({get_name(),"[extract_gpu_job]"},$psprintf("Placed GPU Draw Job into gpu_draw_bezier_job_mb"),OVM_LOW);
          else
            ovm_report_fatal({get_name(),"[extract_gpu_job]"},$psprintf("Could not place GPU Draw Job into gpu_draw_bezier_job_mb!"),OVM_LOW);
        end
      end
      else if(action  ==  FILL)
      begin
        fill_job.fill_color = gpu_reg_set.get_field("gpu_job_bffr_1");
        fill_job.line_color = gpu_reg_set.get_field("gpu_job_bffr_2");
        fill_job.x0         = gpu_reg_set.get_field("gpu_job_bffr_3") & {P_X_W{1'b1}};
        fill_job.y0         = gpu_reg_set.get_field("gpu_job_bffr_4") & {P_Y_W{1'b1}};

        ovm_report_info({get_name(),"[extract_gpu_job]"},$psprintf("Start of extract_gpu_job : \n%s",  sprint_gpu_fill_job(fill_job)),OVM_LOW);

        if(gpu_fill_job_mb.try_put(fill_job))
          ovm_report_info({get_name(),"[extract_gpu_job]"},$psprintf("Placed GPU Fill Job into gpu_fill_job_mb"),OVM_LOW);
        else
          ovm_report_fatal({get_name(),"[extract_gpu_job]"},$psprintf("Could not place GPU Fill Job into gpu_fill_job_mb!"),OVM_LOW);
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


    /*  Task to process a draw line job & derive the set of pixel writes */
    virtual task  process_draw_line_job;
      int x0,y0,x1,y1,dx,dy,sx,sy,err,e2;
      gpu_draw_job_t  job;
      PXL_XFR_PKT_TYPE  actual_xtn;
      PXL_XFR_PKT_TYPE  exptd_xtn;
      string  res;

      ovm_report_info({get_name(),"[process_draw_line_job]"},$psprintf("Start of process_draw_line_job"),OVM_LOW);

      forever
      begin
        ovm_report_info({get_name(),"[process_draw_line_job]"},$psprintf("Waiting on gpu_draw_line_job_mb"),OVM_LOW);
        gpu_draw_line_job_mb.get(job);

        ovm_report_info({get_name(),"[process_draw_line_job]"},$psprintf("Processing job :\n%s",sprint_gpu_draw_job(job)),OVM_LOW);

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

        ovm_report_info({get_name(),"[process_draw_line_job]"},$psprintf("dx : %1d, dy : %1d, sx : %1d, sy : %1d",dx,dy,sx,sy),OVM_LOW);

        while(1)
        begin
          ovm_report_info({get_name(),"[process_draw_line_job]"},$psprintf("Waiting for sniffer"),OVM_LOW);
          while(!pxlgw_ingr_xtns.size())  #1;

          actual_xtn  = new();
          actual_xtn  = pxlgw_ingr_xtns.pop_front();
          ovm_report_info({get_name(),"[process_draw_line_job]"},$psprintf("Received sniffer xtn :\n%s",actual_xtn.sprint()),OVM_LOW);

          exptd_xtn       = new();
          exptd_xtn.posx  = x0;
          exptd_xtn.posy  = y0;
          exptd_xtn.pxl   = job.color;
          exptd_xtn.xtn   = PXL_WRITE;

          res = actual_xtn.check(exptd_xtn);

          if(res  ==  "")
            ovm_report_info({get_name(),"[process_draw_line_job]"},$psprintf("PxlGw XTN Valid"),OVM_LOW);
          else
            ovm_report_error({get_name(),"[process_draw_line_job]"},$psprintf("PxlGw XTN Invalid %s",res),OVM_LOW);

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

        ovm_report_info({get_name(),"[process_draw_line_job]"},$psprintf("End of job %s",sprint_gpu_draw_job(job)),OVM_LOW);
      end
    endtask: process_draw_line_job

    /*  Task to process a draw bezier job & derive the set of pixel writes  */
    virtual task  process_draw_bezier_job;
      gpu_draw_job_t  job,ljob;
      point_t m0,m1,m2;
      bz_set_t  bz_set,bz_set_nxt;
      int depth;

      ovm_report_info({get_name(),"[process_draw_bezier_job]"},$psprintf("Start of process_draw_bezier_job"),OVM_LOW);

      forever
      begin
        ovm_report_info({get_name(),"[process_draw_bezier_job]"},$psprintf("Waiting on gpu_draw_bezier_job_mb"),OVM_LOW);
        gpu_draw_bezier_job_mb.get(job);

        ovm_report_info({get_name(),"[process_draw_bezier_job]"},$psprintf("Processing job :\n%s",sprint_gpu_draw_job(job)),OVM_LOW);

        bz_set.p0.x  = job.x0; bz_set.p0.y  = job.y0;
        bz_set.p1.x  = job.x1; bz_set.p1.y  = job.y1;
        bz_set.p2.x  = job.x2; bz_set.p2.y  = job.y2;
        bz_set.depth = 0;

        bezier_points_q = '{};  //clear queue

        bezier_points_q.push_back(bz_set);

        while(bezier_points_q.size)
        begin
          bz_set  = bezier_points_q.pop_front();

          if(bz_set.depth  ==  job.bzdepth)  //issue line jobs
          begin
            ljob.shape  = LINE;
            ljob.x0     = bz_set.p0.x;
            ljob.y0     = bz_set.p0.y;
            ljob.x1     = bz_set.p1.x;
            ljob.y1     = bz_set.p1.y;
            ljob.color  = job.color;
            if(gpu_draw_line_job_mb.try_put(ljob))
              ovm_report_info({get_name(),"[process_draw_bezier_job]"},$psprintf("Placed GPU Draw Job into gpu_draw_line_job_mb"),OVM_LOW);
            else
              ovm_report_fatal({get_name(),"[process_draw_bezier_job]"},$psprintf("Could not place GPU Draw Job into gpu_draw_line_job_mb!"),OVM_LOW);

            #1;

            ljob.x0     = bz_set.p1.x;
            ljob.y0     = bz_set.p1.y;
            ljob.x1     = bz_set.p2.x;
            ljob.y1     = bz_set.p2.y;
            if(gpu_draw_line_job_mb.try_put(ljob))
              ovm_report_info({get_name(),"[process_draw_bezier_job]"},$psprintf("Placed GPU Draw Job into gpu_draw_line_job_mb"),OVM_LOW);
            else
              ovm_report_fatal({get_name(),"[process_draw_bezier_job]"},$psprintf("Could not place GPU Draw Job into gpu_draw_line_job_mb!"),OVM_LOW);

            continue;
          end

          //Calculate mid points
          m0.x  = (bz_set.p0.x + bz_set.p1.x)/2 ; m0.y  = (bz_set.p0.y + bz_set.p1.y) /2  ;
          m1.x  = (bz_set.p1.x + bz_set.p2.x)/2 ; m1.y  = (bz_set.p1.y + bz_set.p2.y) /2  ;
          m2.x  = (m0.x + m1.x)/2 ; m2.y  = (m0.y + m1.y) /2  ;

          if(m0 !=  bz_set.p0)
          begin
            bz_set_nxt.p0 = bz_set.p0;
            bz_set_nxt.p1 = m0;
            bz_set_nxt.p2 = m2;
            bz_set_nxt.depth  = bz_set.depth  + 1;
            bezier_points_q.push_back(bz_set_nxt);
          end

          if(m1 !=  bz_set.p2)
          begin
            bz_set_nxt.p0 = m2;
            bz_set_nxt.p1 = m1;
            bz_set_nxt.p2 = bz_set.p2;
            bz_set_nxt.depth  = bz_set.depth  + 1;
            bezier_points_q.push_back(bz_set_nxt);
          end
        end

        ovm_report_info({get_name(),"[process_draw_bezier_job]"},$psprintf("End of job ..."),OVM_LOW);
      end
    endtask : process_draw_bezier_job


    task  skip_xtn (input int num);
      PXL_XFR_PKT_TYPE  xtn;

      repeat(num)
      begin
        ovm_report_info({get_name(),"[skip_xtn]"},$psprintf("Waiting on pxlgw_ingr_xtns"),OVM_LOW);
        while(!pxlgw_ingr_xtns.size())  #1;

        xtn = pxlgw_ingr_xtns.pop_front();

        putPixel(xtn);
      end
    endtask : skip_xtn

    /*  Task to process a fill job & derive the set of pixel reads/writes  */
    virtual task  process_fill_job;
      gpu_fill_job_t  job;
      PXL_XFR_PKT_TYPE  actual_xtn;
      PXL_XFR_PKT_TYPE  exptd_xtn;
      string  res;
      point_t p0,p1,p2,p3,p4;

      ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("Start of process_fill_job"),OVM_LOW);

      forever
      begin
        ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("Waiting on gpu_fill_job_mb"),OVM_LOW);
        gpu_fill_job_mb.get(job);

        ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("Processing job :\n%s",sprint_gpu_fill_job(job)),OVM_LOW);

        fill_job_q  = '{};  //clear queue
        p0.x = job.x0;
        p0.y = job.y0;

        `ifdef  USE_GPU_LF_CNTRLR
          fill_job_q.push_front(p0);  //initialize the job fifo
        `else
          fill_job_q.push_back(p0);  //initialize the job fifo
        `endif

        skip_xtn(4);  //DUT Initializes Buffer

        while(fill_job_q.size)
        begin
          /*  WRITE P0  */
          skip_xtn(4);  //DUT reads P0

          p0 = fill_job_q.pop_front();

          exptd_xtn       = new();
          exptd_xtn.xtn   = PXL_WRITE;
          exptd_xtn.pxl   = job.fill_color;
          exptd_xtn.posx  = p0.x;
          exptd_xtn.posy  = p0.y;

          ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("Waiting for sniffer ingress"),OVM_LOW);
          while(!pxlgw_ingr_xtns.size())  #1;

          actual_xtn  = new();
          actual_xtn  = pxlgw_ingr_xtns.pop_front();
          ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("Received sniffer xtn :\n%s",actual_xtn.sprint()),OVM_LOW);

          res = actual_xtn.check(exptd_xtn);

          if(res  ==  "")
          begin
            ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("PxlGw XTN [Write P0] Valid"),OVM_LOW);
          end
          else
          begin
            ovm_report_error({get_name(),"[process_fill_job]"},$psprintf("PxlGw XTN [Write P0] Invalid %s",res),OVM_LOW);
            #25ns;
            global_stop_request();
          end

          putPixel(exptd_xtn);

          /*  Read  P1  */
          //skip_xtn(4);  //DUT reads P1

          p1.x  = p0.x + 1;
          p1.y  = p0.y;

          exptd_xtn       = new();
          exptd_xtn.xtn   = PXL_READ;
          exptd_xtn.pxl   = get_frm_bffr_pxl(p1);
          exptd_xtn.posx  = p1.x;
          exptd_xtn.posy  = p1.y;

          ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("Waiting for sniffer ingress"),OVM_LOW);
          while(!pxlgw_ingr_xtns.size())  #1;

          actual_xtn  = new();
          actual_xtn  = pxlgw_ingr_xtns.pop_front();
          ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("Received sniffer xtn :\n%s",actual_xtn.sprint()),OVM_LOW);

          actual_xtn.pxl = exptd_xtn.pxl; //dont care for read

          res = actual_xtn.check(exptd_xtn);

          if(res  ==  "")
          begin
            ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("PxlGw XTN [Read P1] Valid"),OVM_LOW);
          end
          else
          begin
            ovm_report_error({get_name(),"[process_fill_job]"},$psprintf("PxlGw XTN [Read P1] Invalid %s",res),OVM_LOW);
            #25ns;
            global_stop_request();
          end

          putPixel(exptd_xtn);


          if((actual_xtn.pxl !=  job.line_color)  &&  (actual_xtn.pxl !=  job.fill_color)) //still within polygon
          begin
            ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("Adding P1[x:%1d][y:%1d] to fill_job_q",p1.x,p1.y),OVM_LOW);

            `ifdef  USE_GPU_LF_CNTRLR
              fill_job_q.push_front(p1);
            `else
              fill_job_q.push_back(p1);
            `endif

            skip_xtn(4);  //DUT writes P1 to FF
          end

          /*  Read  P2  */
          //skip_xtn(4);  //DUT Reads P2

          p2.x  = p0.x;
          p2.y  = p0.y - 1;

          exptd_xtn       = new();
          exptd_xtn.xtn   = PXL_READ;
          exptd_xtn.pxl   = get_frm_bffr_pxl(p2);
          exptd_xtn.posx  = p2.x;
          exptd_xtn.posy  = p2.y;

          ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("Waiting for sniffer ingress"),OVM_LOW);
          while(!pxlgw_ingr_xtns.size())  #1;

          actual_xtn  = new();
          actual_xtn  = pxlgw_ingr_xtns.pop_front();
          ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("Received sniffer xtn :\n%s",actual_xtn.sprint()),OVM_LOW);

          //exptd_xtn.pxl = actual_xtn.pxl; //dont care for read
          actual_xtn.pxl = exptd_xtn.pxl; //dont care for read

          res = actual_xtn.check(exptd_xtn);

          if(res  ==  "")
          begin
            ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("PxlGw XTN [Read P2] Valid"),OVM_LOW);
          end
          else
          begin
            ovm_report_error({get_name(),"[process_fill_job]"},$psprintf("PxlGw XTN [Read P2] Invalid %s",res),OVM_LOW);
            #25ns;
            global_stop_request();
          end

          putPixel(exptd_xtn);


          if((actual_xtn.pxl !=  job.line_color)  &&  (actual_xtn.pxl !=  job.fill_color)) //still within polygon
          begin
            ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("Adding P2[x:%1d][y:%1d] to fill_job_q",p2.x,p2.y),OVM_LOW);

            `ifdef  USE_GPU_LF_CNTRLR
              fill_job_q.push_front(p2);
            `else
              fill_job_q.push_back(p2);
            `endif

            skip_xtn(4);  //DUT writes P2
          end

          /*  Read  P3  */
          //skip_xtn(4);  //DUT Reads P3

          p3.x  = p0.x - 1;
          p3.y  = p0.y;

          exptd_xtn       = new();
          exptd_xtn.xtn   = PXL_READ;
          exptd_xtn.pxl   = get_frm_bffr_pxl(p3);
          exptd_xtn.posx  = p3.x;
          exptd_xtn.posy  = p3.y;

          ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("Waiting for sniffer ingress"),OVM_LOW);
          while(!pxlgw_ingr_xtns.size())  #1;

          actual_xtn  = new();
          actual_xtn  = pxlgw_ingr_xtns.pop_front();
          ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("Received sniffer xtn :\n%s",actual_xtn.sprint()),OVM_LOW);

          //exptd_xtn.pxl = actual_xtn.pxl; //dont care for read
          actual_xtn.pxl = exptd_xtn.pxl; //dont care for read

          res = actual_xtn.check(exptd_xtn);

          if(res  ==  "")
          begin
            ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("PxlGw XTN [Read P3] Valid"),OVM_LOW);
          end
          else
          begin
            ovm_report_error({get_name(),"[process_fill_job]"},$psprintf("PxlGw XTN [Read P3] Invalid %s",res),OVM_LOW);
            #25ns;
            global_stop_request();
          end

          putPixel(exptd_xtn);


          if((actual_xtn.pxl !=  job.line_color)  &&  (actual_xtn.pxl !=  job.fill_color)) //still within polygon
          begin
            ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("Adding P3[x:%1d][y:%1d] to fill_job_q",p3.x,p3.y),OVM_LOW);

            `ifdef  USE_GPU_LF_CNTRLR
              fill_job_q.push_front(p3);
            `else
              fill_job_q.push_back(p3);
            `endif

            skip_xtn(4);  //DUT Writes P3
          end

          /*  Read  P4  */
          //skip_xtn(4);  //DUT Reads P4

          p4.x  = p0.x;
          p4.y  = p0.y + 1;

          exptd_xtn       = new();
          exptd_xtn.xtn   = PXL_READ;
          exptd_xtn.pxl   = get_frm_bffr_pxl(p4);
          exptd_xtn.posx  = p4.x;
          exptd_xtn.posy  = p4.y;

          ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("Waiting for sniffer ingress"),OVM_LOW);
          while(!pxlgw_ingr_xtns.size())  #1;

          actual_xtn  = new();
          actual_xtn  = pxlgw_ingr_xtns.pop_front();
          ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("Received sniffer xtn :\n%s",actual_xtn.sprint()),OVM_LOW);

          //exptd_xtn.pxl = actual_xtn.pxl; //dont care for read
          actual_xtn.pxl = exptd_xtn.pxl; //dont care for read

          res = actual_xtn.check(exptd_xtn);

          if(res  ==  "")
          begin
            ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("PxlGw XTN [Read P4] Valid"),OVM_LOW);
          end
          else
          begin
            ovm_report_error({get_name(),"[process_fill_job]"},$psprintf("PxlGw XTN [Read P4] Invalid %s",res),OVM_LOW);
            #25ns;
            global_stop_request();
          end

          putPixel(exptd_xtn);


          if((actual_xtn.pxl !=  job.line_color)  &&  (actual_xtn.pxl !=  job.fill_color)) //still within polygon
          begin
            ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("Adding P4[x:%1d][y:%1d] to fill_job_q",p4.x,p4.y),OVM_LOW);

            `ifdef  USE_GPU_LF_CNTRLR
              fill_job_q.push_front(p4);
            `else
              fill_job_q.push_back(p4);
            `endif

            skip_xtn(4);  //DUT Writes P4
          end
        end

        ovm_report_info({get_name(),"[process_fill_job]"},$psprintf("End of Job"),OVM_LOW);
      end

    endtask : process_fill_job

    //Function to convert pixel coordinates to frame buffer address & push into queue
    function  void  putPixel(PXL_XFR_PKT_TYPE pkt);
      SRAM_PKT_TYPE pkt_sram;

      //if((pkt.posx  >=  P_CANVAS_W) ||  (pkt.posy >=  P_CANVAS_H))  return;
      if((pkt.posx  <   0)          ||  (pkt.posy <   0))           return;

      pkt_sram       = new();
      pkt_sram.addr  = new[1];
      pkt_sram.data  = new[1];
      pkt_sram.lb_xtn= (pkt.xtn ==  PXL_WRITE)  ? WRITE : READ;

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

      if(pkt.lb_xtn ==  WRITE)
      begin
        sram_wr_xtns.push_back(pkt);
      end
      else if(pkt.lb_xtn  ==  READ)
      begin
        sram_rd_xtns.push_back(pkt);
      end
      else
      begin
        ovm_report_fatal({get_name(),"[write_sram]"},$psprintf("Unexpected SRAM xtn : %s",pkt.lb_xtn.name),OVM_LOW);
      end
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

    /*
      * Function to check the validity of each SRAM read
    */
    task check_sram_reads();
      SRAM_PKT_TYPE exptd_pkt,actual_pkt;

      ovm_report_info({get_name(),"[check_sram_reads]"},"Start of check_sram_reads",OVM_LOW);

      forever
      begin
        //Wait for items to arrive in sent & rcvd queues
        ovm_report_info({get_name(),"[check_sram_reads]"},"Waiting on sram_rd_xtns queue ...",OVM_LOW);
        while(!sram_rd_xtns.size())  #1;

        if(!frm_bffr_pending_xtns.size())
        begin
          actual_pkt  = sram_rd_xtns.pop_front();
          ovm_report_error({get_name(),"[check_sram_reads]"},$psprintf("frm_bffr_pending_xtns queue is empty. Unexpected SRAM read \n%s",actual_pkt.sprint()),OVM_LOW);
        end
        else
        begin
          //Extract pkts from front of queues
          actual_pkt  = sram_rd_xtns.pop_front();
          exptd_pkt   = frm_bffr_pending_xtns.pop_front();

          /*
          //Process, compare, check ...
          if(exptd_pkt.check(actual_pkt))
          begin
            ovm_report_info({get_name(),"[check_sram_reads]"},"SRAM Read is valid",OVM_LOW);
          end
          else
          begin
            ovm_report_error({get_name(),"[check_sram_reads]"},"SRAM Read is invalid",OVM_LOW);
          end
        */
        end
      end

    endtask : check_sram_reads


    /*  Run */
    virtual task  run();
      ovm_report_info({get_name(),"[run]"},"Start of run",OVM_LOW);

      fork
        begin
          check_sram_writes();
        end

        begin
          check_sram_reads();
        end

        begin
          process_draw_line_job();
        end

        begin
          process_draw_bezier_job();
        end

        begin
          process_fill_job();
        end
      join

    endtask : run


    /*  GPU FF Functions  */

    function  bit is_gpuff_full ();
      if(fill_job_q.size  >=  gpu_ff_size)
        return  1;
      else
        return  0;
    endfunction : is_gpuff_full

    function  bit is_gpuff_empty ();
      if(fill_job_q.size  ==  0)
        return  1;
      else
        return  0;
    endfunction : is_gpuff_empty

    function  int get_nxt_wptr();
      int res;

      if(is_gpuff_full)
      begin
        res = gpu_ff_wptr;
      end
      else if(gpu_ff_wptr ==  (2  **  18))
      begin
        gpu_ff_wptr = (P_CANVAS_W * P_CANVAS_H) / 2;
        res = gpu_ff_wptr;
      end
      else
      begin
        res = gpu_ff_wptr;
        gpu_ff_wptr +=  4;
      end

      return  res;
    endfunction : get_nxt_wptr

    function  int get_nxt_rptr();
      int res;

      if(is_gpuff_empty)
      begin
        res = gpu_ff_rptr;
      end
      else if(gpu_ff_rptr ==  (2  **  18))
      begin
        gpu_ff_rptr = (P_CANVAS_W * P_CANVAS_H) / 2;
        res = gpu_ff_rptr;
      end
      else
      begin
        res = gpu_ff_rptr;
        gpu_ff_rptr +=  4;
      end

      return  res;
    endfunction : get_nxt_rptr

    function  pxl_hsi_t get_frm_bffr_pxl(point_t p);
      pxl_hsi_t res;
      int frm_bffr_addr = ((p.y*P_CANVAS_W)  + p.x) / 2;
      bit ms_n_ls = p.x % 2;

      if(ms_n_ls)
        $cast(res,  sram_drvr.frm_bffr[frm_bffr_addr][SRAM_DATA_W-1:P_PXL_HSI_W]);
      else
        $cast(res,  sram_drvr.frm_bffr[frm_bffr_addr][P_PXL_HSI_W-1:0]);

      return res;
    endfunction : get_frm_bffr_pxl

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
