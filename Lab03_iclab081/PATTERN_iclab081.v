`ifdef RTL
    `define CYCLE_TIME 40.0
`endif
`ifdef GATE
    `define CYCLE_TIME 40.0
`endif
`define PAT_NUM 1000

module PATTERN(
	//OUTPUT
	rst_n,
	clk,
	in_valid,
	tetrominoes,
	position,
	//INPUT
	tetris_valid,
	score_valid,
	fail,
	score,
	tetris
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
output reg			rst_n, clk, in_valid;
output reg	[2:0]	tetrominoes;
output reg  [2:0]	position;
input 				tetris_valid, score_valid, fail;
input 		[3:0]	score;
input		[71:0]	tetris;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
integer patnum = `PAT_NUM;
integer i_pat, a, tetris_i;
integer f_in;
integer value1, value2;
integer latency;
integer total_latency;
integer out_num;
integer status;
integer scan_count;
integer redunc;
real CYCLE = `CYCLE_TIME;
			
//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg golden_fail;
reg [3:0] golden_score;
reg [71:0] golden_tetris;
reg [95:0] golden_tetris_temp;
reg new_round;
reg [127:0] line;

//---------------------------------------------------------------------
//  CLOCK
//---------------------------------------------------------------------
always #(CYCLE/2.0) clk = ~clk;

//---------------------------------------------------------------------
//  SIMULATION
//---------------------------------------------------------------------
initial begin
	f_in = $fopen("../00_TESTBED/input.txt", "r");
	if (f_in == 0) begin
		$display("Failed to open input.txt");
		$finish;
	end

	reset_task;

	for (i_pat = 0; i_pat < patnum; i_pat = i_pat + 1) begin
		golden_fail = 1'b0;
		golden_score = 4'b0;
		golden_tetris = 72'b0;
		golden_tetris_temp = 96'b0;
		for (tetris_i = 0; tetris_i < 16; tetris_i = tetris_i + 1) begin
			input_task(value1, value2, golden_fail, golden_score, golden_tetris_temp);
			wait_out_valid_task(latency);
			check_ans_task(value1, value2, golden_fail, golden_score, golden_tetris_temp, latency);
			if (golden_fail === 1'b1) begin
				for(redunc = tetris_i + 1; redunc < 16; redunc = redunc + 1) begin
					input_task_redunc;
				end
				break;
			end
		end
	end

	YOU_PASS_task;
end

task reset_task; begin 
	rst_n = 1'b1;
	in_valid = 1'b0;
	tetrominoes = 3'bxxx;
	position = 3'bxxx;
	total_latency = 0;

	golden_fail = 1'b0;
	golden_score = 4'b0;
	golden_tetris = 72'b0;
	golden_tetris_temp = 96'b0;

	force clk = 0;

	// Apply reset
	#CYCLE; rst_n = 1'b0; 
	#CYCLE; rst_n = 1'b1;

	#(100 - CYCLE);
	
	// Check initial conditions
	if (tetris_valid !== 1'b0 || score_valid !== 1'b0 || fail !== 1'b0 || score !== 4'b0 || tetris !== 72'b0) begin
		$display("                    SPEC-4 FAIL                   ");
		repeat (2) #CYCLE;
		$finish;
	end
	#CYCLE; release clk;
end endtask

task input_task; 
	inout integer value1;
	inout integer value2;
	inout reg golden_fail;
	inout reg [3:0] golden_score;
	inout reg [95:0] golden_tetris_temp;

	begin
		repeat (10) @(negedge clk);
		while (!$feof(f_in)) begin
			status = $fgets(line, f_in);

			if (status == 0) begin
				$display("Error or end of file reached");
			end else begin
				if (line == "" || line == "\n" || line == " ") begin
					in_valid = 1'b0;
					tetrominoes = 3'bxxx;
					position = 3'bxxx;
					golden_fail = 1'b0;
					golden_score = 4'b0;
					golden_tetris = 72'b0;
					golden_tetris_temp = 96'b0;
					@(negedge clk);
					// break;
				end else begin
					scan_count = $sscanf(line, "%d %d", value1, value2);
					case (scan_count)
						1: continue;
						2: begin
							in_valid = 1'b1;
							tetrominoes = value1;
							position = value2;
							@(negedge clk);
							break;
						end
						default: $display("Unexpected content in the line.");
					endcase
					
				end
			end
		end

		in_valid = 1'b0;
		tetrominoes = 3'bxxx;
		position = 3'bxxx;
	end 
endtask

task input_task_redunc;
begin
	while (!$feof(f_in)) begin
		status = $fgets(line, f_in);
		break;
	end
end
endtask

task wait_out_valid_task; 
	inout integer latency;

	begin
		latency = 1;
		while (score_valid !== 1'b1) begin
			latency = latency + 1;
			if (score !== 0 || fail !== 0 || tetris_valid !== 0) begin
				$display("                    SPEC-5 FAIL                   ");
				repeat (2) @(negedge clk);
				$finish;
			end
			if (latency >= 1000) begin
				$display("                    SPEC-6 FAIL                   ");
				repeat (2) @(negedge clk);
				$finish;
			end
			@(negedge clk);
		end
		total_latency = total_latency + latency;
	end 
endtask

task check_ans_task; 
	inout integer value1;
	inout integer value2;
	inout reg golden_fail;
	inout reg [3:0] golden_score;
	inout reg [95:0] golden_tetris_temp;
	inout integer latency;

	begin
		out_num = 0;
		cal_golden_ans(value1, value2, golden_fail, golden_score, golden_tetris_temp);
		golden_tetris = golden_tetris_temp[71:0];

		if (tetris_valid === 1'b0 && tetris !== 0) begin
			$display("                    SPEC-5 FAIL                   ");
			repeat (2) @(negedge clk);
			$finish;
		end

		while (score_valid === 1'b1) begin
			latency = latency + 1;
			if (latency >= 1000) begin
				$display("                    SPEC-6 FAIL                   ");
				repeat (2) @(negedge clk);
				$finish;
			end

			if (out_num == 0) begin
				if (golden_score !== score || golden_fail !== fail) begin
					$display("                    SPEC-7 FAIL                   ");
					repeat (2) @(negedge clk);
					$finish;
				end if (tetris_valid == 1 && golden_tetris !== tetris) begin
					$display("                    SPEC-7 FAIL                   ");
					repeat (2) @(negedge clk);
					$finish;
				end else begin
					@(negedge clk);
					out_num = out_num + 1;
				end
			end else begin
				@(negedge clk);
				out_num = out_num + 1;
			end
		end

		if (out_num !== 1) begin
			$display("                    SPEC-8 FAIL                   ");
			repeat (2) @(negedge clk);
			$finish;
		end

		if (tetris_valid == 1) begin
			out_num = 0;
			while (tetris_valid === 1'b1) begin
				if (golden_tetris !== tetris) begin
					$display("                    SPEC-7 FAIL                   ");
					repeat (2) @(negedge clk);
					$finish;
				end else begin
					@(negedge clk);
					out_num = out_num + 1;
				end
			end
		end

		if (out_num !== 1) begin
			$display("                    SPEC-8 FAIL                   ");
			repeat (2) @(negedge clk);
			$finish;
		end
		// end
		
		#((($urandom % 4) + 1) * CYCLE);
		
	end 
endtask

task YOU_PASS_task; begin
	$display("                  Congratulations!               ");
	$display("              execution cycles = %7d", total_latency);
	$display("              clock period = %4fns", CYCLE);
	repeat (2) @(negedge clk);
    $finish;
end endtask

task cal_golden_ans; 
	inout integer value1;
	inout integer position;
	inout reg golden_fail;
	inout reg [3:0] golden_score;
	inout reg [95:0] golden_tetris_temp;

	begin
		integer i, j;
		case (value1)
			0: begin
				for (i = 12; i >= 0; i = i - 1) begin
					if ((golden_tetris_temp[6*i + position] | golden_tetris_temp[6*i + position + 1] | 
					golden_tetris_temp[6*(i+1) + position] | golden_tetris_temp[6*(i+1) + position + 1]) !== 0) begin
						golden_tetris_temp[6*(i+1) + position] = 1;
						golden_tetris_temp[6*(i+1) + position + 1] = 1;
						golden_tetris_temp[6*(i+2) + position] = 1;
						golden_tetris_temp[6*(i+2) + position + 1] = 1;
						break;
					end
					if ( i == 0) begin
						golden_tetris_temp[6*i+ + position] = 1;
						golden_tetris_temp[6*i + position + 1] = 1;
						golden_tetris_temp[6*(i+1) + position] = 1;
						golden_tetris_temp[6*(i+1) + position + 1] = 1;
					end
				end
			end

			1: begin
				for (i = 12; i >= 0; i = i - 1) begin
					if ((golden_tetris_temp[6*i + position] | golden_tetris_temp[6*(i+1) + position] | 
					golden_tetris_temp[6*(i+2) + position] | golden_tetris_temp[6*(i+3) + position]) !== 0) begin
						golden_tetris_temp[6*(i+1) + position] = 1;
						golden_tetris_temp[6*(i+2) + position] = 1;
						golden_tetris_temp[6*(i+3) + position] = 1;
						golden_tetris_temp[6*(i+4) + position] = 1;
						break;
					end

					if (i == 0) begin
						golden_tetris_temp[6*i + position] = 1;
						golden_tetris_temp[6*(i+1) + position] = 1;
						golden_tetris_temp[6*(i+2) + position] = 1;
						golden_tetris_temp[6*(i+3) + position] = 1;
					end
				end
			end

			2: begin
				for (i = 12; i >= 0; i = i - 1) begin
					if ((golden_tetris_temp[6*i + position] | golden_tetris_temp[6*i + position + 1] | 
					golden_tetris_temp[6*i + position + 2] | golden_tetris_temp[6*i + position + 3]) !== 0) begin
						golden_tetris_temp[6*(i+1) + position] = 1;
						golden_tetris_temp[6*(i+1) + position + 1] = 1;
						golden_tetris_temp[6*(i+1) + position + 2] = 1;
						golden_tetris_temp[6*(i+1) + position + 3] = 1;
						break;
					end

					if (i == 0) begin
						golden_tetris_temp[6*i + position] = 1;
						golden_tetris_temp[6*i + position + 1] = 1;
						golden_tetris_temp[6*i + position + 2] = 1;
						golden_tetris_temp[6*i + position + 3] = 1;
					end
				end
			end

			3: begin
				for (i = 12; i >= 0; i = i - 1) begin
					if ((golden_tetris_temp[6*i + position + 1] | golden_tetris_temp[6*(i+1) + position + 1] | 
					golden_tetris_temp[6*(i+2) + position] | golden_tetris_temp[6*(i+2) + position + 1]) !== 0) begin
						golden_tetris_temp[6*(i+1) + position + 1] = 1;
						golden_tetris_temp[6*(i+2) + position + 1] = 1;
						golden_tetris_temp[6*(i+3) + position] = 1;
						golden_tetris_temp[6*(i+3) + position + 1] = 1;
						break;
					end

					if (i == 0) begin
						golden_tetris_temp[6*i + position + 1] = 1;
						golden_tetris_temp[6*(i+1) + position + 1] = 1;
						golden_tetris_temp[6*(i+2) + position] = 1;
						golden_tetris_temp[6*(i+2) + position + 1] = 1;
					end
				end
			end

			4: begin
				for (i = 12; i >= 0; i = i - 1) begin
					if ((golden_tetris_temp[6*i + position] | golden_tetris_temp[6*(i+1) + position] | 
					golden_tetris_temp[6*(i+1) + position + 1] | golden_tetris_temp[6*(i+1) + position + 2]) !== 0) begin
						golden_tetris_temp[6*(i+1) + position] = 1;
						golden_tetris_temp[6*(i+2) + position] = 1;
						golden_tetris_temp[6*(i+2) + position + 1] = 1;
						golden_tetris_temp[6*(i+2) + position + 2] = 1;
						break;
					end

					if (i == 0) begin
						golden_tetris_temp[6*i + position] = 1;
						golden_tetris_temp[6*(i+1) + position] = 1;
						golden_tetris_temp[6*(i+1) + position + 1] = 1;
						golden_tetris_temp[6*(i+1) + position + 2] = 1;
					end
				end
			end

			5: begin
				for (i = 12; i >= 0; i = i - 1) begin
					if ((golden_tetris_temp[6*i + position] | golden_tetris_temp[6*i + position + 1] | 
					golden_tetris_temp[6*(i+1) + position] | golden_tetris_temp[6*(i+2) + position]) !== 0) begin
						golden_tetris_temp[6*(i+1) + position] = 1;
						golden_tetris_temp[6*(i+1) + position + 1] = 1;
						golden_tetris_temp[6*(i+2) + position] = 1;
						golden_tetris_temp[6*(i+3) + position] = 1;
						break;
					end

					if (i == 0) begin
						golden_tetris_temp[6*i + position] = 1;
						golden_tetris_temp[6*i + position + 1] = 1;
						golden_tetris_temp[6*(i+1) + position] = 1;
						golden_tetris_temp[6*(i+2) + position] = 1;
					end
				end
			end

			6: begin
				for (i = 12; i >= 0; i = i - 1) begin
					if ((golden_tetris_temp[6*i + position + 1] | golden_tetris_temp[6*(i+1) + position] | 
					golden_tetris_temp[6*(i+1) + position + 1] | golden_tetris_temp[6*(i+2) + position]) !== 0) begin
						golden_tetris_temp[6*(i+1) + position + 1] = 1;
						golden_tetris_temp[6*(i+2) + position] = 1;
						golden_tetris_temp[6*(i+2) + position + 1] = 1;
						golden_tetris_temp[6*(i+3) + position] = 1;
						break;
					end

					if (i == 0) begin
						golden_tetris_temp[6*i + position + 1] = 1;
						golden_tetris_temp[6*(i+1) + position] = 1;
						golden_tetris_temp[6*(i+1) + position + 1] = 1;
						golden_tetris_temp[6*(i+2) + position] = 1;
					end
				end
			end

			7: begin
				for (i = 12; i >= 0; i = i - 1) begin
					if ((golden_tetris_temp[6*i + position] | golden_tetris_temp[6*i + position + 1] | 
					golden_tetris_temp[6*(i+1) + position + 1] | golden_tetris_temp[6*(i+1) + position + 2]) !== 0) begin
						golden_tetris_temp[6*(i+1) + position] = 1;
						golden_tetris_temp[6*(i+1) + position + 1] = 1;
						golden_tetris_temp[6*(i+2) + position + 1] = 1;
						golden_tetris_temp[6*(i+2) + position + 2] = 1;
						break;
					end

					if ( i == 0) begin
						golden_tetris_temp[6*i + position] = 1;
						golden_tetris_temp[6*i + position + 1] = 1;
						golden_tetris_temp[6*(i+1) + position + 1] = 1;
						golden_tetris_temp[6*(i+1) + position + 2] = 1;
					end
				end
			end

		endcase

		i = 0;
		while (i < 12) begin
			if (&golden_tetris_temp[(6*i + 5) -: 6] == 1) begin
				for (j = i; j < 16; j = j + 1) begin
					golden_tetris_temp[6*j] = golden_tetris_temp[6*(j+1)];
					golden_tetris_temp[6*j + 1] = golden_tetris_temp[6*(j+1) + 1];
					golden_tetris_temp[6*j + 2] = golden_tetris_temp[6*(j+1) + 2];
					golden_tetris_temp[6*j + 3] = golden_tetris_temp[6*(j+1) + 3];
					golden_tetris_temp[6*j + 4] = golden_tetris_temp[6*(j+1) + 4];
					golden_tetris_temp[6*j + 5] = golden_tetris_temp[6*(j+1) + 5];
				end
				golden_tetris_temp[95:90] = 6'b0;
				golden_score = golden_score + 1;
			end else begin
				i = i + 1;
			end
		end

		if (|golden_tetris_temp[95:72] !== 0) begin
			golden_fail = 1'b1;
		end
	end 
endtask

endmodule
