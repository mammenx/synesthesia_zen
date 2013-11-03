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
 -- Component Name    : syn_fft_cache_sb
 -- Author            : mammenx
 -- Function          : This scoreboard checks that all writes to the FFT
                        cache by fgyrus_fsm are correct.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_FFT_CACHE_SB
`define __SYN_FFT_CACHE_SB

//Implicit port declarations
`ovm_analysis_imp_decl(_pcm_pkt)
`ovm_analysis_imp_decl(_fft_cache_pkt)

  import  syn_fft_pkg::*;
  import  syn_math_pkg::*;

  class syn_fft_cache_sb  #(type  SENT_PKT_TYPE = syn_pcm_seq_item,
                            type  RCVD_PKT_TYPE = syn_fft_cache_seq_item
                          ) extends ovm_scoreboard;

    /*  Register with Factory */
    `ovm_component_param_utils(syn_fft_cache_sb#(SENT_PKT_TYPE, RCVD_PKT_TYPE))

    //Queue to hold the sent pkts, till rcvd pkts come
    //Or vice versa in this case
    SENT_PKT_TYPE sent_que[$];
    RCVD_PKT_TYPE rcvd_que[$];

    //Ports
    ovm_analysis_imp_fft_cache_pkt #(SENT_PKT_TYPE,syn_fft_cache_sb)  Mon_sent_2Sb_port;
    ovm_analysis_imp_pcm_pkt #(RCVD_PKT_TYPE,syn_fft_cache_sb)  Mon_rcvd_2Sb_port;

    OVM_FILE  f;

    //Inter-Stage mailboxes
    mailbox#(SENT_PKT_TYPE) stage_1_mb;
    mailbox#(SENT_PKT_TYPE) stage_2_mb;
    mailbox#(SENT_PKT_TYPE) stage_3_mb;

    /*  Constructor */
    function new(string name = "syn_fft_cache_sb", ovm_component parent);
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

      stage_1_mb  = new(1);
      stage_2_mb  = new(1);
      stage_3_mb  = new(1);

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction


    /*
      * Write Sent Pkt
      * This function will be called each time a pkt is written into [ovm_analysis_imp_fft_cache_pkt]Mon_sent_2Sb_port
    */
    virtual function void write_fft_cache_pkt(input SENT_PKT_TYPE  pkt);
      ovm_report_info({get_name(),"[write_fft_cache_pkt]"},$psprintf("Received pkt\n%s",pkt.sprint()),OVM_LOW);

      //Push packet into sent queue
      sent_que.push_back(pkt);

      ovm_report_info({get_name(),"[write_fft_cache_pkt]"},$psprintf("There are %d items in sent_que[$]",sent_que.size()),OVM_LOW);
    endfunction : write_fft_cache_pkt


    /*
      * Write Rcvd Pkt
      * This function will be called each time a pkt is written into [ovm_analysis_imp_pcm_pkt]Mon_rcvd_2Sb_port
    */
    virtual function void write_pcm_pkt(input RCVD_PKT_TYPE pkt);
      ovm_report_info({get_name(),"[write_pcm_pkt]"},$psprintf("Received pkt\n%s",pkt.sprint()),OVM_LOW);

      //Push packet into rcvd queue
      rcvd_que.push_back(pkt);

      ovm_report_info({get_name(),"[write_pcm_pkt]"},$psprintf("There are %d items in rcvd_que[$]",rcvd_que.size()),OVM_LOW);
    endfunction : write_pcm_pkt


    /*  Function to bit reverse a 7 bit number  */
    function  bit[6:0]  bit_rev_7b(bit  [6:0] num);
      bit[6:0]  res;

      for(int i=0;  i<7;  i++)
        res[i]  = num[6-i];

      //ovm_report_info({get_name(),"[bit_rev_7b]"},$psprintf("0x%x -> 0x%x",num,res),OVM_LOW);
        
      return  res;
    endfunction : bit_rev_7b

    /*  Window & Decimate Check */
    task  win_decimate_chk();
      SENT_PKT_TYPE pcm_pkt,nxt_pkt;
      RCVD_PKT_TYPE rcvd_pkt,expctd_pkt;
      string  res;

      ovm_report_info({get_name(),"[win_decimate_chk]"},"Start of win_decimate_chk",OVM_LOW);

      forever
      begin
        ovm_report_info({get_name(),"[win_decimate_chk]"},$psprintf("Waiting on sent_que"),OVM_LOW);
        while(!sent_que.size()) #1;

        pcm_pkt = sent_que.pop_front();

        nxt_pkt = new();
        nxt_pkt.pcm_data  = new[pcm_pkt.pcm_data.size * 2];

        for(int i=0;  i<pcm_pkt.pcm_data.size;  i++)  //Process LChannel data
        begin
          ovm_report_info({get_name(),"[win_decimate_chk-Lchnnl]"},$psprintf("Waiting on rcvd_que"),OVM_LOW);
          while(!rcvd_que.size()) #1;

          rcvd_pkt  = rcvd_que.pop_front();

          expctd_pkt  = new();
          expctd_pkt.addr = i;
          expctd_pkt.sample.re  = pcm_pkt.pcm_data[bit_rev_7b(i)] >>  32; //LChannel
          expctd_pkt.sample.im  = 0;

          res = expctd_pkt.check(rcvd_pkt,  0);

          if(res  ==  "")
            ovm_report_info({get_name(),"[win_decimate_chk-Lchnnl]"},$psprintf("Data[%1d] is correct",i),OVM_LOW);
          else
            ovm_report_error({get_name(),"[win_decimate_chk-Lchnnl]"},$psprintf("Data[%1d] is in-correct%s",i,res),OVM_LOW);

          nxt_pkt.pcm_data[i] = {expctd_pkt.sample.re,  expctd_pkt.sample.im};
        end

        for(int i=0;  i<pcm_pkt.pcm_data.size;  i++)  //Process LChannel data
        begin
          ovm_report_info({get_name(),"[win_decimate_chk-Rchnnl]"},$psprintf("Waiting on rcvd_que"),OVM_LOW);
          while(!rcvd_que.size()) #1;

          rcvd_pkt  = rcvd_que.pop_front();

          expctd_pkt  = new();
          expctd_pkt.addr = i + pcm_pkt.pcm_data.size;
          expctd_pkt.sample.re  = pcm_pkt.pcm_data[bit_rev_7b(i)] & 'hffffffff; //RChannel
          expctd_pkt.sample.im  = 0;

          res = expctd_pkt.check(rcvd_pkt,  0);

          if(res  ==  "")
            ovm_report_info({get_name(),"[win_decimate_chk-Rchnnl]"},$psprintf("Data[%1d] is correct",i),OVM_LOW);
          else
            ovm_report_error({get_name(),"[win_decimate_chk-Rchnnl]"},$psprintf("Data[%1d] is in-correct%s",i,res),OVM_LOW);

          nxt_pkt.pcm_data[i+pcm_pkt.pcm_data.size] = {expctd_pkt.sample.re,  expctd_pkt.sample.im};
        end

        ovm_report_info({get_name(),"[win_decimate_chk]"},$psprintf("Sending nxt_pkt to stage_1_mb\n%s",nxt_pkt.sprint()),OVM_LOW);
        stage_1_mb.put(nxt_pkt);

        //global_stop_request();
      end

    endtask : win_decimate_chk

    /*  Function to generate twiddle factors  */
    function  fft_twdl_t  twdl_gen(input int k,N);
      fft_twdl_t  res;
      real  theta,temp;

      theta = (-2 * pi  * k)/N;

      temp  = (2  **  8)  * syn_cos(theta); //shift by 8 bits
      $cast(res.re, temp);

      temp  = (2  **  8)  * syn_sin(theta); //shift by 8 bits
      $cast(res.im, temp);

      return  res;

    endfunction : twdl_gen

    /* Task to check each part of the FFT butterfly tree  */
    task  fft_chk();
      SENT_PKT_TYPE pcm_pkt,nxt_pkt;
      int num_samples,num_stages,sample_no,pair_offset,k;
      fft_sample_t  lsamples_in[],lsamples_out[],rsamples_in[],rsamples_out[],tmp_sample,sample_a,sample_b;
      fft_twdl_t    twdl;
      RCVD_PKT_TYPE rcvd_pkt,expctd_pkt;
      string res;

      ovm_report_info({get_name(),"[fft_chk]"},"Start of fft_chk",OVM_LOW);

      forever
      begin
        ovm_report_info({get_name(),"[fft_chk]"},$psprintf("Waiting on stage_1_mb"),OVM_LOW);
        stage_1_mb.get(pcm_pkt);

        num_samples   = pcm_pkt.pcm_data.size / 2;
        lsamples_in   = new[num_samples];
        lsamples_out  = new[num_samples];
        rsamples_in   = new[num_samples];
        rsamples_out  = new[num_samples];

        //get the samples
        for(int i=0; i<num_samples; i++)
        begin
          $cast(lsamples_in[i].re,  pcm_pkt.pcm_data[i] >> P_FFT_SAMPLE_W);             lsamples_in[i].im = 0;
          $cast(rsamples_in[i].re,  pcm_pkt.pcm_data[i+num_samples] >> P_FFT_SAMPLE_W); rsamples_in[i].im = 0;
        end

        num_stages  = $clog2(num_samples);

        nxt_pkt = new();
        nxt_pkt.pcm_data  = new[num_samples*2];

        ovm_report_info({get_name(),"[fft_chk-LChannel]"},$psprintf("Starting %1d-point FFT with %1d stages",num_samples,num_stages),OVM_LOW);

        for(int stage_no=0; stage_no<num_stages;  stage_no++)
        begin
          pair_offset = 2 **  stage_no;
          sample_no = 0;
          k=0;

          for(int i=0;  i<(num_samples/2);  i++)
          begin
            sample_a  = lsamples_in[sample_no];
            sample_b  = lsamples_in[sample_no+pair_offset];
            twdl      = twdl_gen(k,num_samples);  //exp(-j*2*pi*k/N)

            tmp_sample  = syn_complex_mul(sample_b, twdl);

            lsamples_out[sample_no] = syn_complex_add(sample_a,tmp_sample);
            lsamples_out[sample_no+pair_offset] = syn_complex_sub(sample_a,tmp_sample);


            ovm_report_info({get_name(),"[fft_chk-LChannel]"},$psprintf("Waiting on rcvd_que0"),OVM_LOW);
            while(!rcvd_que.size()) #1;

            rcvd_pkt  = rcvd_que.pop_front();

            expctd_pkt  = new();
            expctd_pkt.addr   = sample_no;
            expctd_pkt.sample = lsamples_out[sample_no];

            ovm_report_info({get_name(),"[fft_chk-LChannel]"},$psprintf("stage_no:%1d, sample_no:%1d, pair_offset:%1d, k:%1d, sample_a:{0x%x,0x%x}, sample_b:{0x%x,0x%x}, tdwl:{0x%x,0x%x}",stage_no,sample_no,pair_offset,k,sample_a.re,sample_a.im,sample_b.re,sample_b.im,twdl.re,twdl.im),OVM_LOW);

            res = expctd_pkt.check(rcvd_pkt,  6);

            if(res  ==  "")
              ovm_report_info({get_name(),"[fft_chk-LChannel]"},$psprintf("Data[%1d] is correct",sample_no),OVM_LOW);
            else
              ovm_report_error({get_name(),"[fft_chk-LChannel]"},$psprintf("Data[%1d] is in-correct%s",sample_no,res),OVM_LOW);

            nxt_pkt.pcm_data[sample_no] = {rcvd_pkt.sample.re,  rcvd_pkt.sample.im};

            ovm_report_info({get_name(),"[fft_chk-LChannel]"},$psprintf("Waiting on rcvd_que1"),OVM_LOW);
            while(!rcvd_que.size()) #1;

            rcvd_pkt  = rcvd_que.pop_front();

            expctd_pkt  = new();
            expctd_pkt.addr   = sample_no+pair_offset;
            expctd_pkt.sample = lsamples_out[sample_no+pair_offset];

            res = expctd_pkt.check(rcvd_pkt,  6);

            if(res  ==  "")
              ovm_report_info({get_name(),"[fft_chk-LChannel]"},$psprintf("Data[%1d] is correct",sample_no+pair_offset),OVM_LOW);
            else
              ovm_report_error({get_name(),"[fft_chk-LChannel]"},$psprintf("Data[%1d] is in-correct%s",sample_no+pair_offset,res),OVM_LOW);

            nxt_pkt.pcm_data[sample_no+pair_offset] = {rcvd_pkt.sample.re,  rcvd_pkt.sample.im};

            sample_no +=  pair_offset*2;

            if(sample_no  >=  num_samples)
            begin
              sample_no = (sample_no+1)%num_samples;
              k = k+  (num_samples/(pair_offset*2));
            end
          end

          //update buffers
          foreach(lsamples_out[i])
          begin
            lsamples_in[i]  = lsamples_out[i];
          end

          lsamples_out  = new[num_samples];
        end


        ovm_report_info({get_name(),"[fft_chk-RChannel]"},$psprintf("Starting %1d-point FFT with %1d stages",num_samples,num_stages),OVM_LOW);

        for(int stage_no=0; stage_no<num_stages;  stage_no++)
        begin
          pair_offset = 2 **  stage_no;
          sample_no = 0;
          k=0;

          for(int i=0;  i<(num_samples/2);  i++)
          begin
            sample_a  = rsamples_in[sample_no];
            sample_b  = rsamples_in[sample_no+pair_offset];
            twdl      = twdl_gen(k,num_samples);  //exp(-j*2*pi*k/N)

            tmp_sample  = syn_complex_mul(sample_b, twdl);

            rsamples_out[sample_no] = syn_complex_add(sample_a,tmp_sample);
            rsamples_out[sample_no+pair_offset] = syn_complex_sub(sample_a,tmp_sample);


            ovm_report_info({get_name(),"[fft_chk-RChannel]"},$psprintf("Waiting on rcvd_que0"),OVM_LOW);
            while(!rcvd_que.size()) #1;

            rcvd_pkt  = rcvd_que.pop_front();

            expctd_pkt  = new();
            expctd_pkt.addr   = sample_no+num_samples;
            expctd_pkt.sample = rsamples_out[sample_no];

            res = expctd_pkt.check(rcvd_pkt,  6);

            if(res  ==  "")
              ovm_report_info({get_name(),"[fft_chk-RChannel]"},$psprintf("Data[%1d] is correct",sample_no),OVM_LOW);
            else
              ovm_report_error({get_name(),"[fft_chk-RChannel]"},$psprintf("Data[%1d] is in-correct%s",sample_no,res),OVM_LOW);

            nxt_pkt.pcm_data[sample_no+num_samples] = {rcvd_pkt.sample.re,  rcvd_pkt.sample.im};

            ovm_report_info({get_name(),"[fft_chk-RChannel]"},$psprintf("Waiting on rcvd_que1"),OVM_LOW);
            while(!rcvd_que.size()) #1;

            rcvd_pkt  = rcvd_que.pop_front();

            expctd_pkt  = new();
            expctd_pkt.addr   = sample_no+pair_offset+num_samples;
            expctd_pkt.sample = rsamples_out[sample_no+pair_offset];

            res = expctd_pkt.check(rcvd_pkt,  6);

            if(res  ==  "")
              ovm_report_info({get_name(),"[fft_chk-RChannel]"},$psprintf("Data[%1d] is correct",sample_no+pair_offset),OVM_LOW);
            else
              ovm_report_error({get_name(),"[fft_chk-RChannel]"},$psprintf("Data[%1d] is in-correct%s",sample_no+pair_offset,res),OVM_LOW);

            nxt_pkt.pcm_data[sample_no+num_samples+pair_offset] = {rcvd_pkt.sample.re,  rcvd_pkt.sample.im};

            sample_no +=  pair_offset*2;

            if(sample_no  >=  num_samples)
            begin
              sample_no = (sample_no+1)%num_samples;
              k = k+  (num_samples/(pair_offset*2));
            end
          end

          //update buffers
          foreach(rsamples_out[i])
          begin
            rsamples_in[i]  = rsamples_out[i];
          end

          if(stage_no !=  num_stages-1) rsamples_out  = new[num_samples];
        end

        //global_stop_request();

        /*
        //Prep nxt_pkt
        nxt_pkt = new();
        nxt_pkt.pcm_data  = new[num_samples*2];

        for(int i=0; i<num_samples; i++)
        begin
          nxt_pkt.pcm_data[i]             = {lsamples_in[i].re,  lsamples_in[i].im};
          nxt_pkt.pcm_data[i+num_samples] = {rsamples_in[i].re,  rsamples_in[i].im};
        end
        */

        ovm_report_info({get_name(),"[fft_chk]"},$psprintf("Sending nxt_pkt to stage_2_mb\n%s",nxt_pkt.sprint()),OVM_LOW);
        stage_2_mb.put(nxt_pkt);
      end

    endtask : fft_chk


    /*  Task to check the Cordic stage of FFT*/
    task  cordic_chk();
      SENT_PKT_TYPE fft_pkt,nxt_pkt;
      RCVD_PKT_TYPE rcvd_pkt,expctd_pkt;
      string res;
      int   im,re;
      real  im_by_re,theta,norm_fac;

      ovm_report_info({get_name(),"[cordic_chk]"},"Start of cordic_chk",OVM_LOW);

      forever
      begin
        ovm_report_info({get_name(),"[cordic_chk]"},$psprintf("Waiting on stage_2_mb"),OVM_LOW);
        stage_2_mb.get(fft_pkt);

        nxt_pkt = new();
        nxt_pkt.pcm_data  = new[fft_pkt.pcm_data.size];

        for(int i=0;  i<fft_pkt.pcm_data.size;  i++)
        begin
          $cast(re,  fft_pkt.pcm_data[i] >>  P_FFT_SAMPLE_W);
          $cast(im,  fft_pkt.pcm_data[i] &   {P_FFT_SAMPLE_W{1'b1}});

          re  = syn_abs(re);
          im  = syn_abs(im);

          im_by_re  = im  / re;
          theta     = syn_atan(im_by_re);

          if(re !=  0.0)
            norm_fac  = syn_cos(theta) * 65535;
          else
            norm_fac  = 65535.0;

          if(norm_fac < 0)  norm_fac  = norm_fac  * -1.0;
          if(norm_fac > 65535)  norm_fac  = 65535.0;  //contain within 16b

          ovm_report_info({get_name(),"[cordic_chk]"},$psprintf("Waiting on rcvd_que"),OVM_LOW);
          while(!rcvd_que.size()) #1;

          rcvd_pkt  = rcvd_que.pop_front();

          expctd_pkt  = new();
          expctd_pkt.addr   = i;
          $cast(expctd_pkt.sample.re, fft_pkt.pcm_data[i] >>  P_FFT_SAMPLE_W);
          $cast(expctd_pkt.sample.im, norm_fac);

          res = expctd_pkt.check(rcvd_pkt,  1);

          ovm_report_info({get_name(),"[cordic_chk]"},$psprintf("re:%1d, im:%1d, im_by_re:%1f, theta:%1f, norm_fac:%1f",re,im,im_by_re,theta,norm_fac),OVM_LOW);

          if(res  ==  "")
            ovm_report_info({get_name(),"[cordic_chk]"},$psprintf("Data[%1d] is correct",i),OVM_LOW);
          else
            ovm_report_error({get_name(),"[cordic_chk]"},$psprintf("Data[%1d] is in-correct%s",i,res),OVM_LOW);

          $cast(nxt_pkt.pcm_data[i],  {expctd_pkt.sample.re,expctd_pkt.sample.im});
        end

        ovm_report_info({get_name(),"[cordic_chk]"},$psprintf("Sending nxt_pkt to stage_3_mb\n%s",nxt_pkt.sprint()),OVM_LOW);
        stage_3_mb.put(nxt_pkt);

        //global_stop_request();
      end

    endtask : cordic_chk


    /*  Task to check abs stage of Fgyrus */
    task  abs_chk();
      SENT_PKT_TYPE pkt_in;
      RCVD_PKT_TYPE rcvd_pkt,expctd_pkt;
      string res;
      int re,im,abs;

      ovm_report_info({get_name(),"[abs_chk]"},"Start of abs_chk",OVM_LOW);

      forever
      begin
        ovm_report_info({get_name(),"[abs_chk]"},$psprintf("Waiting on stage_3_mb"),OVM_LOW);
        stage_3_mb.get(pkt_in);

        for(int i=0;  i<pkt_in.pcm_data.size;  i++)
        begin
          $cast(re,  pkt_in.pcm_data[i] >>  P_FFT_SAMPLE_W);
          $cast(im,  pkt_in.pcm_data[i] &   {P_FFT_SAMPLE_W{1'b1}});

          re  = syn_abs(re);
          im  = syn_abs(im);
          abs = (re << 16)/im;

          ovm_report_info({get_name(),"[abs_chk]"},$psprintf("Waiting on rcvd_que"),OVM_LOW);
          while(!rcvd_que.size()) #1;

          rcvd_pkt  = rcvd_que.pop_front();

          expctd_pkt  = new();
          expctd_pkt.addr   = i;
          $cast(expctd_pkt.sample.re, abs);
          $cast(expctd_pkt.sample.im, 0);

          res = expctd_pkt.check(rcvd_pkt,  2);

          if(res  ==  "")
            ovm_report_info({get_name(),"[abs_chk]"},$psprintf("Data[%1d] is correct",i),OVM_LOW);
          else
            ovm_report_error({get_name(),"[abs_chk]"},$psprintf("Data[%1d] is in-correct%s",i,res),OVM_LOW);

        end
      end
    endtask : abs_chk

    /*  Run */
    task run();
      fork
        begin
          win_decimate_chk();
        end

        begin
          fft_chk();
        end

        begin
          cordic_chk();
        end

        begin
          abs_chk();
        end
      join
    endtask : run


    /*  Report  */
    virtual function void report();
      ovm_report_info({get_type_name(),"[report]"},$psprintf("Report -\n%s", this.sprint()), OVM_LOW);
    endfunction : report

  endclass : syn_fft_cache_sb

`endif
