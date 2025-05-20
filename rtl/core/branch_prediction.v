// -----------------------------------------------------------------------------
// File Name  : branch_prediction.v
// Module Name: branch_prediction
// Author     : sasathreena
// Version    : 0.9
// Description: 分支预测器模块
//              实现一个简单的二位饱和计数器分支预测器
// -----------------------------------------------------------------------------
// Revision History:
// Date        By              Version         Change Description
// -----------------------------------------------------------------------------
// 2025/05/15  sasathreena     0.9             初始版本
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// 模块: branch_prediction - 分支预测器
// 功能: 预测分支指令的跳转方向，减少分支惩罚
// 说明: 采用二位饱和计数器实现，具有较好的预测准确率
// -----------------------------------------------------------------------------

`include "defines.v"

module branch_prediction #(
    parameter BHT_SIZE = 256     // 分支历史表大小
)(
    input wire clk,              // 时钟信号
    input wire rst,              // 复位信号
    
    // 取指阶段接口
    input wire[`InstAddrBus] pc_i,            // PC值
    output wire prediction_o,                  // 预测结果（跳转/不跳转）
    output wire[`InstAddrBus] predicted_pc_o,  // 预测的目标地址
    
    // 执行阶段更新接口
    input wire branch_i,                       // 是否是分支指令
    input wire jump_i,                         // 实际是否跳转
    input wire[`InstAddrBus] branch_pc_i,      // 分支指令地址
    input wire[`InstAddrBus] target_pc_i       // 实际跳转目标地址
);

    // 分支历史表 - 存储二位饱和计数器
    // 00: 强不跳转
    // 01: 弱不跳转
    // 10: 弱跳转
    // 11: 强跳转
    reg [1:0] bht [0:BHT_SIZE-1];
    
    // 分支目标缓冲表
    reg [`InstAddrBus] btb [0:BHT_SIZE-1];
    
    // 有效位表
    reg valid [0:BHT_SIZE-1];
    
    // 索引计算 - 使用PC的低位作为索引
    wire [$clog2(BHT_SIZE)-1:0] pc_index = pc_i[$clog2(BHT_SIZE)+1:2];
    wire [$clog2(BHT_SIZE)-1:0] branch_index = branch_pc_i[$clog2(BHT_SIZE)+1:2];
    
    // 预测逻辑
    wire is_valid = valid[pc_index];
    wire [1:0] counter = bht[pc_index];
    assign prediction_o = is_valid & counter[1];  // 仅当表项有效且计数器高位为1时预测跳转
    assign predicted_pc_o = btb[pc_index];
    
    // 更新逻辑
    integer i;
    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            // 复位时初始化分支历史表为弱不跳转状态
            for (i = 0; i < BHT_SIZE; i = i + 1) begin
                bht[i] <= 2'b01;   // 默认为弱不跳转
                btb[i] <= `ZeroWord; // 默认目标地址为0
                valid[i] <= 1'b0;  // 默认无效
            end
        end else if (branch_i) begin
            valid[branch_index] <= 1'b1;
            
            if (jump_i) begin
                // 实际跳转，增加计数器
                case (bht[branch_index])
                    2'b00: bht[branch_index] <= 2'b01;
                    2'b01: bht[branch_index] <= 2'b10;
                    2'b10: bht[branch_index] <= 2'b11;
                    2'b11: bht[branch_index] <= 2'b11; // 饱和
                endcase
                // 无论如何更新目标地址
                btb[branch_index] <= target_pc_i;
            end else begin
                // 实际不跳转，减少计数器
                case (bht[branch_index])
                    2'b00: bht[branch_index] <= 2'b00; // 饱和
                    2'b01: bht[branch_index] <= 2'b00;
                    2'b10: bht[branch_index] <= 2'b01;
                    2'b11: bht[branch_index] <= 2'b10;
                endcase
            end
        end
    end

endmodule 