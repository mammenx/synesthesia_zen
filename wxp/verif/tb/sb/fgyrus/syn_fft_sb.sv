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
 -- Component Name    : syn_fft_sb
 -- Author            : mammenx
 -- Function          : This scoreboard checks that the FFT data generated
                        by Fgyrus is correct.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_FFT_SB
`define __SYN_FFT_SB

//Implicit port declarations
`ovm_analysis_imp_decl(_rcvd_fft_pkt)
`ovm_analysis_imp_decl(_sent_fft_pkt)

  import  syn_dsp_pkg::*;

  class syn_fft_sb  #(type  SENT_PKT_TYPE = syn_pcm_seq_item,
                      type  RCVD_PKT_TYPE = syn_pcm_seq_item
                    ) extends ovm_scoreboard;

    /*  Register with Factory */
    `ovm_component_param_utils(syn_fft_sb#(SENT_PKT_TYPE, RCVD_PKT_TYPE))

    //Queue to hold the sent pkts, till rcvd pkts come
    SENT_PKT_TYPE sent_que[$];
    SENT_PKT_TYPE rcvd_que[$];

    //Ports
    ovm_analysis_imp_sent_fft_pkt #(SENT_PKT_TYPE,syn_fft_sb)  Mon_sent_2Sb_port;
    ovm_analysis_imp_rcvd_fft_pkt #(RCVD_PKT_TYPE,syn_fft_sb)  Mon_rcvd_2Sb_port;

    OVM_FILE  f;


    /*  Constructor */
    function new(string name = "syn_fft_sb", ovm_component parent);
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
      * This function will be called each time a pkt is written into [ovm_analysis_imp_sent_fft_pkt]Mon_sent_2Sb_port
    */
    virtual function void write_sent_fft_pkt(input SENT_PKT_TYPE  pkt);
      ovm_report_info({get_name(),"[write_sent_fft_pkt]"},$psprintf("Received pkt\n%s",pkt.sprint()),OVM_LOW);

      //Push packet into sent queue
      sent_que.push_back(pkt);

      ovm_report_info({get_name(),"[write_sent_fft_pkt]"},$psprintf("There are %d items in sent_que[$]",sent_que.size()),OVM_LOW);
    endfunction : write_sent_fft_pkt


    /*
      * Write Rcvd Pkt
      * This function will be called each time a pkt is written into [ovm_analysis_imp_rcvd_fft_pkt]Mon_rcvd_2Sb_port
    */
    virtual function void write_rcvd_fft_pkt(input RCVD_PKT_TYPE pkt);
      ovm_report_info({get_name(),"[write_rcvd_fft_pkt]"},$psprintf("Received pkt\n%s",pkt.sprint()),OVM_LOW);

      //Push packet into rcvd queue
      rcvd_que.push_back(pkt);

      ovm_report_info({get_name(),"[write_rcvd_fft_pkt]"},$psprintf("There are %d items in rcvd_que[$]",rcvd_que.size()),OVM_LOW);
    endfunction : write_rcvd_fft_pkt


    /*  Run */
    task run();
      SENT_PKT_TYPE pcm_pkt;
      RCVD_PKT_TYPE fft_rcvd_pkt,fft_exptd_pkt;
      int   num_samples;
      int   data_int[];
      real  data_in[],data_out_re[],data_out_im[];
      string  res;

      ovm_report_info({get_name(),"[run]"},"Start of run",OVM_LOW);

      forever
      begin
        //Wait for items to arrive in sent & rcvd queues
        ovm_report_info({get_name(),"[run]"},"Waiting on rcvd_que ...",OVM_LOW);
        while(!rcvd_que.size())  #1;

        fft_rcvd_pkt  = rcvd_que.pop_front();

        if(!sent_que.size())
        begin
          ovm_report_error({get_name(),"[run]"},"Unexpected FFT xtn received!",OVM_LOW);
          continue;
        end

        pcm_pkt     = sent_que.pop_front();
        num_samples = pcm_pkt.pcm_data.size;
        fft_exptd_pkt = new();
        fft_exptd_pkt.pcm_data  = new[num_samples];

        /*  L-Channel Data  */
        data_int    = new[num_samples];
        data_in     = new[num_samples];
        data_out_re = new[num_samples];
        data_out_im = new[num_samples];

        for(int i=0; i<num_samples; i++)
        begin
          $cast(data_int[i],  pcm_pkt.pcm_data[i].lchnnl);
          $cast(data_in[i], data_int[i]);
        end

        //Calculate the FFT
        syn_calc_fft(num_samples, data_in,  data_out_re,  data_out_im);

        //Calculate the abs value
        syn_calc_complex_abs(num_samples, data_out_re,  data_out_im);

        //Constuct the expected pkt
        for(int i=0; i<num_samples; i++)
          $cast(fft_exptd_pkt.pcm_data[i].lchnnl, data_out_re[i]);


        /*  R-Channel Data  */
        data_int    = new[num_samples];
        data_in     = new[num_samples];
        data_out_re = new[num_samples];
        data_out_im = new[num_samples];

        for(int i=0; i<num_samples; i++)
        begin
          $cast(data_int[i],  pcm_pkt.pcm_data[i].rchnnl);
          $cast(data_in[i], data_int[i]);
        end

        //Calculate the FFT
        syn_calc_fft(num_samples, data_in,  data_out_re,  data_out_im);

        //Calculate the abs value
        syn_calc_complex_abs(num_samples, data_out_re,  data_out_im);

        //Constuct the expected pkt
        for(int i=0; i<num_samples; i++)
          $cast(fft_exptd_pkt.pcm_data[i].rchnnl, data_out_re[i]);


        ovm_report_info({get_type_name(),"[run]"},$psprintf("Expected FFT:\n%s",fft_exptd_pkt.get_graph()), OVM_LOW);
        ovm_report_info({get_type_name(),"[run]"},$psprintf("Actual FFT:\n%s",fft_rcvd_pkt.get_graph()), OVM_LOW);


        //Check with received pkt
        res = fft_exptd_pkt.check(fft_rcvd_pkt, 5.0);

        if(res  ==  "")
          ovm_report_info({get_type_name(),"[run]"},$psprintf("FFT data is correct"), OVM_LOW);
        else
          ovm_report_error({get_type_name(),"[run]"},$psprintf("FFT data is incorrect\n%s",res), OVM_LOW);

        #1;
      end

    endtask : run


    /*  Report  */
    virtual function void report();
      ovm_report_info({get_type_name(),"[report]"},$psprintf("Report -\n%s", this.sprint()), OVM_LOW);
    endfunction : report

  endclass : syn_fft_sb

`endif
