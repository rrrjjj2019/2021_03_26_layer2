`include "para.v"

module adder_tree(
	input	[31:0]	PEA_result,
	output	[7:0]	sum
);

wire	[7:0]	channel1;
wire	[7:0]	channel2;
wire	[7:0]	channel3;
wire	[7:0]	channel4;

assign channel1 = PEA_result[7:0];
assign channel2 = PEA_result[15:8];
assign channel3 = PEA_result[23:16];
assign channel4 = PEA_result[31:24];

assign sum = (channel1 + channel2) + (channel3 + channel4);

endmodule
