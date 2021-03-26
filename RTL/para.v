`timescale 1ns/1ps

`define	CHANNEL_IN 	4
`define	CHANNEL_OUT	32
`define	PEA_num		4
`define	filter_num	32
`define	CH_NUM 		32

`define	LAYER_NUM	1
`define TILE_NUM	0
`define SRAM_NUM 	32

`define	ROW_single_tiling 	32
`define	COL_single_tiling 	128

`define	ROW_first_layer 	128
`define	COL_first_layer  	128

`define	ROW_second_layer 	64
`define	COL_second_layer  	64

`define ALL_FSM_IDLE    4'b0000
`define FSM0            0
`define FSM1            1
`define FSM2            2
`define FSM3            3

`define	ROW	            128
`define	COL	            128

// =======================
// FSM2
// =======================
`define FSM2_s0         5'd0
`define FSM2_s1         5'd1
`define FSM2_s2         5'd2
`define FSM2_s3         5'd3
`define FSM2_s4         5'd4
`define FSM2_s5         5'd5
`define FSM2_s6         5'd6

`define FSM2_s1_wait    5'd7
`define FSM2_s2_wait    5'd8
`define FSM2_s3_wait    5'd9
`define FSM2_s4_wait    5'd10
`define FSM2_s5_wait    5'd11
`define FSM2_s6_wait    5'd12

`define FSM2_s1_row_end 5'd13
`define FSM2_s2_row_end 5'd14
`define FSM2_s4_row_end 5'd15
`define FSM2_s6_row_end 5'd16

// =======================
// Test Bench
// =======================
`define NULL		0
`define	HALF_CLK	5
// `define DATA_ROW	8
// `define DATA_COL	8
`define WEIGHT_ROW	3
`define WEIGHT_COL	3
// `define OUTPUT_ROW	6
// `define OUTPUT_COL	6

`define DATA_ROW	17
`define DATA_COL	258
`define OUTPUT_ROW	128
`define OUTPUT_COL	128

`define CHIP_ENABLE ~1'b1
`define CHIP_DISABLE ~1'b0
`define TOTAL_LAYER 2
`define TOTAL_NUM_PARTIAL_SUM 8