module FIFO_syn #(parameter WIDTH=8, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo,

    flag_fifo_to_clk1,
	flag_clk1_to_fifo
);

input wclk, rclk;
input rst_n;
input winc;
input [WIDTH-1:0] wdata;
output reg wfull;
input rinc;
output [WIDTH-1:0] rdata;
output rempty;

// You can change the input / output of the custom flag ports
output reg flag_fifo_to_clk2;
input flag_clk2_to_fifo;

output flag_fifo_to_clk1;
input flag_clk1_to_fifo;

wire [WIDTH-1:0] rdata_q;

// Remember: 
//   wptr and rptr should be gray coded
//   Don't modify the signal name
reg [$clog2(WORDS):0] wptr;
reg [$clog2(WORDS):0] rptr;

reg oeb;
reg rinc_pre, rempty_pre, rinc_pre2;
wire [5:0] waddr, raddr;
reg [WIDTH-1:0] rdata_reg;
wire [$clog2(WORDS):0] gray_to_binary_wptr, gray_to_binary_rptr_w;
wire [WIDTH-1:0] w_out, r_in;
wire wean, webn, oea;
wire csa, csb;
wire [7:0] rptr_w, wptr_r, rptr_r, wptr_w;

DUAL_64X8X1BM1 u_dual_sram (.A0(waddr[0]), .A1(waddr[1]), .A2(waddr[2]), .A3(waddr[3]), .A4(waddr[4]), .A5(waddr[5]), 
                    .B0(raddr[0]), .B1(raddr[1]), .B2(raddr[2]), .B3(raddr[3]), .B4(raddr[4]), .B5(raddr[5]),
                    .DOA0(w_out[0]), .DOA1(w_out[1]), .DOA2(w_out[2]), .DOA3(w_out[3]), .DOA4(w_out[4]), .DOA5(w_out[5]), .DOA6(w_out[6]), .DOA7(w_out[7]),
                    .DOB0(rdata_q[0]), .DOB1(rdata_q[1]), .DOB2(rdata_q[2]), .DOB3(rdata_q[3]), .DOB4(rdata_q[4]), .DOB5(rdata_q[5]), .DOB6(rdata_q[6]), .DOB7(rdata_q[7]),
                    .DIA0(wdata[0]), .DIA1(wdata[1]), .DIA2(wdata[2]), .DIA3(wdata[3]), .DIA4(wdata[4]), .DIA5(wdata[5]), .DIA6(wdata[6]), .DIA7(wdata[7]),
                    .DIB0(r_in[0]), .DIB1(r_in[1]), .DIB2(r_in[2]), .DIB3(r_in[3]), .DIB4(r_in[4]), .DIB5(r_in[5]), .DIB6(r_in[6]), .DIB7(r_in[7]),
                    .WEAN(wean), .WEBN(webn), .CKA(wclk), .CKB(rclk), .CSA(csa), .CSB(csb), .OEA(oea), .OEB(oeb));

NDFF_BUS_syn r_to_w (.D(rptr_r), .Q(rptr_w), .clk(wclk), .rst_n(rst_n));
NDFF_BUS_syn w_to_r (.D(wptr_w), .Q(wptr_r), .clk(rclk), .rst_n(rst_n));

assign wean = 'b0;
assign webn = 'b1;
assign oea = 'b1;
assign r_in = 'bx;
assign rempty = (wptr_r == rptr) ? 'b1 : 'b0;
assign rptr_r = {0, rptr};
assign wptr_w = {0, wptr};

assign gray_to_binary_wptr = gray_to_binary(wptr);
assign gray_to_binary_rptr_w = gray_to_binary(rptr_w);

always @(*) begin
    if ( gray_to_binary_rptr_w > gray_to_binary_wptr) begin
        flag_fifo_to_clk2 = (gray_to_binary_rptr_w - gray_to_binary_wptr < 'd78) ? 'b1 : 'b0;
    end else begin
        flag_fifo_to_clk2 = (gray_to_binary_wptr - gray_to_binary_rptr_w > 'd50) ? 'b1 : 'b0;
    end
end

always @(*) begin
    if ( gray_to_binary_rptr_w > gray_to_binary_wptr) begin
        wfull = (gray_to_binary_rptr_w - gray_to_binary_wptr < 'd66) ? 'b1 : 'b0;
    end else begin
        wfull = (gray_to_binary_wptr - gray_to_binary_rptr_w > 'd62) ? 'b1 : 'b0;
    end
end

function [$clog2(WORDS):0] gray_to_binary;
    input [$clog2(WORDS):0] gray;
    integer i;
    begin
        gray_to_binary[$clog2(WORDS)] = gray[$clog2(WORDS)]; // MSB remains the same
        for (i = $clog2(WORDS) - 1; i >= 0; i = i - 1) begin
            gray_to_binary[i] = gray_to_binary[i + 1] ^ gray[i];
        end
    end
endfunction

assign waddr = gray_to_binary(wptr);
assign raddr = gray_to_binary(rptr);



// always @(posedge wclk or negedge rst_n) begin
//     if (!rst_n) begin
//         waddr <= 'd0;
//     end else begin
//         if (!wfull && winc) begin
//             if (waddr == 'd149) begin
//                 waddr <= 'd0;
//             end else begin
//                 waddr <= waddr + 1;
//             end
//         end
//     end
// end

always @(posedge wclk or negedge rst_n) begin
    if (!rst_n) begin
        wptr <= 8'b0; 
    end else begin
        if (!flag_fifo_to_clk2 && winc) begin
            wptr <= gray_code_next(wptr);
        end
    end
end

function [$clog2(WORDS):0] gray_code_next;
    input [$clog2(WORDS):0] gray;
    reg parity;
    integer j;
    begin
        if (gray == 'b1000000) begin
            gray_code_next = 'b0000000;
        end else begin
            parity = ^gray;
            case (parity)
                0: gray_code_next = {gray[6:1], ~gray[0]};
                1: begin
                    gray_code_next = gray;
                    for (j = 0; j < $clog2(WORDS); j = j + 1) begin
                        if (gray[j]) begin
                            gray_code_next[j+1] = ~gray_code_next[j+1];
                            break;
                        end
                    end
                end
            endcase
        end
    end
endfunction

// always @(*) begin
//     wptr[6] = 'b0;
//     wptr[5] = waddr[5];
//     wptr[4] = waddr[5] ^ waddr[4];
//     wptr[3] = waddr[4] ^ waddr[3];
//     wptr[2] = waddr[3] ^ waddr[2];
//     wptr[1] = waddr[2] ^ waddr[1];
//     wptr[0] = waddr[1] ^ waddr[0];
// end

// always @(*) begin
//     wptr[6] = 'b0;
//     wptr[5] = waddr[5];
//     wptr[4] = wptr[5] ^ waddr[4];
//     wptr[3] = wptr[4] ^ waddr[3];
//     wptr[2] = wptr[3] ^ waddr[2];
//     wptr[1] = wptr[2] ^ waddr[1];
//     wptr[0] = wptr[1] ^ waddr[0];
// end

// always @(posedge rclk or negedge rst_n) begin
//     if (!rst_n) begin
//         raddr <= 'd0;
//     end else begin
//         if (!rempty && rinc) begin
//             if (raddr == 'd149) begin
//                 raddr <= 'd0;
//             end else begin
//                 raddr <= raddr + 'd1;
//             end
//         end
//     end
// end

always @(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
        rptr <= 'd0;
    end else begin
        if (!rempty && rinc) begin
            rptr <= gray_code_next(rptr);
        end
    end
end

// always @(*) begin
//     rptr[6] = 'b0;
//     rptr[5] = raddr[5];
//     rptr[4] = raddr[5] ^ raddr[4];
//     rptr[3] = raddr[4] ^ raddr[3];
//     rptr[2] = raddr[3] ^ raddr[2];
//     rptr[1] = raddr[2] ^ raddr[1];
//     rptr[0] = raddr[1] ^ raddr[0];
// end

// always @(*) begin
//     rptr[6] = 'b0;
//     rptr[5] = raddr[5];
//     rptr[4] = rptr[5] ^ raddr[4];
//     rptr[3] = rptr[4] ^ raddr[3];
//     rptr[2] = rptr[3] ^ raddr[2];
//     rptr[1] = rptr[2] ^ raddr[1];
//     rptr[0] = rptr[1] ^ raddr[0];
// end

always @(*) begin
    if (!rempty_pre) begin
        oeb = (rinc_pre) ? 'b1 : 'b0;
    end else begin
        oeb = 'b0;
    end
end

always @(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
        rempty_pre <= 'b1;
    end else begin
        rempty_pre <= rempty;
    end
end

always @(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
        rinc_pre <= 'b0;
    end else begin
        rinc_pre <= rinc;
    end
end

always @(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
        rinc_pre2 <= 'b0;
    end else begin
        rinc_pre2 <= rinc_pre;
    end
end

assign csa = (winc && !flag_fifo_to_clk2) ? 'b1 : 'b0;
assign csb = (rinc) ? 'b1 : 'b0;

assign rdata = (rinc_pre2) ? rdata_reg : 'd0;

always @(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
        rdata_reg <= 'd0;
    end else begin
        rdata_reg <= rdata_q;
    end
end

endmodule
