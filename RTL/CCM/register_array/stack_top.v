`include "para.v"

module stack_top(
	input			clk,
	input			rst_n,
	input			en,
	input	[8:0]	col,
	input	[7:0]	buf_in1,
	input 	[7:0]	buf_in2,
	input   [8-1:0] SIZE_maxpooling_IN,
	output	[7:0]	buf_out1,
	output	[7:0]	buf_out2
);

stack stack1(
	.clk(clk),
	.rst_n(rst_n),
	.en(en),
	.col(col),
	.buf_in(buf_in1),
	.buf_out(buf_out1),
	.SIZE_maxpooling_IN(SIZE_maxpooling_IN)
);

stack stack2(
	.clk(clk),
	.rst_n(rst_n),
	.en(en),
	.col(col),
	.buf_in(buf_in2),
	.buf_out(buf_out2),
	.SIZE_maxpooling_IN(SIZE_maxpooling_IN)
);

endmodule