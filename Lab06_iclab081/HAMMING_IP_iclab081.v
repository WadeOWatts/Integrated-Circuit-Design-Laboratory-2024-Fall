module HAMMING_IP #(parameter IP_BIT = 11) (
    // Input signals
    IN_code,
    // Output signals
    OUT_code
);

// ===============================================================
// Input & Output
// ===============================================================
input [IP_BIT+4-1:0]  IN_code;

output reg [IP_BIT-1:0] OUT_code;

// ===============================================================
// Design
// ===============================================================

integer i;
reg [3:0] check, result;
reg [IP_BIT+4-1:0] IN_code_reg;

always @(*) begin
    result = 4'b0;
    IN_code_reg = IN_code;
    for (i = IP_BIT+4-1; i >= 0; i = i - 1) begin
        if (IN_code[i]) begin
            check = IP_BIT + 4 - i;
            result = result ^ check;
        end
    end

    if (result != 4'b0) begin
        IN_code_reg[IP_BIT + 4 - result] = !IN_code_reg[IP_BIT + 4 - result];
    end

    OUT_code = {IN_code_reg[IP_BIT + 1], IN_code_reg[IP_BIT - 1: IP_BIT - 3], IN_code_reg[IP_BIT - 5:0]};
end


endmodule