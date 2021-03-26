// `define	CHANNEL_IN	4
// `define CHANNEL_OUT	32
// `define	HALF_CLK	5
// `define WEIGHT_ROW 10'd3
// `define WEIGHT_COL 10'd3
// `define OUTPUT_ROW 10'd6
// `define OUTPUT_COL 10'd6

`include "para.v"

module chip_tb();

reg 											clk;
reg 											rst_n;
reg 											start;
reg												en;

reg		[`PEA_num * 8 - 1 : 0]				data_in;

reg		[99 * 8 : 0]							fin_name;	// input data file name
reg 	[99 * 8 : 0]							fout_ans_name;

reg		[7:0]									data_mem_tmp[0 : `ROW_first_layer * `COL_first_layer - 1];
reg		[`CHANNEL_IN * 8 - 1 : 0]				data_mem[0:`ROW_first_layer + 2 - 1][0:`COL_first_layer + 2 - 1];

reg		[99 * 8 : 0]							fw_name;	// weight data file name
reg		[7:0]									weight_mem_tmp[0:`TOTAL_LAYER - 1][0: `TOTAL_NUM_PARTIAL_SUM - 1][0 : 9*32*4-1];
reg		[`CHANNEL_OUT * 24 - 1 : 0]				weight_mem[0:`TOTAL_LAYER - 1][0: `TOTAL_NUM_PARTIAL_SUM - 1][0:3][0:3];

wire	[15:0]									data_out;

reg		[`CHANNEL_OUT * 24 - 1 : 0]				weight_in;

wire    [`filter_num * `PEA_num * 8 - 1 : 0]	sum;
wire											sum_reg_valid;
wire 	[`filter_num * 8 - 1 : 0]				partial_sum;
wire    [`CHANNEL_OUT * 8 - 1 : 0] 				ans;
wire    [8 - 1:0] 								OR_pxl_cnt;
wire    [2:0] 									curr_state_or_output;

//wire    [`filter_num * `PEA_num * 8 - 1 : 0]	sum_reg;

integer								fp;
integer								scan_i;
integer scan_inputs;
integer								i;
integer								j;
integer								k;
integer								c;
integer 							layer;
integer 							partial_sum_cnt;
integer 							partial_sum_cnt_w;				
integer								row;
integer								col;
integer								PEA_row;
integer								filter_col;

integer								index;
integer 							index2;				
integer 							f_out_ans [0: `TOTAL_NUM_PARTIAL_SUM - 1][0:`CHANNEL_OUT - 1];
integer 							f_out_log;
integer 							f_out;

reg     [7:0]  output_mem_tmp  [0:`TOTAL_LAYER - 1][0: `TOTAL_NUM_PARTIAL_SUM - 1][0:`CHANNEL_OUT - 1] [0:(`OUTPUT_ROW/2) * (`OUTPUT_COL/2) - 1];
reg     [7:0]  output_mem      [0:`TOTAL_LAYER - 1][0: `TOTAL_NUM_PARTIAL_SUM - 1][0:`CHANNEL_OUT - 1] [0:(`OUTPUT_ROW/2) - 1] [0:(`OUTPUT_COL/2) - 1];
reg     [7:0]  output_ans      [0:`TOTAL_LAYER - 1][0: `TOTAL_NUM_PARTIAL_SUM - 1][0:`CHANNEL_OUT - 1] [0:(`OUTPUT_ROW/2) * (`OUTPUT_COL/2) - 1];


chip chip1(
	.clk(clk),
	.rst_n(rst_n),
	.start(start),
	.data_in(data_in),
	.weight_in(weight_in),
	.sum(sum),
	.sum_reg_valid(sum_reg_valid),
	.ans(ans),
	.curr_state_or_output(curr_state_or_output),
	.OR_pxl_cnt(OR_pxl_cnt)
	//.sum_reg(sum_reg),
	//.partial_sum(partial_sum)
);
// initial begin
// 	$sdf_annotate("../rtl/chip_syn.sdf", chip1, , "gate_sim.log");
// end
initial begin
	//$dumpfile("./waveform/chip.vcd");
	//$dumpvars(0, chip_tb);
	$fsdbDumpfile("./waveform/chip_quantize_pooling_sim.fsdb");
	$fsdbDumpvars(0, chip_tb);

	// ============================================
	// READ INPUT DATA
	// ============================================
	for(i = 0; i < 4; i = i + 1) begin
		// fin_name = $sformatf("../gen_bench/input/input%0d.txt", i+1);
		// fin_name = $sformatf("../bench/input_128x128/input%0d.txt", i+1);
		fin_name = $sformatf("../bench/layer1_testdata/input_128x128/input%0d.txt", i+1);
		fp = $fopen(fin_name, "r");

		for(j = 0; j < `ROW_first_layer * `COL_first_layer; j = j + 1) begin
			scan_i = $fscanf(fp, "%h", data_mem_tmp[j]);
		end

		for(row = 0; row < `ROW_first_layer; row = row + 1) begin
			for(col = 0; col < `COL_first_layer; col = col + 1) begin
				data_mem[row][col][(i + 1) * 8 - 1 -: 8] = data_mem_tmp[`COL_first_layer * row + col];
			end
		end
		$fclose(fp);
	end

	// ============================================
	// READ WEIGHT DATA
	// ============================================
	for(layer = 0; layer < `TOTAL_LAYER; layer = layer + 1)begin
		for(partial_sum_cnt = 0; partial_sum_cnt < `TOTAL_NUM_PARTIAL_SUM; partial_sum_cnt = partial_sum_cnt + 1)begin
			for(i = 0; i < `CHANNEL_IN; i = i + 1) begin
				for(j = 0; j < `CHANNEL_OUT; j = j + 1) begin
					fw_name = $sformatf("../bench/layer%01d_testdata/weight/weight_%02d_%02d.txt", layer + 1, i+1 + (partial_sum_cnt * 4) , j+1);
					fp = $fopen(fw_name, "r");

					for(k = 0; k < 9; k = k + 1) begin
						scan_i = $fscanf(fp, "%h", weight_mem_tmp[layer][partial_sum_cnt][k + j * 9 + i * 32 * 9]);
					end
				end
			end

			for(i = 0; i < `CHANNEL_OUT; i = i + 1) begin
				for(PEA_row = 0; PEA_row < 3; PEA_row = PEA_row + 1) begin
					for(filter_col = 0; filter_col < 4; filter_col = filter_col + 1) begin
						// 9 x 32 = 288
						weight_mem[layer][partial_sum_cnt][filter_col][PEA_row][(i+1) * 24 - 1 -: 24] = 
						{	weight_mem_tmp[layer][partial_sum_cnt][i * 9 + PEA_row * 3 + filter_col * 288], 
							weight_mem_tmp[layer][partial_sum_cnt][i * 9 + PEA_row * 3 + filter_col * 288 + 1], 
							weight_mem_tmp[layer][partial_sum_cnt][i * 9 + PEA_row * 3 + filter_col * 288 + 2]
						};
					end
				end
			end

			if(layer + 1 == 1)begin
				break;
			end
		end
	end

	
	
    // ============================================
    // Read Output Ans from File
    // ============================================
    f_out = $fopen("../bench/result/output_1.txt","w");
    f_out_log = $fopen("../bench/result/output_log_1.txt", "w");
    // f_out_ans = $fopen("../gen_bench/output_ans/output_ans_01_01.txt", "r");

	for(layer = 0; layer < `TOTAL_LAYER; layer = layer + 1)begin
		for(partial_sum_cnt = 0; partial_sum_cnt < `TOTAL_NUM_PARTIAL_SUM; partial_sum_cnt = partial_sum_cnt + 1)begin
			// c stand for output channel
			for(c = 0; c < `CHANNEL_OUT; c = c + 1)
			begin
				if(layer + 1 == 1)begin	// layer1
					fout_ans_name = $sformatf("../bench/layer1_testdata/output_ans_64x64_maxpooling/output_ans_01_%02d.txt", c+1);
				end
				else if(layer + 1 == 2)begin	// layer2
					fout_ans_name = $sformatf("../bench/layer2_testdata/channel_sum/output_ans_64x64_32_set%1d_quan_plus/output_ans_%02d_%02d.txt", partial_sum_cnt + 1, partial_sum_cnt + 1, c + 1);
				end
				
				
				f_out_ans[partial_sum_cnt][c] = $fopen(fout_ans_name, "r");

				for (i = 0; i < (`OUTPUT_ROW/2) * (`OUTPUT_COL/2); i = i + 1)
				begin
					scan_inputs = $fscanf(f_out_ans[partial_sum_cnt][c], "%h", output_mem_tmp[layer][partial_sum_cnt][c][i]);
				end

				for (i = 0; i < (`OUTPUT_ROW/2); i = i + 1)
				begin
					for (j = 0; j < (`OUTPUT_COL/2); j = j + 1)
					begin
						if(layer == 0)begin
							if (i % 2 == 0) begin
								output_mem[layer][partial_sum_cnt][c][i][j] = output_mem_tmp[layer][partial_sum_cnt][c][(`OUTPUT_COL/2)*i+j];
							end
							else begin
								output_mem[layer][partial_sum_cnt][c][i][j] = output_mem_tmp[layer][partial_sum_cnt][c][(`OUTPUT_COL/2)*i+j];
							end
						end
						else begin
							if (i % 2 == 0) begin
								output_mem[layer][partial_sum_cnt][c][i][j] = output_mem_tmp[layer][partial_sum_cnt][c][(`OUTPUT_COL/2)*i+j];
							end
							else begin
								output_mem[layer][partial_sum_cnt][c][i][(`OUTPUT_COL/2) - j - 1] = output_mem_tmp[layer][partial_sum_cnt][c][(`OUTPUT_COL/2)*i+j];
							end
						end
						
					end
				end

				for (i = 0; i < (`OUTPUT_ROW/2); i = i + 1)
				begin
					for (j = 0; j < (`OUTPUT_COL/2); j = j + 1)
					begin
						output_ans[layer][partial_sum_cnt][c][(`OUTPUT_COL/2)*i+j] = output_mem[layer][partial_sum_cnt][c][i][j];
					end
				end

			end

			if(layer + 1 == 1)begin
			  	break;
			end
		end

		
	end
	

    


    

	clk = 0;
	start = 0;
	rst_n = 1;
	@(posedge clk)
	#3 rst_n = 0;

	#2 rst_n = 1;

	#1
	start = 1;

    // Weight1 = weight_mem[0][0];
    // Weight2 = weight_mem[1][0];
    // Weight3 = weight_mem[2][0];
    // Weight4 = weight_mem[0][1];
    // Weight5 = weight_mem[1][1];
    // Weight6 = weight_mem[2][1];
    // Weight7 = weight_mem[0][2];
    // Weight8 = weight_mem[1][2];
    // Weight9 = weight_mem[2][2];

	// ============================================
	// Simulate data output from DRAM (already sorted)
	// ============================================
	row = 0;
	index = 0;
	index2 = 0;

	@(posedge clk)
	/*@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[0][0]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[1][0]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[0][1]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[1][1]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[0][2]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[1][2]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[0][3]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[1][3]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[0][4]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[1][4]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[0][5]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[1][5]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[2][5]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[2][4]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[2][3]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[2][2]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[2][1]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[2][0]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[3][0]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[3][1]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[3][2]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[3][3]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[3][4]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[3][5]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[4][5]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[4][4]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[4][3]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[4][2]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[4][1]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[4][0]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[5][0]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[5][1]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[5][2]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[5][3]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[5][4]};
	@(posedge clk)
	data_in = {{28{8'd0}}, data_mem[5][5]};*/

	// First Right Shifting
	for(col = 0; col < `COL_first_layer; col = col + 1) begin
		for(row = 0; row < 2; row = row + 1) begin
			@(posedge clk)
			data_in = #1 {{28{8'd0}}, data_mem[row][col]};
		end
	end
	for(row = 2; row < `ROW_first_layer; row = row + 1) begin
		// Left shifting
		if(row % 2 == 0) begin
			for(col = `COL_first_layer - 1; col >= 0; col = col - 1) begin
				@(posedge clk)
				data_in = #1 {{28{8'd0}}, data_mem[row][col]};
			end
		end
		// Right Shifting
		else begin
			for(col = 0; col < `COL_first_layer; col = col + 1) begin
				@(posedge clk)
				data_in = #1 {{28{8'd0}}, data_mem[row][col]};
			end
		end
	end

	
end

initial begin
	while(1)begin
		@(posedge clk)
		if(chip1.sram_module.controller.curr_layer == 1)begin
			if (curr_state_or_output == 4) begin
				for(c = 0; c < `CHANNEL_OUT; c = c + 1)begin
					// output_ans[0][0], first 0 -> layer 0, second 0 -> partial sum 0
					write_to_file(ans[(c + 1) * 8 - 1 -: 8], output_ans[0][0][c][index], 1, 0);
				end
				index = index + 1;
			end
		end
		else if(chip1.sram_module.controller.curr_layer == 2) begin
			if (sum_reg_valid && chip1.sram_module.controller.CCM_en && chip1.sram_module.controller.curr_state_FSM != 6) begin
				for(c = 0; c < `CHANNEL_OUT; c = c + 1)begin
					write_to_file(chip1.partial_sum[(c + 1) * 8 - 1 -: 8], 
								output_ans[1][chip1.sram_module.controller.partial_sum_index][c][index2], 
								2,
								chip1.sram_module.controller.partial_sum_index);
				end
				index2 = index2 + 1;

				if(index2 == 4096)begin
					index2 = 0;
				end
			end
		end
	end

	
end

initial begin
	#1500000
	$finish;
end

initial begin
	// #250000
	// $finish;
	while (1) begin
		@(posedge clk)
		if(chip1.sram_module.controller.curr_layer == 2 && chip1.sram_module.controller.partial_sum_index > 7)begin
			$finish;
		end
	end
end

initial begin
	// load layer 1 weight
	#9
	@(posedge clk)
	for(filter_col = 0; filter_col < 4; filter_col = filter_col + 1) begin
		for(PEA_row = 0; PEA_row < 3; PEA_row = PEA_row + 1) begin
			@(posedge clk)
			// weight_mem[0] -> 0 means layer 1
			weight_in = #1 weight_mem[0][0][filter_col][PEA_row];
			// $display("%h", weight_in);
		end
	end
end

initial begin
	// load layer 2 weight
	while(1)begin
		@(posedge clk)
		if(chip1.sram_module.controller.max_pooling_out_cnt == 4096 || (chip1.sram_module.controller.curr_layer == 2 && chip1.sram_module.controller.partial_sum_CCM_output_cnt == 4095))begin
			for(filter_col = 0; filter_col < 4; filter_col = filter_col + 1) begin
				for(PEA_row = 0; PEA_row < 3; PEA_row = PEA_row + 1) begin
					@(posedge clk)
					// weight_mem[1] -> 1 means layer 2
					weight_in = #1 weight_mem[1][chip1.sram_module.controller.partial_sum_index][filter_col][PEA_row];
					// $display("%h", weight_in);
				end
			end
		end
	end
end

always #`HALF_CLK clk = ~clk;

task write_to_file (
    input   [7:0]  sum_reg, 
    input   [7:0]  output_ans,
	input   [1:0]  curr_layer,
	input   [2:0]  curr_partial_sum_index
);

begin
    $fwrite(f_out, "%h\n", sum_reg);
	if(curr_layer == 1)begin
		if (sum_reg == output_ans)
		begin
			$fwrite(f_out_log, "LAYER 1 ========= # %0d : Correct ! =========, time is %0t\n", index, $time);
			$display("LAYER 1 ========= # %0d : Correct ! =========, time is %0t", index, $time);
		end
		else
		begin
			$fwrite(f_out_log, "LAYER 1 # %0d : [ Output : %h, Answer : %h ]\n", index, sum_reg, output_ans);
			$display("LAYER 1 # %0d : [ Output : %h, Answer : %h ]", index, sum_reg, output_ans);
			$fwrite(f_out_log, "LAYER 1 ========= # %0d : Wrong ! =========, time is %0t\n", index, $time);
			$display("LAYER 1 ========= # %0d : Wrong ! =========, time is %0t", index, $time);
		end
	end
	else if(curr_layer == 2)begin
		if (sum_reg == output_ans)
		begin
			$fwrite(f_out_log, "LAYER 2, partial sum %d ========= # %0d : Correct ! =========, time is %0t\n", curr_partial_sum_index, index2, $time);
			$display("LAYER 2, partial sum %d ========= # %0d : Correct ! =========, time is %0t", curr_partial_sum_index, index2, $time);
		end
		else
		begin
			$fwrite(f_out_log, "LAYER 2, partial sum %d, # %0d : [ Output : %h, Answer : %h ]\n", curr_partial_sum_index, index2, sum_reg, output_ans);
			$display("LAYER 2, partial sum %d, # %0d : [ Output : %h, Answer : %h ]", curr_partial_sum_index, index2, sum_reg, output_ans);
			$fwrite(f_out_log, "LAYER 2 , partial sum %d ========= # %0d : Wrong ! =========, time is %0t\n", curr_partial_sum_index, index2, $time);
			$display("LAYER 2 , partial sum %d ========= # %0d : Wrong ! =========, time is %0t", curr_partial_sum_index, index2, $time);
		end
	end
    
end

endtask

endmodule
