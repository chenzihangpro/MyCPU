// -----------------------------------------------------------------------------
// File Name  : ctrl.v
// Module Name: ctrl
// Author     : sasathreena
// Version    : 0.9
// Description: 控制单元模块
//              管理处理器流水线和异常处理
// -----------------------------------------------------------------------------
// Revision History:
// Date        By              Version         Change Description
// -----------------------------------------------------------------------------
// 2025/04/21  sasathreena     0.9             初始版本
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// 模块: ctrl - 控制单元
// 功能: 协调流水线各级的操作，处理冲突和异常
// 说明: 实现了流水线控制逻辑，负责冲突检测和流水线刷新
// -----------------------------------------------------------------------------

`include "defines.v"

// 控制模块
// 发出跳转、暂停流水线信号
module ctrl(

    input wire rst,

    // from ex
    input wire jump_flag_i,
    input wire[`InstAddrBus] jump_addr_i,
    input wire hold_flag_ex_i,

    // from rib
    input wire hold_flag_rib_i,

    // from jtag
    input wire jtag_halt_flag_i,

    // from clint
    input wire hold_flag_clint_i,
    
    // from id
    input wire load_use_relevant_i,         // load-use相关暂停请求

    output reg[`Hold_Flag_Bus] hold_flag_o,

    // to pc_reg
    output reg jump_flag_o,
    output reg[`InstAddrBus] jump_addr_o

    );


    always @ (*) begin
        jump_addr_o = jump_addr_i;
        jump_flag_o = jump_flag_i;
        // 默认不暂停
        hold_flag_o = `Hold_None;
        // 按优先级处理不同模块的请求
        if (jump_flag_i == `JumpEnable || hold_flag_ex_i == `HoldEnable || hold_flag_clint_i == `HoldEnable) begin
            // 暂停整条流水线
            hold_flag_o = `Hold_Wb;
        end else if (hold_flag_rib_i == `HoldEnable) begin
            // 暂停PC，即取指地址不变
            hold_flag_o = `Hold_Pc;
        end else if (jtag_halt_flag_i == `HoldEnable) begin
            // 暂停整条流水线
            hold_flag_o = `Hold_Wb;
        end else if (load_use_relevant_i == `HoldEnable) begin
            // load-use相关暂停流水线
            hold_flag_o = `Hold_Id;
        end else begin
            hold_flag_o = `Hold_None;
        end
    end

endmodule
