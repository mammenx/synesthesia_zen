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
 -- Sequence Name     : syn_fgyrus_mem_acc_seq
 -- Author            : mammenx
 -- Function          : This sequence generates random writes to each of
                        the memories in FGyrus and reads them back and
                        checks for errors.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_FGYRUS_MEM_ACC_SEQ
`define __SYN_FGYRUS_MEM_ACC_SEQ

  class syn_fgyrus_mem_acc_seq  #(
                                   type  PKT_TYPE  =  syn_lb_seq_item,
                                   type  SEQR_TYPE =  syn_lb_seqr#(PKT_TYPE)
                                ) extends ovm_sequence  #(PKT_TYPE);

    /*  Adding the parameterized sequence to the registery  */
    typedef syn_fgyrus_mem_acc_seq#(PKT_TYPE,SEQR_TYPE) this_type;
    typedef ovm_object_registry#(this_type)type_id;

    /*  Linking with p_sequencer  */
    `ovm_declare_p_sequencer(SEQR_TYPE)

    `include  "syn_cortex_reg_map.sv"
    `include  "syn_fgyrus_reg_map.sv"

    /*  Constructor */
    function new(string name  = "syn_fgyrus_mem_acc_seq");
      super.new(name);
    endfunction

    /*  Body of sequence  */
    task  body();
      PKT_TYPE  wr_pkt,rd_pkt,rsp;
      string    pkt_desc,res;
      int       ram_base_addr,num_locs,data_mask;

      p_sequencer.ovm_report_info(get_name(),"Start of syn_fgyrus_mem_acc_seq",OVM_LOW);

      for(int i=0;  i<3;  i++)
      begin
        if(i==0)
        begin
          pkt_desc  = "Fgyrus WinRam Write pkt";
          ram_base_addr = {FGYRUS_WIN_RAM_CODE,8'd0};
          num_locs  = 128;
          data_mask = 'hffffffff; //32b
        end
        else if(i==1)
        begin
          pkt_desc  = "Fgyrus CordicRam Write pkt";
          ram_base_addr = {FGYRUS_CORDIC_RAM_CODE,8'd0};
          num_locs  = 256;
          data_mask = 'hffff; //16b
        end
        else
        begin
          pkt_desc  = "Fgyrus TwdlRam Write pkt";
          ram_base_addr = {FGYRUS_TWDLE_RAM_CODE,8'd0};
          num_locs  = 128;
          data_mask = 'hffffffff; //32b
        end

        $cast(wr_pkt,create_item(PKT_TYPE::get_type(),m_sequencer,$psprintf("%s",pkt_desc)));

        start_item(wr_pkt);  //start_item has wait_for_grant()
        
        wr_pkt.addr  = new[num_locs];
        wr_pkt.data  = new[num_locs];
        wr_pkt.lb_xtn= BURST_WRITE;

        for(int j=0; j<num_locs;  j++)
        begin
          $cast(wr_pkt.addr[j],  ram_base_addr+j);
          wr_pkt.data[j] = $random  & data_mask;
        end

        p_sequencer.ovm_report_info(get_name(),$psprintf("Generated wr_pkt - \n%s", wr_pkt.sprint()),OVM_LOW);

        finish_item(wr_pkt);

        #1;


        if(i==0)
        begin
          pkt_desc  = "Fgyrus WinRam Read pkt";
        end
        else if(i==1)
        begin
          pkt_desc  = "Fgyrus CordicRam Read pkt";
        end
        else
        begin
          pkt_desc  = "Fgyrus TwdlRam Read pkt";
        end

        $cast(rd_pkt,create_item(PKT_TYPE::get_type(),m_sequencer,$psprintf("%s",pkt_desc)));

        start_item(rd_pkt);  //start_item has wait_for_grant()
        
        rd_pkt.addr  = new[num_locs];
        rd_pkt.data  = new[num_locs];
        rd_pkt.lb_xtn= BURST_READ;

        for(int j=0; j<num_locs;  j++)
        begin
          $cast(rd_pkt.addr[j],  ram_base_addr+j);
          rd_pkt.data[j] = $random  & data_mask;
        end

        p_sequencer.ovm_report_info(get_name(),$psprintf("Generated rd_pkt - \n%s", rd_pkt.sprint()),OVM_LOW);

        finish_item(rd_pkt);

        get_response(rsp);  //wait for response

        p_sequencer.ovm_report_info(get_name(),$psprintf("Got Response pkt - \n%s", rsp.sprint()),OVM_LOW);

        rsp.lb_xtn  = BURST_WRITE;

        res = wr_pkt.checkString(rsp);

        if(res  ==  "")
          p_sequencer.ovm_report_info(get_name(),$psprintf("%s is correct", pkt_desc),OVM_LOW);
        else
          p_sequencer.ovm_report_error(get_name(),$psprintf("%s is in-correct\n%s", pkt_desc, res),OVM_LOW);

        #1;

      end


    endtask : body


  endclass  : syn_fgyrus_mem_acc_seq

`endif
