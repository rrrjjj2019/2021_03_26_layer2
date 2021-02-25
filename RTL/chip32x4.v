// `define CHANNEL_OUT 32
// `define	PEA_num		4
// `define	filter_num	32

`include "para.v"

module chip(
	input											clk,
	input											rst_n,
	input											start,

	input	[`PEA_num * 8 - 1 : 0]					data_in,

	input	[`CHANNEL_OUT * 24 - 1 : 0]				weight_in,

	output	[`filter_num * `PEA_num * 8 - 1 : 0]	sum,
	output											sum_reg_valid,
	//output	[`filter_num * `PEA_num * 8 - 1 : 0]	sum_reg,

	output	[`filter_num * 8 - 1 : 0]				partial_sum
);

wire	[`CHANNEL_OUT * 8 - 1 : 0]	data_i_DRAM;

wire	[`PEA_num * 8 - 1 : 0]		data1;
wire	[`PEA_num * 8 - 1 : 0]		data2;
wire	[`PEA_num * 8 - 1 : 0]		data3;

wire	[`SRAM_NUM * 72 - 1 : 0]	Q_w;

wire								Weight_en;

// wire	[7:0]						Data1;
// wire	[7:0]						Data2;
// wire	[7:0]						Data3;

wire	[8:0]						col;
wire	[8:0]						row;

wire								en;
wire								en_output;

assign data_i_DRAM = {{28{8'd0}}, data_in};

// assign col = 258;
// assign row = 17;

assign col = `COL_first_layer + 2;
assign row = `ROW_first_layer + 2;

// assign Data1 = data1[7:0];
// assign Data2 = data2[7:0];
// assign Data3 = data3[7:0];

sram_top sram_module(
	.clk(clk),
	.rst_n(rst_n),
	.start(start),
	.data_i_DRAM(data_i_DRAM),	// input data from DRAM
	.data_i_CCM(),	// input data from CCM
	.weight_in(weight_in),
	.data1(data1),
	.data2(data2),
	.data3(data3),
	.Q_w(Q_w),
	.CCM_en(en),
	.CCM_en_cnt(en_output),
	.Weight_en(Weight_en)
);

CCM_top CCM(
	.clk(clk),
	.rst_n(rst_n),

	.en(en),
	.en_output(en_output),

	.col(col),
	.row(row),

	.Data1(data1),
	.Data2(data2),
	.Data3(data3),

	.Weight_en(Weight_en),
	.Weight(Q_w),
	// .Weight1(Weight1),
	// .Weight2(Weight2),
	// .Weight3(Weight3),
	// .Weight4(Weight4),
	// .Weight5(Weight5),
	// .Weight6(Weight6),
	// .Weight7(Weight7),
	// .Weight8(Weight8),
	// .Weight9(Weight9),

	.sum(sum),
	.sum_reg_valid(sum_reg_valid),
	// .sum_reg(sum_reg),

	.partial_sum(partial_sum)
);

endmodule
