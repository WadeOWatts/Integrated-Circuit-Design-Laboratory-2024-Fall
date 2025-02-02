module Ramen(
    // Input Registers
    input clk, 
    input rst_n, 
    input in_valid,
    input selling,
    input portion, 
    input [1:0] ramen_type,

    // Output Signals
    output reg out_valid_order,
    output reg success,

    output reg out_valid_tot,
    output reg [27:0] sold_num,
    output reg [14:0] total_gain
);


//==============================================//
//             Parameter and Integer            //
//==============================================//

// ramen_type
parameter TONKOTSU = 0;
parameter TONKOTSU_SOY = 1;
parameter MISO = 2;
parameter MISO_SOY = 3;

// initial ingredient
parameter NOODLE_INIT = 12000;
parameter BROTH_INIT = 41000;
parameter TONKOTSU_SOUP_INIT =  9000;
parameter MISO_INIT = 1000;
parameter SOY_SAUSE_INIT = 1500;

parameter IDLE = 2'd0;
parameter INPUT = 2'd1;
parameter OUTPUT = 2'd2;
parameter TOTAL = 2'd3;


//==============================================//
//                 reg declaration              //
//==============================================// 

reg [1:0] cs, ns;
reg [20:0] noodle, broth, ts, miso, soy;
reg portion_reg, no_order;
reg [1:0] ramen_type_reg;
reg [6:0] bowls [0:3];





//==============================================//
//                    Design                    //
//==============================================//

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cs <= IDLE;
    end else begin
        cs <= ns;
    end
end

always @(*) begin
    case (cs)
        IDLE: begin
            if (in_valid) begin
                ns = INPUT;
            end else begin
                ns = IDLE;
            end
        end
        INPUT: begin
            if (!in_valid) begin
                ns = OUTPUT;
            end else begin
                ns = INPUT;
            end
        end
        OUTPUT:begin
            if (cs == OUTPUT) begin
                ns = (selling) ? IDLE : TOTAL;
            end else begin
                ns = OUTPUT;
            end
        end
        TOTAL: ns = IDLE;
        default: ns = IDLE;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        noodle <= NOODLE_INIT;
    end else begin
        if (ns == OUTPUT) begin
            if (no_order == 0) begin
                case (portion_reg)
                    0: noodle <= noodle - 'd100;
                    1: noodle <= noodle - 'd150;                
                endcase
            end
        end else if (selling == 0) begin
            noodle <= NOODLE_INIT;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        broth <= BROTH_INIT;
    end else begin
        if (ns == OUTPUT) begin
            if (no_order == 0) begin
                case (portion_reg)
                    0: begin
                        case (ramen_type_reg)
                            'b00, 'b01, 'b11: broth <= broth - 'd300;
                            'b10: broth <= broth - 'd400;
                        endcase
                    end

                    1: begin
                        case (ramen_type_reg)
                            'b00, 'b01, 'b11: broth <= broth - 'd500;
                            'b10: broth <= broth - 'd650;
                        endcase
                    end
                endcase
            end
        end else if (selling == 0) begin
            broth <= BROTH_INIT;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ts <= TONKOTSU_SOUP_INIT;
    end else begin
        if (ns == OUTPUT) begin
            if (no_order == 0) begin
                case (portion_reg)
                    0: begin
                        case (ramen_type_reg)
                            'b00: ts <= ts - 'd150;
                            'b01: ts <= ts - 'd100;
                            'b10: ts <= ts;
                            'b11: ts <= ts - 'd70;
                        endcase
                    end

                    1: begin
                        case (ramen_type_reg)
                            'b00: ts <= ts - 'd200;
                            'b01: ts <= ts - 'd150;
                            'b10: ts <= ts;
                            'b11: ts <= ts - 'd100;
                        endcase
                    end
                endcase
            end
        end else if (selling == 0) begin
            ts <= TONKOTSU_SOUP_INIT;
        end
    end
end
 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        miso <= MISO_INIT;
    end else begin
        if (ns == OUTPUT) begin
            if (no_order == 0) begin
                case (portion_reg)
                    0: begin
                        case (ramen_type_reg)
                            'b00: miso <= miso;
                            'b01: miso <= miso;
                            'b10: miso <= miso - 'd30;
                            'b11: miso <= miso - 'd15;
                        endcase
                    end

                    1: begin
                        case (ramen_type_reg)
                            'b00: miso <= miso;
                            'b01: miso <= miso;
                            'b10: miso <= miso - 'd50;
                            'b11: miso <= miso - 'd25;
                        endcase
                    end
                endcase
            end
        end else if (selling == 0) begin
            miso <= MISO_INIT;
        end
    end
end 

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)begin
        soy <= SOY_SAUSE_INIT;
    end else begin
        if (ns == OUTPUT) begin
            if (no_order == 0) begin
                case (portion_reg)
                    0: begin
                        case (ramen_type_reg)
                            'b00: soy <= soy;
                            'b01: soy <= soy - 'd30;
                            'b10: soy <= soy;
                            'b11: soy <= soy - 'd15;
                        endcase
                    end

                    1: begin
                        case (ramen_type_reg)
                            'b00: soy <= soy;
                            'b01: soy <= soy - 'd50;
                            'b10: soy <= soy ;
                            'b11: soy <= soy - 'd25;
                        endcase
                    end
                endcase
            end
        end else if (selling == 0) begin
            soy <= SOY_SAUSE_INIT;
        end
    end
end

always @(*) begin
    if (ns == OUTPUT) begin
        case (portion_reg)
            'b0: begin
                case (ramen_type_reg)
                    'b00: begin
                        if (noodle < 'd100) begin
                            no_order = 1;
                        end else if (broth < 'd300) begin
                            no_order = 1;
                        end else if (ts < 'd150) begin
                            no_order = 1;
                        end else begin
                            no_order = 0;
                        end
                    end
                    'b01: begin
                        if (noodle < 'd100) begin
                            no_order = 1;
                        end else if (broth < 'd300) begin
                            no_order = 1;
                        end else if (ts < 'd100) begin
                            no_order = 1;
                        end else if (soy < 'd30) begin
                            no_order = 1;
                        end else begin
                            no_order = 0;
                        end
                    end
                    'b10: begin
                        if (noodle < 'd100) begin
                            no_order = 1;
                        end else if (broth < 'd400) begin
                            no_order = 1;
                        end else if (miso < 'd30) begin
                            no_order = 1;
                        end else begin
                            no_order = 0;
                        end
                    end
                    'b11: begin
                        if (noodle < 'd100) begin
                            no_order = 1;
                        end else if (broth < 'd300) begin
                            no_order = 1;
                        end else if (ts < 'd70) begin
                            no_order = 1;
                        end else if (soy < 'd15) begin
                            no_order = 1;
                        end else if (miso < 'd15) begin
                            no_order = 1;
                        end else begin
                            no_order = 0;
                        end
                    end
                    default: no_order = 'bx;
                endcase
            end

            'b1: begin
                case (ramen_type_reg)
                    'b00: begin
                        if (noodle < 'd150) begin
                            no_order = 1;
                        end else if (broth < 'd500) begin
                            no_order = 1;
                        end else if (ts < 'd200) begin
                            no_order = 1;
                        end else begin
                            no_order = 0;
                        end
                    end
                    'b01: begin
                        if (noodle < 'd150) begin
                            no_order = 1;
                        end else if (broth < 'd500) begin
                            no_order = 1;
                        end else if (ts < 'd150) begin
                            no_order = 1;
                        end else if (soy < 'd50) begin
                            no_order = 1;
                        end else begin
                            no_order = 0;
                        end
                    end
                    'b10: begin
                        if (noodle < 'd150) begin
                            no_order = 1;
                        end else if (broth < 'd650) begin
                            no_order = 1;
                        end else if (miso < 'd50) begin
                            no_order = 1;
                        end else begin
                            no_order = 0;
                        end
                    end
                    'b11: begin
                        if (noodle < 'd150) begin
                            no_order = 1;
                        end else if (broth < 'd500) begin
                            no_order = 1;
                        end else if (ts < 'd100) begin
                            no_order = 1;
                        end else if (soy < 'd25) begin
                            no_order = 1;
                        end else if (miso < 'd25) begin
                            no_order = 1;
                        end else begin
                            no_order = 0;
                        end
                    end
                    default: no_order = 'bx;
                endcase
            end

            default: no_order = 'bx;
        endcase
    end else begin
        no_order = 'bx;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ramen_type_reg <= 0;
    end else begin
        if (in_valid && cs == IDLE) begin
            ramen_type_reg <= ramen_type;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        portion_reg <= 0;
    end else begin
        if (in_valid && cs == INPUT) begin
            portion_reg <= portion;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid_order <= 0;
    end else begin
        if (ns == OUTPUT) begin
            out_valid_order <= 1;
        end else begin
            out_valid_order <= 0;
        end
    end
end 

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        success <= 0;
    end else begin
        if (ns == OUTPUT) begin
            if (no_order) begin
                success <= 0;
            end else begin
                success <= 1;
            end
        end
    end
end

genvar i;
generate
    for (i = 0; i < 4; i = i + 1) begin: bowl_loop
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                bowls[i] <= 0;
            end else begin
                if (cs == TOTAL) begin
                    bowls[i] <= 0;
                end else if (ns == OUTPUT) begin
                    if (!no_order) begin
                        if (ramen_type_reg == i) begin
                            bowls[i] <= bowls[i] + 'd1;
                        end
                        
                        // if ()
                        // case (ramen_type_reg) 
                        //     'b00: bowls[0] <= bowls[0] + 'd1;
                        //     'b01: bowls[1] <= bowls[1] + 'd1;
                        //     'b10: bowls[2] <= bowls[2] + 'd1;
                        //     'b11: bowls[3] <= bowls[3] + 'd1;
                        // endcase
                    end
                end
            end
        end
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sold_num <= 0;
    end else begin
        if (ns == TOTAL) begin
            sold_num[27:21] <= bowls[0];
            sold_num[20:14] <= bowls[1];
            sold_num[13:7] <= bowls[2];
            sold_num[6:0] <= bowls[3];
        end else begin
            sold_num <= 0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        total_gain <= 0;
    end else begin
        if (ns == TOTAL) begin
            total_gain <= (bowls[0] + bowls[2]) * 'd200 + (bowls[1] + bowls[3]) * 'd250;
        end else begin
            total_gain <= 0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid_tot <= 0;
    end else begin
        if (ns == TOTAL) begin
            out_valid_tot <= 1;
        end else begin
            out_valid_tot <= 0;
        end
    end
end

endmodule
