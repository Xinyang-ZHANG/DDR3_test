`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/6/30 22:20:14
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

module mem_test
#(
   parameter C_AXI_ID_WIDTH       = 4, // The AXI id width used for read and write
                                       // This is an integer between 1-16
   parameter C_AXI_ADDR_WIDTH     = 32,// This is AXI address width for all 
                                        // SI and MI slots
   parameter C_AXI_DATA_WIDTH     = 128// Width of the AXI write and read data
)
(
    // Reset, Clock
    input                             ARESETN,
    input                             ACLK,
    output                            SOFT_ARESETN,
    
    output                            WR_BURST_ADRS_REQ,
    output [C_AXI_ADDR_WIDTH-1:0]     WR_BURST_ADRS,
    output [7:0]                      WR_BURST_LEN, 
    input                             WR_READY,
    output                            WR_BURST_DATA_REQ,
    output [C_AXI_DATA_WIDTH-1:0]     WR_BURST_DATA,
    input                             WR_BURST_ACK,

    output                            RD_BURST_ADRS_REQ,
    output [C_AXI_ADDR_WIDTH-1:0]     RD_BURST_ADRS,
    output [7:0]                      RD_BURST_LEN, 
    input                             RD_READY,
    input                             RD_BURST_DATA_VAL,
    input [C_AXI_DATA_WIDTH-1:0]      RD_BURST_DATA,
    
    input                             init_calib_complete,
    output                            mode,
	output                            error
);

localparam integer P_AXSIZE =  (C_AXI_DATA_WIDTH == 32) ? 3'd2 :
                                (C_AXI_DATA_WIDTH == 64) ? 3'd3 : 
                                (C_AXI_DATA_WIDTH == 128)? 3'd4 :
                                (C_AXI_DATA_WIDTH == 256)? 3'd5 :
                                (C_AXI_DATA_WIDTH == 512)? 3'd6 : 3'd7;
    
    wire    [P_AXSIZE-1:0]                 ADDR_INCR       = 'b0;
    wire    [7:0]                          BURST_LEN;
    localparam                              RAM_ADDR_WIDTH  = C_AXI_ADDR_WIDTH - P_AXSIZE;
    localparam                              SIM_TRANSNUM    = 26'h3ff;
    localparam                              REAL_TRANSNUM   = {RAM_ADDR_WIDTH{1'b1}};
`ifdef  SIM
    localparam                              HALF_TRANSNUM   = (SIM_TRANSNUM+1)/2-1;
    localparam                              TRANSNUM        = SIM_TRANSNUM;
`else
    localparam                              HALF_TRANSNUM   = (REAL_TRANSNUM+1)/2-1;
    localparam                              TRANSNUM        = REAL_TRANSNUM;
`endif

    wire                                    soft_rst;
    wire     [2:0]                          test_mode;   //0:write all then read all, 1: write one then read one, 2: write once then read only 
                                                         //3: write only, 4: read only, 5: pingpong
    wire     [2:0]                          addr_mode;   //0: linear addr, 1: random addr(not support), 2: all 0, 3: all 1, 4: 0/1 alter
                                                          //only linear addr if BURST_LEN > 1
    wire     [2:0]                          data_mode;   //0: linear data, 1: random data(not support), 2: all 0, 3: all 1, 4: 0/1 alter
   
(*mark_debug="true"*)wire                  rst      = (~ARESETN | soft_rst) || ~init_calib_complete;
(*mark_debug="true"*)wire                  start;
    wire                                    start_d0;
    reg                                     start_d1           = 0;
    reg                                     start_d2           = 0;
    
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
    
`ifdef  SIM
    reg                                      soft_rst_reg        = 0;
    reg                                      start_reg           = 0;
   
    initial begin
        #67
        soft_rst_reg     <= 1'b1;
        #232
        soft_rst_reg     <= 1'b0;
       
        #110000
        start_reg        <= 1'b1;
        #87
        start_reg        <= 1'b0;
    end
   
    assign   soft_rst    = soft_rst_reg;
    assign   test_mode   = 3'd5;
    assign   addr_mode   = 3'd0;
    assign   data_mode   = 3'd0;
    assign   start_d0    = start_reg;
    assign   BURST_LEN   = 7;//7
    assign   mode        = 0;
`else
    vio_0    vio_0(
        .clk         (ACLK),
        .probe_in0   (timer_wr_r),
        .probe_in1   (timer_rd_r),
        .probe_in2   (timer_rdvld_r),
        .probe_out0  (soft_rst),
        .probe_out1  (test_mode),
        .probe_out2  (addr_mode),
        .probe_out3  (data_mode),
        .probe_out4  (mode     ),   //mode0: wait bresp and add gap in between 2 rd; mode1: outstanding
        .probe_out5  (start_d0 ),
        .probe_out6  (BURST_LEN)
    );
`endif

assign  SOFT_ARESETN    = ~soft_rst;

(*mark_debug="true"*)reg    [1:0]                   wr_state;
(*mark_debug="true"*)reg    [1:0]                   rd_state;
                      reg    [7:0]                   wr_burst_cnt;
                      reg                            wr_burst_ack_r;
                      reg    [7:0]                   rd_burst_cnt;
                      reg    [RAM_ADDR_WIDTH-1:0]    wr_cnt;
                      reg    [RAM_ADDR_WIDTH-1:0]    wr_cmp_cnt;
                      reg    [RAM_ADDR_WIDTH-1:0]    rd_cnt;
                      reg                            wr_adrs_req;
                      reg                            wr_data_req;
                      reg                            rd_adrs_req;
                      reg    [RAM_ADDR_WIDTH-1:0]    wr_ack_cnt;
                      
                      reg    [C_AXI_ADDR_WIDTH-1:0]  wr_adrs;
                      reg    [C_AXI_DATA_WIDTH-1:0]  wr_data;
                      reg    [C_AXI_ADDR_WIDTH-1:0]  rd_adrs;
(*mark_debug="true"*)reg    [C_AXI_DATA_WIDTH-1:0]  wr_cmp_data;
(*mark_debug="true"*)reg    [C_AXI_DATA_WIDTH-1:0]  rd_data_r1;
(*mark_debug="true"*)reg                            rd_data_valid_r1;

(*mark_debug="true"*)wire                           wr_burst_last;
(*mark_debug="true"*)wire                           rd_burst_last;
(*mark_debug="true"*)wire                           wr_half_last;
(*mark_debug="true"*)wire                           rd_half_last;
(*mark_debug="true"*)wire                           wr_last;
(*mark_debug="true"*)wire                           rd_last;
(*mark_debug="true"*)reg                            wr_finish;
(*mark_debug="true"*)reg                            rd_finish;
    
    wire                                             rw_all_mode0         = (test_mode == 3'b000);      //only linear addr_mode
    wire                                             rw_one_mode1         = (test_mode == 3'b001);
    wire                                             w_one_r_all_mode2    = (test_mode == 3'b010);
    wire                                             w_only_mode3         = (test_mode == 3'b011);
    wire                                             r_only_mode4         = (test_mode == 3'b100);
    wire                                             pingpong_mode5       = (test_mode == 3'b101);      //only linear addr_mode

always@(posedge ACLK) begin
    start_d1    <= start_d0;
    start_d2    <= start_d1;
end
   
assign  start  = ~start_d2 & start_d1;

always@(posedge ACLK) begin
    rd_data_r1          <= RD_BURST_DATA;
    rd_data_valid_r1    <= RD_BURST_DATA_VAL;
end
    
always@(posedge ACLK) begin
	if(rst) begin
	    wr_adrs_req    <= 0;
	    wr_data_req    <= 0;
	    rd_adrs_req    <= 0;
	end else begin
	    wr_adrs_req    <= (WR_READY && (wr_state == 2'b01) && (wr_burst_cnt == 0));
	    wr_data_req    <= (WR_READY && (wr_state == 2'b01));
	    rd_adrs_req    <= (RD_READY && (rd_state == 2'b01) && (rd_burst_cnt == 0));
	end
end

always@(posedge ACLK) begin
	if(rst) begin
	    wr_burst_cnt   <= 0;
	end else if(WR_READY && (wr_state == 2'b01)) begin
	    if(wr_burst_cnt == BURST_LEN)
	        wr_burst_cnt   <= 0;
	    else
	        wr_burst_cnt   <= wr_burst_cnt + 1;
	end
end

always@(posedge ACLK) begin
	if(rst) begin
        wr_cnt  <= 0;
	end else if(WR_READY && (wr_state == 2'b01)) begin
	    if(wr_cnt == TRANSNUM)
	        wr_cnt   <= 0;
	    else
	        wr_cnt   <= wr_cnt + 1;
	end 
end

always@(posedge ACLK) begin
	if(rst) begin
	    rd_burst_cnt   <= 0;
	end else if(RD_READY && (rd_state == 2'b01)) begin
	    if(rd_burst_cnt == BURST_LEN)
	        rd_burst_cnt   <= 0;
	    else
	        rd_burst_cnt   <= rd_burst_cnt + 1;
	end
end

always@(posedge ACLK) begin
	if(rst) begin
        rd_cnt  <= 0;
	end else if(RD_READY && (rd_state == 2'b01)) begin
	    if(rd_cnt == TRANSNUM)
	        rd_cnt   <= 0;
	    else
	        rd_cnt   <= rd_cnt + 1;
	end 
end

always@(posedge ACLK) begin
	if(rst) begin
        wr_cmp_cnt  <= 0;
	end else if(RD_BURST_DATA_VAL) begin
	    if(wr_cmp_cnt == TRANSNUM)
	        wr_cmp_cnt   <= 0;
	    else
	        wr_cmp_cnt   <= wr_cmp_cnt + 1;
	end 
end

always@(posedge ACLK) begin
	if(rst) begin
        wr_burst_ack_r  <= 0;
	end else if(wr_burst_last) begin
	    wr_burst_ack_r  <= 0;
	end else if(WR_BURST_ACK) begin
	    wr_burst_ack_r  <= 1;
	end
end

always@(posedge ACLK) begin
	if(rst) begin
        wr_ack_cnt  <= 0;
	end else if(WR_BURST_ACK) begin
	    if(wr_ack_cnt == TRANSNUM-BURST_LEN)
	        wr_ack_cnt   <= 0;
	    else
	        wr_ack_cnt   <= wr_ack_cnt + BURST_LEN + 1;
	end 
end

always@(posedge ACLK) begin
	if(rst) begin
        wr_adrs    <= 0;
	end else if(WR_READY && (wr_state == 2'b01) && (wr_burst_cnt == 0)) begin
	    case(addr_mode)
	        0:         wr_adrs <= {wr_cnt,ADDR_INCR};
            //1:       wr_adrs <= {prbs_addr,ADDR_INCR};
            2:         wr_adrs <= {{RAM_ADDR_WIDTH{1'b0}}, ADDR_INCR};
            3:         wr_adrs <= {{RAM_ADDR_WIDTH{1'b1}}, ADDR_INCR};
            4:         wr_adrs <= wr_cnt[0] ? {{RAM_ADDR_WIDTH{1'b0}}, ADDR_INCR} : {{RAM_ADDR_WIDTH{1'b1}}, ADDR_INCR};
            default:   wr_adrs <= {wr_cnt,ADDR_INCR};
	    endcase 
	end 
end

always@(posedge ACLK) begin
	if(rst) begin
        wr_data    <= 0;
	end else begin
	    case(data_mode)
	        0:         wr_data <= {C_AXI_DATA_WIDTH/32{{(32-RAM_ADDR_WIDTH){1'b0}}, wr_cnt}};
            //1:       wr_data <= {C_AXI_DATA_WIDTH/32{{(32-RAM_ADDR_WIDTH){1'b0}}, prbs_addr}};
            2:         wr_data <= {C_AXI_DATA_WIDTH{1'b0}};
            3:         wr_data <= {C_AXI_DATA_WIDTH{1'b1}};
            4:         wr_data <= wr_cnt[0] ? {C_AXI_DATA_WIDTH{1'b0}} : {C_AXI_DATA_WIDTH{1'b1}};
            default:   wr_data <= {C_AXI_DATA_WIDTH/32{{(32-RAM_ADDR_WIDTH){1'b0}}, wr_cnt}};
	    endcase 
	end 
end

always@(posedge ACLK) begin
	if(rst) begin
        rd_adrs    <= 0;
	end else if(RD_READY && (rd_state == 2'b01) && (rd_burst_cnt == 0)) begin
	    case(addr_mode)
	        0:         rd_adrs <= {rd_cnt,ADDR_INCR};
            //1:       rd_adrs <= {prbs_addr,ADDR_INCR};
            2:         rd_adrs <= {{RAM_ADDR_WIDTH{1'b0}}, ADDR_INCR};
            3:         rd_adrs <= {{RAM_ADDR_WIDTH{1'b1}}, ADDR_INCR};
            4:         rd_adrs <= rd_cnt[0] ? {{RAM_ADDR_WIDTH{1'b0}}, ADDR_INCR} : {{RAM_ADDR_WIDTH{1'b1}}, ADDR_INCR};
            default:   rd_adrs <= {rd_cnt,ADDR_INCR};
	    endcase 
	end 
end

always@(posedge ACLK) begin
	if(rst) begin
        wr_cmp_data    <= 0;
	end else begin
	    case(data_mode)
	        0:         wr_cmp_data <= {C_AXI_DATA_WIDTH/32{{(32-RAM_ADDR_WIDTH){1'b0}}, wr_cmp_cnt}};
            //1:       wr_data <= {C_AXI_DATA_WIDTH/32{{(32-RAM_ADDR_WIDTH){1'b0}}, prbs_addr}};
            2:         wr_cmp_data <= {C_AXI_DATA_WIDTH{1'b0}};
            3:         wr_cmp_data <= {C_AXI_DATA_WIDTH{1'b1}};
            4:         wr_cmp_data <= wr_cmp_cnt[0] ? {C_AXI_DATA_WIDTH{1'b0}} : {C_AXI_DATA_WIDTH{1'b1}};
            default:   wr_cmp_data <= {C_AXI_DATA_WIDTH/32{{(32-RAM_ADDR_WIDTH){1'b0}}, wr_cmp_cnt}};
	    endcase 
	end 
end

assign  error               = rd_data_valid_r1 ? (wr_cmp_data != rd_data_r1) : 0;

assign  WR_BURST_ADRS_REQ   = wr_adrs_req;
assign  WR_BURST_DATA_REQ   = wr_data_req;
assign  WR_BURST_LEN        = BURST_LEN;
assign  WR_BURST_ADRS       = wr_adrs;
assign  WR_BURST_DATA       = wr_data;

assign  RD_BURST_ADRS_REQ   = rd_adrs_req;
assign  RD_BURST_LEN        = BURST_LEN;
assign  RD_BURST_ADRS       = rd_adrs;

assign  wr_burst_last   = (WR_READY && (wr_burst_ack_r|WR_BURST_ACK));//(WR_READY && (wr_burst_cnt == BURST_LEN));
assign  rd_burst_last   = (RD_READY && (rd_burst_cnt == BURST_LEN));
assign  wr_half_last    = (WR_READY && (wr_ack_cnt == HALF_TRANSNUM-BURST_LEN));
assign  rd_half_last    = (RD_READY && (rd_burst_cnt == BURST_LEN) && (rd_cnt == HALF_TRANSNUM));
assign  wr_last         = (WR_READY && (wr_ack_cnt == TRANSNUM-BURST_LEN));//(WR_READY && (wr_burst_cnt == BURST_LEN) && (wr_cnt == TRANSNUM));
assign  rd_last         = (RD_READY && (rd_burst_cnt == BURST_LEN) && (rd_cnt == TRANSNUM));

always@(posedge ACLK) begin
	if(rst) begin
	    wr_finish      <= 0;
	end else begin
	    if(rw_all_mode0) begin
	        if(wr_last)
	            wr_finish  <= 1;
	        else if(rd_state == 2'b01) 
	            wr_finish  <= 0;    //read start --> 0
	    end else if(pingpong_mode5) begin
	        if(wr_half_last)
	            wr_finish  <= 1;
	        else if(rd_state == 2'b01) 
	            wr_finish  <= 0;    //read start --> 0
	    end
	end
end

always@(posedge ACLK) begin
	if(rst) begin
	    rd_finish      <= 0;
	end else begin
	    if(rw_all_mode0) begin
	    	if(rd_last)
	            rd_finish  <= 1;
	        else if(wr_state == 2'b01) 
	            rd_finish  <= 0;    //write start --> 0
	    end else if(pingpong_mode5) begin
	        if(rd_half_last)
	            rd_finish  <= 1;
	        else if(rd_state == 2'b01) 
	            rd_finish  <= 0;    //read start --> 0
	    end
	end
end

always@(posedge ACLK) begin
	if(rst) begin
		wr_state  <= 2'b00;
	end else begin
		case(wr_state)
			2'b00:begin      //IDLE
			    if(WR_READY & start & ~r_only_mode4) begin
			        wr_state     <= 2'b01;
			    end
			end
			2'b01:begin      //WR_DATA
			    if(WR_READY && (wr_burst_cnt == BURST_LEN)) begin
			        if(rw_one_mode1)
			            wr_state     <= 2'b10;    
			        else if(wr_cnt == TRANSNUM) begin
			            wr_state     <= w_only_mode3 ? 2'b11 : 2'b10;    //write only --> finish 1 turn, start another turn  
			        end
			    end
			end
			2'b10:begin      //WR_WAIT(wait read): only 0,1,5
			    if(rw_one_mode1 & rd_burst_last) begin
		            wr_state      <= rd_last ? 2'b11 : 2'b01;    //1 wr 1 rd: at last burst, jump to state 3
		        end else if((rw_all_mode0|pingpong_mode5) & rd_finish) begin
		            wr_state      <= 2'b11;
			    end
			end
			2'b11:begin      //1 turn finished
			    if(WR_READY) begin
			        wr_state     <= w_one_r_all_mode2 ? 2'b00 : 2'b01;
			    end 
			end
			default:
				wr_state    <= 2'b00;
		endcase
	end
end

always@(posedge ACLK) begin
	if(rst) begin
		rd_state  <= 2'b00;
	end else begin
		case(rd_state)
			2'b00:begin      //IDLE
			    if(RD_READY & start & ~w_only_mode3) begin
			        rd_state     <= r_only_mode4 ? 2'b01 : 2'b10;
			    end
			end
			2'b01:begin      //RD_DATA
			    if(RD_READY && (rd_burst_cnt == BURST_LEN)) begin
			        if(rw_one_mode1)
			            rd_state     <= 2'b10;    
			        else if(rd_cnt == TRANSNUM) begin
			            rd_state     <= (w_one_r_all_mode2 | r_only_mode4) ? 2'b11 : 2'b10;    //read only --> finish 1 turn, start another turn  
			        end
			    end
			end
			2'b10:begin      //RD_WAIT(wait write): only 0,1,5(2 for start)
			    if(rw_one_mode1 & wr_burst_last) begin
		            rd_state      <= wr_last ? 2'b11 : 2'b01;    //1 wr 1 rd: at last burst, jump to state 3
		        end else if((rw_all_mode0|w_one_r_all_mode2|pingpong_mode5) & wr_finish) begin
		            rd_state      <= 2'b11;
			    end
			end
			2'b11:begin      //1 turn finished
			    if(RD_READY) begin
			        rd_state     <= 2'b01;
			    end 
			end
			default:
				rd_state    <= 2'b00;
		endcase
	end
end

//counter
   always@(posedge ACLK) begin
       if(rst) begin
           cnt_wr_en    <= 'b0;
           timer_wr_r   <= 'd0;
       end else begin
           if(WR_READY && (wr_state == 2'b01) & (wr_cnt == TRANSNUM)) begin
               cnt_wr_en    <= 'b0;
               timer_wr_r   <= cnt_wr_1ms;
           end else if(WR_READY && (wr_state == 2'b01) & (wr_cnt == 0)) begin
               cnt_wr_en    <= 'b1;
               timer_wr_r   <= timer_wr_r;
           end
       end
   end
   
   always@(posedge ACLK) begin
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
   
   always@(posedge ACLK) begin
       if(rst) begin
           cnt_rd_en    <= 'b0;
           timer_rd_r   <= 'd0;
       end else begin
           if(RD_READY && (rd_state == 2'b01) & (rd_cnt == TRANSNUM)) begin
               cnt_rd_en    <= 'b0;
               timer_rd_r   <= cnt_rd_1ms;
           end else if(RD_READY && (rd_state == 2'b01) & (rd_cnt == 0)) begin
               cnt_rd_en    <= 'b1;
               timer_rd_r   <= timer_rd_r;
           end
       end
   end
   
   always@(posedge ACLK) begin
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
   
   always@(posedge ACLK) begin
       if(rst) begin
           cnt_rdvld_en     <= 'b0;
           timer_rdvld_r    <= 'd0;
       end else begin
           if(RD_BURST_DATA_VAL & (wr_cmp_cnt == TRANSNUM)) begin
               cnt_rdvld_en     <= 'b0;
               timer_rdvld_r    <= cnt_rdvld_1ms;
           end else if(RD_BURST_DATA_VAL & (wr_cmp_cnt == 0)) begin
               cnt_rdvld_en     <= 'b1;
               timer_rdvld_r    <= timer_rdvld_r;
           end
       end
   end
   
   always@(posedge ACLK) begin
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