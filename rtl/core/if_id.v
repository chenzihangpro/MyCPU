`include "defines.v"

// 将指令向译码模块传递
module if_id(

    input wire clk,
    input wire rst,

    input wire[`InstBus] inst_i,            // 指令内容
    input wire[`InstAddrBus] inst_addr_i,   // 指令地址

    input wire[`Hold_Flag_Bus] hold_flag_i, // 流水线暂停标志

    input wire[`INT_BUS] int_flag_i,        // 外设中断输入信号
    output wire[`INT_BUS] int_flag_o,

    // 分支预测接口
    input wire predict_taken_i,             // 分支预测结果
    input wire[`InstAddrBus] predict_addr_i, // 预测的跳转地址
    output wire predict_taken_o,             // 传递给ID阶段的预测结果
    output wire[`InstAddrBus] predict_addr_o, // 传递给ID阶段的预测地址

    output wire[`InstBus] inst_o,           // 指令内容
    output wire[`InstAddrBus] inst_addr_o   // 指令地址

    );

    wire hold_en = (hold_flag_i >= `Hold_If);

    wire[`InstBus] inst;
    gen_pipe_dff #(32) inst_ff(clk, rst, hold_en, `INST_NOP, inst_i, inst);
    assign inst_o = inst;

    wire[`InstAddrBus] inst_addr;
    gen_pipe_dff #(32) inst_addr_ff(clk, rst, hold_en, `ZeroWord, inst_addr_i, inst_addr);
    assign inst_addr_o = inst_addr;

    wire[`INT_BUS] int_flag;
    gen_pipe_dff #(8) int_ff(clk, rst, hold_en, `INT_NONE, int_flag_i, int_flag);
    assign int_flag_o = int_flag;

    // 传递分支预测信息
    wire predict_taken;
    gen_pipe_dff #(1) predict_taken_ff(clk, rst, hold_en, `PredictNotTaken, predict_taken_i, predict_taken);
    assign predict_taken_o = predict_taken;

    wire[`InstAddrBus] predict_addr;
    gen_pipe_dff #(32) predict_addr_ff(clk, rst, hold_en, `ZeroWord, predict_addr_i, predict_addr);
    assign predict_addr_o = predict_addr;

endmodule
