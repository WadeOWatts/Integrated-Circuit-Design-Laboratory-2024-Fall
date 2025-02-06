//synopsys translate_off
`include "HAMMING_IP.v"
//synopsys translate_on

module MDC(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_data, 
	in_mode,
    // Output signals
    out_valid, 
	out_data
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [8:0] in_mode;
input [14:0] in_data;

output reg out_valid;
output reg [206:0] out_data;

reg [4:0] mode_reg;
reg signed [10:0] matrix [0:15];
reg [1:0] current_state, next_state;
reg signed [206:0] out_temp;
reg signed [10:0] U1_a, U1_b, U1_c, U1_d;
reg signed [10:0] U2_a, U2_b, U2_c, U2_d;
reg signed [22:0] det_1, det_2, det_3, det_4, det_5;
reg signed [35:0] temp_12, temp_13, temp_14, temp_15;
reg [3:0] count;

wire signed [22:0] U1_det, U2_det;
wire [8:0] IN_code_mode;
wire [4:0] OUT_code_mode;
wire [14:0] IN_code_data;
wire signed [10:0] OUT_code_data;


parameter IDLE = 2'd0;
parameter INPUT = 2'd1;
parameter OUTPUT = 2'd2;

HAMMING_IP #(.IP_BIT(5)) HAMMING_IP_mode(.IN_code(IN_code_mode), .OUT_code(OUT_code_mode)); 
HAMMING_IP #(.IP_BIT(11)) HAMMING_IP_data(.IN_code(IN_code_data), .OUT_code(OUT_code_data)); 

determinant_cal U1 (.a(U1_a), .b(U1_b), .c(U1_c), .d(U1_d), .det(U1_det));
determinant_cal U2 (.a(U2_a), .b(U2_b), .c(U2_c), .d(U2_d), .det(U2_det));


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

always @(*) begin
    case (next_state)
        IDLE: next_state = (in_valid) ? INPUT : IDLE;
        INPUT: next_state = (!in_valid) ? IDLE : INPUT;
        default: next_state = IDLE;
    endcase
end

assign IN_code_mode = (in_valid && current_state == IDLE) ? in_mode : 9'b0;
assign IN_code_data = (next_state == INPUT) ? in_data : 11'b0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mode_reg <= 5'd0;
    end else begin
        if (in_valid && current_state == IDLE) begin
            mode_reg <= OUT_code_mode;
        end 
    end
end


genvar i;
generate
    for (i = 0; i < 16; i = i + 1) begin
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                matrix[i] <= 11'b0;
            end else begin
                if (next_state == INPUT) begin
                    if (count == i) begin
                        matrix[i] <= OUT_code_data;
                    end
                end else begin
                    matrix[i] <= 11'b0;
                end
            end
        end
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count <= 4'd0;
    end else begin
        if (next_state == INPUT) begin
            count <= count + 1;
        end else begin
            count <= 0;
        end
    end
end 

always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin
        out_temp <= 207'b0;
    end else begin
        if (current_state == IDLE) begin
            out_temp <= 207'b0;
        end else begin
            case (mode_reg)
                5'b00100: begin
                    case (count)
                        4'd0: if (!in_valid && current_state == INPUT) out_temp[22:0] <= U1_det;
                        4'd6: out_temp[206:184] <= U1_det;
                        4'd7: out_temp[183:161] <= U1_det;
                        4'd8: out_temp[160:138] <= U1_det;
                        4'd10: out_temp[137:115] <= U1_det;
                        4'd11: out_temp[114:92] <= U1_det;
                        4'd12: out_temp[91:69] <= U1_det;
                        4'd14: out_temp[68:46] <= U1_det;
                        4'd15: out_temp[45:23] <= U1_det;
                    endcase
                end

                5'b00110: begin
                    case (count)
                        4'd0: begin
                            if (!in_valid && current_state == INPUT) begin
                                out_temp[50:0] <= $signed(out_temp[50:0]) + (matrix[5] * U1_det - matrix[6] * U2_det);
                            end
                        end
                        4'd10: out_temp[203:153] <= matrix[2] * U1_det;
                        4'd11: begin
                            out_temp[203:153] <= $signed(out_temp[203:153]) + (matrix[0] * U1_det - matrix[1] * U2_det);
                            out_temp[152:102] <= matrix[3] * U1_det;
                        end
                        4'd12: out_temp[152:102] <= $signed(out_temp[152:102]) + (matrix[1] * U1_det - matrix[2] * U2_det);
                        4'd14: out_temp[101:51] <= matrix[6] * U1_det;
                        4'd15: begin
                            out_temp[101:51] <= $signed(out_temp[101:51]) + (matrix[4] * U1_det - matrix[5] * U2_det);
                            out_temp[50:0] <= matrix[7] * U1_det;
                        end
                    endcase
                end

                5'b10110: begin
                    case (count)
                        4'd0: if (!in_valid && current_state == INPUT) out_temp <= $signed(out_temp) + $signed(matrix[15]) * $signed(temp_15);
                        4'd13: out_temp <= - $signed(matrix[12]) * $signed(temp_12);
                        4'd14: out_temp <= $signed(out_temp) + $signed(matrix[13]) * $signed(temp_13);
                        4'd15: out_temp <= $signed(out_temp) - $signed(matrix[14]) * $signed(temp_14);
                    endcase
                end 

                default: out_temp <= 207'b0;
            endcase
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        det_1 <= 23'b0;
    end else begin
        if (current_state == INPUT) begin
            if (mode_reg == 5'b10110) begin
                if (count == 4'd6) begin
                    det_1 <= U1_det;
                end
            end
        end else begin
            det_1 <= 23'b0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        det_2 <= 23'b0;
    end else begin
        if (current_state == INPUT) begin
            if (mode_reg == 5'b10110) begin
                if (count == 4'd7) begin
                    det_2 <= U1_det;
                end
            end
        end else begin
            det_2 <= 23'b0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        det_3 <= 23'b0;
    end else begin
        if (current_state == INPUT) begin
            if (mode_reg == 5'b10110) begin
                if (count == 4'd8) begin
                    det_3 <= U1_det;
                end else if (count == 4'd11) begin
                    det_3 <= U1_det;
                end
            end
        end else begin
            det_3 <= 23'b0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        det_4 <= 23'b0;
    end else begin
        if (current_state == INPUT) begin
            if (mode_reg == 5'b10110) begin
                if (count == 4'd9) begin
                    det_4 <= U1_det;
                end
            end
        end else begin
            det_4 <= 23'b0;
        end 
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        det_5 <= 23'b0;
    end else begin
        if (current_state == INPUT) begin
            if (mode_reg == 5'b10110) begin
                if (count == 4'd10) begin
                    det_5 <= U1_det;
                end
            end
        end else begin
            det_5 <= 23'b0;
        end 
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        temp_12 <= 36'b0;
    end else begin
        if (current_state == INPUT) begin
            if (mode_reg == 5'b10110) begin
                case (count)
                    4'd10: temp_12 <= matrix[9] * det_3;
                    4'd11: temp_12 <= temp_12 - matrix[10] * det_4;
                    4'd12: temp_12 <= temp_12 + matrix[11] * det_2;
                endcase
            end
        end else begin
            temp_12 <= 36'b0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        temp_13 <= 36'b0;
    end else begin
        if (current_state == INPUT) begin
            if (mode_reg == 5'b10110) begin
                case (count) 
                    4'd9: temp_13 <= matrix[8] * det_3;
                    4'd11: temp_13 <= temp_13 - matrix[10] * U1_det;
                    4'd12: temp_13 <= temp_13 + matrix[11] * det_5;
                endcase
            end
        end else begin
            temp_13 <= 36'b0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        temp_14 <= 36'b0;
    end else begin
        if (current_state == INPUT) begin
            if (mode_reg == 5'b10110) begin
                case (count)
                    4'd10: temp_14 <= matrix[8] * det_4;
                    4'd12: temp_14 <= temp_14 + - matrix[9] * det_3;
                    4'd13: temp_14 <= temp_14 + matrix[11] * det_1;
                endcase
            end
        end else begin
            temp_14 <= 36'b0;
        end
    end
end 

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        temp_15 <= 36'b0;
    end else begin
        if (current_state == INPUT) begin
            if (mode_reg == 5'b10110) begin
                case (count) 
                    4'd9: temp_15 <= matrix[8] * det_2;
                    4'd11: temp_15 <= temp_15 - matrix[9] * det_5;
                    4'd12: temp_15 <= temp_15 + matrix[10] * det_1;
                endcase
            end
        end else begin
            temp_15 <= 36'b0;
        end
    end
end

always @(*) begin                           // U1_a
    case (mode_reg)
        5'b00100: begin
            case (count)
                4'd0: U1_a = (!in_valid && current_state == INPUT) ? matrix[10] : 11'b0;
                4'd6: U1_a = matrix[0];
                4'd7: U1_a = matrix[1];
                4'd8: U1_a = matrix[2];
                4'd10: U1_a = matrix[4];
                4'd11: U1_a = matrix[5];
                4'd12: U1_a = matrix[6];
                4'd14: U1_a = matrix[8];
                4'd15: U1_a = matrix[9];
                default: U1_a = 11'b0;
            endcase
        end

        5'b00110: begin
            case (count) 
                4'd0: U1_a = (!in_valid && current_state == INPUT) ? matrix[10] : 11'b0;
                4'd10: U1_a = matrix[4];
                4'd11: U1_a = matrix[5];
                4'd12: U1_a = matrix[6];
                4'd14: U1_a = matrix[8];
                4'd15: U1_a = matrix[9];
                default: U1_a = 11'b0;
            endcase
        end

        5'b10110: begin
            case (count) 
                4'd6: U1_a = matrix[0];
                4'd7: U1_a = matrix[1];
                4'd8: U1_a = matrix[2];
                4'd9: U1_a = matrix[1];
                4'd10: U1_a = matrix[0];
                4'd11: U1_a = matrix[0];
                default: U1_a = 11'b0;
            endcase
        end

        default: U1_a = 11'b0;
    endcase
end

always @(*) begin                           // U1_b
    case (mode_reg)
        5'b00100: begin
            case (count)
                4'd0: U1_b = (!in_valid && current_state == INPUT) ? matrix[11] : 11'b0;
                4'd6: U1_b = matrix[1];
                4'd7: U1_b = matrix[2];
                4'd8: U1_b = matrix[3];
                4'd10: U1_b = matrix[5];
                4'd11: U1_b = matrix[6];
                4'd12: U1_b = matrix[7];
                4'd14: U1_b = matrix[9];
                4'd15: U1_b = matrix[10];
                default: U1_b = 11'b0;
            endcase
        end

        5'b00110: begin
            case (count)
                4'd0: U1_b = (!in_valid && current_state == INPUT) ? matrix[11] : 11'b0;
                4'd10: U1_b = matrix[5];
                4'd11: U1_b = matrix[6];
                4'd12: U1_b = matrix[7];
                4'd14: U1_b = matrix[9];
                4'd15: U1_b = matrix[10];
                default: U1_b = 11'b0;
            endcase
        end

        5'b10110: begin
            case (count)
                4'd6: U1_b = matrix[1];
                4'd7: U1_b = matrix[2];
                4'd8: U1_b = matrix[3];
                4'd9: U1_b = matrix[3];
                4'd10: U1_b = matrix[2];
                4'd11: U1_b = matrix[3];
                default: U1_b = 11'b0;
            endcase
        end
        default: U1_b = 11'b0;
    endcase
end

always @(*) begin                           // U1_c
    case (mode_reg)
        5'b00100: begin
            case (count)
                4'd0: U1_c = (!in_valid && current_state == INPUT) ? matrix[14] : 11'b0;
                4'd6: U1_c = matrix[4];
                4'd7: U1_c = matrix[5];
                4'd8: U1_c = matrix[6];
                4'd10: U1_c = matrix[8];
                4'd11: U1_c = matrix[9];
                4'd12: U1_c = matrix[10];
                4'd14: U1_c = matrix[12];
                4'd15: U1_c = matrix[13];
                default: U1_c = 11'b0;
            endcase
        end

        5'b00110: begin
            case (count)
                4'd0: U1_c = (!in_valid && current_state == INPUT) ? matrix[14] : 11'b0;
                4'd10: U1_c = matrix[8];
                4'd11: U1_c = matrix[9];
                4'd12: U1_c = matrix[10];
                4'd14: U1_c = matrix[12];
                4'd15: U1_c = matrix[13];
                default: U1_c = 11'b0;
            endcase
        end

        5'b10110: begin
            case (count)
                4'd6: U1_c = matrix[4];
                4'd7: U1_c = matrix[5];
                4'd8: U1_c = matrix[6];
                4'd9: U1_c = matrix[5];
                4'd10: U1_c = matrix[4];
                4'd11: U1_c = matrix[4];
                default: U1_c = 11'b0;
            endcase
        end
        default: U1_c = 11'b0;
    endcase
end

always @(*) begin                           // U1_d
    case (mode_reg)
        5'b00100: begin
            case (count)
                4'd0: U1_d = (!in_valid && current_state == INPUT) ? matrix[15] : 11'b0;
                4'd6: U1_d = matrix[5];
                4'd7: U1_d = matrix[6];
                4'd8: U1_d = matrix[7];
                4'd10: U1_d = matrix[9];
                4'd11: U1_d = matrix[10];
                4'd12: U1_d = matrix[11];
                4'd14: U1_d = matrix[13];
                4'd15: U1_d = matrix[14];
                default: U1_d = 11'b0;
            endcase
        end

        5'b00110: begin
            case (count)
                4'd0: U1_d = (!in_valid && current_state == INPUT) ? matrix[15] : 11'b0;
                4'd10: U1_d = matrix[9];
                4'd11: U1_d = matrix[10];
                4'd12: U1_d = matrix[11];
                4'd14: U1_d = matrix[13];
                4'd15: U1_d = matrix[14];
                default: U1_d = 11'b0;
            endcase
        end

        5'b10110: begin
            case (count)
                4'd6: U1_d = matrix[5];
                4'd7: U1_d = matrix[6];
                4'd8: U1_d = matrix[7];
                4'd9: U1_d = matrix[7];
                4'd10: U1_d = matrix[6];
                4'd11: U1_d = matrix[7];
                default: U1_d = 11'b0;
            endcase
        end
        default: U1_d = 11'b0;
    endcase
end

always @(*) begin                           // U2_a
    case (mode_reg)
        5'b00110: begin
            case (count) 
                4'd0: U2_a =  (!in_valid && current_state == INPUT) ? matrix[9] : 11'b0;
                4'd11: U2_a = matrix[4];
                4'd12: U2_a = matrix[5];
                4'd15: U2_a = matrix[8];
                default: U2_a = 11'b0;
            endcase
        end
        default: U2_a = 11'b0;
    endcase
end

always @(*) begin                           // U2_b
    case (mode_reg)
        5'b00110: begin
            case (count) 
                4'd0: U2_b =  (!in_valid && current_state == INPUT) ? matrix[11] : 11'b0;
                4'd11: U2_b = matrix[6];
                4'd12: U2_b = matrix[7];
                4'd15: U2_b = matrix[10];
                default: U2_b = 11'b0;
            endcase
        end
        default: U2_b = 11'b0;
    endcase
end

always @(*) begin                           // U2_c
    case (mode_reg)
        5'b00110: begin
            case (count) 
                4'd0: U2_c =  (!in_valid && current_state == INPUT) ? matrix[13] : 11'b0;
                4'd11: U2_c = matrix[8];
                4'd12: U2_c = matrix[9];
                4'd15: U2_c = matrix[12];
                default: U2_c = 11'b0;
            endcase
        end
        default: U2_c = 11'b0;
    endcase
end

always @(*) begin                           // U2_d
    case (mode_reg)
        5'b00110: begin
            case (count) 
                4'd0: U2_d =  (!in_valid && current_state == INPUT) ? matrix[15] : 11'b0;
                4'd11: U2_d = matrix[10];
                4'd12: U2_d = matrix[11];
                4'd15: U2_d = matrix[14];
                default: U2_d = 11'b0;
            endcase
        end
        default: U2_d = 11'b0;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 1'b0;
    end else begin
        if (current_state == INPUT && !in_valid) begin
            out_valid <= 1'b1;
        end else begin
            out_valid <= 1'b0;
        end
    end
end

always @(*) begin
    if (out_valid) begin
        out_data = out_temp;
    end else begin
        out_data = 207'b0;
    end
end



endmodule

module determinant_cal (
    input signed [10:0] a,
    input signed [10:0] b,
    input signed [10:0] c,
    input signed [10:0] d,
    output signed [22:0] det
);

wire signed [21:0] mul_temp1, mul_temp2;

assign mul_temp1 = a * d;
assign mul_temp2 = b * c;
assign det = mul_temp1 - mul_temp2;

endmodule