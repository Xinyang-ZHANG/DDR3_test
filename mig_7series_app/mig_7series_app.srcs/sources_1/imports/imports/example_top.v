//*****************************************************************************

// (c) Copyright 2009 - 2013 Xilinx, Inc. All rights reserved.

//

// This file contains confidential and proprietary information

// of Xilinx, Inc. and is protected under U.S. and

// international copyright and other intellectual property

// laws.

//

// DISCLAIMER

// This disclaimer is not a license and does not grant any

// rights to the materials distributed herewith. Except as

// otherwise provided in a valid license issued to you by

// Xilinx, and to the maximum extent permitted by applicable

// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND

// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES

// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING

// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-

// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and

// (2) Xilinx shall not be liable (whether in contract or tort,

// including negligence, or under any other theory of

// liability) for any loss or damage of any kind or nature

// related to, arising under or in connection with these

// materials, including for any direct, or any indirect,

// special, incidental, or consequential loss or damage

// (including loss of data, profits, goodwill, or any type of

// loss or damage suffered as a result of any action brought

// by a third party) even if such damage or loss was

// reasonably foreseeable or Xilinx had been advised of the

// possibility of the same.

//

// CRITICAL APPLICATIONS

// Xilinx products are not designed or intended to be fail-

// safe, or for use in any application requiring fail-safe

// performance, such as life-support or safety devices or

// systems, Class III medical devices, nuclear facilities,

// applications related to the deployment of airbags, or any

// other applications that could lead to death, personal

// injury, or severe property or environmental damage

// (individually and collectively, "Critical

// Applications"). Customer assumes the sole risk and

// liability of any use of Xilinx products in Critical

// Applications, subject only to applicable laws and

// regulations governing limitations on product liability.

//

// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS

// PART OF THIS FILE AT ALL TIMES.

//

//*****************************************************************************

//   ____  ____

//  /   /\/   /

// /___/  \  /    Vendor             : Xilinx

// \   \   \/     Version            : 4.2

//  \   \         Application        : MIG

//  /   /         Filename           : example_top.v

// /___/   /\     Date Last Modified : $Date: 2011/06/02 08:35:03 $

// \   \  /  \    Date Created       : Tue Sept 21 2010

//  \___\/\___\

//

// Device           : 7 Series

// Design Name      : DDR3 SDRAM

// Purpose          :

//   Top-level  module. This module serves as an example,

//   and allows the user to synthesize a self-contained design,

//   which they can be used to test their hardware.

//   In addition to the memory controller, the module instantiates:

//     1. Synthesizable testbench - used to model user's backend logic

//        and generate different traffic patterns

// Reference        :

// Revision History :

//*****************************************************************************

// pragma translate_off
`define    SIM
// pragma translate_on

`timescale 1ps/1ps

module example_top #(
   parameter APP_ADDR_WIDTH                 = 29,
   parameter APP_DATA_WIDTH                 = 128,
   parameter TCQ                            = 100
   )(
   // Inouts
   inout [15:0]                                 ddr3_dq,
   inout [1:0]                                  ddr3_dqs_n,
   inout [1:0]                                  ddr3_dqs_p,
   // Outputs
   output [14:0]                                ddr3_addr,
   output [2:0]                                 ddr3_ba,
   output                                       ddr3_ras_n,
   output                                       ddr3_cas_n,
   output                                       ddr3_we_n,
   output                                       ddr3_reset_n,
   output [0:0]                                 ddr3_ck_p,
   output [0:0]                                 ddr3_ck_n,
   output [0:0]                                 ddr3_cke,
   output [0:0]                                 ddr3_cs_n,
   output [1:0]                                 ddr3_dm,
   output [0:0]                                 ddr3_odt,
   // Single-ended system clock
`ifdef  SIM
   input                                        sys_clk_i,
   output                                       init_calib_complete,
   output                                       tg_compare_error,
   input                                        sys_rst
`else
   input                                        sys_clk_i
`endif
   );

  localparam APP_MASK_WIDTH        = APP_DATA_WIDTH / 8;

  (*mark_debug="true"*)wire [APP_ADDR_WIDTH-1:0]             app_addr;
  (*mark_debug="true"*)wire [2:0]                            app_cmd;
  (*mark_debug="true"*)wire                                  app_en;
  (*mark_debug="true"*)wire                                  app_rdy;
  (*mark_debug="true"*)wire [APP_DATA_WIDTH-1:0]             app_rd_data;
  (*mark_debug="true"*)wire                                  app_rd_data_end;
  (*mark_debug="true"*)wire                                  app_rd_data_valid;
  (*mark_debug="true"*)wire [APP_DATA_WIDTH-1:0]             app_wdf_data;
  wire                                  app_wdf_end;
  wire [APP_MASK_WIDTH-1:0]             app_wdf_mask;
  (*mark_debug="true"*)wire                                  app_wdf_rdy;
  wire                                  app_sr_active;
  wire                                  app_ref_ack;
  wire                                  app_zq_ack;
  (*mark_debug="true"*)wire                                  app_wdf_wren;
  
  (*mark_debug="true"*)wire                                  rw_fifo_ready;
  (*mark_debug="true"*)wire                                  rw_fifo_empty;
  (*mark_debug="true"*)wire                                  rd_fifo_data_valid;
  (*mark_debug="true"*)wire [APP_DATA_WIDTH-1:0]             rd_fifo_data;
  (*mark_debug="true"*)wire                                  rd_fifo_req;
  (*mark_debug="true"*)wire                                  wr_fifo_req;
  (*mark_debug="true"*)wire [APP_ADDR_WIDTH-1:0]             rw_fifo_addr;
  (*mark_debug="true"*)wire [APP_DATA_WIDTH-1:0]             wr_fifo_data;
  
  wire                                  r_init_calib_complete;

`ifdef  SIM
`else
   wire                                 clk_200m;
   (*mark_debug="true"*)wire                                 init_calib_complete;
   (*mark_debug="true"*)wire                                 tg_compare_error;
   wire                                 sys_rst;
   
   clk_wiz_50_200   clk_wiz_50_200(
       .clk_in1                         (sys_clk_i),
       .clk_out1                        (clk_200m),
       .locked                          (sys_rst)
   );
`endif
  
  wire                                  clk;
  wire                                  rst;
  wire [11:0]                           device_temp;
  

  mig_7series_1 u_mig_7series_1
      (
// Memory interface ports
       .ddr3_addr                      (ddr3_addr),
       .ddr3_ba                        (ddr3_ba),
       .ddr3_cas_n                     (ddr3_cas_n),
       .ddr3_ck_n                      (ddr3_ck_n),
       .ddr3_ck_p                      (ddr3_ck_p),
       .ddr3_cke                       (ddr3_cke),
       .ddr3_ras_n                     (ddr3_ras_n),
       .ddr3_we_n                      (ddr3_we_n),
       .ddr3_dq                        (ddr3_dq),
       .ddr3_dqs_n                     (ddr3_dqs_n),
       .ddr3_dqs_p                     (ddr3_dqs_p),
       .ddr3_reset_n                   (ddr3_reset_n),
       .init_calib_complete            (init_calib_complete),
       .ddr3_cs_n                      (ddr3_cs_n),
       .ddr3_dm                        (ddr3_dm),
       .ddr3_odt                       (ddr3_odt),
// Application interface ports
       .app_addr                       (app_addr),
       .app_cmd                        (app_cmd),
       .app_en                         (app_en),
       .app_wdf_data                   (app_wdf_data),
       .app_wdf_end                    (app_wdf_end),
       .app_wdf_wren                   (app_wdf_wren),
       .app_rd_data                    (app_rd_data),
       .app_rd_data_end                (app_rd_data_end),
       .app_rd_data_valid              (app_rd_data_valid),
       .app_rdy                        (app_rdy),
       .app_wdf_rdy                    (app_wdf_rdy),
       .app_wdf_mask                   (app_wdf_mask),
       .app_sr_req                     (1'b0),
       .app_ref_req                    (1'b0),
       .app_zq_req                     (1'b0),
       .app_sr_active                  (app_sr_active),
       .app_ref_ack                    (app_ref_ack),
       .app_zq_ack                     (app_zq_ack),
       .ui_clk                         (clk),   //100MHz 400MHz: 4:1
       .ui_clk_sync_rst                (rst),
// System Clock Ports
`ifdef  SIM
       .sys_clk_i                      (sys_clk_i),
`else
       .sys_clk_i                      (clk_200m),
`endif
       .device_temp                    (device_temp),
       .sys_rst                        (sys_rst)
       );

// End of User Design top instance
/*
ddr_app_module ddr_app_module (
    .i_sys_clk                       (clk),
    .i_sys_rst                       (~rst),
    .init_calib_complete             (init_calib_complete)		,	
       .app_addr                        (app_addr),
       .app_cmd                         (app_cmd),
       .app_en                          (app_en),
       .app_wdf_data                    (app_wdf_data),
       .app_wdf_end                     (app_wdf_end),
       .app_wdf_wren                    (app_wdf_wren),
       .app_rd_data                     (app_rd_data),
  //     .app_rd_data_end                 (app_rd_data_end),
       .app_rd_data_valid               (app_rd_data_valid),
       .app_rdy                         (app_rdy),
       .app_wdf_rdy                     (app_wdf_rdy),
       .app_wdf_mask                    (app_wdf_mask)
    );
   */

mem_trans_app #(
   .APP_ADDR_WIDTH                      (APP_ADDR_WIDTH),
   .APP_DATA_WIDTH                      (APP_DATA_WIDTH),
   .APP_MASK_WIDTH                      (APP_MASK_WIDTH)
)u_mem_trans_app(
       .app_addr                        (app_addr),
       .app_cmd                         (app_cmd),
       .app_en                          (app_en),
       .app_wdf_data                    (app_wdf_data),
       .app_wdf_end                     (app_wdf_end),
       .app_wdf_wren                    (app_wdf_wren),
       .app_rd_data                     (app_rd_data),
       .app_rd_data_end                 (app_rd_data_end),
       .app_rd_data_valid               (app_rd_data_valid),
       .app_rdy                         (app_rdy),
       .app_wdf_rdy                     (app_wdf_rdy),
       .app_wdf_mask                    (app_wdf_mask),
       .app_sr_req                      (),
       .app_ref_req                     (),
       .app_zq_req                      (),
       .app_sr_active                   (app_sr_active),
       .app_ref_ack                     (app_ref_ack),
       .app_zq_ack                      (app_zq_ack),
       .app_init_calib_complete         (init_calib_complete),
        //my port
       .RW_FIFO_READY                   (rw_fifo_ready),
       .RW_FIFO_EMPTY                   (rw_fifo_empty),
       .RD_FIFO_DATA_VALID              (rd_fifo_data_valid),
       .RD_FIFO_DATA                    (rd_fifo_data),
       .RD_FIFO_REQ                     (rd_fifo_req),
       .WR_FIFO_REQ                     (wr_fifo_req),
       .RW_FIFO_ADDR                    (rw_fifo_addr),
       .WR_FIFO_DATA                    (wr_fifo_data),
       // Single-ended system clock
       .clk                             (clk),
       .rst                             (rst),
       .init_calib_complete             (r_init_calib_complete)
);

mem_test#(
       .APP_ADDR_WIDTH                  (APP_ADDR_WIDTH),
       .APP_DATA_WIDTH                  (APP_DATA_WIDTH)
)u_mem_test(
       .clk                             (clk),
       .ui_rst                          (rst),
       .init_calib_complete             (r_init_calib_complete),
       .tg_compare_error                (tg_compare_error),
       .RW_FIFO_READY                   (rw_fifo_ready),
       .RW_FIFO_EMPTY                   (rw_fifo_empty),
       .RD_FIFO_DATA_VALID              (rd_fifo_data_valid),
       .RD_FIFO_DATA                    (rd_fifo_data),
       .RD_FIFO_REQ                     (rd_fifo_req),
       .WR_FIFO_REQ                     (wr_fifo_req),
       .RW_FIFO_ADDR                    (rw_fifo_addr),
       .WR_FIFO_DATA                    (wr_fifo_data)
);

endmodule




