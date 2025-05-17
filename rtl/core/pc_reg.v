// -----------------------------------------------------------------------------
// File Name  : pc_reg.v
// Module Name: pc_reg
// Author     : sasathreena
// Version    : 0.9
// Description: 程序计数器模块
//              管理指令指针和取指地址生成
// -----------------------------------------------------------------------------
// Revision History:
// Date        By              Version         Change Description
// -----------------------------------------------------------------------------
// 2025/04/17  sasathreena     0.9             初始版本
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// 模块: pc_reg - 程序计数器
// 功能: 提供指令地址计数和跳转控制
// 说明: 生成下一条指令地址，支持分支和异常处理的跳转
// -----------------------------------------------------------------------------

`include "defines.v"

// PC寄存器模块
module pc_reg(

    input wire clk,
    input wire rst,

    input wire jump_flag_i,                 // 跳转标志
    input wire[`InstAddrBus] jump_addr_i,   // 跳转地址
    input wire[`Hold_Flag_Bus] hold_flag_i, // 流水线暂停标志
    input wire jtag_reset_flag_i,           // 复位标志

    output reg[`InstAddrBus] pc_o           // PC指针

    );


    always @ (posedge clk) begin
        // 复位
        if (rst == `RstEnable || jtag_reset_flag_i == 1'b1) begin
            pc_o <= `CpuResetAddr;
        // 跳转
        end else if (jump_flag_i == `JumpEnable) begin
            pc_o <= jump_addr_i;
        // 暂停
        end else if (hold_flag_i >= `Hold_Pc) begin
            pc_o <= pc_o;
        // 地址加4
        end else begin
            pc_o <= pc_o + 4'h4;
        end
    end

endmodule
