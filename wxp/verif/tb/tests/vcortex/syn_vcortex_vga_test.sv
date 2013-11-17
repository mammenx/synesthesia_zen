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
 -- Test Name         : syn_vcortex_vga_test
 -- Author            : mammenx
 -- Function          : This test checks if host access to Mulberry bus &
                        Frame Buffer are working.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

import  syn_gpu_pkg::*;

class syn_vcortex_vga_test extends syn_vcortex_base_test;

    `ovm_component_utils(syn_vcortex_vga_test)

    //Sequences
    syn_vga_enable_seq#(super.LB_SEQ_ITEM_T,super.LB_SEQR_T)          vga_en_seq;


    OVM_FILE  f;

    /*  Constructor */
    function new (string name="syn_vcortex_vga_test", ovm_component parent=null);
        super.new (name, parent);
    endfunction : new 


    /*  Build */
    function  void  build();
      super.build();

      f = $fopen({"./logs/",get_full_name(),".log"});

      set_report_default_file(f);
      set_report_severity_action(OVM_INFO,  OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_WARNING, OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_ERROR,  OVM_COUNT | OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_FATAL,  OVM_EXIT | OVM_DISPLAY | OVM_LOG);


      ovm_report_info(get_full_name(),"Start of build",OVM_LOW);

      vga_en_seq          = syn_vga_enable_seq#(super.LB_SEQ_ITEM_T,super.LB_SEQR_T)::type_id::create("vga_en_seq");

      ovm_report_info(get_full_name(),"End of build",OVM_LOW);
    endfunction : build


    /*  Connect */
    function  void  connect();
      super.connect();

      ovm_report_info(get_full_name(),"Start of connect",OVM_LOW);

        this.env.pxlgw_sniffer.enable = 0;
        this.env.sram_agent.mon.enable= 0;

      ovm_report_info(get_full_name(),"End of connect",OVM_LOW);
    endfunction : connect


    /*  End of Elaboration  */
    function void end_of_elaboration();
      super.end_of_elaboration();
    endfunction


    /*  Run */
    virtual task run ();

      ovm_report_info(get_full_name(),"Start of run",OVM_LOW);

      super.env.sprint();

      super.init_fb(PXL_INC);

      #500;

      vga_en_seq.vga_mode = 1;
      vga_en_seq.start(super.env.lb_agent.seqr);

      do
      begin
        @(this.env.vga_agent.mon.num_lines);
        ovm_report_info(get_full_name(),$psprintf("VGA Line:%1d",this.env.vga_agent.mon.num_lines),OVM_LOW);
      end
      while(this.env.vga_agent.mon.num_lines  < 10);

      ovm_report_info(get_name(),"Calling global_stop_request().....",OVM_LOW);
      global_stop_request();

      ovm_report_info(get_full_name(),"End of run",OVM_LOW);
    endtask : run

    //Function to write pixel to a particular position in the frame buffer
    function  void  write_pxl(input pxl_hsi_t pxl,  input int x,y);
      int addr  = (y*640) + x;
      int msb_n_lsb = addr  % 2;
      addr  = addr  >>  1;

      mod_fb(pxl,addr,msb_n_lsb);
    endfunction : write_pxl

    //function to modify the frame buffer contents via back door access
    function  void mod_fb(input pxl_hsi_t pxl, input int addr,msb_n_lsb);
      bit [SRAM_DATA_W-1:0] tmp;

      tmp = super.env.sram_agent.drvr.frm_bffr[addr];

      if(msb_n_lsb) //modify MSB
      begin
        $cast(tmp[SRAM_DATA_W-1:SRAM_DATA_W/2],pxl);
      end
      else  //modify LSB
      begin
        $cast(tmp[(SRAM_DATA_W/2)-1:0],pxl);
      end

      super.env.sram_agent.drvr.frm_bffr[addr]  = tmp;
    endfunction : mod_fb

endclass : syn_vcortex_vga_test
