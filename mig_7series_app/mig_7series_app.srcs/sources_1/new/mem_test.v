`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/07 23:56:11
// Design Name: 
// Module Name: mem_test
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
// pragma translate_off
`define    SIM
// pragma translate_on

module mem_test#(
   parameter APP_ADDR_WIDTH                 = 29,
   parameter APP_DATA_WIDTH                 = 128
)(
   input                                    clk,
   input                                    ui_rst,
   input                                    init_calib_complete,
   output                                   tg_compare_error,
   input                                    RW_FIFO_READY,
   input                                    RW_FIFO_EMPTY,
   input                                    RD_FIFO_DATA_VALID,
   input  [APP_DATA_WIDTH-1:0]              RD_FIFO_DATA,
   output                                   RD_FIFO_REQ,
   output                                   WR_FIFO_REQ,
   output [APP_ADDR_WIDTH-1:0]              RW_FIFO_ADDR,
   output [APP_DATA_WIDTH-1:0]              WR_FIFO_DATA
);

   localparam                               RAM_ADDR_WIDTH = APP_ADDR_WIDTH - 3;
   localparam                               SIM_TRANSNUM   = 26'h3ff;
   localparam                               REAL_TRANSNUM  = {1'b0,{(RAM_ADDR_WIDTH-1){1'b1}}};
`ifdef  SIM
   localparam                               TRANSNUM       = SIM_TRANSNUM;
`else
   localparam                               TRANSNUM       = REAL_TRANSNUM;
`endif
   
    
   wire                                    soft_rst;
   wire     [2:0]                          test_mode;   //0:write all then read all, 1: write one then read one, 2: write once then read only 
                                                         //3: write only, 4: read only
   wire                                    wait_rdvld;   //0: no wait, 1: wait
   wire     [2:0]                          addr_mode;   //0: linear addr, 1: random addr, 2: all 0, 3: all 1, 4: 0/1 alter
   wire     [2:0]                          data_mode;   //0: linear data, 1: random data, 2: all 0, 3: all 1, 4: 0/1 alter
   
   wire                                    start;
   wire                                    start_d0;
   reg                                     start_d1           = 0;
   reg                                     start_d2           = 0;
   wire                                    rst      = (ui_rst | soft_rst) || ~init_calib_complete;
   reg                                     r1_ready     = 'b1;
   reg                                     r2_wr_ready  = 'b0;
   reg                                     r2_rd_ready  = 'b0;
   reg                                     r3_wr_ready  = 'b0;
   reg                                     r3_rd_ready  = 'b0;
   reg      [APP_DATA_WIDTH-1 : 0]         r1_rd_fifo_data          =  'b0;
   reg                                     r1_rd_fifo_data_valid    = 1'b0;
   
   (*mark_debug="true"*)reg      [2:0]    state   = 'b0;
   wire                                    rw_all_mode0         = (test_mode == 3'b000);
   wire                                    rw_one_mode1         = (test_mode == 3'b001);
   wire                                    w_one_r_all_mode2    = (test_mode == 3'b010);
   wire                                    w_only_mode3         = (test_mode == 3'b011);
   wire                                    r_only_mode4         = (test_mode == 3'b100);
   
   reg                                     ddr_wr_firstcyc      = 'b0;
   (*mark_debug="true"*)reg     [RAM_ADDR_WIDTH-1 : 0]          ddr_wr_cnt           = 'b0;
   (*mark_debug="true"*)reg     [RAM_ADDR_WIDTH-1 : 0]          ddr_rd_cnt           = 'b0;
   (*mark_debug="true"*)reg     [RAM_ADDR_WIDTH-1 : 0]          ddr_rdvld_cnt        = 'b0;
   
   wire                                    ddr_wr_req           ;
   reg     [RAM_ADDR_WIDTH-1 : 0]          ddr_wr_addr          = 'b0;
   reg     [APP_DATA_WIDTH-1 : 0]          ddr_wr_data          = 'b0;
   reg     [RAM_ADDR_WIDTH-1 : 0]          ddr_wr_addr_r1       = 'b0;
   reg     [APP_DATA_WIDTH-1 : 0]          ddr_wr_data_r1       = 'b0;
   wire                                    ddr_rd_req           ;
   reg     [RAM_ADDR_WIDTH-1 : 0]          ddr_rd_addr          = 'b0;
   reg     [RAM_ADDR_WIDTH-1 : 0]          ddr_rd_addr_r1       = 'b0;
   reg     [APP_DATA_WIDTH-1 : 0]          ddr_rd_cmpdata       = 'b0;
   
   //counter 
   reg      [31:0]                         timer_wr_r           = 'b0;
   reg                                     cnt_wr_en            = 'b0;
   reg      [63:0]                         cnt_wr_10ns          = 'b0;
   reg      [31:0]                         cnt_wr_1ms           = 'b0;
   reg      [31:0]                         timer_rd_r           = 'b0;
   reg                                     cnt_rd_en            = 'b0;
   reg      [63:0]                         cnt_rd_10ns          = 'b0;
   reg      [31:0]                         cnt_rd_1ms           = 'b0;
   reg      [31:0]                         timer_rdvld_r        = 'b0;
   reg                                     cnt_rdvld_en         = 'b0;
   reg      [63:0]                         cnt_rdvld_10ns       = 'b0;
   reg      [31:0]                         cnt_rdvld_1ms        = 'b0;
   
   reg                                     prbs_rst_r           = 'b0;
   wire                                    prbs_rst;
   wire                                    prbs_rst2;
   wire                                    prbs_pause;
   wire    [RAM_ADDR_WIDTH-1 : 0]          prbs_addr;      
   wire    [RAM_ADDR_WIDTH-1 : 0]          prbs_cmpaddr;  
   
   assign   WR_FIFO_REQ                     = ddr_wr_req;     
   assign   RD_FIFO_REQ                     = ddr_rd_req;          
   assign   RW_FIFO_ADDR                    = ddr_rd_req ? {ddr_rd_addr_r1,3'b000} : {ddr_wr_addr_r1,3'b000};
   assign   WR_FIFO_DATA                    = ddr_wr_data_r1;
   
`ifdef  SIM
   reg                                      soft_rst_reg        = 0;
   reg                                      start_reg           = 0;
   
   initial begin
       #110000
       soft_rst_reg     <= 1'b1;
       #232
       soft_rst_reg     <= 1'b0;
       
       #1001
       start_reg        <= 1'b1;
       #87
       start_reg        <= 1'b0;
   end
   
   assign   soft_rst    = soft_rst_reg;
   assign   test_mode   = 3'd0;
   assign   addr_mode   = 3'd1;
   assign   data_mode   = 3'd0;
   assign   wait_rdvld  = 1;
   assign   start_d0    = start_reg;
`else
   vio_0    vio_0(
       .clk         (clk),
       .probe_in0   (timer_wr_r),
       .probe_in1   (timer_rd_r),
       .probe_in2   (timer_rdvld_r),
       .probe_out0  (soft_rst),
       .probe_out1  (test_mode),
       .probe_out2  (addr_mode),
       .probe_out3  (data_mode),
       .probe_out4  (wait_rdvld),
       .probe_out5  (start_d0)
   );
`endif

   always@(posedge clk) begin
       start_d1    <= start_d0;
       start_d2    <= start_d1;
   end
   
   assign   start       = ~start_d2 & start_d1;
   
   always@(posedge clk)
       prbs_rst_r       <= (test_mode == 3'b001) ? (r2_rd_ready & (ddr_rd_cnt == 0))
                                                 : ((r2_wr_ready & (ddr_wr_cnt == 0)) || (r2_rd_ready & (ddr_rd_cnt == 0)));
   assign   prbs_rst    = start | prbs_rst_r;
   assign   prbs_rst2   = start | (RD_FIFO_DATA_VALID & (ddr_rdvld_cnt == TRANSNUM));
   
   assign   prbs_pause  = (test_mode == 3'b001) ? ~r2_rd_ready
                                                : ~(r2_wr_ready | r2_rd_ready);
   
   prbs_generator   u_prbs_generator_wr(
       .clock       (clk),
       .init        (prbs_rst),
       .pause       (prbs_pause),
       .type        (4'b0111),
       .out         (prbs_addr)
   );
   
   prbs_generator   u_prbs_generator_cmprd(
       .clock       (clk),
       .init        (prbs_rst2),
       .pause       (~RD_FIFO_DATA_VALID),
       .type        (4'b0111),
       .out         (prbs_cmpaddr)
   );
   
   always@(posedge clk) begin
       r1_ready     <= RW_FIFO_READY;
       r2_wr_ready  <= r1_ready & (state == 2'd2);
       r2_rd_ready  <= r1_ready & (state == 2'd3);
       r3_wr_ready  <= r2_wr_ready;
       r3_rd_ready  <= r2_rd_ready;
   end
   
   always@(posedge clk) begin
       r1_rd_fifo_data_valid    <= RD_FIFO_DATA_VALID;
       r1_rd_fifo_data          <= RD_FIFO_DATA;
   end
   
   assign   ddr_wr_req  = r3_wr_ready;
   assign   ddr_rd_req  = r3_rd_ready;
        
   always@(posedge clk) begin
       if(rst) begin
           ddr_wr_cnt       <= 'd0;
       end else begin
           if(r1_ready & (state == 2'd2)) begin
               if(ddr_wr_cnt == TRANSNUM) 
                   ddr_wr_cnt   <= 'd0;
               else
                   ddr_wr_cnt   <= ddr_wr_cnt + 'd1;
           end else begin
               ddr_wr_cnt       <= ddr_wr_cnt;
           end
       end
   end
   
   always@(posedge clk) begin
       if(rst) begin
           ddr_wr_addr      <= 'd0;
       end else begin
           if(r2_wr_ready) begin
               case(addr_mode)
                   0: ddr_wr_addr   <= ddr_wr_cnt;
                   //1: ddr_wr_addr   <= {1'b0,prbs_addr[RAM_ADDR_WIDTH-1:0]};
                   2: ddr_wr_addr   <= {RAM_ADDR_WIDTH{1'b0}};
                   3: ddr_wr_addr   <= {RAM_ADDR_WIDTH{1'b1}};
                   4: ddr_wr_addr   <= ddr_wr_cnt[0] ? {RAM_ADDR_WIDTH{1'b0}} : {RAM_ADDR_WIDTH{1'b1}};
                   default: ddr_wr_addr   <= ddr_wr_cnt;
               endcase
           end else begin
               ddr_wr_addr      <= ddr_wr_addr;
           end
       end
   end
   
   always@(posedge clk) begin
       if(rst) begin
           ddr_wr_addr_r1   <= 'd0;
       end else begin
           if(addr_mode==1) begin
               ddr_wr_addr_r1   <= {1'b0,prbs_addr[RAM_ADDR_WIDTH-1:0]};
           end else begin
               ddr_wr_addr_r1   <= ddr_wr_addr;
           end
       end
   end
   
   always@(posedge clk) begin
       if(rst) begin
           ddr_wr_data      <= 'd0;
       end else begin
           if(r2_wr_ready) begin
               case(data_mode)
                   0: ddr_wr_data   <= {APP_DATA_WIDTH/32{{(32-RAM_ADDR_WIDTH){1'b0}}, ddr_wr_cnt}};
                   //1: ddr_wr_data   <= {APP_DATA_WIDTH/32{{(32-RAM_ADDR_WIDTH){1'b0}}, prbs_addr}};
                   2: ddr_wr_data   <= {APP_DATA_WIDTH{1'b0}};
                   3: ddr_wr_data   <= {APP_DATA_WIDTH{1'b1}};
                   4: ddr_wr_data   <= ddr_wr_cnt[0] ? {APP_DATA_WIDTH{1'b0}} : {APP_DATA_WIDTH{1'b1}};
                   default: ddr_wr_data   <= {APP_DATA_WIDTH/32{{(32-RAM_ADDR_WIDTH){1'b0}}, ddr_wr_cnt}};
               endcase
           end else begin
               ddr_wr_data      <= ddr_wr_data;
           end
       end
   end
   
   always@(posedge clk) begin
       if(rst) begin
           ddr_wr_data_r1   <= 'd0;
       end else begin
           if(data_mode==1) begin
               ddr_wr_data_r1   <= {APP_DATA_WIDTH/32{{(32-RAM_ADDR_WIDTH){1'b0}}, prbs_addr}};
           end else begin
               ddr_wr_data_r1   <= ddr_wr_data;
           end
       end
   end
   
   always@(posedge clk) begin
       if(rst) begin
           ddr_wr_firstcyc      <= 'b0;
       end else begin
           if(r1_ready & (ddr_wr_cnt == TRANSNUM))
               ddr_wr_firstcyc  <= 'b1;
       end
   end
   
   always@(posedge clk) begin
       if(rst) begin
           ddr_rd_cnt       <= 'd0;
       end else begin
           if(r1_ready & (state == 2'd3)) begin
               if(ddr_rd_cnt == TRANSNUM) 
                   ddr_rd_cnt   <= 'd0;
               else
                   ddr_rd_cnt   <= ddr_rd_cnt + 'd1;
           end else begin
               ddr_rd_cnt       <= ddr_rd_cnt;
           end
       end
   end
   
   always@(posedge clk) begin
       if(rst) begin
           ddr_rd_addr      <= 'd0;
       end else begin
           if(r2_rd_ready) begin
               case(addr_mode)
                   0: ddr_rd_addr   <= ddr_rd_cnt;
                   1: ddr_rd_addr   <= {1'b0,prbs_addr[RAM_ADDR_WIDTH-1:0]};
                   2: ddr_rd_addr   <= {APP_ADDR_WIDTH{1'b0}};
                   3: ddr_rd_addr   <= {APP_ADDR_WIDTH{1'b1}};
                   4: ddr_rd_addr   <= ddr_rd_cnt[0] ? {APP_ADDR_WIDTH{1'b0}} : {APP_ADDR_WIDTH{1'b1}};
                   default: ddr_rd_addr   <= ddr_rd_cnt;
               endcase
           end else begin
               ddr_rd_addr      <= ddr_rd_addr;
           end
       end
   end
   
   always@(posedge clk) begin
       if(rst) begin
           ddr_rd_addr_r1   <= 'd0;
       end else begin
           if(addr_mode==1) begin
               ddr_rd_addr_r1   <= {1'b0,prbs_addr[RAM_ADDR_WIDTH-1:0]};
           end else begin
               ddr_rd_addr_r1   <= ddr_rd_addr;
           end
       end
   end
   
   always@(posedge clk) begin
       if(rst) begin
           ddr_rdvld_cnt    <= 'd0;
       end else begin
           if(RD_FIFO_DATA_VALID) begin
               if(ddr_rdvld_cnt == TRANSNUM) 
                   ddr_rdvld_cnt   <= 'd0;
               else
                   ddr_rdvld_cnt   <= ddr_rdvld_cnt + 'd1;
           end else begin
               ddr_rdvld_cnt       <= ddr_rdvld_cnt;
           end
       end
   end
   
   always@(posedge clk) begin
       if(rst) begin
           ddr_rd_cmpdata   <= 'd0;
       end else begin
           if(RD_FIFO_DATA_VALID) begin
               case(data_mode)
                   0: ddr_rd_cmpdata    <= {APP_DATA_WIDTH/32{{(32-RAM_ADDR_WIDTH){1'b0}}, ddr_rdvld_cnt}};
                   1: ddr_rd_cmpdata    <= {APP_DATA_WIDTH/32{{(32-RAM_ADDR_WIDTH){1'b0}}, prbs_cmpaddr}};
                   2: ddr_rd_cmpdata    <= {APP_DATA_WIDTH{1'b0}};
                   3: ddr_rd_cmpdata    <= {APP_DATA_WIDTH{1'b1}};
                   4: ddr_rd_cmpdata    <= ddr_wr_cnt[0] ? {APP_DATA_WIDTH{1'b0}} : {APP_DATA_WIDTH{1'b1}};
               endcase
           end else begin
               ddr_rd_cmpdata   <= ddr_rd_cmpdata;
           end
       end
   end
   
   assign   tg_compare_error    = r1_rd_fifo_data_valid & (ddr_rd_cmpdata != r1_rd_fifo_data);
        
   always@(posedge clk) begin
       if(rst) begin
           state    <= 'd0;
       end else begin
           case(state)
               0: begin     // IDLE
                   if(start)
                       state    <= 3'd1;
               end
               1: begin     // MODE
                   if(r_only_mode4 | (ddr_wr_firstcyc & w_one_r_all_mode2))
                       state    <= 3'd3;
                   else
                       state    <= 3'd2;
               end
               2: begin     // WRITE
                   if(r1_ready) begin
                       if(rw_one_mode1) begin
                           state    <= 3'd3;
                       end else if(ddr_wr_cnt == TRANSNUM) begin
                           state    <= w_only_mode3 ? 3'd1 : 3'd5;
                       end else begin
                           state    <= 3'd2;    
                       end
                   end else begin
                       state    <= 3'd2;
                   end
               end
               3: begin     // READ
                   if(r1_ready) begin
                       if(rw_one_mode1) begin
                           if(ddr_rd_cnt == TRANSNUM) begin
                               state    <= wait_rdvld ? 3'd4 : 3'd1;
                           end else begin
                               state    <= wait_rdvld ? 3'd4 : 3'd2;
                           end
                       end else begin       // mode 0,2,4
                           if(ddr_rd_cnt == TRANSNUM) begin
                               state    <= wait_rdvld ? 3'd4 : 3'd1;
                           end else begin
                               state    <= wait_rdvld ? 3'd4 : 3'd3;
                           end
                       end 
                   end else begin
                       state    <= 3'd3;
                   end
               end
               4: begin     // READ WAIT
                   if(RD_FIFO_DATA_VALID) begin
                       if(rw_one_mode1) begin
                           if(ddr_rdvld_cnt == TRANSNUM) begin
                               state    <= 3'd1;
                           end else begin
                               state    <= 3'd2;
                           end
                       end else begin       // mode 0,2,4
                           if(ddr_rdvld_cnt == TRANSNUM) begin
                               state    <= 3'd1;
                           end else begin
                               state    <= 3'd3;
                           end
                       end 
                   end else begin
                       state    <= 3'd4;
                   end
               end
               5: begin     //continuous wr to continuous rd (prbs needs this to init)
                   state    <= 3'd3;
               end
               default: begin
                   state    <= 3'd0;
               end
           endcase
       end
   end
   
   //counter 
   always@(posedge clk) begin
       if(rst) begin
           cnt_wr_en    <= 'b0;
           timer_wr_r   <= 'd0;
       end else begin
           if(r1_ready & (state == 2'd2) & (ddr_wr_cnt == TRANSNUM)) begin
               cnt_wr_en    <= 'b0;
               timer_wr_r   <= cnt_wr_1ms;
           end else if(r1_ready & (state == 2'd2) & (ddr_wr_cnt == 0)) begin
               cnt_wr_en    <= 'b1;
               timer_wr_r   <= timer_wr_r;
           end
       end
   end
   
   always@(posedge clk) begin
       if(rst) begin
           cnt_wr_10ns  <= 'b0;
           cnt_wr_1ms   <= 'b0;
       end else begin
           if(cnt_wr_en) begin
               if(cnt_wr_10ns == 64'd99) begin
                   cnt_wr_10ns  <= 'b0;
                   cnt_wr_1ms   <= cnt_wr_1ms + 'b1;
               end else begin
                   cnt_wr_10ns  <= cnt_wr_10ns + 'b1;
                   cnt_wr_1ms   <= cnt_wr_1ms;
               end
           end else begin
               cnt_wr_10ns  <= 'b0;
               cnt_wr_1ms   <= 'b0;
           end
       end
   end
   
   always@(posedge clk) begin
       if(rst) begin
           cnt_rd_en    <= 'b0;
           timer_rd_r   <= 'd0;
       end else begin
           if(r1_ready & (state == 2'd3) & (ddr_rd_cnt == TRANSNUM)) begin
               cnt_rd_en    <= 'b0;
               timer_rd_r   <= cnt_rd_1ms;
           end else if(r1_ready & (state == 2'd3) & (ddr_rd_cnt == 0)) begin
               cnt_rd_en    <= 'b1;
               timer_rd_r   <= timer_rd_r;
           end
       end
   end
   
   always@(posedge clk) begin
       if(rst) begin
           cnt_rd_10ns  <= 'b0;
           cnt_rd_1ms   <= 'b0;
       end else begin
           if(cnt_rd_en) begin
               if(cnt_rd_10ns == 64'd99) begin
                   cnt_rd_10ns  <= 'b0;
                   cnt_rd_1ms   <= cnt_rd_1ms + 'b1;
               end else begin
                   cnt_rd_10ns  <= cnt_rd_10ns + 'b1;
                   cnt_rd_1ms   <= cnt_rd_1ms;
               end
           end else begin
               cnt_rd_10ns  <= 'b0;
               cnt_rd_1ms   <= 'b0;
           end
       end
   end
   
   always@(posedge clk) begin
       if(rst) begin
           cnt_rdvld_en     <= 'b0;
           timer_rdvld_r    <= 'd0;
       end else begin
           if(RD_FIFO_DATA_VALID & (ddr_rdvld_cnt == TRANSNUM)) begin
               cnt_rdvld_en     <= 'b0;
               timer_rdvld_r    <= cnt_rdvld_1ms;
           end else if(RD_FIFO_DATA_VALID & (ddr_rdvld_cnt == 0)) begin
               cnt_rdvld_en     <= 'b1;
               timer_rdvld_r    <= timer_rdvld_r;
           end
       end
   end
   
   always@(posedge clk) begin
       if(rst) begin
           cnt_rdvld_10ns   <= 'b0;
           cnt_rdvld_1ms    <= 'b0;
       end else begin
           if(cnt_rdvld_en) begin
               if(cnt_rdvld_10ns == 64'd99) begin
                   cnt_rdvld_10ns   <= 'b0;
                   cnt_rdvld_1ms    <= cnt_rdvld_1ms + 'b1;
               end else begin
                   cnt_rdvld_10ns   <= cnt_rdvld_10ns + 'b1;
                   cnt_rdvld_1ms    <= cnt_rdvld_1ms;
               end
           end else begin
               cnt_rdvld_10ns   <= 'b0;
               cnt_rdvld_1ms    <= 'b0;
           end
       end
   end
    
endmodule
