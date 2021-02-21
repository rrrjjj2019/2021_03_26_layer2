// `define	PEA_num		4

`include "para.v"

module PEA_filter(
	input 							clk,
	input 							rst_n,
	// 4-channel
	input	[`PEA_num * 8 - 1 : 0]	Data1,
	input	[`PEA_num * 8 - 1 : 0]	Data2,
	input	[`PEA_num * 8 - 1 : 0]	Data3,

	input							Weight_en,
	input	[7:0]					Weight1,
	input	[7:0]					Weight2,
	input	[7:0]					Weight3,
	input	[7:0]					Weight4,
	input	[7:0]					Weight5,
	input	[7:0]					Weight6,
	input	[7:0]					Weight7,
	input	[7:0]					Weight8,
	input	[7:0]					Weight9,

	input	[8:0]					col,
	input	[8:0]					row,

	input							en,

	input	[`PEA_num * 8 - 1 : 0]	buf_out1,
	input	[`PEA_num * 8 - 1 : 0]	buf_out2,

	output	[`PEA_num * 8 - 1 : 0]	buf_in1,
	output	[`PEA_num * 8 - 1 : 0]	buf_in2,

	output	[`PEA_num * 8 - 1:0]	sum,
	output							sum_reg_valid
	//output	[`PEA_num * 8 - 1:0]	sum_reg
);

reg		[3:0]	Weight_en_reg;

generate
	genvar i;
		for(i = 0;i < `PEA_num;i = i + 1) begin
			PE_array_top PEA(
				.Data1(Data1[(i + 1) * 8 - 1 -: 8]),
				.Data2(Data2[(i + 1) * 8 - 1 -: 8]),
				.Data3(Data3[(i + 1) * 8 - 1 -: 8]),

				.Weight_en(Weight_en_reg[i]),
				.Weight1(Weight7),
				.Weight2(Weight4),
				.Weight3(Weight1),
				.Weight4(Weight8),
				.Weight5(Weight5),
				.Weight6(Weight2),
				.Weight7(Weight9),
				.Weight8(Weight6),
				.Weight9(Weight3),

				.rst_n(rst_n),
				.clk(clk),
				.C(col),
				.R(row),
				.en(en),

				.buf_out1(buf_out1[(i + 1) * 8 - 1 -: 8]),
				.buf_out2(buf_out2[(i + 1) * 8 - 1 -: 8]),

				.buf_in1(buf_in1[(i + 1) * 8 - 1 -: 8]),
				.buf_in2(buf_in2[(i + 1) * 8 - 1 -: 8]),

				.sum_quantize(sum[(i + 1) * 8 - 1 -: 8]),
				.sum_reg_valid(sum_reg_valid)
				//.sum_reg(sum_reg[(i + 1) * 8 - 1 -: 8])
			);
		end
endgenerate

/*always@(*) begin
	Weight_en_reg[0] = Weight_en;
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		Weight_en_reg[3:1] <= #1 0;
	end
	else begin
		Weight_en_reg[1] <= #1 Weight_en_reg[0];
		Weight_en_reg[2] <= #1 Weight_en_reg[1];
		Weight_en_reg[3] <= #1 Weight_en_reg[2];
	end
end*/

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		Weight_en_reg <= #1 0;
	end
	else begin
		Weight_en_reg[0] <= #1 Weight_en;
		Weight_en_reg[1] <= #1 Weight_en_reg[0];
		Weight_en_reg[2] <= #1 Weight_en_reg[1];
		Weight_en_reg[3] <= #1 Weight_en_reg[2];
	end
end

endmodule
