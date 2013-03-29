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
 -- Interface Name    : sram_acc_intf
 -- Author            : mammenx
 -- Function          : This interface encapsulates signals & behavior of
                        the SRAM Access Bus.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

interface sram_acc_intf  #(parameter  P_DATA_W=16, P_ADDR_W=18, P_LATENCY=2) (input logic clk_ir, rst_il);

  localparam  P_BE_W          = P_DATA_W/8; //needs to be a multiple of 8
  localparam  P_GPU_ADDR_W    = P_ADDR_W+1;
  localparam  P_GPU_DATA_W    = P_DATA_W/2;

  //Logic signals
  logic [P_ADDR_W-1:0]  sram_addr;
  logic [P_BE_W-1:0]    sram_be;
  logic                 sram_cs;
  logic                 sram_rd_en;
  logic                 sram_wr_en;
  logic [P_DATA_W-1:0]  sram_wr_data;
  logic [P_DATA_W-1:0]  sram_rd_data;

  logic [P_ADDR_W-1:0]  vga_addr;
  logic                 vga_rd_en;
  logic                 vga_rdy;
  logic                 vga_rd_valid;
  logic [P_DATA_W-1:0]  vga_rd_data;

  logic [P_GPU_ADDR_W-1:0]  gpu_addr;
  logic                     gpu_rd_en;
  logic                     gpu_wr_en;
  logic [P_GPU_DATA_W-1:0]  gpu_wr_data;
  logic                     gpu_rdy;
  logic                     gpu_rd_valid;
  logic [P_GPU_DATA_W-1:0]  gpu_rd_data;

  //Internal registers
  logic [P_LATENCY-1:0]     vga_rd_pipe_f;
  logic [(P_LATENCY*2)-1:0] gpu_rd_pipe_f;
  logic [3:0]               vga_acc_run_cnt_f;
  logic                     acc_vga_n_gpu_f;

  //Modports
  modport sram  (
                  input   sram_addr,
                  input   sram_be,
                  input   sram_cs,
                  input   sram_rd_en,
                  input   sram_wr_en,
                  input   sram_wr_data,
                  output  sram_rd_data
                );

  modport vga   (
                  output  vga_addr,
                  output  vga_rd_en,
                  input   vga_rdy,
                  input   vga_rd_valid,
                  input   vga_rd_data
                );

  modport gpu   (
                  output  gpu_addr,
                  output  gpu_rd_en,
                  output  gpu_wr_en,
                  output  gpu_wr_data,
                  input   gpu_rdy,
                  input   gpu_rd_valid,
                  input   gpu_rd_data
                );


  /*  Internal  Arbitration Logic */
  always@(posedge clk_ir, negedge rst_il)
  begin : vga_acc_run_cnt_logic
    if(~rst_il)
    begin
      vga_acc_run_cnt_f       <=  0;
      acc_vga_n_gpu_f         <=  1;  //default starts with VGA
    end
    else
    begin
      vga_acc_run_cnt_f       <=  vga_acc_run_cnt_f - (~vga_rdy & (|vga_acc_run_cnt_f))
                                                    + (vga_rdy  & ~(&vga_acc_run_cnt_f));

      acc_vga_n_gpu_f         <=  (vga_acc_run_cnt_f  ==  3'd3) ? ~vga_rdy  : acc_vga_n_gpu_f;
    end
  end

  assign  vga_rdy = (acc_vga_n_gpu_f  | (~gpu_rd_en & ~gpu_wr_en))  & vga_rd_en;
  assign  gpu_rdy = (~acc_vga_n_gpu_f | ~vga_rd_en) & (gpu_rd_en  | gpu_wr_en);

  assign  sram_cs = 1'b1;

  always_comb
  begin : sram_mux_logic
    if(vga_rdy)
    begin
      sram_addr     = vga_addr;
      sram_be       = {P_BE_W{1'b1}};
      sram_rd_en    = vga_rd_en;
      sram_wr_en    = 1'b0;
      sram_wr_data  = {P_DATA_W{1'b0}};
    end
    else  //give control to gpu
    begin
      sram_addr     = gpu_addr[P_GPU_ADDR_W-1:1];
      sram_be       = {gpu_addr[0],~gpu_addr[0]};
      sram_rd_en    = gpu_rd_en;
      sram_wr_en    = gpu_wr_en;
      sram_wr_data  = {gpu_wr_data,gpu_wr_data};
    end
  end

  always@(posedge clk_ir, negedge rst_il)
  begin
    if(~rst_il)
    begin
      vga_rd_pipe_f           <=  {P_LATENCY{1'b0}};
      gpu_rd_pipe_f           <=  {(P_LATENCY*2){1'b0}};
    end
    else
    begin
      vga_rd_pipe_f           <=  {vga_rd_pipe_f[P_LATENCY-2:0],(vga_rdy  & vga_rd_en)};
      gpu_rd_pipe_f           <=  {gpu_rd_pipe_f[(P_LATENCY*2)-3:0],{(gpu_rdy & gpu_rd_en),gpu_addr[0]}};
    end
  end

  assign  vga_rd_valid        =   vga_rd_pipe_f[P_LATENCY-1];
  assign  vga_rd_data         =   sram_rd_data;

  assign  gpu_rd_valid        =   gpu_rd_pipe_f[(P_LATENCY*2)-1];
  assign  gpu_rd_data         =   gpu_rd_pipe_f[(P_LATENCY*2)-2]  ? sram_rd_data[P_DATA_W-1:P_GPU_DATA_W]
                                                                  : sram_rd_data[P_GPU_DATA_W-1:0]        ;

endinterface  //  sram_acc_intf
