// -----------------------------------------------------------------------------
// File Name  : mem.v
// Module Name: mem
// Author     : sasathreena
// Version    : 0.9
// Description: 内存访问单元模块
//              处理加载和存储指令的内存操作
// -----------------------------------------------------------------------------
// Revision History:
// Date        By              Version         Change Description
// -----------------------------------------------------------------------------
// 2025/05/03  sasathreena     0.9             初始版本
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// 模块: mem - 内存访问单元
// 功能: 执行内存读写操作，处理不同数据宽度的访问
// 说明: 支持字节、半字和字的加载存储操作，实现数据对齐和扩展
// -----------------------------------------------------------------------------

`include "defines.v"

// 访存模块
// 纯组合逻辑电路
module mem(

    input wire rst,

    // 从执行阶段传递过来的信息
    input wire[`InstBus] inst_i,            // 指令内容
    input wire[`InstAddrBus] inst_addr_i,   // 指令地址
    input wire reg_we_i,                    // 写通用寄存器标志
    input wire[`RegAddrBus] reg_waddr_i,    // 写通用寄存器地址
    input wire[`RegBus] reg_wdata_i,        // 写寄存器数据
    input wire csr_we_i,                    // 写CSR寄存器标志
    input wire[`MemAddrBus] csr_waddr_i,    // 写CSR寄存器地址
    input wire[`RegBus] csr_wdata_i,        // 写CSR寄存器数据
    input wire[`MemBus] mem_wdata_i,        // 写内存数据
    input wire[`MemAddrBus] mem_raddr_i,    // 读内存地址
    input wire[`MemAddrBus] mem_waddr_i,    // 写内存地址
    input wire mem_we_i,                    // 是否要写内存
    input wire mem_req_i,                   // 请求访问内存标志
    input wire[3:0] mem_sel_i,              // 字节选择信号
    input wire jump_flag_i,                 // 跳转标志
    input wire[`InstAddrBus] jump_addr_i,   // 跳转目的地址
    
    // 从内存获取的数据
    input wire[`MemBus] mem_data_i,         // 从内存读取的数据

    // 传递到写回阶段的信息
    output wire[`InstBus] inst_o,           // 指令内容
    output wire[`InstAddrBus] inst_addr_o,  // 指令地址
    output wire reg_we_o,                   // 写通用寄存器标志
    output wire[`RegAddrBus] reg_waddr_o,   // 写通用寄存器地址
    output wire[`RegBus] reg_wdata_o,       // 写寄存器数据
    output wire csr_we_o,                   // 写CSR寄存器标志
    output wire[`MemAddrBus] csr_waddr_o,   // 写CSR寄存器地址
    output wire[`RegBus] csr_wdata_o,       // 写CSR寄存器数据
    
    // 访存相关输出信号
    output wire[`MemBus] mem_wdata_o,       // 写内存数据
    output wire[`MemAddrBus] mem_raddr_o,   // 读内存地址
    output wire[`MemAddrBus] mem_waddr_o,   // 写内存地址
    output wire mem_we_o,                   // 是否要写内存
    output wire mem_req_o,                  // 请求访问内存标志
    output wire[3:0] mem_sel_o,             // 字节选择信号
    
    // 跳转相关输出信号
    output wire jump_flag_o,                // 跳转标志
    output wire[`InstAddrBus] jump_addr_o   // 跳转目的地址

    );

    wire[6:0] opcode = inst_i[6:0];
    wire[2:0] funct3 = inst_i[14:12];
    
    assign inst_o = inst_i;
    assign inst_addr_o = inst_addr_i;
    assign csr_we_o = csr_we_i;
    assign csr_waddr_o = csr_waddr_i;
    assign csr_wdata_o = csr_wdata_i;
    assign jump_flag_o = jump_flag_i;
    assign jump_addr_o = jump_addr_i;
    
    reg reg_we;
    reg[`RegAddrBus] reg_waddr;
    reg[`RegBus] reg_wdata;
    
    // 传递写内存数据和地址信号
    assign mem_wdata_o = mem_wdata_i;
    assign mem_raddr_o = mem_raddr_i;
    assign mem_waddr_o = mem_waddr_i;
    assign mem_we_o = mem_we_i;
    assign mem_req_o = mem_req_i;
    assign mem_sel_o = mem_sel_i;
    
    
    // 访存阶段主要处理加载指令的数据读取和扩展
    always @ (*) begin
        reg_we = reg_we_i;
        reg_waddr = reg_waddr_i;
        reg_wdata = reg_wdata_i;
        
        // 若是加载指令，则需要根据读取的内存数据进行处理
        if ((opcode == `INST_TYPE_L) && (mem_req_i == `RIB_REQ)) begin
            case (funct3)
                `INST_LB: begin
                    case (mem_raddr_i[1:0])
                        2'b00: reg_wdata = {{24{mem_data_i[7]}}, mem_data_i[7:0]};
                        2'b01: reg_wdata = {{24{mem_data_i[15]}}, mem_data_i[15:8]};
                        2'b10: reg_wdata = {{24{mem_data_i[23]}}, mem_data_i[23:16]};
                        2'b11: reg_wdata = {{24{mem_data_i[31]}}, mem_data_i[31:24]};
                        default: reg_wdata = `ZeroWord;
                    endcase
                end
                `INST_LH: begin
                    case (mem_raddr_i[1:0])
                        2'b00: reg_wdata = {{16{mem_data_i[15]}}, mem_data_i[15:0]};
                        2'b10: reg_wdata = {{16{mem_data_i[31]}}, mem_data_i[31:16]};
                        default: reg_wdata = `ZeroWord;
                    endcase
                end
                `INST_LW: begin
                    reg_wdata = mem_data_i;
                end
                `INST_LBU: begin
                    case (mem_raddr_i[1:0])
                        2'b00: reg_wdata = {24'b0, mem_data_i[7:0]};
                        2'b01: reg_wdata = {24'b0, mem_data_i[15:8]};
                        2'b10: reg_wdata = {24'b0, mem_data_i[23:16]};
                        2'b11: reg_wdata = {24'b0, mem_data_i[31:24]};
                        default: reg_wdata = `ZeroWord;
                    endcase
                end
                `INST_LHU: begin
                    case (mem_raddr_i[1:0])
                        2'b00: reg_wdata = {16'b0, mem_data_i[15:0]};
                        2'b10: reg_wdata = {16'b0, mem_data_i[31:16]};
                        default: reg_wdata = `ZeroWord;
                    endcase
                end
                default: begin
                    reg_wdata = reg_wdata_i;
                end
            endcase
        end else if (opcode == `INST_FENCE) begin
            // FENCE指令处理，确保所有内存操作完成
            reg_we = `WriteDisable;
            reg_waddr = `ZeroReg;
            reg_wdata = `ZeroWord;
        end
    end

    assign reg_we_o = reg_we;
    assign reg_waddr_o = reg_waddr;
    assign reg_wdata_o = reg_wdata;

endmodule 