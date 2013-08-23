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
 -- Sequence Name     : syn_fb_init_seq
 -- Author            : mammenx
 -- Function          : This sequence initializes the frame buffer to a 
                        given pixel value.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_FB_INIT_SEQ
`define __SYN_FB_INIT_SEQ

  import  syn_gpu_pkg::pxl_rgb_t;
  import  syn_gpu_pkg::pxl_ycbcr_t;
  import  syn_gpu_pkg::pxl_hsi_t;
  import  syn_image_pkg::convert_rgb2ycbcr;
  import  syn_image_pkg::convert_rgb2hsi;
  import  syn_env_pkg::*;

  class syn_fb_init_seq  #(
                               type  PKT_TYPE  =  syn_lb_seq_item#(16,18),
                               type  SEQR_TYPE =  syn_sram_seqr
                            ) extends ovm_sequence  #(PKT_TYPE);


    /*  Adding the parameterized sequence to the registery  */
    typedef syn_fb_init_seq#(PKT_TYPE,SEQR_TYPE) this_type;
    typedef ovm_object_registry#(this_type)type_id;

    /*  Linking with p_sequencer  */
    `ovm_declare_p_sequencer(SEQR_TYPE)

    pxl_rgb_t pxl;
    fb_init_mode_t  init_mode;

    /*  Constructor */
    function new(string name  = "syn_fb_init_seq");
      super.new(name);

      pxl.red   = 'd0;
      pxl.green = 'd0;
      pxl.blue  = 'd0;

      init_mode = STATIC;
    endfunction

    /*  Body of sequence  */
    task  body();

      case(init_mode)
        STATIC   :   body_static();

        PXL_INC  :   body_pxl_inc();
      endcase

    endtask : body


    /*  Static Initialization */
    task  body_static();
      PKT_TYPE  pkt = new();
      //pxl_ycbcr_t pxl_tmp;
      pxl_hsi_t pxl_tmp;

      p_sequencer.ovm_report_info({get_name(),$psprintf("[%s]",init_mode.name)},"Start of syn_fb_init_seq",OVM_LOW);

      $cast(pkt,create_item(PKT_TYPE::get_type(),m_sequencer,$psprintf("FB Init seq %s",init_mode.name)));

      start_item(pkt);  //start_item has wait_for_grant()
      
      pkt.addr  = new[2**18];
      pkt.data  = new[2**18];
      pkt.lb_xtn= WRITE;

      //test case can set the default value before executing this sequence
      //pxl_tmp = convert_rgb2ycbcr(pxl);
      pxl_tmp = convert_rgb2hsi(pxl);
      //p_sequencer.ovm_report_info(get_name(),$psprintf("pxl_rgb : [0x%x:0x%x:0x%x], pxl_ycbcr : [0x%x:0x%x:0x%x]", pxl.red,pxl.green,pxl.blue, pxl_tmp.y,pxl_tmp.cb,pxl_tmp.cr),OVM_LOW);
      p_sequencer.ovm_report_info({get_name(),$psprintf("[%s]",init_mode.name)},$psprintf("pxl_rgb : [0x%x:0x%x:0x%x], pxl_hsi : [0x%x:0x%x:0x%x]", pxl.red,pxl.green,pxl.blue, pxl_tmp.h,pxl_tmp.s,pxl_tmp.i),OVM_LOW);

      for(int i=0; i<(2**18); i++)
      begin
        pkt.addr[i] = i;
        pkt.data[i] = {pxl_tmp,pxl_tmp};
      end

      p_sequencer.ovm_report_info({get_name(),$psprintf("[%s]",init_mode.name)},$psprintf("Generated pkt - \n%s", pkt.sprint()),OVM_LOW);


      finish_item(pkt);

      #1;

    endtask : body_static


    /*  Incremental Data Initialization */
    task  body_pxl_inc();
      PKT_TYPE  pkt = new();
      pxl_hsi_t pxl1,pxl2;

      p_sequencer.ovm_report_info({get_name(),$psprintf("[%s]",init_mode.name)},"Start of syn_fb_init_seq",OVM_LOW);

      $cast(pkt,create_item(PKT_TYPE::get_type(),m_sequencer,$psprintf("FB Init seq %s",init_mode.name)));

      start_item(pkt);  //start_item has wait_for_grant()
      
      pkt.addr  = new[2**18];
      pkt.data  = new[2**18];
      pkt.lb_xtn= WRITE;

      pxl1.h  = 0;
      pxl1.s  = 0;
      pxl1.i  = 0;

      for(int i=0; i<(2**18); i++)
      begin
        $cast(pxl2, pxl1  + 1);

        pkt.addr[i] = i;
        pkt.data[i] = {pxl2,pxl1};

        $cast(pxl1, pxl1  + 2);
      end

      p_sequencer.ovm_report_info({get_name(),$psprintf("[%s]",init_mode.name)},$psprintf("Generated pkt - \n%s", pkt.sprint()),OVM_LOW);


      finish_item(pkt);

      #1;

    endtask : body_pxl_inc


  endclass  : syn_fb_init_seq

`endif
