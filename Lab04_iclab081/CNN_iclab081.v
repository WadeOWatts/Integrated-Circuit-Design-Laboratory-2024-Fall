//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Convolution Neural Network 
//   Author     		: Yu-Chi Lin (a6121461214.st12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CNN.v
//   Module Name : CNN
//   Release version : V1.0 (Release Date: 2024-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CNN(
    //Input Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel_ch1,
    Kernel_ch2,
	Weight,
    Opt,

    //Output Port
    out_valid,
    out
    );


//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

parameter IDLE = 3'd0;
parameter IN = 3'd1;
parameter CAL = 3'd2;
parameter OUT = 3'd3;

parameter IDLE_INPUT = 3'd0;
parameter CONV = 3'd1;
parameter CONV_CMP = 3'd2;
parameter ACTV = 3'd3;
parameter FLCN = 3'd4;
parameter SOFTMAX = 3'd5;

input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] Img, Kernel_ch1, Kernel_ch2, Weight;
input Opt;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;


//---------------------------------------------------------------------
//   Reg & Wires
//---------------------------------------------------------------------
reg [inst_sig_width+inst_exp_width:0] img_temp [0:2][0:48];
reg [inst_sig_width+inst_exp_width:0] Kernel_ch1_temp [0:2][0:3];
reg [inst_sig_width+inst_exp_width:0] Kernel_ch2_temp [0:2][0:3];
reg [inst_sig_width+inst_exp_width:0] Weight_temp [0:2][0:7];
reg opt_reg;

reg [inst_sig_width+inst_exp_width:0] calc_out_1 [0:5][0:5];
reg [inst_sig_width+inst_exp_width:0] calc_out_2 [0:5][0:5];
reg [inst_sig_width+inst_exp_width:0] max_pool_reg [0:1][0:3];
reg [inst_sig_width+inst_exp_width:0] softmax_temp [0:2];

reg [6:0] counter;
reg [1:0] current_state, next_state;
reg [2:0] cs_process, ns_process;

wire [inst_sig_width+inst_exp_width:0] U1_temp, U2_temp, U3_temp, U4_temp, U5_temp, U6_temp;
wire [inst_sig_width+inst_exp_width:0] U7_temp, U8_temp, U9_temp, U10_temp, U11_temp, S1_temp, T1_temp;
wire [inst_sig_width+inst_exp_width:0] U1_a, U1_b, U1_c, U1_d, U1_e, U1_f, U1_g, U1_h;
wire [inst_sig_width+inst_exp_width:0] U2_a, U2_b, U2_c, U2_d, U2_e, U2_f, U2_g, U2_h;
wire [inst_sig_width+inst_exp_width:0] U3_a, U3_b, U4_a, U4_b, U5_a, U5_b, U6_a, U6_b;
wire [inst_sig_width+inst_exp_width:0] U7_in, U8_in, U9_in, U11_a;
wire [inst_sig_width+inst_exp_width:0] T1_in, S1_in;

wire [3:0] calc_column, calc_row;
wire [6:0] ptr, ct_d5_m7;
wire [2:0] ptr_d36, ptr_d6, ptr_m6, ct_d25, ct_m5, ct_d4, ct_m4, ptr_s116, ptr_s108;
wire [5:0] ptr_cal;

integer i, j;
//---------------------------------------------------------------------
// IPs
//---------------------------------------------------------------------
DW_fp_dp4 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
    U1 ( .a(U1_a), .b(U1_b), .c(U1_c), .d(U1_d), .e(U1_e), .f(U1_f), .g(U1_g), .h(U1_h), .rnd(3'b000), .z(U1_temp), .status() );

DW_fp_dp4 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
    U2 ( .a(U2_a), .b(U2_b), .c(U2_c), .d(U2_d), .e(U2_e), .f(U2_f), .g(U2_g), .h(U2_h), .rnd(3'b000), .z(U2_temp), .status() );

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U3 ( .a(U3_a), .b(U3_b), .rnd(3'b000), .z(U3_temp), .status() );

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U4 ( .a(U4_a), .b(U4_b), .rnd(3'b000), .z(U4_temp), .status() );

DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U5 ( .a(U5_a), .b(U5_b), .zctr(1'b1), .aeqb(), .altb(), .agtb(), .unordered(), .z0(U5_temp), .z1(), .status0(), .status1() );

DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U6 ( .a(U6_a), .b(U6_b), .zctr(1'b1), .aeqb(), .altb(), .agtb(), .unordered(), .z0(U6_temp), .z1(), .status0(), .status1() );

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) 
    U7 ( .a(U7_in), .z(U7_temp), .status() );

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) 
    U8 ( .a(U8_in), .z(U8_temp), .status() );

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) 
    U9 ( .a(U9_in), .z(U9_temp), .status() );

DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
    U10 ( .a(U7_temp), .b(U8_temp), .c(U9_temp), .rnd(3'b000), .z(U10_temp), .status() );

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) 
    U11 ( .a(U11_a), .b(U10_temp), .rnd(3'b000), .z(U11_temp), .status() );

//---------------------------------------------------------------------
// Design
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cs_process <= IDLE_INPUT;
    end else begin
        cs_process <= ns_process;
    end
end

always @(*) begin
	case (current_state) 
		IDLE: next_state = in_valid ? IN : IDLE;
		IN: next_state = counter == 7'd74 ? CAL : IN;
		CAL: next_state = counter == 7'd122 ? OUT : CAL;
		OUT: next_state = counter == 7'd125 ? IDLE : OUT;
	endcase
end

always @(*) begin
    case (cs_process)
        IDLE_INPUT: ns_process = counter < 7'd3 ? IDLE_INPUT : CONV;
        CONV: ns_process = counter < 7'd75 ? CONV : CONV_CMP;
        CONV_CMP: ns_process = counter < 7'd111 ? CONV_CMP : ACTV;
        ACTV: ns_process = counter < 7'd119 ? ACTV : FLCN;
        FLCN: ns_process = counter < 7'd122 ? FLCN : SOFTMAX;
        SOFTMAX: ns_process = counter < 7'd125 ? SOFTMAX : IDLE_INPUT;
        default: ns_process = IDLE_INPUT;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 7'd0;
    end else begin
        if (next_state == IDLE) begin
            counter <= 7'd0;
        end else begin
            counter <= counter + 7'd1;
        end
    end
end

assign ptr = counter - 4;
assign calc_row = ptr % 36 / 6;
assign calc_column = ptr % 36 % 6;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 6; i = i + 1) begin
            for (j = 0; j < 6; j = j + 1) begin
                calc_out_1[i][j] <= 32'b0;
            end
        end
    end else begin
        case (cs_process)
            CONV, CONV_CMP: calc_out_1[calc_row][calc_column] <= U3_temp;
            IDLE_INPUT: begin
                for (i = 0; i < 6; i = i + 1) begin
                    for (j = 0; j < 6; j = j + 1) begin
                        calc_out_1[i][j] <= 32'b0;
                    end
                end
            end
            default: calc_out_1 <= calc_out_1;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 6; i = i + 1) begin
            for (j = 0; j < 6; j = j + 1) begin
                calc_out_2[i][j] <= 32'b0;
            end
        end
    end else begin
        case (cs_process)
            CONV, CONV_CMP: calc_out_2[calc_row][calc_column] <= U4_temp;
            IDLE_INPUT: begin
                for (i = 0; i < 6; i = i + 1) begin
                    for (j = 0; j < 6; j = j + 1) begin
                        calc_out_2[i][j] <= 32'b0;
                    end
                end
            end
            default: calc_out_2 <= calc_out_2;
        endcase
    end
end

assign ptr_d36 = ptr / 36;
assign ptr_cal = ptr % 36 / 6 * 7 + ptr % 6; //ptr % 36 / 6 * 7 + ptr % 6

assign U1_a = (cs_process == CONV || cs_process == CONV_CMP) ? img_temp[ptr_d36][ptr_cal] :
                cs_process == FLCN ? Weight_temp[ptr_s116][0] : 32'bx;

assign U1_b = (cs_process == CONV || cs_process == CONV_CMP) ? Kernel_ch1_temp[ptr_d36][0] :
                cs_process == FLCN ? max_pool_reg[0][0] : 32'bx;

assign U1_c = (cs_process == CONV || cs_process == CONV_CMP) ? img_temp[ptr_d36][ptr_cal + 1] :
                cs_process == FLCN ? Weight_temp[ptr_s116][1] : 32'bx;

assign U1_d = (cs_process == CONV || cs_process == CONV_CMP) ? Kernel_ch1_temp[ptr_d36][1] :
                cs_process == FLCN ? max_pool_reg[0][1] : 32'bx;

assign U1_e = (cs_process == CONV || cs_process == CONV_CMP) ? img_temp[ptr_d36][ptr_cal + 7] :
                cs_process == FLCN ? Weight_temp[ptr_s116][2] : 32'bx;

assign U1_f = (cs_process == CONV || cs_process == CONV_CMP) ? Kernel_ch1_temp[ptr_d36][2] :
                cs_process == FLCN ? max_pool_reg[0][2] : 32'bx;

assign U1_g = (cs_process == CONV || cs_process == CONV_CMP) ? img_temp[ptr_d36][ptr_cal + 8] :
                cs_process == FLCN ? Weight_temp[ptr_s116][3] : 32'bx;

assign U1_h = (cs_process == CONV || cs_process == CONV_CMP) ? Kernel_ch1_temp[ptr_d36][3] :
                cs_process == FLCN ? max_pool_reg[0][3] : 32'bx;

assign U3_a = (cs_process == CONV || cs_process == CONV_CMP || cs_process == FLCN) ? U1_temp : 32'bx;

assign U3_b = (cs_process == CONV || cs_process == CONV_CMP) ? calc_out_1[ptr % 36 / 6][ptr % 6] :
              (cs_process == FLCN) ? U2_temp : 32'bx;

assign U2_a = (cs_process == CONV || cs_process == CONV_CMP) ? img_temp[ptr_d36][ptr_cal] :
                cs_process == FLCN ? Weight_temp[ptr_s116][4] : 32'bx;

assign U2_b = (cs_process == CONV || cs_process == CONV_CMP) ? Kernel_ch2_temp[ptr_d36][0] :
                cs_process == FLCN ? max_pool_reg[1][0] : 32'bx;

assign U2_c = (cs_process == CONV || cs_process == CONV_CMP) ? img_temp[ptr_d36][ptr_cal + 1] :
                cs_process == FLCN ? Weight_temp[ptr_s116][5] : 32'bx;

assign U2_d = (cs_process == CONV || cs_process == CONV_CMP) ? Kernel_ch2_temp[ptr_d36][1] :
                cs_process == FLCN ? max_pool_reg[1][1] : 32'bx;

assign U2_e = (cs_process == CONV || cs_process == CONV_CMP) ? img_temp[ptr_d36][ptr_cal + 7] :
                cs_process == FLCN ? Weight_temp[ptr_s116][6] : 32'bx;

assign U2_f = (cs_process == CONV || cs_process == CONV_CMP) ? Kernel_ch2_temp[ptr_d36][2] :
                cs_process == FLCN ? max_pool_reg[1][2] : 32'bx;

assign U2_g = (cs_process == CONV || cs_process == CONV_CMP) ? img_temp[ptr_d36][ptr_cal + 8] :
                cs_process == FLCN ? Weight_temp[ptr_s116][7] : 32'bx;

assign U2_h = (cs_process == CONV || cs_process == CONV_CMP) ? Kernel_ch2_temp[ptr_d36][3] :
                cs_process == FLCN ? max_pool_reg[1][3] : 32'bx;

assign U4_a = (cs_process == CONV || cs_process == CONV_CMP) ? U2_temp :
              (cs_process == FLCN) ? U1_temp : 32'bx;

assign U4_b = (cs_process == CONV || cs_process == CONV_CMP) ? calc_out_2[ptr % 36 / 6][ptr % 6] :
              (cs_process == FLCN) ? U2_temp : 32'bx;

assign ptr_d6 = (ptr - 72) / 6;
assign ptr_m6 = (ptr - 72) % 6;

assign ptr_s108 = ptr - 7'd108;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 2; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                max_pool_reg[i][j] <= 32'hC0400000;
            end
        end
    end else begin
        case (cs_process)
            CONV_CMP: begin
                if (ptr_d6 < 3) begin
                    if (ptr_m6 < 3) begin
                        max_pool_reg[0][0] <= U5_temp;
                        max_pool_reg[1][0] <= U6_temp;
                    end else begin
                        max_pool_reg[0][1] <= U5_temp;
                        max_pool_reg[1][1] <= U6_temp;
                    end
                end else begin
                    if (ptr_m6 < 3) begin
                        max_pool_reg[0][2] <= U5_temp;
                        max_pool_reg[1][2] <= U6_temp;
                    end else begin
                        max_pool_reg[0][3] <= U5_temp;
                        max_pool_reg[1][3] <= U6_temp;
                    end
                end
            end

            ACTV: begin
                if (opt_reg) begin
                    max_pool_reg[(ptr_s108) / 4][(ptr_s108) % 4] <= T1_temp;
                end else begin
                    max_pool_reg[(ptr_s108) / 4][(ptr_s108) % 4] <= S1_temp;
                end
            end

            IDLE_INPUT: begin
                for (i = 0; i < 2; i = i + 1) begin
                    for (j = 0; j < 4; j = j + 1) begin
                        max_pool_reg[i][j] <= 32'hC0400000;
                    end
                end
            end

            default: max_pool_reg <= max_pool_reg;
        endcase        
    end
end

assign U5_a = (cs_process == CONV_CMP) ? 
                    ((ptr_d6 < 3) ? 
                        ((ptr_m6 < 3) ? max_pool_reg[0][0] : max_pool_reg[0][1]) :
                        (ptr_m6 < 3 ? max_pool_reg[0][2] : max_pool_reg[0][3])) : 
              32'bx;

assign U6_a = (cs_process == CONV_CMP) ? 
                    ((ptr_d6 < 3) ? 
                        ((ptr_m6 < 3) ? max_pool_reg[1][0] : max_pool_reg[1][1]) :
                        (ptr_m6 < 3 ? max_pool_reg[1][2] : max_pool_reg[1][3])) : 
              32'bx;

assign U5_b = cs_process == CONV_CMP ? U3_temp : 32'bx;
assign U6_b = cs_process == CONV_CMP ? U4_temp : 32'bx;

tanh T1 ( .input_fp(T1_in), .output_fp(T1_temp) );
sigmoid S1 ( .input_fp(S1_in), .output_fp(S1_temp) );

assign T1_in = (cs_process == ACTV) ? max_pool_reg[(ptr_s108) / 4][(ptr_s108) % 4] : 32'bx;
assign S1_in = (cs_process == ACTV) ? max_pool_reg[(ptr_s108) / 4][(ptr_s108) % 4] : 32'bx;

assign ct_d25 = counter / 25;
assign ct_m5 = counter % 5;
assign ct_d5_m7 = ((counter % 25) / 5) * 7;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 3; i = i + 1) begin
            for (j = 0; j < 49; j = j + 1) begin
                img_temp[i][j] <= 32'b0;
            end
        end
    end else begin
        if (in_valid) begin
            img_temp[ct_d25][((counter%25)/5 + 1)*7 + ct_m5 + 1] <= Img;

            if (counter == 7'd0 && Opt == 1'b1 || counter > 0 && opt_reg == 1'b1) begin
                if (counter%25/5 == 0) begin
                    img_temp[ct_d25][ct_m5 + 1] <= Img;
                end

                if (counter%25/5 == 4) begin
                    img_temp[ct_d25][ct_d5_m7 + ct_m5 + 15] <= Img;
                end

                if (counter%25%5 == 0) begin
                    img_temp[ct_d25][ct_d5_m7 + ct_m5 + 7] <= Img;
                end

                if (counter%25%5 == 4) begin
                    img_temp[ct_d25][ct_d5_m7 + ct_m5 + 9] <= Img;
                end

                if (counter%25 == 0) begin
                    img_temp[ct_d25][0] <= Img;
                end

                if (counter%25 == 4) begin
                    img_temp[ct_d25][6] <= Img;
                end

                if (counter%25 == 20) begin
                    img_temp[ct_d25][42] <= Img;
                end

                if (counter%25 == 24) begin
                    img_temp[ct_d25][48] <= Img;
                end
            end
        end

        if (ptr == 7'd120) begin
            for (i = 0; i < 3; i = i + 1) begin
                for (j = 0; j < 49; j = j + 1) begin
                    img_temp[i][j] <= 32'b0;
                end
            end
        end
    end
end

assign ct_d4 = counter / 4;
assign ct_m4 = counter % 4;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 3; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                Kernel_ch1_temp[i][j] <= 32'b0;
            end
        end
    end else begin
        if (in_valid && counter < 12) begin
            Kernel_ch1_temp[ct_d4][ct_m4] <= Kernel_ch1;
        end

        if (ptr == 7'd120) begin
            for (i = 0; i < 3; i = i + 1) begin
                for (j = 0; j < 4; j = j + 1) begin
                    Kernel_ch1_temp[i][j] <= 32'b0;
                end
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 3; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                Kernel_ch2_temp[i][j] <= 32'b0;
            end
        end
    end else begin
        if (in_valid && counter < 12) begin
            Kernel_ch2_temp[ct_d4][ct_m4] <= Kernel_ch2;
        end

        if (ptr == 7'd120) begin
            for (i = 0; i < 3; i = i + 1) begin
                for (j = 0; j < 4; j = j + 1) begin
                    Kernel_ch2_temp[i][j] <= 32'b0;
                end
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 3; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                Weight_temp[i][j] <= 32'b0;
            end
        end
    end else begin
        if (in_valid && counter < 24) begin
            Weight_temp[counter/8][counter%8] <= Weight;
        end

        if (ptr == 7'd120) begin
            for (i = 0; i < 3; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    Weight_temp[i][j] <= 32'b0;
                end
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        opt_reg <= 1'b0;
    end else begin
        if (in_valid && counter == 7'd0) begin
            opt_reg <= Opt;
        end
    end
end

assign ptr_s116 = ptr - 7'd116;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 3; i = i + 1) begin
            softmax_temp[i] <= 32'b0;
        end
    end else begin
        if (cs_process == FLCN) begin
            softmax_temp[ptr_s116] <= U3_temp;
        end

        if (counter == 0) begin
            for (i = 0; i < 3; i = i + 1) begin
                softmax_temp[i] <= 32'b0;
            end
        end
    end
end

assign U7_in = (cs_process == SOFTMAX) ? softmax_temp[0] : 32'bx;
assign U8_in = (cs_process == SOFTMAX) ? softmax_temp[1] : 32'bx;
assign U9_in = (cs_process == SOFTMAX) ? softmax_temp[2] : 32'bx;
assign U11_a = (counter == 7'd123) ? U7_temp : 
                (counter == 7'd124) ? U8_temp : 
                (counter == 7'd125) ? U9_temp : 32'bx;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out <= 32'b0;
    end else begin
        if (cs_process == SOFTMAX) begin
            out <= U11_temp;
        end else begin
            out <= 32'b0;
        end
    end
end 

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid <= 1'b0;
    end else begin
        if (cs_process == SOFTMAX) begin
            out_valid <= 1'b1;
        end else begin
            out_valid <= 1'b0;
        end
    end
end

endmodule

module sigmoid(
    input_fp,
    output_fp
);

parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

input [inst_sig_width+inst_exp_width:0] input_fp;
output [inst_sig_width+inst_exp_width:0] output_fp;

wire [inst_sig_width+inst_exp_width:0] exp_result, add_result;

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) 
    U1 ( .a({~input_fp[inst_sig_width+inst_exp_width], input_fp[inst_sig_width+inst_exp_width-1:0]}), .z(exp_result), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2 ( .a(exp_result), .b(32'h3F800000), .rnd(3'b000), .z(add_result), .status() );
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) 
    U3 ( .a(32'h3F800000), .b(add_result), .rnd(3'b000), .z(output_fp), .status() );

endmodule

module tanh(
    input_fp,
    output_fp
);

parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

input [inst_sig_width+inst_exp_width:0] input_fp;
output [inst_sig_width+inst_exp_width:0] output_fp;

wire [inst_sig_width+inst_exp_width:0] exp_result_pos, exp_result_neg, add_result, sub_result;

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) 
    U1 ( .a({~input_fp[inst_sig_width+inst_exp_width], input_fp[inst_sig_width+inst_exp_width-1:0]}), .z(exp_result_neg), .status() );
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) 
    U2 ( .a(input_fp[inst_sig_width+inst_exp_width:0]), .z(exp_result_pos), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U3 ( .a(exp_result_pos), .b(exp_result_neg), .rnd(3'b000), .z(add_result), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U4 ( .a(exp_result_pos), .b({~exp_result_neg[inst_sig_width+inst_exp_width], exp_result_neg[inst_sig_width+inst_exp_width-1:0]}), .rnd(3'b000), .z(sub_result), .status() );
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) 
    U5 ( .a(sub_result), .b(add_result), .rnd(3'b000), .z(output_fp), .status() );

endmodule