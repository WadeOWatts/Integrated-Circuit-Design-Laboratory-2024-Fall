module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
	in_row,
    in_kernel,
    out_idle,
    handshake_sready,
    handshake_din,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

	fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    out_data,

    flag_clk1_to_fifo,
    flag_fifo_to_clk1
);
input clk;
input rst_n;
input in_valid;
input [17:0] in_row;
input [11:0] in_kernel;
input out_idle;
output reg handshake_sready;
output reg [29:0] handshake_din;
// You can use the the custom flag ports for your design
input  flag_handshake_to_clk1;
output reg flag_clk1_to_handshake;

input fifo_empty;
input [7:0] fifo_rdata;
output reg fifo_rinc;
output reg out_valid;
output reg [7:0] out_data;
// You can use the the custom flag ports for your design
output flag_clk1_to_fifo;
input flag_fifo_to_clk1;


reg [17:0] matrix [0:5];
reg [11:0] kernel [0:5];
reg [2:0] counter_in;
reg [1:0] send_cs, send_ns;
reg hs_been_raised, out_idle_pre, fifo_rinc_pre, fifo_empty_pre;
reg [7:0] out_valid_count;

parameter IDLE = 'b0;
parameter INPUT = 'b1;
parameter SEND = 'd2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        send_cs <= IDLE;
    end else begin
        send_cs <= send_ns;
    end
end

always @(*) begin
    case (send_cs)
        IDLE: send_ns = (in_valid) ? INPUT : IDLE;
        INPUT: send_ns = (~in_valid) ? SEND : INPUT;
        SEND: send_ns = counter_in == 'd6 ? IDLE : SEND;
        default: send_ns = IDLE;
    endcase
end

genvar i;
generate
    for (i = 0; i < 6; i = i + 1) begin: matrix_clk1
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                matrix[i] <= 'd0;
            end else begin
                if (in_valid) begin
                    if (i == 5) begin
                        matrix[i] <= in_row;
                    end else begin
                        matrix[i] <= matrix[i+1];
                    end
                end else begin
                    case (send_cs)
                        SEND: begin
                            if (out_idle && ~out_idle_pre) begin
                                if (i == 5) begin
                                    matrix[i] <= 'd0;
                                end else begin
                                    matrix[i] <= matrix[i+1];
                                end
                            end
                        end
                    endcase
                end
            end
        end
    end
endgenerate

genvar j;
generate
    for (j = 0; j < 6; j = j + 1) begin: kernel_clk1
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                kernel[j] <= 'd0;
            end else begin
                if (in_valid) begin
                    if (j == 5) begin
                        kernel[j] <= in_kernel;
                    end else begin
                        kernel[j] <= kernel[j+1];
                    end
                end else begin
                    case (send_cs)
                        SEND: begin
                            if (out_idle && ~out_idle_pre) begin
                                if (j == 5) begin
                                    kernel[j] <= 'd0;
                                end else begin
                                    kernel[j] <= kernel[j+1];
                                end
                            end
                        end
                    endcase
                end
            end
        end
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter_in <= 'd0;
    end else begin
        case (send_cs)
            IDLE, INPUT: counter_in <= 'd0;
            SEND: begin
                if (out_idle && ~out_idle_pre) begin
                    counter_in <= (counter_in == 'd6) ? counter_in : counter_in + 1;
                end
            end
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        handshake_din <= 'd0;
    end else begin
        case (send_cs)
            IDLE, INPUT: handshake_din <= 'b0;
            SEND: begin
                case (counter_in)
                    'd0, 'd1, 'd2, 'd3, 'd4, 'd5: begin
                        if (out_idle && ~out_idle_pre) begin
                            handshake_din <= {matrix[0], kernel[0]};
                        end
                    end
                    default: handshake_din <= 'b0;
                endcase
            end
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        handshake_sready <= 'b0;
    end else begin
        case (send_cs)
            IDLE, INPUT: handshake_sready <= 'b0;
            SEND: begin
                case (counter_in)
                    'd0, 'd1, 'd2, 'd3, 'd4, 'd5: begin
                        case (handshake_sready)
                            0: handshake_sready <= (out_idle) ? 'b1 : 'b0;
                            1: handshake_sready <= (!flag_handshake_to_clk1 && hs_been_raised) ? 'b0 : 'b1;
                        endcase
                    end
                    default: handshake_sready <= 'b0;
                endcase
            end
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        flag_clk1_to_handshake <= 'b0;
    end else begin
        case (send_cs)
            IDLE, INPUT: flag_clk1_to_handshake <= 'b0;
            SEND: begin
                case (counter_in)
                    'd0, 'd1, 'd2, 'd3, 'd4, 'd5: begin
                        case (flag_clk1_to_handshake)
                            0: flag_clk1_to_handshake <= (!in_valid && out_idle) ? 'b1 : 'b0;
                            1: flag_clk1_to_handshake <= (!flag_handshake_to_clk1 && hs_been_raised) ? 'b0 : 'b1;
                        endcase
                    end
                    default: flag_clk1_to_handshake <= 'b0;
                endcase
            end
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        hs_been_raised <= 'b0;
    end else begin
        case (hs_been_raised)
            0: hs_been_raised <= flag_handshake_to_clk1 ? 'b1 : 'b0;
            1: hs_been_raised <= ~flag_handshake_to_clk1 ? 'b0 : 'b1;
        endcase
    end
end


always @(*) begin
    // case (send_cs)
    //     INPUT: fifo_rinc = 'b0;
        // default: 
        fifo_rinc = (!fifo_empty) ? 'b1 : 'b0;
    // endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fifo_empty_pre <= 'b0;
    end else begin
        fifo_empty_pre <= fifo_empty;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fifo_rinc_pre <= 'b0;
    end else begin
        fifo_rinc_pre <= fifo_rinc;
    end
end


always @(*) begin
    out_data = out_valid ? fifo_rdata : 'd0;
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid <= 'b0;
    end else begin
        if (out_valid_count < 'd150) begin
            out_valid <= fifo_rinc_pre ? 'b1 : 'b0;
        end else begin
            out_valid <= 'b0;
        end        
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid_count <= 'd0;
    end else begin
        case (send_cs)
            SEND: out_valid_count <= 'd0;
            default: begin
                if (out_valid_count < 'd150) begin
                    out_valid_count <= fifo_rinc_pre ? out_valid_count + 'd1 : out_valid_count;
                end
            end
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_idle_pre <= 'b0;
    end else begin
        case (send_cs)
            IDLE, INPUT: out_idle_pre <= 'b0;
            SEND: out_idle_pre <= out_idle;
        endcase
    end
end


endmodule

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    in_data,
    out_valid,
    out_data,
    busy,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [29:0] in_data;
output reg out_valid;
output reg [7:0] out_data;
output reg busy;

input  flag_handshake_to_clk2;
output reg flag_clk2_to_handshake;

input  flag_fifo_to_clk2;
output flag_clk2_to_fifo;

reg [17:0] matrix [0:5];
reg [11:0] kernel [0:5];
reg [5:0] counter_conv;
reg [2:0] counter_in;
reg [1:0] cs, ns;

parameter IDLE = 'd0;
parameter INPUT = 'd1;
parameter SEND = 'd2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cs <= IDLE;
    end else begin
        cs <= ns;
    end
end

always @(*) begin
    case (cs)
        IDLE: ns = (in_valid) ? INPUT : IDLE;
        INPUT: ns = (counter_in == 'd6) ? SEND : INPUT;
        SEND: ns = (counter_in == 'd6 && counter_conv == 'd1) ? IDLE : SEND;
        default: ns = IDLE;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter_conv <= 'd0;
    end else begin
        case (cs)
            SEND: begin
                case (counter_in)
                    'd0: begin
                        if (!flag_fifo_to_clk2) begin
                            counter_conv <= (counter_conv == 'd24) ? 'd0 : counter_conv + 'd1;
                        end
                    end
                    default: begin
                        if (!flag_fifo_to_clk2 && out_valid) begin
                            counter_conv <= (counter_conv == 'd24) ? 'd0 : counter_conv + 'd1;
                        end
                    end
                endcase
            end
            default: counter_conv <= 'd0;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter_in <= 'd0;
    end else begin
        case (ns)
            INPUT: begin
                if (in_valid && ~busy) begin
                    counter_in <= counter_in + 'd1;
                end
            end
            SEND: begin
                if (cs == INPUT) begin
                    counter_in <= 'd0;
                end else begin
                    case (counter_in)
                        0: counter_in <= counter_conv == 'd24 ? counter_in + 'd1 : counter_in;
                        default: counter_in <= (counter_conv == 'd24 && !flag_fifo_to_clk2 && out_valid) ? counter_in + 'd1 : counter_in;
                    endcase
                end
            end 
            default: counter_in <= 'd0;
        endcase
    end
end

genvar i;
generate
    for (i = 0; i < 6; i = i + 1) begin: matrix_clk2
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                matrix[i] <= 'd0;
            end else begin
                case (ns)
                    IDLE: matrix[i] <= 'd0;
                    INPUT: begin
                        if (in_valid && ~busy) begin
                            if (i == 5) begin
                                matrix[i] <= in_data[29:12];
                            end else begin
                                matrix[i] <= matrix[i+1];
                            end
                        end
                    end
                    SEND: begin
                        if (cs == SEND && !flag_fifo_to_clk2) begin
                            case (counter_in)
                                0: begin
                                    case (counter_conv)
                                        'd4, 'd9, 'd14, 'd19: begin
                                            if (i == 5) begin
                                                matrix[i] <= {matrix[0][5:0], matrix[i][17:6]};
                                            end else begin
                                                matrix[i] <= {matrix[i+1][5:0], matrix[i][17:6]};
                                            end
                                        end
                                        'd24: begin
                                            if (i == 4) begin
                                                matrix[i] <= {matrix[0][5:0], matrix[i+1][17:6]};
                                            end else if (i == 5) begin
                                                matrix[i] <= {matrix[1][5:0], matrix[0][17:6]};
                                            end else begin
                                                matrix[i] <= {matrix[i+2][5:0], matrix[i+1][17:6]};
                                            end
                                        end
                                        default: begin
                                            if (i == 5) begin
                                                matrix[i] <= {matrix[0][2:0], matrix[i][17:3]};
                                            end else begin
                                                matrix[i] <= {matrix[i+1][2:0], matrix[i][17:3]};
                                            end
                                        end
                                    endcase
                                end
                                default: begin
                                    if (out_valid) begin
                                        case (counter_conv)
                                            'd4, 'd9, 'd14, 'd19: begin
                                                if (i == 5) begin
                                                    matrix[i] <= {matrix[0][5:0], matrix[i][17:6]};
                                                end else begin
                                                    matrix[i] <= {matrix[i+1][5:0], matrix[i][17:6]};
                                                end
                                            end
                                            'd24: begin
                                                if (i == 4) begin
                                                    matrix[i] <= {matrix[0][5:0], matrix[i+1][17:6]};
                                                end else if (i == 5) begin
                                                    matrix[i] <= {matrix[1][5:0], matrix[0][17:6]};
                                                end else begin
                                                    matrix[i] <= {matrix[i+2][5:0], matrix[i+1][17:6]};
                                                end
                                            end
                                            default: begin
                                                if (i == 5) begin
                                                    matrix[i] <= {matrix[0][2:0], matrix[i][17:3]};
                                                end else begin
                                                    matrix[i] <= {matrix[i+1][2:0], matrix[i][17:3]};
                                                end
                                            end
                                        endcase
                                    end
                                end
                            endcase
                        end
                    end
                endcase
            end
        end
    end
endgenerate

genvar j;
generate
    for (j = 0; j < 6; j = j + 1) begin: kernel_clk1
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                kernel[j] <= 'd0;
            end else begin
                case (ns)
                    IDLE: kernel[j] <= 'd0;
                    INPUT: begin
                        if (in_valid && ~busy) begin
                            if (j == 5) begin
                                kernel[j] <= in_data[11:0];
                            end else begin
                                kernel[j] <= kernel[j+1];
                            end
                        end
                    end 
                    SEND: begin
                        if (!flag_fifo_to_clk2 && out_valid && counter_conv == 'd24) begin
                            if (j == 5) begin
                                kernel[j] <= 'd0;
                            end else begin
                                kernel[j] <= kernel[j+1];
                            end
                        end
                    end
                endcase
            end
        end
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_data <= 'd0;
    end else begin
        case (cs)
            SEND: begin
                if (!flag_fifo_to_clk2) begin
                    case (counter_in)
                        0: out_data <= conv(matrix[0][2:0], matrix[0][5:3], matrix[1][2:0], matrix[1][5:3], kernel[0]);
                        default: out_data <= out_valid ? conv(matrix[0][2:0], matrix[0][5:3], matrix[1][2:0], matrix[1][5:3], kernel[0]) : out_data;
                    endcase
                end
            end
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid <= 'b0;
    end else begin
        case (cs)
            SEND: out_valid <= (!flag_fifo_to_clk2) ? 'b1 : 'b0;
            default: out_valid <= 'd0;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        busy <= 'b0;
    end else begin
        case (busy)
            0: busy <= (in_valid) ? 'b1 : 'b0;
            1: busy <= (~flag_handshake_to_clk2) ? 'b0 : 'b1;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        flag_clk2_to_handshake <= 'b0;
    end else begin
        case (flag_clk2_to_handshake)
            0: flag_clk2_to_handshake <= in_valid ? 'b1 : 'b0;
            1: flag_clk2_to_handshake <= (~flag_handshake_to_clk2) ? 'b0 : 'b1;
        endcase
    end
end

function [7:0] conv;
    input [2:0] m1;
    input [2:0] m2;
    input [2:0] m3;
    input [2:0] m4;
    input [11:0] kernel;

    begin
        conv = ( m1 * kernel[2:0] + m2 * kernel[5:3] ) + ( m3 * kernel[8:6] + m4 * kernel[11:9] );
    end
    
endfunction


endmodule