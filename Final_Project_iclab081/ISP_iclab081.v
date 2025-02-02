module ISP(
    // Input Signals
    input clk,
    input rst_n,
    input in_valid,
    input [3:0] in_pic_no,
    input [1:0] in_mode,
    input [1:0] in_ratio_mode,

    // Output Signals
    output reg  out_valid,
    output [7:0] out_data,
    
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

// Your Design
parameter IDLE = 'd0;
parameter INPUT = 2'd1;
parameter CALC = 2'd2;
parameter OUTPUT = 2'd3;

parameter PIC_SIZE = 'd3072;
parameter BURST_LEN = 'd191;

parameter AUTO_FOCUS = 2'd0;
parameter AUTO_EXP = 2'd1;
parameter AVG_MIN_MAX = 2'd2;

reg [1:0] cs, ns;
reg [3:0] in_pic_no_reg;
reg [1:0] in_mode_reg;
reg [1:0] in_ratio_mode_reg;
reg [127:0] dram_input_temp;
reg [13:0] reg_using [0:5][0:5];
reg [7:0] read_counter;    
reg [7:0] out_reg;
reg [1:0] roll_leftward;
reg [2:0] roll_count;
reg [13:0] diff_temp [0:11];
reg stop_flag;

reg [127:0] exp_cal;
wire [7:0] stage1_max [0:7];
wire [7:0] stage1_min [0:7];
wire [7:0] stage2_max [0:3];
wire [7:0] stage2_min [0:3];
wire [7:0] stage3_max [0:1];
wire [7:0] stage3_min [0:1];
wire [7:0] max_val;
wire [7:0] min_val;
wire [10:0] avg_cal;
wire [17:0] exp_avg;



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
        INPUT: begin
            case (in_mode_reg)
                AUTO_FOCUS: ns = read_counter == 'd166 ? CALC : INPUT;
                AUTO_EXP: ns = read_counter == 'd192 ? CALC : INPUT;
                AVG_MIN_MAX: ns = read_counter == 'd192 ? CALC : INPUT;
                default: ns = IDLE;
            endcase
        end
        CALC: begin
            case (in_mode_reg)
                AUTO_FOCUS: ns = read_counter == 'd192 ? OUTPUT : CALC;
                AUTO_EXP: ns = OUTPUT;                       // NEED MODIFICATION    
                AVG_MIN_MAX: ns = OUTPUT;  
                default: ns = IDLE;
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
        case (arvalid_s_inf)
            0: arvalid_s_inf <= in_valid ? 'b1 : 'b0;
            1: arvalid_s_inf <= arready_s_inf ? 'b0 : 'b1;
        endcase
    end
end


always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        rready_s_inf <= 'b0;
    end else begin
        case (in_mode_reg)
        AUTO_FOCUS, AVG_MIN_MAX: begin
            case (rready_s_inf)
                0: rready_s_inf <= arvalid_s_inf && arready_s_inf ? 'b1 : 'b0;
                1: rready_s_inf <= rlast_s_inf ? 'b0 : 'b1;
            endcase
        end
        AUTO_EXP: begin
            case (stop_flag)
                0: begin
                    case (rready_s_inf)
                        0: rready_s_inf <= arvalid_s_inf && arready_s_inf ? 'b1 : 'b0;
                        1: rready_s_inf <= rvalid_s_inf ? 'b0 : 'b1;
                    endcase
                end
                1: begin
                    case (rready_s_inf)
                        0: rready_s_inf <= roll_count == 'd4 ? 'b1 : 'b0;
                        1: rready_s_inf <= rlast_s_inf ? 'b0 : 'b1;
                    endcase
                end
            endcase
        end
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
            'd0, 'd2: awvalid_s_inf <= 'b0;
            'd1: begin
                case (cs) 
                    INPUT: begin
                        case (awvalid_s_inf)
                            0: awvalid_s_inf <= rvalid_s_inf && !stop_flag ? 'b1 : 'b0;
                            1: awvalid_s_inf <= awready_s_inf ? 'b0 : 'b1;
                        endcase
                    end
                    default: awvalid_s_inf <= 'b0;
                endcase
            end
        endcase
    end
end

assign wdata_s_inf = ~rst_n ? 'd0 : exp_cal;    
                        

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        wlast_s_inf <= 'b0;
    end else begin
        case (wlast_s_inf)
            0: wlast_s_inf <= read_counter == 'd191 ? 'b1 : 'b0;
            1: wlast_s_inf <= 'b0; 
        endcase
    end
end


always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        wvalid_s_inf <= 'b0;
    end else begin
        case (wvalid_s_inf)
            0: wvalid_s_inf <= awready_s_inf ? 'b1 : 'b0;
            1: wvalid_s_inf <= wlast_s_inf ? 'b0 : 'b1;
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
        dram_input_temp <= 'd0;
    end else begin
        case (cs) 
            INPUT: dram_input_temp <= rvalid_s_inf && rready_s_inf ? rdata_s_inf : dram_input_temp;
            default: dram_input_temp <= 'd0;
        endcase
    end
end

genvar i, j;
generate
    for (i = 0; i < 6; i = i + 1) begin
        for (j = 0; j < 6; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if (~rst_n) begin
                    reg_using[i][j] <= 'd0;
                end else begin
                    case (in_mode_reg)
                        AUTO_FOCUS: begin
                            case (cs)
                                IDLE: reg_using[i][j] <= 'd0;
                                INPUT: begin
                                    case (read_counter)
                                        'd27, 'd29, 'd31, 'd33, 'd35, 'd37,
                                        'd155, 'd157, 'd159, 'd161, 'd163, 'd165: begin
                                            if (j == 0 || j == 1 || j == 2) begin
                                                reg_using[i][j] <= reg_using[i][j+3];
                                            end else begin
                                                if (i == 5) begin
                                                    if (j == 3) begin
                                                        reg_using[i][j][7:0] <= reg_using[i-5][j-3][7:0] + {2'b00, dram_input_temp[111:106]};
                                                        reg_using[i][j][13:8] <= 6'd0;
                                                    end else if (j == 4) begin
                                                        reg_using[i][j][7:0] <= reg_using[i-5][j-3][7:0] + {2'b00, dram_input_temp[119:114]};
                                                        reg_using[i][j][13:8] <= 6'd0;
                                                    end else begin
                                                        reg_using[i][j][7:0] <= reg_using[i-5][j-3][7:0] + {2'b00, dram_input_temp[127:122]};
                                                        reg_using[i][j][13:8] <= 6'd0;
                                                    end
                                                end else begin
                                                    reg_using[i][j] <= reg_using[i+1][j-3];
                                                end
                                            end
                                        end

                                        'd28, 'd30, 'd32, 'd34, 'd36, 'd38,
                                        'd156, 'd158, 'd160, 'd162, 'd164, 'd166: begin
                                            if (j == 0 || j == 1 || j == 2) begin
                                                reg_using[i][j] <= reg_using[i][j+3];
                                            end else begin
                                                if (i == 5) begin
                                                    if (j == 3) begin
                                                        reg_using[i][j][7:0] <= reg_using[i-5][j-3][7:0] + {2'b00, dram_input_temp[7:2]};
                                                        reg_using[i][j][13:8] <= 6'd0;
                                                    end else if (j == 4) begin
                                                        reg_using[i][j][7:0] <= reg_using[i-5][j-3][7:0] + {2'b00, dram_input_temp[15:10]};
                                                        reg_using[i][j][13:8] <= 6'd0;
                                                    end else begin
                                                        reg_using[i][j][7:0] <= reg_using[i-5][j-3][7:0] + {2'b00, dram_input_temp[23:18]};
                                                        reg_using[i][j][13:8] <= 6'd0;
                                                    end
                                                end else begin
                                                    reg_using[i][j] <= reg_using[i+1][j-3];
                                                end
                                            end
                                        end

                                        'd91, 'd93, 'd95, 'd97, 'd99, 'd101: begin
                                            if (j == 0 || j == 1 || j == 2) begin
                                                reg_using[i][j] <= reg_using[i][j+3];
                                            end else begin
                                                if (i == 5) begin
                                                    if (j == 3) begin
                                                        reg_using[i][j][7:0] <= reg_using[i-5][j-3][7:0] + {1'b0, dram_input_temp[111:105]};
                                                        reg_using[i][j][13:8] <= 6'd0;
                                                    end else if (j == 4) begin
                                                        reg_using[i][j][7:0] <= reg_using[i-5][j-3][7:0] + {1'b0, dram_input_temp[119:113]};
                                                        reg_using[i][j][13:8] <= 6'd0;
                                                    end else begin
                                                        reg_using[i][j][7:0] <= reg_using[i-5][j-3][7:0] + {1'b0, dram_input_temp[127:121]};
                                                        reg_using[i][j][13:8] <= 6'd0;
                                                    end
                                                end else begin
                                                    reg_using[i][j] <= reg_using[i+1][j-3];
                                                end
                                            end
                                        end

                                        'd92, 'd94, 'd96, 'd98, 'd100, 'd102: begin
                                            if (j == 0 || j == 1 || j == 2) begin
                                                reg_using[i][j] <= reg_using[i][j+3];
                                            end else begin
                                                if (i == 5) begin
                                                    if (j == 3) begin
                                                        reg_using[i][j][7:0] <= reg_using[i-5][j-3][7:0] + {1'b0, dram_input_temp[7:1]};
                                                        reg_using[i][j][13:8] <= 6'd0;
                                                    end else if (j == 4) begin
                                                        reg_using[i][j][7:0] <= reg_using[i-5][j-3][7:0] + {1'b0, dram_input_temp[15:9]};
                                                        reg_using[i][j][13:8] <= 6'd0;
                                                    end else begin
                                                        reg_using[i][j][7:0] <= reg_using[i-5][j-3][7:0] + {1'b0, dram_input_temp[23:17]};
                                                        reg_using[i][j][13:8] <= 6'd0;
                                                    end
                                                end else begin
                                                    reg_using[i][j] <= reg_using[i+1][j-3];
                                                end
                                            end
                                        end
                                    endcase
                                end
                                CALC: begin
                                    case (roll_leftward)
                                        0: begin
                                            if (i == 5) begin
                                                reg_using[i][j] <= reg_using[i-5][j];
                                            end else begin
                                                reg_using[i][j] <= reg_using[i+1][j];
                                            end
                                        end
                                        1: begin
                                            if (j == 5) begin
                                                reg_using[i][j] <= reg_using[i][j-5];
                                            end else begin
                                                reg_using[i][j] <= reg_using[i][j+1];
                                            end
                                        end
                                        2: reg_using[i][j] <= reg_using[i][j];
                                    endcase
                                end
                                OUTPUT: reg_using[i][j] <= reg_using[i][j];
                            endcase
                        end

                        AUTO_EXP: begin
                            case (cs)
                                IDLE: reg_using[i][j] <= 'd0;
                                INPUT: begin
                                    case (wready_s_inf) 
                                        0: reg_using[i][j] <= reg_using[i][j];
                                        1: begin
                                            if (read_counter < 'd65 || read_counter > 'd128) begin
                                                case (i)
                                                    0: begin
                                                        case (j)
                                                            0: reg_using[i][j] <= reg_using[i][j] + {2'b00, exp_cal[127:122]};
                                                            1: reg_using[i][j] <= reg_using[i][j] + {2'b00, exp_cal[119:114]};
                                                            2: reg_using[i][j] <= reg_using[i][j] + {2'b00, exp_cal[111:106]};
                                                            3: reg_using[i][j] <= reg_using[i][j] + {2'b00, exp_cal[103: 98]};
                                                            4: reg_using[i][j] <= reg_using[i][j] + {2'b00, exp_cal[ 95: 90]};
                                                            5: reg_using[i][j] <= reg_using[i][j] + {2'b00, exp_cal[ 87: 82]};
                                                        endcase
                                                    end
                                                    1: begin
                                                        case (j)
                                                            0: reg_using[i][j] <= reg_using[i][j] + {2'b00, exp_cal[ 79: 74]};
                                                            1: reg_using[i][j] <= reg_using[i][j] + {2'b00, exp_cal[ 71: 66]};
                                                            2: reg_using[i][j] <= reg_using[i][j] + {2'b00, exp_cal[ 63: 58]};
                                                            3: reg_using[i][j] <= reg_using[i][j] + {2'b00, exp_cal[ 55: 50]};
                                                            4: reg_using[i][j] <= reg_using[i][j] + {2'b00, exp_cal[ 47: 42]};
                                                            5: reg_using[i][j] <= reg_using[i][j] + {2'b00, exp_cal[ 39: 34]};
                                                        endcase 
                                                    end
                                                    2: begin
                                                        case (j)
                                                            0: reg_using[i][j] <= reg_using[i][j] + {2'b00, exp_cal[ 31: 26]};
                                                            1: reg_using[i][j] <= reg_using[i][j] + {2'b00, exp_cal[ 23: 18]};
                                                            2: reg_using[i][j] <= reg_using[i][j] + {2'b00, exp_cal[ 15: 10]};
                                                            3: reg_using[i][j] <= reg_using[i][j] + {2'b00, exp_cal[  7:  2]};
                                                            default: reg_using[i][j] <= reg_using[i][j];
                                                        endcase
                                                    end
                                                    default: reg_using[i][j] <= reg_using[i][j];
                                                endcase
                                            end else begin
                                                case (i)
                                                    0: begin
                                                        case (j)
                                                            0: reg_using[i][j] <= reg_using[i][j] + {1'b0, exp_cal[127:121]};
                                                            1: reg_using[i][j] <= reg_using[i][j] + {1'b0, exp_cal[119:113]};
                                                            2: reg_using[i][j] <= reg_using[i][j] + {1'b0, exp_cal[111:105]};
                                                            3: reg_using[i][j] <= reg_using[i][j] + {1'b0, exp_cal[103: 97]};
                                                            4: reg_using[i][j] <= reg_using[i][j] + {1'b0, exp_cal[ 95: 89]};
                                                            5: reg_using[i][j] <= reg_using[i][j] + {1'b0, exp_cal[ 87: 81]};
                                                        endcase
                                                    end
                                                    1: begin
                                                        case (j)
                                                            0: reg_using[i][j] <= reg_using[i][j] + {1'b0, exp_cal[ 79: 73]};
                                                            1: reg_using[i][j] <= reg_using[i][j] + {1'b0, exp_cal[ 71: 65]};
                                                            2: reg_using[i][j] <= reg_using[i][j] + {1'b0, exp_cal[ 63: 57]};
                                                            3: reg_using[i][j] <= reg_using[i][j] + {1'b0, exp_cal[ 55: 49]};
                                                            4: reg_using[i][j] <= reg_using[i][j] + {1'b0, exp_cal[ 47: 41]};
                                                            5: reg_using[i][j] <= reg_using[i][j] + {1'b0, exp_cal[ 39: 33]};
                                                        endcase 
                                                    end
                                                    2: begin
                                                        case (j)
                                                            0: reg_using[i][j] <= reg_using[i][j] + {1'b0, exp_cal[ 31: 25]};
                                                            1: reg_using[i][j] <= reg_using[i][j] + {1'b0, exp_cal[ 23: 17]};
                                                            2: reg_using[i][j] <= reg_using[i][j] + {1'b0, exp_cal[ 15:  9]};
                                                            3: reg_using[i][j] <= reg_using[i][j] + {1'b0, exp_cal[  7:  1]};
                                                            default: reg_using[i][j] <= reg_using[i][j];
                                                        endcase
                                                    end
                                                    default: reg_using[i][j] <= reg_using[i][j];
                                                endcase
                                            end
                                        end
                                    endcase
                                end
                                CALC, OUTPUT: reg_using[i][j] <= reg_using[i][j];
                            endcase
                        end

                        AVG_MIN_MAX: begin
                            case (cs)
                                IDLE: reg_using[i][j] <= 'd0;
                                INPUT: begin
                                    if (i == 0) begin
                                        if (j == 0) begin
                                            if (read_counter > 'd0 && read_counter < 'd65) begin
                                                reg_using[i][j][7:0] <= max_val > reg_using[i][j][7:0] ? max_val : reg_using[i][j][7:0];
                                            end
                                        end else if (j == 1) begin
                                            if (read_counter > 'd0 && read_counter < 'd65) begin
                                                reg_using[i][j][7:0] <= min_val < reg_using[i][j][7:0] ? min_val : reg_using[i][j][7:0];
                                            end
                                        end else if (j == 2) begin
                                            if (read_counter > 'd64 && read_counter < 'd129) begin
                                                reg_using[i][j][7:0] <= max_val > reg_using[i][j][7:0] ? max_val : reg_using[i][j][7:0];
                                            end 
                                        end else if (j == 3) begin
                                            if (read_counter > 'd64 && read_counter < 'd129) begin
                                                reg_using[i][j][7:0] <= min_val < reg_using[i][j][7:0] ? min_val : reg_using[i][j][7:0];
                                            end
                                        end else if (j == 4) begin
                                            if (read_counter > 'd128 && read_counter < 'd193) begin
                                                reg_using[i][j][7:0] <= max_val > reg_using[i][j][7:0] ? max_val : reg_using[i][j][7:0];
                                            end 
                                        end else if (j == 5) begin
                                            if (read_counter > 'd128 && read_counter < 'd193) begin
                                                reg_using[i][j][7:0] <= min_val < reg_using[i][j][7:0] ? min_val : reg_using[i][j][7:0];
                                            end
                                        end
                                    end
                                end
                                CALC, OUTPUT: reg_using[i][j] <= reg_using[i][j];
                            endcase
                        end

                        default: reg_using[i][j] <= 'd0;
                    endcase
                end
            end
        end
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        roll_leftward <= 'b0;
    end else begin
        case (in_mode_reg)
            AUTO_FOCUS: begin
                case (cs) 
                    CALC: begin
                        case (roll_leftward)
                            0: roll_leftward <= roll_count == 'd5 ? 'd1 : 'd0;
                            1: roll_leftward <= roll_count == 'd5 ? 'd2 : 'd1;
                            2: roll_leftward <= roll_count == 'd5 ? 'd3 : 'd2;
                            3: roll_leftward <= 'd3;
                        endcase
                    end
                    default: roll_leftward <= 'd0;
                endcase
            end
            default: roll_leftward <= 'b0;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        roll_count <= 'd0;
    end else begin
        case (in_mode_reg)
            AUTO_FOCUS: begin
                case (cs)
                    CALC: roll_count <= roll_count == 'd5 ? 'd0 : roll_count + 'd1;
                    default: roll_count <= 'd0;
                endcase
            end
            AUTO_EXP: begin
                case (stop_flag)
                    0: roll_count <= 'b0;
                    1: roll_count <= roll_count < 'd6 ? roll_count + 'd1 : roll_count;
                endcase
            end
            default: roll_count <= 'd0;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        stop_flag <= 'b0;
    end else begin
        case (cs)
            IDLE: stop_flag <= 'b0;
            INPUT: begin
                case (stop_flag)
                    0: stop_flag <= rvalid_s_inf ? 'b1 : 'b0;
                    1: stop_flag <= 'b1;
                endcase
            end
            CALC, OUTPUT: stop_flag <= stop_flag;
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

genvar k;
generate 
    for (k = 0; k < 12; k = k + 1) begin
        always @(posedge clk or negedge rst_n) begin
            if (~rst_n) begin
                diff_temp[k] <= 'd0;
            end else begin
                case (in_mode_reg)
                    AUTO_FOCUS: begin
                        case (cs)
                            IDLE, INPUT: diff_temp[k] <= 'd0;
                            CALC: begin
                                case (roll_leftward)
                                    0: begin
                                        case (k)
                                            0: begin
                                                case (roll_count)
                                                    'd0, 'd1, 'd2, 'd3, 'd4: diff_temp[k] <= reg_using[0][0][7:0] > reg_using[1][0][7:0] ? diff_temp[k] + (reg_using[0][0][7:0] - reg_using[1][0][7:0]) : diff_temp[k] + (reg_using[1][0][7:0] - reg_using[0][0][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            1: begin
                                                case (roll_count)
                                                    'd0, 'd1, 'd2, 'd3, 'd4: diff_temp[k] <= reg_using[0][1][7:0] > reg_using[1][1][7:0] ? diff_temp[k] + (reg_using[0][1][7:0] - reg_using[1][1][7:0]) : diff_temp[k] + (reg_using[1][1][7:0] - reg_using[0][1][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            2: begin
                                                case (roll_count)
                                                    'd0, 'd1, 'd2, 'd3, 'd4: diff_temp[k] <= reg_using[0][2][7:0] > reg_using[1][2][7:0] ? diff_temp[k] + (reg_using[0][2][7:0] - reg_using[1][2][7:0]) : diff_temp[k] + (reg_using[1][2][7:0] - reg_using[0][2][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            3: begin
                                                case (roll_count)
                                                    'd0, 'd1, 'd2, 'd3, 'd4: diff_temp[k] <= reg_using[0][3][7:0] > reg_using[1][3][7:0] ? diff_temp[k] + (reg_using[0][3][7:0] - reg_using[1][3][7:0]) : diff_temp[k] + (reg_using[1][3][7:0] - reg_using[0][3][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            4: begin
                                                case (roll_count)
                                                    'd0, 'd1, 'd2, 'd3, 'd4: diff_temp[k] <= reg_using[0][4][7:0] > reg_using[1][4][7:0] ? diff_temp[k] + (reg_using[0][4][7:0] - reg_using[1][4][7:0]) : diff_temp[k] + (reg_using[1][4][7:0] - reg_using[0][4][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            5: begin
                                                case (roll_count)
                                                    'd0, 'd1, 'd2, 'd3, 'd4: diff_temp[k] <= reg_using[0][5][7:0] > reg_using[1][5][7:0] ? diff_temp[k] + (reg_using[0][5][7:0] - reg_using[1][5][7:0]) : diff_temp[k] + (reg_using[1][5][7:0] - reg_using[0][5][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            6: begin
                                                case (roll_count)
                                                    'd1, 'd2, 'd3: diff_temp[k] <= reg_using[0][1][7:0] > reg_using[1][1][7:0] ? diff_temp[k] + (reg_using[0][1][7:0] - reg_using[1][1][7:0]) : diff_temp[k] + (reg_using[1][1][7:0] - reg_using[0][1][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            7: begin
                                                case (roll_count)
                                                    'd1, 'd2, 'd3: diff_temp[k] <= reg_using[0][2][7:0] > reg_using[1][2][7:0] ? diff_temp[k] + (reg_using[0][2][7:0] - reg_using[1][2][7:0]) : diff_temp[k] + (reg_using[1][2][7:0] - reg_using[0][2][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            8: begin
                                                case (roll_count)
                                                'd1, 'd2, 'd3: diff_temp[k] <= reg_using[0][3][7:0] > reg_using[1][3][7:0] ? diff_temp[k] + (reg_using[0][3][7:0] - reg_using[1][3][7:0]) : diff_temp[k] + (reg_using[1][3][7:0] - reg_using[0][3][7:0]);
                                                default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            9: begin
                                                case (roll_count)
                                                    'd1, 'd2, 'd3: diff_temp[k] <= reg_using[0][4][7:0] > reg_using[1][4][7:0] ? diff_temp[k] + (reg_using[0][4][7:0] - reg_using[1][4][7:0]) : diff_temp[k] + (reg_using[1][4][7:0] - reg_using[0][4][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            10: begin
                                                case (roll_count)
                                                    'd2: diff_temp[k] <= reg_using[0][2][7:0] > reg_using[1][2][7:0] ? diff_temp[k] + (reg_using[0][2][7:0] - reg_using[1][2][7:0]) : diff_temp[k] + (reg_using[1][2][7:0] - reg_using[0][2][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            11: begin
                                                case (roll_count)
                                                    'd2: diff_temp[k] <= reg_using[0][3][7:0] > reg_using[1][3][7:0] ? diff_temp[k] + (reg_using[0][3][7:0] - reg_using[1][3][7:0]) : diff_temp[k] + (reg_using[1][3][7:0] - reg_using[0][3][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                        endcase
                                    end
                                    1: begin
                                        case (k) 
                                            0: begin
                                                case (roll_count)
                                                    'd0, 'd1, 'd2, 'd3, 'd4: diff_temp[k] <= reg_using[0][0][7:0] > reg_using[0][1][7:0] ? diff_temp[k] + (reg_using[0][0][7:0] - reg_using[0][1][7:0]) : diff_temp[k] + (reg_using[0][1][7:0] - reg_using[0][0][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            1: begin
                                                case (roll_count)
                                                    'd0, 'd1, 'd2, 'd3, 'd4: diff_temp[k] <= reg_using[1][0][7:0] > reg_using[1][1][7:0] ? diff_temp[k] + (reg_using[1][0][7:0] - reg_using[1][1][7:0]) : diff_temp[k] + (reg_using[1][1][7:0] - reg_using[1][0][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            2: begin
                                                case (roll_count)
                                                    'd0, 'd1, 'd2, 'd3, 'd4: diff_temp[k] <= reg_using[2][0][7:0] > reg_using[2][1][7:0] ? diff_temp[k] + (reg_using[2][0][7:0] - reg_using[2][1][7:0]) : diff_temp[k] + (reg_using[2][1][7:0] - reg_using[2][0][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            3: begin
                                                case (roll_count)
                                                    'd0, 'd1, 'd2, 'd3, 'd4: diff_temp[k] <= reg_using[3][0][7:0] > reg_using[3][1][7:0] ? diff_temp[k] + (reg_using[3][0][7:0] - reg_using[3][1][7:0]) : diff_temp[k] + (reg_using[3][1][7:0] - reg_using[3][0][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            4: begin
                                                case (roll_count)
                                                    'd0, 'd1, 'd2, 'd3, 'd4: diff_temp[k] <= reg_using[4][0][7:0] > reg_using[4][1][7:0] ? diff_temp[k] + (reg_using[4][0][7:0] - reg_using[4][1][7:0]) : diff_temp[k] + (reg_using[4][1][7:0] - reg_using[4][0][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            5: begin
                                                case (roll_count)
                                                    'd0, 'd1, 'd2, 'd3, 'd4: diff_temp[k] <= reg_using[5][0][7:0] > reg_using[5][1][7:0] ? diff_temp[k] + (reg_using[5][0][7:0] - reg_using[5][1][7:0]) : diff_temp[k] + (reg_using[5][1][7:0] - reg_using[5][0][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            6: begin
                                                case (roll_count)
                                                    'd1, 'd2, 'd3: diff_temp[k] <= reg_using[1][0][7:0] > reg_using[1][1][7:0] ? diff_temp[k] + (reg_using[1][0][7:0] - reg_using[1][1][7:0]) : diff_temp[k] + (reg_using[1][1][7:0] - reg_using[1][0][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            7: begin
                                                case (roll_count)
                                                    'd1, 'd2, 'd3: diff_temp[k] <= reg_using[2][0][7:0] > reg_using[2][1][7:0] ? diff_temp[k] + (reg_using[2][0][7:0] - reg_using[2][1][7:0]) : diff_temp[k] + (reg_using[2][1][7:0] - reg_using[2][0][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            8: begin
                                                case (roll_count)
                                                    'd1, 'd2, 'd3: diff_temp[k] <= reg_using[3][0][7:0] > reg_using[3][1][7:0] ? diff_temp[k] + (reg_using[3][0][7:0] - reg_using[3][1][7:0]) : diff_temp[k] + (reg_using[3][1][7:0] - reg_using[3][0][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            9: begin
                                                case (roll_count)
                                                    'd1, 'd2, 'd3: diff_temp[k] <= reg_using[4][0][7:0] > reg_using[4][1][7:0] ? diff_temp[k] + (reg_using[4][0][7:0] - reg_using[4][1][7:0]) : diff_temp[k] + (reg_using[4][1][7:0] - reg_using[4][0][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            10: begin
                                                case (roll_count)
                                                    'd2: diff_temp[k] <= reg_using[2][0][7:0] > reg_using[2][1][7:0] ? diff_temp[k] + (reg_using[2][0][7:0] - reg_using[2][1][7:0]) : diff_temp[k] + (reg_using[2][1][7:0] - reg_using[2][0][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            11: begin
                                                case (roll_count)
                                                    'd2: diff_temp[k] <= reg_using[3][0][7:0] > reg_using[3][1][7:0] ? diff_temp[k] + (reg_using[3][0][7:0] - reg_using[3][1][7:0]) : diff_temp[k] + (reg_using[3][1][7:0] - reg_using[3][0][7:0]);
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end                                            
                                        endcase
                                    end
                                    2: begin
                                        case (roll_count)
                                            0: begin
                                                case (k)
                                                    'd0, 'd2, 'd4, 'd6, 'd8, 'd10: diff_temp[k] <= diff_temp[k] + diff_temp[k+1];
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            1: begin
                                                case (k) 
                                                    'd0, 'd6: diff_temp[k] <= diff_temp[k] + diff_temp[k+2];
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            2: begin
                                                case (k)
                                                    'd0: diff_temp[k] <= diff_temp[k] + diff_temp[k+4];
                                                    default: diff_temp[k] <= diff_temp[k];
                                                endcase
                                            end
                                            3: begin
                                                case (k)
                                                    'd0: diff_temp[k] <= diff_temp[k] / 36;
                                                    'd6: diff_temp[k] <= {4'b0000, diff_temp[k][13:4]};
                                                    'd10: diff_temp[k] <= {2'b00, diff_temp[k][13:2]};
                                                endcase
                                            end
                                            default: diff_temp[k] <= diff_temp[k];
                                        endcase
                                    end
                                endcase
                            end
                        endcase
                    end

                    AVG_MIN_MAX: begin
                        case (cs)
                            IDLE: diff_temp[k] <= 'd0;
                            INPUT: begin
                                if (k == 0) begin
                                    if (read_counter == 'd65) begin
                                        diff_temp[k][8:0] <= reg_using[0][0][7:0] + reg_using[0][1][7:0];
                                    end else if (read_counter == 'd129) begin
                                        diff_temp[k][9:0] <= diff_temp[k][8:0] + (reg_using[0][2][7:0] + reg_using[0][3][7:0]);
                                    end
                                end
                            end
                            CALC, OUTPUT: diff_temp[k] <= diff_temp[k];
                        endcase
                    end
                endcase
            end
        end
    end
endgenerate

always @(*) begin
    case (in_mode_reg)
        AUTO_FOCUS, AVG_MIN_MAX: exp_cal = 'd0;
        AUTO_EXP: begin
            case (in_ratio_mode_reg)
                0: exp_cal = {2'b00, dram_input_temp[127:122], 
                              2'b00, dram_input_temp[119:114],
                              2'b00, dram_input_temp[111:106],
                              2'b00, dram_input_temp[103: 98],
                              2'b00, dram_input_temp[ 95: 90],
                              2'b00, dram_input_temp[ 87: 82],
                              2'b00, dram_input_temp[ 79: 74],
                              2'b00, dram_input_temp[ 71: 66],
                              2'b00, dram_input_temp[ 63: 58],
                              2'b00, dram_input_temp[ 55: 50],
                              2'b00, dram_input_temp[ 47: 42],
                              2'b00, dram_input_temp[ 39: 34],
                              2'b00, dram_input_temp[ 31: 26],
                              2'b00, dram_input_temp[ 23: 18],
                              2'b00, dram_input_temp[ 15: 10],
                              2'b00, dram_input_temp[  7:  2]};
                1: exp_cal = {1'b0, dram_input_temp[127:121], 
                              1'b0, dram_input_temp[119:113],
                              1'b0, dram_input_temp[111:105],
                              1'b0, dram_input_temp[103: 97],
                              1'b0, dram_input_temp[ 95: 89],
                              1'b0, dram_input_temp[ 87: 81],
                              1'b0, dram_input_temp[ 79: 73],
                              1'b0, dram_input_temp[ 71: 65],
                              1'b0, dram_input_temp[ 63: 57],
                              1'b0, dram_input_temp[ 55: 49],
                              1'b0, dram_input_temp[ 47: 41],
                              1'b0, dram_input_temp[ 39: 33],
                              1'b0, dram_input_temp[ 31: 25],
                              1'b0, dram_input_temp[ 23: 17],
                              1'b0, dram_input_temp[ 15:  9],
                              1'b0, dram_input_temp[  7:  1]};
                2: exp_cal = dram_input_temp;
                3: begin
                    exp_cal[127:120] = dram_input_temp[127] ? 8'b11111111 : {dram_input_temp[126:120], 1'b0};
                    exp_cal[119:112] = dram_input_temp[119] ? 8'b11111111 : {dram_input_temp[118:112], 1'b0};
                    exp_cal[111:104] = dram_input_temp[111] ? 8'b11111111 : {dram_input_temp[110:104], 1'b0};
                    exp_cal[103: 96] = dram_input_temp[103] ? 8'b11111111 : {dram_input_temp[102: 96], 1'b0};
                    exp_cal[ 95: 88] = dram_input_temp[ 95] ? 8'b11111111 : {dram_input_temp[ 94: 88], 1'b0};
                    exp_cal[ 87: 80] = dram_input_temp[ 87] ? 8'b11111111 : {dram_input_temp[ 86: 80], 1'b0};
                    exp_cal[ 79: 72] = dram_input_temp[ 79] ? 8'b11111111 : {dram_input_temp[ 78: 72], 1'b0};
                    exp_cal[ 71: 64] = dram_input_temp[ 71] ? 8'b11111111 : {dram_input_temp[ 70: 64], 1'b0};
                    exp_cal[ 63: 56] = dram_input_temp[ 63] ? 8'b11111111 : {dram_input_temp[ 62: 56], 1'b0};
                    exp_cal[ 55: 48] = dram_input_temp[ 55] ? 8'b11111111 : {dram_input_temp[ 54: 48], 1'b0};
                    exp_cal[ 47: 40] = dram_input_temp[ 47] ? 8'b11111111 : {dram_input_temp[ 46: 40], 1'b0};
                    exp_cal[ 39: 32] = dram_input_temp[ 39] ? 8'b11111111 : {dram_input_temp[ 38: 32], 1'b0};
                    exp_cal[ 31: 24] = dram_input_temp[ 31] ? 8'b11111111 : {dram_input_temp[ 30: 24], 1'b0};
                    exp_cal[ 23: 16] = dram_input_temp[ 23] ? 8'b11111111 : {dram_input_temp[ 22: 16], 1'b0};
                    exp_cal[ 15:  8] = dram_input_temp[ 15] ? 8'b11111111 : {dram_input_temp[ 14:  8], 1'b0};
                    exp_cal[  7:  0] = dram_input_temp[  7] ? 8'b11111111 : {dram_input_temp[  6:  0], 1'b0};
                end
            endcase
        end
        default: exp_cal = 'd0;
    endcase
end


assign stage1_max[0] = (dram_input_temp[127:120] > dram_input_temp[119:112]) ? dram_input_temp[127:120] : dram_input_temp[119:112];
assign stage1_max[1] = (dram_input_temp[111:104] > dram_input_temp[103: 96]) ? dram_input_temp[111:104] : dram_input_temp[103: 96];
assign stage1_max[2] = (dram_input_temp[ 95: 88] > dram_input_temp[ 87: 80]) ? dram_input_temp[ 95: 88] : dram_input_temp[ 87: 80];
assign stage1_max[3] = (dram_input_temp[ 79: 72] > dram_input_temp[ 71: 64]) ? dram_input_temp[ 79: 72] : dram_input_temp[ 71: 64];
assign stage1_max[4] = (dram_input_temp[ 63: 56] > dram_input_temp[ 55: 48]) ? dram_input_temp[ 63: 56] : dram_input_temp[ 55: 48];
assign stage1_max[5] = (dram_input_temp[ 47: 40] > dram_input_temp[ 39: 32]) ? dram_input_temp[ 47: 40] : dram_input_temp[ 39: 32];
assign stage1_max[6] = (dram_input_temp[ 31: 24] > dram_input_temp[ 23: 16]) ? dram_input_temp[ 31: 24] : dram_input_temp[ 23: 16];
assign stage1_max[7] = (dram_input_temp[ 15:  8] > dram_input_temp[  7:  0]) ? dram_input_temp[ 15:  8] : dram_input_temp[  7:  0];

assign stage1_min[0] = (dram_input_temp[127:120] < dram_input_temp[119:112]) ? dram_input_temp[127:120] : dram_input_temp[119:112];
assign stage1_min[1] = (dram_input_temp[111:104] < dram_input_temp[103: 96]) ? dram_input_temp[111:104] : dram_input_temp[103: 96];
assign stage1_min[2] = (dram_input_temp[ 95: 88] < dram_input_temp[ 87: 80]) ? dram_input_temp[ 95: 88] : dram_input_temp[ 87: 80];
assign stage1_min[3] = (dram_input_temp[ 79: 72] < dram_input_temp[ 71: 64]) ? dram_input_temp[ 79: 72] : dram_input_temp[ 71: 64];
assign stage1_min[4] = (dram_input_temp[ 63: 56] < dram_input_temp[ 55: 48]) ? dram_input_temp[ 63: 56] : dram_input_temp[ 55: 48];
assign stage1_min[5] = (dram_input_temp[ 47: 40] < dram_input_temp[ 39: 32]) ? dram_input_temp[ 47: 40] : dram_input_temp[ 39: 32];
assign stage1_min[6] = (dram_input_temp[ 31: 24] < dram_input_temp[ 23: 16]) ? dram_input_temp[ 31: 24] : dram_input_temp[ 23: 16];
assign stage1_min[7] = (dram_input_temp[ 15:  8] < dram_input_temp[  7:  0]) ? dram_input_temp[ 15:  8] : dram_input_temp[  7:  0];

assign stage2_max[0] = (stage1_max[0] > stage1_max[1]) ? stage1_max[0] : stage1_max[1];
assign stage2_max[1] = (stage1_max[2] > stage1_max[3]) ? stage1_max[2] : stage1_max[3];
assign stage2_max[2] = (stage1_max[4] > stage1_max[5]) ? stage1_max[4] : stage1_max[5];
assign stage2_max[3] = (stage1_max[6] > stage1_max[7]) ? stage1_max[6] : stage1_max[7];

assign stage2_min[0] = (stage1_min[0] < stage1_min[1]) ? stage1_min[0] : stage1_min[1];
assign stage2_min[1] = (stage1_min[2] < stage1_min[3]) ? stage1_min[2] : stage1_min[3];
assign stage2_min[2] = (stage1_min[4] < stage1_min[5]) ? stage1_min[4] : stage1_min[5];
assign stage2_min[3] = (stage1_min[6] < stage1_min[7]) ? stage1_min[6] : stage1_min[7];

assign stage3_max[0] = (stage2_max[0] > stage2_max[1]) ? stage2_max[0] : stage2_max[1];
assign stage3_max[1] = (stage2_max[2] > stage2_max[3]) ? stage2_max[2] : stage2_max[3];

assign stage3_min[0] = (stage2_min[0] < stage2_min[1]) ? stage2_min[0] : stage2_min[1];
assign stage3_min[1] = (stage2_min[2] < stage2_min[3]) ? stage2_min[2] : stage2_min[3];

assign max_val = stage3_max[0] > stage3_max[1] ? stage3_max[0] : stage3_max[1];
assign min_val = stage3_min[0] < stage3_min[1] ? stage3_min[0] : stage3_min[1];

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        out_valid <= 'b0;
    end else begin
        out_valid <= ns == OUTPUT ? 'b1 : 'b0;
    end
end

assign out_data = out_valid ? out_reg : 'd0;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        out_reg <= 'd0;
    end else begin
        case (in_mode_reg)
            AUTO_FOCUS: begin
                case (cs)
                    IDLE, INPUT: out_reg <= 'd0;
                    CALC: begin
                        if (roll_count == 'd4 && roll_leftward == 'd2) begin
                            if (diff_temp[10] >= diff_temp[0] && diff_temp[10] >= diff_temp[6]) begin
                                out_reg <= 'd0;
                            end else if (diff_temp[10] < diff_temp[6] && diff_temp[6] >= diff_temp[0]) begin
                                out_reg <= 'd1;
                            end else begin
                                out_reg <= 'd2;
                            end
                        end else begin
                            out_reg <= out_reg;
                        end
                    end
                    OUTPUT: out_reg <= out_reg;
                endcase
            end
            AUTO_EXP: begin
                case (cs)
                    IDLE, INPUT: out_reg <= 'd0;
                    CALC: out_reg <= exp_avg[17:10];
                    OUTPUT: out_reg <= out_reg;
                endcase
            end
            AVG_MIN_MAX: begin
                case(cs)
                    IDLE, INPUT: out_reg <= 'd0;
                    CALC: begin
                        out_reg <= avg_cal[10:1] / 3;
                    end
                    OUTPUT: out_reg <= out_reg;
                endcase
            end
        endcase
    end
end

assign avg_cal = diff_temp[0][9:0] + (reg_using[0][4][7:0] + reg_using[0][5][7:0]);
assign exp_avg = in_mode_reg == AUTO_EXP && cs == CALC ? 
                 (((reg_using[0][0] + reg_using[0][1]) + (reg_using[0][2] + reg_using[0][3])) +
                 ((reg_using[0][4] + reg_using[0][5]) + (reg_using[1][0] + reg_using[1][1]))) +
                 (((reg_using[1][2] + reg_using[1][3]) + (reg_using[1][4] + reg_using[1][5])) +
                 ((reg_using[2][0] + reg_using[2][1]) + (reg_using[2][2] + reg_using[2][3]))) : 'd0;

endmodule
