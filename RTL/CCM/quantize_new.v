`include "para.v"

module quantize
#(
	parameter										fractional_length = 7
)
(
	input				clk,
	input				rst_n,
	input				Data_in_valid,
	input		[15:0]	Data_in,
	output	reg			Data_out_valid,
	output	reg	[7:0]	Data_out
);

wire [15:0] half_interval = 16'h0080;
wire [15:0] max_val = 16'h1 << 7 - 1;
wire [15:0] min_val = 16'h1 << 7;

wire [7:0] Data_out_tmp;
wire [7:0] out1;
wire [7:0] out2;

// ================================
// Pipe line
// ================================
reg				Data_in_valid_reg;
reg		[15:0]	Data_in_reg;

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		Data_in_valid_reg <= #1 0;
		Data_in_reg <= #1 0;
	end
	else begin
		Data_in_valid_reg <= #1 Data_in_valid;
		Data_in_reg <= #1 Data_in;
	end
end

// ================================
// Combinational
// ================================
assign Data_out_tmp = ((Data_in_reg << (16-2*fractional_length-1)) + half_interval) >> 8;
assign out1 = ($signed(Data_out_tmp)<$signed(max_val)) ? Data_out_tmp : max_val;
assign out2 = ($signed(out1)>$signed(min_val)) ? out1 : min_val;
// assign Data_out = out2;

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		Data_out <= #1 0;
	end
	else begin
		Data_out <= #1 Data_out_tmp;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		Data_out_valid <= #1 0;
	end
	else if(Data_in_valid_reg) begin
		Data_out_valid <= #1 1;
	end
	else begin
		Data_out_valid <= #1 0;
	end
end

endmodule