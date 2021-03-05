// `define	PEA_num		4
// `define	filter_num	32

`include "para.v"

module CCM_top(
	input											clk,
	input											rst_n,

	input											en,
	input											en_output,

	input	[8:0]									col,
	input	[8:0]									row,

	input	[`PEA_num * 8 - 1 : 0]					Data1,
	input	[`PEA_num * 8 - 1 : 0]					Data2,
	input	[`PEA_num * 8 - 1 : 0]					Data3,

	input											Weight_en,
	input	[`SRAM_NUM * 72 - 1 : 0]				Weight,
	// input	[`filter_num * `PEA_num * 8 - 1 : 0]	Weight1,
	// input	[`filter_num * `PEA_num * 8 - 1 : 0]	Weight2,
	// input	[`filter_num * `PEA_num * 8 - 1 : 0]	Weight3,
	// input	[`filter_num * `PEA_num * 8 - 1 : 0]	Weight4,
	// input	[`filter_num * `PEA_num * 8 - 1 : 0]	Weight5,
	// input	[`filter_num * `PEA_num * 8 - 1 : 0]	Weight6,
	// input	[`filter_num * `PEA_num * 8 - 1 : 0]	Weight7,
	// input	[`filter_num * `PEA_num * 8 - 1 : 0]	Weight8,
	// input	[`filter_num * `PEA_num * 8 - 1 : 0]	Weight9,

	output 	[`filter_num * `PEA_num * 8 - 1 : 0]	sum,
	output											sum_reg_valid,
	//output	[`filter_num * `PEA_num * 8 - 1 : 0]	sum_reg,

	output	[`filter_num * 8 - 1 : 0]				partial_sum
);

wire	[`PEA_num * 8 - 1 : 0]	buf_in1;
wire	[`PEA_num * 8 - 1 : 0]	buf_in2;
wire	[`PEA_num * 8 - 1 : 0]	buf_out1;
wire	[`PEA_num * 8 - 1 : 0]	buf_out2;

wire [8:0] 						col_without_padding;

assign col_without_padding = col - 2;

generate
	genvar i;
		for(i = 0; i < `filter_num; i = i + 1) begin
			PEA_filter filter(
				.clk			(clk),
				.rst_n			(rst_n),

				.Data1			(Data1),
				.Data2			(Data2),
				.Data3			(Data3),

				.Weight_en		(Weight_en),
				.Weight1		(Weight[(i + 1) * 72 - 1- 64 -: 8]),
				.Weight2		(Weight[(i + 1) * 72 - 1- 56 -: 8]),
				.Weight3		(Weight[(i + 1) * 72 - 1- 48 -: 8]),
				.Weight4		(Weight[(i + 1) * 72 - 1- 40 -: 8]),
				.Weight5		(Weight[(i + 1) * 72 - 1- 32 -: 8]),
				.Weight6		(Weight[(i + 1) * 72 - 1- 24 -: 8]),
				.Weight7		(Weight[(i + 1) * 72 - 1- 16 -: 8]),
				.Weight8		(Weight[(i + 1) * 72 - 1- 8 -: 8]),
				.Weight9		(Weight[(i + 1) * 72 - 1 -: 8]),

				.col			(col),
				.row			(row),

				.en				(en),

				.buf_out1		(buf_out1),
				.buf_out2		(buf_out2),

				.buf_in1		(buf_in1),
				.buf_in2		(buf_in2),

				.sum 			(sum[(i + 1) * `PEA_num * 8 - 1 -: 32]),
				.sum_reg_valid	(sum_reg_valid)
				// .sum_reg 		(sum_reg[(i + 1) * `PEA_num * 2 - 1 -: 32])
			);
		end
endgenerate

generate
	genvar j;
		for(j = 0; j < `PEA_num; j = j + 1) begin
			stack_top stack(
				.clk			(clk),
				.rst_n			(rst_n),
				.en 			(en_output),
				.col			(col),

				.buf_in1		(buf_in1[(j + 1) * 8 - 1 -: 8]),
				.buf_in2		(buf_in2[(j + 1) * 8 - 1 -: 8]),

				.buf_out1		(buf_out1[(j + 1) * 8 - 1 -: 8]),
				.buf_out2		(buf_out2[(j + 1) * 8 - 1 -: 8])
			);
		end
endgenerate

generate
	genvar k;
		for(k = 0; k < `filter_num; k = k + 1) begin
			adder_tree tree(
				.PEA_result		(sum[(k + 1) * `PEA_num * 8 - 1 -: 32]),
				.sum			(partial_sum[(k+1) * 8 - 1 -: 8])
			);
		end
endgenerate

endmodule
