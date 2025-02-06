// synopsys translate_off
`ifdef RTL
	`include "GATED_OR.v"
`else
	`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on


module SA(
    //Input signals
    clk,
    rst_n,
    cg_en,
    in_valid,
    T,
    in_data,
    w_Q,
    w_K,
    w_V,

    //Output signals
    out_valid,
    out_data
    );

input clk;
input rst_n;
input in_valid;
input cg_en;
input [3:0] T;
input signed [7:0] in_data;
input signed [7:0] w_Q;
input signed [7:0] w_K;
input signed [7:0] w_V;

output reg out_valid;
output reg signed [63:0] out_data;

//==============================================//
//       parameter & integer declaration        //
//==============================================//



//==============================================//
//           reg & wire declaration             //
//==============================================//
reg signed [7:0] kqv_temp [0:63];
reg signed [7:0] t_temp [0:63];
reg [3:0] size;
reg [7:0] counter;
reg design_qkv;
reg Sleep_ctrl_1, Sleep_ctrl_2, Sleep_ctrl_3, Sleep_ctrl_4;
reg qkv_mat2_flag, mat1_relu_flag, relu_mat2_flag, out_last_flag;
reg [8:0] QKV_counter;
reg signed [7:0] T_reg [0:7][0:7];
reg signed [7:0] M_reg [0:7][0:7];
reg signed [19:0] out_reg[0:7][0:7];
reg signed [19:0] mult_result [0:7];
reg [2:0] ptr;
reg [1:0] in_valid_count;
reg qkv_mat1, mat1_relu, relu_mat2, qkv_mat2;
reg signed [19:0] out [0:63];
reg signed [19:0] out2 [0:63];
reg q_flag, k_flag;
reg signed [19:0] Q [0:7][0:7];
reg signed [19:0] K_t [0:7][0:7];
reg signed [42:0] Matmul1_and_scale_out [0:7][0:7];
reg signed [42:0] out_temp [0:7];
reg [8:0] Matmul1_and_scale_counter;
reg [2:0] q_ptr, k_ptr;
reg signed [42:0] A [0:63];
reg signed [42:0] S [0:63];
reg signed [42:0] S_reg [0:7][0:7];
reg signed [19:0] V_reg [0:7][0:7];
reg [8:0] Matmul2_counter;
reg s_set, v_set;
reg [2:0] s_ptr, v_ptr;
reg signed [63:0] P;

wire signed [19:0] kq [0:63];
wire signed [19:0] V [0:63];
// wire out_valid_wire;
// wire signed [63:0] out_data_wire;
wire out_last;
wire [6:0] size_8;
wire clk_gated_counter, clk_gated_in_valid_count, clk_gated_ptr;
wire clk_gated_out_valid, clk_gated_out_valid2;
wire clk_gated_T_reg [0:7];
wire clk_gated_M_reg [0:7];
wire clk_gate_mult_result [0:7];
wire clk_gate_out_reg [0:7];
wire clk_gated_sub2_counter, clk_gated_sub2_q_ptr, clk_gated_sub2_k_ptr;
wire clk_gated_sub2_q_flag, clk_gated_sub2_k_flag, clk_gated_sub2_out_valid;
wire clk_gated_sub2_Q [0:7];
wire clk_gated_sub2_K [0:7];
wire clk_gated_sub2_out_temp [0:7];
wire clk_gated_sub2_out [0:7];
wire clk_gated_sub3_S;
wire clk_gated_sub3_out_valid;
wire clk_gated_sub4_counter, clk_gated_sub4_s_set, clk_gated_sub4_v_set, clk_gated_sub4_P;
wire clk_gated_size_reg, clk_gated_s_ptr, clk_gated_v_ptr, clk_gated_out_out_valid;
wire clk_gated_sub4_S_reg [0:7];
wire clk_gated_sub4_V_reg [0:7];

//==============================================//
//                 GATED_OR                     //
//==============================================//
GATED_OR GATED_counter (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gated_counter));
GATED_OR GATED_in_valid_count (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gated_in_valid_count));
GATED_OR GATED_T_reg_0 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gated_T_reg[0]));
GATED_OR GATED_T_reg_1 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gated_T_reg[1]));
GATED_OR GATED_T_reg_2 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gated_T_reg[2]));
GATED_OR GATED_T_reg_3 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gated_T_reg[3]));
GATED_OR GATED_T_reg_4 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gated_T_reg[4]));
GATED_OR GATED_T_reg_5 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gated_T_reg[5]));
GATED_OR GATED_T_reg_6 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gated_T_reg[6]));
GATED_OR GATED_T_reg_7 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gated_T_reg[7]));
GATED_OR GATED_M_reg_0 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gated_M_reg[0]));
GATED_OR GATED_M_reg_1 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gated_M_reg[1]));
GATED_OR GATED_M_reg_2 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gated_M_reg[2]));
GATED_OR GATED_M_reg_3 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gated_M_reg[3]));
GATED_OR GATED_M_reg_4 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gated_M_reg[4]));
GATED_OR GATED_M_reg_5 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gated_M_reg[5]));
GATED_OR GATED_M_reg_6 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gated_M_reg[6]));
GATED_OR GATED_M_reg_7 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gated_M_reg[7]));
GATED_OR GATED_ptr (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gated_ptr));
GATED_OR GATED_mult_result_0 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gate_mult_result[0]));
GATED_OR GATED_mult_result_1 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gate_mult_result[1]));
GATED_OR GATED_mult_result_2 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gate_mult_result[2]));
GATED_OR GATED_mult_result_3 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gate_mult_result[3]));
GATED_OR GATED_mult_result_4 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gate_mult_result[4]));
GATED_OR GATED_mult_result_5 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gate_mult_result[5]));
GATED_OR GATED_mult_result_6 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gate_mult_result[6]));
GATED_OR GATED_mult_result_7 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gate_mult_result[7]));
GATED_OR GATED_out_reg_0 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gate_out_reg[0]));
GATED_OR GATED_out_reg_1 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gate_out_reg[1]));
GATED_OR GATED_out_reg_2 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gate_out_reg[2]));
GATED_OR GATED_out_reg_3 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gate_out_reg[3]));
GATED_OR GATED_out_reg_4 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gate_out_reg[4]));
GATED_OR GATED_out_reg_5 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gate_out_reg[5]));
GATED_OR GATED_out_reg_6 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gate_out_reg[6]));
GATED_OR GATED_out_reg_7 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gate_out_reg[7]));
GATED_OR GATED_out_valid (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gated_out_valid));
GATED_OR GATED_out_valid2 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_1), .RST_N(rst_n), .CLOCK_GATED(clk_gated_out_valid2));
GATED_OR GATED_out_sub2_counter (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_counter));
GATED_OR GATED_out_sub2_q_ptr (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_q_ptr));
GATED_OR GATED_out_sub2_k_ptr (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_k_ptr));
GATED_OR GATED_out_sub2_Q_0 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_Q[0]));
GATED_OR GATED_out_sub2_Q_1 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_Q[1]));
GATED_OR GATED_out_sub2_Q_2 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_Q[2]));
GATED_OR GATED_out_sub2_Q_3 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_Q[3]));
GATED_OR GATED_out_sub2_Q_4 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_Q[4]));
GATED_OR GATED_out_sub2_Q_5 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_Q[5]));
GATED_OR GATED_out_sub2_Q_6 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_Q[6]));
GATED_OR GATED_out_sub2_Q_7 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_Q[7]));
GATED_OR GATED_out_sub2_K_0 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_K[0]));
GATED_OR GATED_out_sub2_K_1 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_K[1]));
GATED_OR GATED_out_sub2_K_2 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_K[2]));
GATED_OR GATED_out_sub2_K_3 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_K[3]));
GATED_OR GATED_out_sub2_K_4 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_K[4]));
GATED_OR GATED_out_sub2_K_5 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_K[5]));
GATED_OR GATED_out_sub2_K_6 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_K[6]));
GATED_OR GATED_out_sub2_K_7 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_K[7]));
GATED_OR GATED_out_sub2_q_flag (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_q_flag));
GATED_OR GATED_out_sub2_k_flag (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_k_flag));
GATED_OR GATED_out_sub2_out_temp_0 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_out_temp[0]));
GATED_OR GATED_out_sub2_out_temp_1 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_out_temp[1]));
GATED_OR GATED_out_sub2_out_temp_2 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_out_temp[2]));
GATED_OR GATED_out_sub2_out_temp_3 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_out_temp[3]));
GATED_OR GATED_out_sub2_out_temp_4 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_out_temp[4]));
GATED_OR GATED_out_sub2_out_temp_5 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_out_temp[5]));
GATED_OR GATED_out_sub2_out_temp_6 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_out_temp[6]));
GATED_OR GATED_out_sub2_out_temp_7 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_out_temp[7]));
GATED_OR GATED_out_sub2_out_0 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_out[0]));
GATED_OR GATED_out_sub2_out_1 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_out[1]));
GATED_OR GATED_out_sub2_out_2 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_out[2]));
GATED_OR GATED_out_sub2_out_3 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_out[3]));
GATED_OR GATED_out_sub2_out_4 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_out[4]));
GATED_OR GATED_out_sub2_out_5 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_out[5]));
GATED_OR GATED_out_sub2_out_6 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_out[6]));
GATED_OR GATED_out_sub2_out_7 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_out[7]));
GATED_OR GATED_out_sub2_out_valid (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_2), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub2_out_valid));
GATED_OR GATED_out_sub3_S_0 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_3), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub3_S));

GATED_OR GATED_out_sub3_S_out_valid (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_3), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub3_out_valid));
GATED_OR GATED_out_sub4_counter (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub4_counter));
GATED_OR GATED_out_sub4_s_set (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub4_s_set));
GATED_OR GATED_out_sub4_v_set (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub4_v_set));
GATED_OR GATED_out_sub4_S_reg_0 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub4_S_reg[0]));
GATED_OR GATED_out_sub4_S_reg_1 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub4_S_reg[1]));
GATED_OR GATED_out_sub4_S_reg_2 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub4_S_reg[2]));
GATED_OR GATED_out_sub4_S_reg_3 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub4_S_reg[3]));
GATED_OR GATED_out_sub4_S_reg_4 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub4_S_reg[4]));
GATED_OR GATED_out_sub4_S_reg_5 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub4_S_reg[5]));
GATED_OR GATED_out_sub4_S_reg_6 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub4_S_reg[6]));
GATED_OR GATED_out_sub4_S_reg_7 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub4_S_reg[7]));
GATED_OR GATED_out_sub4_V_reg_0 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub4_V_reg[0]));
GATED_OR GATED_out_sub4_V_reg_1 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub4_V_reg[1]));
GATED_OR GATED_out_sub4_V_reg_2 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub4_V_reg[2]));
GATED_OR GATED_out_sub4_V_reg_3 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub4_V_reg[3]));
GATED_OR GATED_out_sub4_V_reg_4 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub4_V_reg[4]));
GATED_OR GATED_out_sub4_V_reg_5 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub4_V_reg[5]));
GATED_OR GATED_out_sub4_V_reg_6 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub4_V_reg[6]));
GATED_OR GATED_out_sub4_V_reg_7 (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub4_V_reg[7]));
GATED_OR GATED_out_sub4_P (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_sub4_P));
GATED_OR GATED_out_size_reg (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_size_reg));
GATED_OR GATED_out_s_ptr (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_s_ptr));
GATED_OR GATED_out_v_ptr (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_v_ptr));
GATED_OR GATED_out_out_valid (.CLOCK(clk), .SLEEP_CTRL(Sleep_ctrl_4), .RST_N(rst_n), .CLOCK_GATED(clk_gated_out_out_valid));

//==============================================//
//                  design                      //
//==============================================//

assign kq = out;
assign V = out2;
assign out_data = P;

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		counter <= 'd0;
	end else begin
		counter <= in_valid ? counter + 'd1 : 'd0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		size <= 'd0;
	end else begin
		size <= (in_valid && counter == 'd0) ? T : size;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		design_qkv <= 'b0;
	end else begin
		case (design_qkv)
			0: begin
				case (counter)
					'd63, 'd127, 'd191: design_qkv <= 'b1;
					default: design_qkv <= 'b0;
				endcase
			end
			1: design_qkv <= 'b0;
		endcase
	end
end

genvar i;
generate
	for (i = 0; i < 64; i = i + 1) begin: t_temp_loop
		always @(posedge clk or negedge rst_n) begin
			if(~rst_n) begin
				t_temp[i] <= 'd0;
			end else begin
				if (in_valid) begin
					if (counter < 'd64) begin
						case (size)	
							'd1: begin
								if (i == 63) begin
									if (counter < 8) begin
										t_temp[i] <= in_data;
									end else begin
										t_temp[i] <= 'd0;
									end
								end else begin
									t_temp[i] <= t_temp[i+1];
								end
							end

							'd4: begin
								if (i == 63) begin
									if (counter < 32) begin
										t_temp[i] <= in_data;
									end else begin
										t_temp[i] <= 'd0;
									end
								end else begin
									t_temp[i] <= t_temp[i+1];
								end
							end

							'd8: begin
								if (i == 63) begin
									t_temp[i] <= in_data;
								end else begin
									t_temp[i] <= t_temp[i+1];
								end
							end

							default: begin
								if (i == 63) begin
									t_temp[i] <= in_data;
								end else begin
									t_temp[i] <= t_temp[i+1];
								end
							end
						endcase
					end
				end else begin
					t_temp[i] <= 'd0;
				end
			end
		end
	end
endgenerate

genvar j;
generate
	for (j = 0; j < 64; j = j + 1) begin: qkv_loop
		always @(posedge clk or negedge rst_n) begin
			if (~rst_n) begin
				kqv_temp[j] <= 'd0;
			end else begin
				if (in_valid) begin
					if (counter < 64) begin
						if (j == 63) begin
							kqv_temp[j] <= w_Q;
						end else begin
							kqv_temp[j] <= kqv_temp[j+1];
						end
					end else if (counter < 128) begin
						if (j == 63) begin
							kqv_temp[j] <= w_K;
						end else begin
							kqv_temp[j] <= kqv_temp[j+1];
						end
					end else begin
						if (j == 63) begin
							kqv_temp[j] <= w_V;
						end else begin
							kqv_temp[j] <= kqv_temp[j+1];
						end
					end
				end else begin
					kqv_temp[j] <= 'd0;
				end
			end
		end
	end
endgenerate


always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        qkv_mat2_flag <= 'b0;
    end else begin
        case (qkv_mat2_flag)
            0: qkv_mat2_flag <= qkv_mat2 ? 'b1 : 'b0;
            1: qkv_mat2_flag <= out_valid ? 'b0 : 'b1;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        mat1_relu_flag <= 'b0;
    end else begin
        case (mat1_relu_flag)
            0: mat1_relu_flag <= mat1_relu ? 'b1 : 'b0;
            1: mat1_relu_flag <= out_valid ? 'b0 : 'b1;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        relu_mat2_flag <= 'b0;
    end else begin
        case (relu_mat2_flag) 
            0: relu_mat2_flag <= relu_mat2 ? 'b1 : 'b0;
            1: relu_mat2_flag <= ~relu_mat2 ? 'b0 : 'b1;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        out_last_flag <= 'b0;
    end else begin
        case (out_last_flag)
            0: out_last_flag <= out_last ? 'b1 : 'b0;
            1: out_last_flag <= out_last_flag ? 'b0 : 'b1;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		Sleep_ctrl_1 <= 'b1;
	end else begin
		if (in_valid && cg_en && counter == 'd0) begin
			Sleep_ctrl_1 <= 'b1;
		end else begin
			case (cg_en)
				1: begin
					case (Sleep_ctrl_1)
						0: Sleep_ctrl_1 <= qkv_mat2 ? 'b1 : 'b0;
						1: begin
							case (counter)
								'd63, 'd127, 'd191: Sleep_ctrl_1 <= 'b0;
								default: Sleep_ctrl_1 <= 'b1;
							endcase
						end
					endcase
				end
				0: Sleep_ctrl_1 <= 'b0;
			endcase
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		Sleep_ctrl_2 <= 'b1;
	end else begin
		if (in_valid && cg_en && counter == 'd0) begin
			Sleep_ctrl_2 <= 'b1;
		end else begin
			case (cg_en)
				1: begin
					case (Sleep_ctrl_2)
						0: Sleep_ctrl_2 <= mat1_relu ? 'b1 : 'b0;
						1: begin
							Sleep_ctrl_2 <= (in_valid_count > 'd1 && QKV_counter == 'd0) ? 'b0 : 'b1;
						end
					endcase
				end
				0: Sleep_ctrl_2 <= 'b0;
			endcase
		end
	end
end 


always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		Sleep_ctrl_3 <= 'b1;
	end else begin
		if (in_valid && cg_en && counter == 'd0) begin
			Sleep_ctrl_3 <= 'b1;
		end else begin
			case (cg_en)
				1: begin
					case (Sleep_ctrl_3)
						0: Sleep_ctrl_3 <= relu_mat2 ? 'b1 : 'b0;
						1: Sleep_ctrl_3 <= (q_flag && k_flag && Matmul1_and_scale_counter == 'd64) ? 'b0 : 'b1; 
					endcase
				end
				0: Sleep_ctrl_3 <= 'b0;
			endcase
		end
	end
end 

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		Sleep_ctrl_4 <= 'b1;
	end else begin
		if (in_valid && cg_en && counter == 'd0) begin
			Sleep_ctrl_4 <= 'b1;
		end else begin
			case (cg_en)
				1: begin
					case (Sleep_ctrl_4)
						0: Sleep_ctrl_4 <= out_last ? 'b1 : 'b0;
						1: begin
							Sleep_ctrl_4 <= (mat1_relu || QKV_counter == 'd64) ? 'b0 : 'b1;
						end
					endcase
				end
				0: Sleep_ctrl_4 <= 'b0;
			endcase
		end
	end
end 

//==============================================//
//              QKV_generation                  //
//==============================================//

always @(posedge clk_gated_counter or negedge rst_n) begin
	if (~rst_n) begin
		QKV_counter <= 'd0;
	end else begin
		if (in_valid_count > 'd0) begin
			if (design_qkv) begin
				QKV_counter <= 'd0;
			end else begin
				QKV_counter <= QKV_counter + 'd1;
			end
		end else begin
			QKV_counter <= 'd0;
		end
	end
end

always @(posedge clk_gated_in_valid_count or negedge rst_n) begin
	if (~rst_n) begin
		in_valid_count <= 'd0;
	end else begin
		case (in_valid_count)
			'd3: in_valid_count <= design_qkv ? 'd1 : in_valid_count;
			default: in_valid_count <= design_qkv ? in_valid_count + 'd1 : in_valid_count;
		endcase
	end
end

genvar i_sub, j_sub;
generate
	for (i_sub = 0; i_sub < 8; i_sub = i_sub + 1) begin: T_reg_i
		for (j_sub = 0; j_sub < 8; j_sub = j_sub + 1) begin: T_reg_j
			always @(posedge clk_gated_T_reg[i_sub] or negedge rst_n) begin
				if (~rst_n) begin
					T_reg[i_sub][j_sub] <= 'd0;
				end else begin
					if (design_qkv) begin
						T_reg[i_sub][j_sub] <= t_temp[i_sub*8 + j_sub];
					end else if (qkv_mat2) begin
						T_reg[i_sub][j_sub] <= 'd0;
					end else if (QKV_counter[2:0] == 'd7) begin
						if (i_sub == 7) begin
							T_reg[i_sub][j_sub] <= 'd0;
						end else begin
							T_reg[i_sub][j_sub] <= T_reg[i_sub+1][j_sub];
						end
					end
				end
			end
		end
	end 
endgenerate

genvar k, l;
generate
	for (k = 0; k < 8; k = k + 1) begin: M_reg_i
		for (l = 0; l < 8; l = l + 1) begin: M_reg_j
			always @(posedge clk_gated_M_reg[k] or negedge rst_n) begin
				if (~rst_n) begin
					M_reg[k][l] <= 'd0;
				end else begin
					if (design_qkv) begin
						M_reg[k][l] <= kqv_temp[k*8 + l];
					end else if (qkv_mat2) begin
						M_reg[k][l] <= 'd0;
					end
				end
			end
		end
	end 
endgenerate

always @(posedge clk_gated_ptr or negedge rst_n) begin
	if (~rst_n) begin
		ptr <= 'd0;
	end else begin
		if (in_valid_count > 'd0) begin
			if (design_qkv) begin
				ptr <= 'd0;
			end else begin
				ptr <= (ptr == 'd7) ? 'd0: ptr + 'd1;
			end
		end else begin
			ptr <= 'd0;
		end
	end
end

genvar m;
generate
	for (m = 0; m < 8; m = m + 1) begin: mult_result_loop
		always @(posedge clk_gate_mult_result[m] or negedge rst_n) begin
			if (~rst_n) begin
				mult_result[m] <= 'd0;
			end else begin
				mult_result[m] <= (QKV_counter[2:0] == 'd0) ? T_reg[0][ptr] * M_reg[ptr][m] : mult_result[m] + T_reg[0][ptr] * M_reg[ptr][m];
			end
		end
	end
endgenerate

genvar n, o;
generate
	for (n = 0; n < 8; n = n + 1) begin: out_n
		for (o = 0; o < 8; o = o + 1) begin: out_o
			always @(posedge clk_gate_out_reg[n] or negedge rst_n) begin
				if (~rst_n) begin
					out_reg[n][o] <= 'd0;
				end else begin
					if (QKV_counter == 'd1) begin
						out_reg[n][o] <= 'd0;
					end else if (QKV_counter[2:0] == 'd0) begin
						if (n == 7) begin
							out_reg[n][o] <= mult_result[o];
						end else begin
							out_reg[n][o] <= out_reg[n+1][o];
						end
					end
				end
			end
		end
	end
endgenerate

always @(posedge clk_gated_out_valid or negedge rst_n) begin
	if (~rst_n) begin
		qkv_mat1 <= 'b0;
	end else begin
		if (in_valid_count > 'd1 && QKV_counter == 'd0) begin
			qkv_mat1 <= 'b1;
		end else begin
			qkv_mat1 <= 'b0;
		end
	end
end

always @(posedge clk_gated_out_valid2 or negedge rst_n) begin
	if (~rst_n) begin
		qkv_mat2 <= 'b0;
	end else begin
		if (QKV_counter == 'd64) begin
			qkv_mat2 <= 'b1;
		end else begin
			qkv_mat2 <= 'b0;
		end
	end
end

genvar p, q;
generate
	for (p = 0; p < 8; p = p + 1) begin: out_p
		for (q = 0; q < 8; q = q + 1) begin: out_q
			always @(*) begin
				if (qkv_mat1) begin
					out[8*p + q] = out_reg[p][q];
				end else begin
					out[8*p + q] = 'd0;
				end
			end
		end
	end
endgenerate

genvar r, s;
generate
	for (r = 0; r < 8; r = r + 1) begin
		for (s = 0; s < 8; s = s + 1) begin
			always @(*) begin
				if (qkv_mat2) begin
					out2[8*r + s] = out_reg[r][s];
				end else begin
					out2[8*r + s] = 'd0;
				end
			end
		end
	end
endgenerate

//==============================================//
//            Matmul1_and_scale                 //
//==============================================//

always @(posedge clk_gated_sub2_counter or negedge rst_n) begin
	if (~rst_n) begin
		Matmul1_and_scale_counter <= 'd0;
	end else begin
		Matmul1_and_scale_counter <= k_flag ? Matmul1_and_scale_counter + 'd1 : 'd0;
	end
end

always @(posedge clk_gated_sub2_q_ptr or negedge rst_n) begin
	if (~rst_n) begin
		q_ptr <= 'd0;
	end else begin
		if (k_flag) begin
			if (Matmul1_and_scale_counter[2:0] == 'd7) begin
				q_ptr <= q_ptr + 'd1;
			end 
		end else begin
			q_ptr <= 'd0;
		end
	end
end

always @(posedge clk_gated_sub2_k_ptr or negedge rst_n) begin
	if (~rst_n) begin
		k_ptr <= 'd0;
	end else begin
		if (k_flag) begin
			k_ptr <= k_ptr == 'd7 ? 'd0 : k_ptr + 'd1;
		end else begin
			k_ptr <= 'd0;
		end
	end
end

genvar i_sub2, j_sub2;
generate
	for (i_sub2 = 0; i_sub2 < 8; i_sub2 = i_sub2 + 1) begin: Q_i
		for (j_sub2 = 0; j_sub2 < 8; j_sub2 = j_sub2 + 1) begin: Q_j
			always @(posedge clk_gated_sub2_Q[i_sub2] or negedge rst_n) begin
				if (~rst_n) begin
					Q[i_sub2][j_sub2] <= 'd0;
				end else begin
					if (qkv_mat1 && ~q_flag) begin
						Q[i_sub2][j_sub2] <= kq[8*i_sub2 + j_sub2];
					end else if (mat1_relu) begin
						Q[i_sub2][j_sub2] <= 'd0;
					end
				end
			end
		end
	end
endgenerate

genvar k_sub2, l_sub2;
generate
	for (k_sub2 = 0; k_sub2 < 8; k_sub2 = k_sub2 + 1) begin: K_k
		for (l_sub2 = 0; l_sub2 < 8; l_sub2 = l_sub2 + 1) begin: K_l
			always @(posedge clk_gated_sub2_K[k_sub2] or negedge rst_n) begin
				if (~rst_n) begin
					K_t[k_sub2][l_sub2] <= 'd0;
				end else begin
					if (qkv_mat1 && q_flag && ~k_flag) begin
						K_t[k_sub2][l_sub2] <= kq[k_sub2 + l_sub2*8];
					end else if (mat1_relu) begin
						K_t[k_sub2][l_sub2] <= 'd0;
					end
				end
			end
		end
	end
endgenerate

always @(posedge clk_gated_sub2_q_flag or negedge rst_n) begin
	if(~rst_n) begin
		q_flag <= 'b0;
	end else begin
		case (q_flag)
			0: q_flag <= qkv_mat1 ? 1'b1 : 1'b0;
			1: q_flag <= mat1_relu ? 1'b0 : 1'b1;
		endcase
	end
end

always @(posedge clk_gated_sub2_k_flag or negedge rst_n) begin
	if (~rst_n) begin
		k_flag <= 'b0;
	end else begin
		case (k_flag)
			0: k_flag <= qkv_mat1 && q_flag ? 'b1 : 'b0;
			1: k_flag <= mat1_relu ? 'b0 : 'b1;
		endcase
	end	
end

genvar m_sub2;
generate
	for (m_sub2 = 0; m_sub2 < 8; m_sub2 = m_sub2 + 1) begin
		always @(posedge clk_gated_sub2_out_temp[m_sub2] or negedge rst_n) begin
			if (~rst_n) begin
				out_temp[m_sub2] <= 'd0;
			end else begin
				out_temp[m_sub2] <= Matmul1_and_scale_counter[2:0] == 'd0 ? Q[q_ptr][k_ptr] * K_t[k_ptr][m_sub2] : out_temp[m_sub2] + Q[q_ptr][k_ptr] * K_t[k_ptr][m_sub2];
			end
		end
	end
endgenerate

genvar n_sub2, o_sub2;
generate
	for (n_sub2 = 0; n_sub2 < 8; n_sub2 = n_sub2 + 1) begin: out_n_sub2
		for (o_sub2 = 0; o_sub2 < 8; o_sub2 = o_sub2 + 1) begin: out_o_sub2
			always @(posedge clk_gated_sub2_out[n_sub2] or negedge rst_n) begin
				if (~rst_n) begin
					Matmul1_and_scale_out[n_sub2][o_sub2] <= 'd0;
				end else begin
					if (~k_flag) begin
						Matmul1_and_scale_out[n_sub2][o_sub2] <= 'd0;
					end else if (Matmul1_and_scale_counter[2:0] == 'd0) begin
						if (n_sub2 == 7) begin
							Matmul1_and_scale_out[n_sub2][o_sub2] <= out_temp[o_sub2] / 3;
						end else begin
							Matmul1_and_scale_out[n_sub2][o_sub2] <= Matmul1_and_scale_out[n_sub2+1][o_sub2];
						end
					end
				end
			end
		end
	end
endgenerate

always @(posedge clk_gated_sub2_out_valid or negedge rst_n) begin
	if (~rst_n) begin
		mat1_relu <= 'b0;
	end else begin
		if (q_flag && k_flag && Matmul1_and_scale_counter == 'd64) begin
			mat1_relu <= 'b1;
		end else begin
			mat1_relu <= 'b0;
		end
	end
end

genvar p_sub2, q_sub2;
generate
	for (p_sub2 = 0; p_sub2 < 8; p_sub2 = p_sub2 + 1) begin: out_p_sub2
		for (q_sub2 = 0; q_sub2 < 8; q_sub2 = q_sub2 + 1) begin: out_q_sub2
			always @(*) begin
				if (mat1_relu) begin
					A[8*p_sub2 + q_sub2] = Matmul1_and_scale_out[p_sub2][q_sub2];
				end else begin
					A[8*p_sub2 + q_sub2] = 'd0;
				end
			end
		end
	end
endgenerate

//==============================================//
//       	   	     ReLU	   	   	            //
//==============================================//

genvar i_sub3;
generate
	for (i_sub3 = 0; i_sub3 < 64; i_sub3 = i_sub3 + 1) begin: ReLU_loop
		always @(posedge clk_gated_sub3_S or negedge rst_n) begin
			if (~rst_n) begin
				S[i_sub3] <= 'd0;
			end else begin
				if (mat1_relu) begin
					S[i_sub3] <= (A[i_sub3][42] == 'b0) ? A[i_sub3] : 'd0;
				end else begin
					S[i_sub3] <= 'd0;
				end
			end
		end
	end
endgenerate

always @(posedge clk_gated_sub3_out_valid or negedge rst_n) begin
	if (~rst_n) begin
		relu_mat2 <= 'b0;
	end else begin
		relu_mat2 <= mat1_relu ? 'b1 : 'b0;
	end
end

//==============================================//
//       	   	     Matmul2   	   	            //
//==============================================//

assign size_8 = size * 'd8;

always @(posedge clk_gated_sub4_counter or negedge rst_n) begin
	if(~rst_n) begin
		Matmul2_counter <= 'd0;
	end else begin
		if (s_set && v_set) begin
			Matmul2_counter <= Matmul2_counter + 'd1;
		end else begin
			Matmul2_counter <= 'd0;
		end
	end
end

always @(posedge clk_gated_sub4_s_set or negedge rst_n) begin
	if (~rst_n) begin
		s_set <= 1'b0;
	end else begin
		case (s_set)
			0: s_set <= (relu_mat2 == 1'b1) ? 1'b1 : 1'b0;
			1: s_set <= (Matmul2_counter == size_8 - 'd1) ? 1'b0 : 1'b1;	
			default: s_set <= 1'b0;								
		endcase
	end
end

always @(posedge clk_gated_sub4_v_set or negedge rst_n) begin
	if (~rst_n) begin
		v_set <= 1'b0;
	end else begin
		case (v_set)
			0: v_set <= (qkv_mat2 == 1'b1) ? 1'b1 : 1'b0;
			1: v_set <= (Matmul2_counter == size_8 - 'd1) ? 1'b0 : 1'b1;		
			default: v_set <= 1'b0;							
		endcase
	end
end

genvar i_sub4, j_sub4;
generate
	for (i_sub4 = 0; i_sub4 < 8; i_sub4 = i_sub4 + 1) begin: S_reg_i
		for (j_sub4 = 0; j_sub4 < 8; j_sub4 = j_sub4 + 1) begin: S_reg_j
			always @(posedge clk_gated_sub4_S_reg[i_sub4] or negedge rst_n) begin
				if (~rst_n) begin
					S_reg[i_sub4][j_sub4] <= 'd0;
				end else begin
					if (relu_mat2) begin
						S_reg[i_sub4][j_sub4] <= S[8*i_sub4 + j_sub4];
					end
				end
			end
		end
	end 
endgenerate

genvar k_sub4, l_sub4;
generate
	for (k_sub4 = 0; k_sub4 < 8; k_sub4 = k_sub4 + 1) begin: V_reg_k
		for (l_sub4 = 0; l_sub4 < 8; l_sub4 = l_sub4 + 1) begin: V_reg_l
			always @(posedge clk_gated_sub4_V_reg[k_sub4] or negedge rst_n) begin
				if (~rst_n) begin
					V_reg[k_sub4][l_sub4] <= 'd0;
				end else begin
					if (qkv_mat2) begin
						V_reg[k_sub4][l_sub4] <= V[8*k_sub4 + l_sub4];
					end
				end
			end
		end
	end
endgenerate

always @(posedge clk_gated_sub4_P or negedge rst_n) begin
	if (~rst_n) begin
		P <= 'd0;
	end else begin
		if (v_set && s_set) begin
			case (size)
				1: P <= S_reg[0][0] * V_reg[0][v_ptr];
				4: P <= (S_reg[s_ptr][0] * V_reg[0][v_ptr] + S_reg[s_ptr][1] * V_reg[1][v_ptr]) + (S_reg[s_ptr][2] * V_reg[2][v_ptr] + S_reg[s_ptr][3] * V_reg[3][v_ptr]);
				8: P <= ((S_reg[s_ptr][0] * V_reg[0][v_ptr] + S_reg[s_ptr][1] * V_reg[1][v_ptr]) + (S_reg[s_ptr][2] * V_reg[2][v_ptr] + S_reg[s_ptr][3] * V_reg[3][v_ptr]))
						 + ((S_reg[s_ptr][4] * V_reg[4][v_ptr] + S_reg[s_ptr][5] * V_reg[5][v_ptr]) + (S_reg[s_ptr][6] * V_reg[6][v_ptr] + S_reg[s_ptr][7] * V_reg[7][v_ptr]));
			endcase
        end else begin
            P <= 'd0;
        end
	end
end


always @(posedge clk_gated_s_ptr or negedge rst_n) begin
	if (~rst_n) begin
		s_ptr <= 'd0;
	end else begin
		if (v_set && s_set) begin
			s_ptr <= (v_ptr == 'd7) ? s_ptr + 'd1 : s_ptr;
		end else begin
			s_ptr <= 'd0;
		end
	end
end

always @(posedge clk_gated_v_ptr or negedge rst_n) begin
	if (~rst_n) begin
		v_ptr <= 'd0;
	end else begin
		if (s_set && v_set) begin
			v_ptr <= v_ptr == 'd7 ? 'd0 : v_ptr + 'd1;
		end else begin
			v_ptr <= 'd0;
		end
	end
end 

always @(posedge clk_gated_out_out_valid or negedge rst_n) begin
	if (~rst_n) begin
		out_valid <= 1'b0;
	end else begin
		case (out_valid)
			0: out_valid <= (v_set == 1'b1 && s_set == 1'b1) ? 1'b1 : 1'b0;
			1: out_valid <= (Matmul2_counter == size_8) ? 1'b0 : 1'b1;
			default: out_valid <= 1'b0;
		endcase
	end
end

assign out_last = (out_valid && Matmul2_counter == size_8) ? 'b1 : 'b0; 

endmodule

