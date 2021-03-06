// `define	CHANNEL_IN	4
// `define CHANNEL_OUT	32
// `define	LAYER_NUM	1
// `define	ROW 		6
// `define	COL 		6
// `define TILE_NUM	0

`include "para.v"

module sram_top(
	input								clk,
	input								rst_n,
	input								start,
	input	[`CHANNEL_OUT * 8 - 1 : 0]	data_i_DRAM,// input data from DRAM
	input	[`CHANNEL_OUT * 8 - 1 : 0]	data_i_CCM,	// input data from CCM
	input	[`CHANNEL_OUT * 24 - 1 : 0]	weight_in,
	input	[`filter_num * 8 - 1 : 0]	partial_sum, //input data from CCM
	input  								sum_reg_valid,
	input 	[`CHANNEL_OUT * 8 - 1 : 0]	maxpooling_ans,
	output	[`PEA_num * 8 - 1 : 0]		data1,
	output	[`PEA_num * 8 - 1 : 0]		data2,
	output	[`PEA_num * 8 - 1 : 0]		data3,
	output	[`SRAM_NUM * 72 - 1 : 0]	Q_w,
	output								CCM_en,
	output 								CCM_en_cnt,
	output								Weight_en,
	output	[`CHANNEL_OUT * 16 - 1 : 0]	or_pooling_output,
	output	[2:0]	curr_state_or_output,
	output	[8 - 1:0]	OR_pxl_cnt,
	output	[`CHANNEL_OUT * 8 - 1: 0]	Q_or,

	output  [8 - 1:0]					SIZE_maxpooling_IN
);

wire								CENA_1;
wire								CENB_1;
wire	[`SRAM_NUM - 1 : 0]			WENA_1;
wire	[`SRAM_NUM - 1 : 0]			WENB_1;
wire	[10:0]						AA_1;
wire	[`SRAM_NUM * 16 - 1 : 0]	DA_1;
wire	[10:0]						AB_1;
wire	[`SRAM_NUM * 16 - 1 : 0]	DB_1;
wire	[`SRAM_NUM * 16 - 1 : 0]	QA_1;
wire	[`SRAM_NUM * 16 - 1 : 0]	QB_1;

wire								CENA_2;
wire								CENB_2;
wire	[`SRAM_NUM - 1 : 0]			WENA_2;
wire	[`SRAM_NUM - 1 : 0]			WENB_2;
wire	[10:0]						AA_2;
wire	[`SRAM_NUM * 16 - 1 : 0]	DA_2;
wire	[10:0]						AB_2;
wire	[`SRAM_NUM * 16 - 1 : 0]	DB_2;
wire	[`SRAM_NUM * 16 - 1 : 0]	QA_2;
wire	[`SRAM_NUM * 16 - 1 : 0]	QB_2;

wire								CEN_w;
wire	[`SRAM_NUM - 1 : 0]			WEN_w;
wire	[4:0]						A_w;
wire	[`SRAM_NUM * 72 - 1 : 0]	D_w;

wire								CEN_ir;
wire	[`SRAM_NUM - 1 : 0]			WEN_ir;
wire	[7:0]						A_ir;
wire	[`SRAM_NUM * 16 - 1 : 0]	D_ir;
wire	[`SRAM_NUM * 16 - 1 : 0]	Q_ir;

wire								CEN_or;
wire	[`SRAM_NUM - 1 : 0]			WEN_or;
wire	[6:0]						A_or;
wire	[`SRAM_NUM * 8 - 1 : 0]	D_or;

wire								sram_sel1;
wire								sram_sel2;
wire	[2:0]						data_process;
wire    [3 - 1: 0] 					partial_sum_index;

fsram fsram1(
	.clk(clk),
	.CENA(CENA_1),
	.CENB(CENB_1),
	.WENA(WENA_1),
	.WENB(WENB_1),
	.AA({`SRAM_NUM{AA_1}}),
	.DA(DA_1),
	.AB({`SRAM_NUM{AB_1}}),
	.DB(DB_1),
	.QA(QA_1),
	.QB(QB_1)
);

fsram fsram2(
	.clk(clk),
	.CENA(CENA_2),
	.CENB(CENB_2),
	.WENA(WENA_2),
	.WENB(WENB_2),
	.AA({`SRAM_NUM{AA_2}}),
	.DA(DA_2),
	.AB({`SRAM_NUM{AB_2}}),
	.DB(DB_2),
	.QA(QA_2),
	.QB(QB_2)
);

wsram wsram(
	.clk(clk),
	.CEN(CEN_w),
	.WEN(WEN_w),
	.A({`SRAM_NUM{A_w}}),
	.D(D_w),
	.Q(Q_w)
);

// irsram irsram(
// 	.clk(clk),
// 	.CEN(CEN_ir),
// 	.WEN(WEN_ir),
// 	.A({`SRAM_NUM{A_ir}}),
// 	.D(D_ir),
// 	.Q(Q_ir)
// );

 orsram orsram(
 	.clk(clk),
 	.CEN(CEN_or),
 	.WEN(WEN_or),
 	.A({`SRAM_NUM{A_or}}),
 	.D(D_or),
 	.Q(Q_or)
 );

sram_controller controller(
	.clk(clk),
	.rst_n(rst_n),
	.start(start),
	.data_in_1(data_i_DRAM),
	.data_in_1_2(QB_1),
	.CENA_1(CENA_1),
	.CENB_1(CENB_1),
	.WENA_1(WENA_1),
	.WENB_1(WENB_1),
	.AA_1(AA_1),
	.DA_1(DA_1),
	.AB_1(AB_1),
	.DB_1(DB_1),
	.data_in_2(data_i_CCM),
	.data_in_2_2(QB_2),
	.CENA_2(CENA_2),
	.CENB_2(CENB_2),
	.WENA_2(WENA_2),
	.WENB_2(WENB_2),
	.AA_2(AA_2),
	.DA_2(DA_2),
	.AB_2(AB_2),
	.DB_2(DB_2),
	.weight_in(weight_in),
	.CEN_w(CEN_w),
	.WEN_w(WEN_w),
	.A_w(A_w),
	.D_w(D_w),
	// .CEN_ir(CEN_ir),
	// .WEN_ir(WEN_ir),
	// .A_ir(A_ir),
	// .D_ir(D_ir),

	.partial_sum(partial_sum),
	.CEN_or(CEN_or),
	.WEN_or(WEN_or),
	.A_or(A_or),
	.D_or(D_or),
	.Q_or(Q_or),
	.or_pooling_output(or_pooling_output),
	.curr_state_or_output(curr_state_or_output),
	.OR_pxl_cnt(OR_pxl_cnt),

	.sram_sel1(sram_sel1),
	.sram_sel2(sram_sel2),
	.data_process_reg(data_process),
	.CCM_en(CCM_en),
	.CCM_en_cnt(CCM_en_cnt),
	.Weight_en(Weight_en),
	.sum_reg_valid(sum_reg_valid),
	.maxpooling_ans(maxpooling_ans),

	.SIZE_maxpooling_IN(SIZE_maxpooling_IN),
	.partial_sum_index(partial_sum_index)
);

Data_process data_process1(
	.clk(clk),
	.data_process(data_process),
	.FSRAM1(sram_sel1),
	.data_in_1(QB_1),
	.FSRAM2(sram_sel2),
	.data_in_2(QB_2),
	.data1(data1),
	.data2(data2),
	.data3(data3),
	.partial_sum_index(partial_sum_index)
);

endmodule