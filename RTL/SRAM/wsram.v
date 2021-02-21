`include "para.v"

module wsram(
	input								clk,
	input								CEN,
	input	[`SRAM_NUM - 1 : 0]			WEN,
	input	[`SRAM_NUM * 5 - 1 : 0]		A,
	input	[`SRAM_NUM * 72 - 1 : 0]	D,
	output	[`SRAM_NUM * 72 - 1 : 0]	Q
);

generate
	genvar i;
	for(i = 0; i < `SRAM_NUM; i = i + 1) begin
		rf_sp_wsram wsram(
			.CENY(),
			.WENY(),
			.AY(),
			.DY(),
			.Q(Q[(i+1) * 72 - 1 -: 72]),
			.CLK(clk),
			.CEN(CEN),
			.WEN(WEN[i]),
			.A(A[(i+1) * 5 - 1 -: 5]),
			.D(D[(i+1) * 72 - 1 -: 72]),
			.EMA(3'b000),
			.EMAW(2'b00),
			.EMAS(1'b0),
			.TEN(~1'b0),
			.BEN(~1'b0),
			.TCEN(),
			.TWEN(),
			.TA(),
			.TD(),
			.TQ(),
			.RET1N(1'b1),
			.STOV(1'b0)
			);
	end
endgenerate

endmodule