`timescale 1ns / 1ps
module ddr_app_module (
 
    input                     										i_sys_clk,										//时钟
    input                     										i_sys_rst,										//复位		
    input                     										init_calib_complete,							//DDR3初始完成					
    input                     										app_rdy,										//app_rdy		
    output  	reg   		[ 2 : 0 ]       						app_cmd,										//读写命令		
    output  	reg               									app_en,											//地址en	
    output  	reg   		[ 28 : 0 ]      						app_addr,										//操作地址		
    input                     										app_wdf_rdy,									//app_wdf_rdy			
    output  	reg               									app_wdf_end,									//app_wdf_end			
    output  	reg               									app_wdf_wren,									//写数据有效en			
    output  	reg      	[ 127 : 0 ]     						app_wdf_data,									//写数据		
    output                  [ 15  : 0 ]                             app_wdf_mask,
    input         			[ 127 : 0 ]     						app_rd_data,									//读数据			
	input                     										app_rd_data_valid                               //读数据有效
    );
				localparam											TEST_LEN					= 16'd1023;
				reg			[ 28 : 0 ]								write_addr;
				reg			[ 28 : 0 ]								read_addr;
				reg													app_write_req;
				reg													app_write_req_r0;
				reg													app_write_req_r1;
				reg													write_data_en;
				reg													app_read_req;
				reg													app_read_req_r0;
				reg													app_read_req_r1;
				reg													read_data_en;
				reg			[15 : 0 ]								write_addr_cnt;
				reg			[15 : 0 ]								write_data_cnt;
				reg			[15 : 0 ]								read_addr_cnt;
				reg			[15 : 0 ]								read_data_cnt;
				
assign  app_wdf_mask = 0;
				
always @ ( posedge i_sys_clk ) begin																				//写数据请求
	if ( init_calib_complete == 1'b0 ) begin
		app_write_req	 <= 1'b0;
		app_write_req_r0 <= 1'b0;
		app_write_req_r1 <= 1'b0;
	end else begin
		app_write_req_r0 <= init_calib_complete;
		app_write_req_r1 <= app_write_req_r0;
		app_write_req 	 <= app_write_req_r0 & ( ~app_write_req_r1 );
	end
end
always @ ( posedge i_sys_clk ) begin																				//写数据en
	if ( init_calib_complete == 1'b0 ) begin
		write_data_en <= 1'b0;
	end else begin 
		if ( app_write_req == 1'b1 ) begin
			write_data_en <= 1'b1;
		end else begin
			if ( write_addr_cnt == TEST_LEN && app_rdy == 1'b1 ) begin
				write_data_en <= 1'b0;
			end else begin
				write_data_en <= write_data_en;
			end
		end
	end
end
always @ ( posedge i_sys_clk ) begin																				//读数据请求
	if ( init_calib_complete == 1'b0 ) begin
		app_read_req	<= 1'b0;
		app_read_req_r0 <= 1'b0;
		app_read_req_r1 <= 1'b0;
	end else begin
		app_read_req_r0 <= write_data_en;
		app_read_req_r1 <= app_read_req_r0;
		app_read_req 	<= app_read_req_r1 & ( ~app_read_req_r0 );
	end
end
always @ ( posedge i_sys_clk ) begin																				//读数据en
	if ( init_calib_complete == 1'b0 ) begin
		read_data_en <= 1'b0;
	end else begin 
		if ( app_read_req == 1'b1 ) begin
			read_data_en <= 1'b1;
		end else begin
			if ( read_addr_cnt == TEST_LEN && app_rdy == 1'b1 ) begin
				read_data_en <= 1'b0;
			end else begin
				read_data_en <= read_data_en;
			end
		end
	end
end
always @ ( posedge i_sys_clk ) begin																				//app_en信号产生
	if ( init_calib_complete == 1'b0 ) begin
		app_en <= 1'b0;
	end else begin 
		if ( app_write_req == 1'b1 || app_read_req == 1'b1 ) begin
			app_en <= 1'b1;
		end else begin
			if ( ( write_addr_cnt == TEST_LEN ||  read_addr_cnt == TEST_LEN ) && app_rdy == 1'b1  ) begin
				app_en <= 1'b0;
			end else begin
				app_en <= app_en;
			end
		end
	end
end
always @ ( posedge i_sys_clk ) begin																				//app_amd命令产生
	if ( init_calib_complete == 1'b0 ) begin
		app_cmd <= 3'b000;
	end else begin 
		if ( read_addr_cnt == TEST_LEN && app_rdy == 1'b1 ) begin
			app_cmd <= 3'b000;
		end else begin
			if ( app_read_req == 1'b1 ) begin
				app_cmd <= 3'b001;
			end else begin
				app_cmd <= app_cmd;
			end
		end
	end
end
always @ ( posedge i_sys_clk ) begin																				//写数据地址
	if ( init_calib_complete == 1'b0 ) begin
		write_addr <= 30'h0;
	end else begin 
		if ( write_data_en == 1'b1 && app_rdy == 1'b1 ) begin
			write_addr <= write_addr + 4'h8;
		end else begin
			if ( write_addr_cnt == TEST_LEN && app_rdy == 1'b1 ) begin
				write_addr <= write_addr + 4'h8;
			end else begin
				write_addr <= write_addr;
			end
		end
	end
end
always @ ( posedge i_sys_clk ) begin																				//读数据地址
	if ( init_calib_complete == 1'b0 ) begin
		read_addr <= 30'h0;
	end else begin 
		if ( read_data_en == 1'b1 && app_rdy == 1'b1 ) begin
			read_addr <= read_addr + 4'h8;
		end else begin
			if ( read_addr_cnt == TEST_LEN && app_rdy == 1'b1 ) begin
				read_addr <= read_addr + 4'h8;
			end else begin
				read_addr <= read_addr;
			end
		end
	end
end
always @ ( posedge i_sys_clk ) begin																				//app_addr数据地址
	if ( init_calib_complete == 1'b0 ) begin
		app_addr <= 30'h0;
	end else begin 
		if ( app_write_req == 1'b1 ) begin
			app_addr <= write_addr;
		end else begin
			if ( app_read_req == 1'b1 ) begin
				app_addr <= read_addr;
			end else begin
				if ( write_data_en == 1'b1 && app_rdy == 1'b1 ) begin
					app_addr <= write_addr + 4'h8;
				end else begin
					if ( read_data_en == 1'b1 && app_rdy == 1'b1 ) begin
						app_addr <= read_addr + 4'h8;
					end else begin
						app_addr <= app_addr;
					end
				end
			end
		end
	end
end
always @ ( posedge i_sys_clk ) begin																				//写地址计数器
	if ( init_calib_complete == 1'b0 ) begin
		write_addr_cnt <= 8'd0;
	end else begin 
		if( write_addr_cnt == TEST_LEN && app_rdy == 1'b1 ) begin
			write_addr_cnt <= 8'd0;
		end else begin
			if ( write_data_en == 1'b1 && app_rdy == 1'b1 ) begin
				write_addr_cnt <= write_addr_cnt + 1'b1;
			end else begin
				write_addr_cnt <= write_addr_cnt;
			end
		end
	end
end
always @ ( posedge i_sys_clk ) begin																				//读地址计数器
	if ( init_calib_complete == 1'b0 ) begin
		read_addr_cnt <= 8'd0;
	end else begin 
		if( read_addr_cnt == TEST_LEN && app_rdy == 1'b1 ) begin
			read_addr_cnt <= 8'd0;
		end else begin
			if ( read_data_en == 1'b1 && app_rdy == 1'b1 ) begin
				read_addr_cnt <= read_addr_cnt + 1'b1;
			end else begin
				read_addr_cnt <= read_addr_cnt;
			end
		end
	end
end
always @ ( posedge i_sys_clk ) begin																				//写数据有效
	if ( init_calib_complete == 1'b0 ) begin
		app_wdf_wren <= 1'b0;
	end else begin 
		if ( write_addr_cnt == TEST_LEN && app_wdf_rdy == 1'b1 ) begin
			app_wdf_wren <= 1'b0;
		end else begin
			if ( app_write_req == 1'b1 ) begin
				app_wdf_wren <= 1'b1;
			end else begin
				app_wdf_wren <= app_wdf_wren;
			end
		end
	end
end
always @ ( posedge i_sys_clk ) begin																				//app_wdf_end == app_wdf_wren
	if ( init_calib_complete == 1'b0 ) begin
		app_wdf_end <= 1'b0;
	end else begin 
		if ( write_addr_cnt == TEST_LEN && app_wdf_rdy == 1'b1 ) begin
			app_wdf_end <= 1'b0;
		end else begin
			if ( app_write_req == 1'b1 ) begin
				app_wdf_end <= 1'b1;
			end else begin
				app_wdf_end <= app_wdf_end;
			end
		end
	end
end
always @ ( posedge i_sys_clk ) begin																				//产生写入的数据
	if ( i_sys_rst == 1'b0 ) begin
		app_wdf_data <= 128'h0;
	end else begin
		if ( app_wdf_rdy == 1'b1 && app_wdf_wren == 1'b1 ) begin
			app_wdf_data <= app_wdf_data + 1'b1;
		end else begin
			app_wdf_data <= app_wdf_data;
		end
	end
end
always @ ( posedge i_sys_clk ) begin																				//写数据计数器
	if ( i_sys_rst == 1'b0 ) begin
		write_data_cnt <= 8'd0;
	end else begin
		if ( write_data_cnt == TEST_LEN && app_wdf_rdy == 1'b1 ) begin
			write_data_cnt <= 8'd0;
		end else begin
			if ( app_wdf_wren == 1'b1 && app_wdf_rdy == 1'b1 ) begin
				write_data_cnt <= write_data_cnt + 1'b1;
			end else begin
				write_data_cnt <= write_data_cnt;
			end
		end
	end
end
always @ ( posedge i_sys_clk ) begin																				//读数据计数器
	if ( i_sys_rst == 1'b0 ) begin
		read_data_cnt <= 8'd0;
	end else begin
		if ( read_data_cnt == TEST_LEN && app_rdy == 1'b1 ) begin
			read_data_cnt <= 8'd0;
		end else begin
			if ( app_rd_data_valid == 1'b1 ) begin
				read_data_cnt <= read_data_cnt + 1'b1;
			end else begin
				read_data_cnt <= read_data_cnt;
			end
		end
	end
end
endmodule