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
 -- Module Name       : syn_i2c_master
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This module implements logic for driving I2C
                        transactions.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_i2c_master (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf           cr_intf,      //Clock Reset Interface

  //syn_i2c_intf                    i2c_intf,
  syn_wm8731_intf                 wm8731_intf,

  syn_acortex_lb_bus_intf         lb_intf


  //--------------------- Misc Ports (Logic)  -----------

                );

//----------------------- Global parameters Declarations ------------------
  import  syn_global_pkg::*;

  `include  "syn_acortex_reg_map.sv"

  parameter   P_LB_DATA_W           = P_16B_W;
  parameter   P_LB_ADDR_W           = P_8B_W;

  parameter   P_I2C_ADDR_W          = P_8B_W;
  parameter   P_I2C_DATA_W          = P_16B_W;
  parameter   P_I2C_PRD_CNTR_W      = P_8B_W;
  parameter   P_I2C_CLK_DIV_W       = P_I2C_PRD_CNTR_W;
  localparam  P_I2C_CYCLE_W         = P_8B_W;
  localparam  P_I2C_NUM_DATA_CYCLES = P_I2C_DATA_W  / P_I2C_CYCLE_W;
  localparam  P_I2C_BITSTREAM_W     = P_I2C_ADDR_W  + P_I2C_DATA_W;
  localparam  P_I2C_BIT_CNTR_W      = $clog2(P_I2C_BITSTREAM_W) + 1;

//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------
  logic [P_I2C_ADDR_W-1:0]    i2c_addr_f;
  logic [P_I2C_DATA_W-1:0]    i2c_data_f;
  logic [P_I2C_CLK_DIV_W-1:0] i2c_clk_div_f;

  logic [P_I2C_PRD_CNTR_W-1:0]  i2c_prd_cntr_f;
  logic [P_I2C_BIT_CNTR_W-1:0]  bit_idx_f;
  logic                         nack_detected_f;

  genvar  i;

  logic                       sda_f;
  logic                       release_sda_f;

//----------------------- Internal Wire Declarations ----------------------
  logic                       i2c_start_c;
  logic                       fsm_idle_c;
  logic                       wrap_prd_cntr_c;
  logic                       i2c_prd_by_2_tick_c;
  logic                       i2c_prd_by_4_tick_c;

  logic                       i2c_phase_ovr_c;
  logic                       i2c_data_ovr_c;

  logic [P_I2C_BITSTREAM_W-1:0] i2c_bit_stream_w;
  logic [P_I2C_ADDR_W-1:0]      i2c_addr_rev_w;
  logic [P_I2C_DATA_W-1:0]      i2c_data_rev_w;

//----------------------- Internal Interface Declarations -----------------


//----------------------- FSM Declarations --------------------------------
enum  logic [2:0] {
                    IDLE_S    = 'd0,
                    START_S,
                    ADDR_S,
                    DATA_S,
                    ACK_S,
                    STOP_S
                  }  fsm_pstate, next_state;



//----------------------- Start of Code -----------------------------------

  /*  Local Bus Logic */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : lb_logic
   if(~cr_intf.rst_sync_l)
   begin
     lb_intf.i2cm_wr_valid    <=  0;
     lb_intf.i2cm_rd_valid    <=  0;
     lb_intf.i2cm_rd_data     <=  0;

     i2c_addr_f               <=  0;
     i2c_data_f               <=  0;
     i2c_clk_div_f            <=  {P_I2C_CLK_DIV_W{1'b1}};
   end
   else
   begin
     if(lb_intf.i2cm_wr_en)
     begin
       i2c_addr_f             <=  (lb_intf.i2cm_addr  ==  ACORTEX_I2CM_ADDR_REG_ADDR) ? lb_intf.i2cm_wr_data[P_I2C_ADDR_W-1:0]  : i2c_addr_f;

       i2c_data_f             <=  (lb_intf.i2cm_addr  ==  ACORTEX_I2CM_DATA_REG_ADDR) ? lb_intf.i2cm_wr_data[P_I2C_DATA_W-1:0]  : i2c_data_f;

       i2c_clk_div_f          <=  (lb_intf.i2cm_addr  ==  ACORTEX_I2CM_CLK_DIV_REG_ADDR)  ? lb_intf.i2cm_wr_data[P_I2C_CLK_DIV_W-1:0] : i2c_clk_div_f;
     end

     lb_intf.i2cm_wr_valid    <=  lb_intf.i2cm_wr_en;


     case(lb_intf.i2cm_addr)

       ACORTEX_I2CM_STATUS_REG_ADDR   : lb_intf.i2cm_rd_data  <=  {{P_LB_DATA_W-2{1'b0}},nack_detected_f,~fsm_idle_c};

       ACORTEX_I2CM_ADDR_REG_ADDR     : lb_intf.i2cm_rd_data  <=  {{P_LB_DATA_W-P_I2C_ADDR_W{1'b0}},  i2c_addr_f};

       ACORTEX_I2CM_DATA_REG_ADDR     : lb_intf.i2cm_rd_data  <=  {{P_LB_DATA_W-P_I2C_DATA_W{1'b0}},  i2c_data_f};

       ACORTEX_I2CM_CLK_DIV_REG_ADDR  : lb_intf.i2cm_rd_data  <=  {{P_LB_DATA_W-P_I2C_CLK_DIV_W{1'b0}},  i2c_clk_div_f};

       default  : lb_intf.i2cm_rd_data  <=  'hdead;
     endcase

     lb_intf.i2cm_rd_valid    <=  lb_intf.i2cm_rd_en;
   end
 end

 //Logic for triggering I2C xtn, on write to I2C_DRIVER_STATUS_REG
 assign  i2c_start_c  = (lb_intf.i2cm_addr  ==  ACORTEX_I2CM_STATUS_REG_ADDR) ? lb_intf.i2cm_wr_en  : 1'b0;
 

 /* FSM Sequential Logic  */
 always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
 begin : fsm_seq_logic
   if(~cr_intf.rst_sync_l)
   begin
     fsm_pstate               <=  IDLE_S;
   end
   else
   begin
     fsm_pstate               <=  next_state;
   end
 end

 /* FSM Next State Logic  */
 always_comb
 begin  : fsm_next_state_logic
   next_state = fsm_pstate;

   case(fsm_pstate)

     IDLE_S :
     begin
       if(i2c_start_c)
       begin
         next_state           = START_S;
       end
     end

     START_S  :
     begin
       if(wrap_prd_cntr_c)
       begin
         next_state           = ADDR_S;
       end
     end

     ADDR_S :
     begin
       if(i2c_phase_ovr_c)
       begin
         next_state           = ACK_S;
       end
     end

     DATA_S :
     begin
       if(i2c_phase_ovr_c)
       begin
         next_state           = ACK_S;
       end
     end

     ACK_S  :
     begin
       if(wrap_prd_cntr_c)
       begin
         if(nack_detected_f | i2c_data_ovr_c)
         begin
           next_state         = STOP_S;
         end
         else
         begin
           next_state         = DATA_S;
         end
       end
     end

     STOP_S :
     begin
       if(wrap_prd_cntr_c)
       begin
         next_state           = IDLE_S;
       end
     end

   endcase
 end

 //Check if the FSM is in IDLE_S
 assign fsm_idle_c  = (fsm_pstate ==  IDLE_S) ? 1'b1  : 1'b0;

 /*
   * I2C period counter logic
   * This counter will derive the required I2C period
   *
   * Bit counter is used indexing the addr/data bits
   *
   * Flag to hold nack detected status
 */
 always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
 begin : i2c_period_cntr_logic
   if(~cr_intf.rst_sync_l)
   begin
     i2c_prd_cntr_f           <=  0;
     bit_idx_f                <=  0;

     nack_detected_f          <=  0;
   end
   else
   begin
     i2c_prd_cntr_f           <=  (fsm_idle_c | wrap_prd_cntr_c)  ? {P_I2C_PRD_CNTR_W{1'b0}}
                                                                 : i2c_prd_cntr_f  + 1'b1;

     if((fsm_pstate == ADDR_S) | (fsm_pstate ==  DATA_S))
     begin
       bit_idx_f              <=  bit_idx_f + wrap_prd_cntr_c;
     end
     else
     begin
       bit_idx_f              <=  4'd0;
     end

     //Slave must pull down SDO pin low during ack phase for
     //correct ack, else nack
     nack_detected_f          <=  nack_detected_f ? ~i2c_start_c  //clear NACK flag
                                                  : (fsm_pstate ==  ACK_S)  & wm8731_intf.scl  & i2c_prd_by_2_tick_c & wm8731_intf.sda;
   end
 end

 //Counter wrap logic
 assign wrap_prd_cntr_c = (i2c_prd_cntr_f ==  i2c_clk_div_f)  ? 1'b1  : 1'b0;

 //Generate a tick 4 times every I2C cycle
 assign  i2c_prd_by_4_tick_c = (i2c_prd_cntr_f[P_I2C_PRD_CNTR_W-3:0] ==  i2c_clk_div_f[P_I2C_CLK_DIV_W-1:2])  ? 1'b1  : 1'b0;

 //Generate a tick 2 times every I2C cycle
 assign  i2c_prd_by_2_tick_c = (i2c_prd_cntr_f[P_I2C_PRD_CNTR_W-2:0] ==  i2c_clk_div_f[P_I2C_CLK_DIV_W-1:1])  ? 1'b1  : 1'b0;
 
 //Check if a phase is over
 assign  i2c_phase_ovr_c  = (bit_idx_f[$clog2(P_I2C_CYCLE_W-1)-1:0] ==  P_I2C_CYCLE_W-1)  ? wrap_prd_cntr_c : 1'b0;

 //Check if all bits have been sent
 assign  i2c_data_ovr_c   = (bit_idx_f  ==  (P_I2C_ADDR_W + P_I2C_DATA_W))  ? 1'b1  : 1'b0;


 //Bit reverse the address & data bits
 generate
   for(i=0;i<P_I2C_ADDR_W;i=i+1)
   begin : addr_rev
     assign  i2c_addr_rev_w[i]  = i2c_addr_f[P_I2C_ADDR_W-1-i];
   end

   for(i=0;i<P_I2C_DATA_W;i=i+1)
   begin : data_rev
     assign  i2c_data_rev_w[i]  = i2c_data_f[P_I2C_DATA_W-1-i];
   end
 endgenerate

 //Collect the sequence of bits to be transmitted
 assign i2c_bit_stream_w  = {i2c_data_rev_w,i2c_addr_rev_w};

  /*  SCL, SDA Logic  */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : sda_scl_logic
    if(~cr_intf.rst_sync_l)
    begin
      wm8731_intf.scl         <=  1'b1;
      sda_f                   <=  1'b1;
      release_sda_f           <=  1'b0;
    end
    else
    begin
      case(fsm_pstate)

        IDLE_S  :
        begin
          wm8731_intf.scl     <=  1'b1;
          sda_f               <=  1'b1;
          release_sda_f       <=  1'b0;
        end

        START_S :
        begin
          sda_f               <=  1'b0;
          wm8731_intf.scl     <=  wm8731_intf.scl  & ~i2c_prd_by_2_tick_c;
          release_sda_f       <=  1'b0;
        end

        ADDR_S  :
        begin
          sda_f               <=  i2c_bit_stream_w[bit_idx_f];
          wm8731_intf.scl     <=  wm8731_intf.scl ? i2c_prd_by_2_tick_c | ~i2c_prd_by_4_tick_c
                                                  : i2c_prd_by_4_tick_c;
          release_sda_f       <=  i2c_phase_ovr_c;
        end

        DATA_S  :
        begin
          sda_f               <=  i2c_bit_stream_w[bit_idx_f];
          wm8731_intf.scl     <=  wm8731_intf.scl ? i2c_prd_by_2_tick_c | ~i2c_prd_by_4_tick_c
                                                  : i2c_prd_by_4_tick_c;
          release_sda_f       <=  i2c_phase_ovr_c;
        end

        ACK_S :
        begin
          sda_f               <=  i2c_bit_stream_w[bit_idx_f];
          wm8731_intf.scl     <=  wm8731_intf.scl ? i2c_prd_by_2_tick_c | ~i2c_prd_by_4_tick_c
                                                  : i2c_prd_by_4_tick_c;
          release_sda_f       <=  ~i2c_phase_ovr_c;
        end

        STOP_S  :
        begin
          sda_f               <=  sda_f  | i2c_prd_by_2_tick_c;
          wm8731_intf.scl     <=  1'b1;
          release_sda_f       <=  1'b0;
        end

      endcase
    end
  end

  //Tristate the I2C data line
  assign  wm8731_intf.sda = release_sda_f ? 1'bz  : sda_f;

endmodule // syn_i2c_master
