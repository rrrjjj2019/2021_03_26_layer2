`include "para.v"

module register_array(
	input				clk,
	input				rst_n,
	input 		[8:0]	rd_ptr,
	input 		[8:0]	wr_ptr,
	input		[7:0]	data_in,
	output	reg	[7:0]	data_out
);
reg		[7:0]	buf_mem	[0:256];
integer 					i;

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 257; i = i + 1) begin
			buf_mem[i] <= 8'b0;
		end
	end
	else begin
		buf_mem[wr_ptr] <= data_in;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		data_out <= 0;
	end
	else begin
		data_out <= buf_mem[rd_ptr];
	end
end

endmodule