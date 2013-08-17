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
 -- Sequence Name     : syn_gpu_mul_job_config_seq
 -- Author            : mammenx
 -- Function          : This sequence generates LB transactions to configure
                        & trigger a mul job in GPU.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_GPU_MUL_JOB_CONFIG_SEQ
`define __SYN_GPU_MUL_JOB_CONFIG_SEQ

  import  syn_gpu_pkg::*;

  class syn_gpu_mul_job_config_seq   #(
                                         type  PKT_TYPE  =  syn_lb_seq_item,
                                         type  SEQR_TYPE =  syn_lb_seqr
                                      ) extends ovm_sequence  #(PKT_TYPE);

    /*  Adding the parameterized sequence to the registery  */
    typedef syn_gpu_mul_job_config_seq#(PKT_TYPE,SEQR_TYPE) this_type;
    typedef ovm_object_registry#(this_type)type_id;

    /*  Linking with p_sequencer  */
    `ovm_declare_p_sequencer(SEQR_TYPE)


    `include  "syn_cortex_reg_map.sv"
    `include  "syn_vcortex_reg_map.sv"


    PKT_TYPE  pkt,rsp;
    sid_t  sid;
    bit [15:0]  data0,data1;

    syn_poll_gpu_status_seq#(PKT_TYPE,SEQR_TYPE)  poll_seq;

    /*  Constructor */
    function new(string name  = "syn_gpu_mul_job_config_seq");
      super.new(name);

      pkt = new();
      rsp = new();
      sid = SID_IDLE;
      data0 = 0;
      data1 = 0;
    endfunction

    /*  Body of sequence  */
    task  body();
      action_t  action  = MULBRY;

      p_sequencer.ovm_report_info(get_name(),"Start of syn_gpu_mul_job_config_seq",OVM_LOW);

      //The job has to be populated from the test case

      $cast(pkt,create_item(PKT_TYPE::get_type(),m_sequencer,$psprintf("GPU Mul Job Config seq")));

      start_item(pkt);  //start_item has wait_for_grant()
      
      pkt.addr  = new[4];
      pkt.data  = new[4];
      pkt.lb_xtn= BURST_WRITE;

      $cast(pkt.addr[0],{VCORTEX_BLK,VCORTEX_GPU_CODE,VCORTEX_GPU_JOB_BFFR_1_REG_ADDR});
      $cast(pkt.data[0],sid);

      $cast(pkt.addr[1],{VCORTEX_BLK,VCORTEX_GPU_CODE,VCORTEX_GPU_JOB_BFFR_2_REG_ADDR});
      $cast(pkt.data[1],data0);

      $cast(pkt.addr[2],{VCORTEX_BLK,VCORTEX_GPU_CODE,VCORTEX_GPU_JOB_BFFR_3_REG_ADDR});
      $cast(pkt.data[2],data1);

      $cast(pkt.addr[3],{VCORTEX_BLK,VCORTEX_GPU_CODE,VCORTEX_GPU_JOB_BFFR_0_REG_ADDR});
      $cast(pkt.data[3],action);

      p_sequencer.ovm_report_info(get_name(),$psprintf("Generated pkt - \n%s", pkt.sprint()),OVM_LOW);

      finish_item(pkt);

      #1;

      poll_seq = syn_poll_gpu_status_seq#(PKT_TYPE,SEQR_TYPE)::type_id::create("gpu_status_poll_seq");
      poll_seq.start(p_sequencer, this);

      #1;
      
      $cast(pkt,create_item(PKT_TYPE::get_type(),m_sequencer,$psprintf("GPU Mul Job Result seq")));

      start_item(pkt);  //start_item has wait_for_grant()
      
      pkt.addr  = new[2];
      pkt.data  = new[2];
      pkt.lb_xtn= BURST_READ;

      $cast(pkt.addr[0],{VCORTEX_BLK,VCORTEX_GPU_CODE,VCORTEX_GPU_JOB_BFFR_2_REG_ADDR});
      $cast(pkt.data[0],data0);

      $cast(pkt.addr[1],{VCORTEX_BLK,VCORTEX_GPU_CODE,VCORTEX_GPU_JOB_BFFR_3_REG_ADDR});
      $cast(pkt.data[1],data1);

      p_sequencer.ovm_report_info(get_name(),$psprintf("Generated pkt - \n%s", pkt.sprint()),OVM_LOW);

      finish_item(pkt);

      get_response(rsp);  //wait for response

      p_sequencer.ovm_report_info(get_name(),$psprintf("Got Response - \n%s", rsp.sprint()),OVM_LOW);
      $cast(data0,rsp.data[0]);
      $cast(data1,rsp.data[1]);

      #1;

    endtask : body


  endclass  : syn_gpu_mul_job_config_seq

`endif
