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
 -- Sequence Name     : syn_pcm_mem_load_seq
 -- Author            : mammenx
 -- Function          : This sequence loads the pcm mem agent with PCM data.
                        To be used when running pcm_mem_drvr as master.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_PCM_MEM_LOAD_SEQ
`define __SYN_PCM_MEM_LOAD_SEQ

  class syn_pcm_mem_load_seq  #(
                                 type  PKT_TYPE  = syn_pcm_seq_item,
                                 type  SEQR_TYPE = syn_pcm_mem_seqr#(PKT_TYPE)
                              ) extends ovm_sequence  #(PKT_TYPE);

    /*  Adding the parameterized sequence to the registery  */
    typedef syn_pcm_mem_load_seq#(PKT_TYPE,SEQR_TYPE) this_type;
    typedef ovm_object_registry#(this_type)type_id;

    /*  Linking with p_sequencer  */
    `ovm_declare_p_sequencer(SEQR_TYPE)

    PKT_TYPE  pcm_pkt;

    /*  Constructor */
    function new(string name  = "syn_pcm_mem_load_seq");
      super.new(name);
      pcm_pkt = new();
    endfunction

    /*  Body of sequence  */
    task  body();
      PKT_TYPE  pkt;

      p_sequencer.ovm_report_info(get_name(),"Start of syn_pcm_mem_load_seq",OVM_LOW);

      //Need to configure pcm_pkt from test case

      $cast(pkt,create_item(PKT_TYPE::get_type(),m_sequencer,$psprintf("PCM Mem Seq")));

      start_item(pkt);  //start_item has wait_for_grant()

      pkt.pcm_data  = new[pcm_pkt.pcm_data.size];

      foreach(pkt.pcm_data[i])
        pkt.pcm_data[i] = pcm_pkt.pcm_data[i];

      p_sequencer.ovm_report_info(get_name(),$psprintf("Generated pkt - \n%s", pkt.sprint()),OVM_LOW);

      finish_item(pkt);

      #1;

    endtask : body


  endclass  : syn_pcm_mem_load_seq

`endif
