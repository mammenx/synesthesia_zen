`ifndef __SYN_VCORTEX_TB_TOP
`define __SYN_VCORTEX_TB_TOP

  /////////////////////////////////////////////////////
  // Importing OVM Packages                          //
  /////////////////////////////////////////////////////

  `include "ovm.svh"
  import ovm_pkg::*;

  `timescale  1ns/100ps

  module syn_vcortex_tb_top();

    parameter LB_DATA_W = 32;
    parameter LB_ADDR_W = 12;
    parameter VGA_RES_W = 4;


    `include  "vcortex_tb.list"


    //Clock Reset signals
    logic   sys_clk_50;
    logic   sys_rst;



    //Interfaces
    syn_clk_rst_sync_intf             cr_intf(sys_clk_50,sys_rst);
    syn_lb_intf#(LB_DATA_W,LB_ADDR_W) lb_intf(sys_clk_50,sys_rst);
    syn_sram_mem_intf                 sram_mem_intf(sys_clk_50,sys_rst);
    syn_vga_intf#(VGA_RES_W)          vga_intf(sys_clk_50,sys_rst);


    /////////////////////////////////////////////////////
    // Clock, Reset Generation                         //
    /////////////////////////////////////////////////////
    initial
    begin
      sys_clk_50    = 1;

      #111;

      forever #10ns sys_clk_50  = ~sys_clk_50;
    end

    initial
    begin
      sys_rst   = 1;

      #123;

      sys_rst   = 0;

      #321;

      sys_rst   = 1;

    end



    /*  DUT */
  syn_vcortex   syn_vcortex_inst
  (
    .cr_intf        (cr_intf.sync),   //Clock Reset Interface

    .lb_intf        (lb_intf.slave),  //DATA_W=32, ADDR_W=12

    .sram_mem_intf  (sram_mem_intf.mp),

    .vga_intf       (vga_intf.mp)

  );



    initial
    begin
      #1;
      run_test();
    end

  endmodule

`endif
