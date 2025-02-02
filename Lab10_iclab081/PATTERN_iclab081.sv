
// `include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter MAX_CYCLE=1000;
parameter PATNUM = 7500;

integer i_pat;
//================================================================
// wire & registers 
//================================================================
Action current_act;

//================================================================
// class random
//================================================================

/**
 * Class representing a random action.
 */
class random_act;
    randc Action act_id;

    function new();
        this.srandom($urandom());
        assert(randomize());
    endfunction

    constraint range{
        act_id inside{Index_Check, Update, Check_Valid_Date};
    }
endclass

class DRAM_data;
    logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];  // 32 box

    function new();
        $readmemh(DRAM_p_r, golden_DRAM);
    endfunction
endclass

class index_check_cls;
    randc Order_Info order;             // formula mode
    randc Index todays_info_A;
    randc Index todays_info_B;
    randc Index todays_info_C;
    randc Index todays_info_D;
    randc Month todays_info_M;
    randc Day todays_info_Day;         
    randc Data_No req_no;               // data no.
    DRAM_data obj;
    Data_Dir todays_info;               // indices, month, date

    function new (DRAM_data dram_cls);
        this.srandom($urandom());
        assert(randomize());
        todays_info.Index_A = todays_info_A;
        todays_info.Index_B = todays_info_B;
        todays_info.Index_C = todays_info_C;
        todays_info.Index_D = todays_info_D;
        todays_info.M = todays_info_M;
        todays_info.D = todays_info_Day;
        obj = dram_cls;
    endfunction

    function Formula_Type get_formula();
        return order.Formula_Type_O;
    endfunction

    function Mode get_mode();
        return order.Mode_O;
    endfunction

    function Month get_month();
        return todays_info.M;
    endfunction

    function Day get_date();
        return todays_info.D;
    endfunction

    function Index get_today_index_A();
        return todays_info.Index_A;
    endfunction

    function Index get_today_index_B();
        return todays_info.Index_B;
    endfunction

    function Index get_today_index_C();
        return todays_info.Index_C;
    endfunction

    function Index get_today_index_D();
        return todays_info.Index_D;
    endfunction

    function Data_No get_no_dram();
        return req_no;
    endfunction

    function Data_Dir get_dram_data();  
        logic [7:0] temp [0:7];
        Data_Dir data;
        int i;

        for (i = 0; i < 8; i = i + 1) begin
            temp[i] = obj.golden_DRAM[65536 + req_no * 8 + i];
        end

        data.Index_A = {temp[7], temp[6][7:4]};
        data.Index_B = {temp[6][3:0], temp[5]};
        data.Index_C = {temp[3], temp[2][7:4]};
        data.Index_D = {temp[2][3:0], temp[1]};
        data.M = temp[4];
        data.D = temp[0];
        return data;
    endfunction

    function bit check_date();
        Data_Dir dram;
        Month dram_month;
        Day dram_day;

        dram = get_dram_data();
        dram_month = dram.M;
        dram_day = dram.D;

        if (todays_info.M < dram.M) begin
            return 1;
        end else if (todays_info.M == dram.M && todays_info.D < dram.D) begin
            return 1;
        end else begin
            return 0;
        end
    endfunction

    function bit check_threshold();
        Index I_A, I_B, I_C, I_D;
        Index TI_A, TI_B, TI_C, TI_D;
        Index G_A, G_B, G_C, G_D;
        Index R;
        Index max, min;
        Data_Dir dram;

        dram = get_dram_data();

        I_A = dram.Index_A;
        I_B = dram.Index_B;
        I_C = dram.Index_C;
        I_D = dram.Index_D;

        TI_A = get_today_index_A();
        TI_B = get_today_index_B();
        TI_C = get_today_index_C();
        TI_D = get_today_index_D();

        G_A = I_A > TI_A ? I_A - TI_A : TI_A - I_A;
        G_B = I_B > TI_B ? I_B - TI_B : TI_B - I_B;
        G_C = I_C > TI_C ? I_C - TI_C : TI_C - I_C;
        G_D = I_D > TI_D ? I_D - TI_D : TI_D - I_D;

        case (get_formula())
            Formula_A: begin
                R = int'((I_A + I_B + I_C + I_D) / 4);
                case (get_mode())
                    Insensitive: return R >= 2047;
                    Normal: return R >= 1023;
                    Sensitive: return R >= 511;
                endcase
            end
            Formula_B: begin
                max = I_A > I_B ? I_A : I_B;
                max = max > I_C ? max : I_C;
                max = max > I_D ? max : I_D;

                min = I_A < I_B ? I_A : I_B;
                min = min < I_C ? min : I_C;
                min = min < I_D ? min : I_D;

                R = max - min;

                case (get_mode())
                    Insensitive: return R >= 800;
                    Normal: return R >= 400;
                    Sensitive: return R >= 200;
                endcase
            end
            Formula_C: begin
                min = I_A < I_B ? I_A : I_B;
                min = min < I_C ? min : I_C;
                min = min < I_D ? min : I_D;

                R = min;

                case (get_mode())
                    Insensitive: return R >= 2047;
                    Normal: return R >= 1023;
                    Sensitive: return R >= 511;
                endcase
            end
            Formula_D: begin
                R = I_A >= 'd2047 ? 1 : 0;
                R = I_B >= 'd2047 ? R + 1 : R;
                R = I_C >= 'd2047 ? R + 1 : R;
                R = I_D >= 'd2047 ? R + 1 : R;

                case (get_mode())
                    Insensitive: return R >= 3;
                    Normal: return R >= 2;
                    Sensitive: return R >= 1;
                endcase
            end
            Formula_E: begin
                R = I_A >= TI_A ? 1 : 0;
                R = I_B >= TI_B ? R + 1 : R;
                R = I_C >= TI_C ? R + 1 : R;
                R = I_D >= TI_D ? R + 1 : R;

                case (get_mode())
                    Insensitive: return R >= 3;
                    Normal: return R >= 2;
                    Sensitive: return R >= 1;
                endcase
            end
            Formula_F: begin
                max = G_A > G_B ? G_A : G_B;
                max = max > G_C ? max : G_C;
                max = max > G_D ? max : G_D;

                R = int'((G_A + G_B + G_C + G_D - max) / 3);

                case (get_mode())
                    Insensitive: return R >= 800;
                    Normal: return R >= 400;
                    Sensitive: return R >= 200;
                endcase
            end
            Formula_G: begin
                int temp, a, b, c, d;
                a = G_A; b = G_B; c = G_C; d = G_D;

                if (a > b) begin temp = a; a = b; b = temp; end
                if (b > c) begin temp = b; b = c; c = temp; end
                if (c > d) begin temp = c; c = d; d = temp; end
                if (a > b) begin temp = a; a = b; b = temp; end
                if (b > c) begin temp = b; b = c; c = temp; end
                if (a > b) begin temp = a; a = b; b = temp; end

                R = int'(a / 2) + int'(b / 4) + int'(c / 4);

                case (get_mode())
                    Insensitive: return R >= 800;
                    Normal: return R >= 400;
                    Sensitive: return R >= 200;
                endcase
            end
            Formula_H: begin
                R = int'((G_A + G_B + G_C + G_D) / 4);

                case (get_mode())
                    Insensitive: return R >= 800;
                    Normal: return R >= 400;
                    Sensitive: return R >= 200;
                endcase
            end
        endcase

    endfunction

    function Warn_Msg get_golden_respond();
        if (check_date()) begin
            return Date_Warn;
        end else if (check_threshold()) begin
            return Risk_Warn;
        end else begin
            return No_Warn;
        end
    endfunction

    constraint range{
        order.Mode_O inside{Insensitive, Normal, Sensitive};
    }

    constraint valid_month {
        todays_info_M inside {[1:12]};  
    }

    constraint valid_day {
        if (todays_info_M == 2) {       
            todays_info_Day inside {[1:28]}; 
        } else if (todays_info_M inside {4, 6, 9, 11}) { 
            todays_info_Day inside {[1:30]}; 
        } else {                
            todays_info_Day inside {[1:31]}; 
        }
    }
endclass

class update_cls;
    randc Data_No req_no;               // data no.
    randc Index_var todays_info_A;
    randc Index_var todays_info_B;
    randc Index_var todays_info_C;
    randc Index_var todays_info_D;
    randc Month todays_info_M;
    randc Day todays_info_Day; 
    DRAM_data obj;
    Data_Dir_var todays_info;         // indices, month, date

    function new (DRAM_data dram_cls);
        this.srandom($urandom());
        assert(randomize());
        todays_info.Index_A = todays_info_A;
        todays_info.Index_B = todays_info_B;
        todays_info.Index_C = todays_info_C;
        todays_info.Index_D = todays_info_D;
        todays_info.M = todays_info_M;
        todays_info.D = todays_info_Day;
        obj = dram_cls;
    endfunction

    function Data_Dir get_dram_data();  
        logic [7:0] temp [0:7];
        Data_Dir data;
        int i;

        for (i = 0; i < 8; i = i + 1) begin
            temp[i] = obj.golden_DRAM[65536 + req_no * 8 + i];
        end
        
        data.Index_A = {temp[7], temp[6][7:4]};
        data.Index_B = {temp[6][3:0], temp[5]};
        data.Index_C = {temp[3], temp[2][7:4]};
        data.Index_D = {temp[2][3:0], temp[1]};
        data.M = temp[4];
        data.D = temp[0];
        return data;
    endfunction

    function Warn_Msg update_and_respond();
        Data_Dir dram;
        bit warn_flag;
        Index temp;
        logic [63:0] data_to_sent_back;
        logic [7:0] data_to_sent_back_temp [0:7];
        logic signed [12:0] signed_a, signed_b, signed_c, signed_d;
        integer i;

        warn_flag = 0;
        dram = get_dram_data();
        signed_a = {1'b0, dram.Index_A};
        signed_b = {1'b0, dram.Index_B};
        signed_c = {1'b0, dram.Index_C};
        signed_d = {1'b0, dram.Index_D};

        if (signed_a + todays_info.Index_A > 4095) begin
            data_to_sent_back[63:52] = 4095;
            warn_flag = 1;
        end else if (signed_a + todays_info.Index_A < 0) begin
            data_to_sent_back[63:52] = 0;
            warn_flag = 1;
        end else begin
            temp = signed_a + todays_info.Index_A;
            data_to_sent_back[63:52] = temp;
        end

        if (signed_b + todays_info.Index_B > 4095) begin
            data_to_sent_back[51:40] = 4095;
            warn_flag = 1;
        end else if (signed_b + todays_info.Index_B < 0) begin
            data_to_sent_back[51:40] = 0;
            warn_flag = 1;
        end else begin
            temp = signed_b + todays_info.Index_B;
            data_to_sent_back[51:40] = temp;
        end

        if (signed_c + todays_info.Index_C > 4095) begin
            data_to_sent_back[31:20] = 4095;
            warn_flag = 1;
        end else if (signed_c + todays_info.Index_C < 0) begin
            data_to_sent_back[31:20] = 0;
            warn_flag = 1;
        end else begin
            temp = signed_c + todays_info.Index_C;
            data_to_sent_back[31:20] = temp;
        end

        if (signed_d + todays_info.Index_D > 4095) begin
            data_to_sent_back[19:8] = 4095;
            warn_flag = 1;
        end else if (signed_d + todays_info.Index_D < 0) begin
            data_to_sent_back[19:8] = 0;
            warn_flag = 1;
        end else begin
            temp = signed_d + todays_info.Index_D;
            data_to_sent_back[19:8] = temp;
        end

        data_to_sent_back[39:32] = todays_info_M;
        data_to_sent_back[7:0] = todays_info_Day;

        data_to_sent_back_temp[0] = data_to_sent_back[7:0];
        data_to_sent_back_temp[1] = data_to_sent_back[15:8];
        data_to_sent_back_temp[2] = data_to_sent_back[23:16];
        data_to_sent_back_temp[3] = data_to_sent_back[31:24];
        data_to_sent_back_temp[4] = data_to_sent_back[39:32];
        data_to_sent_back_temp[5] = data_to_sent_back[47:40];
        data_to_sent_back_temp[6] = data_to_sent_back[55:48];
        data_to_sent_back_temp[7] = data_to_sent_back[63:56];

        for (i = 0; i < 8; i = i + 1) begin
            obj.golden_DRAM[65536 + req_no * 8 + i] = data_to_sent_back_temp[i];
        end

        if (warn_flag) begin
            return Data_Warn;
        end else begin
            return No_Warn;
        end
    endfunction

    constraint valid_month {
        todays_info_M inside {[1:12]};  
    }

    constraint indices_limit {
        todays_info_A inside {[-2048:2047]};
        todays_info_B inside {[-2048:2047]};
        todays_info_C inside {[-2048:2047]};
        todays_info_D inside {[-2048:2047]};
    }

    constraint valid_day {
        if (todays_info_M == 2) {       
            todays_info_Day inside {[1:28]}; 
        } else if (todays_info_M inside {4, 6, 9, 11}) { 
            todays_info_Day inside {[1:30]}; 
        } else {                
            todays_info_Day inside {[1:31]}; 
        }
    }
endclass

class Check_Valid_Date_cls;
    randc Index todays_info_A;
    randc Index todays_info_B;
    randc Index todays_info_C;
    randc Index todays_info_D;
    randc Month todays_info_M;
    randc Day todays_info_Day; 
    randc Data_No req_no;               // data no.
    DRAM_data obj;
    Data_Dir todays_info;         // indices, month, date

    function new (DRAM_data dram_cls);
        this.srandom($urandom());
        assert(randomize());
        todays_info.Index_A = todays_info_A;
        todays_info.Index_B = todays_info_B;
        todays_info.Index_C = todays_info_C;
        todays_info.Index_D = todays_info_D;
        todays_info.M = todays_info_M;
        todays_info.D = todays_info_Day;
        obj = dram_cls;
    endfunction

    function Data_Dir get_dram_data();  
        logic [7:0] temp [0:7];
        Data_Dir data;
        int i;
        for (i = 0; i < 8; i = i + 1) begin
            temp[i] = obj.golden_DRAM[65536 + req_no * 8 + i];
        end
        
        data.Index_A = {temp[7], temp[6][7:4]};
        data.Index_B = {temp[6][3:0], temp[5]};
        data.Index_C = {temp[3], temp[2][7:4]};
        data.Index_D = {temp[2][3:0], temp[1]};
        data.M = temp[4];
        data.D = temp[0];
        return data;
    endfunction

    function bit check_date();
        Data_Dir dram;
        Month dram_month;
        Day dram_day;

        dram = get_dram_data();
        dram_month = dram.M;
        dram_day = dram.D;

        if (todays_info.M < dram.M) begin
            return 1;
        end else if (todays_info.M == dram.M && todays_info.D < dram.D) begin
            return 1;
        end else begin
            return 0;
        end
    endfunction

    function Warn_Msg get_golden_respond();
        if (check_date()) begin
            return Date_Warn;
        end else begin
            return No_Warn;
        end
    endfunction

    constraint valid_month {
        todays_info_M inside {[1:12]};  
    }

    constraint valid_day {
        if (todays_info_M == 2) {       
            todays_info_Day inside {[1:28]}; 
        } else if (todays_info_M inside {4, 6, 9, 11}) { 
            todays_info_Day inside {[1:30]}; 
        } else {                
            todays_info_Day inside {[1:31]}; 
        }
    }
endclass

index_check_cls act1;
update_cls act2;
Check_Valid_Date_cls act3;
random_act action;
DRAM_data dram_data;
Data_Dir dram;              // can be deleted

initial begin
    inf.rst_n = 1'b1;
    inf.sel_action_valid = 1'b0;
    inf.formula_valid = 1'b0;
    inf.mode_valid = 1'b0;
    inf.date_valid = 1'b0;
    inf.data_no_valid = 1'b0;
    inf.index_valid = 1'b0;
    inf.D = 72'bx;

    #(1) inf.rst_n = 0;
    #(100) inf.rst_n = 1;

    dram_data = new();

    for (i_pat = 0; i_pat < PATNUM; i_pat = i_pat + 1) begin
        action = new();
        @(negedge clk)
        input_task;
        while (inf.out_valid !== 1) @(negedge clk);
        case (action.act_id)
            Index_Check: begin
                if (inf.warn_msg != act1.get_golden_respond()) begin
                    $display("Wrong Answer");
                    // $display("answer: %d", act1.get_golden_respond());
                    $finish;
                end else if (inf.warn_msg == 2'b00 && !inf.complete) begin
                    $display("Wrong Answer");
                    $finish;
                end else begin
                    // $display("pass pattern no. %d", i_pat);
                end
            end
            Update: begin
                if (inf.warn_msg != act2.update_and_respond()) begin
                    $display("Wrong Answer");
                    $finish;
                end else if (inf.warn_msg == 2'b00 && !inf.complete) begin
                    $display("Wrong Answer");
                    $finish;
                end else begin
                    // $display("pass pattern no. %d", i_pat);
                end
            end
            Check_Valid_Date: begin
                if (inf.warn_msg != act3.get_golden_respond()) begin
                    $display("Wrong Answer");
                    $finish;
                end else if (inf.warn_msg == 2'b00 && !inf.complete) begin
                    $display("Wrong Answer");
                    $finish;
                end else begin
                    // $display("pass pattern no. %d", i_pat);
                end
            end
        endcase
    end

    $display("Congratulations");
    $finish;
end

task input_task;
    int idle;
    begin
        idle = ($urandom_range(0, 3));
        repeat (idle) @(negedge clk);

        if (action.randomize()) begin
            current_act = action.act_id;
        end else begin
            $display("Randomization failed!");
        end

        inf.sel_action_valid = 1'b1;
        inf.D = {70'bx, action.act_id};
        @(negedge clk);

        inf.sel_action_valid = 1'b0;
        inf.D = 72'bx;

        idle = ($urandom_range(0, 3));
        repeat (idle) @(negedge clk);

        case (action.act_id)
            Index_Check: begin
                act1 = new(dram_data);

                inf.formula_valid = 1'b1;
                inf.D = {69'bx, act1.get_formula()};
                @(negedge clk);
                inf.formula_valid = 1'b0;
                inf.D = 72'bx;
                idle = ($urandom_range(0, 3));
                repeat (idle) @(negedge clk);

                inf.mode_valid = 1'b1;
                inf.D = {70'bx, act1.get_mode()};
                @(negedge clk);
                inf.mode_valid = 1'b0;
                inf.D = 72'bx;
                idle = ($urandom_range(0, 3));
                repeat (idle) @(negedge clk);

                inf.date_valid = 1'b1;
                inf.D = {63'bx, act1.get_month(), act1.get_date()};
                @(negedge clk);
                inf.date_valid = 1'b0;
                inf.D = 72'bx;
                idle = ($urandom_range(0, 3));
                repeat (idle) @(negedge clk);

                inf.data_no_valid = 1'b1;
                inf.D = {64'bx, act1.get_no_dram()};
                @(negedge clk);
                inf.data_no_valid = 1'b0;
                inf.D = 72'bx;
                idle = ($urandom_range(0, 3));
                repeat (idle) @(negedge clk);

                inf.index_valid = 1'b1;
                inf.D = {60'bx, act1.get_today_index_A()};
                @(negedge clk);
                inf.index_valid = 1'b0;
                inf.D = 72'bx;
                idle = ($urandom_range(0, 3));
                repeat (idle) @(negedge clk);

                inf.index_valid = 1'b1;
                inf.D = {60'bx, act1.get_today_index_B()};
                @(negedge clk);
                inf.index_valid = 1'b0;
                inf.D = 72'bx;
                idle = ($urandom_range(0, 3));
                repeat (idle) @(negedge clk);

                inf.index_valid = 1'b1;
                inf.D = {60'bx, act1.get_today_index_C()};
                @(negedge clk);
                inf.index_valid = 1'b0;
                inf.D = 72'bx;
                idle = ($urandom_range(0, 3));
                repeat (idle) @(negedge clk);

                inf.index_valid = 1'b1;
                inf.D = {60'bx, act1.get_today_index_D()};
                @(negedge clk);
                inf.index_valid = 1'b0;
                inf.D = 72'bx;
            end

            Update: begin
                act2 = new(dram_data);

                inf.date_valid = 1'b1;
                inf.D = {63'bx, act2.todays_info.M, act2.todays_info.D};
                @(negedge clk);
                inf.date_valid = 1'b0;
                inf.D = 72'bx;
                idle = ($urandom_range(0, 3));
                repeat (idle) @(negedge clk);

                inf.data_no_valid = 1'b1;
                inf.D = {64'bx, act2.req_no};
                @(negedge clk);
                inf.data_no_valid = 1'b0;
                inf.D = 72'bx;
                idle = ($urandom_range(0, 3));
                repeat (idle) @(negedge clk);

                inf.index_valid = 1'b1;
                inf.D = {60'bx, act2.todays_info.Index_A};
                @(negedge clk);
                inf.index_valid = 1'b0;
                inf.D = 72'bx;
                idle = ($urandom_range(0, 3));
                repeat (idle) @(negedge clk);

                inf.index_valid = 1'b1;
                inf.D = {60'bx, act2.todays_info.Index_B};
                @(negedge clk);
                inf.index_valid = 1'b0;
                inf.D = 72'bx;
                idle = ($urandom_range(0, 3));
                repeat (idle) @(negedge clk);

                inf.index_valid = 1'b1;
                inf.D = {60'bx, act2.todays_info.Index_C};
                @(negedge clk);
                inf.index_valid = 1'b0;
                inf.D = 72'bx;
                idle = ($urandom_range(0, 3));
                repeat (idle) @(negedge clk);

                inf.index_valid = 1'b1;
                inf.D = {60'bx, act2.todays_info.Index_D};
                @(negedge clk);
                inf.index_valid = 1'b0;
                inf.D = 72'bx;
            end

            Check_Valid_Date: begin
                act3 = new(dram_data);

                inf.date_valid = 1'b1;
                inf.D = {63'bx, act3.todays_info.M, act3.todays_info.D};
                @(negedge clk);
                inf.date_valid = 1'b0;
                inf.D = 72'bx;
                idle = ($urandom_range(0, 3));
                repeat (idle) @(negedge clk);

                inf.data_no_valid = 1'b1;
                inf.D = {64'bx, act3.req_no};
                @(negedge clk);
                inf.data_no_valid = 1'b0;
                inf.D = 72'bx;
            end
        endcase
    end
endtask

endprogram
