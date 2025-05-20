// -----------------------------------------------------------------------------
// File Name  : ex.v
// Module Name: ex
// Author     : sasathreena
// Version    : 0.9
// Description: 执行单元模块
//              实现指令的算术逻辑运算和地址计算
// -----------------------------------------------------------------------------
// Revision History:
// Date        By              Version         Change Description
// -----------------------------------------------------------------------------
// 2025/04/29  sasathreena     0.9             初始版本
// 2025/04/30  sasathreena     1.0             添加分支预测支持
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// 模块: ex - 执行单元
// 功能: 执行算术逻辑运算、比较、分支等操作
// 说明: 包含ALU和分支单元，负责指令的运算和地址生成，验证分支预测结果
// -----------------------------------------------------------------------------

`include "defines.v"

// 执行模块
// 纯组合逻辑电路
module ex(

    input wire rst,

    // from id
    input wire[`InstBus] inst_i,            // 指令内容
    input wire[`InstAddrBus] inst_addr_i,   // 指令地址
    input wire reg_we_i,                    // 是否写通用寄存器
    input wire[`RegAddrBus] reg_waddr_i,    // 写通用寄存器地址
    input wire[`RegBus] reg1_rdata_i,       // 通用寄存器1输入数据
    input wire[`RegBus] reg2_rdata_i,       // 通用寄存器2输入数据
    input wire csr_we_i,                    // 是否写CSR寄存器
    input wire[`MemAddrBus] csr_waddr_i,    // 写CSR寄存器地址
    input wire[`RegBus] csr_rdata_i,        // CSR寄存器输入数据
    input wire int_assert_i,                // 中断发生标志
    input wire[`InstAddrBus] int_addr_i,    // 中断跳转地址
    input wire[`MemAddrBus] op1_i,
    input wire[`MemAddrBus] op2_i,
    input wire[`MemAddrBus] op1_jump_i,
    input wire[`MemAddrBus] op2_jump_i,

    // 分支预测接口
    input wire is_branch_i,                 // 是否是分支指令
    input wire predict_taken_i,             // 预测的跳转方向
    input wire[`InstAddrBus] predict_addr_i, // 预测的跳转地址

    // from div
    input wire div_ready_i,                 // 除法运算完成标志
    input wire[`RegBus] div_result_i,       // 除法运算结果
    input wire div_busy_i,                  // 除法运算忙标志
    input wire[`RegAddrBus] div_reg_waddr_i,// 除法运算结束后要写的寄存器地址

    // to mem
    output reg[`MemBus] mem_wdata_o,        // 写内存数据
    output reg[`MemAddrBus] mem_raddr_o,    // 读内存地址
    output reg[`MemAddrBus] mem_waddr_o,    // 写内存地址
    output wire mem_we_o,                   // 是否要写内存
    output wire mem_req_o,                  // 请求访问内存标志
    output reg[3:0] mem_sel_o,              // 字节选择信号

    // to regs
    output wire[`RegBus] reg_wdata_o,       // 写寄存器数据
    output wire reg_we_o,                   // 是否要写通用寄存器
    output wire[`RegAddrBus] reg_waddr_o,   // 写通用寄存器地址

    // to csr reg
    output reg[`RegBus] csr_wdata_o,        // 写CSR寄存器数据
    output wire csr_we_o,                   // 是否要写CSR寄存器
    output wire[`MemAddrBus] csr_waddr_o,   // 写CSR寄存器地址

    // to div
    output wire div_start_o,                // 开始除法运算标志
    output reg[`RegBus] div_dividend_o,     // 被除数
    output reg[`RegBus] div_divisor_o,      // 除数
    output reg[2:0] div_op_o,               // 具体是哪一条除法指令
    output reg[`RegAddrBus] div_reg_waddr_o,// 除法运算结束后要写的寄存器地址

    // to ctrl
    output wire hold_flag_o,                // 是否暂停标志
    output wire jump_flag_o,                // 是否跳转标志
    output wire[`InstAddrBus] jump_addr_o,   // 跳转目的地址
    
    // 分支预测输出
    output wire predict_error_o,            // 预测错误标志
    output wire[`InstAddrBus] real_branch_addr_o, // 实际的分支目标地址

    // 指令类型标志
    output wire inst_is_load_o,             // 当前指令是否为加载指令
    output wire is_branch_o,                // 当前指令是否为分支指令
    output wire branch_taken_o              // 分支是否跳转

    );

    wire[1:0] mem_raddr_index;
    wire[1:0] mem_waddr_index;
    wire[`DoubleRegBus] mul_temp;
    wire[`DoubleRegBus] mul_temp_invert;
    wire[31:0] sr_shift;
    wire[31:0] sri_shift;
    wire[31:0] sr_shift_mask;
    wire[31:0] sri_shift_mask;
    wire[31:0] op1_add_op2_res;
    wire[31:0] op1_jump_add_op2_jump_res;
    wire[31:0] reg1_data_invert;
    wire[31:0] reg2_data_invert;
    wire op1_ge_op2_signed;
    wire op1_ge_op2_unsigned;
    wire op1_eq_op2;
    reg[`RegBus] mul_op1;
    reg[`RegBus] mul_op2;
    wire[6:0] opcode;
    wire[2:0] funct3;
    wire[6:0] funct7;
    wire[4:0] rd;
    wire[4:0] uimm;
    reg[`RegBus] reg_wdata;
    reg reg_we;
    reg[`RegAddrBus] reg_waddr;
    reg[`RegBus] div_wdata;
    reg div_we;
    reg[`RegAddrBus] div_waddr;
    reg div_hold_flag;
    reg div_jump_flag;
    reg[`InstAddrBus] div_jump_addr;
    reg hold_flag;
    reg jump_flag;
    reg[`InstAddrBus] jump_addr;
    reg mem_we;
    reg mem_req;
    reg div_start;

    // 分支预测相关的变量
    reg is_branch;
    reg branch_taken;
    reg predict_error;
    reg[`InstAddrBus] real_branch_addr;

    assign opcode = inst_i[6:0];
    assign funct3 = inst_i[14:12];
    assign funct7 = inst_i[31:25];
    assign rd = inst_i[11:7];
    assign uimm = inst_i[19:15];

    assign sr_shift = reg1_rdata_i >> reg2_rdata_i[4:0];
    assign sri_shift = reg1_rdata_i >> inst_i[24:20];
    assign sr_shift_mask = 32'hffffffff >> reg2_rdata_i[4:0];
    assign sri_shift_mask = 32'hffffffff >> inst_i[24:20];

    assign op1_add_op2_res = op1_i + op2_i;
    assign op1_jump_add_op2_jump_res = op1_jump_i + op2_jump_i;

    assign reg1_data_invert = ~reg1_rdata_i + 1;
    assign reg2_data_invert = ~reg2_rdata_i + 1;

    // 有符号数比较
    assign op1_ge_op2_signed = $signed(op1_i) >= $signed(op2_i);
    // 无符号数比较
    assign op1_ge_op2_unsigned = op1_i >= op2_i;
    assign op1_eq_op2 = (op1_i == op2_i);

    assign mul_temp = mul_op1 * mul_op2;
    assign mul_temp_invert = ~mul_temp + 1;

    assign mem_raddr_index = (reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:20]}) & 2'b11;
    assign mem_waddr_index = (reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]}) & 2'b11;

    assign div_start_o = (int_assert_i == `INT_ASSERT)? `DivStop: div_start;

    assign reg_wdata_o = reg_wdata | div_wdata;
    // 响应中断时不写通用寄存器
    assign reg_we_o = (int_assert_i == `INT_ASSERT)? `WriteDisable: (reg_we || div_we);
    assign reg_waddr_o = reg_waddr | div_waddr;

    // 响应中断时不写内存
    assign mem_we_o = (int_assert_i == `INT_ASSERT)? `WriteDisable: mem_we;

    // 响应中断时不向总线请求访问内存
    assign mem_req_o = (int_assert_i == `INT_ASSERT)? `RIB_NREQ: mem_req;

    assign hold_flag_o = hold_flag || div_hold_flag;
    assign jump_flag_o = jump_flag || div_jump_flag || ((int_assert_i == `INT_ASSERT)? `JumpEnable: `JumpDisable);
    assign jump_addr_o = (int_assert_i == `INT_ASSERT)? int_addr_i: (jump_addr | div_jump_addr);

    // 响应中断时不写CSR寄存器
    assign csr_we_o = (int_assert_i == `INT_ASSERT)? `WriteDisable: csr_we_i;
    assign csr_waddr_o = csr_waddr_i;

    // 指令类型标志
    assign inst_is_load_o = (opcode == `INST_TYPE_L) ? `True : `False;

    assign is_branch_o = is_branch;
    assign branch_taken_o = branch_taken;
    assign predict_error_o = predict_error;
    assign real_branch_addr_o = real_branch_addr;

    // 处理乘法指令
    always @ (*) begin
        if ((opcode == `INST_TYPE_R_M) && (funct7 == 7'b0000001)) begin
            case (funct3)
                `INST_MUL, `INST_MULHU: begin
                    mul_op1 = reg1_rdata_i;
                    mul_op2 = reg2_rdata_i;
                end
                `INST_MULHSU: begin
                    mul_op1 = (reg1_rdata_i[31] == 1'b1)? (reg1_data_invert): reg1_rdata_i;
                    mul_op2 = reg2_rdata_i;
                end
                `INST_MULH: begin
                    mul_op1 = (reg1_rdata_i[31] == 1'b1)? (reg1_data_invert): reg1_rdata_i;
                    mul_op2 = (reg2_rdata_i[31] == 1'b1)? (reg2_data_invert): reg2_rdata_i;
                end
                default: begin
                    mul_op1 = reg1_rdata_i;
                    mul_op2 = reg2_rdata_i;
                end
            endcase
        end else begin
            mul_op1 = reg1_rdata_i;
            mul_op2 = reg2_rdata_i;
        end
    end

    // 处理除法指令
    always @ (*) begin
        div_dividend_o = reg1_rdata_i;
        div_divisor_o = reg2_rdata_i;
        div_op_o = funct3;
        div_reg_waddr_o = reg_waddr_i;
        if ((opcode == `INST_TYPE_R_M) && (funct7 == 7'b0000001)) begin
            div_we = `WriteDisable;
            div_wdata = `ZeroWord;
            div_waddr = `ZeroWord;
            case (funct3)
                `INST_DIV, `INST_DIVU, `INST_REM, `INST_REMU: begin
                    div_start = `DivStart;
                    div_jump_flag = `JumpEnable;
                    div_hold_flag = `HoldEnable;
                    div_jump_addr = op1_jump_add_op2_jump_res;
                end
                default: begin
                    div_start = `DivStop;
                    div_jump_flag = `JumpDisable;
                    div_hold_flag = `HoldDisable;
                    div_jump_addr = `ZeroWord;
                end
            endcase
        end else begin
            div_jump_flag = `JumpDisable;
            div_jump_addr = `ZeroWord;
            if (div_busy_i == `True) begin
                div_start = `DivStart;
                div_we = `WriteDisable;
                div_wdata = `ZeroWord;
                div_waddr = `ZeroWord;
                div_hold_flag = `HoldEnable;
            end else begin
                div_start = `DivStop;
                div_hold_flag = `HoldDisable;
                if (div_ready_i == `DivResultReady) begin
                    div_wdata = div_result_i;
                    div_waddr = div_reg_waddr_i;
                    div_we = `WriteEnable;
                end else begin
                    div_we = `WriteDisable;
                    div_wdata = `ZeroWord;
                    div_waddr = `ZeroWord;
                end
            end
        end
    end

    // 执行
    always @ (*) begin
        reg_we = reg_we_i;
        reg_waddr = reg_waddr_i;
        mem_req = `RIB_NREQ;
        csr_wdata_o = `ZeroWord;
        mem_sel_o = 4'b0000;

        // 分支预测相关变量初始化
        is_branch = `NotBranch;
        branch_taken = 1'b0;
        predict_error = 1'b0;
        real_branch_addr = `ZeroWord;

        case (opcode)
            `INST_TYPE_I: begin
                case (funct3)
                    `INST_ADDI: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_NREQ;
                        reg_wdata = op1_add_op2_res;
                    end
                    `INST_SLTI: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_NREQ;
                        reg_wdata = {32{(~op1_ge_op2_signed)}} & 32'h1;
                    end
                    `INST_SLTIU: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_NREQ;
                        reg_wdata = {32{(~op1_ge_op2_unsigned)}} & 32'h1;
                    end
                    `INST_XORI: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_NREQ;
                        reg_wdata = op1_i ^ op2_i;
                    end
                    `INST_ORI: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_NREQ;
                        reg_wdata = op1_i | op2_i;
                    end
                    `INST_ANDI: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_NREQ;
                        reg_wdata = op1_i & op2_i;
                    end
                    `INST_SLLI: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_NREQ;
                        reg_wdata = reg1_rdata_i << inst_i[24:20];
                    end
                    `INST_SRI: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_NREQ;
                        if (inst_i[30] == 1'b1) begin
                            reg_wdata = (sri_shift & sri_shift_mask) | ({32{reg1_rdata_i[31]}} & (~sri_shift_mask));
                        end else begin
                            reg_wdata = reg1_rdata_i >> inst_i[24:20];
                        end
                    end
                    default: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_NREQ;
                        reg_wdata = `ZeroWord;
                    end
                endcase
            end
            `INST_TYPE_R_M: begin
                if ((funct7 == 7'b0000000) || (funct7 == 7'b0100000)) begin
                    case (funct3)
                        `INST_ADD_SUB: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            mem_wdata_o = `ZeroWord;
                            mem_raddr_o = `ZeroWord;
                            mem_waddr_o = `ZeroWord;
                            mem_we = `WriteDisable;
                            mem_req = `RIB_NREQ;
                            if (inst_i[30] == 1'b0) begin
                                reg_wdata = op1_add_op2_res;
                            end else begin
                                reg_wdata = op1_i - op2_i;
                            end
                        end
                        `INST_SLL: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            mem_wdata_o = `ZeroWord;
                            mem_raddr_o = `ZeroWord;
                            mem_waddr_o = `ZeroWord;
                            mem_we = `WriteDisable;
                            mem_req = `RIB_NREQ;
                            reg_wdata = op1_i << op2_i[4:0];
                        end
                        `INST_SLT: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            mem_wdata_o = `ZeroWord;
                            mem_raddr_o = `ZeroWord;
                            mem_waddr_o = `ZeroWord;
                            mem_we = `WriteDisable;
                            mem_req = `RIB_NREQ;
                            reg_wdata = {32{(~op1_ge_op2_signed)}} & 32'h1;
                        end
                        `INST_SLTU: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            mem_wdata_o = `ZeroWord;
                            mem_raddr_o = `ZeroWord;
                            mem_waddr_o = `ZeroWord;
                            mem_we = `WriteDisable;
                            mem_req = `RIB_NREQ;
                            reg_wdata = {32{(~op1_ge_op2_unsigned)}} & 32'h1;
                        end
                        `INST_XOR: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            mem_wdata_o = `ZeroWord;
                            mem_raddr_o = `ZeroWord;
                            mem_waddr_o = `ZeroWord;
                            mem_we = `WriteDisable;
                            mem_req = `RIB_NREQ;
                            reg_wdata = op1_i ^ op2_i;
                        end
                        `INST_SR: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            mem_wdata_o = `ZeroWord;
                            mem_raddr_o = `ZeroWord;
                            mem_waddr_o = `ZeroWord;
                            mem_we = `WriteDisable;
                            mem_req = `RIB_NREQ;
                            if (inst_i[30] == 1'b1) begin
                                reg_wdata = (sr_shift & sr_shift_mask) | ({32{reg1_rdata_i[31]}} & (~sr_shift_mask));
                            end else begin
                                reg_wdata = reg1_rdata_i >> reg2_rdata_i[4:0];
                            end
                        end
                        `INST_OR: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            mem_wdata_o = `ZeroWord;
                            mem_raddr_o = `ZeroWord;
                            mem_waddr_o = `ZeroWord;
                            mem_we = `WriteDisable;
                            mem_req = `RIB_NREQ;
                            reg_wdata = op1_i | op2_i;
                        end
                        `INST_AND: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            mem_wdata_o = `ZeroWord;
                            mem_raddr_o = `ZeroWord;
                            mem_waddr_o = `ZeroWord;
                            mem_we = `WriteDisable;
                            mem_req = `RIB_NREQ;
                            reg_wdata = op1_i & op2_i;
                        end
                        default: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            mem_wdata_o = `ZeroWord;
                            mem_raddr_o = `ZeroWord;
                            mem_waddr_o = `ZeroWord;
                            mem_we = `WriteDisable;
                            mem_req = `RIB_NREQ;
                            reg_wdata = `ZeroWord;
                        end
                    endcase
                end else if (funct7 == 7'b0000001) begin
                    case (funct3)
                        `INST_MUL: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            mem_wdata_o = `ZeroWord;
                            mem_raddr_o = `ZeroWord;
                            mem_waddr_o = `ZeroWord;
                            mem_we = `WriteDisable;
                            mem_req = `RIB_NREQ;
                            reg_wdata = mul_temp[31:0];
                        end
                        `INST_MULHU: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            mem_wdata_o = `ZeroWord;
                            mem_raddr_o = `ZeroWord;
                            mem_waddr_o = `ZeroWord;
                            mem_we = `WriteDisable;
                            mem_req = `RIB_NREQ;
                            reg_wdata = mul_temp[63:32];
                        end
                        `INST_MULH: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            mem_wdata_o = `ZeroWord;
                            mem_raddr_o = `ZeroWord;
                            mem_waddr_o = `ZeroWord;
                            mem_we = `WriteDisable;
                            mem_req = `RIB_NREQ;
                            case ({reg1_rdata_i[31], reg2_rdata_i[31]})
                                2'b00: begin
                                    reg_wdata = mul_temp[63:32];
                                end
                                2'b11: begin
                                    reg_wdata = mul_temp[63:32];
                                end
                                2'b10: begin
                                    reg_wdata = mul_temp_invert[63:32];
                                end
                                default: begin
                                    reg_wdata = mul_temp_invert[63:32];
                                end
                            endcase
                        end
                        `INST_MULHSU: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            mem_wdata_o = `ZeroWord;
                            mem_raddr_o = `ZeroWord;
                            mem_waddr_o = `ZeroWord;
                            mem_we = `WriteDisable;
                            mem_req = `RIB_NREQ;
                            if (reg1_rdata_i[31] == 1'b1) begin
                                reg_wdata = mul_temp_invert[63:32];
                            end else begin
                                reg_wdata = mul_temp[63:32];
                            end
                        end
                        default: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            mem_wdata_o = `ZeroWord;
                            mem_raddr_o = `ZeroWord;
                            mem_waddr_o = `ZeroWord;
                            mem_we = `WriteDisable;
                            mem_req = `RIB_NREQ;
                            reg_wdata = `ZeroWord;
                        end
                    endcase
                end else begin
                    jump_flag = `JumpDisable;
                    hold_flag = `HoldDisable;
                    jump_addr = `ZeroWord;
                    mem_wdata_o = `ZeroWord;
                    mem_raddr_o = `ZeroWord;
                    mem_waddr_o = `ZeroWord;
                    mem_we = `WriteDisable;
                    mem_req = `RIB_NREQ;
                    reg_wdata = `ZeroWord;
                end
            end
            `INST_TYPE_L: begin
                case (funct3)
                    `INST_LB: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_REQ;
                        // 保留完整的内存地址，包括低两位
                        mem_raddr_o = op1_add_op2_res;
                        // 根据地址低两位确定访问哪个字节，生成字节选择信号
                        case (op1_add_op2_res[1:0])
                            2'b00: mem_sel_o = 4'b0001;
                            2'b01: mem_sel_o = 4'b0010;
                            2'b10: mem_sel_o = 4'b0100;
                            2'b11: mem_sel_o = 4'b1000;
                        endcase
                        reg_wdata = `ZeroWord;
                    end
                    `INST_LH: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_REQ;
                        // 保留完整的内存地址，包括低两位
                        mem_raddr_o = op1_add_op2_res;
                        // 根据地址低两位确定访问哪个半字，生成字节选择信号
                        if (op1_add_op2_res[1:0] == 2'b00) begin
                            mem_sel_o = 4'b0011;
                        end else begin
                            mem_sel_o = 4'b1100;
                        end
                        reg_wdata = `ZeroWord;
                    end
                    `INST_LW: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_REQ;
                        // 保留完整的内存地址，包括低两位
                        mem_raddr_o = op1_add_op2_res;
                        // 访问整个字，生成所有字节选择信号
                        mem_sel_o = 4'b1111;
                        reg_wdata = `ZeroWord;
                    end
                    `INST_LBU: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_REQ;
                        // 保留完整的内存地址，包括低两位
                        mem_raddr_o = op1_add_op2_res;
                        // 根据地址低两位确定访问哪个字节，生成字节选择信号
                        case (op1_add_op2_res[1:0])
                            2'b00: mem_sel_o = 4'b0001;
                            2'b01: mem_sel_o = 4'b0010;
                            2'b10: mem_sel_o = 4'b0100;
                            2'b11: mem_sel_o = 4'b1000;
                        endcase
                        reg_wdata = `ZeroWord;
                    end
                    `INST_LHU: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_REQ;
                        // 保留完整的内存地址，包括低两位
                        mem_raddr_o = op1_add_op2_res;
                        // 根据地址低两位确定访问哪个半字，生成字节选择信号
                        if (op1_add_op2_res[1:0] == 2'b00) begin
                            mem_sel_o = 4'b0011;
                        end else begin
                            mem_sel_o = 4'b1100;
                        end
                        reg_wdata = `ZeroWord;
                    end
                    default: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_NREQ;
                        reg_wdata = `ZeroWord;
                    end
                endcase
            end
            `INST_TYPE_S: begin
                case (funct3)
                    `INST_SB: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        reg_wdata = `ZeroWord;
                        mem_we = `WriteEnable;
                        mem_req = `RIB_REQ;
                        // 保留完整的内存地址，包括低两位
                        mem_waddr_o = op1_add_op2_res;
                        // 将待写入字节扩展到对应位置
                        case (op1_add_op2_res[1:0])
                            2'b00: begin
                                mem_wdata_o = {24'b0, reg2_rdata_i[7:0]};
                                mem_sel_o = 4'b0001;
                            end
                            2'b01: begin
                                mem_wdata_o = {16'b0, reg2_rdata_i[7:0], 8'b0};
                                mem_sel_o = 4'b0010;
                            end
                            2'b10: begin
                                mem_wdata_o = {8'b0, reg2_rdata_i[7:0], 16'b0};
                                mem_sel_o = 4'b0100;
                            end
                            2'b11: begin
                                mem_wdata_o = {reg2_rdata_i[7:0], 24'b0};
                                mem_sel_o = 4'b1000;
                            end
                        endcase
                        mem_raddr_o = `ZeroWord;
                    end
                    `INST_SH: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        reg_wdata = `ZeroWord;
                        mem_we = `WriteEnable;
                        mem_req = `RIB_REQ;
                        // 保留完整的内存地址，包括低两位
                        mem_waddr_o = op1_add_op2_res;
                        // 将待写入半字扩展到对应位置
                        if (op1_add_op2_res[1:0] == 2'b00) begin
                            mem_wdata_o = {16'b0, reg2_rdata_i[15:0]};
                            mem_sel_o = 4'b0011;
                        end else begin
                            mem_wdata_o = {reg2_rdata_i[15:0], 16'b0};
                            mem_sel_o = 4'b1100;
                        end
                        mem_raddr_o = `ZeroWord;
                    end
                    `INST_SW: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        reg_wdata = `ZeroWord;
                        mem_we = `WriteEnable;
                        mem_req = `RIB_REQ;
                        // 保留完整的内存地址，包括低两位
                        mem_waddr_o = op1_add_op2_res;
                        mem_wdata_o = reg2_rdata_i;
                        mem_sel_o = 4'b1111; // 写入整个字
                        mem_raddr_o = `ZeroWord;
                    end
                    default: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_NREQ;
                        reg_wdata = `ZeroWord;
                    end
                endcase
            end
            `INST_TYPE_B: begin
                is_branch = `IsBranch;
                
                case (funct3)
                    `INST_BEQ: begin
                        hold_flag = `HoldDisable;
                        mem_wdata_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_NREQ;
                        reg_wdata = `ZeroWord;
                        
                        branch_taken = op1_eq_op2;
                        real_branch_addr = op1_jump_add_op2_jump_res;
                        
                        // 如果是分支指令并且进行了预测
                        if (is_branch_i) begin
                            // 如果预测结果与实际不一致
                            if ((branch_taken && !predict_taken_i) || (!branch_taken && predict_taken_i)) begin
                                predict_error = 1'b1;
                                jump_flag = `JumpEnable;
                                if (branch_taken) begin
                                    // 实际应该跳转但预测不跳转
                                    jump_addr = op1_jump_add_op2_jump_res;
                                end else begin
                                    // 实际不应跳转但预测跳转
                                    jump_addr = inst_addr_i + 4'h4;
                                end
                            end else begin
                                // 预测正确
                                jump_flag = `JumpDisable;
                                jump_addr = branch_taken ? op1_jump_add_op2_jump_res : (inst_addr_i + 4'h4);
                            end
                        end else begin
                            // 没有预测，使用常规处理方式
                            jump_flag = branch_taken ? `JumpEnable : `JumpDisable;
                            jump_addr = branch_taken ? op1_jump_add_op2_jump_res : (inst_addr_i + 4'h4);
                        end
                    end
                    
                    `INST_BNE: begin
                        hold_flag = `HoldDisable;
                        mem_wdata_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_NREQ;
                        reg_wdata = `ZeroWord;
                        
                        branch_taken = ~op1_eq_op2;
                        real_branch_addr = op1_jump_add_op2_jump_res;
                        
                        // 如果是分支指令并且进行了预测
                        if (is_branch_i) begin
                            // 如果预测结果与实际不一致
                            if ((branch_taken && !predict_taken_i) || (!branch_taken && predict_taken_i)) begin
                                predict_error = 1'b1;
                                jump_flag = `JumpEnable;
                                if (branch_taken) begin
                                    // 实际应该跳转但预测不跳转
                                    jump_addr = op1_jump_add_op2_jump_res;
                                end else begin
                                    // 实际不应跳转但预测跳转
                                    jump_addr = inst_addr_i + 4'h4;
                                end
                            end else begin
                                // 预测正确
                                jump_flag = `JumpDisable;
                                jump_addr = branch_taken ? op1_jump_add_op2_jump_res : (inst_addr_i + 4'h4);
                            end
                        end else begin
                            // 没有预测，使用常规处理方式
                            jump_flag = branch_taken ? `JumpEnable : `JumpDisable;
                            jump_addr = branch_taken ? op1_jump_add_op2_jump_res : (inst_addr_i + 4'h4);
                        end
                    end
                    
                    `INST_BLT: begin
                        hold_flag = `HoldDisable;
                        mem_wdata_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_NREQ;
                        reg_wdata = `ZeroWord;
                        
                        branch_taken = ~op1_ge_op2_signed;
                        real_branch_addr = op1_jump_add_op2_jump_res;
                        
                        // 如果是分支指令并且进行了预测
                        if (is_branch_i) begin
                            // 如果预测结果与实际不一致
                            if ((branch_taken && !predict_taken_i) || (!branch_taken && predict_taken_i)) begin
                                predict_error = 1'b1;
                                jump_flag = `JumpEnable;
                                if (branch_taken) begin
                                    // 实际应该跳转但预测不跳转
                                    jump_addr = op1_jump_add_op2_jump_res;
                                end else begin
                                    // 实际不应跳转但预测跳转
                                    jump_addr = inst_addr_i + 4'h4;
                                end
                            end else begin
                                // 预测正确
                                jump_flag = `JumpDisable;
                                jump_addr = branch_taken ? op1_jump_add_op2_jump_res : (inst_addr_i + 4'h4);
                            end
                        end else begin
                            // 没有预测，使用常规处理方式
                            jump_flag = branch_taken ? `JumpEnable : `JumpDisable;
                            jump_addr = branch_taken ? op1_jump_add_op2_jump_res : (inst_addr_i + 4'h4);
                        end
                    end
                    
                    `INST_BGE: begin
                        hold_flag = `HoldDisable;
                        mem_wdata_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_NREQ;
                        reg_wdata = `ZeroWord;
                        
                        branch_taken = op1_ge_op2_signed;
                        real_branch_addr = op1_jump_add_op2_jump_res;
                        
                        // 如果是分支指令并且进行了预测
                        if (is_branch_i) begin
                            // 如果预测结果与实际不一致
                            if ((branch_taken && !predict_taken_i) || (!branch_taken && predict_taken_i)) begin
                                predict_error = 1'b1;
                                jump_flag = `JumpEnable;
                                if (branch_taken) begin
                                    // 实际应该跳转但预测不跳转
                                    jump_addr = op1_jump_add_op2_jump_res;
                                end else begin
                                    // 实际不应跳转但预测跳转
                                    jump_addr = inst_addr_i + 4'h4;
                                end
                            end else begin
                                // 预测正确
                                jump_flag = `JumpDisable;
                                jump_addr = branch_taken ? op1_jump_add_op2_jump_res : (inst_addr_i + 4'h4);
                            end
                        end else begin
                            // 没有预测，使用常规处理方式
                            jump_flag = branch_taken ? `JumpEnable : `JumpDisable;
                            jump_addr = branch_taken ? op1_jump_add_op2_jump_res : (inst_addr_i + 4'h4);
                        end
                    end
                    
                    `INST_BLTU: begin
                        hold_flag = `HoldDisable;
                        mem_wdata_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_NREQ;
                        reg_wdata = `ZeroWord;
                        
                        branch_taken = ~op1_ge_op2_unsigned;
                        real_branch_addr = op1_jump_add_op2_jump_res;
                        
                        // 如果是分支指令并且进行了预测
                        if (is_branch_i) begin
                            // 如果预测结果与实际不一致
                            if ((branch_taken && !predict_taken_i) || (!branch_taken && predict_taken_i)) begin
                                predict_error = 1'b1;
                                jump_flag = `JumpEnable;
                                if (branch_taken) begin
                                    // 实际应该跳转但预测不跳转
                                    jump_addr = op1_jump_add_op2_jump_res;
                                end else begin
                                    // 实际不应跳转但预测跳转
                                    jump_addr = inst_addr_i + 4'h4;
                                end
                            end else begin
                                // 预测正确
                                jump_flag = `JumpDisable;
                                jump_addr = branch_taken ? op1_jump_add_op2_jump_res : (inst_addr_i + 4'h4);
                            end
                        end else begin
                            // 没有预测，使用常规处理方式
                            jump_flag = branch_taken ? `JumpEnable : `JumpDisable;
                            jump_addr = branch_taken ? op1_jump_add_op2_jump_res : (inst_addr_i + 4'h4);
                        end
                    end
                    
                    `INST_BGEU: begin
                        hold_flag = `HoldDisable;
                        mem_wdata_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_NREQ;
                        reg_wdata = `ZeroWord;
                        
                        branch_taken = op1_ge_op2_unsigned;
                        real_branch_addr = op1_jump_add_op2_jump_res;
                        
                        // 如果是分支指令并且进行了预测
                        if (is_branch_i) begin
                            // 如果预测结果与实际不一致
                            if ((branch_taken && !predict_taken_i) || (!branch_taken && predict_taken_i)) begin
                                predict_error = 1'b1;
                                jump_flag = `JumpEnable;
                                if (branch_taken) begin
                                    // 实际应该跳转但预测不跳转
                                    jump_addr = op1_jump_add_op2_jump_res;
                                end else begin
                                    // 实际不应跳转但预测跳转
                                    jump_addr = inst_addr_i + 4'h4;
                                end
                            end else begin
                                // 预测正确
                                jump_flag = `JumpDisable;
                                jump_addr = branch_taken ? op1_jump_add_op2_jump_res : (inst_addr_i + 4'h4);
                            end
                        end else begin
                            // 没有预测，使用常规处理方式
                            jump_flag = branch_taken ? `JumpEnable : `JumpDisable;
                            jump_addr = branch_taken ? op1_jump_add_op2_jump_res : (inst_addr_i + 4'h4);
                        end
                    end
                    
                    default: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_NREQ;
                        reg_wdata = `ZeroWord;
                    end
                endcase
            end
            
            `INST_JAL, `INST_JALR: begin
                is_branch = `IsBranch;
                branch_taken = 1'b1; // JAL和JALR总是跳转
                real_branch_addr = op1_jump_add_op2_jump_res;
                
                hold_flag = `HoldDisable;
                mem_wdata_o = `ZeroWord;
                mem_raddr_o = `ZeroWord;
                mem_waddr_o = `ZeroWord;
                mem_we = `WriteDisable;
                mem_req = `RIB_NREQ;
                reg_wdata = op1_add_op2_res;
                
                // 如果是分支指令并且进行了预测
                if (is_branch_i) begin
                    // 如果预测结果与实际不一致 (对于JAL/JALR，预测应当跳转且地址应当正确)
                    if (!predict_taken_i || (predict_taken_i && (predict_addr_i != op1_jump_add_op2_jump_res))) begin
                        predict_error = 1'b1;
                        jump_flag = `JumpEnable;
                        jump_addr = op1_jump_add_op2_jump_res;
                    end else begin
                        // 预测正确
                        jump_flag = `JumpDisable;
                    end
                end else begin
                    // 没有预测，使用常规处理方式
                    jump_flag = `JumpEnable;
                    jump_addr = op1_jump_add_op2_jump_res;
                end
            end
            
            `INST_LUI, `INST_AUIPC: begin
                hold_flag = `HoldDisable;
                mem_wdata_o = `ZeroWord;
                mem_raddr_o = `ZeroWord;
                mem_waddr_o = `ZeroWord;
                mem_we = `WriteDisable;
                mem_req = `RIB_NREQ;
                jump_addr = `ZeroWord;
                jump_flag = `JumpDisable;
                reg_wdata = op1_add_op2_res;
            end
            `INST_NOP_OP: begin
                jump_flag = `JumpDisable;
                hold_flag = `HoldDisable;
                jump_addr = `ZeroWord;
                mem_wdata_o = `ZeroWord;
                mem_raddr_o = `ZeroWord;
                mem_waddr_o = `ZeroWord;
                mem_we = `WriteDisable;
                mem_req = `RIB_NREQ;
                reg_wdata = `ZeroWord;
            end
            `INST_FENCE: begin
                hold_flag = `HoldDisable;
                mem_wdata_o = `ZeroWord;
                mem_raddr_o = `ZeroWord;
                mem_waddr_o = `ZeroWord;
                mem_we = `WriteDisable;
                mem_req = `RIB_NREQ;
                reg_wdata = `ZeroWord;
                jump_flag = `JumpEnable;
                jump_addr = op1_jump_add_op2_jump_res;
            end
            `INST_CSR: begin
                jump_flag = `JumpDisable;
                hold_flag = `HoldDisable;
                jump_addr = `ZeroWord;
                mem_wdata_o = `ZeroWord;
                mem_raddr_o = `ZeroWord;
                mem_waddr_o = `ZeroWord;
                mem_we = `WriteDisable;
                mem_req = `RIB_NREQ;
                case (funct3)
                    `INST_CSRRW: begin
                        csr_wdata_o = reg1_rdata_i;
                        reg_wdata = csr_rdata_i;
                    end
                    `INST_CSRRS: begin
                        csr_wdata_o = reg1_rdata_i | csr_rdata_i;
                        reg_wdata = csr_rdata_i;
                    end
                    `INST_CSRRC: begin
                        csr_wdata_o = csr_rdata_i & (~reg1_rdata_i);
                        reg_wdata = csr_rdata_i;
                    end
                    `INST_CSRRWI: begin
                        csr_wdata_o = {27'h0, uimm};
                        reg_wdata = csr_rdata_i;
                    end
                    `INST_CSRRSI: begin
                        csr_wdata_o = {27'h0, uimm} | csr_rdata_i;
                        reg_wdata = csr_rdata_i;
                    end
                    `INST_CSRRCI: begin
                        csr_wdata_o = (~{27'h0, uimm}) & csr_rdata_i;
                        reg_wdata = csr_rdata_i;
                    end
                    default: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        mem_wdata_o = `ZeroWord;
                        mem_raddr_o = `ZeroWord;
                        mem_waddr_o = `ZeroWord;
                        mem_we = `WriteDisable;
                        mem_req = `RIB_NREQ;
                        reg_wdata = `ZeroWord;
                    end
                endcase
            end
            default: begin
                jump_flag = `JumpDisable;
                hold_flag = `HoldDisable;
                jump_addr = `ZeroWord;
                mem_wdata_o = `ZeroWord;
                mem_raddr_o = `ZeroWord;
                mem_waddr_o = `ZeroWord;
                mem_we = `WriteDisable;
                mem_req = `RIB_NREQ;
                reg_wdata = `ZeroWord;
            end
        endcase
    end

endmodule
