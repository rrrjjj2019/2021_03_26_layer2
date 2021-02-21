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

`define ALL_FSM_IDLE    3'b000
`define FSM0            0
`define FSM1            1
`define FSM2            2


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
`define OUTPUT_ROW	16
`define OUTPUT_COL	256

`define CHIP_ENABLE ~1'b1
`define CHIP_DISABLE ~1'b0