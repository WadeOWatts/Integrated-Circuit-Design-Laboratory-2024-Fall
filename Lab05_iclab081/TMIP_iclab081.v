module TMIP(
    // input signals
    clk,
    rst_n,
    in_valid, 
    in_valid2,
    
    image,
    template,
    image_size,
	action,
	
    // output signals
    out_valid,
    out_value
    );

input            clk, rst_n;
input            in_valid, in_valid2;

input      [7:0] image;
input      [7:0] template;
input      [1:0] image_size;
input      [2:0] action;

output reg       out_valid;
output reg       out_value;

//==================================================================
// parameter & integer
//==================================================================

parameter IDLE = 2'd0;
parameter INPUT = 2'd1;
parameter CALC = 2'd2;
parameter OUTPUT = 2'd3;

parameter RED = 2'd0;
parameter GREEN = 2'd1;
parameter BLUE = 2'd2;

parameter MAX_GRAYSCALE = 3'd0;
parameter AVERAGE = 3'd1;
parameter WEIGHTED = 3'd2;
parameter MAXPOOLING = 3'd3;
parameter NEGATIVE = 3'd4;
parameter FLIP = 3'd5;
parameter FILTER = 3'd6;
parameter CONVOLUTION = 3'd7;

parameter CALC_IDLE = 3'd7;

//==================================================================
// reg & wire
//==================================================================
reg [7:0] Img_input_R_A, Img_input_R_DI, Img_input_R_out;
reg [7:0] Img_input_G_A, Img_input_G_DI, Img_input_G_out;
reg [7:0] Img_input_B_A, Img_input_B_DI, Img_input_B_out;
reg [7:0] temp1_A, temp1_DI;
reg [7:0] max_pooling_1, max_pooling_2, max_pooling_3, max_pooling_4;
reg [7:0] filter_conv_temp [0:2][0:15];
reg [7:0] filter_r, filter_w;
reg [1:0] currunt_state, next_state;
reg [2:0] calc_cs, calc_ns;
reg [1:0] image_size_reg;
reg [7:0] Img_temp;
reg [9:0] counter;
reg [2:0] action_reg[0:7];
reg [7:0] array_len;
reg neg_flag, flip_flag, mp_flip;
reg [1:0] ptr_clr, mp_cnt;
reg [2:0] act_cnt;
reg [7:0] mp_ptr;
reg [7:0] data0, data1, data2, data3, data4, data5, data6, data7, data8;
reg [7:0] conv_ptr, element;
reg [19:0] out_temp;
reg temp1_WEB, temp1_OE, temp1_CS;

wire [7:0] Img_input_R_DO, Img_input_G_DO, Img_input_B_DO, temp1_DO;
wire [7:0] avg, max_g_result, weighted_result, max;
wire Img_input_R_WEB, Img_input_R_OE, Img_input_R_CS;
wire Img_input_G_WEB, Img_input_G_OE, Img_input_G_CS;
wire Img_input_B_WEB, Img_input_B_OE, Img_input_B_CS;
wire [2:0] ctm5;
wire [7:0] median;
wire [19:0] out;

//==================================================================
// design
//==================================================================

Img_input_R R_memory (.A0(Img_input_R_A[0]), .A1(Img_input_R_A[1]), .A2(Img_input_R_A[2]), .A3(Img_input_R_A[3]), 
             .A4(Img_input_R_A[4]), .A5(Img_input_R_A[5]), .A6(Img_input_R_A[6]), .A7(Img_input_R_A[7]), 
             .DO0(Img_input_R_DO[0]), .DO1(Img_input_R_DO[1]), .DO2(Img_input_R_DO[2]), .DO3(Img_input_R_DO[3]),
             .DO4(Img_input_R_DO[4]), .DO5(Img_input_R_DO[5]), .DO6(Img_input_R_DO[6]), .DO7(Img_input_R_DO[7]),
             .DI0(Img_input_R_DI[0]), .DI1(Img_input_R_DI[1]), .DI2(Img_input_R_DI[2]), .DI3(Img_input_R_DI[3]), 
             .DI4(Img_input_R_DI[4]), .DI5(Img_input_R_DI[5]), .DI6(Img_input_R_DI[6]), .DI7(Img_input_R_DI[7]), 
             .CK(clk), .WEB(Img_input_R_WEB), .OE(Img_input_R_OE), .CS(Img_input_R_CS));

Img_input_G G_memory (.A0(Img_input_G_A[0]), .A1(Img_input_G_A[1]), .A2(Img_input_G_A[2]), .A3(Img_input_G_A[3]), 
             .A4(Img_input_G_A[4]), .A5(Img_input_G_A[5]), .A6(Img_input_G_A[6]), .A7(Img_input_G_A[7]), 
             .DO0(Img_input_G_DO[0]), .DO1(Img_input_G_DO[1]), .DO2(Img_input_G_DO[2]), .DO3(Img_input_G_DO[3]), 
             .DO4(Img_input_G_DO[4]), .DO5(Img_input_G_DO[5]), .DO6(Img_input_G_DO[6]), .DO7(Img_input_G_DO[7]),
             .DI0(Img_input_G_DI[0]), .DI1(Img_input_G_DI[1]), .DI2(Img_input_G_DI[2]), .DI3(Img_input_G_DI[3]), 
             .DI4(Img_input_G_DI[4]), .DI5(Img_input_G_DI[5]), .DI6(Img_input_G_DI[6]), .DI7(Img_input_G_DI[7]), 
             .CK(clk), .WEB(Img_input_G_WEB), .OE(Img_input_G_OE), .CS(Img_input_G_CS));

Img_input_B B_memory (.A0(Img_input_B_A[0]), .A1(Img_input_B_A[1]), .A2(Img_input_B_A[2]), .A3(Img_input_B_A[3]), 
             .A4(Img_input_B_A[4]), .A5(Img_input_B_A[5]), .A6(Img_input_B_A[6]), .A7(Img_input_B_A[7]), 
             .DO0(Img_input_B_DO[0]), .DO1(Img_input_B_DO[1]), .DO2(Img_input_B_DO[2]), .DO3(Img_input_B_DO[3]), 
             .DO4(Img_input_B_DO[4]), .DO5(Img_input_B_DO[5]), .DO6(Img_input_B_DO[6]), .DO7(Img_input_B_DO[7]),
             .DI0(Img_input_B_DI[0]), .DI1(Img_input_B_DI[1]), .DI2(Img_input_B_DI[2]), .DI3(Img_input_B_DI[3]), 
             .DI4(Img_input_B_DI[4]), .DI5(Img_input_B_DI[5]), .DI6(Img_input_B_DI[6]), .DI7(Img_input_B_DI[7]), 
             .CK(clk), .WEB(Img_input_B_WEB), .OE(Img_input_B_OE), .CS(Img_input_B_CS));

process_temp_1 temp1_emmory (.A0(temp1_A[0]), .A1(temp1_A[1]), .A2(temp1_A[2]), .A3(temp1_A[3]), 
                             .A4(temp1_A[4]), .A5(temp1_A[5]), .A6(temp1_A[6]), .A7(temp1_A[7]),
                             .DO0(temp1_DO[0]), .DO1(temp1_DO[1]), .DO2(temp1_DO[2]), .DO3(temp1_DO[3]),
                             .DO4(temp1_DO[4]), .DO5(temp1_DO[5]), .DO6(temp1_DO[6]), .DO7(temp1_DO[7]), 
                             .DI0(temp1_DI[0]), .DI1(temp1_DI[1]), .DI2(temp1_DI[2]), .DI3(temp1_DI[3]), 
                             .DI4(temp1_DI[4]), .DI5(temp1_DI[5]), .DI6(temp1_DI[6]), .DI7(temp1_DI[7]),
                             .CK(clk), .WEB(temp1_WEB), .OE(temp1_OE), .CS(temp1_CS));

average_3numbers avg3 (.num1(Img_input_R_out), .num2(Img_input_G_out), .num3(Img_input_B_out), .avg(avg));
max_method max_g (.num1(Img_input_R_out), .num2(Img_input_G_out), .num3(Img_input_B_out), .out(max_g_result));
weighted weight_g (.num1(Img_input_R_out), .num2(Img_input_G_out), .num3(Img_input_B_out), .out(weighted_result));
max_pooling mp (.num1(max_pooling_1), .num2(max_pooling_2), .num3(max_pooling_3), .num4(max_pooling_4), .neg(neg_flag), .max(max));
median_quickselect U_median (.data0(data0), .data1(data1), .data2(data2), .data3(data3), .data4(data4), .data5(data5), .data6(data6), .data7(data7), .data8(data8), .neg_flag(neg_flag), .median(median));
Convolutioner U_conv (.template(template), .counter(counter), .clk(clk), .rst_n(rst_n), .in_valid(in_valid), .neg_flag(neg_flag),
                      .flip_flag(flip_flag), .element(element), .ptr_clr(ptr_clr), .out_valid(out_valid), .currunt_state(currunt_state), .out(out));

assign ctm5 = counter % 'd5;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        currunt_state <= IDLE;
    end else begin
        currunt_state <= next_state;
    end
end

always @(*) begin
    case (currunt_state)                                                   
        IDLE: begin 
            if (in_valid) begin
                next_state = INPUT;
            end else if (in_valid2) begin
                next_state = CALC;
            end else begin
                next_state = IDLE;
            end
        end
        INPUT : next_state = (~in_valid) ? IDLE : INPUT;
        CALC: next_state = (calc_ns == CALC_IDLE) ? OUTPUT : CALC;
        OUTPUT: begin
            if (flip_flag) begin
                case (array_len)
                    15: next_state = (conv_ptr == 'd19 && counter == 'd19) ? IDLE : OUTPUT;
                    63: next_state = (conv_ptr == 'd71 && counter == 'd19) ? IDLE : OUTPUT;
                    255: next_state = (conv_ptr == 'd15 && counter == 'd19) ? IDLE : OUTPUT;
                    default: next_state = IDLE;
                endcase
            end else begin
                case (array_len)
                    15: next_state = (counter == 'd19 && conv_ptr == 'd16) ? IDLE : OUTPUT;
                    63: next_state = (counter == 'd19 && conv_ptr == 'd64) ? IDLE : OUTPUT;
                    255: next_state = (counter == 'd19 && conv_ptr == 'd0) ? IDLE : OUTPUT;
                    default: next_state = IDLE;
                endcase
            end
        end
    endcase
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        calc_cs <= CALC_IDLE;
    end else begin
        calc_cs <= calc_ns;
    end
end

always @(*) begin
    case (calc_cs)                                                  
        CALC_IDLE: begin
            if (in_valid2) begin
                case (action)
                    MAX_GRAYSCALE: calc_ns = MAX_GRAYSCALE;
                    AVERAGE: calc_ns = AVERAGE;
                    WEIGHTED: calc_ns = WEIGHTED;
                    default: calc_ns = CALC_IDLE;
                endcase
            end else begin
                calc_ns = CALC_IDLE;
            end
        end
        MAX_GRAYSCALE: begin
            if (counter == array_len + 'd2) begin
                if (action_reg[1] == NEGATIVE) begin
                    calc_ns = action_reg[2];
                end else begin
                    calc_ns = action_reg[1];
                end
            end else begin
                calc_ns = MAX_GRAYSCALE;
            end
        end
        AVERAGE: begin
            if (counter == array_len + 'd2) begin
                if (action_reg[1] == NEGATIVE) begin
                    calc_ns = action_reg[2];
                end else begin
                    calc_ns = action_reg[1];
                end
            end else begin
                calc_ns = AVERAGE;
            end
        end 
        WEIGHTED: begin
            if (counter == array_len + 'd2) begin
                if (action_reg[1] == NEGATIVE) begin
                    calc_ns = action_reg[2];
                end else begin
                    calc_ns = action_reg[1];
                end
            end else begin
                calc_ns = WEIGHTED;
            end
        end
        MAXPOOLING: begin
            case (array_len)
                63: begin
                    if (counter == 'd80) begin
                        if (action_reg[1] == NEGATIVE) begin
                            calc_ns = action_reg[2];
                        end else begin
                            calc_ns = action_reg[1];
                        end
                    end else begin
                        calc_ns = MAXPOOLING;
                    end
                end
                255: begin
                    if (counter == 'd320) begin
                        if (action_reg[1] == NEGATIVE) begin
                            calc_ns = action_reg[2];
                        end else begin
                            calc_ns = action_reg[1];
                        end
                    end else begin
                        calc_ns = MAXPOOLING;
                    end
                end
                default: calc_ns = CALC_IDLE;
            endcase
        end
        FILTER: begin
            case (array_len)
                15: begin
                    if (counter == 'd32) begin
                        if (action_reg[1] == NEGATIVE) begin
                            calc_ns = action_reg[2];
                        end else begin
                            calc_ns = action_reg[1];
                        end
                    end else begin
                        calc_ns = FILTER;
                    end
                end
                63: begin
                    if (counter == 'd128) begin
                        if (action_reg[1] == NEGATIVE) begin
                            calc_ns = action_reg[2];
                        end else begin
                            calc_ns = action_reg[1];
                        end
                    end else begin
                        calc_ns = FILTER;
                    end
                end
                255: begin
                    if (counter == 'd512) begin
                        if (action_reg[1] == NEGATIVE) begin
                            calc_ns = action_reg[2];
                        end else begin
                            calc_ns = action_reg[1];
                        end
                    end else begin
                        calc_ns = FILTER;
                    end
                end
                default: calc_ns = CALC_IDLE;
            endcase
        end
        default: calc_ns = CALC_IDLE;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        Img_temp <= 8'd0;
    end else begin
        Img_temp <= (in_valid) ? image : 8'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        image_size_reg <= 2'd0;
    end else begin
        image_size_reg <= (next_state == 1 &&  currunt_state == 0) ? image_size : image_size_reg;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        array_len <= 8'd0;
    end else begin
        if (in_valid || in_valid2) begin
            case (image_size_reg)
                0: array_len <= 8'd15;
                1: array_len <= 8'd63;
                2: array_len <= 8'd255;
            endcase
        end else if (currunt_state == CALC) begin
            if (calc_cs == MAXPOOLING) begin                        
                case (array_len)
                    15: array_len <= 8'd15;
                    63: array_len <= (counter == 'd80) ? 8'd15 : 'd63;
                    255: array_len <= (counter == 'd320) ? 8'd63 : 'd255;
                endcase
            end 
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        mp_cnt <= 'd0;
    end else begin
        if (in_valid2) begin
            if (action == MAXPOOLING && mp_cnt < 'd3) begin
                mp_cnt <= mp_cnt + 'd1;
            end
        end else begin
            mp_cnt <= 'd0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        act_cnt <= 'd0;
    end else begin
        if (in_valid2) begin
            case (action)
                MAX_GRAYSCALE, AVERAGE, WEIGHTED, FILTER, CONVOLUTION: act_cnt <= act_cnt + 'd1;
                MAXPOOLING: begin
                    case (image_size_reg)
                        0: act_cnt <= act_cnt;
                        1: act_cnt <=  (mp_cnt > 'd0) ? act_cnt : act_cnt + 'd1;
                        2: act_cnt <=  (mp_cnt > 'd1) ? act_cnt : act_cnt + 'd1;
                    endcase
                end
                NEGATIVE: act_cnt <= (action_reg[7] == NEGATIVE) ? act_cnt - 'd1 : act_cnt + 'd1;
                FLIP: act_cnt <= act_cnt;
            endcase
        end else if (currunt_state == IDLE) begin
            act_cnt <= 'd0;
        end
    end
end

genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin: action_reg_loop                
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                action_reg[i] <= 3'd5;
            end else begin
                if (in_valid2) begin
                    case (action)
                        MAX_GRAYSCALE, AVERAGE, WEIGHTED: action_reg[i] <= (i == 7) ? action : action_reg[i+1];
                        MAXPOOLING: begin
                            case (image_size_reg)
                                1: begin
                                    if (mp_cnt > 'd0) begin
                                        action_reg[i] <= action_reg[i];
                                    end else begin
                                        if (action_reg[7] == 'd7) begin
                                            action_reg[i] <= (i == 7) ? action : action_reg[i];
                                        end else begin
                                            action_reg[i] <= (i == 7) ? action : action_reg[i+1];
                                        end
                                    end
                                end
                                2: begin
                                    if (mp_cnt > 'd1) begin
                                        action_reg[i] <= action_reg[i];
                                    end else begin
                                        if (action_reg[7] == 'd7) begin
                                            action_reg[i] <= (i == 7) ? action : action_reg[i];
                                        end else begin
                                            action_reg[i] <= (i == 7) ? action : action_reg[i+1];
                                        end
                                    end
                                end
                            endcase
                        end
                        NEGATIVE: begin
                            if (action_reg[7] == 'd7) begin
                                action_reg[i] <= (i == 7) ? action : action_reg[i];
                            end else if (action_reg[7] == NEGATIVE) begin
                                // action_reg[7] <= 'd7;
                                action_reg[i] <= (i == 7) ? 'd7 : action_reg[i];
                            end else begin
                                action_reg[i] <= (i == 7) ? action : action_reg[i+1];
                            end
                        end
                        FLIP: action_reg[i] <= action_reg[i];
                        FILTER: begin
                            if (action_reg[7] == 'd7) begin
                                action_reg[i] <= (i == 7) ? action : action_reg[i];
                            end else begin
                                action_reg[i] <= (i == 7) ? action : action_reg[i+1];
                            end
                        end
                        CONVOLUTION: begin
                            if (action_reg[7] == 'd7) begin
                                action_reg[i] <= (i == 7) ? action : action_reg[i];
                            end else begin
                                action_reg[i] <= (i == 7) ? action : action_reg[i+1];
                            end
                        end
                    endcase
                end else begin
                    if (currunt_state == CALC) begin
                        if (~in_valid2 && ((calc_cs == MAX_GRAYSCALE && action_reg[0] != MAX_GRAYSCALE) || (calc_cs == AVERAGE && action_reg[0] != AVERAGE) || (calc_cs == WEIGHTED && action_reg[0] != WEIGHTED))) begin
                            action_reg[i] <= (i == 7) ? 'd5 : action_reg[i+1];
                        end else begin
                            case (action_reg[0])
                                MAX_GRAYSCALE, AVERAGE, WEIGHTED: begin
                                    if (counter == array_len + 'd2) begin
                                        if (action_reg[1] == NEGATIVE) begin
                                            action_reg[i] <= (i == 6 || i == 7) ? 'd5 : action_reg[i+2];
                                        end else begin
                                            action_reg[i] <= (i == 7) ? 'd5 : action_reg[i+1];
                                        end
                                    end
                                end
                                MAXPOOLING: begin
                                    case (array_len)
                                        63: begin
                                            if (counter == 'd80) begin
                                                if (action_reg[1] == NEGATIVE) begin
                                                    action_reg[i] <= (i == 6 || i == 7) ? 'd5 : action_reg[i+2];
                                                end else begin
                                                    action_reg[i] <= (i == 7) ? 'd5 : action_reg[i+1];
                                                end
                                            end
                                        end
                                        255: begin
                                            if (counter == 'd320) begin
                                                if (action_reg[1] == NEGATIVE) begin
                                                    action_reg[i] <= (i == 6 || i == 7) ? 'd5 : action_reg[i+2];
                                                end else begin
                                                    action_reg[i] <= (i == 7) ? 'd5 : action_reg[i+1];
                                                end
                                            end
                                        end
                                    endcase
                                end
                                FILTER: begin
                                    case (array_len)
                                        15: begin
                                            if (counter == 'd32) begin
                                                if (action_reg[1] == NEGATIVE) begin
                                                    action_reg[i] <= (i == 6 || i == 7) ? 'd5 : action_reg[i+2];
                                                end else begin
                                                    action_reg[i] <= (i == 7) ? 'd5 : action_reg[i+1];
                                                end
                                            end
                                        end
                                        63: begin
                                            if (counter == 'd128) begin
                                                if (action_reg[1] == NEGATIVE) begin
                                                    action_reg[i] <= (i == 6 || i == 7) ? 'd5 : action_reg[i+2];
                                                end else begin
                                                    action_reg[i] <= (i == 7) ? 'd5 : action_reg[i+1];
                                                end
                                            end
                                        end
                                        255: begin
                                            if (counter == 'd512) begin
                                                if (action_reg[1] == NEGATIVE) begin
                                                    action_reg[i] <= (i == 6 || i == 7) ? 'd5 : action_reg[i+2];
                                                end else begin
                                                    action_reg[i] <= (i == 7) ? 'd5 : action_reg[i+1];
                                                end
                                            end
                                        end
                                    endcase
                                end
                            endcase
                        end
                    end
                end
            end
        end
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        flip_flag <= 1'b0;
    end else begin
        if (currunt_state == IDLE) begin
            flip_flag <= 1'b0;
        end else begin
            if (in_valid2) begin
                flip_flag <= (action == FLIP) ? ~flip_flag : flip_flag;
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        neg_flag <= 1'b0;
    end else begin
        case (currunt_state) 
            IDLE, INPUT: neg_flag <= 1'b0;
            CALC, OUTPUT: begin                       
                case (calc_cs)
                    MAX_GRAYSCALE, AVERAGE, WEIGHTED: begin
                        if (counter == array_len + 'd2) begin
                            neg_flag <= (action_reg[1] == NEGATIVE) ? 'b1 : 'b0;
                        end
                    end
                    MAXPOOLING: begin
                        case (array_len)
                            63: begin
                                if (counter == 'd80) begin
                                    neg_flag <= (action_reg[1] == NEGATIVE) ? 'b1 : 'b0;
                                end
                            end
                            255: begin
                                if (counter == 'd320) begin
                                    neg_flag <= (action_reg[1] == NEGATIVE) ? 'b1 : 'b0;
                                end
                            end
                        endcase
                    end
                    FILTER: begin
                        case (array_len)
                            15: begin
                                if (counter == 'd32) begin
                                    neg_flag <= (action_reg[1] == NEGATIVE) ? 'b1 : 'b0;
                                end
                            end
                            63: begin
                                if (counter == 'd128) begin
                                    neg_flag <= (action_reg[1] == NEGATIVE) ? 'b1 : 'b0;
                                end
                            end
                            255: begin
                                if (counter == 'd512) begin
                                    neg_flag <= (action_reg[1] == NEGATIVE) ? 'b1 : 'b0;
                                end
                            end
                        endcase
                    end
                    default: neg_flag <= neg_flag;
                endcase
            end
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ptr_clr <= RED;
    end else begin
        if (currunt_state == INPUT) begin
            case (ptr_clr)
                RED: ptr_clr <= GREEN;
                GREEN: ptr_clr <= BLUE;
                BLUE: ptr_clr <= RED;
                default: ptr_clr <= RED;
            endcase
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        counter <= 'd0;
    end else begin
        case (currunt_state)
            IDLE: counter <= 'd0;
            INPUT: begin
                if (ptr_clr == BLUE) begin
                    if (counter == array_len) begin
                        counter <= 'd0;
                    end else begin
                        counter <= counter + 'd1;
                    end
                end
            end
            CALC: begin
                case (calc_cs)
                    CALC_IDLE: counter <= 'd0;
                    MAX_GRAYSCALE, AVERAGE, WEIGHTED: begin
                        if (counter == array_len + 'd2) begin
                            counter <= 'd0;
                        end else begin
                            counter <= counter + 'd1;
                        end
                    end 

                    MAXPOOLING: begin
                        case (array_len)
                            63: counter <= (counter == 'd80) ? 'd0 : counter + 'd1;
                            255: counter <= (counter == 'd320) ? 'd0 : counter + 'd1;
                        endcase
                    end

                    FILTER: begin
                        case (array_len)
                            15: counter <= (counter == 'd32) ? 'd0 : counter + 'd1;
                            63: counter <= (counter == 'd128) ? 'd0 : counter + 'd1;
                            255: counter <= (counter == 'd512) ? 'd0 : counter + 'd1;
                        endcase
                    end
                endcase
            end
            OUTPUT: begin
                if (out_valid) begin
                    counter <= (counter == 'd19) ? 'd0 : counter + 'd1;
                end else begin
                    counter <= (counter == 'd7) ? 'd0 : counter + 'd1;
                end
            end
        endcase
    end
end


// Logic of wrting / reading data into R_memory
assign Img_input_R_OE = (currunt_state == INPUT || (currunt_state == CALC && (calc_cs == MAX_GRAYSCALE || calc_cs == AVERAGE || calc_cs == WEIGHTED))) ? 1'b1 : 1'b0;
assign Img_input_R_CS = (currunt_state == INPUT || (currunt_state == CALC && (calc_cs == MAX_GRAYSCALE || calc_cs == AVERAGE || calc_cs == WEIGHTED))) ? 1'b1 : 1'b0;
assign Img_input_R_WEB = (Img_input_R_OE && Img_input_R_CS) ? 
                         (currunt_state == INPUT && ptr_clr == RED) ? 1'b0 : 1'b1 : 1'bx;            // pull low when inputing (writing)

// Logic of wrting / reading data into G_memory
assign Img_input_G_OE = (currunt_state == INPUT || (currunt_state == CALC && (calc_cs == MAX_GRAYSCALE || calc_cs == AVERAGE || calc_cs == WEIGHTED))) ? 1'b1 : 1'b0;
assign Img_input_G_CS = (currunt_state == INPUT || (currunt_state == CALC && (calc_cs == MAX_GRAYSCALE || calc_cs == AVERAGE || calc_cs == WEIGHTED))) ? 1'b1 : 1'b0;
assign Img_input_G_WEB = (Img_input_G_OE && Img_input_G_CS) ? 
                         (currunt_state == INPUT && ptr_clr == GREEN) ? 1'b0 : 1'b1 : 1'bx;              // pull low when inputing (writing)

// Logic of wrting / reading data into B_memory
assign Img_input_B_OE = (currunt_state == INPUT || (currunt_state == CALC && (calc_cs == MAX_GRAYSCALE || calc_cs == AVERAGE || calc_cs == WEIGHTED))) ? 1'b1 : 1'b0;
assign Img_input_B_CS = (currunt_state == INPUT || (currunt_state == CALC && (calc_cs == MAX_GRAYSCALE || calc_cs == AVERAGE || calc_cs == WEIGHTED))) ? 1'b1 : 1'b0;
assign Img_input_B_WEB = (Img_input_B_OE && Img_input_B_CS) ? 
                         (currunt_state == INPUT && ptr_clr == BLUE) ? 1'b0 : 1'b1 : 1'bx;             // pull low when inputing (writing)
// What to input to R_memory
assign Img_input_R_A = counter;
assign Img_input_R_DI = !Img_input_R_WEB ? Img_temp : 8'bx;

// What to input to G_memory
assign Img_input_G_A = counter;
assign Img_input_G_DI = !Img_input_G_WEB ? Img_temp : 8'bx;

// What to input to B_memory
assign Img_input_B_A = counter;
assign Img_input_B_DI = !Img_input_B_WEB ? Img_temp : 8'bx;

always @(*) begin
    case (currunt_state)
        IDLE, INPUT: temp1_CS = 'b0;
        CALC: begin
            case (calc_cs)
                CALC_IDLE: temp1_CS = 'b0;
                MAX_GRAYSCALE, AVERAGE, WEIGHTED: temp1_CS = (counter > 'd1) ? 'b1 : 'b0;
                default: temp1_CS = 'b1;
            endcase
        end
        OUTPUT: begin
            if (flip_flag) begin
                case (array_len)
                    15: temp1_CS = (conv_ptr == 'd19) ? 'b0 : 'b1;
                    63: temp1_CS = (conv_ptr == 'd71) ? 'b0 : 'b1;
                    255: temp1_CS = (out_valid && conv_ptr == 'd15) ? 'b0 : 'b1;
                    default: temp1_CS = 'bx;
                endcase
            end else begin
                case (array_len)
                    15: temp1_CS = (conv_ptr == 'd16) ? 'b0 : 'b1;
                    63: temp1_CS = (conv_ptr == 'd64) ? 'b0 : 'b1;
                    255: temp1_CS = (out_valid && conv_ptr == 'd0) ? 'b0 : 'b1;
                    default: temp1_CS = 'bx;
                endcase
            end
        end
        default: temp1_CS = 'bx;
    endcase
end


always @(*) begin
    case (currunt_state)
        IDLE, INPUT: temp1_OE = 'b0;
        CALC: begin
            case (calc_cs)
                MAX_GRAYSCALE, AVERAGE, WEIGHTED: temp1_OE = (counter > 'd2) ? 'b1 : 'b0;
                MAXPOOLING: begin
                    case (array_len)
                        63: temp1_OE = (counter == 'd80) ? 1'b0 : 'b1;
                        255: temp1_OE = (counter == 'd320) ? 1'b0 : 'b1;
                        default: temp1_OE = 'b0;
                    endcase
                end
                FILTER: begin
                    case (array_len)
                        15: temp1_OE = (counter == 'd0) ? 'b0 : 'b1;
                        63: temp1_OE = (counter == 'd0) ? 'b0 : 'b1;
                        255: temp1_OE = (counter == 'd0) ? 'b0 : 'b1;
                        default: temp1_OE = 'b0;
                    endcase
                end
                default: temp1_OE = 'b0;
            endcase
        end
        OUTPUT: temp1_OE = 'b1;
        default: temp1_OE = 'bx;
    endcase
end

always @(*) begin
    case (currunt_state)
        IDLE, INPUT: temp1_WEB = 'bx;
        CALC: begin
            case (calc_cs)
                MAX_GRAYSCALE, AVERAGE, WEIGHTED: temp1_WEB = 'b0;
                MAXPOOLING: begin
                    if (ctm5 == 'd0 && counter != 'd0) begin
                        temp1_WEB = 'b0;
                    end else begin
                        temp1_WEB = 'b1;
                    end
                end
                FILTER: begin
                    case (array_len)
                        15: begin
                            if (counter < 'd7) begin
                                temp1_WEB = 'b1;
                            end else if (counter > 'd27) begin                                     
                                temp1_WEB = 'b0;
                            end else begin
                                case (^counter[1:0])
                                    0: temp1_WEB = 'b0;
                                    1: temp1_WEB = 'b1;
                                endcase
                            end
                        end
                        63: begin
                            if (counter < 'd11) begin
                                temp1_WEB = 'b1;
                            end else if (counter > 'd118) begin
                                temp1_WEB = 'b0;
                            end else begin
                                case (^counter[1:0])
                                    0: temp1_WEB = 'b0;
                                    1: temp1_WEB = 'b1;
                                endcase
                            end
                        end
                        255: begin
                            if (counter < 'd19) begin
                                temp1_WEB = 'b1;
                            end else if (counter > 'd494) begin                                     
                                temp1_WEB = 'b0;
                            end else begin
                                case (^counter[1:0])
                                    0: temp1_WEB = 'b0;
                                    1: temp1_WEB = 'b1;
                                endcase
                            end
                        end
                        default: temp1_WEB = 'bx;
                    endcase
                end
                default: temp1_WEB = 'bx;
            endcase
        end
        OUTPUT: temp1_WEB = 'b1;
        default: temp1_WEB = 'bx;
    endcase
end


// Store the output from R_memory.
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        Img_input_R_out <= 8'd0;
    end else begin
        Img_input_R_out <= (Img_input_R_OE && Img_input_R_CS && Img_input_R_WEB) ? Img_input_R_DO : Img_input_R_out;
    end 
end

// Store the output from G_memory.
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        Img_input_G_out <= 8'd0;
    end else begin
        Img_input_G_out <= (Img_input_G_OE && Img_input_G_CS && Img_input_G_WEB) ? Img_input_G_DO : Img_input_G_out;
    end 
end

// Store the output from B_memory.
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        Img_input_B_out <= 8'd0;
    end else begin
        Img_input_B_out <= (Img_input_B_OE && Img_input_B_CS && Img_input_B_WEB) ? Img_input_B_DO : Img_input_B_out;
    end 
end

always @(*) begin
    case (currunt_state)
        IDLE, INPUT: temp1_A = 8'bx;
        CALC: begin
            case (calc_cs)
                MAX_GRAYSCALE, AVERAGE, WEIGHTED: temp1_A = (counter > 'd1) ? counter - 'd2 : 'bx;
                MAXPOOLING: begin
                    if (ctm5 == 'd0 && counter != 'd0) begin
                        temp1_A = counter / 'd5 - 'd1;
                    end else begin
                        if (mp_flip) begin
                            case (array_len)
                                63: temp1_A = mp_ptr + 'd8;
                                255: temp1_A = mp_ptr + 'd16;
                                default: temp1_A = 'd0;
                            endcase
                        end else begin
                            temp1_A = mp_ptr;
                        end
                    end
                end
                FILTER: begin
                    case (array_len)
                        15: begin
                            if (counter < 'd7) begin
                                temp1_A = filter_r;
                            end else if (counter > 'd27) begin                                     
                                temp1_A = filter_w;
                            end else begin
                                case (^counter[1:0])
                                    0: temp1_A = filter_w;
                                    1: temp1_A = filter_r;
                                endcase
                            end
                        end
                        63: begin
                            if (counter < 'd11) begin
                                temp1_A = filter_r;
                            end else if (counter > 'd118) begin                                     
                                temp1_A = filter_w;
                            end else begin
                                case (^counter[1:0])
                                    0: temp1_A = filter_w;
                                    1: temp1_A = filter_r;
                                endcase
                            end
                        end
                        255: begin
                            if (counter < 'd19) begin
                                temp1_A = filter_r;
                            end else if (counter > 'd494) begin                                     
                                temp1_A = filter_w;
                            end else begin
                                case (^counter[1:0])
                                    0: temp1_A = filter_w;
                                    1: temp1_A = filter_r;
                                endcase
                            end
                        end
                        default: temp1_A = 'd0;
                    endcase
                end
                default: temp1_A = 'd0;
            endcase
        end
        OUTPUT: begin
            case (array_len)
                15: begin
                    if (~out_valid) begin
                        if (flip_flag) begin
                            case (counter)
                                'd0: temp1_A = 'd3;
                                'd1: temp1_A = 'd2;
                                'd2: temp1_A = 'd7;
                                'd3: temp1_A = 'd6;
                                default: temp1_A = 'd0;
                            endcase
                        end else begin
                            case (counter)
                                'd0: temp1_A = 'd0;
                                'd1: temp1_A = 'd1;
                                'd2: temp1_A = 'd4;
                                'd3: temp1_A = 'd5;
                                default: temp1_A = 'd0;
                            endcase
                        end
                    end else begin
                        case (counter)
                            'd0: begin
                                if (conv_ptr[1:0] == 'd0 || conv_ptr[7:2] == 'd0) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr - 'd5;
                                end
                            end
                            'd1: begin
                                if (conv_ptr[7:2] == 'd0) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr - 'd4;
                                end
                            end
                            'd2: begin
                                if (conv_ptr[1:0] == 'd3 || conv_ptr[7:2] == 'd0) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr - 'd3;
                                end
                            end
                            'd3: begin
                                if (conv_ptr[1:0] == 'd0) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr - 'd1;
                                end
                            end
                            'd4: temp1_A = conv_ptr;
                            'd5: begin
                                if (conv_ptr[1:0] == 'd3) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr + 'd1;
                                end
                            end
                            'd6: begin
                                if (conv_ptr[1:0] == 'd0 || conv_ptr[7:2] == 'd3) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr + 'd3;
                                end
                            end
                            'd7: begin
                                if (conv_ptr[7:2] == 'd3) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr + 'd4;
                                end
                            end
                            'd8: begin
                                if (conv_ptr[1:0] == 'd3 || conv_ptr[7:2] == 'd3) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr + 'd5;
                                end
                            end
                            default: temp1_A = 'd0;
                        endcase
                    end
                end
                63: begin
                    if (~out_valid) begin
                        if (flip_flag) begin
                            case (counter)
                                'd0: temp1_A = 'd7;
                                'd1: temp1_A = 'd6;
                                'd2: temp1_A = 'd15;
                                'd3: temp1_A = 'd14;
                                default: temp1_A = 'd0;
                            endcase
                        end else begin
                            case (counter)
                                'd0: temp1_A = 'd0;
                                'd1: temp1_A = 'd1;
                                'd2: temp1_A = 'd8;
                                'd3: temp1_A = 'd9;
                                default: temp1_A = 'd0;
                            endcase
                        end
                    end else begin
                        case (counter)
                            'd0: begin
                                if (conv_ptr[2:0] == 'd0 || conv_ptr[7:3] == 'd0) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr - 'd9;
                                end
                            end
                            'd1: begin
                                if (conv_ptr[7:3] == 'd0) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr - 'd8;
                                end
                            end
                            'd2: begin
                                if (conv_ptr[2:0] == 'd7 || conv_ptr[7:3] == 'd0) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr - 'd7;
                                end
                            end
                            'd3: begin
                                if (conv_ptr[2:0] == 'd0) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr - 'd1;
                                end
                            end
                            'd4: temp1_A = conv_ptr;
                            'd5: begin
                                if (conv_ptr[2:0] == 'd7) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr + 'd1;
                                end
                            end
                            'd6: begin
                                if (conv_ptr[2:0] == 'd0 || conv_ptr[7:3] == 'd7) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr + 'd7;
                                end
                            end
                            'd7: begin
                                if (conv_ptr[7:3] == 'd7) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr + 'd8;
                                end
                            end
                            'd8: begin
                                if (conv_ptr[2:0] == 'd7 || conv_ptr[7:3] == 'd7) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr + 'd9;
                                end
                            end
                            default: temp1_A = 'd0;
                        endcase
                    end
                end
                255: begin
                    if (~out_valid) begin
                        if (flip_flag) begin
                            case (counter)
                                'd0: temp1_A = 'd15;
                                'd1: temp1_A = 'd14;
                                'd2: temp1_A = 'd31;
                                'd3: temp1_A = 'd30;
                                default: temp1_A = 'd0;
                            endcase
                        end else begin
                            case (counter)
                                'd0: temp1_A = 'd0;
                                'd1: temp1_A = 'd1;
                                'd2: temp1_A = 'd16;
                                'd3: temp1_A = 'd17;
                                default: temp1_A = 'd0;
                            endcase
                        end
                    end else begin
                        case (counter)
                            'd0: begin
                                if (conv_ptr[3:0] == 'd0 || conv_ptr[7:4] == 'd0) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr - 'd17;
                                end
                            end
                            'd1: begin
                                if (conv_ptr[7:4] == 'd0) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr - 'd16;
                                end
                            end
                            'd2: begin
                                if (conv_ptr[3:0] == 'd15 || conv_ptr[7:4] == 'd0) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr - 'd15;
                                end
                            end
                            'd3: begin
                                if (conv_ptr[3:0] == 'd0) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr - 'd1;
                                end
                            end
                            'd4: temp1_A = conv_ptr;
                            'd5: begin
                                if (conv_ptr[3:0] == 'd15) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr + 'd1;
                                end
                            end
                            'd6: begin
                                if (conv_ptr[3:0] == 'd0 || conv_ptr[7:4] == 'd15) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr + 'd15;
                                end
                            end
                            'd7: begin
                                if (conv_ptr[7:4] == 'd15) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr + 'd16;
                                end
                            end
                            'd8: begin
                                if (conv_ptr[3:0] == 'd15 || conv_ptr[7:4] == 'd15) begin
                                    temp1_A = 'd0;
                                end else begin
                                    temp1_A = conv_ptr + 'd17;
                                end
                            end
                            default: temp1_A = 'd0;
                        endcase
                    end
                end
                default: temp1_A = 'd0;
            endcase
        end
        default: temp1_A = 'd0;
    endcase
end

always @(*) begin
    case (currunt_state)
        IDLE, INPUT, OUTPUT: temp1_DI = 8'bx;
        CALC: begin
            case (calc_cs)
                MAX_GRAYSCALE: temp1_DI = (counter > 'd1) ? max_g_result : 'bx;
                AVERAGE: temp1_DI = (counter > 'd1) ? avg : 'bx;
                WEIGHTED: temp1_DI = (counter > 'd1) ? weighted_result : 'bx;
                MAXPOOLING: begin
                    if (ctm5 == 'd0 && counter != 'd0) begin
                        temp1_DI = max;
                    end else begin
                        temp1_DI = 'bx;
                    end
                end
                FILTER: begin
                    case (array_len)
                        15: begin
                            if (counter > 'd27) begin                                     
                                temp1_DI = median;
                            end else begin
                                if (^counter[1:0] == 'b0) begin
                                    temp1_DI = median;
                                end else begin
                                    temp1_DI = 'bx;
                                end
                            end
                        end
                        63: begin
                            if (counter > 'd118) begin                                     
                                temp1_DI = median;
                            end else begin
                                if (^counter[1:0] == 'b0) begin
                                    temp1_DI = median;
                                end else begin
                                    temp1_DI = 'bx;
                                end
                            end
                        end
                        255: begin
                            if (counter > 'd494) begin                                     
                                temp1_DI = median;
                            end else begin
                                if (^counter[1:0] == 'b0) begin
                                    temp1_DI = median;
                                end else begin
                                    temp1_DI = 'bx;
                                end
                            end
                        end
                        default: temp1_DI = 'bx;
                    endcase
                end
                default: temp1_DI = 'bx;
            endcase
        end
        default: temp1_DI = 'bx;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        mp_ptr <= 8'd0;
    end else begin
        if (currunt_state == CALC) begin
            if (calc_cs == MAXPOOLING && temp1_WEB) begin
                case (array_len)
                    63: if (mp_ptr == 'd56) mp_ptr <= 'd0;
                    255: if (mp_ptr == 'd240) mp_ptr <= 'd0;
                endcase

                if (mp_flip == 1'b1) begin
                    case (array_len)
                        63: begin
                            case (mp_ptr)
                                'd7, 'd23, 'd39: mp_ptr <= mp_ptr + 'd9;
                                default: mp_ptr <= mp_ptr + 'd1;
                            endcase
                        end
                        255: begin
                            case (mp_ptr)
                                'd15, 'd47, 'd79, 'd111, 'd143, 'd175, 'd207: mp_ptr <= mp_ptr + 'd17;
                                default: mp_ptr <= mp_ptr + 'd1;
                            endcase
                        end
                    endcase
                end
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        mp_flip <= 1'b0;
    end else begin
        case (currunt_state)
            IDLE, INPUT, OUTPUT: mp_flip <= 'b0;
            CALC: begin
                case (calc_cs)
                    MAXPOOLING: begin
                        case (array_len)
                            63: begin
                                case (counter)
                                    'd5, 'd10, 'd15, 'd20, 'd25, 'd30, 'd35, 'd40, 'd45, 'd50, 'd55, 'd60, 'd65, 'd70, 'd75: mp_flip <= mp_flip;
                                    default: mp_flip <= ~mp_flip;
                                endcase
                            end
                            255: begin
                                case (counter)
                                    'd5, 'd10, 'd15, 'd20, 'd25, 'd30, 'd35, 'd40, 'd45, 'd50, 'd55, 'd60, 'd65, 'd70, 'd75, 'd80, 
                                    'd85, 'd90, 'd95, 'd100, 'd105, 'd110, 'd115, 'd120, 'd125, 'd130, 'd135, 'd140, 'd145, 'd150, 'd155, 'd160, 
                                    'd165, 'd170, 'd175, 'd180, 'd185, 'd190, 'd195, 'd200, 'd205, 'd210, 'd215, 'd220, 'd225, 'd230, 'd235, 'd240, 
                                    'd245, 'd250, 'd255, 'd260, 'd265, 'd270, 'd275, 'd280, 'd285, 'd290, 'd295, 'd300, 'd305, 'd310, 'd315: mp_flip <= mp_flip;

                                    default: mp_flip <= ~mp_flip;
                                endcase
                            end
                        endcase
                    end
                    default: mp_flip <= 'b0;
                endcase
            end
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        max_pooling_1 <= 'd0;
    end else begin
        if (currunt_state == CALC) begin
            if (calc_cs == MAXPOOLING) begin
                if (counter == 'd1) begin
                    max_pooling_1 <= temp1_DO;
                end else if (ctm5 == 'd0 && counter != 'd0) begin
                    max_pooling_1 <= temp1_DO;
                end
            end
        end
    end
end 

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        max_pooling_2 <= 'd0;
    end else begin
        if (currunt_state == CALC) begin
            if (calc_cs == MAXPOOLING) begin
                if (ctm5 == 'd2) begin
                    max_pooling_2 <= temp1_DO;
                end
            end
        end
    end
end 

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        max_pooling_3 <= 'd0;
    end else begin
        if (currunt_state == CALC) begin
            if (calc_cs == MAXPOOLING) begin
                if (ctm5 == 'd3) begin
                    max_pooling_3 <= temp1_DO;
                end
            end
        end
    end
end 

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        max_pooling_4 <= 'd0;
    end else begin
        if (currunt_state == CALC) begin
            if (calc_cs == MAXPOOLING) begin
                if (ctm5 == 'd4) begin
                    max_pooling_4 <= temp1_DO;
                end
            end
        end
    end
end 


genvar j;
generate
    for (i = 0; i < 3; i = i + 1) begin
        for (j = 0 ; j < 16; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if (~rst_n) begin
                    filter_conv_temp[i][j] <= 'd0;
                end else begin
                    case (currunt_state)
                        IDLE, INPUT, OUTPUT: filter_conv_temp[i][j] <= 'd0;
                        CALC: begin
                            case (calc_cs)
                                FILTER: begin
                                    case (array_len)
                                        15: begin
                                            if (counter == 'd0 || (counter > 'd7 && counter < 'd26 && (counter[1:0] == 'b00 || counter[1:0] == 'b01))) begin                                     
                                                filter_conv_temp[i][j] <= filter_conv_temp[i][j];
                                            end else begin
                                                if (j == 3) begin
                                                    if (i == 2) begin
                                                        filter_conv_temp[i][j] <= temp1_DO;
                                                    end else begin
                                                        filter_conv_temp[i][j] <= filter_conv_temp[i+1][0];
                                                    end
                                                end else begin
                                                    filter_conv_temp[i][j] <= filter_conv_temp[i][j+1];
                                                end
                                            end
                                        end
                                        63: begin
                                            if (counter == 'd0 || (counter > 'd11 && counter < 'd118 && (counter[1:0] == 'b00 || counter[1:0] == 'b01))) begin                                     
                                                filter_conv_temp[i][j] <= filter_conv_temp[i][j];
                                            end else begin
                                                if (j == 7) begin
                                                    if (i == 2) begin
                                                        filter_conv_temp[i][j] <= temp1_DO;
                                                    end else begin
                                                        filter_conv_temp[i][j] <= filter_conv_temp[i+1][0];
                                                    end
                                                end else begin
                                                    filter_conv_temp[i][j] <= filter_conv_temp[i][j+1];
                                                end
                                            end
                                        end
                                        255: begin
                                            if (counter == 'd0 || (counter > 'd19 && counter < 'd494 && (counter[1:0] == 'b00 || counter[1:0] == 'b01))) begin                                     
                                                filter_conv_temp[i][j] <= filter_conv_temp[i][j];
                                            end else begin
                                                if (j == 15) begin
                                                    if (i == 2) begin
                                                        filter_conv_temp[i][j] <= temp1_DO;
                                                    end else begin
                                                        filter_conv_temp[i][j] <= filter_conv_temp[i+1][0];
                                                    end
                                                end else begin
                                                    filter_conv_temp[i][j] <= filter_conv_temp[i][j+1];
                                                end
                                            end
                                        end
                                    endcase
                                end
                            endcase
                        end
                    endcase
                end
            end
        end
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        filter_r <= 'd0;
    end else begin
        if (currunt_state == CALC) begin
            if (calc_cs == FILTER) begin
                case (array_len)
                    15: begin
                        if (counter == 'd32) begin
                            filter_r <= 'd0;
                        end else if (counter < 'd6) begin
                            filter_r <= filter_r + 'd1;
                        end else if (filter_r == 'd15) begin
                            filter_r <= filter_r;
                        end else begin
                            case (counter[1])
                                'b1: filter_r <= filter_r;
                                'b0: filter_r <= filter_r + 'd1;
                            endcase
                        end
                    end
                    63: begin
                        if (counter == 'd128) begin
                            filter_r <= 'd0;
                        end else if (counter < 'd10) begin
                            filter_r <= filter_r + 'd1;
                        end else if (filter_r == 'd63) begin
                            filter_r <= filter_r;
                        end else begin
                            case (counter[1])
                                'b0: filter_r <= filter_r + 'd1;
                                'b1: filter_r <= filter_r;
                            endcase
                        end
                    end
                    255: begin
                        if (counter == 'd512) begin
                            filter_r <= 'd0;
                        end else  if (counter < 'd18) begin
                            filter_r <= filter_r + 'd1;
                        end else if (filter_r == 'd255) begin
                            filter_r <= filter_r;
                        end else begin
                            case (counter[1])
                                'b0: filter_r <= filter_r + 'd1;
                                'b1: filter_r <= filter_r;
                            endcase
                        end
                    end
                endcase
            end
        end else begin
            filter_r <= 'd0;
        end
    end
end


always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        filter_w <= 'd0;
    end else begin
        if (currunt_state == CALC) begin
            if (calc_cs == FILTER) begin
                case (array_len)
                    15: begin
                        if (counter < 'd7) begin
                            filter_w <= 'd0;
                        end else if (filter_w > 'd10) begin
                            filter_w <= filter_w + 'd1;
                        end else if (filter_w == 'd15) begin
                            filter_w <= filter_w;
                        end else begin
                            case (counter[1])
                                'b0: filter_w <= filter_w;
                                'b1: filter_w <= filter_w + 'd1;
                            endcase
                        end
                    end
                    63: begin
                        if (counter < 'd11) begin
                            filter_w <= 'd0;
                        end else if (filter_w > 'd54) begin
                            filter_w <= filter_w + 'd1;
                        end else if (filter_w == 'd63) begin
                            filter_w <= filter_w;
                        end else begin
                            case (counter[1])
                                'b0: filter_w <= filter_w;
                                'b1: filter_w <= filter_w + 'd1;
                            endcase
                        end
                    end
                    255: begin
                        if (counter < 'd19) begin
                            filter_w <= 'd0;
                        end else if (filter_w > 'd238) begin
                            filter_w <= filter_w + 'd1;
                        end else if (filter_w == 'd255) begin
                            filter_w <= filter_w;
                        end else begin
                            case (counter[1])
                                'b0: filter_w <= filter_w;
                                'b1: filter_w <= filter_w + 'd1;
                            endcase
                        end
                    end
                endcase
            end
        end else begin
            filter_w <= 'd0;
        end
    end
end

always @(*) begin
    if (currunt_state == CALC) begin
        if (calc_cs == FILTER && ~temp1_WEB) begin
            case (array_len)
                15: begin
                    if (temp1_A[7:2] == 'd0) begin
                        data0 = data3;
                    end else if (temp1_A[1:0] == 'b00) begin
                        data0 = data1;
                    end else begin
                        data0 = filter_conv_temp[0][1];
                    end
                end 
                63: begin
                    if (temp1_A[7:3] == 'd0) begin
                        data0 = data3;
                    end else if (temp1_A[2:0] == 'b000) begin
                        data0 = data1;
                    end else begin
                        data0 = filter_conv_temp[0][5];
                    end
                end
                255: begin
                    if (temp1_A[7:4] == 'd0) begin
                        data0 = data3;
                    end else if (temp1_A[3:0] == 'b0000) begin
                        data0 = data1;
                    end else begin
                        data0 = filter_conv_temp[0][13];
                    end
                end
                default: data0 = 'bx;
            endcase
        end else begin
            data0 = 'bx;
        end
    end else begin
        data0 = 'bx;
    end
end


always @(*) begin
    if (currunt_state == CALC) begin
        if (calc_cs == FILTER && ~temp1_WEB) begin
            case (array_len)
                15: begin
                    if (temp1_A[7:2] == 'b0) begin
                        data1 = data4;
                    end else begin
                        data1 = filter_conv_temp[0][2];
                    end
                end 
                63: begin
                    if (temp1_A[7:3] == 'b0) begin
                        data1 = data4;
                    end else begin
                        data1 = filter_conv_temp[0][6];
                    end
                end
                255: begin
                    if (temp1_A[7:4] == 'b0) begin
                        data1 = data4;
                    end else begin
                        data1 = filter_conv_temp[0][14];
                    end
                end
                default: data1 = 'bx;
            endcase
        end else begin
            data1 = 'bx;
        end
    end else begin
        data1 = 'bx;
    end
end


always @(*) begin
    if (currunt_state == CALC) begin
        if (calc_cs == FILTER && ~temp1_WEB) begin
            case (array_len)
                15: begin
                    if (temp1_A[7:2] == 'd0) begin
                        data2 = data5;
                    end else if (temp1_A[1:0] == 'b11) begin
                        data2 = data1;
                    end else begin
                        data2 = filter_conv_temp[0][3];
                    end
                end 
                63: begin
                    if (temp1_A[7:3] == 'd0) begin
                        data2 = data5;
                    end else if (temp1_A[2:0] == 'b111) begin
                        data2 = data1;
                    end else begin
                        data2 = filter_conv_temp[0][7];
                    end
                end
                255: begin
                    if (temp1_A[7:4] == 'd0) begin
                        data2 = data5;
                    end else if (temp1_A[3:0] == 'b1111) begin
                        data2 = data1;
                    end else begin
                        data2 = filter_conv_temp[0][15];
                    end
                end
                default: data2 = 'bx;
            endcase
        end else begin
            data2 = 'bx;
        end
    end else begin
        data2 = 'bx;
    end
end


always @(*) begin
    if (currunt_state == CALC) begin
        if (calc_cs == FILTER && ~temp1_WEB) begin
            case (array_len)
                15: begin
                    if (temp1_A[1:0] == 'b00) begin
                        data3 = data4;
                    end else begin
                        data3 = filter_conv_temp[1][1];
                    end
                end 
                63: begin
                    if (temp1_A[2:0] == 'b000) begin
                        data3 = data4;
                    end else begin
                        data3 = filter_conv_temp[1][5];
                    end
                end
                255: begin
                    if (temp1_A[3:0] == 'b0000) begin
                        data3 = data4;
                    end else begin
                        data3 = filter_conv_temp[1][13];
                    end
                end
                default: data3 = 'bx;
            endcase
        end else begin
            data3 = 'bx;
        end
    end else begin
        data3 = 'bx;
    end
end


always @(*) begin
    if (currunt_state == CALC) begin
        if (calc_cs == FILTER && ~temp1_WEB) begin
            case (array_len)
                15: data4 = filter_conv_temp[1][2];
                63: data4 = filter_conv_temp[1][6];
                255: data4 = filter_conv_temp[1][14];
                default: data4 = 'bx;
            endcase
        end else begin
            data4 = 'bx;
        end
    end else begin
        data4 = 'bx;
    end
end

always @(*) begin
    if (currunt_state == CALC) begin
        if (calc_cs == FILTER && ~temp1_WEB) begin
            case (array_len)
                15: begin
                    if (temp1_A[1:0] == 'b11) begin
                        data5 = data4;
                    end else begin
                        data5 = filter_conv_temp[1][3];
                    end
                end 
                63: begin
                    if (temp1_A[2:0] == 'b111) begin
                        data5 = data4;
                    end else begin
                        data5 = filter_conv_temp[1][7];
                    end
                end
                255: begin
                    if (temp1_A[3:0] == 'b1111) begin
                        data5 = data4;
                    end else begin
                        data5 = filter_conv_temp[1][15];
                    end
                end
                default: data5 = 'bx;
            endcase
        end else begin
            data5 = 'bx;
        end
    end else begin
        data5 = 'bx;
    end
end


always @(*) begin
    if (currunt_state == CALC) begin
        if (calc_cs == FILTER && ~temp1_WEB) begin
            case (array_len)
                15: begin
                    if (temp1_A[7:2] == 'd3) begin
                        data6 = data3;
                    end else if (temp1_A[1:0] == 'b00) begin
                        data6 = data7;
                    end else begin
                        data6 = filter_conv_temp[2][1];
                    end
                end 
                63: begin
                    if (temp1_A[7:3] == 'd7) begin
                        data6 = data3;
                    end else if (temp1_A[2:0] == 'b000) begin
                        data6 = data7;
                    end else begin
                        data6 = filter_conv_temp[2][5];
                    end
                end
                255: begin
                    if (temp1_A[7:4] == 'd15) begin
                        data6 = data3;
                    end else if (temp1_A[3:0] == 'b000) begin
                        data6 = data7;
                    end else begin
                        data6 = filter_conv_temp[2][13];
                    end
                end
                default: data6 = 'bx;
            endcase
        end else begin
            data6 = 'bx;
        end
    end else begin
        data6 = 'bx;
    end
end

always @(*) begin
    if (currunt_state == CALC) begin
        if (calc_cs == FILTER && ~temp1_WEB) begin
            case (array_len)
                15: begin
                    if (temp1_A[7:2] == 'd3) begin
                        data7 = data4;
                    end else begin
                        data7 = filter_conv_temp[2][2];
                    end
                end 
                63: begin
                    if (temp1_A[7:3] == 'd7) begin
                        data7 = data4;
                    end else begin
                        data7 = filter_conv_temp[2][6];
                    end
                end
                255: begin
                    if (temp1_A[7:4] == 'd15) begin
                        data7 = data4;
                    end else begin
                        data7 = filter_conv_temp[2][14];
                    end
                end
                default: data7 = 'bx;
            endcase
        end else begin
            data7 = 'bx;
        end
    end else begin
        data7 = 'bx;
    end
end

always @(*) begin
    if (currunt_state == CALC) begin
        if (calc_cs == FILTER && ~temp1_WEB) begin
            case (array_len)
                15: begin
                    if (temp1_A[7:2] == 'd3) begin
                        data8 = data5;
                    end else if (temp1_A[1:0] == 'b11) begin
                        data8 = data7;
                    end else begin
                        data8 = filter_conv_temp[2][3];
                    end
                end 
                63: begin
                    if (temp1_A[7:3] == 'd7) begin
                        data8 = data5;
                    end else if (temp1_A[2:0] == 'b111) begin
                        data8 = data7;
                    end else begin
                        data8 = filter_conv_temp[2][7];
                    end
                end
                255: begin
                    if (temp1_A[7:4] == 'd15) begin
                        data8 = data5;
                    end else if (temp1_A[3:0] == 'b1111) begin
                        data8 = data7;
                    end else begin
                        data8 = filter_conv_temp[2][15];
                    end
                end
                default: data8 = 'bx;
            endcase
        end else begin
            data8 = 'bx;
        end
    end else begin
        data8 = 'bx;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        conv_ptr <= 'd0;
    end else begin
        case (currunt_state)
            IDLE, INPUT, CALC: conv_ptr <= 'd0;
            OUTPUT: begin
                if (out_valid) begin
                    if (counter == 'd19) begin
                        if (flip_flag) begin
                            case (array_len)
                                15: conv_ptr <= (conv_ptr[1:0] == 'd0) ? conv_ptr + 'd7 : conv_ptr - 'd1;
                                63: conv_ptr <= (conv_ptr[2:0] == 'd0) ? conv_ptr + 'd15 : conv_ptr - 'd1;
                                255: begin
                                    if (conv_ptr == 'd240) begin
                                        conv_ptr <= 'd15;
                                    end else begin
                                        conv_ptr <= (conv_ptr[3:0] == 'd0) ? conv_ptr + 'd31 : conv_ptr - 'd1;
                                    end
                                end
                            endcase
                        end else begin
                            conv_ptr <= conv_ptr + 'd1;
                        end
                    end else begin
                        conv_ptr <= conv_ptr;
                    end
                end else begin
                    if (counter == 'd7) begin
                        if (flip_flag) begin
                            case (array_len)
                                15: conv_ptr <= 'd2;
                                63: conv_ptr <= 'd6;
                                255: conv_ptr <= 'd14;
                            endcase
                        end else begin
                            conv_ptr <= 'd1;
                        end
                    end
                end
            end
        endcase
    end
end

always @(*) begin
    if (currunt_state == OUTPUT) begin
        case (array_len)
            15: begin
                if (~out_valid) begin
                    case (counter)
                        'd1, 'd2, 'd3, 'd4: element = temp1_DO;
                        default: element = 'd0;
                    endcase
                end else begin
                    case (counter)
                        'd1: begin
                            if (conv_ptr[1:0] == 'd0 || conv_ptr[7:2] == 'd0) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        'd2: begin
                            if (conv_ptr[7:2] == 'd0) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        'd3: begin
                            if (conv_ptr[1:0] == 'd3 || conv_ptr[7:2] == 'd0) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        'd4: begin
                            if (conv_ptr[1:0] == 'd0) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        'd5: element = temp1_DO;
                        'd6: begin
                            if (conv_ptr[1:0] == 'd3) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        'd7: begin
                            if (conv_ptr[1:0] == 'd0 || conv_ptr[7:2] == 'd3) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        'd8: begin
                            if (conv_ptr[7:2] == 'd3) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        'd9: begin
                            if (conv_ptr[1:0] == 'd3 || conv_ptr[7:2] == 'd3) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        default: element = 'bx;
                    endcase
                end
            end
            63: begin
                if (~out_valid) begin
                    case (counter)
                        'd1, 'd2, 'd3, 'd4: element = temp1_DO;
                        default: element = 'd0;
                    endcase
                end else begin
                    case (counter)
                        'd1: begin
                            if (conv_ptr[2:0] == 'd0 || conv_ptr[7:3] == 'd0) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        'd2: begin
                            if (conv_ptr[7:3] == 'd0) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        'd3: begin
                            if (conv_ptr[2:0] == 'd7 || conv_ptr[7:3] == 'd0) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        'd4: begin
                            if (conv_ptr[2:0] == 'd0) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        'd5: element = temp1_DO;
                        'd6: begin
                            if (conv_ptr[2:0] == 'd7) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        'd7: begin
                            if (conv_ptr[2:0] == 'd0 || conv_ptr[7:3] == 'd7) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        'd8: begin
                            if (conv_ptr[7:3] == 'd7) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        'd9: begin
                            if (conv_ptr[2:0] == 'd7 || conv_ptr[7:3] == 'd7) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        default: element = 'bx;
                    endcase
                end
            end
            255: begin
                if (~out_valid) begin
                    case (counter)
                        'd1, 'd2, 'd3, 'd4: element = temp1_DO;
                        default: element = 'd0;
                    endcase
                end else begin
                    case (counter)
                        'd1: begin
                            if (conv_ptr[3:0] == 'd0 || conv_ptr[7:4] == 'd0) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        'd2: begin
                            if (conv_ptr[7:4] == 'd0) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        'd3: begin
                            if (conv_ptr[3:0] == 'd15 || conv_ptr[7:4] == 'd0) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        'd4: begin
                            if (conv_ptr[3:0] == 'd0) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        'd5: element = temp1_DO;
                        'd6: begin
                            if (conv_ptr[3:0] == 'd15) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        'd7: begin
                            if (conv_ptr[3:0] == 'd0 || conv_ptr[7:4] == 'd15) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        'd8: begin
                            if (conv_ptr[7:4] == 'd15) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        'd9: begin
                            if (conv_ptr[3:0] == 'd15 || conv_ptr[7:4] == 'd15) begin
                                element = (neg_flag) ? 'd255 : 'd0;
                            end else begin
                                element = temp1_DO;
                            end
                        end
                        default: element = 'bx;
                    endcase
                end
            end
            default: element = 'bx;
        endcase
    end else begin
        element = 'bx;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_temp <= 'd0;
    end else begin
        if (currunt_state == OUTPUT) begin
            if((~out_valid && counter == 'd7) || counter == 'd19) begin
                out_temp <= out;
            end
        end
    end
end

always @(*) begin
    if (out_valid) begin
        out_value = out_temp['d19 - counter];
    end else begin
        out_value = 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid <= 'b0;
    end else begin
        if (currunt_state == OUTPUT) begin
            case (out_valid)
                'b0: out_valid <= (conv_ptr == 'd0 && counter == 'd7) ? 'b1 : 'b0;
                'b1: begin
                    if (flip_flag) begin
                        case (array_len)
                            15: out_valid <= (conv_ptr == 'd19 && counter == 'd19) ? 'b0 : 'b1;
                            63: out_valid <= (conv_ptr == 'd71 && counter == 'd19) ? 'b0 : 'b1;
                            255: out_valid <= (conv_ptr == 'd15 && counter == 'd19) ? 'b0 : 'b1;
                        endcase
                    end else begin
                        case (array_len)
                            15: out_valid <= (conv_ptr == 'd16 && counter == 'd19) ? 'b0 : 'b1;
                            63: out_valid <= (conv_ptr == 'd64 && counter == 'd19) ? 'b0 : 'b1;
                            255: out_valid <= (conv_ptr == 'd0 && counter == 'd19) ? 'b0 : 'b1;
                        endcase
                    end
                end
            endcase
        end
    end
end 
  
endmodule

module max_method (
    input  [7:0] num1,  
    input  [7:0] num2,  
    input  [7:0] num3,  
    output reg [7:0] out 
);

always @(*) begin
    out = num1;

    if (num2 > out) begin
        out = num2;
    end

    if (num3 > out) begin
        out = num3;
    end
end

endmodule

module weighted (
    input  [7:0] num1,  
    input  [7:0] num2,  
    input  [7:0] num3,  
    output [7:0] out 
);

wire [5:0] r_shift, b_shift;
wire [6:0] g_shift;

assign r_shift = num1 >> 2;
assign g_shift = num2 >> 1;
assign b_shift = num3 >> 2;

assign out = (r_shift + b_shift) + g_shift;

endmodule


module average_3numbers (
    input  [7:0] num1,  
    input  [7:0] num2,  
    input  [7:0] num3,  
    output [7:0] avg    
);
    reg [9:0] sum;      
    reg [7:0] result;   

    always @(*) begin
        sum = num1 + num2 + num3;      
        result = sum / 3;       
    end

    assign avg = result;  
endmodule

module max_pooling (
    input [7:0] num1,
    input [7:0] num2,
    input [7:0] num3,
    input [7:0] num4,
    input neg,
    output [7:0] max
);

    reg [7:0] result;
    wire [7:0] temp_max1, temp_max2, temp_min1, temp_min2;

    assign temp_max1 = (num1 > num2) ? num1 : num2;
    assign temp_max2 = (num3 > num4) ? num3 : num4;
    assign temp_min1 = (num1 < num2) ? num1 : num2;
    assign temp_min2 = (num3 < num4) ? num3 : num4;

    always @(*) begin
        if (!neg) begin
            result = (temp_max1 > temp_max2) ? temp_max1 : temp_max2;
        end else begin
            result = (temp_min1 < temp_min2) ? temp_min1 : temp_min2;
        end
    end

    assign max = neg ? (8'd255 - result) : result;

endmodule

module median_quickselect (
    input [7:0] data0,  
    input [7:0] data1,
    input [7:0] data2,
    input [7:0] data3,
    input [7:0] data4,
    input [7:0] data5,
    input [7:0] data6,
    input [7:0] data7,
    input [7:0] data8,
    input neg_flag,
    output [7:0] median    
);

    reg [7:0] layer1 [0:8];
    reg [7:0] layer2 [0:8];
    reg [7:0] layer3 [0:8];
    reg [7:0] layer4 [0:8];
    reg [7:0] layer5 [0:8];
    reg [7:0] layer6 [0:8];
    reg [7:0] layer7 [0:8];

    always @(*) begin
        layer1[0] = (data0 < data3) ? data0 : data3;
        layer1[3] = (data0 < data3) ? data3 : data0;
        layer1[1] = (data1 < data7) ? data1 : data7;
        layer1[7] = (data1 < data7) ? data7 : data1;
        layer1[2] = (data2 < data5) ? data2 : data5;
        layer1[5] = (data2 < data5) ? data5 : data2;
        layer1[4] = (data4 < data8) ? data4 : data8;
        layer1[8] = (data4 < data8) ? data8 : data4;
        layer1[6] = data6;

        layer2[0] = (layer1[0] < layer1[7]) ? layer1[0] : layer1[7];
        layer2[7] = (layer1[0] < layer1[7]) ? layer1[7] : layer1[0];
        layer2[2] = (layer1[2] < layer1[4]) ? layer1[2] : layer1[4];
        layer2[4] = (layer1[2] < layer1[4]) ? layer1[4] : layer1[2];
        layer2[3] = (layer1[3] < layer1[8]) ? layer1[3] : layer1[8];
        layer2[8] = (layer1[3] < layer1[8]) ? layer1[8] : layer1[3];
        layer2[5] = (layer1[5] < layer1[6]) ? layer1[5] : layer1[6];
        layer2[6] = (layer1[5] < layer1[6]) ? layer1[6] : layer1[5];
        layer2[1] = layer1[1];

        layer3[0] = (layer2[0] < layer2[2]) ? layer2[0] : layer2[2];
        layer3[2] = (layer2[0] < layer2[2]) ? layer2[2] : layer2[0];
        layer3[1] = (layer2[1] < layer2[3]) ? layer2[1] : layer2[3];
        layer3[3] = (layer2[1] < layer2[3]) ? layer2[3] : layer2[1];
        layer3[4] = (layer2[4] < layer2[5]) ? layer2[4] : layer2[5];
        layer3[5] = (layer2[4] < layer2[5]) ? layer2[5] : layer2[4];
        layer3[7] = (layer2[7] < layer2[8]) ? layer2[7] : layer2[8];
        layer3[8] = (layer2[7] < layer2[8]) ? layer2[8] : layer2[7];
        layer3[6] = layer2[6];

        layer4[1] = (layer3[1] < layer3[4]) ? layer3[1] : layer3[4];
        layer4[4] = (layer3[1] < layer3[4]) ? layer3[4] : layer3[1];
        layer4[3] = (layer3[3] < layer3[6]) ? layer3[3] : layer3[6];
        layer4[6] = (layer3[3] < layer3[6]) ? layer3[6] : layer3[3];
        layer4[5] = (layer3[5] < layer3[7]) ? layer3[5] : layer3[7];
        layer4[7] = (layer3[5] < layer3[7]) ? layer3[7] : layer3[5];
        layer4[0] = layer3[0];
        layer4[2] = layer3[2];
        layer4[8] = layer3[8];

        layer5[0] = (layer4[0] < layer4[1]) ? layer4[0] : layer4[1];
        layer5[1] = (layer4[0] < layer4[1]) ? layer4[1] : layer4[0];
        layer5[2] = (layer4[2] < layer4[4]) ? layer4[2] : layer4[4];
        layer5[4] = (layer4[2] < layer4[4]) ? layer4[4] : layer4[2];
        layer5[3] = (layer4[3] < layer4[5]) ? layer4[3] : layer4[5];
        layer5[5] = (layer4[3] < layer4[5]) ? layer4[5] : layer4[3];
        layer5[6] = (layer4[6] < layer4[8]) ? layer4[6] : layer4[8];
        layer5[8] = (layer4[6] < layer4[8]) ? layer4[8] : layer4[6];
        layer5[7] = layer4[7];

        layer6[2] = (layer5[2] < layer5[3]) ? layer5[2] : layer5[3];
        layer6[3] = (layer5[2] < layer5[3]) ? layer5[3] : layer5[2];
        layer6[4] = (layer5[4] < layer5[5]) ? layer5[4] : layer5[5];
        layer6[5] = (layer5[4] < layer5[5]) ? layer5[5] : layer5[4];
        layer6[6] = (layer5[6] < layer5[7]) ? layer5[6] : layer5[7];
        layer6[7] = (layer5[6] < layer5[7]) ? layer5[7] : layer5[6];
        layer6[0] = layer5[0];
        layer6[1] = layer5[1];
        layer6[8] = layer5[8];

        layer7[1] = (layer6[1] < layer6[2]) ? layer6[1] : layer6[2];
        layer7[2] = (layer6[1] < layer6[2]) ? layer6[2] : layer6[1];
        layer7[3] = (layer6[3] < layer6[4]) ? layer6[3] : layer6[4];
        layer7[4] = (layer6[3] < layer6[4]) ? layer6[4] : layer6[3];
        layer7[5] = (layer6[5] < layer6[6]) ? layer6[5] : layer6[6];
        layer7[6] = (layer6[5] < layer6[6]) ? layer6[6] : layer6[5];
        layer7[0] = layer6[0];
        layer7[7] = layer6[7];
        layer7[8] = layer6[8];
    end

    assign median = (neg_flag) ? (8'd255 - layer7[4]) : layer7[4];
endmodule


module Convolutioner (
    input [7:0] template,
    input [9:0] counter,
    input clk,
    input rst_n,
    input in_valid,
    input neg_flag,
    input flip_flag,
    input [1:0] ptr_clr,
    input [7:0] element,
    input out_valid,
    input [1:0] currunt_state,
    output reg [19:0] out
);

reg [7:0] template_reg [0:2][0:2];
reg [7:0] element_reg;
reg [19:0] sum;
reg [15:0] mul_result;

genvar i, j;
generate
    for (i = 0; i < 3; i = i + 1) begin: template_loop_i
        for (j = 0; j < 3; j = j + 1) begin: template_loop_j
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    template_reg[i][j] <= 8'd0;
                end else begin
                    if (in_valid) begin
                        if (counter < 10'd3) begin
                            if (counter == 'd2 && ptr_clr == 'd2) begin
                                template_reg[i][j] <= template_reg[i][j];
                            end else begin
                                if (j == 2) begin
                                    if (i == 2) begin
                                        template_reg[i][j] <= template;
                                    end else begin
                                        template_reg[i][j] <= template_reg[i+1][0];
                                    end
                                end else begin
                                    template_reg[i][j] <= template_reg[i][j+1];
                                end
                            end
                        end
                    end else if (currunt_state == 'd3 && out_valid) begin
                        if (counter > 'd1 && counter < 'd11) begin
                            if (flip_flag) begin
                                if (j == 0) begin
                                    if (i == 2) begin
                                        template_reg[i][j] <= template_reg[0][2];
                                    end else begin
                                        template_reg[i][j] <= template_reg[i+1][2];
                                    end
                                end else begin
                                    template_reg[i][j] <= template_reg[i][j-1];
                                end
                            end else begin
                                if (j == 2) begin
                                    if (i == 2) begin
                                        template_reg[i][j] <= template_reg[0][0];
                                    end else begin
                                        template_reg[i][j] <= template_reg[i+1][0];
                                    end
                                end else begin
                                    template_reg[i][j] <= template_reg[i][j+1];
                                end
                            end
                        end
                    end
                end
            end
        end
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        element_reg <= 'd0;
    end else begin
        if (neg_flag) begin
            element_reg <= 'd255 - element;
        end else begin
            element_reg <= element;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mul_result <= 'd0;
    end else begin
        if (currunt_state == 'd3) begin
            if (~out_valid) begin
                case (counter)
                    'd2: mul_result <= multiple(element_reg, template_reg[1][1]);
                    'd3: mul_result <= multiple(element_reg, template_reg[1][2]);
                    'd4: mul_result <= multiple(element_reg, template_reg[2][1]);
                    'd5: mul_result <= multiple(element_reg, template_reg[2][2]);
                    default: mul_result <= 'd0;
                endcase
            end else begin
                case (counter)
                    'd2, 'd3, 'd4, 'd5, 'd6, 'd7, 'd8, 'd9, 'd10: mul_result <= (flip_flag) ? multiple(element_reg, template_reg[0][2]) : multiple(element_reg, template_reg[0][0]);
                    default: mul_result <= 'd0;
                endcase
            end
        end else begin
            mul_result <= 'd0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sum <= 'd0;
    end else begin
        if (currunt_state == 'd3) begin
            if (~out_valid) begin
                case (counter)
                    'd3, 'd4, 'd5, 'd6: sum <= add(mul_result, sum);
                    default: sum <= 'd0;
                endcase
            end else begin
                case (counter)
                    'd0, 'd1, 'd2: sum <= 'd0;
                    'd3, 'd4, 'd5, 'd6, 'd7, 'd8, 'd9, 'd10, 'd11: sum <= add(mul_result, sum);
                    'd12, 'd13, 'd14, 'd15, 'd16, 'd17, 'd18, 'd19: sum <= sum;
                    default: sum <= 'd0;
                endcase
            end
        end else begin
            sum <= 'd0;
        end
    end
end

always @(*) begin
    if (~out_valid) begin
        out = (counter == 'd7) ? sum : 'd0;
    end else begin
        out = (counter == 'd19) ? sum : 'd0;
    end
end


function [15:0] multiple;
    input [7:0] a;
    input [7:0] b;

    begin
        multiple = a * b;
    end    
endfunction

function [19:0] add;
    input [19:0] a;
    input [19:0] b;

    begin
        add = a + b;
    end    
endfunction

endmodule

