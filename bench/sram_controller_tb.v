module middle_section_tb;

reg									clk;
reg									rst_n;
reg									start;

// ============================================
// FSRAM1 (Real SRAM)
// ============================================
reg [`CHANNEL_OUT  * 8 - 1 : 0]	    data_in_1;
reg [`CHANNEL_OUT * 16 - 1 : 0]	    data_in_1_2;
wire								CENA_1;
wire								CENB_1;
wire [`SRAM_NUM - 1 : 0]			WENA_1;
wire [`SRAM_NUM - 1 : 0]			WENB_1;
wire [11:0]					        AA_1;
wire [`SRAM_NUM * 16 - 1 : 0]	    DA_1;
wire [11:0]					        AB_1;
wire [`SRAM_NUM * 16 - 1 : 0]	    DB_1;


// ============================================
// FSRAM2 (Real SRAM)
// ============================================
reg [`CHANNEL_OUT * 8 - 1 : 0]	    data_in_2;
reg [`CHANNEL_OUT * 16 - 1 : 0]	    data_in_2_2;
wire								CENA_2;
wire								CENB_2;
wire [`SRAM_NUM - 1 : 0]			WENA_2;
wire [`SRAM_NUM - 1 : 0]			WENB_2;
wire [11:0]					        AA_2;
wire [`SRAM_NUM * 16 - 1 : 0]	    DA_2;
wire [11:0]					        AB_2;
wire [`SRAM_NUM * 16 - 1 : 0]	    DB_2;


wire [`SRAM_NUM * 16 - 1 : 0]	    QA_1;
wire [`SRAM_NUM * 16 - 1 : 0]	    QB_1;
wire [`SRAM_NUM * 16 - 1 : 0]	    QA_2;
wire [`SRAM_NUM * 16 - 1 : 0]	    QB_2;

// ============================================
// IRSRAM 1 & 2 (Real SRAM)
// ============================================
wire								CEN1_ir;
wire	[`SRAM_NUM - 1 : 0]			WEN1_ir;
wire								CEN2_ir;
wire	[`SRAM_NUM - 1 : 0]			WEN2_ir;
wire	[7 - 1 : 0]					A1_ir;
wire	[`SRAM_NUM * 16 - 1 : 0]	D1_ir;
wire	[7 - 1 : 0]					A2_ir;
wire	[`SRAM_NUM * 16 - 1 : 0]	D2_ir;
wire 	[`SRAM_NUM * 16 - 1 : 0]	Q1_ir;
wire 	[`SRAM_NUM * 16 - 1 : 0]	Q2_ir;



reg		[99 * 8:0]					fin_name;
reg		[7 : 0]						data_mem_tmp[0 : `ROW * `COL - 1];
reg		[7 : 0]						data_mem[0 : 3 * `ROW - 1][0 : `COL - 1];

integer								fp;
integer								scan_i;
integer								i;
integer								j;
integer								clk_cycle_count;
integer								row;
integer								col;

integer								row_read;
integer								col_read;

reg [8 - 1 : 0]     counter_1;
//wire [2:0]                          curr_state_FSM;

reg 								loop;

sram_controller controller(
	.clk(clk),
	.rst_n(rst_n),
	.start(start),

    // ============================================
	// FSRAM1 (Real SRAM)
	// ============================================
	.data_in_1(data_in_1),
	.data_in_1_2(QB_1),
	.CENA_1(CENA_1),
	.CENB_1(CENB_1),
	.WENA_1(WENA_1),
	.WENB_1(WENB_1),
	.AA_1(AA_1),
	.DA_1(DA_1),
	.AB_1(AB_1),
	.DB_1(DB_1),

    // ============================================
	// FSRAM2 (Real SRAM)
	// ============================================
	.data_in_2(data_in_2),
	.data_in_2_2(QB_2),
	.CENA_2(CENA_2),
	.CENB_2(CENB_2),
	.WENA_2(WENA_2),
	.WENB_2(WENB_2),
	.AA_2(AA_2),
	.DA_2(DA_2),
	.AB_2(AB_2),
	.DB_2(DB_2),

    // ============================================
	// WSRAM (Real SRAM)
	// ============================================
	.weight_in(),
	.CEN_w(),
	.WEN_w(),
	.A_w(),
	.D_w(),

    // ============================================
	// IRSRAM (Real SRAM)
	// ============================================
	.CEN1_ir(CEN1_ir),
	.CEN2_ir(CEN2_ir),
	.WEN1_ir(WEN1_ir),
	.WEN2_ir(WEN2_ir),
	.A1_ir(A1_ir),
	.A2_ir(A2_ir),
	.D1_ir(D1_ir),
	.D2_ir(D2_ir),
	.Q1_ir(Q1_ir),
	.Q2_ir(Q2_ir),

    // ============================================
	// ORSRAM (Real SRAM)
	// ============================================
	.CEN_or(),
	.WEN_or(),
	.A_or(),
	.D_or(),


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
	// sram_sel1: For data process module to know which sram to be select
	// ============================================
    .sram_sel1(),
	.sram_sel2(),
	.data_process_reg(),

    // ============================================
	// FSRAM ready, tell CCM start to count
	// ============================================
    .CCM_en(),
	.CCM_en_cnt(),
	.Weight_en(),

	//for debug
	.curr_state_FSM()
);

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

irsram irsram1(
	.clk(clk),
	.CEN(CEN1_ir),
	.WEN(WEN1_ir),
	.A({`SRAM_NUM{A1_ir}}),
	.D(D1_ir),
	.Q(Q1_ir)
);

irsram irsram2(
	.clk(clk),
	.CEN(CEN2_ir),
	.WEN(WEN2_ir),
	.A({`SRAM_NUM{A2_ir}}),
	.D(D2_ir),
	.Q(Q2_ir)
);


initial begin
	$fsdbDumpfile("wave/middle_section_tb.fsdb");
	$fsdbDumpvars(0, middle_section_tb);

	for(i = 0; i < 3; i = i + 1) begin
		fin_name = $sformatf("./bench/input_256x16/input%0d.txt", i+1);
		fp = $fopen(fin_name, "r");

		for(row = 0; row < `ROW; row = row + 1)begin
			for(col = 0; col < `COL; col = col + 1)begin
				scan_i = $fscanf(fp, "%h", data_mem[row + i * `ROW][col]);
			end
		end
	end

	//display_datamem();
	row_read = 0;
	col_read = 0;
	i = 0;
	row = 0;
	col = 0;

	clk = 0;
	rst_n = 0;
	start = 0;
	//counter_1 = 0;
	clk_cycle_count = 0;
	#1 rst_n = 0;
	#3 rst_n = 1;

	#5
	start = 1;
	loop = 1;
	
end

// initial begin
// 	#500000  $finish;
// end

// ============================================
// Simulate data output from DRAM
// ============================================

always@(*)begin
	if(controller.FSM_flag == `ACTIVATE_TOP_FSM0)begin		
		if(controller.curr_state0 == 0)begin
			row = 0;
			col = 0;
		end
		else if(controller.curr_state0 == 1)begin
			if(row <= 2 - 1)begin
				row = row + 1;
				col = col;
			end
			else begin
				if(row % 2 == 0)begin
					row = row;
					col = col - 1;
				end
				else begin
					row = row;
					col = col + 1;
				end
			end
		end
		else if(controller.curr_state0 == 2) begin
			if(row <= 2 - 1)begin
				if(row == 2 - 1 && col == `COL - 1)begin
					row = row + 1;
					col = col;
				end
				else begin
					row = row - 1;
					col = col + 1;
				end
			end
			else begin
				if(row % 2 == 0)begin
					if(col == 0)begin
						row = row + 1;
						col = col;
					end
					else begin
						row = row;
						col = col - 1;
					end
				end
				else begin
					if(col == `COL - 1)begin
						row = row + 1;
						col = col;
					end
					else begin
						row = row;
						col = col + 1;
					end
				end
			end
		end
		
	end
	else if(controller.FSM_flag == `ACTIVATE_MIDDLE_FSM0) begin
		if(controller.curr_state_FSM0_middleSection == 0)begin
			row = row;
			col = 0;
		end
		else begin
			if(row % 2 == 1)begin
				if(col == 0)begin
					row = row + 1;
					col = col;
				end
				else begin
					row = row;
					col = col - 1;
				end
			end
			else begin
				if(col == `COL - 1)begin
					row = row + 1;
					col = col;
				end
				else begin
					row = row;
					col = col + 1;
				end
			end
		end
		
	end
end

always@(posedge clk)begin
	#1
	clk_cycle_count <= clk_cycle_count + 1;
	data_in_1 <= {`CHANNEL_OUT{data_mem[row][col]}};

	if(row_read >= `ROW * 3)begin
		$finish;
	end
end

always@(negedge clk)begin
	if (controller.FSM_flag == `ACTIVATE_TOP_FSM1) begin
		#1
		case (controller.curr_state1)
			5'd2: begin
				if(QB_1[16 - 1 : 0] == {data_mem[row_read][col_read], data_mem[row_read + 1][col_read]})begin
					$display("============== CORRECT =============");
				end
				else begin
					$display("TOP, curr_state1 = 2, ERROR : row = %0d, col = %0d, data_mem = %0h, QB_1(16bit) = %0h", 
							row_read, col_read, {data_mem[row_read][col_read], data_mem[row_read + 1][col_read]} , QB_1[16 - 1 : 0]);
				end
				
				if(col_read == `COL - 1)begin
					row_read <= row_read + 2;
					col_read <= col_read;
				end
				else begin
					row_read <= row_read;
					col_read <= col_read + 1;
				end
				
			end
			5'd3: begin
				if(QB_1[16 - 1 : 0] == {data_mem[row_read][col_read], data_mem[row_read][col_read - 1]})begin
					$display("============== CORRECT =============");
				end
				else begin
					$display("TOP, curr_state1 = 3, ERROR : row = %0d, col = %0d, data_mem = %0h, QB_1(16bit) = %0h", 
							row_read, col_read, {data_mem[row_read][col_read], data_mem[row_read][col_read - 1]} , QB_1[16 - 1 : 0]);
				end
				
				row_read <= row_read;
				col_read <= col_read - 2;
			end
			5'd4: begin
				if(QB_1[16 - 1 : 0] == {data_mem[row_read][col_read], data_mem[row_read][col_read - 1]})begin
					$display("============== CORRECT =============");
				end
				else begin
					$display("TOP, curr_state1 = 4, ERROR : row = %0d, col = %0d, data_mem = %0h, QB_1(16bit) = %0h", 
							row_read, col_read, {data_mem[row_read][col_read], data_mem[row_read][col_read - 1]} , QB_1[16 - 1 : 0]);
				end
				
				if(col_read == 1)begin
					row_read <= row_read + 1;
					col_read <= col_read - 1;
				end
				else begin
					row_read <= row_read;
					col_read <= col_read - 2;
				end
				
			end
			5'd7: begin
				if(QB_1[16 - 1 : 0] == {data_mem[row_read][col_read], data_mem[row_read][col_read + 1]})begin
					$display("============== CORRECT =============");
				end
				else begin
					$display("TOP, curr_state1 = 7, ERROR : row = %0d, col = %0d, data_mem = %0h, QB_1(16bit) = %0h", 
							row_read, col_read, {data_mem[row_read][col_read], data_mem[row_read][col_read + 1]} , QB_1[16 - 1 : 0]);
				end
				
				row_read <= row_read;
				col_read <= col_read + 2;
				
			end
			5'd8: begin
				if(QB_1[16 - 1 : 0] == {data_mem[row_read][col_read], data_mem[row_read][col_read + 1]})begin
					$display("============== CORRECT =============");
				end
				else begin
					$display("TOP, curr_state1 = 8, ERROR : row = %0d, col = %0d, data_mem = %0h, QB_1(16bit) = %0h", 
							row_read, col_read, {data_mem[row_read][col_read], data_mem[row_read][col_read + 1]} , QB_1[16 - 1 : 0]);
				end
				
				if(col_read == `COL - 2)begin
					if(row_read != 0 && row_read % 15 == 0)begin
						row_read <= row_read + 1;
						col_read <= 0;
					end
					else begin
						row_read <= row_read + 1;
						col_read <= col_read + 1;
					end
					
				end
				else begin
					row_read <= row_read;
					col_read <= col_read + 2;
				end
			end
			default: begin
				row_read <= row_read;
				col_read <= col_read;
			end
		endcase
	end
	else if (controller.FSM_flag == `ACTIVATE_MIDDLE_FSM1) begin
		#1
		case (controller.curr_state_FSM1_middleSection)
			4'd0: begin
				row_read <= row_read;
				col_read <= 0;
			end
			4'd1:begin
				row_read <= row_read;
				col_read <= col_read;
			end
			4'd2: begin
				if(QB_1[16 - 1 : 0] == {data_mem[row_read][col_read], data_mem[row_read][col_read + 1]})begin
					$display("============== CORRECT =============");
				end
				else begin
					$display("MIDDLE, curr_state_FSM1_middleSection = 2, ERROR : row = %0d, col = %0d, data_mem = %0h, QB_1(16bit) = %0h", 
							row_read, col_read, {data_mem[row_read][col_read], data_mem[row_read][col_read + 1]} , QB_1[16 - 1 : 0]);
				end
				
				if(Q2_ir[16 - 1: 0] == {data_mem[row_read - 2][col_read], data_mem[row_read - 1][col_read]})begin
					$display("============== CORRECT (IRSRAM) =============");
				end
				else begin
					$display("MIDDLE(IRSRAM), curr_state_FSM1_middleSection = 2, ERROR : row = %0d, col = %0d, data_mem = %0h, Q2_ir(16bit) = %0h", 
							row_read, col_read, {data_mem[row_read - 2][col_read], data_mem[row_read - 1][col_read]} , Q2_ir[16 - 1 : 0]);
				end

				row_read <= row_read;
				col_read <= col_read + 1;
			end
			4'd3: begin
				if(Q1_ir[16 - 1: 0] == {data_mem[row_read - 2][col_read], data_mem[row_read - 1][col_read]})begin
					$display("============== CORRECT (IRSRAM) =============");
				end
				else begin
					$display("MIDDLE(IRSRAM), curr_state_FSM1_middleSection = 3, ERROR : row = %0d, col = %0d, data_mem = %0h, Q1_ir(16bit) = %0h", 
							row_read, col_read,  {data_mem[row_read - 2][col_read], data_mem[row_read - 1][col_read]} , Q1_ir[16 - 1 : 0]);
				end

				if(col_read == `COL - 1)begin
					row_read <= row_read + 1;
					col_read <= col_read;
				end
				else begin
					row_read <= row_read;
					col_read <= col_read + 1;
				end
			end
			4'd4: begin
				if(QB_1[16 - 1 : 0] == {data_mem[row_read][col_read], data_mem[row_read][col_read - 1]})begin
					$display("============== CORRECT =============");
				end
				else begin
					$display("MIDDLE, curr_state_FSM1_middleSection = 4, ERROR : row = %0d, col = %0d, data_mem = %0h, QB_1(16bit) = %0h", 
							row_read, col_read, {data_mem[row_read][col_read], data_mem[row_read][col_read - 1]} , QB_1[16 - 1 : 0]);
				end

				row_read <= row_read;
				col_read <= col_read - 2;
			end
			4'd5: begin
				if(QB_1[16 - 1 : 0] == {data_mem[row_read][col_read], data_mem[row_read][col_read - 1]})begin
					$display("============== CORRECT =============");
				end
				else begin
					$display("MIDDLE, curr_state_FSM1_middleSection = 5, ERROR : row = %0d, col = %0d, data_mem = %0h, QB_1(16bit) = %0h", 
							row_read, col_read, {data_mem[row_read][col_read], data_mem[row_read][col_read - 1]} , QB_1[16 - 1 : 0]);
				end
				
				if(col_read == 1)begin
					row_read <= row_read + 1;
					col_read <= col_read - 1;
				end
				else begin
					row_read <= row_read;
					col_read <= col_read - 2;
				end
			end
			4'd8: begin
				if(QB_1[16 - 1 : 0] == {data_mem[row_read][col_read], data_mem[row_read][col_read + 1]})begin
					$display("============== CORRECT =============");
				end
				else begin
					$display("MIDDLE, curr_state_FSM1_middleSection = 8, ERROR : row = %0d, col = %0d, data_mem = %0h, QB_1(16bit) = %0h", 
							row_read, col_read, {data_mem[row_read][col_read], data_mem[row_read][col_read + 1]} , QB_1[16 - 1 : 0]);
				end
				
				row_read <= row_read;
				col_read <= col_read + 2;
			end
			4'd9: begin
				if(QB_1[16 - 1 : 0] == {data_mem[row_read][col_read], data_mem[row_read][col_read + 1]})begin
					$display("============== CORRECT =============");
				end
				else begin
					$display("MIDDLE, curr_state_FSM1_middleSection = 9, ERROR : row = %0d, col = %0d, data_mem = %0h, QB_1(16bit) = %0h", 
							row_read, col_read, {data_mem[row_read][col_read], data_mem[row_read][col_read + 1]} , QB_1[16 - 1 : 0]);
				end
				
				if(col_read == `COL - 2)begin
					row_read <= row_read + 1;
					col_read <= col_read + 1;
				end
				else begin
					row_read <= row_read;
					col_read <= col_read + 2;
				end
			end
			default: begin
				row_read <= row_read;
				col_read <= col_read;
			end
		endcase
	end
end

always #`HALF_CLK clk = ~clk;


task display_datamem();
	begin
		for(i = 0; i < 3; i = i + 1) begin
			$display("=============== i = %d =============", i);
			for(row = 0; row < `ROW; row = row + 1)begin
				for(col = 0; col < `COL; col = col + 1)begin
					$display("%0h", data_mem[row + i * `ROW][col]);
				end
			end
		end
	end
endtask

endmodule
