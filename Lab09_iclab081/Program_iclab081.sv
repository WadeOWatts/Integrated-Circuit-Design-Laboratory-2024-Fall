module Program(input clk, INF.Program_inf inf);
import usertype::*;

Action current_act;
Date input_date;
State current_state, next_state;
Warn_Msg warn_msg_reg;
Data_No req_no_reg;
Data_Dir data_from_dram, todays_info;
Data_Dir_var input_var;
Formula_Type current_formula;
Mode current_mode;

logic [1:0] index_count;
logic index_ready_flag;
logic [1:0] data_warn_A, data_warn_B, data_warn_C, data_warn_D;
logic [11:0] result;

always_comb begin
    inf.out_valid = current_state == OUTPUT ? 'b1 : 'b0;
    inf.warn_msg = inf.out_valid ? warn_msg_reg : No_Warn;
    inf.complete = inf.out_valid ? inf.warn_msg == No_Warn ? 'b1 : 'b0 : 'b0;
    inf.AR_ADDR = !inf.rst_n ? 'd0 : 17'h10000 + req_no_reg * 'h8;
    inf.AW_ADDR = inf.AR_ADDR;
end

always_comb begin
    case (current_act)
        Update: begin
            case (current_state)
                CALC: begin
                    if ($signed({1'b0, data_from_dram.Index_A}) + input_var.Index_A > 4095) begin
                        data_warn_A = 2'b01;
                    end else if ($signed({1'b0, data_from_dram.Index_A}) + input_var.Index_A < 0) begin
                        data_warn_A = 2'b10;
                    end else begin
                        data_warn_A = 2'b00;
                    end

                    if ($signed({1'b0, data_from_dram.Index_B}) + input_var.Index_B > 4095) begin
                        data_warn_B = 2'b01;
                    end else if ($signed({1'b0, data_from_dram.Index_B}) + input_var.Index_B < 0) begin
                        data_warn_B = 2'b10;
                    end else begin
                        data_warn_B = 2'b00;
                    end

                    if ($signed({1'b0, data_from_dram.Index_C}) + input_var.Index_C > 4095) begin
                        data_warn_C = 2'b01;
                    end else if ($signed({1'b0, data_from_dram.Index_C}) + input_var.Index_C < 0) begin
                        data_warn_C = 2'b10;
                    end else begin
                        data_warn_C = 2'b00;
                    end

                    if ($signed({1'b0, data_from_dram.Index_D}) + input_var.Index_D > 4095) begin
                        data_warn_D = 2'b01;
                    end else if ($signed({1'b0, data_from_dram.Index_D}) + input_var.Index_D < 0) begin
                        data_warn_D = 2'b10;
                    end else begin
                        data_warn_D = 2'b00;
                    end
                end
                default: begin
                    data_warn_A = 'bx;
                    data_warn_B = 'bx;
                    data_warn_C = 'bx;
                    data_warn_D = 'bx;
                end
            endcase
        end
        default: begin
            data_warn_A = 'bx;
            data_warn_B = 'bx;
            data_warn_C = 'bx;
            data_warn_D = 'bx;
        end
    endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

always_comb begin
    case (current_state)
        IDLE: next_state = inf.sel_action_valid ? INPUT : IDLE;
        INPUT: begin
            case (current_act)
                Index_Check, Update: next_state = index_ready_flag && !inf.AR_VALID && !inf.R_READY ? CALC : INPUT;
                Check_Valid_Date: next_state = inf.R_VALID ? CALC : INPUT;
                default: next_state = IDLE;
            endcase
        end
        CALC: begin
            case (current_act)
                Index_Check, Check_Valid_Date: next_state = OUTPUT;
                Update: next_state = inf.B_VALID ? OUTPUT : CALC;
                default: next_state = IDLE;
            endcase
        end
        OUTPUT: next_state = IDLE;
    endcase
end

always_ff @( posedge clk or negedge inf.rst_n ) begin
    if (!inf.rst_n) begin
        input_date <= 'd0;
    end else begin
        case (current_act)
            Index_Check: input_date <= inf.date_valid ? inf.D.d_date[0] : input_date;
            Update: input_date <= inf.date_valid ? inf.D.d_date[0] : input_date;
            Check_Valid_Date: input_date <= inf.date_valid ? inf.D.d_date[0] : input_date;
            default: input_date <= input_date;
        endcase
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        warn_msg_reg <= No_Warn;
    end else begin
        case (current_act)
            Index_Check: begin
                case (current_state)
                    CALC: begin
                        if (input_date.M < data_from_dram.M) begin
                            warn_msg_reg <= Date_Warn;
                        end else if (input_date.M == data_from_dram.M && input_date.D < data_from_dram.D) begin
                            warn_msg_reg <= Date_Warn;
                        end else begin
                            case (current_mode)
                                Insensitive: begin
                                    case (current_formula)
                                        Formula_A: warn_msg_reg <= result >= 2047 ? Risk_Warn : No_Warn;
                                        Formula_B: warn_msg_reg <= result >= 800 ? Risk_Warn : No_Warn;
                                        Formula_C: warn_msg_reg <= result >= 2047 ? Risk_Warn : No_Warn;
                                        Formula_D: warn_msg_reg <= result >= 3 ? Risk_Warn : No_Warn;
                                        Formula_E: warn_msg_reg <= result >= 3 ? Risk_Warn : No_Warn;
                                        Formula_F: warn_msg_reg <= result >= 800 ? Risk_Warn : No_Warn;
                                        Formula_G: warn_msg_reg <= result >= 800 ? Risk_Warn : No_Warn;
                                        Formula_H: warn_msg_reg <= result >= 800 ? Risk_Warn : No_Warn;
                                    endcase
                                end
                                Normal: begin
                                    case (current_formula)
                                        Formula_A: warn_msg_reg <= result >= 1023 ? Risk_Warn : No_Warn;
                                        Formula_B: warn_msg_reg <= result >= 400 ? Risk_Warn : No_Warn;
                                        Formula_C: warn_msg_reg <= result >= 1023 ? Risk_Warn : No_Warn;
                                        Formula_D: warn_msg_reg <= result >= 2 ? Risk_Warn : No_Warn;
                                        Formula_E: warn_msg_reg <= result >= 2 ? Risk_Warn : No_Warn;
                                        Formula_F: warn_msg_reg <= result >= 400 ? Risk_Warn : No_Warn;
                                        Formula_G: warn_msg_reg <= result >= 400 ? Risk_Warn : No_Warn;
                                        Formula_H: warn_msg_reg <= result >= 400 ? Risk_Warn : No_Warn;
                                    endcase
                                end
                                Sensitive: begin
                                    case (current_formula)
                                        Formula_A: warn_msg_reg <= result >= 511 ? Risk_Warn : No_Warn;
                                        Formula_B: warn_msg_reg <= result >= 200 ? Risk_Warn : No_Warn;
                                        Formula_C: warn_msg_reg <= result >= 511 ? Risk_Warn : No_Warn;
                                        Formula_D: warn_msg_reg <= result >= 1 ? Risk_Warn : No_Warn;
                                        Formula_E: warn_msg_reg <= result >= 1 ? Risk_Warn : No_Warn;
                                        Formula_F: warn_msg_reg <= result >= 200 ? Risk_Warn : No_Warn;
                                        Formula_G: warn_msg_reg <= result >= 200 ? Risk_Warn : No_Warn;
                                        Formula_H: warn_msg_reg <= result >= 200 ? Risk_Warn : No_Warn;
                                    endcase
                                end
                            endcase
                        end
                    end
                    default: warn_msg_reg <= warn_msg_reg;
                endcase
            end
            Update: begin
                case (current_state)
                    CALC: warn_msg_reg <= (|data_warn_A || |data_warn_B || |data_warn_C || |data_warn_D) ? Data_Warn : No_Warn;
                    default: warn_msg_reg <= warn_msg_reg;
                endcase
            end
            Check_Valid_Date: begin
                case (current_state)
                    CALC: begin
                        if (input_date.M < data_from_dram.M) begin
                            warn_msg_reg <= Date_Warn;
                        end else if (input_date.M == data_from_dram.M && input_date.D < data_from_dram.D) begin
                            warn_msg_reg <= Date_Warn;
                        end else begin
                            warn_msg_reg <= No_Warn;
                        end
                    end
                    default: warn_msg_reg <= warn_msg_reg;
                endcase
            end
        endcase
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        current_act <= Index_Check;
    end else begin
        current_act <= inf.sel_action_valid ? inf.D.d_act[0] : current_act;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        req_no_reg <= 'd0;
    end else begin
        req_no_reg <= inf.data_no_valid ? inf.D.d_data_no[0] : req_no_reg;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.AR_VALID <= 'b0;
    end else begin
        case (inf.AR_VALID)
            0: inf.AR_VALID <= inf.data_no_valid ? 'b1 : 'b0;
            1: inf.AR_VALID <= inf.AR_READY ? 'b0 : 'b1;
        endcase
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.R_READY <= 'b0;
    end else begin
        case (inf.R_READY) 
            0: inf.R_READY <= inf.AR_READY ? 'b1 : 'b0;
            1: inf.R_READY <= inf.R_VALID ? 'b0 : 'b1;
        endcase
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        data_from_dram.Index_A <= 'd0;
        data_from_dram.Index_B <= 'd0;
        data_from_dram.Index_C <= 'd0;
        data_from_dram.Index_D <= 'd0;
        data_from_dram.M <= 'd0;
        data_from_dram.D <= 'd0;
    end else begin
        case (current_state)
            IDLE: begin
                data_from_dram.Index_A <= 'd0;
                data_from_dram.Index_B <= 'd0;
                data_from_dram.Index_C <= 'd0;
                data_from_dram.Index_D <= 'd0;
                data_from_dram.M <= 'd0;
                data_from_dram.D <= 'd0;
            end
            default: begin
                data_from_dram.Index_A <= inf.R_VALID ? inf.R_DATA[63:52] : data_from_dram.Index_A;
                data_from_dram.Index_B <= inf.R_VALID ? inf.R_DATA[51:40] : data_from_dram.Index_B;
                data_from_dram.Index_C <= inf.R_VALID ? inf.R_DATA[31:20] : data_from_dram.Index_C;
                data_from_dram.Index_D <= inf.R_VALID ? inf.R_DATA[19:8] : data_from_dram.Index_D;
                data_from_dram.M <= inf.R_VALID ? inf.R_DATA[39:32] : data_from_dram.M;
                data_from_dram.D <= inf.R_VALID ? inf.R_DATA[7:0] : data_from_dram.D;
            end
        endcase
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        index_count <= 'd0;
    end else begin
        index_count <= inf.index_valid ? index_count + 'd1 : index_count;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        index_ready_flag <= 'b0;
    end else begin
        case (current_state)
            IDLE: index_ready_flag <= 'b0;
            INPUT: begin
                case (index_ready_flag)
                    0: index_ready_flag <= inf.index_valid && index_count == 'd3 ? 'b1 : 'b0;
                    1: index_ready_flag <= 'b1;
                endcase
            end
            default: index_ready_flag <= index_ready_flag;
        endcase
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        input_var.Index_A <= 'd0;
        input_var.Index_B <= 'd0;
        input_var.Index_C <= 'd0;
        input_var.Index_D <= 'd0;
        input_var.M <= 'd0;
        input_var.D <= 'd0;
    end else begin
        case (current_act)
            Update: begin
                case (index_count)
                    0: input_var.Index_A <= inf.index_valid ? inf.D.d_index[0] : input_var.Index_A;
                    1: input_var.Index_B <= inf.index_valid ? inf.D.d_index[0] : input_var.Index_B;
                    2: input_var.Index_C <= inf.index_valid ? inf.D.d_index[0] : input_var.Index_C;
                    3: input_var.Index_D <= inf.index_valid ? inf.D.d_index[0] : input_var.Index_D;
                endcase
            end
            default: begin
                input_var.Index_A <= 'd0;
                input_var.Index_B <= 'd0;
                input_var.Index_C <= 'd0;
                input_var.Index_D <= 'd0;
            end
        endcase
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        todays_info.Index_A <= 'd0;
        todays_info.Index_B <= 'd0;
        todays_info.Index_C <= 'd0;
        todays_info.Index_D <= 'd0;
        todays_info.M <= 'd0;
        todays_info.D <= 'd0;
    end else begin
        case (current_act)
            Index_Check: begin
                case (index_count)
                    0: todays_info.Index_A <= inf.index_valid ? inf.D.d_index[0] : todays_info.Index_A;
                    1: todays_info.Index_B <= inf.index_valid ? inf.D.d_index[0] : todays_info.Index_B;
                    2: todays_info.Index_C <= inf.index_valid ? inf.D.d_index[0] : todays_info.Index_C;
                    3: todays_info.Index_D <= inf.index_valid ? inf.D.d_index[0] : todays_info.Index_D;
                endcase
            end
            default: begin
                todays_info.Index_A <= 'd0;
                todays_info.Index_B <= 'd0;
                todays_info.Index_C <= 'd0;
                todays_info.Index_D <= 'd0;
            end
        endcase
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.AW_VALID <= 'b0;
    end else begin
        case (current_act)
            Update: begin
                case (inf.AW_VALID)
                    0: inf.AW_VALID <= inf.R_VALID ? 'b1 : 'b0;
                    1: inf.AW_VALID <= inf.AW_READY ? 'b0 : 'b1;
                endcase
            end
            default: inf.AW_VALID <= 'b0;
        endcase
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.W_VALID <= 'b0;
    end else begin
        case (current_act)
            Update: begin
                case (next_state)
                    CALC: inf.W_VALID <= 'b1;
                    default: inf.W_VALID <= 'b0;
                endcase
            end 
            default: inf.W_VALID <= 'b0;
        endcase 
    end
end

always_comb begin
    case (current_act)
        Index_Check, Check_Valid_Date: inf.W_DATA = 'd0;
        Update: begin
            case (current_state)
                CALC: begin
                    case (data_warn_A)
                        2'b00: inf.W_DATA[63:52] = $signed({1'b0, data_from_dram.Index_A}) + input_var.Index_A;
                        2'b01: inf.W_DATA[63:52] = 4095;
                        2'b10: inf.W_DATA[63:52] = 0;
                        default: inf.W_DATA[63:52] = 'd0;
                    endcase

                    case (data_warn_B)
                        2'b00: inf.W_DATA[51:40] = $signed({1'b0, data_from_dram.Index_B}) + input_var.Index_B;
                        2'b01: inf.W_DATA[51:40] = 4095;
                        2'b10: inf.W_DATA[51:40] = 0;
                        default: inf.W_DATA[51:40] = 'd0;
                    endcase

                    inf.W_DATA[39:32] = input_date.M;

                    case (data_warn_C)
                        2'b00: inf.W_DATA[31:20] = $signed({1'b0, data_from_dram.Index_C}) + input_var.Index_C;
                        2'b01: inf.W_DATA[31:20] = 4095;
                        2'b10: inf.W_DATA[31:20] = 0;
                        default: inf.W_DATA[31:20] = 'd0;
                    endcase

                    case (data_warn_D)
                        2'b00: inf.W_DATA[19:8] = $signed({1'b0, data_from_dram.Index_D}) + input_var.Index_D;
                        2'b01: inf.W_DATA[19:8] = 4095;
                        2'b10: inf.W_DATA[19:8] = 0;
                        default: inf.W_DATA[19:8] = 'd0;
                    endcase

                    inf.W_DATA[7:0] = input_date.D;
                end
                default: inf.W_DATA = 'd0;
            endcase
        end
        default: inf.W_DATA = 'd0;
    endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.B_READY <= 'b0;
    end else begin
        case (inf.B_READY)
            0: inf.B_READY <= inf.AW_READY ? 'b1 : 'b0;
            1: inf.B_READY <= inf.B_VALID ? 'b0 : 'b1;
        endcase
    end
end 

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        current_formula <= Formula_A;
    end else begin
        current_formula <= inf.formula_valid ? inf.D.d_formula[0] : current_formula;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        current_mode <= Insensitive;
    end else begin
        current_mode <= inf.mode_valid ? inf.D.d_mode[0] : current_mode;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        result <= 'd0;
    end else begin
        case (current_act)
            Index_Check: begin
                case (next_state)
                    IDLE: result <= 'd0;
                    CALC: begin
                        case (current_formula)
                            Formula_A: result <= formula_a(data_from_dram);
                            Formula_B: result <= formula_b(data_from_dram);
                            Formula_C: result <= formula_c(data_from_dram);
                            Formula_D: result <= formula_d(data_from_dram);
                            Formula_E: result <= formula_e(data_from_dram, todays_info);
                            Formula_F: result <= formula_f(data_from_dram, todays_info);
                            Formula_G: result <= formula_g(data_from_dram, todays_info);
                            Formula_H: result <= formula_h(data_from_dram, todays_info);
                        endcase
                    end
                    default: result <= result;
                endcase
            end
            default: result <= 'd0;
        endcase
    end
end

function logic [11:0] formula_a;
    input Data_Dir data_from_dram;
    logic [13:0] temp;
    begin
        temp = (data_from_dram.Index_A + data_from_dram.Index_B) + (data_from_dram.Index_C + data_from_dram.Index_D);
        formula_a = temp >> 2;
    end
endfunction

function logic [11:0] formula_b;
    input Data_Dir data_from_dram;
    Index layer1_a, layer1_b, layer1_c, layer1_d;
    Index layer2_a, layer2_b, layer2_c, layer2_d;
    begin
        layer1_a = data_from_dram.Index_A < data_from_dram.Index_C ? data_from_dram.Index_A : data_from_dram.Index_C;
        layer1_c = data_from_dram.Index_A < data_from_dram.Index_C ? data_from_dram.Index_C : data_from_dram.Index_A;
        layer1_b = data_from_dram.Index_B < data_from_dram.Index_D ? data_from_dram.Index_B : data_from_dram.Index_D;
        layer1_d = data_from_dram.Index_B < data_from_dram.Index_D ? data_from_dram.Index_D : data_from_dram.Index_B;

        layer2_a = layer1_a < layer1_b ? layer1_a : layer1_b;
        layer2_b = layer1_a < layer1_b ? layer1_b : layer1_a;
        layer2_c = layer1_c < layer1_d ? layer1_c : layer1_d;
        layer2_d = layer1_c < layer1_d ? layer1_d : layer1_c;

        formula_b = layer2_d - layer2_a;
    end
endfunction

function logic [11:0] formula_c;
    input Data_Dir data_from_dram;
    Index layer1_a, layer1_b, layer1_c, layer1_d;
    Index layer2_a, layer2_b, layer2_c, layer2_d;
    begin
        layer1_a = data_from_dram.Index_A < data_from_dram.Index_C ? data_from_dram.Index_A : data_from_dram.Index_C;
        layer1_b = data_from_dram.Index_B < data_from_dram.Index_D ? data_from_dram.Index_B : data_from_dram.Index_D;

        layer2_a = layer1_a < layer1_b ? layer1_a : layer1_b;

        formula_c = layer2_a;
    end
endfunction

function logic [11:0] formula_d;
    input Data_Dir data_from_dram; 
    begin
        formula_d = data_from_dram.Index_A >= 2047 ? 'd1 : 'd0;
        formula_d = data_from_dram.Index_B >= 2047 ? formula_d + 'd1 : formula_d;
        formula_d = data_from_dram.Index_C >= 2047 ? formula_d + 'd1 : formula_d;
        formula_d = data_from_dram.Index_D >= 2047 ? formula_d + 'd1 : formula_d;
    end
endfunction

function logic [11:0] formula_e;
    input Data_Dir data_from_dram;
    input Data_Dir todays_info; 
    begin
        formula_e = data_from_dram.Index_A >= todays_info.Index_A ? 'd1 : 'd0;
        formula_e = data_from_dram.Index_B >= todays_info.Index_B ? formula_e + 'd1 : formula_e;
        formula_e = data_from_dram.Index_C >= todays_info.Index_C ? formula_e + 'd1 : formula_e;
        formula_e = data_from_dram.Index_D >= todays_info.Index_D ? formula_e + 'd1 : formula_e;
    end
endfunction

function logic [11:0] formula_f;
    input Data_Dir data_from_dram;
    input Data_Dir todays_info; 
    Index Ga, Gb, Gc, Gd;
    logic [11:0] max;
    begin
        Ga = data_from_dram.Index_A > todays_info.Index_A ? data_from_dram.Index_A - todays_info.Index_A : todays_info.Index_A - data_from_dram.Index_A;
        Gb = data_from_dram.Index_B > todays_info.Index_B ? data_from_dram.Index_B - todays_info.Index_B : todays_info.Index_B - data_from_dram.Index_B;
        Gc = data_from_dram.Index_C > todays_info.Index_C ? data_from_dram.Index_C - todays_info.Index_C : todays_info.Index_C - data_from_dram.Index_C;
        Gd = data_from_dram.Index_D > todays_info.Index_D ? data_from_dram.Index_D - todays_info.Index_D : todays_info.Index_D - data_from_dram.Index_D;

        max = Gb > Ga ? Gb : Ga;
        max = Gc > max ? Gc : max;
        max = Gd > max ? Gd : max;

        formula_f = (Ga + Gb + Gc + Gd - max) / 3;
    end
endfunction

function logic [11:0] formula_g;
    input Data_Dir data_from_dram;
    input Data_Dir todays_info; 
    Index Ga, Gb, Gc, Gd;
    Index layer1_a, layer1_b, layer1_c, layer1_d;
    Index layer2_a, layer2_b, layer2_c, layer2_d;
    logic [10:0] n0;
    logic [9:0] n1, n2;
    begin
        Ga = data_from_dram.Index_A > todays_info.Index_A ? data_from_dram.Index_A - todays_info.Index_A : todays_info.Index_A - data_from_dram.Index_A;
        Gb = data_from_dram.Index_B > todays_info.Index_B ? data_from_dram.Index_B - todays_info.Index_B : todays_info.Index_B - data_from_dram.Index_B;
        Gc = data_from_dram.Index_C > todays_info.Index_C ? data_from_dram.Index_C - todays_info.Index_C : todays_info.Index_C - data_from_dram.Index_C;
        Gd = data_from_dram.Index_D > todays_info.Index_D ? data_from_dram.Index_D - todays_info.Index_D : todays_info.Index_D - data_from_dram.Index_D;

        layer1_a = Ga < Gc ? Ga : Gc;
        layer1_c = Ga < Gc ? Gc : Ga;
        layer1_b = Gb < Gd ? Gb : Gd;
        layer1_d = Gb < Gd ? Gd : Gb;

        layer2_a = layer1_a < layer1_b ? layer1_a : layer1_b;
        layer2_b = layer1_a < layer1_b ? layer1_b : layer1_a;
        layer2_c = layer1_c < layer1_d ? layer1_c : layer1_d;
        layer2_d = layer1_c < layer1_d ? layer1_d : layer1_c;

        n0 = layer2_a >> 1;
        n1 = layer2_b >> 2;
        n2 = layer2_c >> 2;

        formula_g = n0 + n1 + n2;
    end
endfunction

function logic [11:0] formula_h;
    input Data_Dir data_from_dram;
    input Data_Dir todays_info; 
    Index Ga, Gb, Gc, Gd;
    logic [13:0] temp;
    begin
        Ga = data_from_dram.Index_A > todays_info.Index_A ? data_from_dram.Index_A - todays_info.Index_A : todays_info.Index_A - data_from_dram.Index_A;
        Gb = data_from_dram.Index_B > todays_info.Index_B ? data_from_dram.Index_B - todays_info.Index_B : todays_info.Index_B - data_from_dram.Index_B;
        Gc = data_from_dram.Index_C > todays_info.Index_C ? data_from_dram.Index_C - todays_info.Index_C : todays_info.Index_C - data_from_dram.Index_C;
        Gd = data_from_dram.Index_D > todays_info.Index_D ? data_from_dram.Index_D - todays_info.Index_D : todays_info.Index_D - data_from_dram.Index_D;

        temp = (Ga + Gb) + (Gc + Gd);
        formula_h = temp >> 2;
    end
endfunction

endmodule
