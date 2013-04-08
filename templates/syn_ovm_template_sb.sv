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
 -- Component Name    : <sb_name>
 -- Author            : 
 -- Function          : 
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __<sb_name>
`define __<sb_name>

//Implicit port declarations
`ovm_analysis_imp_decl(_rcvd_pkt)
`ovm_analysis_imp_decl(_sent_pkt)

  class <sb_name> #(type  SENT_PKT_TYPE = ,
                    type  RCVD_PKT_TYPE = 
                  ) extends ovm_scoreboard;

    /*  Register with Factory */
    `ovm_component_param_utils(<sb_name>#(SENT_PKT_TYPE, RCVD_PKT_TYPE))

    //Queue to hold the sent pkts, till rcvd pkts come
    SENT_PKT_TYPE sent_que[$];
    SENT_PKT_TYPE rcvd_que[$];

    //Ports
    ovm_analysis_imp_sent_pkt #(SENT_PKT_TYPE,<sb_name>)  Mon_sent_2Sb_port;
    ovm_analysis_imp_rcvd_pkt #(RCVD_PKT_TYPE,<sb_name>)  Mon_rcvd_2Sb_port;

    OVM_FILE  f;


    /*  Constructor */
    function new(string name = "<sb_name>", ovm_component parent);
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
      * This function will be called each time a pkt is written into [ovm_analysis_imp_sent_pkt]Mon_sent_2Sb_port
    */
    virtual function void write_sent_pkt(input SENT_PKT_TYPE  pkt);
      ovm_report_info({get_name(),"[write_sent_pkt]"},$psprintf("Received pkt\n%s",pkt.sprint()),OVM_LOW);

      //Push packet into sent queue
      sent_que.push_back(pkt);

      ovm_report_info({get_name(),"[write_sent_pkt]"},$psprintf("There are %d items in sent_que[$]",sent_que.size()),OVM_LOW);
    endfunction : write_sent_pkt


    /*
      * Write Rcvd Pkt
      * This function will be called each time a pkt is written into [ovm_analysis_imp_rcvd_pkt]Mon_rcvd_2Sb_port
    */
    virtual function void write_rcvd_pkt(input RCVD_PKT_TYPE pkt);
      ovm_report_info({get_name(),"[write_rcvd_pkt]"},$psprintf("Received pkt\n%s",pkt.sprint()),OVM_LOW);

      //Push packet into rcvd queue
      rcvd_que.push_back(pkt);

      ovm_report_info({get_name(),"[write_rcvd_pkt]"},$psprintf("There are %d items in rcvd_que[$]",rcvd_que.size()),OVM_LOW);
    endfunction : write_rcvd_pkt


    /*  Run */
    task run();
      ovm_report_info({get_name(),"[run]"},"Start of run",OVM_LOW);

      forever
      begin
        //Wait for items to arrive in sent & rcvd queues
        ovm_report_info({get_name(),"[run]"},"Waiting on queues ...",OVM_LOW);
        while(sent_que.size() &&  rcvd_que.size())  #1;

        //Extract pkts from front of queues

        //Process, compare, check etc.

      end

    endtask : run


    /*  Report  */
    virtual function void report();
      ovm_report_info({get_type_name(),"[report]"},$psprintf("Report -\n%s", this.sprint()), OVM_LOW);
    endfunction : report

  endclass : <sb_name>

`endif
