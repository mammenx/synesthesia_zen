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
 -- Component Name    : syn_vga_mon
 -- Author            : mammenx
 -- Function          : This component monitors the vga interface.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_VGA_MON
`define __SYN_VGA_MON

  class syn_vga_mon   #(parameter LINE_LENGTH = 640,
                        parameter FRAME_LENGTH= 480,
                        type  PKT_TYPE    = syn_vga_seq_item,
                        type  INTF_TYPE   = virtual syn_vga_intf.TB
                      ) extends ovm_component;

    INTF_TYPE intf;

    ovm_analysis_port #(PKT_TYPE) Mon2Sb_port;

    OVM_FILE  f;

    PKT_TYPE  pkt;

    shortint  enable;
    int unsigned  num_lines,num_frames;

    /*  Register with factory */
    `ovm_component_param_utils_begin(syn_vga_mon#(LINE_LENGTH,FRAME_LENGTH,PKT_TYPE,INTF_TYPE))
      `ovm_field_int(enable,  OVM_ALL_ON);
      `ovm_field_int(num_lines,  OVM_ALL_ON);
      `ovm_field_int(num_frames,  OVM_ALL_ON);
    `ovm_component_utils_end


    /*  Constructor */
    function new( string name = "syn_vga_mon" , ovm_component parent = null) ;
      super.new( name , parent );
    endfunction : new


    /*  Build */
    function  void  build();
      super.build();

      f = $fopen({"./logs/",get_full_name(),".log"},  "w");

      set_report_default_file(f);
      set_report_severity_action(OVM_INFO,  OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_WARNING, OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_ERROR,  OVM_COUNT | OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_FATAL,  OVM_EXIT | OVM_DISPLAY | OVM_LOG);

      ovm_report_info(get_name(),"Start of build ",OVM_LOW);

      Mon2Sb_port = new("Mon2Sb_port", this);

      pkt = new();

      enable  = 1;  //Enabled by default; disable from test case
      num_lines = 0;
      num_frames  = 0;

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction : build


    /*  Run */
    task run();
      int unsigned  hcntr,vcntr;
      PKT_TYPE  hpkt,vpkt;
      pxl_rgb_t hpxl,hpxl_1d;

      ovm_report_info({get_name(),"[run]"},"Start of run ",OVM_LOW);

      @(posedge intf.rst_il);

      if(enable)
      begin
        fork
          begin //Line monitor logic
            forever
            begin
              @(negedge intf.hsync_n);  //wait for start of HSYNC
              hcntr = 0;  //reset counter
              hpkt  = new();
              hpkt.vga_type = VGA_LINE;

              do
              begin //count length of HSYNC
                @(posedge intf.clk_ir);
                hcntr++;
              end
              while(intf.hsync_n  ==  0);

              hpkt.sync = hcntr;

              /*  --------------------  */

              hcntr = 0;
              $cast(hpxl, {intf.r,intf.g,intf.b});
              hpxl_1d = hpxl;

              do
              begin //count length of Back Porch
                @(posedge intf.clk_ir);
                hcntr++;

                hpxl_1d = hpxl;
                $cast(hpxl, {intf.r,intf.g,intf.b});
              end
              while(hpxl  ==  hpxl_1d);

              hpkt.bp = hcntr;

              /*  --------------------  */

              hpkt.pxl_arry = new[LINE_LENGTH];

              //foreach(hpkt.pxl_arry[i]) //get pixels
              for(int i=0; i<hpkt.pxl_arry.size; i++) //get pixels
              begin
                $cast(hpkt.pxl_arry[i], {intf.r,intf.g,intf.b});
                @(posedge intf.clk_ir);
              end

              /*  --------------------  */

              hcntr = 0;  //reset counter

              do
              begin //count length of Front Porch
                @(posedge intf.clk_ir);
                hcntr++;
              end
              while(intf.hsync_n  ==  1);

              hpkt.fp = hcntr;

              /*  --------------------  */

              //Send captured pkt to SB
              ovm_report_info({get_name(),"[run-hmon]"},$psprintf("Sending pkt to SB -\n%s", pkt.sprint()),OVM_LOW);
              Mon2Sb_port.write(pkt);

              num_lines++;
            end
          end

          begin //frame monitor logic
            forever
            begin
              @(negedge intf.vsync_n);  //wait for start of VSYNC
              vcntr = 0;  //reset counter
              vpkt  = new();
              vpkt.vga_type = VGA_FRAME;

              do
              begin //count length of VSYNC
                @(posedge intf.hsync_n);
                vcntr++;
              end
              while(intf.vsync_n  ==  0);

              vpkt.sync = vcntr;

              //Send captured pkt to SB
              ovm_report_info({get_name(),"[run-vmon]"},$psprintf("Sending pkt to SB -\n%s", pkt.sprint()),OVM_LOW);
              Mon2Sb_port.write(pkt);

              num_frames++;
            end

          end
        join
      end
      else
      begin
        ovm_report_info({get_name(),"[run]"},"syn_vga_mon  is disabled",OVM_LOW);
        ovm_report_info({get_name(),"[run]"},"Shutting down .....",OVM_LOW);
      end
    endtask : run


  endclass  : syn_vga_mon

`endif
