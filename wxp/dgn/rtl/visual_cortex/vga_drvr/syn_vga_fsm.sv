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
 -- Module Name       : syn_vga_fsm
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This module contains the main fsm for generating
                        VGA signals & timing.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_vga_fsm (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf       cr_intf,      //Clock Reset Interface

  ff_intf                     lbffr_intf,   //DATA_W=8, FWFT

  syn_vga_intf                vga_intf,

  syn_vga_drvr_lb_intf        lb_intf

  //--------------------- Misc Ports (Logic)  -----------

                );

//----------------------- Global parameters Declarations ------------------
  import  syn_global_pkg::*;
  import  syn_gpu_pkg::*;

  parameter P_RAM_ACC_DELAY       = 2;
  localparam  P_PST_W             = P_RAM_ACC_DELAY + 1;

  //VGA Timing parameters
  //Taken from [http://tinyvga.com/vga-timing/640x480@60Hz]
  parameter P_VGA_HVALID_W        = 640;
  parameter P_VGA_HFP_W           = 16;
  parameter P_VGA_HSYNC_W         = 96;
  parameter P_VGA_HBP_W           = 48;
  localparam  P_VGA_HTOTAL_W      = P_VGA_HVALID_W  + P_VGA_HFP_W + P_VGA_HSYNC_W + P_VGA_HBP_W;
  localparam  P_VGA_HCNTR_W       = $clog2(P_VGA_HTOTAL_W);

  parameter P_VGA_VVALID_W        = 480;
  parameter P_VGA_VFP_W           = 10;
  parameter P_VGA_VSYNC_W         = 2;
  parameter P_VGA_VBP_W           = 33;
  localparam  P_VGA_VTOTAL_W      = P_VGA_VVALID_W  + P_VGA_VFP_W + P_VGA_VSYNC_W + P_VGA_VBP_W;
  localparam  P_VGA_VCNTR_W       = $clog2(P_VGA_VTOTAL_W);

//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------
  logic                       vga_tck_gen_f;
  logic [P_VGA_HCNTR_W-1:0]   hcntr_f;
  logic [P_VGA_VCNTR_W-1:0]   vcntr_f;

  logic [P_PST_W-1:0]         pst_f;

  logic [P_8B_W-1:0]          ycbcr2rgb_ram_raddr_f;

  logic [P_RAM_ACC_DELAY:0]   hsync_del_f;
  logic [P_RAM_ACC_DELAY:0]   vsync_del_f;

//----------------------- Internal Wire Declarations ----------------------
  logic                       hcntr_en_c;
  logic                       hcntr_wrap_c;
  logic                       hfp_ovr_c;
  logic                       hsync_ovr_c;
  logic                       hbp_ovr_c;

  logic                       vcntr_en_c;
  logic                       vcntr_wrap_c;
  logic                       vfp_ovr_c;
  logic                       vsync_ovr_c;
  logic                       vbp_ovr_c;

  logic                       valid_pxl_range_c;

  logic [P_16B_W-1:0]         ycbcr2rgb_ram_rd_data_w;

//----------------------- FSM Declarations --------------------------------
typedef enum  logic [3:0] {IDLE_S,  FP_S, SYNC_S, BP_S, VALID_S}  vga_fsm_t;
vga_fsm_t   hfsm_pstate,  hfsm_nstate;
vga_fsm_t   vfsm_pstate,  vfsm_nstate;



//----------------------- Start of Code -----------------------------------

  /*  FSM Sequential logic  */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : fsm_seq_logic
    if(~cr_intf.rst_sync_l)
    begin
      hfsm_pstate             <=  IDLE_S;
      vfsm_pstate             <=  IDLE_S;
    end
    else
    begin
      hfsm_pstate             <=  hfsm_nstate;
      vfsm_pstate             <=  vfsm_nstate;
    end
  end


  /*  HFSM combinational logic  */
  always_comb
  begin : hfsm_comb_logic
    if(~lb_intf.vga_drvr_en)
    begin
      hfsm_nstate             = IDLE_S;
    end
    else
    begin
      hfsm_nstate             = hfsm_pstate;

      unique  case(hfsm_pstate)

        IDLE_S  :
        begin
          hfsm_nstate         = FP_S;
        end

        FP_S  :
        begin
          if(hfp_ovr_c)
          begin
            hfsm_nstate       = SYNC_S;
          end
        end

        SYNC_S  :
        begin
          if(hsync_ovr_c)
          begin
            hfsm_nstate       = BP_S;
          end
        end

        BP_S  :
        begin
          if(hbp_ovr_c)
          begin
            hfsm_nstate       = VALID_S;
          end
        end

        VALID_S :
        begin
          if(hcntr_wrap_c)
          begin
            hfsm_nstate       = FP_S;
          end
        end

      endcase
    end
  end

  /*  VFSM combinational logic  */
  always_comb
  begin : vfsm_comb_logic
    if(~lb_intf.vga_drvr_en)
    begin
      vfsm_nstate             = IDLE_S;
    end
    else
    begin
      vfsm_nstate             = vfsm_pstate;

      unique  case(vfsm_pstate)

        IDLE_S  :
        begin
          vfsm_nstate         = FP_S;
        end

        FP_S  :
        begin
          if(vfp_ovr_c)
          begin
            vfsm_nstate       = SYNC_S;
          end
        end

        SYNC_S  :
        begin
          if(vsync_ovr_c)
          begin
            vfsm_nstate       = BP_S;
          end
        end

        BP_S  :
        begin
          if(vbp_ovr_c)
          begin
            vfsm_nstate       = VALID_S;
          end
        end

        VALID_S :
        begin
          if(vcntr_wrap_c)
          begin
            vfsm_nstate       = FP_S;
          end
        end

      endcase
    end
  end


  //Counter enable logic
  assign  hcntr_en_c          =   (hfsm_pstate  ==  IDLE_S) ? 1'b0  : 1'b1;
  assign  vcntr_en_c          =   (vfsm_pstate  ==  IDLE_S) ? 1'b0  : 1'b1;

  //Check when to wrap counters
  assign  hcntr_wrap_c        =   (hcntr_f  ==  P_VGA_HTOTAL_W-1) ? vga_tck_gen_f : 1'b0;
  assign  vcntr_wrap_c        =   (vcntr_f  ==  P_VGA_VTOTAL_W-1) ? hcntr_wrap_c  : 1'b0;

  //Check if FP is done
  assign  hfp_ovr_c           =   (hcntr_f  ==  P_VGA_HFP_W-1)    ? vga_tck_gen_f : 1'b0;
  assign  vfp_ovr_c           =   (vcntr_f  ==  P_VGA_VFP_W-1)    ? hcntr_wrap_c  : 1'b0;

  //Check if SYNC is done
  assign  hsync_ovr_c         =   (hcntr_f  ==  P_VGA_HFP_W+P_VGA_HSYNC_W-1)  ? vga_tck_gen_f : 1'b0;
  assign  vsync_ovr_c         =   (vcntr_f  ==  P_VGA_VFP_W+P_VGA_VSYNC_W-1)  ? hcntr_wrap_c  : 1'b0;

  //Check if BP is done
  assign  hbp_ovr_c           =   (hcntr_f  ==  P_VGA_HFP_W+P_VGA_HSYNC_W+P_VGA_HBP_W-1)  ? vga_tck_gen_f : 1'b0;
  assign  vbp_ovr_c           =   (vcntr_f  ==  P_VGA_VFP_W+P_VGA_VSYNC_W+P_VGA_VBP_W-1)  ? hcntr_wrap_c  : 1'b0;

  /*  Generate VGA ticks @25MHz
    * HCNTR, VCNTR Logic
  */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : vga_tck_cntr_logic
    if(~cr_intf.rst_sync_l)
    begin
      vga_tck_gen_f           <=  1'b0;
      hcntr_f                 <=  0;
      vcntr_f                 <=  0;
    end
    else
    begin
      vga_tck_gen_f           <=  ~vga_tck_gen_f;

      if(hcntr_wrap_c)
      begin
        hcntr_f               <=  0;
      end
      else if(hcntr_en_c)
      begin
        hcntr_f               <=  hcntr_f + vga_tck_gen_f;
      end

      if(vcntr_wrap_c)
      begin
        vcntr_f               <=  0;
      end
      else if(vcntr_en_c)
      begin
        vcntr_f               <=  vcntr_f + hcntr_wrap_c;
      end
    end
  end

  //Check if the fsm is in a state of valid range
  assign  valid_pxl_range_c   =   (hfsm_pstate  ==  VALID_S)  & (vfsm_pstate  ==  VALID_S);


  /*  LBFFR Interface logic */
  assign  lbffr_intf.ff_rd_en =   ~lbffr_intf.ff_empty  & vga_tck_gen_f & valid_pxl_range_c;


  /*  Internal pipeline logic */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : vga_pipe_logic
    if(~cr_intf.rst_sync_l)
    begin
      ycbcr2rgb_ram_raddr_f   <=  0;
      pst_f                   <=  0;
      hsync_del_f             <=  0;
      vsync_del_f             <=  0;

      vga_intf.r              <=  0;
      vga_intf.g              <=  0;
      vga_intf.b              <=  0;
      vga_intf.hsync_n        <=  1;
      vga_intf.vsync_n        <=  1;
    end
    else
    begin
      ycbcr2rgb_ram_raddr_f   <=  lbffr_intf.ff_rd_en ? lbffr_intf.ff_rd_data : ycbcr2rgb_ram_raddr_f;

      pst_f                   <=  {pst_f[P_PST_W-2:0],lbffr_intf.ff_rd_en};

      hsync_del_f             <=  {hsync_del_f[P_RAM_ACC_DELAY-1:0],  (hfsm_pstate  ==  SYNC_S)};
      vga_intf.hsync_n        <=  ~hsync_del_f[P_RAM_ACC_DELAY];

      vsync_del_f             <=  {vsync_del_f[P_RAM_ACC_DELAY-1:0],  (vfsm_pstate  ==  SYNC_S)};
      vga_intf.vsync_n        <=  ~vsync_del_f[P_RAM_ACC_DELAY];

      if(pst_f[P_RAM_ACC_DELAY])
      begin
        vga_intf.r            <=  ycbcr2rgb_ram_rd_data_w[11:8];
        vga_intf.g            <=  ycbcr2rgb_ram_rd_data_w[7:4];
        vga_intf.b            <=  ycbcr2rgb_ram_rd_data_w[3:0];
      end
    end
  end

  /*  Instantiation of YCBCR2RGB RAM  */
  ram_1xM4K_16bW_dualport   ycbcr2rgb_ram_inst
  (
    .address_a              (ycbcr2rgb_ram_raddr_f),
    .address_b              ('d0),
    .clock                  (cr_intf.clk_ir),
    .data_a                 (8'd0),
    .data_b                 ('d0),
    .wren_a                 (1'b0),
    .wren_b                 ('d0),
    .q_a                    (ycbcr2rgb_ram_rd_data_w),
    .q_b                    ()
  );

endmodule // syn_vga_fsm
