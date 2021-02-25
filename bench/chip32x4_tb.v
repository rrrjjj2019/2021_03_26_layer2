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
reg		[7:0]									data_mem_tmp[0 : `ROW_first_layer * `COL_first_layer - 1];
reg		[`CHANNEL_IN * 8 - 1 : 0]				data_mem[0:`ROW_first_layer + 2 - 1][0:`COL_first_layer + 2 - 1];

reg		[99 * 8 : 0]							fw_name;	// weight data file name
reg		[7:0]									weight_mem_tmp[0 : 9*32*4-1];
reg		[`CHANNEL_OUT * 24 - 1 : 0]				weight_mem[0:3][0:3];

wire	[15:0]									data_out;

reg		[`CHANNEL_OUT * 24 - 1 : 0]				weight_in;

wire    [`filter_num * `PEA_num * 8 - 1 : 0]	sum;
wire											sum_reg_valid;
//wire    [`filter_num * `PEA_num * 8 - 1 : 0]	sum_reg;

integer								fp;
integer								scan_i;
integer scan_inputs;
integer								i;
integer								j;
integer								k;
integer								row;
integer								col;
integer								PEA_row;
integer								filter_col;

integer								index;
integer f_out_ans;
integer f_out_log;
integer f_out;
reg     [7:0]  output_mem_tmp  [0:`OUTPUT_ROW * `OUTPUT_COL - 1];
reg     [7:0]  output_mem      [0:`OUTPUT_ROW - 1][0:`OUTPUT_COL - 1];
reg     [7:0]  output_ans      [0:`OUTPUT_ROW * `OUTPUT_COL - 1];


chip chip1(
	.clk(clk),
	.rst_n(rst_n),
	.start(start),
	.data_in(data_in),
	.weight_in(weight_in),
	.sum(sum),
	.sum_reg_valid(sum_reg_valid),
	//.sum_reg(sum_reg),
	.partial_sum()
);
// initial begin
// 	$sdf_annotate("../rtl/chip_syn.sdf", chip1, , "gate_sim.log");
// end
initial begin
	//$dumpfile("./waveform/chip.vcd");
	//$dumpvars(0, chip_tb);
	$fsdbDumpfile("./waveform/chip_quantize_sim.fsdb");
	$fsdbDumpvars(0, chip_tb);

	// ============================================
	// READ INPUT DATA
	// ============================================
	for(i = 0; i < 4; i = i + 1) begin
		// fin_name = $sformatf("../gen_bench/input/input%0d.txt", i+1);
		// fin_name = $sformatf("../bench/input_128x128/input%0d.txt", i+1);
		fin_name = $sformatf("../bench/input_128x128/input%0d.txt", i+1);
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
	for(i = 0; i < `CHANNEL_IN; i = i + 1) begin
		for(j = 0; j < `CHANNEL_OUT; j = j + 1) begin
			fw_name = $sformatf("../bench/weight/weight_%02d_%02d.txt", i+1, j+1);
			fp = $fopen(fw_name, "r");

			for(k = 0; k < 9; k = k + 1) begin
				scan_i = $fscanf(fp, "%h", weight_mem_tmp[k + j * 9 + i * 32 * 9]);
			end
		end
	end

	for(i = 0; i < `CHANNEL_OUT; i = i + 1) begin
		for(PEA_row = 0; PEA_row < 3; PEA_row = PEA_row + 1) begin
			for(filter_col = 0; filter_col < 4; filter_col = filter_col + 1) begin
				// 9 x 32 = 288
				weight_mem[filter_col][PEA_row][(i+1) * 24 - 1 -: 24] = 
				{	weight_mem_tmp[i * 9 + PEA_row * 3 + filter_col * 288], 
					weight_mem_tmp[i * 9 + PEA_row * 3 + filter_col * 288 + 1], 
					weight_mem_tmp[i * 9 + PEA_row * 3 + filter_col * 288 + 2]
				};
			end
		end
	end
	
    // ============================================
    // Read Output Ans from File
    // ============================================
    f_out = $fopen("../bench/result/output_1.txt","w");
    f_out_log = $fopen("../bench/result/output_log_1.txt", "w");
    // f_out_ans = $fopen("../gen_bench/output_ans/output_ans_01_01.txt", "r");
    f_out_ans = $fopen("../bench/aftermaxpooling(64x64)/output_ans_64x64_maxpooling/output_ans_01_01.txt", "r");

    for (i = 0; i < `OUTPUT_ROW * `OUTPUT_COL; i = i + 1)
    begin
        scan_inputs = $fscanf(f_out_ans, "%h", output_mem_tmp[i]);
    end
    for (i = 0; i < `OUTPUT_ROW; i = i + 1)
    begin
        for (j = 0; j < `OUTPUT_COL; j = j + 1)
        begin
            if (i % 2 == 0)
                output_mem[i][j] = output_mem_tmp[`OUTPUT_COL*i+j];
            else
                output_mem[i][`OUTPUT_COL-j-1] = output_mem_tmp[`OUTPUT_COL*i+j];
        end
    end
    for (i = 0; i < `OUTPUT_ROW; i = i + 1)
    begin
        for (j = 0; j < `OUTPUT_COL; j = j + 1)
        begin
            output_ans[`OUTPUT_COL*i+j] = output_mem[i][j];
        end
    end

	clk = 0;
	start = 0;
	rst_n = 0;
	@(posedge clk)
	#3 rst_n = 1;

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
			data_in = #1 {{29{8'd0}}, data_mem[row][col]};
		end
	end
	for(row = 2; row < `ROW_first_layer; row = row + 1) begin
		// Left shifting
		$display(row);
		if(row % 2 == 0) begin
			for(col = `COL_first_layer - 1; col >= 0; col = col - 1) begin
				@(posedge clk)
				data_in = #1 {{29{8'd0}}, data_mem[row][col]};
			end
		end
		// Right Shifting
		else begin
			for(col = 0; col < `COL_first_layer; col = col + 1) begin
				@(posedge clk)
				data_in = #1 {{29{8'd0}}, data_mem[row][col]};
			end
		end
	end

	while(1) begin
		@(posedge clk)
		if (sum_reg_valid) begin
			write_to_file(sum, output_ans[index]);
			index = index + 1;
		end
	end

	
end

initial begin
	#200000
	// $display("%x", data_mem[14][255]);
	$finish;
end

initial begin
	#9
	@(posedge clk)
	for(filter_col = 0; filter_col < 4; filter_col = filter_col + 1) begin
		for(PEA_row = 0; PEA_row < 3; PEA_row = PEA_row + 1) begin
			@(posedge clk)
			weight_in = #1 weight_mem[filter_col][PEA_row];
			// $display("%h", weight_in);
		end
	end
end

always #`HALF_CLK clk = ~clk;

task write_to_file (
    input   [7:0]  sum_reg, 
    input   [7:0]  output_ans
);

begin
    $fwrite(f_out, "%h\n", sum_reg);
    if (sum_reg == output_ans)
    begin
        $fwrite(f_out_log, "========= # %0d : Correct ! =========, time is %0t\n", index, $time);
        $display("========= # %0d : Correct ! =========, time is %0t", index, $time);
    end
    else
    begin
        $fwrite(f_out_log, "# %0d : [ Output : %h, Answer : %h ]\n", index, sum_reg, output_ans);
        $display("# %0d : [ Output : %h, Answer : %h ]", index, sum_reg, output_ans);
        $fwrite(f_out_log, "========= # %0d : Wrong ! =========, time is %0t\n", index, $time);
        $display("========= # %0d : Wrong ! =========, time is %0t", index, $time);
    end
end

endtask

endmodule
