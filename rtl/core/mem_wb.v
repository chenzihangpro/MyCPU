`include "defines.v"

// 将访存结果向写回阶段传递
module mem_wb(

    input wire clk,
    input wire rst,

    input wire[`InstBus] inst_i,            // 指令内容
    input wire[`InstAddrBus] inst_addr_i,   // 指令地址
    input wire reg_we_i,                    // 写通用寄存器标志
    input wire[`RegAddrBus] reg_waddr_i,    // 写通用寄存器地址
    input wire[`RegBus] reg_wdata_i,        // 写寄存器数据
    input wire csr_we_i,                    // 写CSR寄存器标志
    input wire[`MemAddrBus] csr_waddr_i,    // 写CSR寄存器地址
    input wire[`RegBus] csr_wdata_i,        // 写CSR寄存器数据
    input wire jump_flag_i,                 // 跳转标志
    input wire[`InstAddrBus] jump_addr_i,   // 跳转目的地址

    input wire[`Hold_Flag_Bus] hold_flag_i, // 流水线暂停标志

    output wire[`InstBus] inst_o,           // 指令内容
    output wire[`InstAddrBus] inst_addr_o,  // 指令地址
    output wire reg_we_o,                   // 写通用寄存器标志
    output wire[`RegAddrBus] reg_waddr_o,   // 写通用寄存器地址
    output wire[`RegBus] reg_wdata_o,       // 写寄存器数据
    output wire csr_we_o,                   // 写CSR寄存器标志
    output wire[`MemAddrBus] csr_waddr_o,   // 写CSR寄存器地址
    output wire[`RegBus] csr_wdata_o,       // 写CSR寄存器数据
    output wire jump_flag_o,                // 跳转标志
    output wire[`InstAddrBus] jump_addr_o   // 跳转目的地址

    );

    wire hold_en = (hold_flag_i >= `Hold_Mem);

    wire[`InstBus] inst;
    gen_pipe_dff #(32) inst_ff(clk, rst, hold_en, `INST_NOP, inst_i, inst);
    assign inst_o = inst;

    wire[`InstAddrBus] inst_addr;
    gen_pipe_dff #(32) inst_addr_ff(clk, rst, hold_en, `ZeroWord, inst_addr_i, inst_addr);
    assign inst_addr_o = inst_addr;

    wire reg_we;
    gen_pipe_dff #(1) reg_we_ff(clk, rst, hold_en, `WriteDisable, reg_we_i, reg_we);
    assign reg_we_o = reg_we;

    wire[`RegAddrBus] reg_waddr;
    gen_pipe_dff #(5) reg_waddr_ff(clk, rst, hold_en, `ZeroReg, reg_waddr_i, reg_waddr);
    assign reg_waddr_o = reg_waddr;

    wire[`RegBus] reg_wdata;
    gen_pipe_dff #(32) reg_wdata_ff(clk, rst, hold_en, `ZeroWord, reg_wdata_i, reg_wdata);
    assign reg_wdata_o = reg_wdata;

    wire csr_we;
    gen_pipe_dff #(1) csr_we_ff(clk, rst, hold_en, `WriteDisable, csr_we_i, csr_we);
    assign csr_we_o = csr_we;

    wire[`MemAddrBus] csr_waddr;
    gen_pipe_dff #(32) csr_waddr_ff(clk, rst, hold_en, `ZeroWord, csr_waddr_i, csr_waddr);
    assign csr_waddr_o = csr_waddr;

    wire[`RegBus] csr_wdata;
    gen_pipe_dff #(32) csr_wdata_ff(clk, rst, hold_en, `ZeroWord, csr_wdata_i, csr_wdata);
    assign csr_wdata_o = csr_wdata;

    wire jump_flag;
    gen_pipe_dff #(1) jump_flag_ff(clk, rst, hold_en, `JumpDisable, jump_flag_i, jump_flag);
    assign jump_flag_o = jump_flag;

    wire[`InstAddrBus] jump_addr;
    gen_pipe_dff #(32) jump_addr_ff(clk, rst, hold_en, `ZeroWord, jump_addr_i, jump_addr);
    assign jump_addr_o = jump_addr;

endmodule 