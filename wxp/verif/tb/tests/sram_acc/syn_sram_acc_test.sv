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
 -- Test Name         : syn_sram_acc_test
 -- Author            : mammenx
 -- Function          : This test stresses the sram_acc_intf.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

class syn_sram_acc_test extends syn_sram_acc_base_test;

    `ovm_component_utils(syn_sram_acc_test)

    //Sequences
    //syn_sram_acc_seq#(super.VGA_AGENT_PKT_T,super.VGA_AGENT_SEQR_T) vga_sram_agent_seq;
    syn_sram_acc_seq#(syn_lb_seq_item#(16,18),syn_sram_acc_seqr#(syn_lb_seq_item#(16,18))) vga_sram_agent_seq;
    //syn_sram_acc_seq#(super.GPU_AGENT_PKT_T,super.GPU_AGENT_SEQR_T) gpu_sram_agent_seq;
    syn_sram_acc_seq#(syn_lb_seq_item#(8,19),syn_sram_acc_seqr#(syn_lb_seq_item#(8,19))) gpu_sram_agent_seq;

    OVM_FILE  f;

    /*  Constructor */
    function new (string name="syn_sram_acc_test", ovm_component parent=null);
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

      //vga_sram_agent_seq = syn_sram_acc_seq#(super.VGA_AGENT_PKT_T,super.VGA_AGENT_SEQR_T)::type_id::create("vga_sram_agent_seq");
      //gpu_sram_agent_seq = syn_sram_acc_seq#(super.GPU_AGENT_PKT_T,super.GPU_AGENT_SEQR_T)::type_id::create("gpu_sram_agent_seq");
      vga_sram_agent_seq = syn_sram_acc_seq#(syn_lb_seq_item#(16,18),syn_sram_acc_seqr#(syn_lb_seq_item#(16,18)))::type_id::create("vga_sram_agent_seq");
      gpu_sram_agent_seq = syn_sram_acc_seq#(syn_lb_seq_item#(8,19),syn_sram_acc_seqr#(syn_lb_seq_item#(8,19)))::type_id::create("gpu_sram_agent_seq");

      ovm_report_info(get_full_name(),"End of build",OVM_LOW);
    endfunction : build


    /*  Connect */
    function  void  connect();
      super.connect();

      ovm_report_info(get_full_name(),"Start of connect",OVM_LOW);

        super.env.vga_sram_agent.drvr.read_only = 1;
        this.vga_sram_agent_seq.read_only = 1;

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

      #100;
      super.init_fb(PXL_INC);

      #500;

      fork
        begin
          vga_sram_agent_seq.start(super.env.vga_sram_agent.seqr);
        end

        begin
          #100;
          gpu_sram_agent_seq.start(super.env.gpu_sram_agent.seqr);
        end
      join_any

      ovm_report_info(get_name(),"Calling global_stop_request().....",OVM_LOW);
      global_stop_request();

      ovm_report_info(get_full_name(),"End of run",OVM_LOW);
    endtask : run


endclass : syn_sram_acc_test
