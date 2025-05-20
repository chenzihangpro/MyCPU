// -----------------------------------------------------------------------------
// File Name  : id.v
// Module Name: id
// Author     : sasathreena
// Version    : 0.9
// Description: 指令译码单元模块
//              实现指令解码和控制信号生成
// -----------------------------------------------------------------------------
// Revision History:
// Date        By              Version         Change Description
// -----------------------------------------------------------------------------
// 2025/05/01  sasathreena     0.9             初始版本
// 2025/05/01  sasathreena     1.0             添加分支预测支持
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// 模块: id - 指令译码单元
// 功能: 解析指令格式，生成操作控制信号
// 说明: 支持RV32I基本指令集，产生ALU和寄存器操作控制信号，添加分支预测功能
// -----------------------------------------------------------------------------

`include "defines.v"

// 译码模块
// 纯组合逻辑电路
module id(

	input wire rst,

    // from if_id
    input wire[`InstBus] inst_i,             // 指令内容
    input wire[`InstAddrBus] inst_addr_i,    // 指令地址

    // from regs
    input wire[`RegBus] reg1_rdata_i,        // 通用寄存器1输入数据
    input wire[`RegBus] reg2_rdata_i,        // 通用寄存器2输入数据

    // from csr reg
    input wire[`RegBus] csr_rdata_i,         // CSR寄存器输入数据

    // from ex
    input wire ex_jump_flag_i,               // 跳转标志
    
    // 数据前馈输入
    input wire ex_reg_we_i,                  // EX阶段的寄存器写使能
    input wire[`RegAddrBus] ex_reg_waddr_i,  // EX阶段的寄存器写地址
    input wire[`RegBus] ex_reg_wdata_i,      // EX阶段的寄存器写数据
    input wire ex_inst_is_load,              // EX阶段的指令是否为加载指令
    
    input wire mem_reg_we_i,                 // MEM阶段的寄存器写使能
    input wire[`RegAddrBus] mem_reg_waddr_i, // MEM阶段的寄存器写地址
    input wire[`RegBus] mem_reg_wdata_i,     // MEM阶段的寄存器写数据
    
    input wire wb_reg_we_i,                  // WB阶段的寄存器写使能
    input wire[`RegAddrBus] wb_reg_waddr_i,  // WB阶段的寄存器写地址
    input wire[`RegBus] wb_reg_wdata_i,      // WB阶段的寄存器写数据

    // 分支预测接口
    input wire predict_taken_i,              // 预测的跳转方向
    input wire[`InstAddrBus] predict_addr_i, // 预测的跳转地址
    output reg is_branch_o,                  // 是否是分支指令
    output reg predict_taken_o,              // 传递给下一阶段的预测结果
    output reg[`InstAddrBus] predict_addr_o, // 传递给下一阶段的预测地址

    // to regs
    output reg[`RegAddrBus] reg1_raddr_o,    // 读通用寄存器1地址
    output reg[`RegAddrBus] reg2_raddr_o,    // 读通用寄存器2地址

    // to csr reg
    output reg[`MemAddrBus] csr_raddr_o,     // 读CSR寄存器地址

    // to ex
    output reg[`MemAddrBus] op1_o,
    output reg[`MemAddrBus] op2_o,
    output reg[`MemAddrBus] op1_jump_o,
    output reg[`MemAddrBus] op2_jump_o,
    output reg[`InstBus] inst_o,             // 指令内容
    output reg[`InstAddrBus] inst_addr_o,    // 指令地址
    output reg[`RegBus] reg1_rdata_o,        // 通用寄存器1数据
    output reg[`RegBus] reg2_rdata_o,        // 通用寄存器2数据
    output reg reg_we_o,                     // 写通用寄存器标志
    output reg[`RegAddrBus] reg_waddr_o,     // 写通用寄存器地址
    output reg csr_we_o,                     // 写CSR寄存器标志
    output reg[`RegBus] csr_rdata_o,         // CSR寄存器数据
    output reg[`MemAddrBus] csr_waddr_o,      // 写CSR寄存器地址
    output reg load_use_relevant_o           // load-use相关标志

    );

    wire[6:0] opcode = inst_i[6:0];
    wire[2:0] funct3 = inst_i[14:12];
    wire[6:0] funct7 = inst_i[31:25];
    wire[4:0] rd = inst_i[11:7];
    wire[4:0] rs1 = inst_i[19:15];
    wire[4:0] rs2 = inst_i[24:20];
    
    // 声明寄存器1数据前馈相关的变量
    reg reg1_raw_ex;   // 寄存器1 EX阶段数据相关
    reg reg1_raw_mem;  // 寄存器1 MEM阶段数据相关
    reg reg1_raw_wb;   // 寄存器1 WB阶段数据相关
    wire[`RegBus] reg1_data; // 最终使用的寄存器1数据
    
    // 声明寄存器2数据前馈相关的变量
    reg reg2_raw_ex;   // 寄存器2 EX阶段数据相关
    reg reg2_raw_mem;  // 寄存器2 MEM阶段数据相关
    reg reg2_raw_wb;   // 寄存器2 WB阶段数据相关
    wire[`RegBus] reg2_data; // 最终使用的寄存器2数据
    
    // 检测寄存器1数据相关
    always @ (*) begin
        // 默认值
        reg1_raw_ex = 1'b0;
        reg1_raw_mem = 1'b0;
        reg1_raw_wb = 1'b0;
        
        // 检测EX阶段数据相关
        if ((ex_reg_we_i == `WriteEnable) && (ex_reg_waddr_i != `ZeroReg) && (ex_reg_waddr_i == rs1)) begin
            reg1_raw_ex = 1'b1;
        // 检测MEM阶段数据相关
        end else if ((mem_reg_we_i == `WriteEnable) && (mem_reg_waddr_i != `ZeroReg) && (mem_reg_waddr_i == rs1)) begin
            reg1_raw_mem = 1'b1;
        // 检测WB阶段数据相关
        end else if ((wb_reg_we_i == `WriteEnable) && (wb_reg_waddr_i != `ZeroReg) && (wb_reg_waddr_i == rs1)) begin
            reg1_raw_wb = 1'b1;
        end
    end
    
    // 检测寄存器2数据相关
    always @ (*) begin
        // 默认值
        reg2_raw_ex = 1'b0;
        reg2_raw_mem = 1'b0;
        reg2_raw_wb = 1'b0;
        
        // 检测EX阶段数据相关
        if ((ex_reg_we_i == `WriteEnable) && (ex_reg_waddr_i != `ZeroReg) && (ex_reg_waddr_i == rs2)) begin
            reg2_raw_ex = 1'b1;
        // 检测MEM阶段数据相关
        end else if ((mem_reg_we_i == `WriteEnable) && (mem_reg_waddr_i != `ZeroReg) && (mem_reg_waddr_i == rs2)) begin
            reg2_raw_mem = 1'b1;
        // 检测WB阶段数据相关
        end else if ((wb_reg_we_i == `WriteEnable) && (wb_reg_waddr_i != `ZeroReg) && (wb_reg_waddr_i == rs2)) begin
            reg2_raw_wb = 1'b1;
        end
    end
    
    // 确定寄存器1最终使用的数据
    assign reg1_data = (rs1 == `ZeroReg) ? `ZeroWord :
                       reg1_raw_ex ? ex_reg_wdata_i :
                       reg1_raw_mem ? mem_reg_wdata_i :
                       reg1_raw_wb ? wb_reg_wdata_i :
                       reg1_rdata_i;
    
    // 确定寄存器2最终使用的数据
    assign reg2_data = (rs2 == `ZeroReg) ? `ZeroWord :
                       reg2_raw_ex ? ex_reg_wdata_i :
                       reg2_raw_mem ? mem_reg_wdata_i :
                       reg2_raw_wb ? wb_reg_wdata_i :
                       reg2_rdata_i;

    // 识别分支指令及传递分支预测信息
    always @ (*) begin
        is_branch_o = `NotBranch;
        predict_taken_o = predict_taken_i;
        predict_addr_o = predict_addr_i;
        
        // 检查是否为分支或跳转指令
        if (opcode == `INST_TYPE_B) begin
            is_branch_o = `IsBranch;
            // 这里只传递IF阶段的预测结果，但需要确保预测地址有效
            // 如果预测地址为0，可能是无效的，则不采用预测
            if (predict_addr_i == 32'h0) begin
                predict_taken_o = `PredictNotTaken;
            end
        end else if (opcode == `INST_JAL || opcode == `INST_JALR) begin
            // 对于JAL和JALR，我们可以固定认为会跳转
            is_branch_o = `IsBranch;
            
            // JAL/JALR总是跳转，但我们依然尊重预测结果
            // 对于JAL，可以计算精确的跳转地址
            if (opcode == `INST_JAL) begin
                // 对于JAL指令，预测地址可以在ID阶段精确计算
                predict_taken_o = `PredictTaken;
                predict_addr_o = inst_addr_i + {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
            end
        end
    end

    always @ (*) begin
        inst_o = inst_i;
        inst_addr_o = inst_addr_i;
        // 使用前馈后的数据而不是直接从寄存器堆读取的数据
        reg1_rdata_o = reg1_data;
        reg2_rdata_o = reg2_data;
        csr_rdata_o = csr_rdata_i;
        csr_raddr_o = `ZeroWord;
        csr_waddr_o = `ZeroWord;
        csr_we_o = `WriteDisable;
        op1_o = `ZeroWord;
        op2_o = `ZeroWord;
        op1_jump_o = `ZeroWord;
        op2_jump_o = `ZeroWord;

        case (opcode)
            `INST_TYPE_I: begin
                case (funct3)
                    `INST_ADDI, `INST_SLTI, `INST_SLTIU, `INST_XORI, `INST_ORI, `INST_ANDI, `INST_SLLI, `INST_SRI: begin
                        reg_we_o = `WriteEnable;
                        reg_waddr_o = rd;
                        reg1_raddr_o = rs1;
                        reg2_raddr_o = `ZeroReg;
                        op1_o = reg1_data; // 使用前馈后的数据
                        op2_o = {{20{inst_i[31]}}, inst_i[31:20]};
                    end
                    default: begin
                        reg_we_o = `WriteDisable;
                        reg_waddr_o = `ZeroReg;
                        reg1_raddr_o = `ZeroReg;
                        reg2_raddr_o = `ZeroReg;
                    end
                endcase
            end
            `INST_TYPE_R_M: begin
                if ((funct7 == 7'b0000000) || (funct7 == 7'b0100000)) begin
                    case (funct3)
                        `INST_ADD_SUB, `INST_SLL, `INST_SLT, `INST_SLTU, `INST_XOR, `INST_SR, `INST_OR, `INST_AND: begin
                            reg_we_o = `WriteEnable;
                            reg_waddr_o = rd;
                            reg1_raddr_o = rs1;
                            reg2_raddr_o = rs2;
                            op1_o = reg1_data;
                            op2_o = reg2_data;
                        end
                        default: begin
                            reg_we_o = `WriteDisable;
                            reg_waddr_o = `ZeroReg;
                            reg1_raddr_o = `ZeroReg;
                            reg2_raddr_o = `ZeroReg;
                        end
                    endcase
                end else if (funct7 == 7'b0000001) begin
                    case (funct3)
                        `INST_MUL, `INST_MULHU, `INST_MULH, `INST_MULHSU: begin
                            reg_we_o = `WriteEnable;
                            reg_waddr_o = rd;
                            reg1_raddr_o = rs1;
                            reg2_raddr_o = rs2;
                            op1_o = reg1_data;
                            op2_o = reg2_data;
                        end
                        `INST_DIV, `INST_DIVU, `INST_REM, `INST_REMU: begin
                            reg_we_o = `WriteDisable;
                            reg_waddr_o = rd;
                            reg1_raddr_o = rs1;
                            reg2_raddr_o = rs2;
                            op1_o = reg1_data;
                            op2_o = reg2_data;
                            op1_jump_o = inst_addr_i;
                            op2_jump_o = 32'h4;
                        end
                        default: begin
                            reg_we_o = `WriteDisable;
                            reg_waddr_o = `ZeroReg;
                            reg1_raddr_o = `ZeroReg;
                            reg2_raddr_o = `ZeroReg;
                        end
                    endcase
                end else begin
                    reg_we_o = `WriteDisable;
                    reg_waddr_o = `ZeroReg;
                    reg1_raddr_o = `ZeroReg;
                    reg2_raddr_o = `ZeroReg;
                end
            end
            `INST_TYPE_L: begin
                case (funct3)
                    `INST_LB, `INST_LH, `INST_LW, `INST_LBU, `INST_LHU: begin
                        reg1_raddr_o = rs1;
                        reg2_raddr_o = `ZeroReg;
                        reg_we_o = `WriteEnable;
                        reg_waddr_o = rd;
                        op1_o = reg1_data;
                        op2_o = {{20{inst_i[31]}}, inst_i[31:20]};
                    end
                    default: begin
                        reg1_raddr_o = `ZeroReg;
                        reg2_raddr_o = `ZeroReg;
                        reg_we_o = `WriteDisable;
                        reg_waddr_o = `ZeroReg;
                    end
                endcase
            end
            `INST_TYPE_S: begin
                case (funct3)
                    `INST_SB, `INST_SW, `INST_SH: begin
                        reg1_raddr_o = rs1;
                        reg2_raddr_o = rs2;
                        reg_we_o = `WriteDisable;
                        reg_waddr_o = `ZeroReg;
                        op1_o = reg1_data;
                        op2_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
                    end
                    default: begin
                        reg1_raddr_o = `ZeroReg;
                        reg2_raddr_o = `ZeroReg;
                        reg_we_o = `WriteDisable;
                        reg_waddr_o = `ZeroReg;
                    end
                endcase
            end
            `INST_TYPE_B: begin
                case (funct3)
                    `INST_BEQ, `INST_BNE, `INST_BLT, `INST_BGE, `INST_BLTU, `INST_BGEU: begin
                        reg1_raddr_o = rs1;
                        reg2_raddr_o = rs2;
                        reg_we_o = `WriteDisable;
                        reg_waddr_o = `ZeroReg;
                        op1_o = reg1_data;
                        op2_o = reg2_data;
                        op1_jump_o = inst_addr_i;
                        op2_jump_o = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                    end
                    default: begin
                        reg1_raddr_o = `ZeroReg;
                        reg2_raddr_o = `ZeroReg;
                        reg_we_o = `WriteDisable;
                        reg_waddr_o = `ZeroReg;
                    end
                endcase
            end
            `INST_JAL: begin
                reg_we_o = `WriteEnable;
                reg_waddr_o = rd;
                reg1_raddr_o = `ZeroReg;
                reg2_raddr_o = `ZeroReg;
                op1_o = inst_addr_i;
                op2_o = 32'h4;
                op1_jump_o = inst_addr_i;
                op2_jump_o = {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
            end
            `INST_JALR: begin
                reg_we_o = `WriteEnable;
                reg1_raddr_o = rs1;
                reg2_raddr_o = `ZeroReg;
                reg_waddr_o = rd;
                op1_o = inst_addr_i;
                op2_o = 32'h4;
                op1_jump_o = reg1_data;
                op2_jump_o = {{20{inst_i[31]}}, inst_i[31:20]};
            end
            `INST_LUI: begin
                reg_we_o = `WriteEnable;
                reg_waddr_o = rd;
                reg1_raddr_o = `ZeroReg;
                reg2_raddr_o = `ZeroReg;
                op1_o = {inst_i[31:12], 12'b0};
                op2_o = `ZeroWord;
            end
            `INST_AUIPC: begin
                reg_we_o = `WriteEnable;
                reg_waddr_o = rd;
                reg1_raddr_o = `ZeroReg;
                reg2_raddr_o = `ZeroReg;
                op1_o = inst_addr_i;
                op2_o = {inst_i[31:12], 12'b0};
            end
            `INST_NOP_OP: begin
                reg_we_o = `WriteDisable;
                reg_waddr_o = `ZeroReg;
                reg1_raddr_o = `ZeroReg;
                reg2_raddr_o = `ZeroReg;
            end
            `INST_FENCE: begin
                reg_we_o = `WriteDisable;
                reg_waddr_o = `ZeroReg;
                reg1_raddr_o = `ZeroReg;
                reg2_raddr_o = `ZeroReg;
                op1_jump_o = inst_addr_i;
                op2_jump_o = 32'h4;
            end
            `INST_CSR: begin
                reg_we_o = `WriteDisable;
                reg_waddr_o = `ZeroReg;
                reg1_raddr_o = `ZeroReg;
                reg2_raddr_o = `ZeroReg;
                csr_raddr_o = {20'h0, inst_i[31:20]};
                csr_waddr_o = {20'h0, inst_i[31:20]};
                case (funct3)
                    `INST_CSRRW, `INST_CSRRS, `INST_CSRRC: begin
                        reg1_raddr_o = rs1;
                        reg2_raddr_o = `ZeroReg;
                        reg_we_o = `WriteEnable;
                        reg_waddr_o = rd;
                        csr_we_o = `WriteEnable;
                    end
                    `INST_CSRRWI, `INST_CSRRSI, `INST_CSRRCI: begin
                        reg1_raddr_o = `ZeroReg;
                        reg2_raddr_o = `ZeroReg;
                        reg_we_o = `WriteEnable;
                        reg_waddr_o = rd;
                        csr_we_o = `WriteEnable;
                    end
                    default: begin
                        reg_we_o = `WriteDisable;
                        reg_waddr_o = `ZeroReg;
                        reg1_raddr_o = `ZeroReg;
                        reg2_raddr_o = `ZeroReg;
                        csr_we_o = `WriteDisable;
                    end
                endcase
            end
            default: begin
                reg_we_o = `WriteDisable;
                reg_waddr_o = `ZeroReg;
                reg1_raddr_o = `ZeroReg;
                reg2_raddr_o = `ZeroReg;
            end
        endcase
    end

    // load-use相关性检测 - 当前指令要读取的寄存器是EX阶段的load指令要写的寄存器
    always @ (*) begin
        // 默认没有load-use相关
        load_use_relevant_o = 1'b0;
        
        // 如果EX阶段指令是load类型，且当前指令读取的寄存器与EX阶段要写入的寄存器相同
        if (ex_inst_is_load && ex_reg_we_i && ex_reg_waddr_i != `ZeroReg) begin
            if ((reg1_raddr_o != `ZeroReg && reg1_raddr_o == ex_reg_waddr_i) || 
                (reg2_raddr_o != `ZeroReg && reg2_raddr_o == ex_reg_waddr_i)) begin
                load_use_relevant_o = 1'b1;
            end
        end
    end

endmodule
