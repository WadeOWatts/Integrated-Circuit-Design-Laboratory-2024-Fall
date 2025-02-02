module Handshake_syn #(parameter WIDTH=8) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake
);

input sclk, dclk;
input rst_n;
input sready;
input [WIDTH-1:0] din;
input dbusy;
output reg sidle;
output reg dvalid;
output reg [WIDTH-1:0] dout;

// You can change the input / output of the custom flag ports
output reg flag_handshake_to_clk1;
input flag_clk1_to_handshake;

output reg flag_handshake_to_clk2;
input flag_clk2_to_handshake;

// Remember:
//   Don't modify the signal name
reg sreq;
wire dreq;
reg dack;
wire sack;

reg [WIDTH-1:0] ffs;
wire [WIDTH-1:0] data;

NDFF_syn U_req (.D(sreq), .Q(dreq), .clk(dclk), .rst_n(rst_n));
NDFF_syn U_ack (.D(dack), .Q(sack), .clk(sclk), .rst_n(rst_n));

always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        ffs <= 'd0;
    end else begin
        if (sidle && sready) begin
            ffs <= din;
        end
    end
end

assign data = ffs;

always @(posedge dclk or negedge rst_n) begin
    if (!rst_n) begin
        dout <= 'd0;
    end else begin
        if (!dbusy && dreq) begin
            dout <= data;
        end
    end
end

always @(posedge dclk or negedge rst_n) begin
    if (!rst_n) begin
        dvalid <= 'b0;
    end else begin
        case (dvalid)
            0: dvalid <= (!dbusy && dreq) ? 'b1 : 'b0;
            1: dvalid <= !dreq ? 'b0 : 'b1;
        endcase
    end
end

always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        sreq <= 'b0;
    end else begin
        case (sreq)
            0: sreq <= (flag_clk1_to_handshake && sidle && !sack) ? 'b1 : 'b0;
            1: sreq <= (sack) ? 'b0 : 'b1;
        endcase
    end
end

always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        flag_handshake_to_clk1 <= 'b0;
    end else begin
        case (flag_handshake_to_clk1)
            0: flag_handshake_to_clk1 <= (flag_clk1_to_handshake && sidle) ? 'b1 : 'b0;
            1: flag_handshake_to_clk1 <= sack ? 'b0 : 'b1;
        endcase
    end
end

// always @(posedge sclk or negedge rst_n) begin
//     if (!rst_n) begin
//         flag_handshake_to_clk1 <= 'b0;
//     end else begin
//         case (flag_handshake_to_clk1)
//             0: flag_handshake_to_clk1 = (flag_clk1_to_handshake && sidle) ? 'b1 : 'b0;
//             1: flag_handshake_to_clk1 = sack ? 'b0 : 'b1;
//         endcase
//     end
// end

always @(posedge dclk or negedge rst_n) begin
    if (!rst_n) begin
        flag_handshake_to_clk2 <= 'b0;
    end else begin
        case (flag_handshake_to_clk2)
            0: flag_handshake_to_clk2 <= (!dbusy && dreq) ? 'b1 : 'b0;
            1: flag_handshake_to_clk2 <= ~dreq ? 'b0 : 'b1;
        endcase
    end
end

always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        sidle <= 'b1;
    end else begin
        case (sidle)
            0: sidle <= (~flag_clk1_to_handshake && ~sack) ? 'b1 : 'b0;
            1: sidle <= sready ? 'b0 : 'b1;
        endcase
    end
end

always @(posedge dclk or negedge rst_n) begin
    if (!rst_n) begin
        dack <= 'b0;
    end else begin
        case (dack)
            0: dack <= (flag_handshake_to_clk2) ? 'b1 : 'b0;
            1: dack <= (!dreq) ? 'b0 : 'b1;
        endcase
    end
end


endmodule