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
 -- Component Name    : syn_sram_drvr
 -- Author            : mammenx
 -- Function          : This driver maintains the 512KB frame buffer
                        memory and interacts with DUT via the SRAM interface.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_SRAM_DRVR
`define __SYN_SRAM_DRVR


  import  syn_gpu_pkg::*;
  import  syn_image_pkg::*;

  class syn_sram_drvr #(parameter DATA_W  = 16,
                        parameter ADDR_W  = 18,
                        type  PKT_TYPE    = syn_lb_seq_item,
                        type  INTF_TYPE   = virtual syn_sram_mem_intf.TB
                      ) extends ovm_driver  #(PKT_TYPE,PKT_TYPE); //request, response

    INTF_TYPE intf;

    OVM_FILE  f;

    shortint  enable;

    /*  Frame Buffer  */
    bit [DATA_W-1:0]  frm_bffr[];

    /*  Image extension */
    string  img_ext;

    /*  Register with factory */
    `ovm_component_param_utils_begin(syn_sram_drvr#(DATA_W,ADDR_W,PKT_TYPE, INTF_TYPE))
      `ovm_field_int(enable,  OVM_ALL_ON);
      `ovm_field_string(img_ext,  OVM_ALL_ON);
    `ovm_component_utils_end


    /*  Constructor */
    function new( string name = "syn_sram_drvr" , ovm_component parent = null) ;
      super.new( name , parent );

      enable    = 1;  //by default enabled; disable from test case
      //img_ext   = ".raw";
      img_ext   = ".ppm";
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

      //allocate memory to frm_bffr
      frm_bffr  = new[2**ADDR_W];

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction : build


    /*  Run */
    task run();
      /*  Check if the parameters are in sync!  */
      //  if(intf.SRAM_ADDR.size  !=  ADDR_W)
      //     ovm_report_fatal({get_name(),"[run]"},$psprintf("sram_addr_w(%d) does not match ADDR_W(%d) !!!",intf.SRAM_ADDR.size,ADDR_W),OVM_LOW);

      //  if(intf.SRAM_DQ.size !=  DATA_W)
      //     ovm_report_fatal({get_name(),"[run]"},$psprintf("sram_data_w(%d) does not match DATA_W(%d) !!!",intf.SRAM_DQ.size,DATA_W),OVM_LOW);


      ovm_report_info({get_name(),"[run]"},"Start of run ",OVM_LOW);


      if(enable)
      begin
        fork
          begin
            process_seq_item();
          end

          begin
            talk_to_dut();
          end
        join  //join_all
      end
      else
      begin
        ovm_report_info({get_name(),"[run]"},"syn_sram_drvr is disabled",OVM_LOW);
        ovm_report_info({get_name(),"[run]"},"Shutting down .....",OVM_LOW);
      end
    endtask : run

    /*  Taks to accept sequence items & update memory */
    task  process_seq_item();
      PKT_TYPE  pkt = new();
      PKT_TYPE  pkt_rsp;

      forever
      begin
        ovm_report_info({get_name(),"[process_seq_item]"},"Waiting for seq_item",OVM_LOW);
        seq_item_port.get_next_item(pkt);

        ovm_report_info({get_name(),"[process_seq_item]"},$psprintf("Got seq_item - \n%s",pkt.sprint()),OVM_LOW);

        ovm_report_info({get_name(),"[process_seq_item]"},$psprintf("pkt.addr.size = %1d, pkt.data.size = %1d",pkt.addr.size,pkt.data.size),OVM_LOW);
        ovm_report_info({get_name(),"[process_seq_item]"},$psprintf("pkt.addr[0] = %1d, pkt.data[0] = %1d",pkt.addr[0],pkt.data[0]),OVM_LOW);


        if((pkt.lb_xtn  ==  WRITE)  ||  (pkt.lb_xtn ==  BURST_WRITE))
        begin
          //foreach(pkt.addr[i])
          for(int i=0; i<pkt.addr.size; i++)
          begin
            frm_bffr[pkt.addr[i]] = pkt.data[i];
            //ovm_report_info({get_name(),"[process_seq_item]"},$psprintf("Updated frm_bffr[%1d]",pkt.addr[i]),OVM_LOW);
          end

          ovm_report_info({get_name(),"[process_seq_item]"},$psprintf("Updated frm_bffr"),OVM_LOW);
        end
        else  //READ, BURST_READ
        begin
          pkt_rsp = new();
          pkt_rsp.addr  = new[pkt.addr.size];
          pkt_rsp.data  = new[pkt.addr.size];
          pkt_rsp.lb_xtn= pkt.lb_xtn;

          foreach(pkt.addr[i])
          begin
            pkt_rsp.addr[i] = pkt.addr[i];
            pkt_rsp.data[i] = frm_bffr[pkt.addr[i]];
          end

          //Send back response
          pkt_rsp.set_id_info(pkt);
          #1;
          seq_item_port.put_response(pkt_rsp);
        end

        seq_item_port.item_done();
      end
    endtask : process_seq_item


    /*  Task to interact with DUT */
    task  talk_to_dut();
      forever
      begin
        @(intf.SRAM_ADDR, intf.SRAM_LB_N, intf.SRAM_UB_N, intf.SRAM_CE_N, intf.SRAM_OE_N, intf.SRAM_WE_N);

        #2ns;

        if(!intf.SRAM_OE_N  &&  !intf.SRAM_CE_N) //read command
        begin
          intf.tb_dq      = frm_bffr[intf.SRAM_ADDR];  //drive data to bus
          intf.tb_dq_sel  = 1;
          //  ovm_report_info({get_name(),"[talk_to_dut]"},$psprintf("READ - addr : 0x%x\tdata : 0x%x",intf.SRAM_ADDR,mem[intf.SRAM_ADDR]),OVM_LOW);
        end
        else
        begin
          intf.tb_dq_sel  = 0;  //release bus
        end

        if(!intf.SRAM_WE_N  &&  !intf.SRAM_CE_N)  //write command
        begin
          if(~intf.SRAM_LB_N)
          begin
            frm_bffr[intf.SRAM_ADDR][(DATA_W/2)-1:0]  = intf.SRAM_DQ[(DATA_W/2)-1:0];  //sample low data from bus
          end

          if(~intf.SRAM_UB_N)
          begin
            frm_bffr[intf.SRAM_ADDR][DATA_W-1:(DATA_W/2)] = intf.SRAM_DQ[DATA_W-1:(DATA_W/2)]; //sample high data from bus
          end

          //  ovm_report_info({get_name(),"[talk_to_dut]"},$psprintf("WRITE - addr : 0x%x\tmdata : 0x%x\tidata : 0x%x",intf.SRAM_ADDR,mem[intf.SRAM_ADDR],intf.SRAM_DQ),OVM_LOW);
        end
      end
    endtask : talk_to_dut

    /*  Overriding extract function to dump the frame buffer contents as a image file */
    virtual function void extract();
      byte  unsigned  red[],green[],blue[];
      const int num_pxls  = P_CANVAS_W  * P_CANVAS_H;
      pxl_ycbcr_t pxl_ycbcr;
      pxl_rgb_t   pxl_rgb;

      ovm_report_info({get_name(),"[extract]"},"Start of extract ...",OVM_LOW);

      red   = new[num_pxls];
      green = new[num_pxls];
      blue  = new[num_pxls];

      /*  Extract RGB information from frm_bffr */
      for(int i=0; i<num_pxls; i++)
      begin
        pxl_ycbcr = frm_bffr[i/2][((i%2)*(DATA_W/2))  +:  (P_LUM_W+P_CHRM_W+P_CHRM_W)];
        pxl_rgb   = convert_ycbcr2rgb(pxl_ycbcr);
        $cast(red[i],   (pxl_rgb.red * 16));
        $cast(green[i], (pxl_rgb.green * 16));
        $cast(blue[i],  (pxl_rgb.blue * 16));
      end

      if(img_ext  ==  ".ppm")
      begin
        ovm_report_info({get_name(),"[extract]"},"Dumping ppm file ...",OVM_LOW);

        if(!syn_dump_ppm(
                          //{"frm_bffr",$psprintf("_%t_",$time),img_ext},
                          {"frm_bffr",$psprintf("_%1t_",$time),img_ext},
                          P_CANVAS_W,
                          P_CANVAS_H,
                          red,
                          green,
                          blue
                        )
          )
        begin
          ovm_report_fatal({get_name(),"[extract]"},"ppm file dump failed !",OVM_LOW);
        end
      end
      else if(img_ext  ==  ".raw")
      begin
        ovm_report_info({get_name(),"[extract]"},"Dumping raw file ...",OVM_LOW);

        if(!syn_dump_raw(
                          //{"frm_bffr",$psprintf("_%t_",$time),img_ext},
                          {"frm_bffr",$psprintf("_%1t_",$time),img_ext},
                          P_CANVAS_W,
                          P_CANVAS_H,
                          red,
                          green,
                          blue
                        )
          )
        begin
          ovm_report_fatal({get_name(),"[extract]"},"raw file dump failed !",OVM_LOW);
        end
      end
      else
      begin
        ovm_report_fatal({get_name(),"[extract]"},{"Unsupported file extension <",img_ext,">"},OVM_LOW);
      end

    endfunction : extract

  endclass  : syn_sram_drvr

`endif
