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
 -- Sequence Name     : syn_wm8731_drvr_poll_seq
 -- Author            : mammenx
 -- Function          : This sequence polls the WM8731 Driver status reg
                        until the required value is read.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_WM8731_DRVR_POLL_SEQ
`define __SYN_WM8731_DRVR_POLL_SEQ

  import  syn_audio_pkg::*;

  class syn_wm8731_drvr_poll_seq  #(
                                      parameter type  PKT_TYPE  = syn_lb_seq_item,
                                      parameter type  SEQR_TYPE = syn_lb_seqr#(PKT_TYPE)
                                    ) extends ovm_sequence  #(PKT_TYPE);



    /*  Adding the parameterized sequence to the registery  */
    typedef syn_wm8731_drvr_poll_seq#(PKT_TYPE,SEQR_TYPE) this_type;
    typedef ovm_object_registry#(this_type)type_id;

    /*  Linking with p_sequencer  */
    `ovm_declare_p_sequencer(SEQR_TYPE)

    `include  "syn_cortex_reg_map.sv"
    `include  "syn_acortex_reg_map.sv"

    bit fsm_idle;
    int poll_time_us;

    /*  Constructor */
    function new(string name  = "syn_wm8731_drvr_poll_seq");
      super.new(name);

      poll_time_us  = 100;
    endfunction

    /*  Body of sequence  */
    task  body();
      PKT_TYPE  pkt,rsp;
      int i = 0;

      p_sequencer.ovm_report_info(get_name(),"Start of syn_wm8731_drvr_poll_seq",OVM_LOW);

      do
      begin
        repeat(poll_time_us)  #1us;

        $cast(pkt,create_item(PKT_TYPE::get_type(),m_sequencer,$psprintf("WM8731 Driver Poll Seq[%1d]",i)));

        start_item(pkt);  //start_item has wait_for_grant()
        
        pkt.addr  = new[1];
        pkt.data  = new[1];
        pkt.lb_xtn= READ;

        $cast(pkt.addr[0],  {ACORTEX_BLK,ACORTEX_WMDRVR_CODE,ACORTEX_WMDRVR_STATUS_REG_ADDR});
        pkt.data[0] = $random;

        p_sequencer.ovm_report_info(get_name(),$psprintf("Generated pkt - \n%s", pkt.sprint()),OVM_LOW);

        finish_item(pkt);

        get_response(rsp);  //wait for response

        p_sequencer.ovm_report_info(get_name(),$psprintf("Got Response pkt - \n%s", rsp.sprint()),OVM_LOW);

        i++;
      end
      while(rsp.data[0][0]  !=  fsm_idle);

    endtask : body


  endclass  : syn_wm8731_drvr_poll_seq

`endif
