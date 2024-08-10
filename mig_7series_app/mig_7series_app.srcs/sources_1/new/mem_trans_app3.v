`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/07 14:31:48
// Design Name: 
// Module Name: mem_trans_app
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mem_trans_app3 #(
   parameter APP_ADDR_WIDTH                 = 29,
   parameter APP_DATA_WIDTH                 = 128,
   parameter APP_MASK_WIDTH                 = APP_DATA_WIDTH / 8
)(
   output [APP_ADDR_WIDTH-1:0]              app_addr,
   output [2:0]                             app_cmd,
   output                                   app_en,
   input                                    app_rdy,
   input  [APP_DATA_WIDTH-1:0]              app_rd_data,
   input                                    app_rd_data_end,
   input                                    app_rd_data_valid,
   output [APP_DATA_WIDTH-1:0]              app_wdf_data,
   output                                   app_wdf_wren,
   output                                   app_wdf_end,
   output [APP_MASK_WIDTH-1:0]              app_wdf_mask,
   input                                    app_wdf_rdy,
   output                                   app_sr_req,
   output                                   app_ref_req,
   output                                   app_zq_req,
   input                                    app_sr_active,
   input                                    app_ref_ack,
   input                                    app_zq_ack,
   input                                    app_init_calib_complete,
   //my port
   output                                   RW_FIFO_READY,
   output                                   RW_FIFO_EMPTY,
   output                                   RD_FIFO_DATA_VALID,
   output [APP_DATA_WIDTH-1:0]              RD_FIFO_DATA,
   input                                    RD_FIFO_REQ,
   input                                    WR_FIFO_REQ,
   input  [APP_ADDR_WIDTH-1:0]              RW_FIFO_ADDR,
   input  [APP_DATA_WIDTH-1:0]              WR_FIFO_DATA,
   // Single-ended system clock
   input                                    clk,
   output reg                              init_calib_complete,
   input                                    rst
);

    always@(posedge clk)                    init_calib_complete     <= app_init_calib_complete;

    wire                                    empty_appfifo_cmd;
    wire                                    empty_appfifo_dat;
    
    wire                                    wr_appfifo_cmd;
    wire [3:0]                              cmdcnt_appfifo;
    wire [3:0]                              datcnt_appfifo;
    wire                                    rd_appfifo_cmd;
    wire                                    rd_appfifo_dat;
    wire                                    rd_en_appfifo;
    wire                                    rd_we_appfifo;
    wire                                    rd_rw_appfifo;
    wire [APP_ADDR_WIDTH-1:0]               rd_addr_appfifo;
    wire [APP_DATA_WIDTH-1:0]               rd_data_appfifo;
    
    assign  wr_appfifo_cmd                  = WR_FIFO_REQ | RD_FIFO_REQ;
    assign  rd_appfifo_cmd                  = ~empty_appfifo_cmd & app_rdy;
    assign  rd_appfifo_dat                  = ~empty_appfifo_dat & app_wdf_rdy;
    assign  RW_FIFO_EMPTY                   = empty_appfifo_cmd & empty_appfifo_dat;
    assign  RW_FIFO_READY                   = ~cmdcnt_appfifo[3] && ~datcnt_appfifo[3];
    
    syncfifo_dist   u_app_syncfifo_cmd(
        .clk        (clk),
        .wr_en      (wr_appfifo_cmd),
        .din        ({wr_appfifo_cmd, RD_FIFO_REQ, RW_FIFO_ADDR}),
        .full       (),
        .rd_en      (rd_appfifo_cmd),
        .dout       ({rd_en_appfifo, rd_rw_appfifo, rd_addr_appfifo}),
        .empty      (empty_appfifo_cmd),
        .data_count (cmdcnt_appfifo)
    );
    
    syncfifo_dist   u_app_syncfifo_dat(
        .clk        (clk),
        .wr_en      (WR_FIFO_REQ),
        .din        ({WR_FIFO_REQ, WR_FIFO_DATA}),
        .full       (),
        .rd_en      (rd_appfifo_dat),
        .dout       ({rd_we_appfifo, rd_data_appfifo}),
        .empty      (empty_appfifo_dat),
        .data_count (datcnt_appfifo)
    );
    
    assign  app_en                          = rd_en_appfifo & ~empty_appfifo_cmd;
    assign  app_cmd                         = {2'b00, rd_rw_appfifo};
    assign  app_addr                        = rd_addr_appfifo;
    assign  app_wdf_data                    = rd_data_appfifo;
    assign  app_wdf_wren                    = rd_we_appfifo & ~empty_appfifo_dat;
    assign  app_wdf_end                     = rd_we_appfifo & ~empty_appfifo_dat;
    assign  app_wdf_mask                    = 'b0;
    
    assign  RD_FIFO_DATA_VALID              = app_rd_data_valid;
    assign  RD_FIFO_DATA                    = app_rd_data;
    
endmodule
