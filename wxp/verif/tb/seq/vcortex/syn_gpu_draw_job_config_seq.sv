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
 -- Sequence Name     : syn_gpu_draw_job_config_seq
 -- Author            : mammenx
 -- Function          : This sequence generates LB transactions to configure
                        & trigger a draw job in GPU.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __syn_gpu_draw_job_config_seq
`define __syn_gpu_draw_job_config_seq

  import  syn_gpu_pkg::*;

  class syn_gpu_draw_job_config_seq   #(
                                         type  PKT_TYPE  =  syn_lb_seq_item,
                                         type  SEQR_TYPE =  syn_lb_seqr
                                      ) extends ovm_sequence  #(PKT_TYPE);

    /*  Adding the parameterized sequence to the registery  */
    typedef syn_gpu_draw_job_config_seq#(PKT_TYPE,SEQR_TYPE) this_type;
    typedef ovm_object_registry#(this_type)type_id;

    /*  Linking with p_sequencer  */
    `ovm_declare_p_sequencer(SEQR_TYPE)


    `include  "syn_cortex_reg_map.sv"
    `include  "syn_vcortex_reg_map.sv"


    PKT_TYPE  pkt;
    gpu_draw_job_t  job;


    /*  Constructor */
    function new(string name  = "syn_gpu_draw_job_config_seq");
      super.new(name);

      pkt = new();
    endfunction

    /*  Body of sequence  */
    task  body();
      action_t  action  = DRAW;

      p_sequencer.ovm_report_info(get_name(),"Start of syn_gpu_draw_job_config_seq",OVM_LOW);

      //The job has to be populated from the test case

      $cast(pkt,create_item(PKT_TYPE::get_type(),m_sequencer,$psprintf("GPU Draw Job Config seq")));

      start_item(pkt);  //start_item has wait_for_grant()
      
      pkt.addr  = new[10];
      pkt.data  = new[10];
      pkt.lb_xtn= BURST_WRITE;

      $cast(pkt.addr[0],{VCORTEX_BLK,VCORTEX_GPU_CODE,VCORTEX_GPU_JOB_BFFR_1_REG_ADDR});
      $cast(pkt.data[0],job.shape);

      $cast(pkt.addr[1],{VCORTEX_BLK,VCORTEX_GPU_CODE,VCORTEX_GPU_JOB_BFFR_2_REG_ADDR});
      $cast(pkt.data[1],job.x0);

      $cast(pkt.addr[2],{VCORTEX_BLK,VCORTEX_GPU_CODE,VCORTEX_GPU_JOB_BFFR_3_REG_ADDR});
      $cast(pkt.data[2],job.y0);

      $cast(pkt.addr[3],{VCORTEX_BLK,VCORTEX_GPU_CODE,VCORTEX_GPU_JOB_BFFR_4_REG_ADDR});
      $cast(pkt.data[3],job.x1);

      $cast(pkt.addr[4],{VCORTEX_BLK,VCORTEX_GPU_CODE,VCORTEX_GPU_JOB_BFFR_5_REG_ADDR});
      $cast(pkt.data[4],job.y1);

      $cast(pkt.addr[5],{VCORTEX_BLK,VCORTEX_GPU_CODE,VCORTEX_GPU_JOB_BFFR_6_REG_ADDR});
      $cast(pkt.data[5],job.x2);

      $cast(pkt.addr[6],{VCORTEX_BLK,VCORTEX_GPU_CODE,VCORTEX_GPU_JOB_BFFR_7_REG_ADDR});
      $cast(pkt.data[6],job.y2);

      $cast(pkt.addr[7],{VCORTEX_BLK,VCORTEX_GPU_CODE,VCORTEX_GPU_JOB_BFFR_8_REG_ADDR});
      $cast(pkt.data[7],job.color);

      $cast(pkt.addr[8],{VCORTEX_BLK,VCORTEX_GPU_CODE,VCORTEX_GPU_JOB_BFFR_9_REG_ADDR});
      $cast(pkt.data[8],job.bzdepth);

      $cast(pkt.addr[9],{VCORTEX_BLK,VCORTEX_GPU_CODE,VCORTEX_GPU_JOB_BFFR_0_REG_ADDR});
      $cast(pkt.data[9],action);

      p_sequencer.ovm_report_info(get_name(),$psprintf("Generated pkt - \n%s", pkt.sprint()),OVM_LOW);


      finish_item(pkt);

      #1;

    endtask : body


  endclass  : syn_gpu_draw_job_config_seq

`endif
