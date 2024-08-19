`timescale 1ps/1ps

module example_top#(
   parameter BEGIN_ADDRESS         = 32'h00000000,
   parameter END_ADDRESS           = 32'h00ffffff,
   parameter PRBS_EADDR_MASK_POS   = 32'hff000000,
   parameter ENFORCE_RD_WR         = 0,
   parameter ENFORCE_RD_WR_CMD     = 8'h11,
   parameter ENFORCE_RD_WR_PATTERN = 3'b000,
   parameter C_EN_WRAP_TRANS       = 0,
   parameter C_AXI_NBURST_TEST     = 0,
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
   parameter C_S_AXI_ID_WIDTH              = 12,
   parameter C_S_AXI_ADDR_WIDTH            = 29,
   parameter C_S_AXI_DATA_WIDTH            = 128,
   parameter C_S_AXI_SUPPORTS_NARROW_BURST = 0,
   parameter DEBUG_PORT            = "OFF",
   parameter RST_ACT_LOW           = 1
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

   input                                sys_clk_i,
   output                               tg_compare_error,
   output                               init_calib_complete,
   input                                sys_rst
);


wire                              clk;
wire                              rst;
reg                               aresetn;

wire [C_S_AXI_ID_WIDTH-1:0]       s_axi_awid;
wire [C_S_AXI_ADDR_WIDTH-1:0]     s_axi_awaddr;
wire [7:0]                        s_axi_awlen;
wire [2:0]                        s_axi_awsize;
wire [1:0]                        s_axi_awburst;
wire [0:0]                        s_axi_awlock;
wire [3:0]                        s_axi_awcache;
wire [2:0]                        s_axi_awprot;
wire                              s_axi_awvalid;
wire                              s_axi_awready;
// Slave Interface Write Data Ports
wire [C_S_AXI_DATA_WIDTH-1:0]     s_axi_wdata;
wire [(C_S_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb;
wire                              s_axi_wlast;
wire                              s_axi_wvalid;
wire                              s_axi_wready;
// Slave Interface Write Response Ports
wire                              s_axi_bready;
wire [C_S_AXI_ID_WIDTH-1:0]       s_axi_bid;
wire [1:0]                        s_axi_bresp;
wire                              s_axi_bvalid;
// Slave Interface Read Address Ports
wire [C_S_AXI_ID_WIDTH-1:0]       s_axi_arid;
wire [C_S_AXI_ADDR_WIDTH-1:0]     s_axi_araddr;
wire [7:0]                        s_axi_arlen;
wire [2:0]                        s_axi_arsize;
wire [1:0]                        s_axi_arburst;
wire [0:0]                        s_axi_arlock;
wire [3:0]                        s_axi_arcache;
wire [2:0]                        s_axi_arprot;
wire                              s_axi_arvalid;
wire                              s_axi_arready;
// Slave Interface Read Data Ports
wire                              s_axi_rready;
wire [C_S_AXI_ID_WIDTH-1:0]       s_axi_rid;
wire [C_S_AXI_DATA_WIDTH-1:0]     s_axi_rdata;
wire [1:0]                        s_axi_rresp;
wire                              s_axi_rlast;
wire                              s_axi_rvalid;

wire [11:0]                       device_temp;

  

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
       .app_sr_active                  (),
       .app_ref_ack                    (),
       .app_zq_ack                     (),
// Slave Interface Write Address Ports
       .s_axi_awid                     (s_axi_awid),
       .s_axi_awaddr                   (s_axi_awaddr),
       .s_axi_awlen                    (s_axi_awlen),
       .s_axi_awsize                   (s_axi_awsize),
       .s_axi_awburst                  (s_axi_awburst),
       .s_axi_awlock                   (s_axi_awlock),
       .s_axi_awcache                  (s_axi_awcache),
       .s_axi_awprot                   (s_axi_awprot),
       .s_axi_awqos                    (4'h0),
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
       .s_axi_arqos                    (4'h0),
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
       .sys_clk_i                       (sys_clk_i),
       .device_temp                     (device_temp),
       .sys_rst                         (sys_rst)
);

always @(posedge clk) begin
    aresetn <= ~rst;
end

mem_trans_axi#(
    .C_AXI_ID_WIDTH     (),
    .C_AXI_ADDR_WIDTH   (),
    .C_AXI_DATA_WIDTH   ()
)
u_mem_trans_axi
(
	.ARESETN           (aresetn),
	.ACLK              (clk),
	
	.M_AXI_AWID        (M_AXI_AWID),
	.M_AXI_AWADDR      (M_AXI_AWADDR),     
	.M_AXI_AWLEN       (M_AXI_AWLEN),
	.M_AXI_AWSIZE      (M_AXI_AWSIZE),
	.M_AXI_AWBURST     (M_AXI_AWBURST),
	.M_AXI_AWLOCK      (M_AXI_AWLOCK),
	.M_AXI_AWCACHE     (M_AXI_AWCACHE),
	.M_AXI_AWPROT      (M_AXI_AWPROT),
	.M_AXI_AWQOS       (M_AXI_AWQOS),
	.M_AXI_AWUSER      (M_AXI_AWUSER),
	.M_AXI_AWVALID     (M_AXI_AWVALID),
	.M_AXI_AWREADY     (M_AXI_AWREADY),
	
	.M_AXI_WDATA       (M_AXI_WDATA),
	.M_AXI_WSTRB       (M_AXI_WSTRB),
	.M_AXI_WLAST       (M_AXI_WLAST),
	.M_AXI_WUSER       (M_AXI_WUSER),
	.M_AXI_WVALID      (M_AXI_WVALID),
	.M_AXI_WREADY      (M_AXI_WREADY),
	
	.M_AXI_BID         (M_AXI_BID),
	.M_AXI_BRESP       (M_AXI_BRESP),
	.M_AXI_BUSER       (M_AXI_BUSER),
	.M_AXI_BVALID      (M_AXI_BVALID),
	.M_AXI_BREADY      (M_AXI_BREADY),
	
	.M_AXI_ARID        (M_AXI_ARID),
	.M_AXI_ARADDR      (M_AXI_ARADDR),
	.M_AXI_ARLEN       (M_AXI_ARLEN),
	.M_AXI_ARSIZE      (M_AXI_ARSIZE),
	.M_AXI_ARBURST     (M_AXI_ARBURST),
	.M_AXI_ARLOCK      (M_AXI_ARLOCK),
	.M_AXI_ARCACHE     (M_AXI_ARCACHE),
	.M_AXI_ARPROT      (M_AXI_ARPROT),
	.M_AXI_ARQOS       (M_AXI_ARQOS),
	.M_AXI_ARUSER      (M_AXI_ARUSER),
	.M_AXI_ARVALID     (M_AXI_ARVALID),
	.M_AXI_ARREADY     (M_AXI_ARREADY),
	
	.M_AXI_RID         (M_AXI_RID),
	.M_AXI_RDATA       (M_AXI_RDATA),
	.M_AXI_RRESP       (M_AXI_RRESP),
	.M_AXI_RLAST       (M_AXI_RLAST),
	.M_AXI_RUSER       (M_AXI_RUSER),
	.M_AXI_RVALID      (M_AXI_RVALID),
	.M_AXI_RREADY      (M_AXI_RREADY),
	
    .DEVICE_ID         (),
  
    .WR_BURST_ADRS_REQ (),
    .WR_BURST_ADRS     (),
    .WR_BURST_LEN      (), 
    .WR_READY          (),
    .WR_BURST_DATA_REQ (),
    .WR_BURST_DATA     (),

    .RD_BURST_ADRS_REQ (),
    .RD_BURST_ADRS     (),
    .RD_BURST_LEN      (), 
    .RD_READY          (),
    .RD_BURST_DATA_VAL (),
    .RD_BURST_DATA     (),
	.DEBUG             ()                                         
);

endmodule




