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
 -- Module Name       : syn_clk_mux
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This block selects which clock signal to feed to
                        WM8731 codec.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_clk_mux (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf           cr_intf,      //Clock Reset Interface

  syn_acortex_lb_bus_intf         lb_intf,

  syn_wm8731_intf                 wm8731_intf,

  //--------------------- Misc Ports (Logic)  -----------
  clk_vec_ir    //Input Clock lines

                );

//----------------------- Global parameters Declarations ------------------
  import  syn_global_pkg::*;

  `include  "syn_acortex_reg_map.sv"

  parameter   P_LB_DATA_W           = P_16B_W;
  parameter   P_LB_ADDR_W           = P_8B_W;

  parameter   P_NUM_CLOCKS          = 4;
  localparam  P_CLK_SEL_W           = $clog2(P_NUM_CLOCKS);

//----------------------- Input Declarations ------------------------------
  input   logic [P_NUM_CLOCKS-1:0]  clk_vec_ir;

//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------
  logic                       clk_mux_en_f;
  logic [P_CLK_SEL_W-1:0]     clk_sel_f;

//----------------------- Internal Wire Declarations ----------------------
  logic [P_NUM_CLOCKS-1:0]    clk_en_vec_c;
  logic [P_NUM_CLOCKS-1:0]    clk_en_vec_sync_w;
  logic [P_NUM_CLOCKS-1:0]    xeno_hot_chk_vec_c;
  logic [P_NUM_CLOCKS-1:0]    clk_gate_vec_c;

  genvar  i;

//----------------------- Internal Interface Declarations -----------------


//----------------------- FSM Declarations --------------------------------



//----------------------- Start of Code -----------------------------------

  /*  Local Bus Logic */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : lb_logic
    if(~cr_intf.rst_sync_l)
    begin
      lb_intf.cmux_wr_valid   <=  0;
      lb_intf.cmux_rd_valid   <=  0;
      lb_intf.cmux_rd_data    <=  0;

      clk_mux_en_f            <=  0;
      clk_sel_f               <=  0;
    end
    else
    begin
      if(lb_intf.cmux_wr_en)
      begin
        clk_sel_f             <=  (lb_intf.cmux_addr  ==  ACORTEX_CMUX_CLK_SEL_REG_ADDR)  ? lb_intf.cmux_wr_data[P_CLK_SEL_W-1:0]
                                                                                           : clk_sel_f;

        clk_mux_en_f          <=  (lb_intf.cmux_addr  ==  ACORTEX_CMUX_CLK_SEL_REG_ADDR)  ? lb_intf.cmux_wr_data[P_LB_DATA_W-1]
                                                                                          : clk_mux_en_f;
      end

      lb_intf.cmux_wr_valid   <=  lb_intf.cmux_wr_en;


      case(lb_intf.cmux_addr)

        ACORTEX_CMUX_CLK_SEL_REG_ADDR : lb_intf.cmux_rd_data  <=  {{P_LB_DATA_W-P_CLK_SEL_W{1'b0}},  clk_sel_f};

        default  : lb_intf.cmux_rd_data <=  'hdead;
      endcase

      lb_intf.cmux_rd_valid   <=  lb_intf.cmux_rd_en;
    end
  end

  /* Generate one hot signal based on clk select */
  always_comb
  begin  : clk_en_vec_logic
    clk_en_vec_c  = {P_NUM_CLOCKS{1'b0}};

    clk_en_vec_c[clk_sel_f] = clk_mux_en_f;
  end

  /*
  * Synchronize enable signals to respective clocks
  */
  generate
    for(i=0;  i<P_NUM_CLOCKS;  i=i+1)
    begin : clk_sync_xeno
      dd_sync dd_sync_clk_inst(.clk_ir    (clk_vec_ir[i]),
                               .rst_il    (cr_intf.rst_sync_l),
                               .signal_id (clk_en_vec_c[i]),
                               .signal_od (clk_en_vec_sync_w[i])
                             );

      //Check if any of the other signals are still high!
      if(i==0)
      begin
        assign  xeno_hot_chk_vec_c[i] = |(clk_en_vec_sync_w[P_NO_CLOCKS-1:i+1]);
      end
      else if(i==P_NUM_CLOCKS-1)
      begin
        assign  xeno_hot_chk_vec_c[i] = |(clk_en_vec_sync_w[i-1:0]);
      end
      else
      begin
        assign  xeno_hot_chk_vec_c[i] = |({clk_en_vec_sync_w[P_NO_CLOCKS-1:i+1],  clk_en_vec_sync_w[i-1:0]});
      end
    end
  endgenerate

  //Gate the clocks with synced masks
  assign  clk_gate_vec_c      = clk_vec_ir  & clk_en_vec_sync_w & ~xeno_hot_chk_vec_c;

  assign  wm8731_intf.mclk  = |(clk_gate_vec_c);

endmodule // syn_clk_mux
