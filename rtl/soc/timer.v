// -----------------------------------------------------------------------------
// File Name  : timer.v
// Module Name: timer
// Author     : sasathreena
// Version    : 0.9
// Description: 定时器控制器模块，支持三个独立定时器
//              提供可配置计数器和中断功能
// -----------------------------------------------------------------------------
// Revision History:
// Date        By              Version         Change Description
// -----------------------------------------------------------------------------
// 2025/04/12  sasathreena     0.9             初始版本
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// 模块: timer - 定时器控制器
// 功能: 实现32位向上计数定时器，提供计数值比较和中断功能
// 说明: 支持多个定时器通道，可独立配置和控制
// -----------------------------------------------------------------------------

`include "../core/defines.v"


// 32 bits count up timer module
module timer(

    input wire clk,
    input wire rst,

    input wire we_i,
    input wire[`MemAddrBus] addr_i,
    input wire[`MemBus] data_i,
    input wire[3:0] sel_i,        // 添加字节选择信号

    output reg[`MemBus] data_o,
    output wire timer0_int_o,
    output wire timer1_int_o,
    output wire timer2_int_o

    );

    // 定义本地常量
    localparam REG_CTRL = 4'h0;
    localparam REG_COUNT = 4'h4;
    localparam REG_VALUE = 4'h8;
    
    // 定义本地地址常量，避免使用宏
    localparam ADDR_TIMER0_CTRL = 32'h20000;
    localparam ADDR_TIMER0_COUNT = 32'h20004;
    localparam ADDR_TIMER0_CMP = 32'h20008;
    localparam ADDR_TIMER1_CTRL = 32'h2000C;
    localparam ADDR_TIMER1_COUNT = 32'h20010;
    localparam ADDR_TIMER1_CMP = 32'h20014;
    localparam ADDR_TIMER2_CTRL = 32'h20018;
    localparam ADDR_TIMER2_COUNT = 32'h2001C;
    localparam ADDR_TIMER2_CMP = 32'h20020;

    // [0]: timer enable
    // [1]: timer int enable
    // [2]: timer int pending, write 1 to clear it
    // addr offset: 0x00
    reg[31:0] timer_ctrl;

    // timer current count, read only
    // addr offset: 0x04
    reg[31:0] timer_count;

    // timer expired value
    // addr offset: 0x08
    reg[31:0] timer_value;


    assign timer0_int_o = ((timer_ctrl[2] == 1'b1) && (timer_ctrl[1] == 1'b1))? `INT_ASSERT: `INT_DEASSERT;
    assign timer1_int_o = ((timer_ctrl[2] == 1'b1) && (timer_ctrl[1] == 1'b1))? `INT_ASSERT: `INT_DEASSERT;
    assign timer2_int_o = ((timer_ctrl[2] == 1'b1) && (timer_ctrl[1] == 1'b1))? `INT_ASSERT: `INT_DEASSERT;

    // counter
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            timer_count <= `ZeroWord;
        end else begin
            if (timer_ctrl[0] == 1'b1) begin
                timer_count <= timer_count + 1'b1;
                if (timer_count >= timer_value) begin
                    timer_count <= `ZeroWord;
                end
            end else begin
                timer_count <= `ZeroWord;
            end
        end
    end

    // write regs
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            timer_ctrl <= `ZeroWord;
            timer_value <= `ZeroWord;
        end else begin
            if (we_i == `WriteEnable) begin
                case (addr_i)
                    ADDR_TIMER0_CTRL: begin
                        if (sel_i[0]) timer_ctrl[7:0] <= data_i[7:0];
                        if (sel_i[1]) timer_ctrl[15:8] <= data_i[15:8];
                        if (sel_i[2]) timer_ctrl[23:16] <= data_i[23:16];
                        if (sel_i[3]) timer_ctrl[31:24] <= data_i[31:24];
                        timer_ctrl[0] <= data_i[0];
                    end
                    ADDR_TIMER0_COUNT: begin
                        if (sel_i[0]) timer_count[7:0] <= data_i[7:0];
                        if (sel_i[1]) timer_count[15:8] <= data_i[15:8];
                        if (sel_i[2]) timer_count[23:16] <= data_i[23:16];
                        if (sel_i[3]) timer_count[31:24] <= data_i[31:24];
                    end
                    ADDR_TIMER0_CMP: begin
                        if (sel_i[0]) timer_value[7:0] <= data_i[7:0];
                        if (sel_i[1]) timer_value[15:8] <= data_i[15:8];
                        if (sel_i[2]) timer_value[23:16] <= data_i[23:16];
                        if (sel_i[3]) timer_value[31:24] <= data_i[31:24];
                    end
                    ADDR_TIMER1_CTRL: begin
                        if (sel_i[0]) timer_ctrl[7:0] <= data_i[7:0];
                        if (sel_i[1]) timer_ctrl[15:8] <= data_i[15:8];
                        if (sel_i[2]) timer_ctrl[23:16] <= data_i[23:16];
                        if (sel_i[3]) timer_ctrl[31:24] <= data_i[31:24];
                        timer_ctrl[0] <= data_i[0];
                    end
                    ADDR_TIMER1_COUNT: begin
                        if (sel_i[0]) timer_count[7:0] <= data_i[7:0];
                        if (sel_i[1]) timer_count[15:8] <= data_i[15:8];
                        if (sel_i[2]) timer_count[23:16] <= data_i[23:16];
                        if (sel_i[3]) timer_count[31:24] <= data_i[31:24];
                    end
                    ADDR_TIMER1_CMP: begin
                        if (sel_i[0]) timer_value[7:0] <= data_i[7:0];
                        if (sel_i[1]) timer_value[15:8] <= data_i[15:8];
                        if (sel_i[2]) timer_value[23:16] <= data_i[23:16];
                        if (sel_i[3]) timer_value[31:24] <= data_i[31:24];
                    end
                    ADDR_TIMER2_CTRL: begin
                        if (sel_i[0]) timer_ctrl[7:0] <= data_i[7:0];
                        if (sel_i[1]) timer_ctrl[15:8] <= data_i[15:8];
                        if (sel_i[2]) timer_ctrl[23:16] <= data_i[23:16];
                        if (sel_i[3]) timer_ctrl[31:24] <= data_i[31:24];
                        timer_ctrl[0] <= data_i[0];
                    end
                    ADDR_TIMER2_COUNT: begin
                        if (sel_i[0]) timer_count[7:0] <= data_i[7:0];
                        if (sel_i[1]) timer_count[15:8] <= data_i[15:8];
                        if (sel_i[2]) timer_count[23:16] <= data_i[23:16];
                        if (sel_i[3]) timer_count[31:24] <= data_i[31:24];
                    end
                    ADDR_TIMER2_CMP: begin
                        if (sel_i[0]) timer_value[7:0] <= data_i[7:0];
                        if (sel_i[1]) timer_value[15:8] <= data_i[15:8];
                        if (sel_i[2]) timer_value[23:16] <= data_i[23:16];
                        if (sel_i[3]) timer_value[31:24] <= data_i[31:24];
                    end
                    default: begin
                        // 不做任何操作
                    end
                endcase
            end else begin
                if ((timer_ctrl[0] == 1'b1) && (timer_count >= timer_value)) begin
                    timer_ctrl[0] <= 1'b0;
                    timer_ctrl[2] <= 1'b1;
                end
            end
        end
    end

    // read regs
    always @ (*) begin
        if (rst == `RstEnable) begin
            data_o = `ZeroWord;
        end else begin
            case (addr_i[3:0])
                REG_VALUE: begin
                    data_o = timer_value;
                end
                REG_CTRL: begin
                    data_o = timer_ctrl;
                end
                REG_COUNT: begin
                    data_o = timer_count;
                end
                default: begin
                    data_o = `ZeroWord;
                end
            endcase
        end
    end

endmodule
