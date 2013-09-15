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
 -- Sequence Name     : syn_adc_cap_seq
 -- Author            : mammenx
 -- Function          : This sequence triggers ADC capture, polls acache
                        till acortex completion and reads out the PCM data.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_ADC_CAP_SEQ
`define __SYN_ADC_CAP_SEQ

  import  syn_audio_pkg::*;

  class syn_adc_cap_seq  #(
                           parameter type  PKT_TYPE  = syn_lb_seq_item,
                           parameter type  SEQR_TYPE = syn_lb_seqr#(PKT_TYPE)
                         ) extends ovm_sequence  #(PKT_TYPE);



    /*  Adding the parameterized sequence to the registery  */
    typedef syn_adc_cap_seq#(PKT_TYPE,SEQR_TYPE) this_type;
    typedef ovm_object_registry#(this_type)type_id;

    /*  Linking with p_sequencer  */
    `ovm_declare_p_sequencer(SEQR_TYPE)

    `include  "syn_cortex_reg_map.sv"
    `include  "syn_acortex_reg_map.sv"

    PKT_TYPE  cap_pkt;  //for holding captured PCM data
    int       poll_time_us;
    int       num_samples;

    /*  Constructor */
    function new(string name  = "syn_adc_cap_seq");
      super.new(name);

      poll_time_us  = 100;
      num_samples   = 128;
      cap_pkt       = new();
    endfunction

    /*  Body of sequence  */
    task  body();
      PKT_TYPE  pkt,rsp;
      int i = 0;

      /*  Start ADC Capture */
      p_sequencer.ovm_report_info(get_name(),"Start of syn_adc_cap_seq",OVM_LOW);

      $cast(pkt,create_item(PKT_TYPE::get_type(),m_sequencer,$psprintf("ADC Capture Trigger Seq")));

      start_item(pkt);  //start_item has wait_for_grant()
      
      pkt.addr  = new[1];
      pkt.data  = new[1];
      pkt.lb_xtn= WRITE;

      $cast(pkt.addr[0],  {ACORTEX_BLK,ACORTEX_ACACHE_CODE,ACORTEX_ACACHE_CTRL_REG_ADDR});
      pkt.data[0] = 'd1;

      p_sequencer.ovm_report_info(get_name(),$psprintf("Generated pkt - \n%s", pkt.sprint()),OVM_LOW);

      finish_item(pkt);

      #1;

      /*  Start Polling */
      do
      begin
        repeat(poll_time_us)  #1us;

        $cast(pkt,create_item(PKT_TYPE::get_type(),m_sequencer,$psprintf("Acache Poll Seq[%1d]",i)));

        start_item(pkt);  //start_item has wait_for_grant()
        
        pkt.addr  = new[1];
        pkt.data  = new[1];
        pkt.lb_xtn= READ;

        $cast(pkt.addr[0],  {ACORTEX_BLK,ACORTEX_ACACHE_CODE,ACORTEX_ACACHE_STATUS_REG_ADDR});
        pkt.data[0] = $random;

        p_sequencer.ovm_report_info(get_name(),$psprintf("Generated pkt - \n%s", pkt.sprint()),OVM_LOW);

        finish_item(pkt);

        get_response(rsp);  //wait for response

        p_sequencer.ovm_report_info(get_name(),$psprintf("Got Response pkt - \n%s", rsp.sprint()),OVM_LOW);

        i++;
      end
      while(rsp.data[0][0]  !=  1);


      /*  Read the captured PCM data */
      cap_pkt = new();
      cap_pkt.addr  = new[num_samples*2];
      cap_pkt.data  = new[num_samples*2];

      for(i =0; i<(num_samples*2);  i++)
      begin
        $cast(pkt,create_item(PKT_TYPE::get_type(),m_sequencer,$psprintf("Acache CAP NO Seq[%1d]",i)));

        start_item(pkt);  //start_item has wait_for_grant()
        
        pkt.addr  = new[1];
        pkt.data  = new[1];
        pkt.lb_xtn= WRITE;

        $cast(pkt.addr[0],  {ACORTEX_BLK,ACORTEX_ACACHE_CODE,ACORTEX_ACACHE_CAP_NO_ADDR});
        pkt.data[0] = i;

        p_sequencer.ovm_report_info(get_name(),$psprintf("Generated pkt - \n%s", pkt.sprint()),OVM_LOW);

        finish_item(pkt);

        #30ns;

        $cast(pkt,create_item(PKT_TYPE::get_type(),m_sequencer,$psprintf("Acache CAP DATA Seq[%1d]",i)));

        start_item(pkt);  //start_item has wait_for_grant()
        
        pkt.addr  = new[1];
        pkt.data  = new[1];
        pkt.lb_xtn= READ;

        $cast(pkt.addr[0],  {ACORTEX_BLK,ACORTEX_ACACHE_CODE,ACORTEX_ACACHE_CAP_DATA_ADDR});
        pkt.data[0] = $random;

        p_sequencer.ovm_report_info(get_name(),$psprintf("Generated pkt - \n%s", pkt.sprint()),OVM_LOW);

        finish_item(pkt);

        get_response(rsp);  //wait for response

        p_sequencer.ovm_report_info(get_name(),$psprintf("Got Response pkt - \n%s", rsp.sprint()),OVM_LOW);

        //Copy into cap_pkt
        cap_pkt.addr[i] = i;
        cap_pkt.data[i] = rsp.data[0];

        #1;
      end

      p_sequencer.ovm_report_info(get_name(),$psprintf("ADC CAP pkt - \n%s", cap_pkt.sprint()),OVM_LOW);

    endtask : body


  endclass  : syn_adc_cap_seq

`endif
