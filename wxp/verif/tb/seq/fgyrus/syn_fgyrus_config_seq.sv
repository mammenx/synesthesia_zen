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
 -- Sequence Name     : syn_fgyrus_config_seq
 -- Author            : mammenx
 -- Function          : This sequence configures the Fgyrus.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_FGYRUS_CONFIG_SEQ
`define __SYN_FGYRUS_CONFIG_SEQ

  import  syn_fft_pkg::*;

  class syn_fgyrus_config_seq #(
                                 type  PKT_TYPE  = syn_lb_seq_item,
                                 type  SEQR_TYPE = syn_lb_seqr#(PKT_TYPE)
                              ) extends ovm_sequence  #(PKT_TYPE);


    /*  Adding the parameterized sequence to the registery  */
    typedef syn_fgyrus_config_seq#(PKT_TYPE,SEQR_TYPE) this_type;
    typedef ovm_object_registry#(this_type)type_id;

    /*  Linking with p_sequencer  */
    `ovm_declare_p_sequencer(SEQR_TYPE)

    `include  "syn_cortex_reg_map.sv"
    `include  "syn_fgyrus_reg_map.sv"

    bit fgyrus_en;
    fgyrus_mode_t  fgyrus_mode;
    bit[3:0]  fgyrus_post_norm;

    /*  Constructor */
    function new(string name  = "syn_fgyrus_config_seq");
      super.new(name);
    endfunction

    /*  Body of sequence  */
    task  body();
      PKT_TYPE pkt;

      p_sequencer.ovm_report_info(get_name(),"Start of syn_fgyrus_config_seq",OVM_LOW);

      //Need to set the fields from test case

      $cast(pkt,create_item(PKT_TYPE::get_type(),m_sequencer,$psprintf("Fgyrus Config Seq")));

      start_item(pkt);  //start_item has wait_for_grant()
      
      pkt.addr  = new[2];
      pkt.data  = new[2];
      pkt.lb_xtn= BURST_WRITE;

      $cast(pkt.addr[0],  {FGYRUS_REG_CODE,FGYRUS_CONTROL_REG_ADDR});
      //pkt.data[0] = $random;
      pkt.data[0] = 0;
      pkt.data[0][0]  = fgyrus_en;
      pkt.data[0][1]  = fgyrus_mode;

      $cast(pkt.addr[1],  {FGYRUS_REG_CODE,FGYRUS_POST_NORM_REG_ADDR});
      pkt.data[1] = fgyrus_post_norm;

      p_sequencer.ovm_report_info(get_name(),$psprintf("Generated pkt - \n%s", pkt.sprint()),OVM_LOW);

      finish_item(pkt);

      #1;

    endtask : body


  endclass  : syn_fgyrus_config_seq

`endif
