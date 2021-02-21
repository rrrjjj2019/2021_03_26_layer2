// `define BIT_WIDTH 	8
// `define BUF_WIDTH 	9
// `define BUF_SIZE 	257
// `define COL 		8
`include "para.v"

module reuse_module_tb;

reg 						clk;
reg 						rst_n;
reg							en;
reg		[8:0]				col;
reg		[7:0]	buf_in1;
reg		[7:0]	buf_in2;
wire	[7:0]	buf_out1;
wire	[7:0]	buf_out2;

integer						i;

reuse_module reuse_top(
	.clk(clk),
	.rst_n(rst_n),
	.en(en),
	.col(col),
	.buf_in1(buf_in1),
	.buf_in2(buf_in2),
	.buf_out1(buf_out1),
	.buf_out2(buf_out2)
);

initial begin
	$dumpfile("waveform/reuse_module.vcd");
	$dumpvars(0, reuse_module_tb);

	clk = 0;
	rst_n = ~1'b1;
	en = 0;
	col = `COL;
	#10
	rst_n = 1;

	#10
	en = 1;

	for(i = 0;i < 5 * (col-2); i = i + 1) begin
		@(posedge clk);
		buf_in1 = i;
		buf_in2 = i;
	end
	$finish;
end

always #5 clk = ~clk;

endmodule