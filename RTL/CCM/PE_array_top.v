`include "para.v"

module PE_array_top(

    input           [7:0]               Data1,
    input           [7:0]               Data2,
    input           [7:0]               Data3,

    input                               Weight_en,
    input           [7:0]               Weight1,
    input           [7:0]               Weight2,
    input           [7:0]               Weight3,
    input           [7:0]               Weight4,
    input           [7:0]               Weight5,
    input           [7:0]               Weight6,
    input           [7:0]               Weight7,
    input           [7:0]               Weight8,
    input           [7:0]               Weight9,

    input                               rst_n,
    input                               clk,

    input           [8:0]               C,
    input           [8:0]               R,

    input                               en,

    input           [7:0]               buf_out1,
    input           [7:0]               buf_out2,

    output  reg     [7:0]               buf_in1,
    output  reg     [7:0]               buf_in2,

    output          [7:0]               sum_quantize,
    output                              sum_reg_valid
    // output          [7:0]               sum_reg

    );

reg					[7:0]	Data1_reg;
reg					[7:0]	Data2_reg;
reg					[7:0]	Data3_reg;

reg                 [1:0]   MUX4to1_sel;
reg                 [1:0]   MUX3to1_sel;

reg                         Data_valid;
wire                        Weight_valid;
reg                         Weight_valid_reg;
reg                         Weight_valid_reg_reg;
wire                        Data_out_valid;

reg                 [9:0]   counter_col;
reg                 [9:0]   counter_row;
reg                         dir_R;
reg                 [4:0]   curr_state;
reg                 [4:0]   next_state;
reg                 [9:0]   counter_col_reg;
reg                 [9:0]   counter_row_reg;

wire                [7:0]   MUX_out1;
wire                [7:0]   MUX_out2;
wire                [7:0]   MUX_out3;
wire                [7:0]   MUX_out4;
wire                [7:0]   MUX_out5;
wire                [7:0]   MUX_out6;
wire                [7:0]   MUX_out7;
wire                [7:0]   MUX_out8;
wire                [7:0]   MUX_out9;

wire                [7:0]   PE_Data1;
wire                [7:0]   PE_Data2;
wire                [7:0]   PE_Data3;
wire                [7:0]   PE_Data4;
wire                [7:0]   PE_Data5;
wire                [7:0]   PE_Data6;
wire                [7:0]   PE_Data7;
wire                [7:0]   PE_Data8;
wire                [7:0]   PE_Data9;


// ============================================
// PE_out: for sum_reg and adder tree
// ============================================
wire                [15:0]  PE_out_1;
wire                [15:0]  PE_out_2;
wire                [15:0]  PE_out_3;
wire                [15:0]  PE_out_4;
wire                [15:0]  PE_out_5;
wire                [15:0]  PE_out_6;
wire                [15:0]  PE_out_7;
wire                [15:0]  PE_out_8;
wire                [15:0]  PE_out_9;
wire                [15:0]  PE_out_10;
wire                [15:0]  PE_out_11;
wire                [15:0]  PE_out_12;
wire                [15:0]  PE_out_13;
wire                [15:0]  PE_out_14;
wire                [15:0]  PE_out_15;
wire                [15:0]  PE_out_16;
wire                [15:0]  PE_out_17;

wire                [15:0]  PE1_sum;
wire                [15:0]  PE2_sum;
wire                [15:0]  PE3_sum;
wire                [15:0]  PE4_sum;
wire                [15:0]  PE5_sum;
wire                [15:0]  PE6_sum;
wire                [15:0]  PE7_sum;
wire                [15:0]  PE8_sum;
wire                [15:0]  PE9_sum;

wire                [15:0]  sum;

wire                        PE1_sum_reg_valid;
wire                        PE2_sum_reg_valid;
wire                        PE3_sum_reg_valid;
wire                        PE4_sum_reg_valid;
wire                        PE5_sum_reg_valid;
wire                        PE6_sum_reg_valid;
wire                        PE7_sum_reg_valid;
wire                        PE8_sum_reg_valid;
wire                        PE9_sum_reg_valid;

reg                         datapath_rst;

// ============================================
// Declare Module : 4-1 MUX => 3
// ============================================
MUX4to1 MUX1(
    .In1    (Data1_reg),
    .In2    (buf_out1),
    .In3    (PE_Data4),
    .In4    (PE_Data2),
    .sel    (MUX4to1_sel),
    .Out    (MUX_out1)
);
MUX4to1 MUX2(
    .In1    (Data2_reg),
    .In2    (buf_out2),
    .In3    (PE_Data5),
    .In4    (PE_Data3),
    .sel    (MUX4to1_sel),
    .Out    (MUX_out2)
);
MUX4to1 MUX3(
    .In1    (Data3_reg),
    .In2    (Data1_reg),
    .In3    (PE_Data6),
    .In4    (Data3_reg),
    .sel    (MUX4to1_sel),
    .Out    (MUX_out3)
);

// ============================================
// Declare Module : 3-1 MUX => 6
// ============================================
MUX3to1 MUX4(
    .In1    (PE_Data1),
    .In2    (PE_Data7),
    .In3    (PE_Data5),
    .sel    (MUX3to1_sel),
    .Out    (MUX_out4)
);
MUX3to1 MUX5(
    .In1    (PE_Data2),
    .In2    (PE_Data8),
    .In3    (PE_Data6),
    .sel    (MUX3to1_sel),
    .Out    (MUX_out5)
);
MUX3to1 MUX6(
    .In1    (PE_Data3),
    .In2    (PE_Data9),
    .In3    (Data2_reg),
    .sel    (MUX3to1_sel),
    .Out    (MUX_out6)
);
MUX3to1 MUX7(
    .In1    (PE_Data4),
    .In2    (buf_out1),
    .In3    (PE_Data8),
    .sel    (MUX3to1_sel),
    .Out    (MUX_out7)
);
MUX3to1 MUX8(
    .In1    (PE_Data5),
    .In2    (buf_out2),
    .In3    (PE_Data9),
    .sel    (MUX3to1_sel),
    .Out    (MUX_out8)
);
MUX3to1 MUX9(
    .In1    (PE_Data6),
    .In2    (Data1_reg),
    .In3    (Data1_reg),
    .sel    (MUX3to1_sel),
    .Out    (MUX_out9)
);

// ============================================
// Declare Module : PE => 9
// ============================================
PE_top PE1(
    .Data                   (MUX_out1),
    .Weight                 (Weight1),
    .rst_n                  (rst_n),
    .clk                    (clk),
    .Data_valid             (Data_valid),
    .Weight_valid           (Weight_valid),
    .sum                    (PE1_sum),
    .sum_reg                (PE_out_1),
    .sum_reg_valid          (PE1_sum_reg_valid),
    .Data_reg_out           (PE_Data1)
);
PE_top PE2(
    .Data                   (MUX_out2),
    .Weight                 (Weight2),
    .rst_n                  (rst_n),
    .clk                    (clk),
    .Data_valid             (Data_valid),
    .Weight_valid           (Weight_valid),
    .sum                    (PE2_sum),
    .sum_reg                (PE_out_2),
    .sum_reg_valid          (PE2_sum_reg_valid),
    .Data_reg_out           (PE_Data2)
);
PE_top PE3(
    .Data                   (MUX_out3),
    .Weight                 (Weight3),
    .rst_n                  (rst_n),
    .clk                    (clk),
    .Data_valid             (Data_valid),
    .Weight_valid           (Weight_valid),
    .sum                    (PE3_sum),
    .sum_reg                (PE_out_3),
    .sum_reg_valid          (PE3_sum_reg_valid),
    .Data_reg_out           (PE_Data3)
);
PE_top PE4(
    .Data                   (MUX_out4),
    .Weight                 (Weight4),
    .rst_n                  (rst_n),
    .clk                    (clk),
    .Data_valid             (Data_valid),
    .Weight_valid           (Weight_valid),
    .sum                    (PE4_sum),
    .sum_reg                (PE_out_4),
    .sum_reg_valid          (PE4_sum_reg_valid),
    .Data_reg_out           (PE_Data4)
);
PE_top PE5(
    .Data                   (MUX_out5),
    .Weight                 (Weight5),
    .rst_n                  (rst_n),
    .clk                    (clk),
    .Data_valid             (Data_valid),
    .Weight_valid           (Weight_valid),
    .sum                    (PE5_sum),
    .sum_reg                (PE_out_5),
    .sum_reg_valid          (PE5_sum_reg_valid),
    .Data_reg_out           (PE_Data5)
);
PE_top PE6(
    .Data                   (MUX_out6),
    .Weight                 (Weight6),
    .rst_n                  (rst_n),
    .clk                    (clk),
    .Data_valid             (Data_valid),
    .Weight_valid           (Weight_valid),
    .sum                    (PE6_sum),
    .sum_reg                (PE_out_6),
    .sum_reg_valid          (PE6_sum_reg_valid),
    .Data_reg_out           (PE_Data6)
);
PE_top PE7(
    .Data                   (MUX_out7),
    .Weight                 (Weight7),
    .rst_n                  (rst_n),
    .clk                    (clk),
    .Data_valid             (Data_valid),
    .Weight_valid           (Weight_valid),
    .sum                    (PE7_sum),
    .sum_reg                (PE_out_7),
    .sum_reg_valid          (PE7_sum_reg_valid),
    .Data_reg_out           (PE_Data7)
);
PE_top PE8(
    .Data                   (MUX_out8),
    .Weight                 (Weight8),
    .rst_n                  (rst_n),
    .clk                    (clk),
    .Data_valid             (Data_valid),
    .Weight_valid           (Weight_valid),
    .sum                    (PE8_sum),
    .sum_reg                (PE_out_8),
    .sum_reg_valid          (PE8_sum_reg_valid),
    .Data_reg_out           (PE_Data8)
);
PE_top PE9(
    .Data                   (MUX_out9),
    .Weight                 (Weight9),
    .rst_n                  (rst_n),
    .clk                    (clk),
    .Data_valid             (Data_valid),
    .Weight_valid           (Weight_valid),
    .sum                    (PE9_sum),
    .sum_reg                (PE_out_9),
    .sum_reg_valid          (PE9_sum_reg_valid),
    .Data_reg_out           (PE_Data9)
);

quantize quantize(
    .clk                    (clk),
    .rst_n                  (rst_n),
    .Data_in_valid          (PE1_sum_reg_valid),
    .Data_in                (sum),
    .Data_out_valid         (sum_reg_valid),
    .Data_out               (sum_quantize)
);

assign Weight_valid = Weight_valid_reg ^ Weight_valid_reg_reg;

// ============================================
// Sum up the results of each PE
// ============================================
// Adder Tree
// Level 1
assign PE_out_10 = PE_out_1 + PE_out_2;
assign PE_out_11 = PE_out_3 + PE_out_4;
assign PE_out_12 = PE_out_5 + PE_out_6;
assign PE_out_13 = PE_out_7 + PE_out_8;

// Level 2
assign PE_out_14 = PE_out_10 + PE_out_11;
assign PE_out_15 = PE_out_12 + PE_out_13;

// Level 3
assign PE_out_16 = PE_out_14 + PE_out_15;

// Level 4
assign PE_out_17 = PE_out_9 + PE_out_16;

assign sum = datapath_rst ? 16'b0 : PE_out_17;

always @(negedge rst_n or posedge clk)
begin
    if (~rst_n)
        datapath_rst <= 1'b1;
    else
        datapath_rst <= #1 1'b0;
end

// always @(negedge rst_n or posedge clk)
// begin
//  if (~rst_n)
//  begin
//      sum_reg <= 16'b0;
//      sum_reg_valid <= 1'b0;
//  end
//  else
//  begin
//      sum_reg <= #1 sum_quantize;
//      sum_reg_valid <= #1 Data_out_valid;
//  end
// end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		Data1_reg <= #1 0;
		Data2_reg <= #1 0;
		Data3_reg <= #1 0;
	end
	else begin
		Data1_reg <= #1 Data1;
		Data2_reg <= #1 Data2;
		Data3_reg <= #1 Data3;
	end
end

// ============================================
// State Register
// ============================================
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        curr_state <= 5'b0;
    end
    else if (en) begin
        curr_state <= #1 next_state;
    end
    else begin
        curr_state <= 5'b0;
    end
end

// ============================================
// Next State Logic
// ============================================
always @(*) begin
    case (curr_state)
        5'd0    : begin
                    next_state = 5'd1;
        end
        5'd1    : begin
                    next_state = 5'd2;
        end
        5'd2    : begin
                    next_state = 5'd3;
        end
        5'd3    : begin
                    next_state = 5'd4;
        end
        5'd4    : begin
                    if (counter_col <= C-1) begin
                        next_state = 5'd4;
                    end 
                    else begin
                        next_state = 5'd8;
                    end
        end
        5'd5    : begin
                    next_state = 5'd6;
        end
        5'd6    : begin
                    if (counter_col <= C-4) next_state = 5'd6;
                    else next_state = 5'd9;
        end
        5'd7    : begin
                    if (counter_col <= C-4) next_state = 5'd7;
                    else next_state = 5'd10;
        end
        5'd8    : begin
                    if (counter_row == R-1) begin
                        next_state = 5'd0;
                    end
                    else begin
                        next_state = 5'd5;
                    end 
        end 
        5'd9    : begin
                    if (counter_row == R-1) begin
                        next_state = 5'd0;
                    end 
                    else begin
                        next_state = 5'd11;
                    end 
        end 
        5'd10   : begin
                    if (counter_row == R-1) begin
                        next_state = 5'd0;
                    end
                    else begin
                        next_state = 5'd5;
                    end 
        end 
        5'd11   : begin
                    next_state = 5'd7;
        end 
        
        default :   next_state = 5'd0;
    endcase
end

// ============================================
// Output Logic
// ============================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter_col_reg <= #1 10'b0;
        counter_row_reg <= #1 10'b0;
    end
    else begin
        counter_col_reg <= #1 counter_col;
        counter_row_reg <= #1 counter_row;
    end
end
always @(*) begin
    counter_col = 0;
    counter_row = 0;
    if(en) begin
        case (curr_state)
            5'd0    : begin
                        counter_col = counter_col_reg + 1;
                        counter_row = 0;
                        MUX4to1_sel = 2'd0;
                        MUX3to1_sel = 2'd0;
                        buf_in1 = 8'd0;
                        buf_in2 = 8'd0;
                        Data_valid = 1'b0;
            end
            5'd1    : begin
                        counter_col = counter_col_reg + 1;
                        counter_row = counter_row_reg;
                        MUX4to1_sel = 2'd0;
                        MUX3to1_sel = 2'd0;
                        buf_in1 = 8'd0;
                        buf_in2 = 8'd0;
                        Data_valid = 1'b0;
            end
            5'd2    : begin
                        counter_col = counter_col_reg + 1;
                        counter_row = counter_row_reg;
                        MUX4to1_sel = 2'd0;
                        MUX3to1_sel = 2'd0;
                        buf_in1 = 8'd0;
                        buf_in2 = 8'd0;
                        Data_valid = 1'b0;
            end
            5'd3    : begin
                        counter_col = counter_col_reg + 1;
                        counter_row = counter_row_reg;
                        MUX4to1_sel = 2'd0;
                        MUX3to1_sel = 2'd0;
                        buf_in1 = 8'd0;
                        buf_in2 = 8'd0;
                        Data_valid = 1'b1;
            end
            5'd4    : begin
                        counter_col = counter_col_reg + 1;
                        counter_row = counter_row_reg;
                        MUX4to1_sel = 2'd0;
                        MUX3to1_sel = 2'd0;
                        buf_in1 = PE_Data8;
                        buf_in2 = PE_Data9;
                        Data_valid = 1'b1;
            end
            5'd5    : begin
                        counter_col = counter_col_reg + 1;
                        counter_row = counter_row_reg;
                        MUX4to1_sel = 2'd3;
                        MUX3to1_sel = 2'd2;
                        buf_in1 = PE_Data2;
                        buf_in2 = PE_Data3;
                        Data_valid = 1'b1;
            end
            5'd6    : begin
                        counter_col = counter_col_reg + 1;
                        counter_row = counter_row_reg;
                        MUX4to1_sel = 2'd2;
                        MUX3to1_sel = 2'd1;
                        buf_in1 = PE_Data2;
                        buf_in2 = PE_Data3;
                        Data_valid = 1'b1;
            end
            5'd7    : begin
                        counter_col = counter_col_reg + 1;
                        counter_row = counter_row_reg;
                        MUX4to1_sel = 2'd1;
                        MUX3to1_sel = 2'd0;
                        buf_in1 = PE_Data8;
                        buf_in2 = PE_Data9;
                        Data_valid = 1'b1;
            end
            5'd8    : begin
                        if (counter_row == R-1) begin //FINISH
                            counter_col = 10'b0;
                            counter_row = 10'b0;
                        end
                        else begin
                            counter_col = 10'b0;
                            counter_row = counter_row_reg + 1;
                        end
                        MUX4to1_sel = 2'd0;
                        MUX3to1_sel = 2'd0;
                        buf_in1 = PE_Data8;
                        buf_in2 = PE_Data9;
                        Data_valid = 1'b1;
            end
            5'd9    : begin
                        if (counter_row == R-1) begin //FINISH
                            counter_col = 10'b0;
                            counter_row = 10'b0;
                        end
                        else begin
                            counter_col = 10'b0;
                            counter_row = counter_row_reg + 1;
                        end
                        MUX4to1_sel = 2'd2;
                        MUX3to1_sel = 2'd1;
                        buf_in1 = PE_Data2;
                        buf_in2 = PE_Data3;
                        Data_valid = 1'b1;
            end
            5'd10   : begin
                        if (counter_row == R-1) begin //FINISH
                            counter_col = 10'b0;
                            counter_row = 10'b0;
                        end
                        else begin
                            counter_col = 10'b0;
                            counter_row = counter_row_reg + 1;
                        end
                        MUX4to1_sel = 2'd1;
                        MUX3to1_sel = 2'd0;
                        buf_in1 = PE_Data8;
                        buf_in2 = PE_Data9;
                        Data_valid = 1'b1;
            end
            5'd11   : begin
                        counter_col = counter_col_reg + 1;
                        counter_row = counter_row_reg;
                        MUX4to1_sel = 2'd3;
                        MUX3to1_sel = 2'd2;
                        buf_in1 = PE_Data2;
                        buf_in2 = PE_Data3;
                        Data_valid = 1'b1;
            end
            default : begin
                        counter_col = 10'b0;
                        counter_row = 10'b0;
                        MUX4to1_sel = 2'd0;
                        MUX3to1_sel = 2'd0;
                        buf_in1 = 8'd0;
                        buf_in2 = 8'd0;
                        Data_valid = 1'b0;
            end
        endcase
    end
    else begin
        counter_col = 0;
        MUX4to1_sel = 2'd0;
        MUX3to1_sel = 2'd0;
        buf_in1 = 8'd0;
        buf_in2 = 8'd0;
        Data_valid = 1'b0;
    end
end

// ============================================
// Weight State Register Control
// ============================================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Weight_valid_reg <= #1 0;
    end
    else if(Weight_en) begin
        Weight_valid_reg <= #1 1;
    end
    else begin
        Weight_valid_reg <= #1 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Weight_valid_reg_reg <= #1 0;
    end
    else begin
        Weight_valid_reg_reg <= #1 Weight_valid_reg;
    end
end

endmodule