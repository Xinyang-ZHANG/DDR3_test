// pragma translate_off
`define    SIM
// pragma translate_on


`timescale 1ps/1ps

module example_top#(
   /*
   parameter BEGIN_ADDRESS         = 32'h00000000,
   parameter END_ADDRESS           = 32'h00ffffff,
   parameter CK_WIDTH              = 1,
   parameter nCS_PER_RANK          = 1,
   parameter CKE_WIDTH             = 1,
   parameter DM_WIDTH              = 2,
   parameter ODT_WIDTH             = 1,
   parameter BANK_WIDTH            = 3,
   parameter COL_WIDTH             = 10,
   parameter CS_WIDTH              = 1,
   parameter DQ_WIDTH              = 16,
   parameter DQS_WIDTH             = 2,
   parameter DQS_CNT_WIDTH         = 1,
   parameter DRAM_WIDTH            = 8,
   parameter ECC                   = "OFF",
   parameter ECC_TEST              = "OFF",
   parameter nBANK_MACHS           = 4,
   parameter RANKS                 = 1,
   parameter ROW_WIDTH             = 15,
   parameter ADDR_WIDTH            = 29,
   parameter BURST_MODE            = "8",
   parameter CLKIN_PERIOD          = 5000,
   parameter CLKFBOUT_MULT         = 4,
   parameter DIVCLK_DIVIDE         = 1,
   parameter CLKOUT0_PHASE         = 0.0,
   parameter CLKOUT0_DIVIDE        = 1,
   parameter CLKOUT1_DIVIDE        = 2,
   parameter CLKOUT2_DIVIDE        = 32,
   parameter CLKOUT3_DIVIDE        = 8,
   parameter MMCM_VCO              = 800,
   parameter MMCM_MULT_F           = 8,
   parameter MMCM_DIVCLK_DIVIDE    = 1,
   parameter SIMULATION            = "FALSE",
   parameter TCQ                   = 100,
   parameter DRAM_TYPE             = "DDR3",
   parameter nCK_PER_CLK           = 4,
   */
   parameter C_S_AXI_ID_WIDTH      = 12,
   parameter C_S_AXI_ADDR_WIDTH    = 29,
   parameter C_S_AXI_DATA_WIDTH    = 128
 )(
   inout [15:0]                         ddr3_dq,
   inout [1:0]                          ddr3_dqs_n,
   inout [1:0]                          ddr3_dqs_p,
   output [14:0]                        ddr3_addr,
   output [2:0]                         ddr3_ba,
   output                               ddr3_ras_n,
   output                               ddr3_cas_n,
   output                               ddr3_we_n,
   output                               ddr3_reset_n,
   output [0:0]                         ddr3_ck_p,
   output [0:0]                         ddr3_ck_n,
   output [0:0]                         ddr3_cke,
   output [0:0]                         ddr3_cs_n,
   output [1:0]                         ddr3_dm,
   output [0:0]                         ddr3_odt,

`ifdef  SIM
   input                                        sys_clk_i,
   output                                       init_calib_complete,
   output                                       tg_compare_error,
   input                                        sys_rst
`else
   input                                        sys_clk_i
`endif
);

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

wire                              clk;
wire                              rst;
reg                               aresetn;
wire                              soft_aresetn;

wire [C_S_AXI_ID_WIDTH-1:0]                             s_axi_awid;
(*mark_debug="true"*)wire [C_S_AXI_ADDR_WIDTH-1:0]     s_axi_awaddr;
(*mark_debug="true"*)wire [7:0]                        s_axi_awlen;
wire [2:0]                                              s_axi_awsize;
wire [1:0]                                              s_axi_awburst;
wire [0:0]                                              s_axi_awlock;
wire [3:0]                                              s_axi_awcache;
wire [2:0]                                              s_axi_awprot;
(*mark_debug="true"*)wire                              s_axi_awvalid;
(*mark_debug="true"*)wire                              s_axi_awready;
// Slave Interface Write Data Ports
(*mark_debug="true"*)wire [C_S_AXI_DATA_WIDTH-1:0]     s_axi_wdata;
wire [(C_S_AXI_DATA_WIDTH/8)-1:0]                       s_axi_wstrb;
(*mark_debug="true"*)wire                              s_axi_wlast;
(*mark_debug="true"*)wire                              s_axi_wvalid;
(*mark_debug="true"*)wire                              s_axi_wready;
// Slave Interface Write Response Ports
(*mark_debug="true"*)wire                              s_axi_bready;
wire [C_S_AXI_ID_WIDTH-1:0]                             s_axi_bid;
(*mark_debug="true"*)wire [1:0]                        s_axi_bresp;
wire                                                    s_axi_bvalid;
// Slave Interface Read Address Ports
wire [C_S_AXI_ID_WIDTH-1:0]                             s_axi_arid;
(*mark_debug="true"*)wire [C_S_AXI_ADDR_WIDTH-1:0]     s_axi_araddr;
(*mark_debug="true"*)wire [7:0]                        s_axi_arlen;
wire [2:0]                                              s_axi_arsize;
wire [1:0]                                              s_axi_arburst;
wire [0:0]                                              s_axi_arlock;
wire [3:0]                                              s_axi_arcache;
wire [2:0]                                              s_axi_arprot;
(*mark_debug="true"*)wire                              s_axi_arvalid;
(*mark_debug="true"*)wire                              s_axi_arready;
// Slave Interface Read Data Ports
(*mark_debug="true"*)wire                              s_axi_rready;
wire [C_S_AXI_ID_WIDTH-1:0]                             s_axi_rid;
(*mark_debug="true"*)wire [C_S_AXI_DATA_WIDTH-1:0]     s_axi_rdata;
wire [1:0]                                              s_axi_rresp;
(*mark_debug="true"*)wire                              s_axi_rlast;
(*mark_debug="true"*)wire                              s_axi_rvalid;

//wire [11:0]                       device_temp;

(*mark_debug="true"*)wire                             wr_adrs_req;
(*mark_debug="true"*)wire [C_S_AXI_ADDR_WIDTH-1:0]    wr_adrs;
(*mark_debug="true"*)wire [7:0]                       wr_len; 
(*mark_debug="true"*)wire                             wr_ready;
(*mark_debug="true"*)wire                             wr_data_req;
(*mark_debug="true"*)wire [C_S_AXI_DATA_WIDTH-1:0]    wr_data;
(*mark_debug="true"*)wire                             wr_ack;

(*mark_debug="true"*)wire                             rd_adrs_req;
(*mark_debug="true"*)wire [C_S_AXI_ADDR_WIDTH-1:0]    rd_adrs;
(*mark_debug="true"*)wire [7:0]                       rd_len;
(*mark_debug="true"*)wire                             rd_ready;
(*mark_debug="true"*)wire                             rd_data_val;
(*mark_debug="true"*)wire [C_S_AXI_DATA_WIDTH-1:0]    rd_data;

wire                             mode;

mig_7series_0   u_mig_7series_0(
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
       .ui_clk                         (clk),
       .ui_clk_sync_rst                (rst),
       .mmcm_locked                    (),
       .aresetn                        (aresetn),
// Slave Interface Write Address Ports
       .s_axi_awid                     (s_axi_awid),
       .s_axi_awaddr                   (s_axi_awaddr),
       .s_axi_awlen                    (s_axi_awlen),
       .s_axi_awsize                   (s_axi_awsize),
       .s_axi_awburst                  (s_axi_awburst),
       .s_axi_awlock                   (s_axi_awlock),
       .s_axi_awcache                  (s_axi_awcache),
       .s_axi_awprot                   (s_axi_awprot),
       .s_axi_awqos                    (4'h1),
       .s_axi_awvalid                  (s_axi_awvalid),
       .s_axi_awready                  (s_axi_awready),
// Slave Interface Write Data Ports
       .s_axi_wdata                    (s_axi_wdata),
       .s_axi_wstrb                    (s_axi_wstrb),
       .s_axi_wlast                    (s_axi_wlast),
       .s_axi_wvalid                   (s_axi_wvalid),
       .s_axi_wready                   (s_axi_wready),
// Slave Interface Write Response Ports
       .s_axi_bid                      (s_axi_bid),
       .s_axi_bresp                    (s_axi_bresp),
       .s_axi_bvalid                   (s_axi_bvalid),
       .s_axi_bready                   (s_axi_bready),
// Slave Interface Read Address Ports
       .s_axi_arid                     (s_axi_arid),
       .s_axi_araddr                   (s_axi_araddr),
       .s_axi_arlen                    (s_axi_arlen),
       .s_axi_arsize                   (s_axi_arsize),
       .s_axi_arburst                  (s_axi_arburst),
       .s_axi_arlock                   (s_axi_arlock),
       .s_axi_arcache                  (s_axi_arcache),
       .s_axi_arprot                   (s_axi_arprot),
       .s_axi_arqos                    (4'h1),
       .s_axi_arvalid                  (s_axi_arvalid),
       .s_axi_arready                  (s_axi_arready),
// Slave Interface Read Data Ports
       .s_axi_rid                      (s_axi_rid),
       .s_axi_rdata                    (s_axi_rdata),
       .s_axi_rresp                    (s_axi_rresp),
       .s_axi_rlast                    (s_axi_rlast),
       .s_axi_rvalid                   (s_axi_rvalid),
       .s_axi_rready                   (s_axi_rready),
// System Clock Ports
`ifdef  SIM
       .sys_clk_i                      (sys_clk_i),
`else
       .sys_clk_i                      (clk_200m),
`endif
       .device_temp                    (),
       .sys_rst                        (sys_rst)
);

always @(posedge clk) begin
    aresetn <= ~rst;
end

mem_trans_axi#(
    .C_AXI_ID_WIDTH     (C_S_AXI_ID_WIDTH),
    .C_AXI_ADDR_WIDTH   (C_S_AXI_ADDR_WIDTH),
    .C_AXI_DATA_WIDTH   (C_S_AXI_DATA_WIDTH)
)
u_mem_trans_axi
(
	.ARESETN           (aresetn & soft_aresetn),
	.ACLK              (clk),
	
	.M_AXI_AWID        (s_axi_awid),   //output
	.M_AXI_AWADDR      (s_axi_awaddr),     
	.M_AXI_AWLEN       (s_axi_awlen),
	.M_AXI_AWSIZE      (s_axi_awsize),
	.M_AXI_AWBURST     (s_axi_awburst),
	.M_AXI_AWLOCK      (s_axi_awlock),
	.M_AXI_AWCACHE     (s_axi_awcache),
	.M_AXI_AWPROT      (s_axi_awprot),
//	.M_AXI_AWQOS       (M_AXI_AWQOS),
//	.M_AXI_AWUSER      (M_AXI_AWUSER),
	.M_AXI_AWVALID     (s_axi_awvalid),
	.M_AXI_AWREADY     (s_axi_awready),
	
//	.M_AXI_WID         (s_axi_wid),      //output
	.M_AXI_WDATA       (s_axi_wdata),
	.M_AXI_WSTRB       (s_axi_wstrb),
	.M_AXI_WLAST       (s_axi_wlast),
//	.M_AXI_WUSER       (M_AXI_WUSER),
	.M_AXI_WVALID      (s_axi_wvalid),
	.M_AXI_WREADY      (s_axi_wready),
	
	.M_AXI_BID         (s_axi_bid),        //input
	.M_AXI_BRESP       (s_axi_bresp),
//	.M_AXI_BUSER       (M_AXI_BUSER),
	.M_AXI_BVALID      (s_axi_bvalid),
	.M_AXI_BREADY      (s_axi_bready),
	
	.M_AXI_ARID        (s_axi_arid),       //output
	.M_AXI_ARADDR      (s_axi_araddr),
	.M_AXI_ARLEN       (s_axi_arlen),
	.M_AXI_ARSIZE      (s_axi_arsize),
	.M_AXI_ARBURST     (s_axi_arburst),
	.M_AXI_ARLOCK      (s_axi_arlock),
	.M_AXI_ARCACHE     (s_axi_arcache),
	.M_AXI_ARPROT      (s_axi_arprot),
//	.M_AXI_ARQOS       (M_AXI_ARQOS),
//	.M_AXI_ARUSER      (M_AXI_ARUSER),
	.M_AXI_ARVALID     (s_axi_arvalid),
	.M_AXI_ARREADY     (s_axi_arready),
	
	.M_AXI_RID         (s_axi_rid),        //input
	.M_AXI_RDATA       (s_axi_rdata),
	.M_AXI_RRESP       (s_axi_rresp),
	.M_AXI_RLAST       (s_axi_rlast),
//	.M_AXI_RUSER       (M_AXI_RUSER),
	.M_AXI_RVALID      (s_axi_rvalid),
	.M_AXI_RREADY      (s_axi_rready),
	
    .DEVICE_ID         (0),
  
    .WR_BURST_ADRS_REQ (wr_adrs_req),
    .WR_BURST_ADRS     (wr_adrs),
    .WR_BURST_LEN      (wr_len), 
    .WR_READY          (wr_ready),
    .WR_BURST_DATA_REQ (wr_data_req),
    .WR_BURST_DATA     (wr_data),
    .WR_BURST_ACK      (wr_ack),

    .RD_BURST_ADRS_REQ (rd_adrs_req),
    .RD_BURST_ADRS     (rd_adrs),
    .RD_BURST_LEN      (rd_len), 
    .RD_READY          (rd_ready),
    .RD_BURST_DATA_VAL (rd_data_val),
    .RD_BURST_DATA     (rd_data),
    
    .MODE              (mode),
	.DEBUG             ()                                         
);

mem_test#(
    .C_AXI_ID_WIDTH     (C_S_AXI_ID_WIDTH),
    .C_AXI_ADDR_WIDTH   (C_S_AXI_ADDR_WIDTH),
    .C_AXI_DATA_WIDTH   (C_S_AXI_DATA_WIDTH)
)mem_test_m0(
	.ARESETN           (aresetn),
	.ACLK              (clk),
	.SOFT_ARESETN      (soft_aresetn),
	                    
    .WR_BURST_ADRS_REQ (wr_adrs_req),
    .WR_BURST_ADRS     (wr_adrs),
    .WR_BURST_LEN      (wr_len), 
    .WR_READY          (wr_ready),
    .WR_BURST_DATA_REQ (wr_data_req),
    .WR_BURST_DATA     (wr_data),
    .WR_BURST_ACK      (wr_ack),

    .RD_BURST_ADRS_REQ (rd_adrs_req),
    .RD_BURST_ADRS     (rd_adrs),
    .RD_BURST_LEN      (rd_len), 
    .RD_READY          (rd_ready),
    .RD_BURST_DATA_VAL (rd_data_val),
    .RD_BURST_DATA     (rd_data),
    
    .init_calib_complete   (init_calib_complete),
    .mode                  (mode),
	.error                 (tg_compare_error)
); 

endmodule




