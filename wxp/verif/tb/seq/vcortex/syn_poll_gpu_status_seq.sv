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
 -- Sequence Name     : syn_poll_gpu_status_seq
 -- Author            : mammenx
 -- Function          : This sequence polls the GPU status register until
                        the required bits are set.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_POLL_GPU_STATUS_SEQ
`define __SYN_POLL_GPU_STATUS_SEQ

  class syn_poll_gpu_status_seq   #(
                                     type  PKT_TYPE  =  syn_lb_seq_item,
                                     type  SEQR_TYPE =  syn_lb_seqr
                                  ) extends ovm_sequence  #(PKT_TYPE);

    /*  Adding the parameterized sequence to the registery  */
    typedef syn_poll_gpu_status_seq#(PKT_TYPE,SEQR_TYPE) this_type;
    typedef ovm_object_registry#(this_type)type_id;

    /*  Linking with p_sequencer  */
    `ovm_declare_p_sequencer(SEQR_TYPE)


    `include  "syn_cortex_reg_map.sv"
    `include  "syn_vcortex_reg_map.sv"

    bit gpu_busy,anti_alias_job_qeue_empty;
    PKT_TYPE  pkt, rsp;

    /*  Constructor */
    function new(string name  = "syn_poll_gpu_status_seq");
      super.new(name);

      gpu_busy  = 0;
      anti_alias_job_qeue_empty = 1;
      pkt = new();
      rsp = new();
    endfunction

    /*  Body of sequence  */
    task  body();
      p_sequencer.ovm_report_info(get_name(),"Start of syn_poll_gpu_status_seq",OVM_LOW);

      do
      begin
        #1us;

        $cast(pkt,create_item(PKT_TYPE::get_type(),m_sequencer,$psprintf("Poll GPU Status")));

        start_item(pkt);  //start_item has wait_for_grant()

        pkt.lb_xtn      = READ;
        pkt.addr        = new[1];
        $cast(pkt.addr[0],  {VCORTEX_BLK,VCORTEX_GPU_CODE,VCORTEX_GPU_STATUS_REG_ADDR});
        pkt.data        = new[1];
        $cast(pkt.data[0],  $random);

        p_sequencer.ovm_report_info(get_name(),$psprintf("Generated pkt - \n%s", pkt.sprint()),OVM_LOW);

        finish_item(pkt);

        get_response(rsp);  //wait for response

        p_sequencer.ovm_report_info(get_name(),$psprintf("Got Response - \n%s", rsp.sprint()),OVM_LOW);
      end
      while(rsp.data[0][1:0]  !=  {anti_alias_job_qeue_empty,gpu_busy});

      #1;

      p_sequencer.ovm_report_info(get_name(),"End of syn_poll_gpu_status_seq",OVM_LOW);
    endtask : body


  endclass  : syn_poll_gpu_status_seq

`endif
