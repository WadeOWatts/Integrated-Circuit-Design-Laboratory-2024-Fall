module ISP(
    // Input Signals
    input clk,
    input rst_n,
    input in_valid,
    input [3:0] in_pic_no,
    input       in_mode,
    input [1:0] in_ratio_mode,

    // Output Signals
    output reg out_valid,
    output reg [7:0] out_data,
    
    // DRAM Signals
    // axi write address channel
    // src master
    output [3:0]  awid_s_inf,
    output [31:0] awaddr_s_inf,
    output [2:0]  awsize_s_inf,
    output [1:0]  awburst_s_inf,
    output [7:0]  awlen_s_inf,
    output reg    awvalid_s_inf,
    // src slave
    input         awready_s_inf,
    // -----------------------------
  
    // axi write data channel 
    // src master
    output [127:0] wdata_s_inf,
    output reg     wlast_s_inf,
    output reg     wvalid_s_inf,
    // src slave
    input          wready_s_inf,
  
    // axi write response channel 
    // src slave
    input [3:0]    bid_s_inf,
    input [1:0]    bresp_s_inf,
    input          bvalid_s_inf,
    // src master 
    output         bready_s_inf,
    // -----------------------------
  
    // axi read address channel 
    // src master
    output [3:0]   arid_s_inf,
    output [31:0]  araddr_s_inf,
    output [7:0]   arlen_s_inf,
    output [2:0]   arsize_s_inf,
    output [1:0]   arburst_s_inf,
    output reg     arvalid_s_inf,
    // src slave
    input          arready_s_inf,
    // -----------------------------
  
    // axi read data channel 
    // slave
    input [3:0]    rid_s_inf,
    input [127:0]  rdata_s_inf,
    input [1:0]    rresp_s_inf,
    input          rlast_s_inf,
    input          rvalid_s_inf,
    // master
    output reg     rready_s_inf
    
);

parameter IDLE = 'd0;
parameter INPUT = 2'd1;
parameter CALC = 2'd2;
parameter OUTPUT = 2'd3;

parameter PIC_SIZE = 'd3072;
parameter BURST_LEN = 'd191;

parameter INPUT_R = 'd1;
parameter OUTPUT_R = 'd2;
parameter INPUT_G = 'd3;
parameter OUTPUT_G = 'd4;
parameter INPUT_B = 'd5;
parameter OUTPUT_B = 'd6;

reg [7:0] auto_focus_temp [0:5][0:5];
reg [127:0] dram_input_temp;            // store data sent from DRAM
reg [127:0] output_from_sram;
reg [13:0] auto_exp_temp [0:15];
reg [1:0] cs, ns;
reg [3:0] in_pic_no_reg;
reg in_mode_reg;
reg [1:0] in_ratio_mode_reg;
reg read_req_flag;                           // flag that mark whether it has requested to read
reg [7:0] read_counter;                      // count how many data have been read.
reg rvalid_s_inf_pre;
reg [5:0] diff_count;                       // count in auto focus diff
reg [13:0] diff_6;                          // only add for exclusive 6 * 6
reg [12:0] diff_4;
reg [10:0] diff_2;
reg [2:0] ptr_x, ptr_y;
reg [7:0] result_2, result_4, result_6;
reg [2:0] sram_cs, sram_ns;
reg [5:0] addr;
reg [127:0] DI;
reg [127:0] DO;
reg oe, CS, web;

SUMA180_64X16X1BM1 ram_0 (.A0(addr[0]), .A1(addr[1]), .A2(addr[2]), .A3(addr[3]), .A4(addr[4]), .A5(addr[5]),
                          .DO0(DO[0]), .DO1(DO[1]), .DO2(DO[2]), .DO3(DO[3]), .DO4(DO[4]), .DO5(DO[5]), .DO6(DO[6]), .DO7(DO[7]), 
                          .DO8(DO[8]), .DO9(DO[9]), .DO10(DO[10]), .DO11(DO[11]), .DO12(DO[12]), .DO13(DO[13]), .DO14(DO[14]), .DO15(DO[15]),
                          .DI0(DI[0]), .DI1(DI[1]), .DI2(DI[2]), .DI3(DI[3]), .DI4(DI[4]), .DI5(DI[5]), .DI6(DI[6]), .DI7(DI[7]),
                          .DI8(DI[8]), .DI9(DI[9]), .DI10(DI[10]), .DI11(DI[11]), .DI12(DI[12]), .DI13(DI[13]), .DI14(DI[14]), .DI15(DI[15]), 
                          .CK(clk), .WEB(web), .OE(oe), .CS(CS));

SUMA180_64X16X1BM1 ram_1 (.A0(addr[0]), .A1(addr[1]), .A2(addr[2]), .A3(addr[3]), .A4(addr[4]), .A5(addr[5]),
                          .DO0(DO[16]), .DO1(DO[17]), .DO2(DO[18]), .DO3(DO[19]), .DO4(DO[20]), .DO5(DO[21]), .DO6(DO[22]), .DO7(DO[23]),
                          .DO8(DO[24]), .DO9(DO[25]), .DO10(DO[26]), .DO11(DO[27]), .DO12(DO[28]), .DO13(DO[29]), .DO14(DO[30]), .DO15(DO[31]),
                          .DI0(DI[16]), .DI1(DI[17]), .DI2(DI[18]), .DI3(DI[19]), .DI4(DI[20]), .DI5(DI[21]), .DI6(DI[22]), .DI7(DI[23]),
                          .DI8(DI[24]), .DI9(DI[25]), .DI10(DI[26]), .DI11(DI[27]), .DI12(DI[28]), .DI13(DI[29]), .DI14(DI[30]), .DI15(DI[31]),
                          .CK(clk), .WEB(web), .OE(oe), .CS(CS));

SUMA180_64X16X1BM1 ram_2 (.A0(addr[0]), .A1(addr[1]), .A2(addr[2]), .A3(addr[3]), .A4(addr[4]), .A5(addr[5]),
                          .DO0(DO[32]), .DO1(DO[33]), .DO2(DO[34]), .DO3(DO[35]), .DO4(DO[36]), .DO5(DO[37]), .DO6(DO[38]), .DO7(DO[39]),
                          .DO8(DO[40]), .DO9(DO[41]), .DO10(DO[42]), .DO11(DO[43]), .DO12(DO[44]), .DO13(DO[45]), .DO14(DO[46]), .DO15(DO[47]),
                          .DI0(DI[32]), .DI1(DI[33]), .DI2(DI[34]), .DI3(DI[35]), .DI4(DI[36]), .DI5(DI[37]), .DI6(DI[38]), .DI7(DI[39]),
                          .DI8(DI[40]), .DI9(DI[41]), .DI10(DI[42]), .DI11(DI[43]), .DI12(DI[44]), .DI13(DI[45]), .DI14(DI[46]), .DI15(DI[47]), 
                          .CK(clk), .WEB(web), .OE(oe), .CS(CS));

SUMA180_64X16X1BM1 ram_3 (.A0(addr[0]), .A1(addr[1]), .A2(addr[2]), .A3(addr[3]), .A4(addr[4]), .A5(addr[5]),
                          .DO0(DO[48]), .DO1(DO[49]), .DO2(DO[50]), .DO3(DO[51]), .DO4(DO[52]), .DO5(DO[53]), .DO6(DO[54]), .DO7(DO[55]),
                          .DO8(DO[56]), .DO9(DO[57]), .DO10(DO[58]), .DO11(DO[59]), .DO12(DO[60]), .DO13(DO[61]), .DO14(DO[62]), .DO15(DO[63]),
                          .DI0(DI[48]), .DI1(DI[49]), .DI2(DI[50]), .DI3(DI[51]), .DI4(DI[52]), .DI5(DI[53]), .DI6(DI[54]), .DI7(DI[55]), 
                          .DI8(DI[56]), .DI9(DI[57]), .DI10(DI[58]), .DI11(DI[59]), .DI12(DI[60]), .DI13(DI[61]), .DI14(DI[62]), .DI15(DI[63]), 
                          .CK(clk), .WEB(web), .OE(oe), .CS(CS));

SUMA180_64X16X1BM1 ram_4 (.A0(addr[0]), .A1(addr[1]), .A2(addr[2]), .A3(addr[3]), .A4(addr[4]), .A5(addr[5]),
                          .DO0(DO[64]), .DO1(DO[65]), .DO2(DO[66]), .DO3(DO[67]), .DO4(DO[68]), .DO5(DO[69]), .DO6(DO[70]), .DO7(DO[71]),
                          .DO8(DO[72]), .DO9(DO[73]), .DO10(DO[74]), .DO11(DO[75]), .DO12(DO[76]), .DO13(DO[77]), .DO14(DO[78]), .DO15(DO[79]),
                          .DI0(DI[64]), .DI1(DI[65]), .DI2(DI[66]), .DI3(DI[67]), .DI4(DI[68]), .DI5(DI[69]), .DI6(DI[70]), .DI7(DI[71]),
                          .DI8(DI[72]), .DI9(DI[73]), .DI10(DI[74]), .DI11(DI[75]), .DI12(DI[76]), .DI13(DI[77]), .DI14(DI[78]), .DI15(DI[79]), 
                          .CK(clk), .WEB(web), .OE(oe), .CS(CS));

SUMA180_64X16X1BM1 ram_05 (.A0(addr[0]), .A1(addr[1]), .A2(addr[2]), .A3(addr[3]), .A4(addr[4]), .A5(addr[5]),
                          .DO0(DO[80]), .DO1(DO[81]), .DO2(DO[82]), .DO3(DO[83]), .DO4(DO[84]), .DO5(DO[85]), .DO6(DO[86]), .DO7(DO[87]),
                          .DO8(DO[88]), .DO9(DO[89]), .DO10(DO[90]), .DO11(DO[91]), .DO12(DO[92]), .DO13(DO[93]), .DO14(DO[94]), .DO15(DO[95]),
                          .DI0(DI[80]), .DI1(DI[81]), .DI2(DI[82]), .DI3(DI[83]), .DI4(DI[84]), .DI5(DI[85]), .DI6(DI[86]), .DI7(DI[87]), 
                          .DI8(DI[88]), .DI9(DI[89]), .DI10(DI[90]), .DI11(DI[91]), .DI12(DI[92]), .DI13(DI[93]), .DI14(DI[94]), .DI15(DI[95]), 
                          .CK(clk), .WEB(web), .OE(oe), .CS(CS));

SUMA180_64X16X1BM1 ram_6 (.A0(addr[0]), .A1(addr[1]), .A2(addr[2]), .A3(addr[3]), .A4(addr[4]), .A5(addr[5]),
                          .DO0(DO[96]), .DO1(DO[97]), .DO2(DO[98]), .DO3(DO[99]), .DO4(DO[100]), .DO5(DO[101]), .DO6(DO[102]), .DO7(DO[103]),
                          .DO8(DO[104]), .DO9(DO[105]), .DO10(DO[106]), .DO11(DO[107]), .DO12(DO[108]), .DO13(DO[109]), .DO14(DO[110]), .DO15(DO[111]),
                          .DI0(DI[96]), .DI1(DI[97]), .DI2(DI[98]), .DI3(DI[99]), .DI4(DI[100]), .DI5(DI[101]), .DI6(DI[102]), .DI7(DI[103]),
                          .DI8(DI[104]), .DI9(DI[105]), .DI10(DI[106]), .DI11(DI[107]), .DI12(DI[108]), .DI13(DI[109]), .DI14(DI[110]), .DI15(DI[111]), 
                          .CK(clk), .WEB(web), .OE(oe), .CS(CS));

SUMA180_64X16X1BM1 ram_7 (.A0(addr[0]), .A1(addr[1]), .A2(addr[2]), .A3(addr[3]), .A4(addr[4]), .A5(addr[5]),
                          .DO0(DO[112]), .DO1(DO[113]), .DO2(DO[114]), .DO3(DO[115]), .DO4(DO[116]), .DO5(DO[117]), .DO6(DO[118]), .DO7(DO[119]),
                          .DO8(DO[120]), .DO9(DO[121]), .DO10(DO[122]), .DO11(DO[123]), .DO12(DO[124]), .DO13(DO[125]), .DO14(DO[126]), .DO15(DO[127]),
                          .DI0(DI[112]), .DI1(DI[113]), .DI2(DI[114]), .DI3(DI[115]), .DI4(DI[116]), .DI5(DI[117]), .DI6(DI[118]), .DI7(DI[119]),
                          .DI8(DI[120]), .DI9(DI[121]), .DI10(DI[122]), .DI11(DI[123]), .DI12(DI[124]), .DI13(DI[125]), .DI14(DI[126]), .DI15(DI[127]), 
                          .CK(clk), .WEB(web), .OE(oe), .CS(CS));

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        cs <= IDLE;
    end else begin
        cs <= ns;
    end
end

always @(*) begin
    case (cs)
        IDLE: ns = in_valid ? INPUT : IDLE;
        INPUT: ns = rlast_s_inf ? CALC : INPUT;
        CALC: begin
            case (in_mode_reg)
                0: ns = diff_count == 'd61 ? OUTPUT : CALC;
                1: ns = (sram_cs == IDLE && ~addr[0]) ? OUTPUT : CALC;                       // NEED MODIFICATION      
            endcase
        end                                         
        OUTPUT: ns = out_valid ? IDLE : OUTPUT;
    endcase
end

assign arid_s_inf = 'd0;
assign araddr_s_inf = ~rst_n ? 'd0 : 32'h10000 + in_pic_no_reg * PIC_SIZE;                                
assign arlen_s_inf = ~rst_n ? 'd0 : BURST_LEN;
assign arsize_s_inf = ~rst_n ? 'd0 : 3'b100;
assign arburst_s_inf = ~rst_n ? 'd0 : 2'b01;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        arvalid_s_inf <= 'b0;
    end else begin
        case (cs) 
            INPUT: begin
                case (arvalid_s_inf)
                    0: arvalid_s_inf <= (~read_req_flag) ? 'b1 : 'b0;
                    1: arvalid_s_inf <= arready_s_inf ? 'b0 : 'b1;
                endcase
            end
            default: arvalid_s_inf <= 'b0;
        endcase
    end
end


always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        rready_s_inf <= 'b0;
    end else begin
        case (cs) 
            INPUT: begin
                case (sram_cs)
                    IDLE: begin
                        if (read_req_flag && !arvalid_s_inf) begin
                            case (rready_s_inf)
                                0: rready_s_inf <= 'b1;
                                1: rready_s_inf <= rlast_s_inf ? 'b0 : 'b1;
                            endcase
                        end else begin
                            rready_s_inf <= 'b0;
                        end
                    end

                    INPUT_R: begin
                        case (rready_s_inf)
                            0: rready_s_inf <= 'b0;
                            1: rready_s_inf <= &addr[5:1] ? 'b0 : 'b1;
                        endcase
                    end

                    OUTPUT_R: begin
                        case (rready_s_inf)
                            0: rready_s_inf <= &addr[5:1] ? 'b1 : 'b0;
                            1: rready_s_inf <= 'b1;
                        endcase
                    end 

                    INPUT_G: begin
                        case (rready_s_inf)
                            0: rready_s_inf <= 'b0;
                            1: rready_s_inf <= &addr[5:1] ? 'b0 : 'b1;
                        endcase
                    end 

                    OUTPUT_G: begin
                        case (rready_s_inf)
                            0: rready_s_inf <= &addr[5:1] ? 'b1 : 'b0;
                            1: rready_s_inf <= 'b1;
                        endcase
                    end

                    INPUT_B: begin
                        case (rready_s_inf)
                            0: rready_s_inf <= 'b0;
                            1: rready_s_inf <= &addr[5:1] ? 'b0 : 'b1;
                        endcase
                    end

                    OUTPUT_B: rready_s_inf <= 'b0;
                endcase
            end
            default: rready_s_inf <= 'b0;
        endcase
    end
end

assign awid_s_inf = 'd0;
assign awaddr_s_inf = ~rst_n ? 'd0 : 32'h10000 + in_pic_no_reg * PIC_SIZE;                                     
assign awlen_s_inf = ~rst_n ? 'd0 : BURST_LEN;
assign awsize_s_inf = ~rst_n ? 'd0 : 3'b100;
assign awburst_s_inf = ~rst_n ? 'd0 : 2'b01;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        awvalid_s_inf <= 'b0;
    end else begin
        case (in_mode_reg)
            0: awvalid_s_inf <= 'b0;
            1: begin
                case (cs) 
                    INPUT: begin
                        case (awvalid_s_inf)
                            0: awvalid_s_inf <= sram_cs == INPUT_R && addr == 'd60 ? 'b1 : 'b0;
                            1: awvalid_s_inf <= awready_s_inf ? 'b0 : 'b1;
                        endcase
                    end
                    default: awvalid_s_inf <= 'b0;
                endcase
            end
        endcase
    end
end

assign wdata_s_inf = ~rst_n ? 'b0 : output_from_sram;                                      

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        wlast_s_inf <= 'b0;
    end else begin
        case (wlast_s_inf)
            0: wlast_s_inf <= (sram_cs == OUTPUT_B && sram_ns == IDLE) ? 'b1 : 'b0;
            1: wlast_s_inf <= 'b0; 
        endcase
    end
end


always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        wvalid_s_inf <= 'b0;
    end else begin
        case (sram_cs)
            IDLE: wvalid_s_inf <= 'b0;
            INPUT_R: begin
                case (wvalid_s_inf)
                    0: wvalid_s_inf <= awready_s_inf ? 'b1 : 'b0;
                    1: wvalid_s_inf <= 'b1;
                endcase
            end
            OUTPUT_R: wvalid_s_inf <= 'b1;
            INPUT_G: wvalid_s_inf <= 'b0;
            OUTPUT_G: wvalid_s_inf <= 'b1;
            INPUT_B: wvalid_s_inf <= 'b0;
            OUTPUT_B: wvalid_s_inf <= 'b1;
        endcase
    end
end                                     
                             

assign bready_s_inf = ~rst_n ? 'b0 : 'b1;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        in_pic_no_reg <= 'd0;
    end else begin
        in_pic_no_reg <= in_valid ? in_pic_no : in_pic_no_reg;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        in_mode_reg <= 'b0;
    end else begin
        in_mode_reg <= in_valid ? in_mode : in_mode_reg;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        in_ratio_mode_reg <= 'd0;
    end else begin
        in_ratio_mode_reg <= (in_valid && in_mode) ? in_ratio_mode : in_ratio_mode_reg;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        read_req_flag <= 'b0;
    end else begin
        case (cs)
            INPUT: begin
                case (read_req_flag)
                    0: read_req_flag <= araddr_s_inf ? 'b1 : 'b0;
                    1: read_req_flag <= 'b1;
                endcase
            end
            default: read_req_flag <= 'b0;
        endcase
    end
end


always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        dram_input_temp <= 'd0;
    end else begin
        case (cs) 
            INPUT: dram_input_temp <= rvalid_s_inf ? rdata_s_inf : dram_input_temp;
            default: dram_input_temp <= 'd0;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        read_counter <= 'd0;
    end else begin
        case (cs)
            INPUT, CALC: read_counter <= rvalid_s_inf && rready_s_inf ? read_counter + 'd1 : read_counter;
            default: read_counter <= 'd0;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        rvalid_s_inf_pre <= 'b0;
    end else begin
        rvalid_s_inf_pre <= rvalid_s_inf;
    end
end 

genvar i, j;
generate
    for (i = 0; i < 6; i = i + 1) begin: auto_focus_temp_i
        for (j = 0; j < 6; j = j + 1) begin: auto_focus_temp_j
            always @(posedge clk or negedge rst_n) begin
                if (~rst_n) begin
                    auto_focus_temp[i][j] <= 'd0;
                end else begin
                    case (cs)
                        IDLE, OUTPUT: auto_focus_temp[i][j] <= 'd0;
                        CALC: auto_focus_temp[i][j] <= auto_focus_temp[i][j];
                        INPUT: begin
                            if (rvalid_s_inf_pre) begin
                                case (read_counter)
                                    'd27, 'd29, 'd31, 'd33, 'd35, 'd37: begin
                                        if (j == 0 || j == 1 || j == 2) begin
                                            auto_focus_temp[i][j] <= auto_focus_temp[i][j+3];
                                        end else begin
                                            if (i == 5) begin
                                                if (j == 3) begin
                                                    auto_focus_temp[i][j] <= {2'b00, dram_input_temp[111:106]};
                                                end else if (j == 4) begin
                                                    auto_focus_temp[i][j] <= {2'b00, dram_input_temp[119:114]};
                                                end else if (j == 5) begin
                                                    auto_focus_temp[i][j] <= {2'b00, dram_input_temp[127:122]};
                                                end
                                            end else begin
                                                auto_focus_temp[i][j] <= auto_focus_temp[i+1][j-3];
                                            end
                                        end
                                    end

                                    'd91, 'd93, 'd95, 'd97, 'd99, 'd101: begin
                                        if (j == 0 || j == 1 || j == 2) begin
                                            auto_focus_temp[i][j] <= auto_focus_temp[i][j+3];
                                        end else begin
                                            if (i == 5) begin
                                                if (j == 3) begin
                                                    auto_focus_temp[i][j] <= auto_focus_temp[i-5][j-3] + {1'b0, dram_input_temp[111:105]};
                                                end else if (j == 4) begin
                                                    auto_focus_temp[i][j] <= auto_focus_temp[i-5][j-3] + {1'b0, dram_input_temp[119:113]};
                                                end else if (j == 5) begin
                                                    auto_focus_temp[i][j] <= auto_focus_temp[i-5][j-3] + {1'b0, dram_input_temp[127:121]};
                                                end
                                            end else begin
                                                auto_focus_temp[i][j] <= auto_focus_temp[i+1][j-3];
                                            end
                                        end
                                    end

                                    'd155, 'd157, 'd159, 'd161, 'd163, 'd165: begin
                                        if (j == 0 || j == 1 || j == 2) begin
                                            auto_focus_temp[i][j] <= auto_focus_temp[i][j+3];
                                        end else begin
                                            if (i == 5) begin
                                                if (j == 3) begin
                                                    auto_focus_temp[i][j] <= auto_focus_temp[i-5][j-3] + {2'b00, dram_input_temp[111:106]};
                                                end else if (j == 4) begin
                                                    auto_focus_temp[i][j] <= auto_focus_temp[i-5][j-3] + {2'b00, dram_input_temp[119:114]};
                                                end else if (j == 5) begin
                                                    auto_focus_temp[i][j] <= auto_focus_temp[i-5][j-3] + {2'b00, dram_input_temp[127:122]};
                                                end
                                            end else begin
                                                auto_focus_temp[i][j] <= auto_focus_temp[i+1][j-3];
                                            end
                                        end
                                    end

                                    'd28, 'd30, 'd32, 'd34, 'd36, 'd38: begin
                                        if (j == 0 || j == 1 || j == 2) begin
                                            auto_focus_temp[i][j] <= auto_focus_temp[i][j+3];
                                        end else begin
                                            if (i == 5) begin
                                                if (j == 3) begin
                                                    auto_focus_temp[i][j] <= {2'b00, dram_input_temp[7:2]};
                                                end else if (j == 4) begin
                                                    auto_focus_temp[i][j] <= {2'b00, dram_input_temp[15:10]};
                                                end else if (j == 5) begin
                                                    auto_focus_temp[i][j] <= {2'b00, dram_input_temp[23:18]};
                                                end
                                            end else begin
                                                auto_focus_temp[i][j] <= auto_focus_temp[i+1][j-3];
                                            end
                                        end
                                    end

                                    'd92, 'd94, 'd96, 'd98, 'd100, 'd102: begin
                                        if (j == 0 || j == 1 || j == 2) begin
                                            auto_focus_temp[i][j] <= auto_focus_temp[i][j+3];
                                        end else begin
                                            if (i == 5) begin
                                                if (j == 3) begin
                                                    auto_focus_temp[i][j] <= auto_focus_temp[i-5][j-3] + {1'b0, dram_input_temp[7:1]};
                                                end else if (j == 4) begin
                                                    auto_focus_temp[i][j] <= auto_focus_temp[i-5][j-3] + {1'b0, dram_input_temp[15:9]};
                                                end else if (j == 5) begin
                                                    auto_focus_temp[i][j] <= auto_focus_temp[i-5][j-3] + {1'b0, dram_input_temp[23:17]};
                                                end
                                            end else begin
                                                auto_focus_temp[i][j] <= auto_focus_temp[i+1][j-3];
                                            end
                                        end
                                    end
                                    'd156, 'd158, 'd160, 'd162, 'd164, 'd166: begin
                                        if (j == 0 || j == 1 || j == 2) begin
                                            auto_focus_temp[i][j] <= auto_focus_temp[i][j+3];
                                        end else begin
                                            if (i == 5) begin
                                                if (j == 3) begin
                                                    auto_focus_temp[i][j] <= auto_focus_temp[i-5][j-3] + {2'b00, dram_input_temp[7:2]};
                                                end else if (j == 4) begin
                                                    auto_focus_temp[i][j] <= auto_focus_temp[i-5][j-3] + {2'b00, dram_input_temp[15:10]};
                                                end else if (j == 5) begin
                                                    auto_focus_temp[i][j] <= auto_focus_temp[i-5][j-3] + {2'b00, dram_input_temp[23:18]};
                                                end
                                            end else begin
                                                auto_focus_temp[i][j] <= auto_focus_temp[i+1][j-3];
                                            end
                                        end
                                    end
                                endcase
                            end
                        end
                    endcase
                end
            end
        end
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        diff_count <= 'd0;
    end else begin
        case (cs)
            CALC: begin
                diff_count <= diff_count + 'd1;
            end
            default: diff_count <= 'd0;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        ptr_x <= 'd0;
    end else begin
        case (cs)
            CALC: begin
                if (diff_count < 'd30) begin
                    ptr_x <= (ptr_x == 'd4) ? 'd0 : ptr_x + 'd1;
                end else begin
                    ptr_x <= (ptr_x == 'd5) ? 'd0 : ptr_x + 'd1;
                end
            end
            default: ptr_x <= 'd0;
        endcase
    end
end 

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        ptr_y <= 'd0;
    end else begin
        case (cs)
            CALC: begin
                if (diff_count < 'd29) begin
                    ptr_y <= (diff_count % 5 == 'd4) ? ptr_y + 'd1 : ptr_y;
                end else if (diff_count == 'd29) begin
                    ptr_y <= 'd0;
                end else begin
                    ptr_y <= (diff_count % 6 == 'd5) ? ptr_y + 'd1 : ptr_y;
                end
            end
            default: ptr_y <= 'd0;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        diff_6 <= 'd0;
    end else begin
        case (cs) 
            CALC: begin
                case (diff_count)
                    'd0, 'd1, 'd2, 'd3, 'd4, 'd5, 'd9, 'd10, 'd14, 'd15, 
                    'd19, 'd20, 'd24, 'd25, 'd26, 'd27, 'd28, 'd29: 
                    begin
                        diff_6 <= (auto_focus_temp[ptr_y][ptr_x] > auto_focus_temp[ptr_y][ptr_x+1]) ? 
                        diff_6 + (auto_focus_temp[ptr_y][ptr_x] - auto_focus_temp[ptr_y][ptr_x+1]) :
                        diff_6 + (auto_focus_temp[ptr_y][ptr_x+1] - auto_focus_temp[ptr_y][ptr_x]);
                    end

                    'd30, 'd31, 'd32, 'd33, 'd34, 'd35, 'd36, 'd41, 'd42,
                    'd47, 'd48, 'd53, 'd54, 'd55, 'd56, 'd57, 'd58, 'd59:
                    begin
                        diff_6 <= (auto_focus_temp[ptr_y][ptr_x] > auto_focus_temp[ptr_y+1][ptr_x]) ? 
                        diff_6 + (auto_focus_temp[ptr_y][ptr_x] - auto_focus_temp[ptr_y+1][ptr_x]) :
                        diff_6 + (auto_focus_temp[ptr_y+1][ptr_x] - auto_focus_temp[ptr_y][ptr_x]);
                    end
                endcase
            end
            default: diff_6 <= 'd0;
        endcase
    end
end 

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        diff_4 <= 'd0;
    end else begin
        case (cs) 
            CALC: begin
                case (diff_count)
                    'd6, 'd7, 'd8, 'd11, 'd13, 'd16, 'd18, 'd21, 'd22, 'd23: 
                    begin
                        diff_4 <= (auto_focus_temp[ptr_y][ptr_x] > auto_focus_temp[ptr_y][ptr_x+1]) ? 
                        diff_4 + (auto_focus_temp[ptr_y][ptr_x] - auto_focus_temp[ptr_y][ptr_x+1]) :
                        diff_4 + (auto_focus_temp[ptr_y][ptr_x+1] - auto_focus_temp[ptr_y][ptr_x]);
                    end

                    'd37, 'd38, 'd39, 'd40, 'd43, 'd46, 'd49, 'd50, 'd51, 'd52:
                    begin
                        diff_4 <= (auto_focus_temp[ptr_y][ptr_x] > auto_focus_temp[ptr_y+1][ptr_x]) ? 
                        diff_4 + (auto_focus_temp[ptr_y][ptr_x] - auto_focus_temp[ptr_y+1][ptr_x]) :
                        diff_4 + (auto_focus_temp[ptr_y+1][ptr_x] - auto_focus_temp[ptr_y][ptr_x]);
                    end
                endcase
            end
            default: diff_4 <= 'd0;
        endcase
    end
end 

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        diff_2 <= 'd0;
    end else begin
        case (cs) 
            CALC: begin
                case (diff_count)
                    'd12, 'd17: 
                    begin
                        diff_2 <= (auto_focus_temp[ptr_y][ptr_x] > auto_focus_temp[ptr_y][ptr_x+1]) ? 
                        diff_2 + (auto_focus_temp[ptr_y][ptr_x] - auto_focus_temp[ptr_y][ptr_x+1]) :
                        diff_2 + (auto_focus_temp[ptr_y][ptr_x+1] - auto_focus_temp[ptr_y][ptr_x]);
                    end

                    'd44, 'd45:
                    begin
                        diff_2 <= (auto_focus_temp[ptr_y][ptr_x] > auto_focus_temp[ptr_y+1][ptr_x]) ? 
                        diff_2 + (auto_focus_temp[ptr_y][ptr_x] - auto_focus_temp[ptr_y+1][ptr_x]) :
                        diff_2 + (auto_focus_temp[ptr_y+1][ptr_x] - auto_focus_temp[ptr_y][ptr_x]);
                    end
                endcase
            end
            default: diff_2 <= 'd0;
        endcase
    end
end 

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        result_2 <= 'd0;
    end else begin
        case (cs)
            CALC: begin
                case (diff_count)
                    'd60: result_2 <= diff_2 >> 2;
                endcase
            end
            default: result_2 <= 'd0;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        result_4 <= 'd0;
    end else begin
        case (cs)
            CALC: begin
                case (diff_count)
                    'd60: result_4 <= (diff_4 + diff_2) >> 4;
                endcase
            end
            default: result_4 <= 'd0;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        result_6 <= 'd0;
    end else begin
        case (cs)
            CALC: begin
                case (diff_count)
                    'd60: result_6 <= (diff_2 + diff_4 + diff_6) / 'd36;
                endcase
            end
            default: result_6 <= 'd0;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        addr <= 'd0;
    end else begin
        case (cs)
            IDLE, OUTPUT: addr <= 'd0;
            INPUT, CALC: addr <= CS || cs == CALC ? addr + 'd1 : addr;
        endcase
    end
end

always @(*) begin
    case (sram_ns)
        INPUT_R, INPUT_G, INPUT_B: begin
            case (in_ratio_mode_reg)
                'd0: DI = {2'b00, dram_input_temp[127:122], 2'b00, dram_input_temp[119:114], 2'b00, dram_input_temp[111:106], 2'b00, dram_input_temp[103: 98],
                           2'b00, dram_input_temp[ 95: 90], 2'b00, dram_input_temp[ 87: 82], 2'b00, dram_input_temp[ 79: 74], 2'b00, dram_input_temp[ 71: 66],
                           2'b00, dram_input_temp[ 63: 58], 2'b00, dram_input_temp[ 55: 50], 2'b00, dram_input_temp[ 47: 42], 2'b00, dram_input_temp[ 39: 34],
                           2'b00, dram_input_temp[ 31: 26], 2'b00, dram_input_temp[ 23: 18], 2'b00, dram_input_temp[ 15: 10], 2'b00, dram_input_temp[  7:  2]};

                'd1: DI = {1'b0, dram_input_temp[127:121], 1'b0, dram_input_temp[119:113], 1'b0, dram_input_temp[111:105], 1'b0, dram_input_temp[103: 97],
                           1'b0, dram_input_temp[ 95: 89], 1'b0, dram_input_temp[ 87: 81], 1'b0, dram_input_temp[ 79: 73], 1'b0, dram_input_temp[ 71: 65],
                           1'b0, dram_input_temp[ 63: 57], 1'b0, dram_input_temp[ 55: 49], 1'b0, dram_input_temp[ 47: 41], 1'b0, dram_input_temp[ 39: 33],
                           1'b0, dram_input_temp[ 31: 25], 1'b0, dram_input_temp[ 23: 17], 1'b0, dram_input_temp[ 15:  9], 1'b0, dram_input_temp[  7:  1]};

                'd2: DI = dram_input_temp;

                'd3: DI = dram_mul_2(dram_input_temp);
            endcase
        end
        default: DI = 'D0;
    endcase
end


always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        output_from_sram <= 'd0;
    end else begin
        case (sram_cs)
            IDLE, INPUT_R, INPUT_G, INPUT_B: output_from_sram <= 'd0;
            OUTPUT_R, OUTPUT_G, OUTPUT_B: output_from_sram <= DO;
        endcase
    end 
end



always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        out_valid <= 'b0;
    end else begin
        out_valid <= ns == OUTPUT ? 'b1 : 'b0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        out_data <= 'd0;
    end else begin
        case (in_mode_reg)
            0: begin
                case (ns)
                    OUTPUT: begin
                        if (result_2 >= result_4 && result_2 >= result_6) begin
                            out_data <= 'd0;
                        end else if (result_4 > result_2 && result_4 >= result_6) begin
                            out_data <= 'd1;
                        end else begin
                            out_data <= 'd2;
                        end
                    end
                    default: out_data <= 'd0;
                endcase
            end
            1: begin
                case (ns)
                    OUTPUT: out_data <= calc_avg(auto_exp_temp);
                    default: out_data <= 'd0;
                endcase
            end
        endcase
    end
end


always @(*) begin
    case (sram_ns)
        IDLE: web = 'b1;
        INPUT_R: web = 'b0;
        OUTPUT_R: web = 'b1;
        INPUT_G: web = 'b0;
        OUTPUT_G: web = 'b1;
        INPUT_B: web = 'b0;
        OUTPUT_B: web = 'b1;
        default: web = 'b1;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        CS <= 'b0;
    end else begin
        case (sram_ns)
            IDLE: CS <= 'b0;
            default: CS <= 'b1;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        oe <= 'b0;
    end else begin
        case (sram_ns)
            IDLE, INPUT_R, INPUT_G, INPUT_B: oe <= 'b0;
            OUTPUT_R, OUTPUT_G, OUTPUT_B: oe <= 'b1;
        endcase
    end
end



genvar o;
generate
    for (o = 0; o < 16; o = o + 1) begin: auto_exp_temp_loop
        always @(posedge clk or negedge rst_n) begin
            if (~rst_n) begin
                auto_exp_temp[o] <= 'd0;
            end else begin
                case (sram_cs)
                    INPUT_R: auto_exp_temp[o] <= 'd0;
                    OUTPUT_R, INPUT_G: begin
                        if (wready_s_inf) begin
                            case (o)
                                0: auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[127:122]};
                                1: auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[119:114]};
                                2: auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[111:106]};
                                3: auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[103: 98]};
                                4: auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[ 95: 90]};
                                5: auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[ 87: 82]};
                                6: auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[ 79: 74]};
                                7: auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[ 71: 66]};
                                8: auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[ 63: 58]};
                                9: auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[ 55: 50]};
                                10:auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[ 47: 42]};
                                11:auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[ 39: 34]};
                                12:auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[ 31: 26]};
                                13:auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[ 23: 18]};
                                14:auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[ 15: 10]};
                                15:auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[  7:  2]};
                            endcase
                        end
                    end
                    OUTPUT_G, INPUT_B: begin
                        if (wready_s_inf) begin
                            case (o)
                                0: auto_exp_temp[o] <= auto_exp_temp[o] + {1'b0, output_from_sram[127:121]};
                                1: auto_exp_temp[o] <= auto_exp_temp[o] + {1'b0, output_from_sram[119:113]};
                                2: auto_exp_temp[o] <= auto_exp_temp[o] + {1'b0, output_from_sram[111:105]};
                                3: auto_exp_temp[o] <= auto_exp_temp[o] + {1'b0, output_from_sram[103: 97]};
                                4: auto_exp_temp[o] <= auto_exp_temp[o] + {1'b0, output_from_sram[ 95: 89]};
                                5: auto_exp_temp[o] <= auto_exp_temp[o] + {1'b0, output_from_sram[ 87: 81]};
                                6: auto_exp_temp[o] <= auto_exp_temp[o] + {1'b0, output_from_sram[ 79: 73]};
                                7: auto_exp_temp[o] <= auto_exp_temp[o] + {1'b0, output_from_sram[ 71: 65]};
                                8: auto_exp_temp[o] <= auto_exp_temp[o] + {1'b0, output_from_sram[ 63: 57]};
                                9: auto_exp_temp[o] <= auto_exp_temp[o] + {1'b0, output_from_sram[ 55: 49]};
                                10:auto_exp_temp[o] <= auto_exp_temp[o] + {1'b0, output_from_sram[ 47: 41]};
                                11:auto_exp_temp[o] <= auto_exp_temp[o] + {1'b0, output_from_sram[ 39: 33]};
                                12:auto_exp_temp[o] <= auto_exp_temp[o] + {1'b0, output_from_sram[ 31: 25]};
                                13:auto_exp_temp[o] <= auto_exp_temp[o] + {1'b0, output_from_sram[ 23: 17]};
                                14:auto_exp_temp[o] <= auto_exp_temp[o] + {1'b0, output_from_sram[ 15:  9]};
                                15:auto_exp_temp[o] <= auto_exp_temp[o] + {1'b0, output_from_sram[  7:  1]};
                            endcase
                        end
                    end
                    OUTPUT_B, IDLE: begin
                        if (wready_s_inf) begin
                            case (o)
                                0: auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[127:122]};
                                1: auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[119:114]};
                                2: auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[111:106]};
                                3: auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[103: 98]};
                                4: auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[ 95: 90]};
                                5: auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[ 87: 82]};
                                6: auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[ 79: 74]};
                                7: auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[ 71: 66]};
                                8: auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[ 63: 58]};
                                9: auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[ 55: 50]};
                                10:auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[ 47: 42]};
                                11:auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[ 39: 34]};
                                12:auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[ 31: 26]};
                                13:auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[ 23: 18]};
                                14:auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[ 15: 10]};
                                15:auto_exp_temp[o] <= auto_exp_temp[o] + {2'b00, output_from_sram[  7:  2]};
                            endcase
                        end
                    end
                    default: auto_exp_temp[o] <= auto_exp_temp[o];
                endcase
            end
        end 
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        sram_cs <= IDLE;
    end else begin
        sram_cs <= sram_ns;
    end
end

always @(*) begin
    case (sram_cs)
        IDLE: sram_ns = in_mode_reg && rvalid_s_inf ? INPUT_R : IDLE;
        INPUT_R: sram_ns = ~|addr && wvalid_s_inf && ~awready_s_inf ? OUTPUT_R : INPUT_R;
        OUTPUT_R: sram_ns = ~|addr ? INPUT_G : OUTPUT_R;
        INPUT_G: sram_ns = ~|addr && ~oe ? OUTPUT_G : INPUT_G;
        OUTPUT_G: sram_ns = ~|addr ? INPUT_B : OUTPUT_G;
        INPUT_B: sram_ns = ~|addr && ~oe ? OUTPUT_B : INPUT_B;
        OUTPUT_B: sram_ns = ~|addr ? IDLE : OUTPUT_B;
        default: sram_ns = IDLE;
    endcase
end

function [7:0] calc_avg;
    input [13:0] auto_exp_temp [0:15];
    reg [17:0] total;
    begin
        total = (((auto_exp_temp[0] + auto_exp_temp[1]) + (auto_exp_temp[2] + auto_exp_temp[3]))
                + ((auto_exp_temp[4] + auto_exp_temp[5]) + (auto_exp_temp[6] + auto_exp_temp[7])))
                + (((auto_exp_temp[8] + auto_exp_temp[9]) + (auto_exp_temp[10] + auto_exp_temp[11]))
                + ((auto_exp_temp[12] + auto_exp_temp[13]) + (auto_exp_temp[14] + auto_exp_temp[15])));
        
        calc_avg = total >> 10;
    end
endfunction

function [127:0] dram_mul_2;
    input [127:0] dram;

    begin
        dram_mul_2[127:120] = dram[127] ? 8'b11111111 : {dram[126:120], 1'b0};
        dram_mul_2[119:112] = dram[119] ? 8'b11111111 : {dram[118:112], 1'b0};
        dram_mul_2[111:104] = dram[111] ? 8'b11111111 : {dram[110:104], 1'b0};
        dram_mul_2[103: 96] = dram[103] ? 8'b11111111 : {dram[102: 96], 1'b0};
        dram_mul_2[ 95: 88] = dram[ 95] ? 8'b11111111 : {dram[ 94: 88], 1'b0};
        dram_mul_2[ 87: 80] = dram[ 87] ? 8'b11111111 : {dram[ 86: 80], 1'b0};
        dram_mul_2[ 79: 72] = dram[ 79] ? 8'b11111111 : {dram[ 78: 72], 1'b0};
        dram_mul_2[ 71: 64] = dram[ 71] ? 8'b11111111 : {dram[ 70: 64], 1'b0};
        dram_mul_2[ 63: 56] = dram[ 63] ? 8'b11111111 : {dram[ 62: 56], 1'b0};
        dram_mul_2[ 55: 48] = dram[ 55] ? 8'b11111111 : {dram[ 54: 48], 1'b0};
        dram_mul_2[ 47: 40] = dram[ 47] ? 8'b11111111 : {dram[ 46: 40], 1'b0};
        dram_mul_2[ 39: 32] = dram[ 39] ? 8'b11111111 : {dram[ 38: 32], 1'b0};
        dram_mul_2[ 31: 24] = dram[ 31] ? 8'b11111111 : {dram[ 30: 24], 1'b0};
        dram_mul_2[ 23: 16] = dram[ 23] ? 8'b11111111 : {dram[ 22: 16], 1'b0};
        dram_mul_2[ 15:  8] = dram[ 15] ? 8'b11111111 : {dram[ 14:  8], 1'b0};
        dram_mul_2[  7:  0] = dram[  7] ? 8'b11111111 : {dram[  6:  0], 1'b0};
    end
endfunction

endmodule
