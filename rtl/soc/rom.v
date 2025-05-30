// -----------------------------------------------------------------------------
// File Name  : rom.v
// Module Name: rom
// Author     : sasathreena
// Version    : 0.9
// Description: 只读存储器模块
//              提供固定程序和数据存储功能
// -----------------------------------------------------------------------------
// Revision History:
// Date        By              Version         Change Description
// -----------------------------------------------------------------------------
// 2025/04/30  sasathreena     0.9             初始版本
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// 模块: rom - 只读存储器
// 功能: 提供指令和常量数据的存储，支持字节寻址
// 说明: 实现了同步读取，用于存储启动代码和基本程序
// -----------------------------------------------------------------------------

`include "../core/defines.v"


module rom(

    input wire clk,
    input wire rst,

    input wire we_i,                   // write enable
    input wire[`MemAddrBus] addr_i,    // addr
    input wire[`MemBus] data_i,
    input wire[3:0] sel_i,             // 字节选择信号

    output reg[`MemBus] data_o         // read data

    );

    reg[`MemBus] _rom[0:`RomNum - 1];


    always @ (posedge clk) begin
        if (we_i == `WriteEnable) begin
            if (sel_i[0]) _rom[addr_i[31:2]][7:0] <= data_i[7:0];
            if (sel_i[1]) _rom[addr_i[31:2]][15:8] <= data_i[15:8];
            if (sel_i[2]) _rom[addr_i[31:2]][23:16] <= data_i[23:16];
            if (sel_i[3]) _rom[addr_i[31:2]][31:24] <= data_i[31:24];
        end
    end

    always @ (*) begin
        if (rst == `RstEnable) begin
            data_o = `ZeroWord;
        end else begin
            // 读取整个字，让MEM阶段根据字节选择信号进行处理
            data_o = _rom[addr_i[31:2]];
        end
    end

endmodule
