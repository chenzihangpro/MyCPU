// -----------------------------------------------------------------------------
// File Name  : ram.v
// Module Name: ram
// Author     : sasathreena
// Version    : 0.9
// Description: 随机存取存储器模块
//              提供可读写的数据和程序存储空间
// -----------------------------------------------------------------------------
// Revision History:
// Date        By              Version         Change Description
// -----------------------------------------------------------------------------
// 2025/05/02  sasathreena     0.9             初始版本
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// 模块: ram - 随机存取存储器
// 功能: 提供读写存储功能，支持字节选择操作
// 说明: 实现了同步读写，支持不同数据宽度的访问
// -----------------------------------------------------------------------------

`include "../core/defines.v"

// ram module
module ram(

    input wire clk,
    input wire rst,

    input wire we_i,                   // write enable
    input wire[`MemAddrBus] addr_i,    // addr
    input wire[`MemBus] data_i,
    input wire[3:0] sel_i,             // 字节选择信号

    output reg[`MemBus] data_o         // read data

    );

    reg[`MemBus] _ram[0:`MemNum - 1];

    // 支持字节写入
    always @ (posedge clk) begin
        if (we_i == `WriteEnable) begin
            if (sel_i[0]) _ram[addr_i[31:2]][7:0] <= data_i[7:0];
            if (sel_i[1]) _ram[addr_i[31:2]][15:8] <= data_i[15:8];
            if (sel_i[2]) _ram[addr_i[31:2]][23:16] <= data_i[23:16];
            if (sel_i[3]) _ram[addr_i[31:2]][31:24] <= data_i[31:24];
        end
    end

    always @ (*) begin
        if (rst == `RstEnable) begin
            data_o = `ZeroWord;
        end else begin
            // 读取整个字，让MEM阶段根据字节选择信号进行处理
            data_o = _ram[addr_i[31:2]];
        end
    end

endmodule
