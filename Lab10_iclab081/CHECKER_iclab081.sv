/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab10: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;

// integer fp_w;

// initial begin
// fp_w = $fopen("out_valid.txt", "w");
// end

/**
 * This section contains the definition of the class and the instantiation of the object.
 *  * 
 * The always_ff blocks update the object based on the values of valid signals.
 * When valid signal is true, the corresponding property is updated with the value of inf.D
 */

class Formula_and_mode;
    Formula_Type f_type;
    Mode f_mode;
endclass

Action action_reg;
logic [1:0] in_valid_count;
Formula_Type current_formula, formula_sampled;
Mode current_mode, mode_sampled;
Index_var current_index_value;

Formula_and_mode fm_info = new();

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        action_reg <= Index_Check;
    end else begin
        action_reg <= inf.sel_action_valid ? inf.D.d_act[0] : action_reg;
    end
end

always_ff @(negedge clk or negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        in_valid_count <= 'd0;
    end else begin
        in_valid_count <= inf.index_valid ? in_valid_count + 'd1 : in_valid_count;
    end
end

always_ff @(negedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        current_formula <= Index_Check;
    end else begin
        current_formula <= inf.formula_valid ? inf.D.d_formula[0] : current_formula;
    end
end

always_ff @(negedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        current_mode <= Insensitive;
    end else begin
        current_mode <= inf.mode_valid ? inf.D.d_mode[0] : current_mode;
    end
end

always_ff @(negedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        current_index_value <= 0;
    end else begin
        current_index_value <= (action_reg == Update && inf.index_valid) ? inf.D.d_index[0] : current_index_value;
    end
end

//================================================================
// Covergroups
//================================================================

covergroup cg @(posedge clk iff (action_reg == Update && inf.index_valid));
    coverpoint inf.D.d_index[0] {
        option.auto_bin_max = 32;
    }
endgroup

covergroup cg_formula @(posedge clk iff inf.formula_valid);
    cp1: coverpoint inf.D.d_formula[0] {
        option.at_least = 150;
    }
endgroup

covergroup cg_mode @(posedge clk iff inf.mode_valid);
    cp2: coverpoint inf.D.d_mode[0] {
        option.at_least = 150;
    }
endgroup

covergroup cg_cross @(posedge clk iff inf.mode_valid);
    cross_cp: cross formula_sampled, mode_sampled {
        option.at_least = 150;
    }
endgroup

covergroup cg_warn @(inf.out_valid);
    coverpoint inf.warn_msg{
        option.at_least = 50;
    }
endgroup

covergroup cg_act @(posedge clk iff inf.sel_action_valid);
    coverpoint inf.D.d_act[0] {
        bins trans [] = ([Index_Check : Check_Valid_Date] => [Index_Check : Check_Valid_Date]);
        option.at_least = 300;
    }
endgroup


cg cg1 = new();
cg_warn cg2 = new();
cg_act cg3 = new();
cg_formula cg4 = new();
cg_mode cg5 = new();
cg_cross cg6 = new();


always @(posedge clk iff inf.formula_valid) begin
    formula_sampled = inf.D.d_formula[0];
    cg4.sample();
end

always @(posedge clk iff inf.mode_valid) begin
    mode_sampled = inf.D.d_mode[0];
    cg5.sample();
end

always @(posedge clk iff inf.mode_valid) begin
    cg6.sample();
end

//================================================================
// Assertions
//================================================================

property reset_check;
    @(posedge clk) disable iff (inf.rst_n)
    inf.out_valid === 1'b0 && inf.warn_msg === 2'b0 && inf.complete === 1'b0 && inf.AR_VALID === 1'b0 && inf.AR_ADDR === 17'b0 && inf.R_READY === 1'b0 && inf.AW_VALID === 1'b0 && inf.AW_ADDR === 17'b0 && inf.W_VALID === 1'b0 && inf.W_DATA === 64'b0 && inf.B_READY === 1'b0;
endproperty: reset_check

assert property (reset_check)
    else begin
        $error("Assertion 1 is violated");
        $finish();
    end


assert property (latency_check_1)
    else begin
        $error("Assertion 2 is violated");
        $finish();
    end

assert property (latency_check_2)
    else begin
        $error("Assertion 2 is violated");
        $finish();
    end

assert property (latency_check_3)
    else begin
        $error("Assertion 2 is violated");
        $finish();
    end


property latency_check_1;
    @(negedge clk) disable iff (!inf.rst_n)
    (action_reg == Index_Check && in_valid_count == 3 && inf.index_valid) |=> ##[0:999] inf.out_valid;
endproperty: latency_check_1

property latency_check_2;
    @(negedge clk) disable iff (!inf.rst_n)
    (action_reg == Update && in_valid_count == 3 && inf.index_valid) |=> ##[0:999] inf.out_valid;
endproperty: latency_check_2

property latency_check_3;
    @(negedge clk) disable iff (!inf.rst_n)
    (action_reg == Check_Valid_Date && inf.data_no_valid) |=> ##[0:999] inf.out_valid;
endproperty: latency_check_3

assert property (complete_check)
    else begin
        $error("Assertion 3 is violated");
        $finish();
    end

property complete_check;
    @(negedge clk) disable iff (!inf.rst_n)
    inf.complete |-> inf.warn_msg == 2'b00;
endproperty: complete_check

assert property (formula_valid_check)
    else begin
        $error("Assertion 4 is violated");
        $finish();
    end

property formula_valid_check;
    @(negedge clk) disable iff (!inf.rst_n)
    (inf.sel_action_valid && inf.D.d_act[0] == 2'b00) |=> ##[0:3] inf.formula_valid;
endproperty: formula_valid_check

assert property (mode_valid_check)
    else begin
        $error("Assertion 4 is violated");
        $finish();
    end

property mode_valid_check;
    @(negedge clk) disable iff (!inf.rst_n)
    inf.formula_valid |=> ##[0:3] inf.mode_valid;
endproperty: mode_valid_check

assert property (date_valid_check)
    else begin
        $error("Assertion 4 is violated");
        $finish();
    end

property date_valid_check;
    @(negedge clk) disable iff (!inf.rst_n)
    (inf.mode_valid || (inf.sel_action_valid && (inf.D.d_act[0] == 2'b01 || inf.D.d_act[0] == 2'b10))) |=> ##[0:3] inf.date_valid;
endproperty: date_valid_check

assert property (data_no_valid_check)
    else begin
        $error("Assertion 4 is violated");
        $finish();
    end

property data_no_valid_check;
    @(negedge clk) disable iff (!inf.rst_n)
    inf.date_valid |=> ##[0:3] inf.data_no_valid;
endproperty: data_no_valid_check

assert property (index_valid_check)
    else begin
        $error("Assertion 4 is violated");
        $finish();
    end

property index_valid_check;
    @(negedge clk) disable iff (!inf.rst_n)
    ((action_reg == Index_Check || action_reg == Update) && (inf.data_no_valid || (inf.index_valid && in_valid_count < 3))) |=> ##[0:3] inf.index_valid;
endproperty: index_valid_check

assert property (overlap_check)
    else begin
        $error("Assertion 5 is violated");
        $finish();
    end

property overlap_check;
    @(negedge clk) disable iff (!inf.rst_n)
    (inf.sel_action_valid || inf.formula_valid || inf.mode_valid || inf.date_valid || inf.data_no_valid || inf.index_valid) |-> 
    (inf.sel_action_valid + inf.formula_valid + inf.mode_valid + inf.date_valid + inf.data_no_valid + inf.index_valid == 1);
endproperty: overlap_check

assert property (out_valid_check)
    else begin
        $error("Assertion 6 is violated");
        $finish();
    end

property out_valid_check;
    @(negedge clk) disable iff (!inf.rst_n)
    inf.out_valid |=> !inf.out_valid;
endproperty: out_valid_check

assert property (next_input_check)
    else begin
        $error("Assertion 7 is violated");
        $finish();
    end

property next_input_check;
    @(negedge clk) disable iff (!inf.rst_n)
    $fell(inf.out_valid) |=> ##[0:3] inf.sel_action_valid;
endproperty: next_input_check

assert property (date_check)
    else begin
        $error("Assertion 8 is violated");
        $finish();
    end

property date_check;
    @(negedge clk) disable iff (!inf.rst_n)
    inf.date_valid |-> 
    (
        (inf.D.d_date[0][8:5] == 1 && inf.D.d_date[0][4:0] > 0 && inf.D.d_date[0][4:0] <= 31) ||
        (inf.D.d_date[0][8:5] == 2 && inf.D.d_date[0][4:0] > 0 && inf.D.d_date[0][4:0] <= 28) ||
        (inf.D.d_date[0][8:5] == 3 && inf.D.d_date[0][4:0] > 0 && inf.D.d_date[0][4:0] <= 31) ||
        (inf.D.d_date[0][8:5] == 4 && inf.D.d_date[0][4:0] > 0 && inf.D.d_date[0][4:0] <= 30) ||
        (inf.D.d_date[0][8:5] == 5 && inf.D.d_date[0][4:0] > 0 && inf.D.d_date[0][4:0] <= 31) ||
        (inf.D.d_date[0][8:5] == 6 && inf.D.d_date[0][4:0] > 0 && inf.D.d_date[0][4:0] <= 30) ||
        (inf.D.d_date[0][8:5] == 7 && inf.D.d_date[0][4:0] > 0 && inf.D.d_date[0][4:0] <= 31) ||
        (inf.D.d_date[0][8:5] == 8 && inf.D.d_date[0][4:0] > 0 && inf.D.d_date[0][4:0] <= 31) ||
        (inf.D.d_date[0][8:5] == 9 && inf.D.d_date[0][4:0] > 0 && inf.D.d_date[0][4:0] <= 30) ||
        (inf.D.d_date[0][8:5] == 10 && inf.D.d_date[0][4:0] > 0 && inf.D.d_date[0][4:0] <= 31) ||
        (inf.D.d_date[0][8:5] == 11 && inf.D.d_date[0][4:0] > 0 && inf.D.d_date[0][4:0] <= 30) ||
        (inf.D.d_date[0][8:5] == 12 && inf.D.d_date[0][4:0] > 0 && inf.D.d_date[0][4:0] <= 31)
    );
endproperty: date_check

assert property (dram_check)
    else begin
        $error("Assertion 9 is violated");
        $finish();
    end
property dram_check;
    @(negedge clk) disable iff (!inf.rst_n)
    inf.AR_VALID |-> !inf.AW_VALID;
endproperty

endmodule