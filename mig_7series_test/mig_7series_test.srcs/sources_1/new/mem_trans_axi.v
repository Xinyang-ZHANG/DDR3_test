module mem_trans_axi#(
   parameter C_AXI_ID_WIDTH       = 4, // The AXI id width used for read and write
                                       // This is an integer between 1-16
   parameter C_AXI_ADDR_WIDTH     = 32,// This is AXI address width for all 
                                        // SI and MI slots
   parameter C_AXI_DATA_WIDTH     = 128// Width of the AXI write and read data
)(
  // Reset, Clock
  input                             ARESETN,
  input                             ACLK,

  // Master Write Address
  output [C_AXI_ID_WIDTH-1:0]       M_AXI_AWID,
  output [C_AXI_ADDR_WIDTH-1:0]     M_AXI_AWADDR,
  output [7:0]                      M_AXI_AWLEN,    // Burst Length: 0-255
  output [2:0]                      M_AXI_AWSIZE,   // Burst Size: Fixed 2'b011
  output [1:0]                      M_AXI_AWBURST,  // Burst Type: Fixed 2'b01(Incremental Burst)
  output [1:0]                      M_AXI_AWLOCK,   // Lock: Fixed 2'b00
  output [3:0]                      M_AXI_AWCACHE,  // Cache: Fiex 2'b0011
  output [2:0]                      M_AXI_AWPROT,   // Protect: Fixed 2'b000
  output                            M_AXI_AWVALID,
  input                             M_AXI_AWREADY,

  // Master Write Data
  output [C_AXI_ID_WIDTH-1:0]       M_AXI_WID,
  output [C_AXI_DATA_WIDTH-1:0]     M_AXI_WDATA,
  output [C_AXI_DATA_WIDTH/8-1:0]   M_AXI_WSTRB,
  output                            M_AXI_WLAST,
  output                            M_AXI_WVALID,
  input                             M_AXI_WREADY,

  // Master Write Response
  input [C_AXI_ID_WIDTH-1:0]        M_AXI_BID,
  input [1:0]                       M_AXI_BRESP,
  input                             M_AXI_BVALID,
  output                            M_AXI_BREADY,
    
  // Master Read Address
  output [C_AXI_ID_WIDTH-1:0]       M_AXI_ARID,
  output [C_AXI_ADDR_WIDTH-1:0]     M_AXI_ARADDR,
  output [7:0]                      M_AXI_ARLEN,
  output [2:0]                      M_AXI_ARSIZE,
  output [1:0]                      M_AXI_ARBURST,
  output [1:0]                      M_AXI_ARLOCK,
  output [3:0]                      M_AXI_ARCACHE,
  output [2:0]                      M_AXI_ARPROT,
  output                            M_AXI_ARVALID,
  input                             M_AXI_ARREADY,
    
  // Master Read Data 
  input [C_AXI_ID_WIDTH-1:0]        M_AXI_RID,
  input [C_AXI_DATA_WIDTH-1:0]      M_AXI_RDATA,
  input [1:0]                       M_AXI_RRESP,
  input                             M_AXI_RLAST,
  input                             M_AXI_RVALID,
  output                            M_AXI_RREADY,
        
  // Local Bus
  input [C_AXI_ID_WIDTH-1:0]        DEVICE_ID,
  
  input                             WR_BURST_ADRS_REQ,
  input [C_AXI_ADDR_WIDTH-1:0]      WR_BURST_ADRS,
  input [7:0]                       WR_BURST_LEN, 
  output                            WR_READY,
  input                             WR_BURST_DATA_REQ,
  input [C_AXI_DATA_WIDTH-1:0]      WR_BURST_DATA,
  output                            WR_BURST_ACK,

  input                             RD_BURST_ADRS_REQ,
  input [C_AXI_ADDR_WIDTH-1:0]      RD_BURST_ADRS,
  input [7:0]                       RD_BURST_LEN, 
  output                            RD_READY,
  output                            RD_BURST_DATA_VAL,
  output [C_AXI_DATA_WIDTH-1:0]     RD_BURST_DATA,

  input                             MODE,
  output [31:0]                     DEBUG
);

    localparam  S_WR_ADDR   = 3'd0;
    localparam  S_WR_DATA   = 3'd1;
    localparam  S_WR_BACK   = 3'd2;
  
  
    reg     [2:0]                   wr_state        = S_WR_ADDR;
    
    wire                            wr_fifo_adrlen_empty    ;
    wire                            wr_fifo_adrlen_rdreq    ;
    wire                            wr_fifo_data_empty      ;
    wire                            wr_fifo_data_rdreq      ;
    reg                             wr_adrlen_valid_r       ;
    reg                             wr_data_valid_r         ;
    
    reg     [7:0]                   wr_data_cnt     ;
    wire    [3:0]                   wa_fifo_count   ;
    wire    [9:0]                   wd_fifo_count   ;
    
    syncfifo_dist_cmd   u_axi_syncfifo_dist_wcmd(
        .clk        (ACLK),
        .wr_en      (WR_BURST_ADRS_REQ),
        .din        ({WR_BURST_ADRS, WR_BURST_LEN}),
        .full       (),
        .rd_en      (wr_fifo_adrlen_rdreq),
        .dout       ({M_AXI_AWADDR, M_AXI_AWLEN}),
        .empty      (wr_fifo_adrlen_empty),
        .data_count (wa_fifo_count)
    );
    
    assign  M_AXI_AWVALID           = wr_adrlen_valid_r & ~wr_fifo_adrlen_empty & M_AXI_AWREADY;
    assign  wr_fifo_adrlen_rdreq    = M_AXI_AWVALID;
    
    syncfifo_dist_dat   u_axi_syncfifo_dist_wdat(
        .clk        (ACLK),
        .wr_en      (WR_BURST_DATA_REQ),
        .din        (WR_BURST_DATA),
        .full       (),
        .rd_en      (wr_fifo_data_rdreq),
        .dout       (M_AXI_WDATA),
        .empty      (wr_fifo_data_empty),
        .data_count (wd_fifo_count)
    );
    
    assign  M_AXI_WVALID        = wr_data_valid_r & ~wr_fifo_data_empty & M_AXI_WREADY;
    assign  wr_fifo_data_rdreq  = M_AXI_WVALID;
    assign  WR_READY            = (wd_fifo_count < 512) & (wa_fifo_count < 8);
    assign  WR_BURST_ACK        = M_AXI_BVALID;
    
always @(posedge ACLK) begin
    if(!ARESETN) begin
        wr_data_cnt             <= 8'h0;
    end else if(M_AXI_WVALID) begin
        if(wr_data_cnt == M_AXI_AWLEN)
            wr_data_cnt         <= 8'h0;
        else
            wr_data_cnt         <= wr_data_cnt + 8'h1;
    end
end
    assign  M_AXI_WLAST        = M_AXI_WVALID & (wr_data_cnt==M_AXI_AWLEN);

// Write State
always @(posedge ACLK) begin
    if(!ARESETN) begin
        wr_state                <= S_WR_ADDR;
        wr_adrlen_valid_r       <= 1'b0;
        wr_data_valid_r         <= 1'b0;
    end else begin
        case(wr_state)
            S_WR_ADDR: begin
                if(~wr_fifo_adrlen_empty & ~wr_fifo_data_empty) begin
                    wr_adrlen_valid_r       <= 1'b1;
                    wr_data_valid_r         <= 1'b1;
                    if(M_AXI_AWREADY & M_AXI_WREADY) begin
                        if(wr_data_cnt == M_AXI_AWLEN) begin
                            wr_state        <= MODE?S_WR_ADDR:S_WR_BACK;
                        end else begin
                            wr_state        <= S_WR_DATA;
                        end 
                    end
                end else begin
                    wr_adrlen_valid_r       <= 1'b0;
                    wr_data_valid_r         <= 1'b0;
                end
            end
            S_WR_DATA: begin
                wr_adrlen_valid_r           <= 1'b0;
                if(~wr_fifo_data_empty) begin
                    if(M_AXI_WREADY) begin
                        if(wr_data_cnt == M_AXI_AWLEN) begin
                            wr_state                <= MODE?S_WR_ADDR:S_WR_BACK;
                            wr_data_valid_r         <= 1'b0;
                        end else begin
                            wr_state                <= S_WR_DATA;
                            wr_data_valid_r         <= 1'b1;
                        end 
                    end else begin
                        wr_data_valid_r         <= 1'b1;
                    end
                end else begin
                    wr_data_valid_r         <= 1'b0;
                end
            end
            S_WR_BACK: begin
                wr_adrlen_valid_r       <= 1'b0;
                wr_data_valid_r         <= 1'b0;
                if(M_AXI_BVALID) begin
                    wr_state            <= S_WR_ADDR;
                end
            end
            default: begin
                wr_state                <= S_WR_ADDR;
                wr_adrlen_valid_r       <= 1'b0;
                wr_data_valid_r         <= 1'b0;
            end
        endcase
    end
end
   
generate 
    begin: awsize
        if (C_AXI_DATA_WIDTH == 1024) begin
            assign M_AXI_AWSIZE = 3'b111;
        end else if (C_AXI_DATA_WIDTH == 512) begin
            assign M_AXI_AWSIZE = 3'b110;
        end else if (C_AXI_DATA_WIDTH == 256) begin
            assign M_AXI_AWSIZE = 3'b101;
        end else if (C_AXI_DATA_WIDTH == 128) begin
            assign M_AXI_AWSIZE = 3'b100;
        end else if (C_AXI_DATA_WIDTH == 64) begin
            assign M_AXI_AWSIZE = 3'b011;
        end else begin
            assign M_AXI_AWSIZE = 3'b010;
        end
    end
endgenerate
    assign  M_AXI_AWID          = DEVICE_ID;
    assign  M_AXI_AWBURST[1:0]  = 2'b01;    //INCR
    assign  M_AXI_AWLOCK        = 2'b00;
    assign  M_AXI_AWCACHE[3:0]  = 4'b0011;  //0011: bufferable and cachable, 0000: non-bufferable and non-cachable
    assign  M_AXI_AWPROT[2:0]   = 3'b000;

    assign  M_AXI_WID           = DEVICE_ID;
    assign  M_AXI_WSTRB         = M_AXI_WVALID?{(C_AXI_DATA_WIDTH/8){1'b1}}:{(C_AXI_DATA_WIDTH/8){1'b0}};
    assign  M_AXI_BREADY        = 1'b1;
  
  //READ
  localparam  S_RD_ADDR  = 3'd0;
  localparam  S_RD_WAIT  = 3'd1;
  
  reg       [2:0]               rd_state          = S_RD_ADDR;
  
  wire                          rd_fifo_adrlen_empty  ;
  wire                          rd_fifo_adrlen_rdreq  ;
  wire                          rd_fifo_data_empty    ;
  reg                           rd_adrlen_valid_r     ;
    
  wire      [3:0]               ra_fifo_count   ;
  reg                           rd_axi_ready    ;
  reg                           rd_axi_ready_d1 ;
  
  syncfifo_dist_cmd   u_axi_syncfifo_dist_rcmd(
      .clk        (ACLK),
      .wr_en      (RD_BURST_ADRS_REQ),
      .din        ({RD_BURST_ADRS, RD_BURST_LEN}),
      .full       (),
      .rd_en      (rd_fifo_adrlen_rdreq),
      .dout       ({M_AXI_ARADDR, M_AXI_ARLEN}),
      .empty      (rd_fifo_adrlen_empty),
      .data_count (ra_fifo_count)
   );
   
    assign  M_AXI_ARVALID           = rd_adrlen_valid_r & ~rd_fifo_adrlen_empty & M_AXI_ARREADY;
    assign  rd_fifo_adrlen_rdreq    = M_AXI_ARVALID;
  
    assign  RD_READY                = (ra_fifo_count < 8);
    
  // Read State
always @(posedge ACLK) begin
    if(!ARESETN) begin
        rd_state                <= S_RD_ADDR;
        rd_adrlen_valid_r       <= 1'b0;
    end else begin
        case(rd_state)
            S_RD_ADDR: begin
                if(~rd_fifo_adrlen_empty) begin
                    if(M_AXI_ARREADY) begin
                        rd_state            <= MODE?S_RD_ADDR:S_RD_WAIT;
                        rd_adrlen_valid_r   <= 1'b1;
                    end else begin
                        rd_state            <= S_RD_ADDR;
                        rd_adrlen_valid_r   <= 1'b1;
                    end
                end else begin
                    rd_adrlen_valid_r   <= 1'b0;
                end
            end
            S_RD_WAIT: begin
                if(M_AXI_RLAST) begin
                    rd_state            <= S_RD_ADDR;
                end
                rd_adrlen_valid_r       <= 1'b0;
            end
            default: begin
                rd_state                <= S_RD_ADDR;
                rd_adrlen_valid_r       <= 1'b0;
			end
	  endcase
    end
  end
  
  always @(posedge ACLK) begin
      if(!ARESETN) begin
          rd_axi_ready      <= 1'b0;
      end else begin
          if(M_AXI_ARVALID) begin
              rd_axi_ready      <= 1'b1;
          end else if(M_AXI_RLAST) begin
              rd_axi_ready      <= 1'b0;
          end
      end
  end
   
  // Master Read Address
generate 
    begin: arsize
        if (C_AXI_DATA_WIDTH == 1024) begin
            assign M_AXI_ARSIZE = 3'b111;
        end else if (C_AXI_DATA_WIDTH == 512) begin
            assign M_AXI_ARSIZE = 3'b110;
        end else if (C_AXI_DATA_WIDTH == 256) begin
            assign M_AXI_ARSIZE = 3'b101;
        end else if (C_AXI_DATA_WIDTH == 128) begin
            assign M_AXI_ARSIZE = 3'b100;
        end else if (C_AXI_DATA_WIDTH == 64) begin
            assign M_AXI_ARSIZE = 3'b011;
        end else begin
            assign M_AXI_ARSIZE = 3'b010;
        end
    end
endgenerate
    assign M_AXI_ARID         = DEVICE_ID;
    assign M_AXI_ARBURST[1:0] = 2'b01;   //INCR
    assign M_AXI_ARLOCK       = 1'b0;
    assign M_AXI_ARCACHE[3:0] = 4'b0011;  //0011: bufferable and cachable, 0000: non-bufferable and non-cachable
    assign M_AXI_ARPROT[2:0]  = 3'b000;

    assign M_AXI_RREADY       = 1'b1;

    assign RD_BURST_DATA_VAL  = M_AXI_RVALID;
    assign RD_BURST_DATA      = M_AXI_RDATA;

    assign DEBUG[31:0] = {  M_AXI_AWLEN, M_AXI_ARLEN, 
                            wr_fifo_adrlen_empty, M_AXI_AWREADY, M_AXI_WREADY, M_AXI_BREADY, M_AXI_ARREADY, M_AXI_RREADY, WR_READY, RD_READY, 
                            wr_fifo_data_empty, wr_state[2:0], rd_fifo_adrlen_empty, rd_state[2:0]};
   
endmodule

