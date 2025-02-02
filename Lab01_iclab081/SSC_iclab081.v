//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Fall
//   Lab01 Exercise		: Snack Shopping Calculator
//   Author     		  : Yu-Hsiang Wang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SSC.v
//   Module Name : SSC
//   Release version : V1.0 (Release Date: 2024-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module SSC(
    // Input signals
    card_num,
    input_money,
    snack_num,
    price, 
    // Output signals
    out_valid,
    out_change
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input [63:0] card_num;
input [8:0] input_money;
input [31:0] snack_num;
input [31:0] price;
output out_valid;
output [8:0] out_change;    

//================================================================
//    Wire & Registers 
//================================================================
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment

wire [3:0] a, c, e, g, i, k, m, o;
wire [3:0] b, d, f, h, j, l, n, p;
wire a1, c1, e1, g1, i1, k1, m1, o1;
wire [3:0] snack_num_1, snack_num_2, snack_num_3, snack_num_4, snack_num_5, snack_num_6, snack_num_7, snack_num_8;
wire [3:0] price_1, price_2, price_3, price_4, price_5, price_6, price_7, price_8;
wire [4:0] total_0, total_1;
wire [5:0] total_2, total_3, total_4, total_5;
wire [6:0] total_6, total_7, total_8, total_9, total_10, total_11, total_12, total_13;
wire [7:0] total, total_14, total_15, total_16, total_17, total_18, total_19, total_20, total_21;
wire [7:0] total_price [7:0];
wire [7:0] stage_1 [7:0];
wire [7:0] stage_2 [7:0];
wire [7:0] stage_3 [7:0];
wire [7:0] stage_4 [7:0];
wire [7:0] stage_5 [7:0];
wire [7:0] total_price_sorted [7:0];
reg [7:0] total_price_sorted_cummulative_7;
reg [8:0] total_price_sorted_cummulative_6;
reg [9:0] total_price_sorted_cummulative_5;
reg [9:0] total_price_sorted_cummulative_4;
reg [10:0] total_price_sorted_cummulative_3;
reg [10:0] total_price_sorted_cummulative_2;
reg [10:0] total_price_sorted_cummulative_1;
reg [10:0] total_price_sorted_cummulative_0, C34, C56, C78;
reg [8:0] out_change_temp;

//wire [8:0] snack_sum;


//================================================================
//    DESIGN
//================================================================

assign b = card_num [59:56];
assign d = card_num [51:48];
assign f = card_num [43:40];
assign h = card_num [35:32];
assign j = card_num [27:24];
assign l = card_num [19:16];
assign n = card_num [11:8];
assign p = card_num [3:0];

comparer a_comparer(.input_digit(card_num [63:60]), .output_digit_1(a1), .output_digit_2(a));
comparer c_comparer(.input_digit(card_num [55:52]), .output_digit_1(c1), .output_digit_2(c));
comparer e_comparer(.input_digit(card_num [47:44]), .output_digit_1(e1), .output_digit_2(e));
comparer g_comparer(.input_digit(card_num [39:36]), .output_digit_1(g1), .output_digit_2(g));
comparer i_comparer(.input_digit(card_num [31:28]), .output_digit_1(i1), .output_digit_2(i));
comparer k_comparer(.input_digit(card_num [23:20]), .output_digit_1(k1), .output_digit_2(k));
comparer m_comparer(.input_digit(card_num [15:12]), .output_digit_1(m1), .output_digit_2(m));
comparer o_comparer(.input_digit(card_num [7:4]), .output_digit_1(o1), .output_digit_2(o));

assign total_0 = a + b; 
assign total_1 = total_0 + c;
assign total_2 = total_1 + d;
assign total_3 = total_2 + e;
assign total_4 = total_3 + f;
assign total_5 = total_4 + g;
assign total_6 = total_5 + h;
assign total_7 = total_6 + i;
assign total_8 = total_7 + j;
assign total_9 = total_8 + k;
assign total_10 = total_9 + l;
assign total_11 = total_10 + m;
assign total_12 = total_11 + n;
assign total_13 = total_12 + o;
assign total_14 = total_13 + p;
assign total_15 = total_14 + a1;
assign total_16 = total_15 + c1;
assign total_17 = total_16 + e1;
assign total_18 = total_17 + g1;
assign total_19 = total_18 + i1;
assign total_20 = total_19 + k1;
assign total_21 = total_20 + m1;
assign total = total_21 + o1;

assign out_valid = (total % 10 == 0) ? 1 : 0;

assign snack_num_1 = snack_num[31:28];
assign snack_num_2 = snack_num[27:24];
assign snack_num_3 = snack_num[23:20];
assign snack_num_4 = snack_num[19:16];
assign snack_num_5 = snack_num[15:12];
assign snack_num_6 = snack_num[11:8];
assign snack_num_7 = snack_num[7:4];
assign snack_num_8 = snack_num[3:0];

assign price_1 = price[31:28];
assign price_2 = price[27:24];
assign price_3 = price[23:20];
assign price_4 = price[19:16];
assign price_5 = price[15:12];
assign price_6 = price[11:8];
assign price_7 = price[7:4];
assign price_8 = price[3:0];


assign total_price[7] = snack_num_1 * price_1;
assign total_price[6] = snack_num_2 * price_2;
assign total_price[5] = snack_num_3 * price_3;
assign total_price[4] = snack_num_4 * price_4;
assign total_price[3] = snack_num_5 * price_5;
assign total_price[2] = snack_num_6 * price_6;
assign total_price[1] = snack_num_7 * price_7;
assign total_price[0] = snack_num_8 * price_8;

assign stage_1[7] = (total_price[7] < total_price[6]) ? total_price[7] : total_price[6];
assign stage_1[6] = (total_price[7] < total_price[6]) ? total_price[6] : total_price[7];
assign stage_1[5] = (total_price[5] > total_price[4]) ? total_price[5] : total_price[4];
assign stage_1[4] = (total_price[5] > total_price[4]) ? total_price[4] : total_price[5];
assign stage_1[3] = (total_price[3] < total_price[2]) ? total_price[3] : total_price[2];
assign stage_1[2] = (total_price[3] < total_price[2]) ? total_price[2] : total_price[3];
assign stage_1[1] = (total_price[1] > total_price[0]) ? total_price[1] : total_price[0];
assign stage_1[0] = (total_price[1] > total_price[0]) ? total_price[0] : total_price[1];

assign stage_2[7] = (stage_1[7] < stage_1[5]) ? stage_1[7] : stage_1[5];
assign stage_2[6] = (stage_1[6] < stage_1[4]) ? stage_1[6] : stage_1[4];
assign stage_2[5] = (stage_1[7] < stage_1[5]) ? stage_1[5] : stage_1[7];
assign stage_2[4] = (stage_1[6] < stage_1[4]) ? stage_1[4] : stage_1[6];
assign stage_2[3] = (stage_1[3] > stage_1[1]) ? stage_1[3] : stage_1[1];
assign stage_2[2] = (stage_1[2] > stage_1[0]) ? stage_1[2] : stage_1[0];
assign stage_2[1] = (stage_1[3] > stage_1[1]) ? stage_1[1] : stage_1[3];
assign stage_2[0] = (stage_1[2] > stage_1[0]) ? stage_1[0] : stage_1[2];

assign stage_3[7] = (stage_2[7] < stage_2[6]) ? stage_2[7] : stage_2[6];
assign stage_3[6] = (stage_2[7] < stage_2[6]) ? stage_2[6] : stage_2[7];
assign stage_3[5] = (stage_2[5] < stage_2[4]) ? stage_2[5] : stage_2[4];
assign stage_3[4] = (stage_2[5] < stage_2[4]) ? stage_2[4] : stage_2[5];
assign stage_3[3] = (stage_2[3] > stage_2[2]) ? stage_2[3] : stage_2[2];
assign stage_3[2] = (stage_2[3] > stage_2[2]) ? stage_2[2] : stage_2[3];
assign stage_3[1] = (stage_2[1] > stage_2[0]) ? stage_2[1] : stage_2[0];
assign stage_3[0] = (stage_2[1] > stage_2[0]) ? stage_2[0] : stage_2[1];

assign stage_4[7] = (stage_3[7] < stage_3[3]) ? stage_3[7] : stage_3[3];
assign stage_4[6] = (stage_3[6] < stage_3[2]) ? stage_3[6] : stage_3[2];
assign stage_4[5] = (stage_3[5] < stage_3[1]) ? stage_3[5] : stage_3[1];
assign stage_4[4] = (stage_3[4] < stage_3[0]) ? stage_3[4] : stage_3[0];
assign stage_4[3] = (stage_3[7] < stage_3[3]) ? stage_3[3] : stage_3[7];
assign stage_4[2] = (stage_3[6] < stage_3[2]) ? stage_3[2] : stage_3[6];
assign stage_4[1] = (stage_3[5] < stage_3[1]) ? stage_3[1] : stage_3[5];
assign stage_4[0] = (stage_3[4] < stage_3[0]) ? stage_3[0] : stage_3[4];

assign stage_5[7] = (stage_4[7] < stage_4[5]) ? stage_4[7] : stage_4[5];
assign stage_5[6] = (stage_4[6] < stage_4[4]) ? stage_4[6] : stage_4[4];
assign stage_5[5] = (stage_4[7] < stage_4[5]) ? stage_4[5] : stage_4[7];
assign stage_5[4] = (stage_4[6] < stage_4[4]) ? stage_4[4] : stage_4[6];
assign stage_5[3] = (stage_4[3] < stage_4[1]) ? stage_4[3] : stage_4[1];
assign stage_5[2] = (stage_4[2] < stage_4[0]) ? stage_4[2] : stage_4[0];
assign stage_5[1] = (stage_4[3] < stage_4[1]) ? stage_4[1] : stage_4[3];
assign stage_5[0] = (stage_4[2] < stage_4[0]) ? stage_4[0] : stage_4[2];


assign total_price_sorted[0] = (stage_5[7] < stage_5[6]) ? stage_5[7] : stage_5[6];
assign total_price_sorted[1] = (stage_5[7] < stage_5[6]) ? stage_5[6] : stage_5[7];
assign total_price_sorted[2] = (stage_5[5] < stage_5[4]) ? stage_5[5] : stage_5[4];
assign total_price_sorted[3] = (stage_5[5] < stage_5[4]) ? stage_5[4] : stage_5[5];
assign total_price_sorted[4] = (stage_5[3] < stage_5[2]) ? stage_5[3] : stage_5[2];
assign total_price_sorted[5] = (stage_5[3] < stage_5[2]) ? stage_5[2] : stage_5[3];
assign total_price_sorted[6] = (stage_5[1] < stage_5[0]) ? stage_5[1] : stage_5[0];
assign total_price_sorted[7] = (stage_5[1] < stage_5[0]) ? stage_5[0] : stage_5[1];


always @(*) begin
    total_price_sorted_cummulative_7 = total_price_sorted[7];                                       // 1
    total_price_sorted_cummulative_6 = total_price_sorted_cummulative_7 + total_price_sorted[6];    // 1 + 2
    C34 = total_price_sorted[5] + total_price_sorted[4];                                            // 3 + 4
    C56 = total_price_sorted[3] + total_price_sorted[2];                                            // 5 + 6
    C78 = total_price_sorted[1] + total_price_sorted[0];                                            // 7 + 8
    total_price_sorted_cummulative_5 = total_price_sorted_cummulative_6 + total_price_sorted[5];    // 1 + 2 + 3
    total_price_sorted_cummulative_4 = total_price_sorted_cummulative_6 + C34;                      // 1 + 2 + 3 + 4

    total_price_sorted_cummulative_3 = total_price_sorted_cummulative_4 + total_price_sorted[3];    // 1 + 2 + 3 + 4 + 5
    total_price_sorted_cummulative_2 = total_price_sorted_cummulative_4 + C56;                      // 1 + 2 + 3 + 4 + 5 + 6 
    total_price_sorted_cummulative_1 = total_price_sorted_cummulative_2 + total_price_sorted[1];    // to 7
    total_price_sorted_cummulative_0 = total_price_sorted_cummulative_2 + C78;                      // to 8
end

always @(*) begin
    if (out_valid == 0) begin
        out_change_temp = input_money;
    end else begin
        if (input_money >= total_price_sorted_cummulative_4) begin
            if (input_money >= total_price_sorted_cummulative_2) begin
                if (input_money >= total_price_sorted_cummulative_1) begin
                    if (input_money >= total_price_sorted_cummulative_0) begin
                        out_change_temp = input_money - total_price_sorted_cummulative_0;
                    end else begin
                        out_change_temp = input_money - total_price_sorted_cummulative_1;
                    end
                end else begin
                    out_change_temp = input_money - total_price_sorted_cummulative_2;
                end
            end else begin
                if (input_money >= total_price_sorted_cummulative_3) begin
                    out_change_temp = input_money - total_price_sorted_cummulative_3;
                end else begin
                    out_change_temp = input_money - total_price_sorted_cummulative_4;
                end
            end
        end else begin
            if (input_money >= total_price_sorted_cummulative_6) begin
                if (input_money >= total_price_sorted_cummulative_5) begin
                    out_change_temp = input_money - total_price_sorted_cummulative_5;
                end else begin
                    out_change_temp = input_money - total_price_sorted_cummulative_6;
                end
            end else begin
                if (input_money >= total_price_sorted_cummulative_7) begin
                    out_change_temp = input_money - total_price_sorted_cummulative_7;
                end else begin
                    out_change_temp = input_money;
                end
            end
        end
    end
end

assign out_change = out_change_temp;

endmodule



module comparer(
    input [3:0] input_digit,
    output reg output_digit_1,
    output reg [3:0] output_digit_2
);

always @(*) begin
    if (input_digit >= 4'd5) begin
        output_digit_1 = 1;
        output_digit_2 = (input_digit << 1) - 4'd10;
    end else begin
        output_digit_1 = 0;
        output_digit_2 = input_digit << 1;
    end
end

endmodule

