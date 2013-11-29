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
 -- Sequence Name     : syn_sram_acc_seq
 -- Author            : mammenx
 -- Function          : This sequence generated random read/write xtns for
                        the sram_acc_intf.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_SRAM_ACC_SEQ
`define __SYN_SRAM_ACC_SEQ

  import  syn_math_pkg::*;

  class syn_sram_acc_seq  #(
                            type  PKT_TYPE  = syn_lb_seq_item#(16,18),
                            type  SEQR_TYPE = syn_sram_acc_seqr#(PKT_TYPE)
                          ) extends ovm_sequence  #(PKT_TYPE);

    /*  Adding the parameterized sequence to the registery  */
    typedef syn_sram_acc_seq#(PKT_TYPE,SEQR_TYPE) this_type;
    typedef ovm_object_registry#(this_type)type_id;

    /*  Linking with p_sequencer  */
    `ovm_declare_p_sequencer(SEQR_TYPE)

    bit read_only;
    int num_xtns,seed,avg_xtn_len;
    PKT_TYPE  pkt, rsp;

    /*  Constructor */
    function new(string name  = "syn_sram_acc_seq");
      super.new(name);

      read_only = 0;
      num_xtns  = 10;
      seed      = 0;
      avg_xtn_len = 10;

      pkt = new();
      rsp = new();
    endfunction

    /*  Body of sequence  */
    task  body();
      int i=0;

      p_sequencer.ovm_report_info(get_name(),"Start of syn_sram_acc_seq",OVM_LOW);

      if(!seed) seed  = $random;

      p_sequencer.ovm_report_info(get_name(),$psprintf("Seed:%1d",seed),OVM_LOW);

      forever
      begin
        $cast(pkt,create_item(PKT_TYPE::get_type(),m_sequencer,$psprintf("sram_acc xtn:%1d",i)));

        start_item(pkt);  //start_item has wait_for_grant()

        if(read_only)
          pkt.lb_xtn  = READ;
        else
          $cast(pkt.lb_xtn, ($random & 'h1));

        pkt.addr        = new[syn_abs($dist_exponential(seed,avg_xtn_len)) + 1];
        pkt.data        = new[pkt.addr.size];

        if(pkt.addr.size > 1)
        begin
          if(pkt.lb_xtn ==  READ)
            pkt.lb_xtn  = BURST_READ;
          else
            pkt.lb_xtn  = BURST_WRITE;
        end

        for(int n=0; n<pkt.addr.size; n++)
        begin
          $cast(pkt.addr[n],  $random);
          $cast(pkt.data[n],  $random);
        end

        p_sequencer.ovm_report_info(get_name(),$psprintf("Generated pkt - \n%s", pkt.sprint()),OVM_LOW);

        finish_item(pkt);

        #1;

        if((pkt.lb_xtn == READ) ||  (pkt.lb_xtn ==  BURST_READ))
        begin
          get_response(rsp);  //wait for response

          p_sequencer.ovm_report_info(get_name(),$psprintf("Got Response - \n%s", rsp.sprint()),OVM_LOW);
          #1;
        end

        i++;

        if((i>=num_xtns)  &&  (num_xtns>0)) break;
      end

    endtask : body


  endclass  : syn_sram_acc_seq

`endif
