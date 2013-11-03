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
 -- Component Name    : syn_but_sb
 -- Author            : mammenx
 -- Function          : This scoreboard checks that the results of the 
                        Butterfly module are correct.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_BUT_SB
`define __SYN_BUT_SB

//Implicit port declarations
`ovm_analysis_imp_decl(_rcvd_but_pkt)
`ovm_analysis_imp_decl(_sent_but_pkt)

  import  syn_math_pkg::*;

  class syn_but_sb  #(type  SENT_PKT_TYPE = syn_but_seq_item,
                      type  RCVD_PKT_TYPE = syn_but_seq_item
                    ) extends ovm_scoreboard;

    /*  Register with Factory */
    `ovm_component_param_utils(syn_but_sb#(SENT_PKT_TYPE, RCVD_PKT_TYPE))

    //Queue to hold the sent pkts, till rcvd pkts come
    SENT_PKT_TYPE sent_que[$];
    SENT_PKT_TYPE rcvd_que[$];

    //Ports
    ovm_analysis_imp_sent_but_pkt #(SENT_PKT_TYPE,syn_but_sb)  Mon_sent_2Sb_port;
    ovm_analysis_imp_rcvd_but_pkt #(RCVD_PKT_TYPE,syn_but_sb)  Mon_rcvd_2Sb_port;

    OVM_FILE  f;


    /*  Constructor */
    function new(string name = "syn_but_sb", ovm_component parent);
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


      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction


    /*
      * Write Sent Pkt
      * This function will be called each time a pkt is written into [ovm_analysis_imp_sent_but_pkt]Mon_sent_2Sb_port
    */
    virtual function void write_sent_but_pkt(input SENT_PKT_TYPE  pkt);
      ovm_report_info({get_name(),"[write_sent_but_pkt]"},$psprintf("Received pkt\n%s",pkt.sprint()),OVM_LOW);

      //Push packet into sent queue
      sent_que.push_back(pkt);

      ovm_report_info({get_name(),"[write_sent_but_pkt]"},$psprintf("There are %d items in sent_que[$]",sent_que.size()),OVM_LOW);
    endfunction : write_sent_but_pkt


    /*
      * Write Rcvd Pkt
      * This function will be called each time a pkt is written into [ovm_analysis_imp_rcvd_but_pkt]Mon_rcvd_2Sb_port
    */
    virtual function void write_rcvd_but_pkt(input RCVD_PKT_TYPE pkt);
      ovm_report_info({get_name(),"[write_rcvd_but_pkt]"},$psprintf("Received pkt\n%s",pkt.sprint()),OVM_LOW);

      //Push packet into rcvd queue
      rcvd_que.push_back(pkt);

      ovm_report_info({get_name(),"[write_rcvd_but_pkt]"},$psprintf("There are %d items in rcvd_que[$]",rcvd_que.size()),OVM_LOW);
    endfunction : write_rcvd_but_pkt


    /*  Run */
    task run();
      SENT_PKT_TYPE sent_pkt;
      RCVD_PKT_TYPE exp_pkt1,exp_pkt2,rcvd_pkt;
      string res;

      ovm_report_info({get_name(),"[run]"},"Start of run",OVM_LOW);

      forever
      begin
        //Wait for items to arrive in sent & rcvd queues
        ovm_report_info({get_name(),"[run]"},"Waiting on sent queue...",OVM_LOW);
        while(!sent_que.size())  #1;

        sent_pkt  = sent_que.pop_front();

        exp_pkt1  = new();
        exp_pkt1.sample_a = syn_complex_mul(sent_pkt.sample_b,  sent_pkt.twdl);
        exp_pkt1.sample_a = syn_complex_add(exp_pkt1.sample_a,  sent_pkt.sample_a);
        exp_pkt1.sample_b.re  = 0;
        exp_pkt1.sample_b.im  = 0;
        exp_pkt1.twdl.re  = 0;
        exp_pkt1.twdl.im  = 0;

        exp_pkt2  = new();
        exp_pkt2.sample_a = syn_complex_mul(sent_pkt.sample_b,  sent_pkt.twdl);
        exp_pkt2.sample_a = syn_complex_sub(sent_pkt.sample_a,  exp_pkt2.sample_a);
        exp_pkt2.sample_b.re  = 0;
        exp_pkt2.sample_b.im  = 0;
        exp_pkt2.twdl.re  = 0;
        exp_pkt2.twdl.im  = 0;

        ovm_report_info({get_name(),"[run]"},"Waiting on rcvd queue 0 ...",OVM_LOW);
        while(!rcvd_que.size())  #1;

        rcvd_pkt  = rcvd_que.pop_front();

        res = exp_pkt1.check(rcvd_pkt, 1);

        if(res  ==  "")
        begin
          ovm_report_info({get_name(),"[run]"},"Packets match",OVM_LOW);
        end
        else
        begin
          ovm_report_error({get_name(),"[run]"},$psprintf("Packets mismatch in a+b.t - \nsent_pkt-\n%s\n%s", sent_pkt.sprint(),res),OVM_LOW);
        end


        ovm_report_info({get_name(),"[run]"},"Waiting on rcvd queue 1 ...",OVM_LOW);
        while(!rcvd_que.size())  #1;

        rcvd_pkt  = rcvd_que.pop_front();

        res = exp_pkt2.check(rcvd_pkt, 1);

        if(res  ==  "")
          ovm_report_info({get_name(),"[run]"},"Packets match",OVM_LOW);
        else
          ovm_report_error({get_name(),"[run]"},$psprintf("Packets mismatch in a-b.t - \nsent_pkt-\n%s\n%s", sent_pkt.sprint(),res),OVM_LOW);

        #1;

        ovm_report_info({get_name(),"[run]"},$psprintf("Queue Stats - sent[%1d] rcvd[%1d]",sent_que.size,rcvd_que.size),OVM_LOW);
      end

    endtask : run


    /*  Report  */
    virtual function void report();
      if(sent_que.size)
        ovm_report_error({get_type_name(),"[report]"},$psprintf("%1d items pending in sent_que", sent_que.size), OVM_LOW);

      if(rcvd_que.size)
        ovm_report_error({get_type_name(),"[report]"},$psprintf("%1d items pending in rcvd_que", rcvd_que.size), OVM_LOW);

      ovm_report_info({get_type_name(),"[report]"},$psprintf("Report -\n%s", this.sprint()), OVM_LOW);
    endfunction : report

  endclass : syn_but_sb

`endif
