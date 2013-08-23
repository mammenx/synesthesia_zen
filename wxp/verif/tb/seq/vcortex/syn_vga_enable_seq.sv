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
 -- Sequence Name     : syn_vga_enable_seq
 -- Author            : mammenx
 -- Function          : This sequence generates a LB transaction that
                        enables the GPU.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_VGA_ENABLE_SEQ
`define __SYN_VGA_ENABLE_SEQ

  class syn_vga_enable_seq  #(
                               type  PKT_TYPE  =  syn_lb_seq_item,
                               type  SEQR_TYPE =  syn_lb_seqr
                            ) extends ovm_sequence  #(PKT_TYPE);

    /*  Adding the parameterized sequence to the registery  */
    typedef syn_vga_enable_seq#(PKT_TYPE,SEQR_TYPE) this_type;
    typedef ovm_object_registry#(this_type)type_id;

    /*  Linking with p_sequencer  */
    `ovm_declare_p_sequencer(SEQR_TYPE)


    `include  "syn_cortex_reg_map.sv"
    `include  "syn_vcortex_reg_map.sv"


    /*  Constructor */
    function new(string name  = "syn_vga_enable_seq");
      super.new(name);
    endfunction

    /*  Body of sequence  */
    task  body();
      PKT_TYPE  pkt = new();

      p_sequencer.ovm_report_info(get_name(),"Start of syn_vga_enable_seq",OVM_LOW);

      $cast(pkt,create_item(PKT_TYPE::get_type(),m_sequencer,$psprintf("VGA Enable seq")));

      start_item(pkt);  //start_item has wait_for_grant()
      
      pkt.addr  = new[1];
      pkt.data  = new[1];
      pkt.lb_xtn= WRITE;

      $cast(pkt.addr[0],  {VCORTEX_BLK,VCORTEX_VGA_CODE,VCORTEX_VGA_CONTROL_REG_ADDR});
      pkt.data[0] = 'd1;

      p_sequencer.ovm_report_info(get_name(),$psprintf("Generated pkt - \n%s", pkt.sprint()),OVM_LOW);


      finish_item(pkt);

      #1;


    endtask : body


  endclass  : syn_vga_enable_seq

`endif
