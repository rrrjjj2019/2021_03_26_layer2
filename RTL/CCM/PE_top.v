module PE_top(
    input               clk,
    input               rst_n,
    input               Data_valid,
    input       [7:0]   Data,
    input               Weight_valid,
    input       [7:0]   Weight,
    output      [15:0]  sum,
    output  reg [15:0]  sum_reg,
    output  reg         sum_reg_valid,
    output      [7:0]   Data_reg_out
    );

reg         [7:0]   Data_reg;
reg                 Data_valid_reg;

reg         [7:0]   Weight_reg;
reg         [7:0]   Weight_stable_reg;
reg                 Weight_valid_reg;

reg                 MSB_weight_reg;

wire                MSB_out;

reg                 datapath_rst;

// ============================================
// Declare Module : sPE => 8
// ============================================

assign sum = $signed(Data_reg)*$signed(Weight_stable_reg);
assign Data_reg_out = datapath_rst ? 8'b0 : Data_reg;

always @(negedge rst_n or posedge clk)
begin
    if (~rst_n)
        datapath_rst <= 1'b1;
    else
        datapath_rst <= 1'b0;
end

always @(negedge rst_n or posedge clk)
begin
    if (~rst_n)
    begin
        Data_reg <= #1 8'b0;
        Data_valid_reg <= #1 1'b0;
        Weight_reg <= #1 8'b0;
        Weight_valid_reg <= #1 1'b0;
        sum_reg <= #1 16'b0;
        sum_reg_valid <= #1 1'b0;
        MSB_weight_reg <= #1 1'b0;
    end
    else
    begin
        Data_reg <= #1 Data;
        Data_valid_reg <= #1 Data_valid;
        Weight_reg <= #1 Weight;
        Weight_valid_reg <= #1 Weight_valid;
        sum_reg <= #1 sum;
        sum_reg_valid <= #1 Data_valid_reg;
        MSB_weight_reg <= #1 Weight[7];
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Weight_stable_reg <= #1 8'b0;
    end
    else if(Weight_valid_reg) begin
        Weight_stable_reg <= #1 Weight_reg;
    end
    else begin
        Weight_stable_reg <= #1 Weight_stable_reg;
    end
end

endmodule