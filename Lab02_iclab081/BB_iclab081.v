module BB(
    //Input Ports
    input clk,
    input rst_n,
    input in_valid,
    input [1:0] inning,   // Current inning number
    input half,           // 0: top of the inning, 1: bottom of the inning
    input [2:0] action,   // Action code

    //Output Ports
    output reg out_valid,  // Result output valid
    output reg [7:0] score_A,  // Score of team A (guest team)
    output reg [7:0] score_B,  // Score of team B (home team)
    output reg [1:0] result    // 0: Team A wins, 1: Team B wins, 2: Darw
);

//==============================================//
//             Parameter and Integer            //
//==============================================//

parameter IDLE = 2'd0;
parameter INPUT = 2'd1;
parameter OUT = 2'd2;

parameter WALK = 3'd0;
parameter SINGLE = 3'd1;
parameter DOUBLE = 3'd2;
parameter TRIPLE = 3'd3;
parameter HR = 3'd4;
parameter BUNT = 3'd5;
parameter GO = 3'd6;
parameter FO = 3'd7;

//==============================================//
//                 reg declaration              //
//==============================================//

reg [1:0] current_state, next_state;
reg [1:0] inning_reg;
reg half_reg;
reg [2:0] action_reg;
reg [1:0] current_out;
reg [2:0] base;
reg [7:0] score_A, score_B;
reg game_over_early_reg;

//==============================================//
//             Current State Block              //
//==============================================//

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

//==============================================//
//              Next State Block                //
//==============================================//

always @(*) begin
    case (current_state)
        IDLE:   begin
            if (in_valid)  begin
                next_state = INPUT;
            end else begin
                next_state = IDLE;
            end
        end

        INPUT:  begin
            if (!in_valid) begin
                next_state = OUT;
            end else begin
                next_state = INPUT;
            end
        end

        OUT:    begin
            next_state = IDLE;
        end

        default: next_state = IDLE;

    endcase 
end

//==============================================//
//             Base and Score Logic             //
//==============================================//

always @(posedge clk or negedge rst_n) begin                    // inning
    if (!rst_n) begin
        inning_reg <= 2'd0;
    end else begin
        if (next_state == INPUT) begin
            inning_reg <= inning;
        end else begin
            inning_reg <= 2'd0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin                    // half
    if (!rst_n) begin
        half_reg <= 0;
    end else begin
        if (next_state == INPUT) begin
            half_reg <= half;
        end else begin
            half_reg <= 0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin                    // action
    if (!rst_n) begin
        action_reg <= 3'd0;
    end else begin
        if (next_state == INPUT) begin
            action_reg <= action;
        end else begin
            action_reg <= 3'd0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin                    // current_out
    if (!rst_n) begin
        current_out <= 0;
    end else begin
        case (action_reg)
            BUNT: current_out <= current_out + 1;
            GO: begin
                case (current_out)
                    2'b00: current_out <= (base[0] == 0) ? 2'b01 : 2'b10;
                    2'b01: current_out <= (base[0] == 0) ? 2'b10 : 2'b00;
                    2'b10: current_out <= 2'b00;
                endcase
            end

            FO: current_out <= (current_out == 2'b10) ? 2'b00 : (current_out + 1);
            
            default: current_out <= current_out;
        endcase
    end
end


always @(posedge clk or negedge rst_n) begin			// base
    if (!rst_n) begin
        base <= 3'b000;
    end else begin
        if (current_state == INPUT) begin
            case (action_reg)
                WALK: begin
                    case (base)
                        3'b000: base <= 3'b001;
                        3'b001: base <= 3'b011;
                        3'b010: base <= 3'b011;
                        3'b011: base <= 3'b111;
                        3'b100: base <= 3'b101;
                        3'b101: base <= 3'b111;
                        3'b110: base <= 3'b111;
                        3'b111: base <= 3'b111;
                        default: base <= 3'b000;
                    endcase
                end

                SINGLE: begin
                    case (current_out)
                        2'b00: base <= (base << 1) + 1;
                        2'b01: base <= (base << 1) + 1;
                        2'b10: base <= (base << 2) + 1;
                        default: base <= base;
                    endcase
                end

                DOUBLE: begin
                    case (current_out)
                        2'b00: base <= (base << 2) + 3'b010;
                        2'b01: base <= (base << 2) + 3'b010;
                        2'b10: base <= 3'b010;
                        default: base <= base;
                    endcase
                end

                TRIPLE: base <= 3'b100;

                HR: base <= 3'b000;

                BUNT: base <= base << 1;

                GO: begin
                    case (current_out)
                        2'b00: base <= {base[1], 2'b00};
                        2'b01: base <= (base[1] == 1 && base[0] == 0) ? 3'b100 : 3'b000;
                        2'b10: base <= 3'b000;
                        default: base <= base;
                    endcase
                end

                FO: begin
                    case (current_out)
                        2'b00: base <= (base[2] == 1) ? {1'b0, base[1:0]} : base;
                        2'b01: base <= (base[2] == 1) ? {1'b0, base[1:0]} : base;
                        2'b10: base <= 3'b000;
                        default: base <= base;
                    endcase
                end
                default: base <= base;
            endcase
        end else begin
            base <= 3'b000;
        end
    end
end

always @(posedge clk or negedge rst_n) begin                    // runs of A (guest)
    if (!rst_n) begin
        score_A <= 0;
    end else begin
        if (current_state != IDLE) begin
            if (half_reg == 0) begin
                case (action_reg)
                    WALK: score_A <= (base == 3'b111) ? (score_A + 1) : score_A;

                    SINGLE: begin
                        case (current_out)
                            2'b00: score_A <= (base[2]) ? (score_A + 1) : score_A;
                            2'b01: score_A <= (base[2]) ? (score_A + 1) : score_A;
                            2'b10: begin
                                case (base)
                                    3'b000: score_A <= score_A;
                                    3'b001: score_A <= score_A;
                                    3'b010: score_A <= score_A + 1;
                                    3'b011: score_A <= score_A + 1;
                                    3'b100: score_A <= score_A + 1;
                                    3'b101: score_A <= score_A + 1;
                                    3'b110: score_A <= score_A + 2;
                                    3'b111: score_A <= score_A + 2;
                                endcase
                            end
                            default: score_A <= score_A;
                        endcase
                    end

                    DOUBLE: begin
                        case (current_out)
                            2'b00: begin
                                case (base)
                                    3'b000: score_A <= score_A;
                                    3'b001: score_A <= score_A;
                                    3'b010: score_A <= score_A + 1;
                                    3'b011: score_A <= score_A + 1;
                                    3'b100: score_A <= score_A + 1;
                                    3'b101: score_A <= score_A + 1;
                                    3'b110: score_A <= score_A + 2;
                                    3'b111: score_A <= score_A + 2;
                                endcase
                            end
                            2'b01: begin
                                case (base)
                                    3'b000: score_A <= score_A;
                                    3'b001: score_A <= score_A;
                                    3'b010: score_A <= score_A + 1;
                                    3'b011: score_A <= score_A + 1;
                                    3'b100: score_A <= score_A + 1;
                                    3'b101: score_A <= score_A + 1;
                                    3'b110: score_A <= score_A + 2;
                                    3'b111: score_A <= score_A + 2;
                                endcase
                            end
                            2'b10: begin
                                case (base)
                                    3'b000: score_A <= score_A;
                                    3'b001: score_A <= score_A + 1;
                                    3'b010: score_A <= score_A + 1;
                                    3'b011: score_A <= score_A + 2;
                                    3'b100: score_A <= score_A + 1;
                                    3'b101: score_A <= score_A + 2;
                                    3'b110: score_A <= score_A + 2;
                                    3'b111: score_A <= score_A + 3;
                                endcase
                            end
                            default: score_A <= score_A;
                        endcase
                    end

                    TRIPLE: begin
                        case (base)
                            3'b000: score_A <= score_A;
                            3'b001: score_A <= score_A + 1;
                            3'b010: score_A <= score_A + 1;
                            3'b011: score_A <= score_A + 2;
                            3'b100: score_A <= score_A + 1;
                            3'b101: score_A <= score_A + 2;
                            3'b110: score_A <= score_A + 2;
                            3'b111: score_A <= score_A + 3;
                        endcase
                    end

                    HR: begin
                        case (base)
                            3'b000: score_A <= score_A + 1;
                            3'b001: score_A <= score_A + 2;
                            3'b010: score_A <= score_A + 2;
                            3'b011: score_A <= score_A + 3;
                            3'b100: score_A <= score_A + 2;
                            3'b101: score_A <= score_A + 3;
                            3'b110: score_A <= score_A + 3;
                            3'b111: score_A <= score_A + 4;
                        endcase
                    end

                    BUNT: score_A <= (base[2]) ? (score_A + 1) : score_A;

                    GO: begin
                        case (current_out)
                            2'b00: score_A <= (base[2]) ? (score_A + 1) : score_A;
                            2'b01: score_A <= (base[2] == 1 && base[0] == 0) ? (score_A + 1) : score_A;
                            2'b10: score_A <= score_A;
                            default: score_A <= score_A;
                        endcase
                    end

                    FO: begin
                        case (current_out)
                            2'b00: score_A <= (base[2]) ? (score_A + 1) : score_A;
                            2'b01: score_A <= (base[2]) ? (score_A + 1) : score_A;
                            2'b10: score_A <= score_A;
                            default: score_A <= score_A;
                        endcase
                    end

                    default: score_A <= score_A;
                endcase
            end else begin
                score_A <= score_A;
            end
        end else begin
            score_A <= 0;
        end
    end
end

// how to defin game over?
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        game_over_early_reg <= 0;
    end else begin
        if (inning_reg == 2'd3) begin
            if (((current_out == 1 && action_reg == 6 && base[0] == 1) || (current_out == 2 && action_reg > 3'd4)) && (score_B > score_A)) begin
                game_over_early_reg <= 1;
            end else begin
                game_over_early_reg <= game_over_early_reg;
            end
        end else begin
            game_over_early_reg <= 0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin                    // runs of B (host)
    if (!rst_n) begin
        score_B <= 0;
    end else begin
        if (current_state != IDLE) begin
            if (half_reg == 1) begin
                if (game_over_early_reg) begin
                    score_B <= score_B;
                end else begin
                    case (action_reg)
                        WALK: score_B <= (base == 3'b111) ? (score_B + 1) : score_B;

                        SINGLE: begin
                            case (current_out)
                                2'b00: score_B <= (base[2]) ? (score_B + 1) : score_B;
                                2'b01: score_B <= (base[2]) ? (score_B + 1) : score_B;
                                2'b10: begin
                                    case (base)
                                        3'b000: score_B <= score_B;
                                        3'b001: score_B <= score_B;
                                        3'b010: score_B <= score_B + 1;
                                        3'b011: score_B <= score_B + 1;
                                        3'b100: score_B <= score_B + 1;
                                        3'b101: score_B <= score_B + 1;
                                        3'b110: score_B <= score_B + 2;
                                        3'b111: score_B <= score_B + 2;
                                    endcase
                                end
                                default: score_B <= score_B;
                            endcase
                        end

                        DOUBLE: begin
                            case (current_out)
                                2'b00: begin
                                    case (base)
                                        3'b000: score_B <= score_B;
                                        3'b001: score_B <= score_B;
                                        3'b010: score_B <= score_B + 1;
                                        3'b011: score_B <= score_B + 1;
                                        3'b100: score_B <= score_B + 1;
                                        3'b101: score_B <= score_B + 1;
                                        3'b110: score_B <= score_B + 2;
                                        3'b111: score_B <= score_B + 2;
                                    endcase
                                end
                                2'b01: begin
                                    case (base)
                                        3'b000: score_B <= score_B;
                                        3'b001: score_B <= score_B;
                                        3'b010: score_B <= score_B + 1;
                                        3'b011: score_B <= score_B + 1;
                                        3'b100: score_B <= score_B + 1;
                                        3'b101: score_B <= score_B + 1;
                                        3'b110: score_B <= score_B + 2;
                                        3'b111: score_B <= score_B + 2;
                                    endcase
                                end
                                2'b10: begin
                                    case (base)
                                        3'b000: score_B <= score_B;
                                        3'b001: score_B <= score_B + 1;
                                        3'b010: score_B <= score_B + 1;
                                        3'b011: score_B <= score_B + 2;
                                        3'b100: score_B <= score_B + 1;
                                        3'b101: score_B <= score_B + 2;
                                        3'b110: score_B <= score_B + 2;
                                        3'b111: score_B <= score_B + 3;
                                    endcase
                                end
                                default: score_B <= score_B;
                            endcase
                        end

                        TRIPLE: begin
                            case (base)
                                3'b000: score_B <= score_B;
                                3'b001: score_B <= score_B + 1;
                                3'b010: score_B <= score_B + 1;
                                3'b011: score_B <= score_B + 2;
                                3'b100: score_B <= score_B + 1;
                                3'b101: score_B <= score_B + 2;
                                3'b110: score_B <= score_B + 2;
                                3'b111: score_B <= score_B + 3;
                            endcase
                        end

                        HR: begin
                            case (base)
                                3'b000: score_B <= score_B + 1;
                                3'b001: score_B <= score_B + 2;
                                3'b010: score_B <= score_B + 2;
                                3'b011: score_B <= score_B + 3;
                                3'b100: score_B <= score_B + 2;
                                3'b101: score_B <= score_B + 3;
                                3'b110: score_B <= score_B + 3;
                                3'b111: score_B <= score_B + 4;
                            endcase
                        end

                        BUNT: score_B <= (base[2]) ? (score_B + 1) : score_B;

                        GO: begin
                            case (current_out)
                                2'b00: score_B <= (base[2]) ? (score_B + 1) : score_B;
                                2'b01: score_B <= (base[2] == 1 && base[0] == 0) ? (score_B + 1) : score_B;
                                2'b10: score_B <= score_B;
                                default: score_B <= score_B;
                            endcase
                        end

                        FO: begin
                            case (current_out)
                                2'b00: score_B <= (base[2]) ? (score_B + 1) : score_B;
                                2'b01: score_B <= (base[2]) ? (score_B + 1) : score_B;
                                2'b10: score_B <= score_B;
                                default: score_B <= score_B;
                            endcase
                        end

                        default: score_B <= score_B;
                    endcase
                end
            end else begin
                score_B <= score_B;
            end
        end else begin
            score_B <= 0;
        end
    end
end

//==============================================//
//                Output Block                  //
//==============================================//

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid <= 0;
    end else begin
        out_valid <= (next_state == OUT) ? 1 : 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        result <= 0;
    end else begin
        if (next_state == OUT) begin
            if (score_A > score_B) begin
                result <= 2'd0;
            end else if (score_B > score_A) begin
                result <= 2'd1;
            end else begin
                result <= 2'd2;
            end
        end else begin
            result <= 0;
        end
    end
end

endmodule
