`define BIT_WIDTH 	8
`define BUF_WIDTH 	9
`define BUF_SIZE 	257

module register_array_tb;

reg 						clk;
reg 						rst_n;
reg 	[`BUF_WIDTH-1 : 0]	rd_ptr;
reg 	[`BUF_WIDTH-1 : 0]	wr_ptr;
reg 	[`BIT_WIDTH-1 : 0]	data_in;
wire 	[`BIT_WIDTH-1 : 0]	data_out;
integer 					i;

register_array reg_array(
	.clk(clk),
	.rst_n(rst_n),
	.rd_ptr(rd_ptr),
	.wr_ptr(wr_ptr),
	.data_in(data_in),
	.data_out(data_out)
);

initial begin
	$dumpfile("./waveform/register_array.vcd");
	$dumpvars(0, register_array_tb);

	rst_n = 0;
	clk = 0;

	#3 rst_n = 1;
	rd_ptr = 256;
	wr_ptr = 0;

	for(i = 0;i < 256;i = i+1) begin
		@(posedge clk);
		data_in = i;
		wr_ptr = i;
	end
	for(i = 256;i > 0;i = i-1) begin
		@(posedge clk);
		data_in = i;
		rd_ptr = i-1;
		wr_ptr = i;
	end

	#1000 $finish;
end

always #1 clk = ~clk;

endmodule