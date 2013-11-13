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
 -- Project Code      : synesthesia_zen
 -- Module Name       : syn_zen_fpga_top
 -- Author            : mammenx
 -- Associated modules:
 -- Function          : This is the FPGA top module for Synesthesia Zen.
                        Both Limbus(NIIOS) & Cortex sub-systems are
                        instantiated here.
 --------------------------------------------------------------------------
*/


`timescale 1ns / 10ps


module syn_zen_fpga_top
   (
     /*  Clocks  */
     CLOCK_50,               //50MHz clock
     EXT_CLOCK,              //External clock
     CLOCK_27,               //27MHz clock
     CLOCK_24,               //24MHz clock

     /*  TOGGLE SWITCH    */
     SW,                     //Toggle Switch

     /*  SDRAM            */
     DRAM_DQ,                //SDRAM Data bus 16 Bits
     DRAM_ADDR,              //SDRAM Address bus 12 Bits
     DRAM_LDQM,              //SDRAM Low-byte Data Mask 
     DRAM_UDQM,              //SDRAM High-byte Data Mask
     DRAM_WE_N,              //SDRAM Write Enable
     DRAM_CAS_N,             //SDRAM Column Address Strobe
     DRAM_RAS_N,             //SDRAM Row Address Strobe
     DRAM_CS_N,              //SDRAM Chip Select
     DRAM_BA_0,              //SDRAM Bank Address 0
     DRAM_BA_1,              //SDRAM Bank Address 0
     DRAM_CLK,               //SDRAM Clock
     DRAM_CKE,               //SDRAM Clock Enable

     /*  7 SEGMENT DISPLAY */
     HEX0,                   // Seven Segment Digit 0
     HEX1,                   // Seven Segment Digit 1
     HEX2,                   // Seven Segment Digit 2
     HEX3,                   // Seven Segment Digit 3

     /*  PUSH BUTTON SWITCH*/
     KEY,                    // Pushbutton[3:0]

     /*      LEDs    */
     LEDR,                   // LED Red[9:0]
     LEDG,                   // LED Green[7:0]

     /*      RS232   */
     UART_TXD,               // RS232 UART Transmitter
     UART_RXD,               // RS232 UART Receiver

     /*      SRAM    */
     SRAM_DQ,                // SRAM Data bus 16 Bits
     SRAM_ADDR,              // SRAM Address bus 18 Bits
     SRAM_UB_N,              // SRAM High-byte Data Mask 
     SRAM_LB_N,              // SRAM Low-byte Data Mask 
     SRAM_WE_N,              // SRAM Write Enable
     SRAM_CE_N,              // SRAM Chip Enable
     SRAM_OE_N,              // SRAM Output Enable

     /*      VGA     */
     VGA_HS,                 // VGA H_SYNC
     VGA_VS,                 // VGA V_SYNC
     VGA_R,                  // VGA Red[3:0]
     VGA_G,                  // VGA Green[3:0]
     VGA_B,                  // VGA Blue[3:0]

     /*  AUDIO CODEC */
     I2C_SCLK,               // I2C Clock
     I2C_SDAT,               // I2C Data
     AUD_ADCLRCK,            // Audio CODEC ADC LR Clock
     AUD_ADCDAT,             // Audio CODEC ADC Data
     AUD_DACLRCK,            // Audio CODEC DAC LR Clock
     AUD_DACDAT,             // Audio CODEC DAC Data
     AUD_BCLK,               // Audio CODEC Bit-Stream Clock
     AUD_XCK,                // Audio CODEC Chip Clock

     /*   SDCARD     */
     SD_DAT,                 // SD Card Data
     SD_DAT3,                // SD Card Data 3
     SD_CMD,                 // SD Card Command Signal
     SD_CLK,                 // SD Card Clock

     /* USB JTAG UART  */
     TDI,                    // CPLD -> FPGA (data in)
     TCK,                    // CPLD -> FPGA (clk)
     TCS,                    // CPLD -> FPGA (CS)
     TDO                     // FPGA -> CPLD (data out)

   );

//----------------------- Global parameters Declarations ------------------

  import  syn_global_pkg::*;

  parameter   P_CORTEX_LB_DWIDTH  = 32;
  parameter   P_CORTEX_LB_AWIDTH  = 16;
  parameter   P_FFT_CACHE_LB_DWIDTH  = 32;
  parameter   P_FFT_CACHE_LB_AWIDTH  = 12;
  parameter   P_CORTEX_NUM_CLKS   = 3;
  parameter   P_VGA_COLOR_W       = 4;

//----------------------- Input Declarations ------------------------------
   input                       CLOCK_50;
   input                       EXT_CLOCK;
   input   [1:0]               CLOCK_27;
   input   [1:0]               CLOCK_24;

   input   [9:0]               SW;

   input   [3:0]               KEY;

   input                       UART_RXD;

   input                       AUD_ADCDAT;

   input                       SD_DAT;
   input                       TDI;
   input                       TCK;
   input                       TCS;


//----------------------- Inout Declarations ------------------------------
   inout   [15:0]              DRAM_DQ;

   inout   [15:0]              SRAM_DQ;

   inout                       I2C_SDAT;
   inout                       AUD_BCLK;


//----------------------- Output Declarations -----------------------------
   output  [11:0]              DRAM_ADDR;
   output                      DRAM_LDQM;
   output                      DRAM_UDQM;
   output                      DRAM_WE_N;
   output                      DRAM_CAS_N;
   output                      DRAM_RAS_N;
   output                      DRAM_CS_N;
   output                      DRAM_BA_0;
   output                      DRAM_BA_1;
   output                      DRAM_CLK;
   output                      DRAM_CKE;

   output  [6:0]               HEX0;
   output  [6:0]               HEX1;
   output  [6:0]               HEX2;
   output  [6:0]               HEX3;

   output  [9:0]               LEDR;

   output  [7:0]               LEDG;

   output                      UART_TXD;

   output  [17:0]              SRAM_ADDR;
   output                      SRAM_UB_N;
   output                      SRAM_LB_N;
   output                      SRAM_WE_N;
   output                      SRAM_CE_N;
   output                      SRAM_OE_N;

   output                      VGA_HS;
   output                      VGA_VS;
   output  [3:0]               VGA_R;
   output  [3:0]               VGA_G;
   output  [3:0]               VGA_B;

   output                      I2C_SCLK;
   output                      AUD_ADCLRCK;
   output                      AUD_DACLRCK;
   output                      AUD_DACDAT;
   output                      AUD_XCK;

   output                      SD_CLK;
   output                      SD_DAT3;
   output                      SD_CMD;

   output                      TDO;


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------


//----------------------- Internal Wire Declarations ----------------------
  logic                       sys_clk_50MHz_w;
  logic                       sys_clk_100MHz_w;
  logic                       sys_rst_lw;

  logic                       aud_mclk_11MHz_w;
  logic                       aud_mclk_12MHz_w;
  logic                       aud_mclk_18MHz_w;

  logic                       cortex_clk_w;
  logic                       fft_cache_clk_w;
  logic                       cortex_rst_l_w;
  logic                       cortex_rst_w;
  logic                       fft_cache_rst_l_w;
  logic                       fft_cache_rst_w;
  logic [P_CORTEX_NUM_CLKS-1:0] cortex_clk_vec_w;

  logic [P_CORTEX_LB_AWIDTH+1:0]    cortex_mm_slv_addr_w;
  logic [P_FFT_CACHE_LB_AWIDTH+1:0] fft_cache_mm_slv_addr_w;

//----------------------- Internal Interfaces Declarations ----------------
  syn_clk_rst_sync_intf       cortex_cr_intf(cortex_clk_w,cortex_rst_l_w);
  syn_clk_rst_sync_intf       fft_cache_cr_intf(fft_cache_clk_w,fft_cache_rst_l_w);

  syn_lb_intf#(P_CORTEX_LB_DWIDTH,P_CORTEX_LB_AWIDTH)       cortex_lb_intf(cortex_clk_w,cortex_rst_l_w);
  syn_lb_intf#(P_FFT_CACHE_LB_DWIDTH,P_FFT_CACHE_LB_AWIDTH) fft_cache_lb_intf(fft_cache_clk_w,fft_cache_rst_l_w);

  syn_wm8731_intf             wm8731_intf(sys_rst_lw);

  syn_clk_vec_intf#(P_CORTEX_NUM_CLKS)  clk_vec_intf(cortex_clk_vec_w);

  syn_sram_mem_intf           sram_mem_intf(cortex_clk_w, sys_rst_lw);

  syn_vga_intf#(P_VGA_COLOR_W)  vga_intf(cortex_clk_w,sys_rst_lw);

//----------------------- Start of Code -----------------------------------

  /*  PLLs  */
  syn_sys_pll     syn_sys_pll_inst
  (
    .areset       (~KEY[0]),  //key[0] is active low reset
    .inclk0       (CLOCK_50),
    .c0           (sys_clk_50MHz_w),
    .c1           (sys_clk_100MHz_w),
    .c2           (DRAM_CLK),  //SDRAM clock delayed by -3ns
    .locked       (sys_rst_lw)    //System reset
  );

  assign  cortex_clk_w    = sys_clk_50MHz_w;
  assign  fft_cache_clk_w = sys_clk_100MHz_w;


  mclk_pll        mclk_pll_inst
  (
    .areset       (~KEY[0]),
    .inclk0       (CLOCK_24[0]),
    .c0           (aud_mclk_11MHz_w),
    .c1           (aud_mclk_12MHz_w),
    .c2           (aud_mclk_18MHz_w)
  );

  assign  cortex_clk_vec_w  = {aud_mclk_11MHz_w,aud_mclk_12MHz_w,aud_mclk_18MHz_w};


  /*  Instantiating Limbus(NIIOS) */
  limbus  limbus_inst
  (
    .clk_100_clk                        (sys_clk_100MHz_w),
    .reset_clk_100_reset_n              (sys_rst_lw),

    .clk_50_clk                         (sys_clk_50MHz_w),
    .reset_clk_50_reset_n               (sys_rst_lw),

    .sdram_addr                         (DRAM_ADDR),
    .sdram_ba                           ({DRAM_BA_1,DRAM_BA_0}),
    .sdram_cas_n                        (DRAM_CAS_N),
    .sdram_cke                          (DRAM_CKE),
    .sdram_cs_n                         (DRAM_CS_N),
    .sdram_dq                           (DRAM_DQ),
    .sdram_dqm                          ({DRAM_UDQM,DRAM_LDQM}),
    .sdram_ras_n                        (DRAM_RAS_N),
    .sdram_we_n                         (DRAM_WE_N),

    .cortex_mm_slave_address            (cortex_mm_slv_addr_w),
    .cortex_mm_slave_read               (cortex_lb_intf.rd_en),
    .cortex_mm_slave_readdata           (cortex_lb_intf.rd_data),
    .cortex_mm_slave_write              (cortex_lb_intf.wr_en),
    .cortex_mm_slave_writedata          (cortex_lb_intf.wr_data),
    .cortex_mm_slave_readdatavalid      (cortex_lb_intf.rd_valid),
    .cortex_mm_slave_reset_reset        (cortex_rst_w),

    .fft_cache_mm_slave_address         (fft_cache_mm_slv_addr_w),
    .fft_cache_mm_slave_read            (fft_cache_lb_intf.rd_en),
    .fft_cache_mm_slave_readdata        (fft_cache_lb_intf.rd_data),
    .fft_cache_mm_slave_write           (fft_cache_lb_intf.wr_en),
    .fft_cache_mm_slave_writedata       (fft_cache_lb_intf.wr_data),
    .fft_cache_mm_slave_readdatavalid   (fft_cache_lb_intf.rd_valid),
    .fft_cache_mm_slave_reset_reset     (fft_cache_rst_w),

    .sdcard_spi_MISO                    (SD_DAT),
    .sdcard_spi_MOSI                    (SD_CMD),
    .sdcard_spi_SCLK                    (SD_CLK),
    .sdcard_spi_SS_n                    (SD_DAT3),

    .uart_rxd                           (UART_RXD),
    .uart_txd                           (UART_TXD)

  );

  //Discard lower two bits of the system address
  assign  cortex_lb_intf.addr     = cortex_mm_slv_addr_w[P_CORTEX_LB_AWIDTH+1:2];
  assign  fft_cache_lb_intf.addr  = fft_cache_mm_slv_addr_w[P_FFT_CACHE_LB_AWIDTH+1:2];

  assign  cortex_rst_l_w    = ~cortex_rst_w;
  assign  fft_cache_rst_l_w = ~fft_cache_rst_w;

  /*  Instantiating Cortex Block  */
  syn_cortex            cortex_inst
  (

    .cortex_cr_intf     (cortex_cr_intf.sync),

    .fft_cache_cr_intf  (fft_cache_cr_intf.sync),

    .cortex_lb_intf     (cortex_lb_intf.slave),

    .fft_cache_lb_intf  (fft_cache_lb_intf.slave),

    .wm8731_intf        (wm8731_intf),

    .clk_vec_intf       (clk_vec_intf.dut),

    .sram_mem_intf      (sram_mem_intf.mp),

    .vga_intf           (vga_intf.mp)

  );
  defparam  cortex_inst.P_NUM_CLOCKS  = P_CORTEX_NUM_CLKS;

  //Assign to FPGA Pins
  assign  I2C_SCLK            = wm8731_intf.scl;
  assign  I2C_SDAT            = wm8731_intf.sda;
  //assign  wm8731_intf.sda     = I2C_SDAT;

  assign  AUD_XCK             = wm8731_intf.mclk;

  assign  AUD_BCLK            = wm8731_intf.bclk;
  assign  wm8731_intf.adc_dat = AUD_ADCDAT;
  assign  AUD_ADCLRCK         = wm8731_intf.adc_lrc;
  assign  AUD_DACDAT          = wm8731_intf.dac_dat;
  assign  AUD_DACLRCK         = wm8731_intf.dac_lrc;

  assign  SRAM_DQ             = sram_mem_intf.SRAM_DQ;
  //assign  sram_mem_intf.SRAM_DQ = SRAM_DQ;
  assign  SRAM_ADDR           = sram_mem_intf.SRAM_ADDR;
  assign  SRAM_LB_N           = sram_mem_intf.SRAM_LB_N;
  assign  SRAM_UB_N           = sram_mem_intf.SRAM_UB_N;
  assign  SRAM_CE_N           = sram_mem_intf.SRAM_CE_N;
  assign  SRAM_OE_N           = sram_mem_intf.SRAM_OE_N;
  assign  SRAM_WE_N           = sram_mem_intf.SRAM_WE_N;

  assign  VGA_HS              = vga_intf.hsync_n;
  assign  VGA_VS              = vga_intf.vsync_n;
  assign  VGA_R               = vga_intf.r;
  assign  VGA_G               = vga_intf.g;
  assign  VGA_B               = vga_intf.b;
  //assign  VGA_R               = 'd15;
  //assign  VGA_G               = 'd0;
  //assign  VGA_B               = 'd0;

  //LED Status
  assign  LEDR[9] = ~sys_rst_lw;
  assign  LEDR[8] = ~cortex_rst_l_w;
  assign  LEDR[7] = ~fft_cache_rst_l_w;

  assign  LEDR[6:0] = 'd0;
  assign  LEDG[7:0] = 'd0;

  //turn off the 7seg display
  assign  HEX0  = 7'h7f;
  assign  HEX1  = 7'h7f;
  assign  HEX2  = 7'h7f;
  assign  HEX3  = 7'h7f;

endmodule // syn_zen_fpga_top
