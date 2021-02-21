`include "para.v"

module stack_tb();

reg				clk;
reg				rst_n;
reg				en;
reg		[7:0]	buf_in;
wire	[7:0]	buf_out;

stack stack(
	.clk(clk),
	.rst_n(rst_n),
	.en(en),
	.col(9'd8),
	.buf_in(buf_in),
	.buf_out(buf_out)
);

initial begin
	$dumpfile("./waveform/stack.vcd");
	$dumpvars(0, stack_tb);

	clk = 0;
	rst_n = ~1'b1;
	@(posedge clk)
	#1
	rst_n = ~1'b0;
	en = 1;
	#2000
	$finish;
end

always #`HALF_CLK clk = ~clk;

endmodule