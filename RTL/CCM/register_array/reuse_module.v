`include "para.v"

module reuse_module(
	input			clk,
	input			rst_n,
	input			en,
	input	[8:0]	col,
	input	[7:0]	buf_in1,
	input 	[7:0]	buf_in2,
	output	[7:0]	buf_out1,
	output	[7:0]	buf_out2
);

wire	[9:0]	col_reuse;
reg		[8:0]	rd_ptr;
reg		[8:0]	rd_ptr_reg;
reg		[8:0]	wr_ptr;
reg		[8:0]	wr_ptr_reg;
reg		[2:0]	curr_state;
reg		[2:0]	next_state;

reg		[7:0]	row_cnt;
reg		[7:0]	col_cnt;

assign col_reuse = col - 3;

register_array reg_array1(
	.clk(clk),
	.rst_n(rst_n),
	.rd_ptr(rd_ptr),
	.wr_ptr(wr_ptr),
	.data_in(buf_in1),
	.data_out(buf_out1)
);

register_array reg_array2(
	.clk(clk),
	.rst_n(rst_n),
	.rd_ptr(rd_ptr),
	.wr_ptr(wr_ptr),
	.data_in(buf_in2),
	.data_out(buf_out2)
);

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		col_cnt <= #1 ~0;
	end
	else if(en) begin
		if(col_cnt == col - 2 - 1) begin
			col_cnt <= #1 0;
		end
		else begin
			col_cnt <= #1 col_cnt + 1;
		end
	end
	else begin
		col_cnt <= #1 ~0;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		row_cnt <= #1 0;
	end
	else if(en) begin
		if(col_cnt == col - 2 - 1) begin
			row_cnt <= #1 row_cnt + 1;
		end
		else begin
			row_cnt <= #1 row_cnt;
		end
	end
	else begin
		row_cnt <= #1 0;
	end
end

// // ============================================
// // State Register Control
// // ============================================
// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n) begin
// 		curr_state <= #1 0;
// 	end
// 	else if(en) begin
// 		curr_state <= #1 next_state;
// 	end
// 	else begin
// 		curr_state <= #1 0;
// 	end
// end

// // ============================================
// // Next State logic
// // ============================================
// always@(*) begin
// 	next_state = 0;
// 	if(en) begin
// 		case(curr_state)
// 			3'd0: begin // IDLE
// 				next_state = 1;
// 			end
// 			3'd1: begin // RIGHT
// 				if(wr_ptr == col_reuse) begin
// 					next_state = 2;
// 				end
// 				else begin
// 					next_state = 1;
// 				end
// 			end
// 			3'd2: begin // PAUSE
// 				if(row_cnt == col) begin
// 					next_state = 5;
// 				end
// 				else begin
// 					next_state = 3;
// 				end
// 			end
// 			3'd3: begin // UP
// 				if(wr_ptr == col_reuse + 1) begin
// 					next_state = 4;
// 				end
// 				else begin
// 					next_state = 1;
// 				end
// 			end
// 			3'd4: begin // LEFT
// 				if(wr_ptr == 1) begin
// 					next_state = 2;
// 				end
// 				else begin
// 					next_state = 4;
// 				end
// 			end
// 			3'd5: begin // FINISH
// 			end
// 			default: begin
// 				next_state = 0;
// 			end
// 		endcase
// 	end
// 	else begin
// 		next_state = 0;
// 	end
// end


// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n) begin
// 		col_cnt <= #1 0;
// 	end
// 	else if(en) begin
// 		if(col_cnt == col_reuse + 2) begin
// 			col_cnt <= #1 0;
// 		end
// 		else begin
// 			col_cnt <= #1 col_cnt + 1;
// 		end
// 	end
// 	else begin
// 		col_cnt <= #1 0;
// 	end
// end
// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n) begin
// 		row_cnt <= #1 0;
// 	end
// 	else if(en) begin
// 		if(col_cnt == col_reuse + 2) begin
// 			row_cnt <= #1 row_cnt + 1;
// 		end
// 		else begin
// 			row_cnt <= #1 row_cnt;
// 		end
// 	end
// 	else begin
// 		row_cnt <= #1 0;
// 	end
// end

// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n) begin
// 		wr_ptr_reg <= #1 0;
// 	end
// 	else begin
// 		wr_ptr_reg <= #1 wr_ptr;
// 	end
// end
// always@(*) begin
// 	wr_ptr = ~{9{1'b0}};
// 	if(en) begin
// 		case(curr_state)
// 			3'd0: begin
// 				wr_ptr = ~{9{1'b0}};
// 			end
// 			3'd1: begin
// 				wr_ptr = wr_ptr_reg + 1;
// 			end
// 			3'd2: begin
// 				if(row_cnt[0] == 0) begin
// 					wr_ptr = wr_ptr_reg + 1;
// 				end
// 				else begin
// 					wr_ptr = wr_ptr_reg - 1;
// 				end
// 			end
// 			3'd3: begin
// 				wr_ptr = wr_ptr_reg;
// 			end
// 			3'd4: begin
// 				wr_ptr = wr_ptr_reg - 1;
// 			end
// 			3'd5: begin
// 				wr_ptr = ~{9{1'b0}};
// 			end
// 			default: begin
// 				wr_ptr = ~{9{1'b0}};
// 			end 
// 		endcase
// 	end
// 	else begin
// 		wr_ptr = ~{9{1'b0}};
// 	end
// end

// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n) begin
// 		rd_ptr_reg <= #1 col_reuse;
// 	end
// 	else begin
// 		rd_ptr_reg <= #1 rd_ptr;
// 	end
// end
// always@(*) begin
// 	rd_ptr = col_reuse;
// 	if(en) begin
// 		case(curr_state)
// 			3'd0: begin
// 				rd_ptr = col_reuse;
// 			end
// 			3'd1: begin
// 				if(row_cnt == 0) begin
// 					if(col_cnt == 4) begin
// 						rd_ptr = rd_ptr_reg - 1;
// 					end
// 					else begin
// 						rd_ptr = rd_ptr_reg;
// 					end
// 				end
// 				else if(wr_ptr == col_reuse) begin
// 					rd_ptr = rd_ptr_reg;
// 				end
// 				else begin
// 					rd_ptr = rd_ptr_reg + 1;
// 				end
// 			end
// 			3'd2: begin
// 				if(wr_ptr == col_reuse + 1) begin
// 					rd_ptr = rd_ptr_reg - 1;
// 				end
// 				else begin
// 					rd_ptr = rd_ptr_reg + 1;
// 				end
// 			end
// 			3'd3: begin
// 				if(wr_ptr == col_reuse + 1) begin
// 					rd_ptr = rd_ptr_reg - 1;
// 				end
// 				else begin
// 					rd_ptr = rd_ptr_reg + 1;
// 				end
// 			end
// 			3'd4: begin
// 				if(wr_ptr == 1) begin
// 					rd_ptr = rd_ptr_reg;
// 				end
// 				else begin
// 					rd_ptr = rd_ptr_reg - 1;
// 				end
// 			end
// 			default: begin
// 				rd_ptr = rd_ptr_reg;
// 			end
// 		endcase
// 	end
// 	else begin
// 		rd_ptr = col_reuse + 1;
// 	end
// end

endmodule