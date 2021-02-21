/*simulate real sram*/

module rf_sp_stack(
	input				CENY,
	input				WENY,
	input		[7:0]	AY,
	input		[7:0]	DY,
	output	reg	[7:0]	Q,
	input				CLK,
	input				CEN,
	input				WEN,
	input		[7:0]	A,
	input		[7:0]	D,
	input		[2:0]	EMA,
	input		[1:0]	EMAW,
	input				EMAS,
	input				TEN,
	input				BEN,
	input				TCEN,
	input				TWEN,
	input		[7:0]	TA,
	input		[7:0]	TD,
	output		[7:0]	TQ,
	input				RET1N,
	input				STOV
);

reg		[7:0]	buf_mem[0:255];
integer			i;

always@(posedge CLK) begin
	if(!WEN) begin
		buf_mem[A] <= #1 D;
	end
	else begin
		Q = #1 buf_mem[A];
	end
end

endmodule