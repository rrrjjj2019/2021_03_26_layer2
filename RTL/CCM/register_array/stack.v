`include "para.v"

module stack(
	input			clk,
	input			rst_n,
	input			en,
	input	[8:0]	col,
	input   [8-1:0] SIZE_maxpooling_IN,
	input	[7:0]	buf_in,
	output	[7:0]	buf_out
);

reg		[7:0]	rd_ptr1;
reg		[7:0]	wr_ptr1;
wire	[7:0]	A1;

reg		[7:0]	rd_ptr2;
reg		[7:0]	wr_ptr2;
wire	[7:0]	A2;

reg				CEN1;
reg				CEN2;
reg				WEN1;
reg				WEN2;

wire	[8:0]	col_reuse;
reg		[2:0]	curr_state;
reg		[2:0]	next_state;

reg		[8:0]	row_cnt;
reg		[8:0]	col_cnt;

reg		[7:0]	rd_ptr1_reg;
reg		[7:0]	wr_ptr1_reg;
reg		[7:0]	rd_ptr2_reg;
reg		[7:0]	wr_ptr2_reg;

wire	[7:0]	buf_out1;
wire	[7:0]	buf_out2;

assign A1 = WEN1 ? rd_ptr1 : wr_ptr1;
assign A2 = WEN2 ? rd_ptr2 : wr_ptr2;
assign buf_out = row_cnt[0] ? buf_out1 : buf_out2;

// ============================================
// Store when right-shifting (For left-shifting reuse)
// ============================================
rf_sp_stack stack1(
	.CENY(),
	.WENY(),
	.AY(),
	.DY(),
	.Q(buf_out1),
	.CLK(clk),
	.CEN(CEN1),
	.WEN(WEN1),
	.A(A1),
	.D(buf_in),
	.EMA(3'b000),
	.EMAW(2'b00),
	.EMAS(1'b0),
	.TEN(~1'b0),
	.BEN(~1'b0),
	.TCEN(),
	.TWEN(),
	.TA(),
	.TD(),
	.TQ(),
	.RET1N(~1'b0),
	.STOV(1'b0)
	);

// ============================================
// Store when left shifting (For right-shifting reuse)
// ============================================
rf_sp_stack stack2(
	.CENY(),
	.WENY(),
	.AY(),
	.DY(),
	.Q(buf_out2),
	.CLK(clk),
	.CEN(CEN2),
	.WEN(WEN2),
	.A(A2),
	.D(buf_in),
	.EMA(3'b000),
	.EMAW(2'b00),
	.EMAS(1'b0),
	.TEN(~1'b0),
	.BEN(~1'b0),
	.TCEN(),
	.TWEN(),
	.TA(),
	.TD(),
	.TQ(),
	.RET1N(~1'b0),
	.STOV(1'b0)
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

// ============================================
// State Register Control
// ============================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		curr_state <= #1 0;
	end
	else if(en) begin
		curr_state <= #1 next_state;
	end
	else begin
		curr_state <= #1 0;
	end
end

// ============================================
// Next State logic
// ============================================
always@(*) begin
	if(en) begin
		case(curr_state)
			3'd0: begin // IDLE
				next_state = 1;
			end
			3'd1: begin // FIRST RIGHT
				if(col_cnt == SIZE_maxpooling_IN - 2) begin
					next_state = 2;
				end
				else begin
					next_state = 1;
				end
			end
			3'd2: begin // PAUSE
				if(row_cnt == SIZE_maxpooling_IN - 1) begin
					next_state = 5;
				end
				else if(row_cnt[0] == 0) begin
					next_state = 3;
				end
				else begin
					next_state = 4;
				end
			end
			3'd3: begin // LEFT
				if(col_cnt == col - 4) begin
					next_state = 2;
				end
				else begin
					next_state = 3;
				end
			end
			3'd4: begin // RIGHT
				if(col_cnt == col - 4) begin
					next_state = 2;
				end
				else begin
					next_state = 4;
				end
			end
			3'd5: begin
				next_state = 5;
			end
			default: begin
				next_state = 0;
			end
		endcase
	end
	else begin
		next_state = 0;
	end
end

// ============================================
// Output Logic (stack1)
// ============================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		rd_ptr1_reg <= #1 0;
		wr_ptr1_reg <= #1 0;
	end
	else begin
		rd_ptr1_reg <= #1 rd_ptr1;
		wr_ptr1_reg <= #1 wr_ptr1;
	end
end
always@(*) begin
	case(curr_state) // synopsys parallel_case
		3'd0: begin
			CEN1 = ~1'b0;
			WEN1 = ~1'b1;
			rd_ptr1 = ~0;
			wr_ptr1 = ~0;
		end
		3'd1: begin
			CEN1 = ~1'b1;
			WEN1 = ~1'b1;
			rd_ptr1 = ~0;
			wr_ptr1 = wr_ptr1_reg + 1;
		end
		3'd2: begin
			CEN1 = ~1'b1;
			WEN1 = ~1'b0;
			rd_ptr1 = wr_ptr1_reg;
			wr_ptr1 = ~0;
		end
		3'd3: begin
			CEN1 = ~1'b1;
			WEN1 = ~1'b0;
			rd_ptr1 = rd_ptr1_reg - 1;
			wr_ptr1 = ~0;
		end
		3'd4: begin
			CEN1 = ~1'b1;
			WEN1 = ~1'b1;
			rd_ptr1 = ~0;
			wr_ptr1 = wr_ptr1_reg + 1;
		end
		default: begin
			CEN1 = ~1'b0;
			WEN1 = ~1'b0;
			rd_ptr1 = ~0;
			wr_ptr1 = ~0;
		end
	endcase
end

// ============================================
// Output Logic (stack2)
// ============================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		rd_ptr2_reg <= #1 0;
		wr_ptr2_reg <= #1 0;
	end
	else begin
		rd_ptr2_reg <= #1 rd_ptr2;
		wr_ptr2_reg <= #1 wr_ptr2;
	end
end
always@(*) begin
	case(curr_state) // synopsys parallel_case
		3'd0: begin
			CEN2 = ~1'b0;
			WEN2 = ~1'b0;
			rd_ptr2 = ~0;
			wr_ptr2 = ~0;
		end
		3'd1: begin
			CEN2 = ~1'b0;
			WEN2 = ~1'b0;
			rd_ptr2 = ~0;
			wr_ptr2 = ~0;
		end
		3'd2: begin
			CEN2 = ~1'b1;
			WEN2 = ~1'b0;
			rd_ptr2 = wr_ptr2_reg;
			wr_ptr2 = ~0;
		end
		3'd3: begin
			CEN2 = ~1'b1;
			WEN2 = ~1'b1;
			rd_ptr2 = ~0;
			wr_ptr2 = wr_ptr2 + 1;
		end
		3'd4: begin
			CEN2 = ~1'b1;
			WEN2 = ~1'b0;
			rd_ptr2 = rd_ptr2_reg - 1;
			wr_ptr2 = ~0;
		end
		default: begin
			CEN2 = ~1'b0;
			WEN2 = ~1'b0;
			rd_ptr2 = ~0;
			wr_ptr2 = ~0;
		end
	endcase
end

endmodule