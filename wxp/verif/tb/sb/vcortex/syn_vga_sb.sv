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
 -- Component Name    : syn_vga_sb
 -- Author            : mammenx
 -- Function          : This scoreboard checks if the data given by VGA is
                        correct or not.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_VGA_SB
`define __SYN_VGA_SB

  import  syn_gpu_pkg::*;
  import  syn_image_pkg::*;

//Implicit port declarations
`ovm_analysis_imp_decl(_vga_rcvd_pkt)

  class syn_vga_sb  #(parameter FRM_BFFR_W    = 16,
                      type      RCVD_PKT_TYPE = syn_vga_seq_item
                  ) extends ovm_scoreboard;

    /*  Register with Factory */
    `ovm_component_param_utils(syn_vga_sb#(FRM_BFFR_W, RCVD_PKT_TYPE))

    //Queue to hold the pkts
    RCVD_PKT_TYPE rcvd_que[$];

    //Ports
    ovm_analysis_imp_vga_rcvd_pkt #(RCVD_PKT_TYPE,syn_vga_sb)  Mon_rcvd_2Sb_port;

    OVM_FILE  f;

    //VGA Timing parameters
    //Taken from [http://tinyvga.com/vga-timing/640x480@60Hz]
    parameter P_VGA_HVALID_W        = 640;
    parameter P_VGA_HFP_W           = 16;
    parameter P_VGA_HSYNC_W         = 96;
    parameter P_VGA_HBP_W           = 48;
    parameter  P_VGA_HTOTAL_W       = P_VGA_HVALID_W  + P_VGA_HFP_W + P_VGA_HSYNC_W + P_VGA_HBP_W;
    parameter  P_VGA_HCNTR_W        = $clog2(P_VGA_HTOTAL_W);

    parameter P_VGA_VVALID_W        = 480;
    parameter P_VGA_VFP_W           = 10;
    parameter P_VGA_VSYNC_W         = 2;
    parameter P_VGA_VBP_W           = 33;
    parameter  P_VGA_VTOTAL_W       = P_VGA_VVALID_W  + P_VGA_VFP_W + P_VGA_VSYNC_W + P_VGA_VBP_W;
    parameter  P_VGA_VCNTR_W        = $clog2(P_VGA_VTOTAL_W);


    //Must connect this to the frame buffer in SRAM driver
    bit [FRM_BFFR_W-1:0]  frm_bffr[];


    /*  Constructor */
    function new(string name = "syn_vga_sb", ovm_component parent);
      super.new(name, parent);
    endfunction : new


    /*  Build */
    function void build();
      super.build();

      f = $fopen({"./logs/",get_full_name(),".log"},  "w");

      set_report_default_file(f);
      set_report_severity_action(OVM_INFO,  OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_WARNING, OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_ERROR,  OVM_COUNT | OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_FATAL,  OVM_EXIT | OVM_DISPLAY | OVM_LOG);

      ovm_report_info(get_name(),"Start of build ",OVM_LOW);

      Mon_rcvd_2Sb_port = new("Mon_rcvd_2Sb_port", this);


      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction


    /*
      * Write Rcvd Pkt
      * This function will be called each time a pkt is written into [ovm_analysis_imp_vga_rcvd_pkt]Mon_rcvd_2Sb_port
    */
    virtual function void write_vga_rcvd_pkt(input RCVD_PKT_TYPE pkt);
      ovm_report_info({get_name(),"[write_vga_rcvd_pkt]"},$psprintf("Received pkt\n%s",pkt.sprint()),OVM_LOW);

      //Push packet into rcvd queue
      rcvd_que.push_back(pkt);

      ovm_report_info({get_name(),"[write_vga_rcvd_pkt]"},$psprintf("There are %d items in rcvd_que[$]",rcvd_que.size()),OVM_LOW);
    endfunction : write_vga_rcvd_pkt


    /*  Run */
    task run();
      int line_cntr=0;
      RCVD_PKT_TYPE rcvd_pkt;
      pxl_rgb_t     exp_pxl;
      pxl_hsi_t     pxl_hsi;
      int frm_bffr_addr,frm_bffr_msb_n_lsb;
      string        msg;

      ovm_report_info({get_name(),"[run]"},"Start of run",OVM_LOW);

      forever
      begin
        ovm_report_info({get_name(),"[run]"},"Waiting on rcvd_que ...",OVM_LOW);
        while(!rcvd_que.size) #1;

        rcvd_pkt  = rcvd_que.pop_front();

        if(rcvd_pkt.vga_type  !=  VGA_LINE)
        begin
          ovm_report_error({get_name(),"[run]"},$psprintf("Unexpected vga_type:%s",rcvd_pkt.vga_type.name),OVM_LOW);
          continue;
        end

        if(rcvd_pkt.pxl_arry.size !=  P_VGA_HVALID_W)
        begin
          ovm_report_error({get_name(),"[run]"},$psprintf("Unexpected pxl_arry.size:%1d",rcvd_pkt.pxl_arry.size),OVM_LOW);
          continue;
        end

        if(rcvd_pkt.fp  !=  P_VGA_HFP_W)
        begin
          ovm_report_error({get_name(),"[run]"},$psprintf("Unexpected hfp:%1d",rcvd_pkt.fp),OVM_LOW);
          continue;
        end

        if(rcvd_pkt.bp  !=  P_VGA_HBP_W)
        begin
          ovm_report_error({get_name(),"[run]"},$psprintf("Unexpected hbp:%1d",rcvd_pkt.bp),OVM_LOW);
          continue;
        end

        if(rcvd_pkt.sync  !=  P_VGA_HSYNC_W)
        begin
          ovm_report_error({get_name(),"[run]"},$psprintf("Unexpected hsync:%1d",rcvd_pkt.bp),OVM_LOW);
          continue;
        end

        for(int i=0; i<rcvd_pkt.pxl_arry.size;  i++)
        begin
          frm_bffr_addr = ((P_VGA_VVALID_W*line_cntr) + i)/2;
          frm_bffr_msb_n_lsb  = ((P_VGA_VVALID_W*line_cntr) + i) % 2;

          if(frm_bffr_msb_n_lsb)
            $cast(pxl_hsi,  frm_bffr[frm_bffr_addr][FRM_BFFR_W-1:(FRM_BFFR_W/2)]);
          else
            $cast(pxl_hsi,  frm_bffr[frm_bffr_addr][(FRM_BFFR_W/2)-1:0]);

          //Convert to rgb
          exp_pxl = convert_hsi2rgb(pxl_hsi);

          if(rcvd_pkt.pxl_arry[i] !=  exp_pxl)
          begin
            msg = "Expected ->";
            msg = $psprintf("%s\nH:0x%x, S:0x%x, I:0x%x",msg,pxl_hsi.h,pxl_hsi.s,pxl_hsi.i);
            msg = $psprintf("%s\nR:0x%x, G:0x%x, B:0x%x",msg,exp_pxl.red,exp_pxl.green,exp_pxl.blue);
            msg = {msg,"\nReceived ->"};
            msg = $psprintf("%s\nR:0x%x, G:0x%x, B:0x%x",msg,rcvd_pkt.pxl_arry[i].red,rcvd_pkt.pxl_arry[i].green,rcvd_pkt.pxl_arry[i].blue);

            ovm_report_error({get_name(),"[run]"},$psprintf("Pixel Mismatch@%1d|%1d",frm_bffr_addr,frm_bffr_msb_n_lsb),OVM_LOW);
          end
        end
      end

    endtask : run


    /*  Report  */
    virtual function void report();
      ovm_report_info({get_type_name(),"[report]"},$psprintf("Report -\n%s", this.sprint()), OVM_LOW);
    endfunction : report

  endclass : syn_vga_sb

`endif
