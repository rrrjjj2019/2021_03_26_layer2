`include "para.v"

module sram_controller(
	input									clk,
	input									rst_n,
	input									start,

	// ============================================
	// FSRAM1 (Real SRAM)
	// ============================================
	input 		[`CHANNEL_OUT * 8 - 1 : 0]	data_in_1,
	input 		[`CHANNEL_OUT * 16 - 1 : 0]	data_in_1_2,
	output	reg								CENA_1,
	output	reg								CENB_1,
	output	reg	[`SRAM_NUM - 1 : 0]			WENA_1,
	output	reg	[`SRAM_NUM - 1 : 0]			WENB_1,
	output	reg	[11 - 1:0]					AA_1,
	output	reg	[`SRAM_NUM * 16 - 1 : 0]	DA_1,
	output	reg	[11 - 1:0]					AB_1,
	output	reg	[`SRAM_NUM * 16 - 1 : 0]	DB_1,

	// ============================================
	// FSRAM2 (Real SRAM)
	// ============================================
	input		[`CHANNEL_OUT * 8 - 1 : 0]	data_in_2,
	input		[`CHANNEL_OUT * 16 - 1 : 0]	data_in_2_2,
	output	reg								CENA_2,
	output	reg								CENB_2,
	output	reg	[`SRAM_NUM - 1 : 0]			WENA_2,
	output	reg	[`SRAM_NUM - 1 : 0]			WENB_2,
	output	reg	[11 - 1:0]					AA_2,
	output	reg	[`SRAM_NUM * 16 - 1 : 0]	DA_2,
	output	reg	[11 - 1:0]					AB_2,
	output	reg	[`SRAM_NUM * 16 - 1 : 0]	DB_2,

	// ============================================
	// WSRAM (Real SRAM)
	// ============================================
	input		[`CHANNEL_OUT * 24 - 1 : 0]	weight_in,
	output	reg								CEN_w,
	output	reg	[`SRAM_NUM - 1 : 0]			WEN_w,
	output	reg	[4:0]						A_w,
	output	reg	[`SRAM_NUM * 72 - 1 : 0]	D_w,


	// ============================================
	// Data Process
	// 0: idle
	// 1: 3 zeros
	// 2: pad 1 zeros forward
	// 3: pad 1 zeros backward
	// 4: 1 zeros
	// 5: front data ([15 : 8])
	// 6: back data ([7 : 0])
	// ============================================
	// sram_sel1: For data process module to know which sram to be select
	// ============================================
	output 									sram_sel1,
	output 									sram_sel2,
	output 	reg [2:0]						data_process_reg,

	// ============================================
	// FSRAM ready, tell CCM start to count
	// ============================================
	output 	reg 							CCM_en,
	output 	reg								CCM_en_cnt,

	output	reg								Weight_en,
	output  reg [2:0]	                    curr_state_FSM
);

reg		[3:0]	curr_layer;

reg		[3 - 1:0]	FSM_flag;
reg		[2:0]	next_state_FSM;

// ============================================
// FSM0 
// ============================================
reg		[2 - 1:0]					curr_state_FSM0;
reg		[2 - 1:0]					next_state_FSM0;
reg		[14 - 1:0]					pxl_cnt_FSM0;

// ============================================
// FSM1 
// ============================================
reg		[4 - 1:0]					curr_state_FSM1;
reg		[4 - 1:0]					next_state_FSM1;
reg 	[14 - 1 : 0]                pxl_cnt_FSM1;
reg     [7 - 1 : 0]					col_cnt_FSM1;

// ============================================
// FSM2 
// ============================================
reg		[4 - 1:0]					curr_state_FSM2;
reg		[4 - 1:0]					next_state_FSM2;
reg 	[12 - 1:0]					pxl_cnt_FSM2;
reg 	[6 - 1:0]					col_cnt_FSM2;

// ============================================
// WSRAM
// ============================================
reg		[2:0]	curr_state_w;
reg		[2:0]	next_state_w;
reg		[4:0]	A_w_reg;
reg		[`CHANNEL_OUT * 72 - 1 : 0]	weight_in_tmp_reg;
reg		[`SRAM_NUM * 72 - 1 : 0]	D_w_reg;
reg		[`CHANNEL_OUT * 72 - 1 : 0]	weight_in_tmp;



// ============================================
// FSRAM1
// ============================================
reg		[11 - 1:0]	AA_1_reg;
reg		[11 - 1:0]	AB_1_reg;
reg 	[`CHANNEL_IN * 16 - 1 : 0]	data_in_tmp1;
reg 	[`CHANNEL_IN * 16 - 1 : 0]	data_in_tmp1_reg;
reg	    [`SRAM_NUM - 1 : 0]			RENA_1;
reg	    [`SRAM_NUM - 1 : 0]			RENB_1;

// ============================================
// FSRAM2
// ============================================
reg		[11 - 1:0]	AA_2_reg;
reg		[11 - 1:0]	AB_2_reg;
reg 	[`CHANNEL_OUT * 16 - 1 : 0]	data_in_tmp2;
reg 	[`CHANNEL_OUT * 16 - 1 : 0]	data_in_tmp2_reg;
reg		[`SRAM_NUM - 1 : 0]			RENA_2;
reg		[`SRAM_NUM - 1 : 0]			RENB_2;


// ============================================
// OTHER
// ============================================
integer								i;
reg		[2:0]	data_process;
reg 	[2:0]	ch_tiling;
reg				start_cntw;
reg		[1:0]	w_cnt;
reg		[2:0]	k_cnt;
reg		[1:0]	out_cnt;








always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		curr_layer <= 1;
	end
	else begin
		curr_layer <= curr_layer;
	end
end

assign sram_sel1 = FSM_flag[1];
// assign sram_sel2 = FSM_flag[2];
assign sram_sel2 = 0;

always@(*) begin
	if(start) begin
		if(RENA_1 == ~{32{1'b1}} || WENA_1 == ~{32{1'b1}})begin
			CENA_1 = ~1'b1;
		end
		else begin
			CENA_1 = ~1'b0;
		end
		
		if(RENB_1 == ~{32{1'b1}} || WENB_1 == ~{32{1'b1}})begin
			CENB_1 = ~1'b1;
		end
		else begin
			CENB_1 = ~1'b0;
		end

		if(RENA_2 == ~{32{1'b1}} || WENA_2 == ~{32{1'b1}})begin
			CENA_2 = ~1'b1;
		end
		else begin
			CENA_2 = ~1'b0;
		end

		if(RENB_2 == ~{32{1'b1}} || WENB_2 == ~{32{1'b1}})begin
			CENB_2 = ~1'b1;
		end
		else begin
			CENB_2 = ~1'b0;
		end
	end
	else begin
		CENA_1 = ~1'b0;
		CENB_1 = ~1'b0;
		CENA_2 = ~1'b0;
		CENB_2 = ~1'b0;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		CCM_en <= 0;
	end
	else if (curr_state_FSM1 == 1) begin
		CCM_en <= 1;
	end
	else begin
		CCM_en <= CCM_en;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		CCM_en_cnt <= 0;
	end
	else if(curr_state_FSM1 == 2 && col_cnt_FSM1 == 3) begin
		CCM_en_cnt <= 1;
	end
	else begin
		CCM_en_cnt <= CCM_en_cnt;
	end
end
// ============================================
// Finite State Machine Flag
// 0: idle
// 1: Write data from DRAM to FSRAM
// 2: Read data from FSRAM1 to CCM
// 3: Write data from CCM to FSRAM2 or RSRAM
// 4: Write data from CCM to FSRAM1 or RSRAM
// 5: Read data from FSRAM2 to CCM
// 6: Read data from FSRAM1 to regular max-pooling module
// 7: Read data from FSRAM2 to regular max-pooling module
// ============================================


// always@(*) begin
// 	FSM_flag[0] = start;
// 	FSM_flag[3] = 0;
// end

// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n) begin
// 		FSM_flag[1] <= 0;
// 	end
// 	else begin
// 		case(curr_state0) //synopsys parallel_case
// 			4'd15: begin
// 				FSM_flag[1] <= 1;
// 			end
// 			default: begin
// 				FSM_flag[1] <= 0;
// 			end
// 		endcase
// 		FSM_flag[2] <= 1;
// 	end
// end

// ============================================
// Finite State Machine Controller
// ============================================
// ============================================
// State Register
// ============================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		curr_state_FSM <= #1 0;
	end
	else if(start) begin
		curr_state_FSM <= #1 next_state_FSM;
	end
	else begin
		curr_state_FSM <= #1 0;
	end
end
// ============================================
// Next State Logic
// FSM0 -> (Write the input feature map into FSRAM1.)
// FSM1 -> (Read data from FSRAM1 and pass them to CCM.)
// FSM2 -> (Write the CCM result into FSRAM2.)
// ============================================
// ============================================
// Next State Logic
// 0 -> ALL FSM IDLE
// 1 -> ACTIVATE FSM0
// 2 -> ACTIVATE FSM0 & FSM1
// 3 -> ACTIVATE FSM0 & FSM1 & FSM2
// 4 -> ACTIVATE FSM1 & FSM2
// 5 -> ACTIVATE FSM2
// ============================================
always@(*) begin
	next_state_FSM = 0;
	case(curr_state_FSM)
		3'd0: begin
			next_state_FSM = 1;
		end
		3'd1: begin
			if(pxl_cnt_FSM0 == 2 * `COL_first_layer - 1 - 1) begin
				next_state_FSM = 2;
			end
			else begin
				next_state_FSM = 1;
			end
		end
		3'd2: begin
			if(pxl_cnt_FSM1 == 3 - 1) begin
				next_state_FSM = 3;
			end
			else begin
				next_state_FSM = 2;
			end
		end
		3'd3: begin
			if(pxl_cnt_FSM0 == `ROW_first_layer * `COL_first_layer - 1) begin
				next_state_FSM = 4;
			end
			else begin
				next_state_FSM = 3;
			end
		end
		3'd4: begin
			if(pxl_cnt_FSM1 == `COL_first_layer + 2 + `COL_first_layer * (`ROW_first_layer - 2) - 1)begin
				next_state_FSM = 5;
			end
			else begin
				next_state_FSM = 4;
			end
		end
		3'd5: begin
			if(pxl_cnt_FSM2 == `ROW_first_layer * `COL_first_layer - 1) begin
				// need to be changed after second layer implemented.
				next_state_FSM = 5;
			end
			else begin
				next_state_FSM = 5;
			end
		end
		default: begin
			next_state_FSM = 7;
		end
	endcase
end
// ============================================
// Output Logic
// ============================================
always@(*) begin
	case(curr_state_FSM)
		3'd0: begin
			FSM_flag = `ALL_FSM_IDLE;
		end
		3'd1: begin
			FSM_flag = `ALL_FSM_IDLE;
			FSM_flag[`FSM0] = 1;
		end
		3'd2: begin
			FSM_flag = `ALL_FSM_IDLE;
			FSM_flag[`FSM0] = 1;
			FSM_flag[`FSM1] = 1;
		end
		3'd3: begin
			FSM_flag = `ALL_FSM_IDLE;
			FSM_flag[`FSM0] = 1;
			FSM_flag[`FSM1] = 1;
			FSM_flag[`FSM2] = 1;
		end
		3'd4: begin
			FSM_flag = `ALL_FSM_IDLE;
			FSM_flag[`FSM1] = 1;
			FSM_flag[`FSM2] = 1;
		end
		3'd5: begin
			FSM_flag = `ALL_FSM_IDLE;
			FSM_flag[`FSM2] = 1;
		end
		default: begin
			FSM_flag = `ALL_FSM_IDLE;
		end
	endcase
end

// ============================================
// Finite State Machine 0 
// Write data from DRAM to FSRAM
// ============================================

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		pxl_cnt_FSM0 <= #1 0;
	end
	else begin
		if(FSM_flag[`FSM0])begin
			pxl_cnt_FSM0 <= #1 pxl_cnt_FSM0 + 1;
		end
		else begin
			pxl_cnt_FSM0 <= #1 0;
		end
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		curr_state_FSM0 <= #1 0;
	end
	else if(FSM_flag[`FSM0]) begin
		curr_state_FSM0 <= #1 next_state_FSM0
	end
	else begin
		curr_state_FSM0 <= #1 0;
	end
end

always@(*) begin
	next_state_FSM0 = 0;
	case(curr_state_FSM0) //synopsys parallel_case
		2'd0: begin
			if(FSM_flag[`FSM0])begin
				next_state_FSM0 = 1;
			end
			else begin
				next_state_FSM0 = 0;
			end
		end
		2'd1: begin
			next_state_FSM0 = 2;
		end
		2'd2: begin
			if(pxl_cnt_FSM0 == `ROW_first_layer * `COL_first_layer - 1) begin
				next_state_FSM0 = 3;
			end
			else begin
				next_state_FSM0 = 1;
			end
		end
		2'd3: begin
			next_state_FSM0 = 0;
		end
		default: begin
			next_state_FSM0 = curr_state_FSM0;
		end
	endcase
end

// ============================================
// Finite State Machine 1 
// Read data from FSRAM1 to CCM
// ============================================

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		curr_state_FSM1 <= #1 0;
	end
	else if(FSM_flag[`FSM1]) begin
		curr_state_FSM1 <= #1 next_state_FSM1;
	end
	else begin
		curr_state_FSM1 <= #1 0;
	end
end

always@(*) begin
	next_state_FSM1 = 0;
	case(curr_state_FSM1) //synopsys parallel_case
		4'd0: begin
			next_state_FSM1 = 1;
		end
		4'd1: begin
			if(col_cnt_FSM1 == `COL_first_layer) begin
				next_state_FSM1 = 4;
			end
			else begin
				next_state_FSM1 = 2;
			end
		end
		4'd2: begin
			if(col_cnt_FSM1 == `COL_first_layer - 1)begin
				next_state_FSM1 = 1;
			end
			else begin
				next_state_FSM1 = 2;
			end
		end
		4'd3: begin
			next_state_FSM1 = 4;
		end
		4'd4: begin
			next_state_FSM1 = 5;
		end
		4'd5: begin
			if(col_cnt_FSM1 == 2) begin
				next_state_FSM1 = 6;
			end
			else begin
				next_state_FSM1 = 4;
			end
		end
		4'd6: begin
			if(col_cnt_FSM1 == 1) begin
				next_state_FSM1 = 7;
			end
			else begin
				next_state_FSM1 = 3;
			end
		end
		4'd7: begin
			next_state_FSM1 = 8;
		end
		4'd8: begin
			next_state_FSM1 = 9;
		end
		4'd9: begin
			if(col_cnt_FSM1 == `COL_first_layer - 1)begin
				next_state_FSM1 = 6;
			end
			else begin
				next_state_FSM1 = 8;
			end
		end
		default: begin
			next_state_FSM1 = 0;
		end
	endcase
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		pxl_cnt_FSM1 <= #1 0;
	end
	else begin
		if(FSM_flag[`FSM1])begin
			pxl_cnt_FSM1 <= #1 pxl_cnt_FSM1 + 1;
		end
		else begin
			pxl_cnt_FSM1 <= #1 0;
		end
	end
end

always@(*) begin
	case(curr_state_FSM1) //synopsys parallel_case
		4'd0: begin
			col_cnt_FSM1 = 0;
		end
		4'd1: begin
			col_cnt_FSM1 = col_cnt_FSM1;
		end
		4'd2: begin
			col_cnt_FSM1 = col_cnt_FSM1 + 1;
		end
		4'd3: begin
			col_cnt_FSM1 = `COL_first_layer;
		end
		4'd4: begin
			if(col_cnt_FSM1 == `COL_first_layer)begin
				col_cnt_FSM1 = col_cnt_FSM1 - 2;
			end
			else begin
				col_cnt_FSM1 = col_cnt_FSM1 - 1;
			end
		end
		4'd5: begin
			col_cnt_FSM1 = col_cnt_FSM1 - 1;
		end
		4'd6: begin
			col_cnt_FSM1 = col_cnt_FSM1;
		end
		4'd7: begin
			col_cnt_FSM1 = 1;
		end
		4'd8: begin
			if(col_cnt_FSM1 == 1)begin
				col_cnt_FSM1 = col_cnt_FSM1 + 2;
			end
			else begin
				col_cnt_FSM1 = col_cnt_FSM1 + 1;
			end
		end
		4'd9: begin
			col_cnt_FSM1 = col_cnt_FSM1 + 1;
		end
		default: begin
			col_cnt_FSM1 = 0;
		end
	endcase
end

// ============================================
// Finite State Machine 2
// Write data from CCM to FSRAM2 or RSRAM
// ============================================

// ============================================
// Counter:
// ============================================
// Pixel
// ============================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		pxl_cnt_FSM2 <= #1 0;
	end
	else if(FSM_flag[`FSM2]) begin
		pxl_cnt_FSM2 <= #1 pxl_cnt_FSM2 + 1;
	end
	else begin
		pxl_cnt_FSM2 <= #1 0;
	end
end
// ============================================
// Col
// ============================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		col_cnt_FSM2 <= #1 `COL_second_layer - 1;
	end
	else if(FSM_flag[`FSM2]) begin
		if(col_cnt_FSM2 == 0) begin
			col_cnt_FSM2 <= #1 `COL_second_layer - 1;
		end
		else begin
			col_cnt_FSM2 <= #1 col_cnt_FSM2 - 1;
		end
	end
	else begin
		col_cnt_FSM2 <= #1 col_cnt_FSM2;
	end
end

// ============================================
// State Register
// ============================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		curr_state_FSM2 <= #1 0;
	end
	else if(FSM_flag[`FSM2]) begin
		curr_state_FSM2 <= #1 curr_state_FSM2;
	end
	else begin
		curr_state_FSM2 <= #1 0;
	end
end

// ============================================
// Next State Logic
// ============================================
always@(*) begin
	next_state_FSM2 = 0;
	case(curr_state_FSM2) //synopsys parallel_case
		4'd0: begin
			if(FSM_flag[`FSM2]) begin
				next_state_FSM2 = 1;
			end
			else begin
				next_state_FSM2 = 0;
			end
		end
		4'd1: begin
			next_state_FSM2 = 2;
		end
		4'd2: begin
			if(col_cnt_FSM2 == 0) begin
				next_state_FSM2 = 3;
			end
			else begin
				next_state_FSM2 = 1;
			end
		end
		4'd3: begin
			next_state_FSM2 = 4;
		end
		4'd4: begin
			if(col_cnt_FSM2 == 0) begin
				next_state_FSM2 = 5;
			end
			else begin
				next_state_FSM2 = 3;
			end
		end
		4'd5: begin
			next_state_FSM2 = 6;
		end
		4'd6: begin
			if(col_cnt_FSM2 == 0) begin
				next_state_FSM2 = 7;
			end
			else begin
				next_state_FSM2 = 5;
			end
		end
		4'd7: begin
			next_state_FSM2 = 8;
		end
		4'd8: begin
			if(col_cnt_FSM2 == 0) begin
				next_state_FSM2 = 5;
			end
			else begin
				next_state_FSM2 = 7;
			end
		end
		default: begin
			next_state_FSM2 = 0;
		end
	endcase
end

// ============================================
// Finite State Machine (Weight)
// ============================================

// ============================================
// Counter:
// ============================================
// weight count: Count if weight can make up a filter
// ============================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		w_cnt <= #1 0;
	end
	else if(start_cntw) begin
		if(w_cnt != 2) begin
			w_cnt <= #1 w_cnt + 1;
		end
		else begin
			w_cnt <= #1 0;
		end
	end
	else begin
		w_cnt <= #1 0;
	end
end

// ============================================
// filter count: Count if input channel is ready
// ============================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		k_cnt <= #1 0;
	end
	else if(start_cntw) begin
		if(w_cnt == 2) begin
			k_cnt <= #1 k_cnt + 1;
		end
		else begin
			k_cnt <= #1 k_cnt;
		end
	end
	else begin
		k_cnt <= #1 0;
	end
end

// ============================================
// output count: Count if PEA_filter is filled up
// ============================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_cnt <= #1 0;
	end
	else if(curr_state_w == 4) begin
		out_cnt <= #1 out_cnt + 1;
	end
	else begin
		out_cnt <= #1 0;
	end
end

// ============================================
// State Register
// ============================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		curr_state_w <= #1 0;
	end
	else if(FSM_flag[`FSM0]) begin
		curr_state_w <= #1 next_state_w;
	end
	else begin
		curr_state_w <= curr_state_w;
	end
end

// ============================================
// Next State Logic
// ============================================
always@(*) begin
	next_state_w = 0;
	case(curr_state_w)
		3'd0: begin
			if(FSM_flag[`FSM0]) begin
				next_state_w = 1;
			end
			else begin
				next_state_w = 0;
			end
		end
		3'd1: begin
			next_state_w = 2;
		end
		3'd2: begin
			next_state_w = 3;
		end
		3'd3: begin
			if(k_cnt == 3) begin
				next_state_w = 4;
			end
			else begin
				next_state_w = 1;
			end
		end
		3'd4: begin
			if(out_cnt == 3) begin
				next_state_w = 5;
			end
			else begin
				next_state_w = 4;
			end
		end
		3'd5: begin
			next_state_w = 5;
		end
		default: begin
			next_state_w = 5;
		end
	endcase
end


// ============================================
// Output Logic:
// ============================================

// ============================================
// ch_tiling // maybe have bug (4'd5)
// ============================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		ch_tiling <= #1 0;
	end
	else if(FSM_flag[`FSM0]) begin
		case(curr_state_FSM0) //synopsys parallel_case
			4'd5: begin 
				ch_tiling <= #1 ch_tiling + 1;
			end
			default: begin
				ch_tiling <= #1 ch_tiling;
			end
		endcase
	end
	else begin
		ch_tiling <= #1 0;
	end
end

// ============================================
// data_in_tmp1
// ============================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		data_in_tmp1_reg <= #1 0;
	end
	else begin
		data_in_tmp1_reg <= #1 data_in_tmp1;
	end
end
always@(*) begin
	if(FSM_flag[`FSM0]) begin
		case(curr_state_FSM0) //synopsys parallel_case
			2'd0: begin
				data_in_tmp1 = 0;
			end
			2'd1: begin
				for(i = 0; i < `CHANNEL_IN; i = i + 1) begin
					data_in_tmp1[(i + 1) * 16 - 1 -: 16] = {data_in_1[(i + 1) * 8 - 1 -: 8], data_in_tmp1_reg[(i+1) * 16 - 9 -: 8]};
				end
			end
			2'd2: begin
				for(i = 0; i < `CHANNEL_IN; i = i + 1) begin
					data_in_tmp1[(i + 1) * 16 - 1 -: 16] = {data_in_tmp1_reg[(i+1) * 16 - 1 -: 8], data_in_1[(i + 1) * 8 - 1 -: 8]};
				end
			end
			default: begin
				data_in_tmp1 = 0;
			end
		endcase
	end
	else begin
		data_in_tmp1 = 0;
	end
end

// ============================================
// WENA_1
// ============================================
always@(*) begin
	if(FSM_flag[`FSM0]) begin
		case(curr_state_FSM0) //synopsys parallel_case
			2'd1: begin
				WENA_1 = ~{32{1'b0}};
			end
			2'd2: begin
				WENA_1 = ~{32{1'b1}};
			end
			default: begin
				WENA_1 = ~{32{1'b0}};
			end
		endcase
	end
	else begin
		WENA_1 = ~{32{1'b0}};
	end
end

// ============================================
// RENA_1
// ============================================

always@(*) begin
	if(FSM_flag[`FSM0]) begin
		case(curr_state_FSM0) //synopsys parallel_case
			2'd0: begin
				RENA_1 = ~{32{1'b0}};
			end
			2'd1: begin
				RENA_1 = ~{32{1'b1}};
			end
			2'd2: begin
				RENA_1 = ~{32{1'b0}};
			end
			default: begin
				RENA_1 = ~{32{1'b0}};
			end
		endcase
	end
	else begin
		RENA_1 = ~{32{1'b0}};
	end
end

// ============================================
// RENB_1
// ============================================
always@(*) begin
	if (FSM_flag[`FSM1]) begin
		case (curr_state_FSM1)
			4'd0: begin
				RENB_1 = ~{32{1'b0}};
			end
			4'd1: begin
				RENB_1 = ~{32{1'b0}};
			end
			4'd2: begin
				RENB_1 = ~{32{1'b1}};
			end
			4'd3: begin
				RENB_1 = ~{32{1'b1}};
			end
			4'd4: begin
				RENB_1 = ~{32{1'b1}};
			end
			4'd5: begin
				RENB_1 = ~{32{1'b0}};
			end
			4'd6: begin
				RENB_1 = ~{32{1'b0}};
			end
			4'd7: begin
				RENB_1 = ~{32{1'b1}};
			end
			4'd8: begin
				RENB_1 = ~{32{1'b1}};
			end
			4'd9: begin
				RENB_1 = ~{32{1'b0}};
			end
			default: begin
				RENB_1 = ~{32{1'b0}};
			end
		endcase
	end
	else begin
		RENB_1 = ~{32{1'b0}};
	end
end

// ============================================
// RENA_2
// ============================================
always@(*) begin
	if(FSM_flag[`FSM2]) begin
		case(curr_state2) //synopsys parallel_case
			4'd0: begin
				RENA_2 = ~{32{1'b0}};
			end
			4'd1: begin
				RENA_2 = ~{32{1'b1}};
			end
			4'd2: begin
				RENA_2 = ~{32{1'b1}};
			end
			4'd3: begin
				RENA_2 = ~{32{1'b1}};
			end
			4'd4: begin
				RENA_2 = ~{32{1'b1}};
			end
			4'd5: begin
				RENA_2 = ~{32{1'b1}};
			end
			4'd6: begin
				RENA_2 = ~{32{1'b1}};
			end
			4'd7: begin
				RENA_2 = ~{32{1'b1}};
			end
			4'd8: begin
				RENA_2 = ~{32{1'b1}};
			end
		endcase
	end
	else begin
		RENA_2 = ~{32{1'b0}};
	end
end

// ============================================
// RENB_2
// ============================================
always@(*) begin
	if(FSM_flag[`FSM2]) begin
		case(curr_state_FSM2) //synopsys parallel_case
			4'd2: begin
				if(col_cnt_FSM2 == 0) begin
					RENB_2 = ~{32{1'b1}};
				end
				else begin
					// do nothing
					RENB_2 = ~{32{1'b0}};
				end
			end
			4'd3: begin
				RENB_2 = ~{32{1'b1}};
			end
			4'd4: begin
				RENB_2 = ~{32{1'b1}};
			end
			default: begin
				RENB_2 = ~{32{1'b0}};
			end
		endcase
	end
	else begin
		RENB_2 = ~{32{1'b0}};
	end
end

// ============================================
// AA_1
// ============================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		AA_1_reg <= #1 {11{1'b1}};
	end
	else begin
		AA_1_reg <= #1 AA_1;
	end
end
always@(*) begin
	if(FSM_flag[`FSM0])begin
		case(curr_state_FSM0)
			2'd0: begin
				AA_1 = {11{1'b1}};
			end
			2'd1: begin
			  	AA_1 = AA_1_reg + 1;
			end
			2'd2: begin
			  	AA_1 = AA_1_reg;
			end
			2'd3: begin
			  	AA_1 = {11{1'b1}};
			end
			default: begin
				AA_1 = {11{1'b1}};
			end
		endcase
	end
	else begin
		AA_1 = {11{1'b1}};
	end
end

// ============================================
// DA_1
// ============================================
always@(*) begin
	if(FSM_flag[`FSM0]) begin
		case(curr_state_FSM0) //synopsys parallel_case
			2'd0: begin
				DA_1 = 0;
			end
			default: begin
				DA_1 = {{28{16'd0}}, data_in_tmp1};
			end
		endcase
	end
	else begin
		DA_1 = 0;
	end
end

// ============================================
// WENB_1
// ============================================
always@(*) begin
	if(FSM_flag[`FSM1]) begin
		case(curr_state_FSM1) //synopsys parallel_case
			default: begin
				WENB_1 = ~1'b0;
			end
		endcase
	end
	else begin
		WENB_1 = ~1'b0;
	end
end

// ============================================
// AB_1
// ============================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		AB_1_reg <= #1 {11{1'b1}};
	end
	else begin
		AB_1_reg <= #1 AB_1;
	end
end
always@(*) begin
	AB_1 = {11{1'b1}};
	if (FSM_flag[`FSM1]) begin
		case (curr_state_FSM1)
			4'd0: begin
				AB_1 = {11{1'b1}};
			end
			4'd1: begin
				AB_1 = AB_1_reg;
			end
			4'd2: begin
				AB_1 = AB_1_reg + 1;
			end
			4'd3: begin
				AB_1 = AB_1_reg + 1;
			end
			4'd4: begin
				AB_1 = AB_1_reg + 1;
			end
			4'd5: begin
				AB_1 = AB_1_reg;
			end
			4'd6: begin
				AB_1 = AB_1_reg;
			end
			4'd7: begin
				AB_1 = AB_1_reg + 1;
			end
			4'd8: begin
				AB_1 = AB_1_reg + 1;
			end
			4'd9: begin
				AB_1 = AB_1_reg;
			end
			default: begin
				AB_1 = AB_1_reg;
			end
		endcase
	end
	else begin
		AB_1 = {11{1'b1}};
	end
end

// ============================================
// Data Process
// 0: idle
// 1: 3 zeros
// 2: pad 1 zeros forward
// 3: pad 1 zeros backward
// 4: 1 zeros
// 5: front data ([15 : 8])
// 6: back data ([7 : 0])
// ============================================
always@(*) begin
	if (FSM_flag[`FSM1]) begin
		case (curr_state_FSM1)
			4'd0: begin
				data_process = 0;
			end
			4'd1: begin
				data_process = 1;
			end
			4'd2: begin
				data_process = 2;
			end
			4'd3: begin
				data_process = 3;
			end
			4'd4: begin
				data_process = 5;
			end
			4'd5: begin
				data_process = 6;
			end
			4'd6: begin
				data_process = 4;
			end
			4'd7: begin
				data_process = 2;
			end
			4'd8: begin
				data_process = 5;
			end
			4'd9: begin
				data_process = 6;
			end
			default: begin
				data_process = 0;
			end
		endcase
	end
	else begin
		data_process = 0;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		data_process_reg <= #1 data_process;
	end
	else begin
		data_process_reg <= #1 data_process;
	end
end

// ============================================
// WENA_2
// ============================================
always@(*) begin
	if(FSM_flag[`FSM2]) begin
		case(curr_state2) //synopsys parallel_case
			4'd0: begin
				WENA_2 = ~{32{1'b0}};
			end
			4'd1: begin
				WENA_2 = ~{32{1'b1}};
			end
			4'd2: begin
				WENA_2 = ~{32{1'b1}};
			end
			4'd3: begin
				WENA_2 = ~{32{1'b1}};
			end
			4'd4: begin
				WENA_2 = ~{32{1'b1}};
			end
			4'd5: begin
				WENA_2 = ~{32{1'b1}};
			end
			4'd6: begin
				WENA_2 = ~{32{1'b1}};
			end
			4'd7: begin
				WENA_2 = ~{32{1'b1}};
			end
			4'd8: begin
				WENA_2 = ~{32{1'b1}};
			end
			default: begin
				WENA_2 = ~{32{1'b0}};
			end
		endcase
	end
	else begin
		WENA_2 = ~{32{1'b0}};
	end
end

// ============================================
// AA_2
// ============================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		AA_2_reg <= #1 {12{1'b1}};
	end
	else begin
		AA_2_reg <= #1 AA_2;
	end
end
always@(*) begin
	AA_2 = {11{1'b1}};
	if(FSM_flag[`FSM2]) begin
		case(curr_state_FSM2) //synopsys parallel_case
			4'd0: begin
				AA_2 = 11'd`COL_second_layer;
			end
			4'd1: begin
				AA_2 = AA_2_reg - 1;
			end
			4'd2: begin
				AA_2 = AA_2_reg - 1;
			end
			4'd3: begin
				if(col_cnt_FSM2 == `COL_second_layer - 1)begin
					AA_2 = 11'd`COL_second_layer - 1;
				end
				else begin
					AA_2 = AA_2_reg - 1;
				end
			end
			4'd4: begin
				AA_2 = AA_2_reg - 1;
			end
			4'd5: begin
				if(col_cnt_FSM2 == `COL_second_layer - 1)begin
					AA_2 = 11'd`COL_second_layer - 1;
				end
				else begin
					AA_2 = AA_2_reg + 1;
				end
			end
			4'd6: begin
				AA_2 = AA_2_reg;
			end
			4'd7: begin
				if(col_cnt_FSM2 == `COL_second_layer - 1)begin
					AA_2 = pxl_cnt_FSM2 / 2;
				end
				else begin
					AA_2 = AA_2_reg - 1;
				end
			end
			4'd8: begin
				AA_2 = AA_2_reg;
			end
			default: begin
				AA_2 = 11'd`COL_second_layer;
			end
		endcase
	end
	else begin
		AA_2 = {11{1'b1}};
	end
end

// ============================================
// WENB_2
// ============================================
always@(*) begin
	if(FSM_flag[`FSM2]) begin
		case(curr_state_FSM2) //synopsys parallel_case
			default: begin
				WENB_2 = ~{32{1'b0}};
			end
		endcase
	end
	else begin
		WENB_2 = ~{32{1'b0}};
	end
end

// ============================================
// AB_2
// ============================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		AB_2_reg <= #1 {11{1'b1}};
	end
	else begin
		AB_2_reg <= #1 AB_2;
	end
end
always@(*) begin
	if(FSM_flag[`FSM2]) begin
		case(curr_state_FSM2) //synopsys parallel_case
			4'd2: begin
				if(col_cnt_FSM2 == 0) begin
					AB_2 = `COL_second_layer - 1;
				end
				else begin
					// do nothing
					AB_2 = AB_2_reg;
				end
			end
			4'd3: begin
				AB_2 = AB_2_reg - 1;
			end
			4'd4: begin
				AB_2 = AB_2_reg - 1;
			end
			default: begin
				AB_2 = {11{1'b1}};
			end
		endcase
	end
	else begin
		AB_2 = {11{1'b1}};
	end
end

// ============================================
// data_in_tmp2
// ============================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		data_in_tmp2_reg <= #1 0;
	end
	else begin
		data_in_tmp2_reg <= #1 data_in_tmp2;
	end
end

always@(*) begin
	data_in_tmp2 = 0;
	if(FSM_flag[`FSM2]) begin
		case(curr_state_FSM2) //synopsys parallel_case
			4'd0: begin
				data_in_tmp2 = 0;
			end
			4'd1: begin
				for(i = 0; i < `CHANNEL_OUT; i = i + 1) begin
					data_in_tmp2[(i + 1) * 16 - 1 -: 16] = {data_in_2[(i + 1) * 8 - 1 -: 8], 8'd0};
				end
			end
			4'd2: begin
				for(i = 0; i < `CHANNEL_OUT; i = i + 1) begin
					data_in_tmp2[(i + 1) * 16 - 1 -: 16] = {data_in_2[(i + 1) * 8 - 1 -: 8], 8'd0};
				end
			end
			4'd3: begin
				for(i = 0; i < `CHANNEL_OUT; i = i + 1) begin
					data_in_tmp2[(i + 1) * 16 - 1 -: 16] = {data_in_2_2[(i + 1) * 16 - 1 -: 8], data_in_2[(i + 1) * 8 - 1 -: 8]};
				end
			end
			4'd4: begin
				for(i = 0; i < `CHANNEL_OUT; i = i + 1) begin
					data_in_tmp2[(i + 1) * 16 - 1 -: 16] = {data_in_2_2[(i + 1) * 16 - 1 -: 8], data_in_2[(i + 1) * 8 - 1 -: 8]};
				end
			end
			4'd5: begin
				for(i = 0; i < `CHANNEL_OUT; i = i + 1) begin
					data_in_tmp2[(i + 1) * 16 - 1 -: 16] = {data_in_2[(i + 1) * 8 - 1 -: 8], data_in_tmp2_reg[(i+1) * 16 - 9 -: 8]};
				end
			end
			4'd6: begin
				for(i = 0; i < `CHANNEL_OUT; i = i + 1) begin
					data_in_tmp2[(i + 1) * 16 - 1 -: 16] = {data_in_tmp2_reg[(i+1) * 16 - 1 -: 8], data_in_2[(i + 1) * 8 - 1 -: 8]};
				end
			end
			4'd7: begin
				for(i = 0; i < `CHANNEL_OUT; i = i + 1) begin
					data_in_tmp2[(i + 1) * 16 - 1 -: 16] = {data_in_tmp2_reg[(i+1) * 16 - 1 -: 8], data_in_2[(i + 1) * 8 - 1 -: 8]};
				end
			end
			4'd8: begin
				for(i = 0; i < `CHANNEL_OUT; i = i + 1) begin
					data_in_tmp2[(i + 1) * 16 - 1 -: 16] = {data_in_2[(i + 1) * 8 - 1 -: 8], data_in_tmp2_reg[(i+1) * 16 - 9 -: 8]};
				end
			end
			default: begin
				data_in_tmp2 = 0;
			end
		endcase
	end
	else begin
		data_in_tmp2 = 0;
	end
end

// ============================================
// start_cntw
// ============================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		start_cntw <= #1 0;
	end
	else if(FSM_flag[`FSM0]) begin
		case(curr_state_w)
			default: begin
				start_cntw <= #1 1;
			end
		endcase
	end
	else begin
		start_cntw <= #1 0;
	end
end

// ============================================
// data_io_2_1
// ============================================
always@(*) begin
	if(FSM_flag[`FSM2]) begin
		case(curr_state_FSM2) //synopsys parallel_case
			default: begin
				DA_2 = data_in_tmp2;
			end
		endcase
	end
	else begin
		DA_2 = 0;
	end
end

// ============================================
// CEN_w
// ============================================
always@(*) begin
	if(FSM_flag[`FSM0]) begin
		case(curr_state_w) //synopsys parallel_case
			3'd0: begin
				CEN_w = ~1'b0;
			end
			3'd5: begin
				CEN_w = ~1'b0;
			end
			default: begin
				CEN_w = ~1'b1;
			end
		endcase
	end
	else begin
		CEN_w = ~1'b0;
	end
end

// ============================================
// WEN_w
// ============================================
always@(*) begin
	if(FSM_flag[`FSM0]) begin
		case(curr_state_w) //synopsys parallel_case
			3'd0: begin
				WEN_w = ~{32{1'b0}};
			end
			3'd1: begin
				WEN_w = ~{32{1'b1}};
			end
			3'd2: begin
				WEN_w = ~{32{1'b1}};
			end
			3'd3: begin
				WEN_w = ~{32{1'b1}};
			end
			3'd4: begin
				WEN_w = ~{32{1'b0}};
			end
			3'd5: begin
				WEN_w = ~{32{1'b0}};
			end
			default: begin
				WEN_w = ~{32{1'b0}};
			end
		endcase
	end
	else begin
		WEN_w = ~{32{1'b1}};
	end
end

// ============================================
// A_w
// ============================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		A_w_reg <= #1 {5{1'b1}};
	end
	else begin
		A_w_reg <= #1 A_w;
	end
end
always@(*) begin
	if(FSM_flag[`FSM0]) begin
		case(curr_state_w) //synopsys parallel_case
			3'd0: begin
				A_w = A_w_reg;
			end
			3'd1: begin
				A_w = A_w_reg;
			end
			3'd2: begin
				A_w = A_w_reg;
			end
			3'd3: begin
				A_w = A_w_reg + 1;
			end
			3'd4: begin
				if(out_cnt == 0) begin
					A_w = A_w_reg - 4 + 1;
				end
				else begin
					A_w = A_w_reg + 1;
				end
			end
			3'd5: begin
				A_w = A_w_reg;
			end
			default: begin
				A_w = A_w_reg;
			end
		endcase
	end
	else begin
		A_w = A_w_reg;
	end
end

// ============================================
// weight_in_tmp
// ============================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		weight_in_tmp_reg <= #1 0;
	end
	else begin
		weight_in_tmp_reg <= #1 weight_in_tmp;
	end
end
always@(*) begin
	if(FSM_flag[`FSM0]) begin
		case(curr_state_w) //synopsys parallel_case
			3'd0: begin
				weight_in_tmp = 0;
			end
			3'd1: begin
				for(i = 0; i < `CHANNEL_OUT; i = i + 1) begin
					weight_in_tmp[(i + 1) * 72 - 1 -: 72] = {weight_in[(i + 1) * 24 - 1 -: 24], {48'd0}};
				end
			end
			3'd2: begin
				for(i = 0; i < `CHANNEL_OUT; i = i + 1) begin
					weight_in_tmp[(i + 1) * 72 - 1 -: 72] = {weight_in_tmp_reg[(i + 1) * 72 - 1 -: 24], weight_in[(i + 1) * 24 - 1 -: 24], {24'd0}};
				end
			end
			3'd3: begin
				for(i = 0; i < `CHANNEL_OUT; i = i + 1) begin
					weight_in_tmp[(i + 1) * 72 - 1 -: 72] = {weight_in_tmp_reg[(i + 1) * 72 - 1 -: 48], weight_in[(i + 1) * 24 - 1 -: 24]};
				end
			end
			default: begin
				weight_in_tmp = 0;
			end
		endcase
	end
	else begin
		weight_in_tmp = 0;
	end
end

// ============================================
// D_w
// ============================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		D_w_reg <= #1 0;
	end
	else begin
		D_w_reg <= #1 D_w;
	end
end
always@(*) begin
	if(FSM_flag[`FSM0]) begin
		case(curr_state_w) //synopsys parallel_case
			3'd3: begin
				D_w = weight_in_tmp;
			end
			default: begin
				D_w = D_w_reg;
			end
		endcase
	end
	else begin
		D_w = 0;
	end
end

// ============================================
// Weight_en
// ============================================
always@(*) begin
	Weight_en = 0;
	if(FSM_flag[`FSM0]) begin
		case(curr_state_w) //synopsys parallel_case
			3'd0: begin
				Weight_en = 0;
			end
			3'd1: begin
				Weight_en = 0;
			end
			3'd2: begin
				Weight_en = 0;
			end
			3'd3: begin
				if(k_cnt == 3) begin
					Weight_en = 1;
				end
				else begin
					Weight_en = 0;
				end
			end
			3'd4: begin
				Weight_en = 1;
			end
			3'd5: begin
				Weight_en = 1;
			end
			default: begin
				Weight_en = 1;
			end
		endcase
	end
	else begin
		Weight_en = 1;
	end
end

endmodule