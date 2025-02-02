/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: TETRIS
// FILE NAME: TETRIS.v
// VERSRION: 1.0
// DATE: August 15, 2024
// AUTHOR: Yu-Hsuan Hsu, NYCU IEE
// DESCRIPTION: ICLAB2024FALL / LAB3 / TETRIS
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/
module TETRIS (
	//INPUT
	rst_n,
	clk,
	in_valid,
	tetrominoes,
	position,
	//OUTPUT
	tetris_valid,
	score_valid,
	fail,
	score,
	tetris
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
input				rst_n, clk, in_valid;
input		[2:0]	tetrominoes;
input		[2:0]	position;
output reg			tetris_valid, score_valid, fail;
output reg	[3:0]	score;
output reg 	[71:0]	tetris;


//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
parameter IDLE = 2'd0;
parameter INPUT = 2'd1;
parameter CALC = 2'd2;
parameter OUTPUT = 2'd3;

integer i;

//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg [1:0] current_state, next_state;
reg [3:0] round_counter;
reg [2:0] tetrominoes_reg, position_reg;
reg [3:0] score_reg;
reg [5:0] row [13:0];
reg [5:0] row_temp [13:0];
reg [3:0] score_temp;

//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

always @(*) begin
	case (current_state) 
		IDLE:next_state = in_valid ? INPUT : IDLE;
		INPUT: next_state = CALC;
		CALC: next_state = OUTPUT;
		OUTPUT: next_state = IDLE;
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		round_counter <= 4'd0;
	end else begin
		if (fail == 1'b1) begin
			round_counter <= 4'd0;
		end else if (current_state == OUTPUT) begin
			round_counter <= round_counter + 1;
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		tetrominoes_reg <= 3'd0;
	end else begin
		tetrominoes_reg <= (next_state == INPUT) ? tetrominoes : tetrominoes_reg;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		position_reg <= 3'd0;
	end else begin
		position_reg <= (next_state == INPUT) ? position : position_reg;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for (i = 0; i < 14; i = i + 1) begin
			row[i] <= 6'b0;
		end
		score_reg <= 4'd0;
	end else begin
		if (round_counter == 4'd0 && next_state == INPUT) begin
			for (i = 0; i < 14; i = i + 1) begin
				row[i] <= 6'b0;
			end
			score_reg <= 4'd0;
		end else if (next_state == CALC) begin
			row_calc(row, tetrominoes_reg, position_reg, score_reg, row_temp, score_temp);
			row <= row_temp;
			score_reg <= score_reg + score_temp;
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		score_valid <= 0;
	end else begin
		score_valid <= (next_state == OUTPUT) ? 1'b1 : 1'b0;
	end	
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		score <= 0;
	end else begin
		score <= (next_state == OUTPUT) ? score_reg : 4'd0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		fail <= 1'b0;
	end else begin
		fail <= (next_state == OUTPUT) ? ((|row[12]) | (|row[13])) : 1'b0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		tetris_valid <= 1'b0;
	end else begin
		if (next_state == OUTPUT) begin
			if (round_counter == 4'd15 || ((|row[12]) | (|row[13]))) begin
				tetris_valid <= 1'b1;
			end else begin
				tetris_valid <= 1'b0;
			end
		end else begin
			tetris_valid <= 1'b0;
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		tetris <= 72'b0;
	end else begin
		if (next_state == OUTPUT) begin
			if (round_counter == 4'd15 || ((|row[12]) | (|row[13]))) begin
				tetris[71:66] <= row[11];
				tetris[65:60] <= row[10];
				tetris[59:54] <= row[9];
				tetris[53:48] <= row[8];
				tetris[47:42] <= row[7];
				tetris[41:36] <= row[6];
				tetris[35:30] <= row[5];
				tetris[29:24] <= row[4];
				tetris[23:18] <= row[3];
				tetris[17:12] <= row[2];
				tetris[11:6] <= row[1];
				tetris[5:0] <= row[0];
			end else begin
				tetris <= 72'b0;
			end
		end else begin
			tetris <= 72'b0;
		end
	end
end

task row_calc;
	input [5:0] row [13:0];
	input [2:0] tetrominoes_reg;
	input [2:0] position_reg;
	input [3:0] score_reg;
	output [5:0] row_temp [13:0];
	output [3:0] score_temp;

	begin
		row_temp = row;
		score_temp = score;
		assign_row_value(row_temp, tetrominoes_reg, position_reg);
		clear_and_refine(row_temp, score_temp);
	end
endtask

task assign_row_value;
	inout [5:0] row [13:0];
	input [2:0] tetrominoes_reg;
	input [2:0] position_reg;
	integer i;
	reg break_flag;

	begin
		break_flag = 1'b0;
		case (tetrominoes_reg)
			0: begin
				for (i = 11; i >= 0; i = i - 1) begin
					if (row[i][position_reg] | row[i][position_reg +1] | row[i+1][position_reg] | row[i+1][position_reg +1] == 1'b1) begin
						row[i+1][position_reg] = 1'b1;
						row[i+1][position_reg +1] = 1'b1;
						row[i+2][position_reg] = 1'b1;
						row[i+2][position_reg +1] = 1'b1;
						break_flag = 1'b1;
						break;
					end 
				end

				if (break_flag == 1'b0) begin
					row[0][position_reg] = 1'b1;
					row[0][position_reg +1] = 1'b1;
					row[1][position_reg] = 1'b1;
					row[1][position_reg +1] = 1'b1;
				end
			end

			1: begin
				if (row[11][position_reg] == 1'b1) begin
					row[12][position_reg] = 1'b1;
					break_flag = 1'b1;
				end else if (row[10][position_reg] == 1'b1) begin
					row[11][position_reg] = 1'b1;
					row[12][position_reg] = 1'b1;
					row[13][position_reg] = 1'b1;
					break_flag = 1'b1;
				end else begin
					for (i = 9; i >= 0; i = i - 1) begin
						if (row[i][position_reg] | row[i+1][position_reg] | row[i+2][position_reg] | row[i+3][position_reg] == 1'b1) begin
							row[i+1][position_reg] = 1'b1;
							row[i+2][position_reg] = 1'b1;
							row[i+3][position_reg] = 1'b1;
							row[i+4][position_reg] = 1'b1;
							break_flag = 1'b1;
							break;
						end
					end
				end

				if (break_flag == 1'b0) begin
					row[0][position_reg] = 1'b1;
					row[1][position_reg] = 1'b1;
					row[2][position_reg] = 1'b1;
					row[3][position_reg] = 1'b1;
				end
			end

			2: begin
				for (i = 11; i >= 0; i = i - 1) begin
					if (row[i][position_reg] | row[i][position_reg +1] | row[i][position_reg +2] | row[i][position_reg +3] == 1'b1) begin
						row[i+1][position_reg] = 1'b1;
						row[i+1][position_reg +1] = 1'b1;
						row[i+1][position_reg +2] = 1'b1;
						row[i+1][position_reg +3] = 1'b1;
						break_flag = 1'b1;
						break;
					end
				end

				if (break_flag == 1'b0) begin
					row[0][position_reg] = 1'b1;
					row[0][position_reg +1] = 1'b1;
					row[0][position_reg +2] = 1'b1;
					row[0][position_reg +3] = 1'b1;
				end
			end

			3: begin
				for(i = 10; i >= 0; i = i - 1) begin
					if (row[i+2][position_reg] | row[i+2][position_reg +1] | row[i+1][position_reg +1] | row[i][position_reg +1] == 1'b1) begin
						row[i+3][position_reg] = 1'b1;
						row[i+3][position_reg +1] = 1'b1;
						row[i+2][position_reg +1] = 1'b1;
						row[i+1][position_reg +1] = 1'b1;
						break_flag = 1'b1;
						break;
					end
				end

				if (break_flag == 1'b0) begin
					row[2][position_reg] = 1'b1;
					row[2][position_reg +1] = 1'b1;
					row[1][position_reg +1] = 1'b1;
					row[0][position_reg +1] = 1'b1;
				end
			end

			4: begin
				for (i = 11; i >= 0; i = i - 1) begin
					if (row[i][position_reg] | row[i+1][position_reg] | row[i+1][position_reg +1] | row[i+1][position_reg +2] == 1'b1) begin
						row[i+1][position_reg] = 1'b1;
						row[i+2][position_reg] = 1'b1;
						row[i+2][position_reg +1] = 1'b1;
						row[i+2][position_reg +2] = 1'b1;
						break_flag = 1'b1;
						break;
					end
				end

				if (break_flag == 1'b0) begin
					row[0][position_reg] = 1'b1;
					row[1][position_reg] = 1'b1;
					row[1][position_reg +1] = 1'b1;
					row[1][position_reg +2] = 1'b1;
				end
			end

			5: begin
				if (row[11][position_reg] | row[11][position_reg +1] | row[12][position_reg] | row[13][position_reg] == 1'b1) begin
					row[12][position_reg] = 1'b1;
					break_flag = 1'b1;
				end else begin
					for (i = 10; i >= 0; i = i - 1) begin
						if (row[i][position_reg] | row[i][position_reg +1] | row[i+1][position_reg] | row[i+2][position_reg] == 1'b1) begin
							row[i+1][position_reg] = 1'b1;
							row[i+1][position_reg +1] = 1'b1;
							row[i+2][position_reg] = 1'b1;
							row[i+3][position_reg] = 1'b1;
							break_flag = 1'b1;
							break;
						end
					end
				end

				if (break_flag == 1'b0) begin
					row[0][position_reg] = 1'b1;
					row[0][position_reg +1] = 1'b1;
					row[1][position_reg] = 1'b1;
					row[2][position_reg] = 1'b1;
				end
			end

			6: begin
				for (i = 10; i >= 0; i = i - 1) begin
					if (row[i][position_reg +1] | row[i+1][position_reg] | row[i+1][position_reg +1] | row[i+2][position_reg] == 1'b1) begin
						row[i+1][position_reg +1] = 1'b1;
						row[i+2][position_reg] = 1'b1;
						row[i+2][position_reg +1] = 1'b1;
						row[i+3][position_reg] = 1'b1;
						break_flag = 1'b1;
						break;
					end
				end

				if (break_flag == 1'b0) begin
					row[0][position_reg +1] = 1'b1;
					row[1][position_reg] = 1'b1;
					row[1][position_reg +1] = 1'b1;
					row[2][position_reg] = 1'b1;
				end
			end

			7: begin
				for (i = 11; i >= 0; i = i - 1) begin
					if (row[i][position_reg] | row[i][position_reg +1] | row[i+1][position_reg +1] | row[i+1][position_reg +2] == 1'b1) begin
						row[i+1][position_reg] = 1'b1;
						row[i+1][position_reg +1] = 1'b1;
						row[i+2][position_reg +1] = 1'b1;
						row[i+2][position_reg +2] = 1'b1;
						break_flag = 1'b1;
						break;
					end
				end

				if (break_flag == 1'b0) begin
					row[0][position_reg] = 1'b1;
					row[0][position_reg +1] = 1'b1;
					row[1][position_reg +1] = 1'b1;
					row[1][position_reg +2] = 1'b1;
				end
			end
		endcase
	end
endtask

task clear_and_refine;
	inout [5:0] row [13:0];
	inout [3:0] score_reg;
	reg [3:0] row_ptr, score_this_round, i, j;

	begin
		row_ptr = 4'd0;
		score_this_round = 4'd0;
		for (i = 0; i < 14; i = i + 1) begin
			if (&row[row_ptr] == 1) begin
				score_this_round = score_this_round + 1;
				for (j = 0; j < 13; j = j + 1) begin
					row[j] = (j < row_ptr) ? row[j] : row[j+1];
				end
				row[13] = 6'b0;
			end else begin
				row_ptr = row_ptr + 1;
			end
		end
		score_reg = score_reg + score_this_round;
	end
endtask

endmodule