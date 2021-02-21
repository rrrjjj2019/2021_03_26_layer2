// `define CHANNEL_OUT	32
`include "para.v"

// ============================================
// Data Process
// 0: idle
// 1: 3 zeros
// 2: pad 1 zeros forward
// 3: pad 1 zeros backward
// 4: 1 zeros
// 5: front data ([15 : 8])
// 6: back data ([7 : 0])
// ============================================
module Data_process(
	input									clk,
	input		[2:0]						data_process,
	input									FSRAM1,			// for choosing which SRAM is input (fsm_flag[2])
	input		[`CHANNEL_OUT * 16 - 1 : 0]	data_in_1,
	input									FSRAM2,			// for choosing which SRAM is input
	input		[`CHANNEL_OUT * 16 - 1 : 0]	data_in_2,
	output	reg	[`CHANNEL_IN * 8 - 1 : 0]	data1,
	output	reg	[`CHANNEL_IN * 8 - 1 : 0]	data2,
	output	reg	[`CHANNEL_IN * 8 - 1 : 0]	data3
);



reg		[`CHANNEL_OUT * 16 - 1 : 0] data_in_1_reg;
reg		[`CHANNEL_OUT * 16 - 1 : 0] data_in_2_reg;
reg		[2:0]						data_process_reg;

reg		[1:0]						cnt;
integer i;

wire	[1:0]	FSRAM_sel;
assign FSRAM_sel = FSRAM1 ? (FSRAM2 ? 2'd0 : 2'd1) : (FSRAM2 ? 2'd2 : 2'd0);

// assign data_in_1 = {`CHANNEL_OUT*16{1'bz}};
// assign data_in_2 = {`CHANNEL_OUT*16{1'bz}};

// ============================================
// Two stage Flip_Flop
// ============================================
always@(posedge clk) begin
	data_in_1_reg <= #1 data_in_1;
	data_in_2_reg <= #1 data_in_2;
	data_process_reg <= #1 data_process;
end

// ============================================
// data1
// ============================================
always@(*) begin
	data1 = 0;
	case(FSRAM_sel)
		2'd1: begin
			case(data_process_reg)
				3'd0: begin
					data1 = 0;
				end
				3'd1: begin
					data1 = 0;
				end
				3'd2: begin
					data1 = 0;
				end
				3'd3: begin
					for(i = 0; i < `CHANNEL_IN; i = i + 1) begin
						data1[(i + 1) * 8 - 1 -: 8] = data_in_1_reg[(i + 1) * 16 - 9 -: 8];
					end
				end
				3'd4: begin
					data1 = 0;
				end
				3'd5: begin
					for(i = 0; i < `CHANNEL_IN; i = i + 1) begin
						data1[(i + 1) * 8 - 1 -: 8] = data_in_1_reg[(i + 1) * 16 - 1 -: 8];
					end
				end
				3'd6: begin
					for(i = 0; i < `CHANNEL_IN; i = i + 1) begin
						data1[(i + 1) * 8 - 1 -: 8] = data_in_1_reg[(i + 1) * 16 - 9 -: 8];
					end
				end
				default: begin
					data1 = 0;
				end
			endcase
		end
		2'd2: begin
			case(data_process_reg)
				3'd0: begin
					data1 = 0;
				end
				3'd1: begin
					data1 = 0;
				end
				3'd2: begin
					data1 = 0;
				end
				3'd3: begin
					for(i = 0; i < `CHANNEL_IN; i = i + 1) begin
						data1[(i + 1) * 8 - 1 -: 8] = data_in_2_reg[(i + 1) * 16 - 9 -: 8];
					end
				end
				3'd4: begin
					data1 = 0;
				end
				3'd5: begin
					for(i = 0; i < `CHANNEL_IN; i = i + 1) begin
						data1[(i + 1) * 8 - 1 -: 8] = data_in_2_reg[(i + 1) * 16 - 1 -: 8];
					end
				end
				3'd6: begin
					for(i = 0; i < `CHANNEL_IN; i = i + 1) begin
						data1[(i + 1) * 8 - 1 -: 8] = data_in_2_reg[(i + 1) * 16 - 9 -: 8];
					end
				end
				default: begin
					data1 = 0;
				end
			endcase
		end
		default: begin
			data1 = 0;
		end
	endcase
end

// ============================================
// data2
// ============================================
always@(*) begin
	data2 = 0;
	case(FSRAM_sel)
		2'd1: begin
			case(data_process_reg)
				3'd0: begin
					data2 = 0;
				end
				3'd1: begin
					data2 = 0;
				end
				3'd2: begin
					for(i = 0; i < `CHANNEL_IN; i = i + 1) begin
						data2[(i + 1) * 8 - 1 -: 8] = data_in_1_reg[(i + 1) * 16 - 1 -: 8];
					end
				end
				3'd3: begin
					for(i = 0; i < `CHANNEL_IN; i = i + 1) begin
						data2[(i + 1) * 8 - 1 -: 8] = data_in_1_reg[(i + 1) * 16 - 1 -: 8];
					end
				end
				3'd4: begin
					data2 = 0;
				end
				3'd5: begin
					data2 = 0;
				end
				3'd6: begin
					data2 = 0;
				end
				default: begin
					data2 = 0;
				end
			endcase
		end
		2'd2: begin
			case(data_process_reg)
				3'd0: begin
					data2 = 0;
				end
				3'd1: begin
					data2 = 0;
				end
				3'd2: begin
					for(i = 0; i < `CHANNEL_IN; i = i + 1) begin
						data2[(i + 1) * 8 - 1 -: 8] = data_in_2_reg[(i + 1) * 16 - 1 -: 8];
					end
				end
				3'd3: begin
					for(i = 0; i < `CHANNEL_IN; i = i + 1) begin
						data2[(i + 1) * 8 - 1 -: 8] = data_in_2_reg[(i + 1) * 16 - 1 -: 8];
					end
				end
				3'd4: begin
					data2 = 0;
				end
				3'd5: begin
					data2 = 0;
				end
				3'd6: begin
					data2 = 0;
				end
				default: begin
					data2 = 0;
				end
			endcase
		end
		default: begin
			data2 = 0;
		end
	endcase
end

// ============================================
// data3
// ============================================
always@(*) begin
	data3 = 0;
	case(FSRAM_sel)
		2'd1: begin
			case(data_process)
				3'd0: begin
					data3 = 0;
				end
				3'd1: begin
					data3 = 0;
				end
				3'd2: begin
					for(i = 0; i < `CHANNEL_IN; i = i + 1) begin
						data3[(i + 1) * 8 - 1 -: 8] = data_in_1_reg[(i + 1) * 16 - 9 -: 8];
					end
				end
				3'd3: begin
					data3 = 0;
				end
				3'd4: begin
					data3 = 0;
				end
				3'd5: begin
					data3 = 0;
				end
				3'd6: begin
					data3 = 0;
				end
				default: begin
					data3 = 0;
				end
			endcase
		end
		2'd2: begin
			case(data_process)
				3'd0: begin
					data3 = 0;
				end
				3'd1: begin
					data3 = 0;
				end
				3'd2: begin
					for(i = 0; i < `CHANNEL_IN; i = i + 1) begin
						data3[(i + 1) * 8 - 1 -: 8] = data_in_2_reg[(i + 1) * 16 - 9 -: 8];
					end
				end
				3'd3: begin
					data3 = 0;
				end
				3'd4: begin
					data3 = 0;
				end
				3'd5: begin
					data3 = 0;
				end
				3'd6: begin
					data3 = 0;
				end
				default: begin
					data3 = 0;
				end
			endcase
		end
		default: begin
			data3 = 0;
		end
	endcase
end

endmodule
