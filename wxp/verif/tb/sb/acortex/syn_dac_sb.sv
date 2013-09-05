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
 -- Component Name    : syn_dac_sb
 -- Author            : mammenx
 -- Function          : This scoreboard checks that the PCM data sent on
                        DAC line is correct.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_DAC_SB
`define __SYN_DAC_SB

//Implicit port declarations
`ovm_analysis_imp_decl(_dac_sb_lb_pkt)
`ovm_analysis_imp_decl(_dac_sb_rcvd_pkt)
`ovm_analysis_imp_decl(_dac_sb_sent_pkt)

  class syn_dac_sb #(
                      parameter type  LB_PKT_TYPE   = syn_lb_seq_item,
                      parameter type  PCM_PKT_TYPE  = syn_pcm_seq_item
                    ) extends ovm_scoreboard;

    `include  "syn_acortex_reg_map.sv"

    /*  Register with Factory */
    `ovm_component_param_utils(syn_dac_sb#(LB_PKT_TYPE, PCM_PKT_TYPE))

    //Queue to hold the sent pkts, till rcvd pkts come
    PCM_PKT_TYPE sent_que[$];
    PCM_PKT_TYPE rcvd_que[$];

    //Ports
    ovm_analysis_imp_dac_sb_lb_pkt   #(LB_PKT_TYPE,syn_dac_sb#(LB_PKT_TYPE,PCM_PKT_TYPE))   Mon_lb_2Sb_port;
    ovm_analysis_imp_dac_sb_sent_pkt #(PCM_PKT_TYPE,syn_dac_sb#(LB_PKT_TYPE,PCM_PKT_TYPE))  Mon_sent_2Sb_port;
    ovm_analysis_imp_dac_sb_rcvd_pkt #(PCM_PKT_TYPE,syn_dac_sb#(LB_PKT_TYPE,PCM_PKT_TYPE))  Mon_rcvd_2Sb_port;

    OVM_FILE  f;

    syn_reg_map#(16)  dac_reg_map;

    /*  Constructor */
    function new(string name = "syn_dac_sb", ovm_component parent);
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

      Mon_lb_2Sb_port   = new("Mon_lb_2Sb_port", this);
      Mon_sent_2Sb_port = new("Mon_sent_2Sb_port", this);
      Mon_rcvd_2Sb_port = new("Mon_rcvd_2Sb_port", this);

      build_dac_reg_map();

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction

    /*
      * This function populates the DAC registers
    */
    function  void  build_dac_reg_map();

      dac_reg_map = syn_reg_map#(16)::type_id::create("dac_reg_map",  this);
      dac_reg_map.create_field("dac_en",      {ACORTEX_WMDRVR_CODE,ACORTEX_WMDRVR_CTRL_REG_ADDR},   0,  0);
      dac_reg_map.create_field("bps",         {ACORTEX_WMDRVR_CODE,ACORTEX_WMDRVR_CTRL_REG_ADDR},   2,  2);
      dac_reg_map.create_field("acache_mode", {ACORTEX_ACACHE_CODE,ACORTEX_ACACHE_CTRL_REG_ADDR},   0,  0);

    endfunction : build_dac_reg_map


    /*
      * Write LB Pkt
      * This function will be called each time a pkt is written into [ovm_analysis_imp_dac_sb_lb_pkt]Mon_lb_2Sb_port
    */
    virtual function void write_dac_sb_lb_pkt(input LB_PKT_TYPE  pkt);
      ovm_report_info({get_name(),"[write_dac_sb_lb_pkt]"},$psprintf("Received pkt\n%s",pkt.sprint()),OVM_LOW);

      if((pkt.lb_xtn  ==  WRITE)  ||  (pkt.lb_xtn ==  BURST_WRITE))
      begin
        //foreach(pkt.addr[i])
        for(int i=0; i<pkt.addr.size; i++)
        begin
          if(dac_reg_map.set_reg(pkt.addr[i][11:0],  pkt.data[i])  == syn_reg_map#(16)::SUCCESS)
            ovm_report_info({get_name(),"[write_dac_sb_lb_pkt]"},$psprintf("Updated register [0x%x] to [0x%x]",pkt.addr[i][11:0],pkt.data[i]),OVM_LOW);

        end
      end

    endfunction : write_dac_sb_lb_pkt


    /*
      * Write Sent Pkt
      * This function will be called each time a pkt is written into [ovm_analysis_imp_dac_sb_sent_pkt]Mon_sent_2Sb_port
    */
    virtual function void write_dac_sb_sent_pkt(input PCM_PKT_TYPE  pkt);
      ovm_report_info({get_name(),"[write_dac_sb_sent_pkt]"},$psprintf("Received pkt\n%s",pkt.sprint()),OVM_LOW);

      if(dac_reg_map.get_field("dac_en")  ==  1)
      begin
        //Push packet into sent queue
        sent_que.push_back(pkt);
      end
      else
      begin
        ovm_report_info({get_name(),"[write_dac_sb_sent_pkt]"},$psprintf("Skipping sent_que since dac is disabled"),OVM_LOW);
      end

      ovm_report_info({get_name(),"[write_dac_sb_sent_pkt]"},$psprintf("There are %d items in sent_que[$]",sent_que.size()),OVM_LOW);
    endfunction : write_dac_sb_sent_pkt


    /*
      * Write Rcvd Pkt
      * This function will be called each time a pkt is written into [ovm_analysis_imp_dac_sb_rcvd_pkt]Mon_rcvd_2Sb_port
    */
    virtual function void write_dac_sb_rcvd_pkt(input PCM_PKT_TYPE pkt);
      ovm_report_info({get_name(),"[write_dac_sb_rcvd_pkt]"},$psprintf("Received pkt\n%s",pkt.sprint()),OVM_LOW);

      //Push packet into rcvd queue
      rcvd_que.push_back(pkt);

      ovm_report_info({get_name(),"[write_dac_sb_rcvd_pkt]"},$psprintf("There are %d items in rcvd_que[$]",rcvd_que.size()),OVM_LOW);
    endfunction : write_dac_sb_rcvd_pkt


    /*  Run */
    task run();
      PCM_PKT_TYPE  sent_pkt,rcvd_pkt;
      string  res;

      ovm_report_info({get_name(),"[run]"},"Start of run",OVM_LOW);

      forever
      begin
        //Wait for items to arrive in sent & rcvd queues
        ovm_report_info({get_name(),"[run]"},"Waiting on rcvd_que ...",OVM_LOW);
        while(!rcvd_que.size())  #1;

        //Extract pkts from front of queues
        rcvd_pkt  = rcvd_que.pop_front();

        if(!sent_que.size())
        begin
          ovm_report_error({get_name(),"[run]"},$psprintf("Unexpected pkt!\n%s",rcvd_pkt.sprint()),OVM_LOW);
          continue;
        end

        sent_pkt  = sent_que.pop_front();

        //Process, compare, check etc.
        if(dac_reg_map.get_field("bps") ==  1)  //16b
        begin
          foreach(rcvd_pkt.pcm_data[i])
          begin
            rcvd_pkt.pcm_data[i].lchnnl = {{16{rcvd_pkt.pcm_data[i].lchnnl[16]}}, rcvd_pkt.pcm_data[i].lchnnl[15:0]};
            rcvd_pkt.pcm_data[i].rchnnl = {{16{rcvd_pkt.pcm_data[i].rchnnl[16]}}, rcvd_pkt.pcm_data[i].rchnnl[15:0]};
          end

          foreach(sent_pkt.pcm_data[i])
          begin
            sent_pkt.pcm_data[i].lchnnl = {{16{sent_pkt.pcm_data[i].lchnnl[16]}}, sent_pkt.pcm_data[i].lchnnl[15:0]};
            sent_pkt.pcm_data[i].rchnnl = {{16{sent_pkt.pcm_data[i].rchnnl[16]}}, sent_pkt.pcm_data[i].rchnnl[15:0]};
          end
        end

        res = sent_pkt.check(rcvd_pkt);

        if(res  ==  "")
        begin
          ovm_report_info({get_name(),"[run]"},$psprintf("PCM Data is correct"),OVM_LOW);
        end
        else
        begin
          ovm_report_error({get_name(),"[run]"},$psprintf("PCM Data is incorrect\n%s",res),OVM_LOW);
        end
      end

    endtask : run


    /*  Report  */
    virtual function void report();
      ovm_report_info({get_type_name(),"[report]"},$psprintf("Report -\n%s", this.sprint()), OVM_LOW);
    endfunction : report

  endclass : syn_dac_sb

`endif
