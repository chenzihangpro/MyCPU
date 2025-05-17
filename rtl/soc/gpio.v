// -----------------------------------------------------------------------------
// File Name  : gpio.v
// Module Name: gpio
// Author     : sasathreena
// Version    : 0.9
// Description: 通用输入输出接口控制模块
//              支持输入输出方向配置和数据控制
// -----------------------------------------------------------------------------
// Revision History:
// Date        By              Version         Change Description
// -----------------------------------------------------------------------------
// 2025/04/26  sasathreena     0.9             初始版本
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// 模块: gpio - 通用输入输出接口
// 功能: 实现可配置的IO口，支持输入输出和中断功能
// 说明: 每个引脚可独立配置方向和操作状态
// -----------------------------------------------------------------------------

// GPIO模块
module gpio(

    input wire clk,
	input wire rst,

    input wire we_i,
    input wire[31:0] addr_i,
    input wire[31:0] data_i,
    input wire[3:0] sel_i,         // 添加字节选择信号

    output reg[31:0] data_o,

    input wire[1:0] io_pin_i,
    output wire[31:0] reg_ctrl,
    output wire[31:0] reg_data

    );


    // GPIO控制寄存器
    localparam GPIO_CTRL = 4'h0;
    // GPIO数据寄存器
    localparam GPIO_DATA = 4'h4;

    // 每2位控制1个IO的模式，最多支持16个IO
    // 0: 高阻，1：输出，2：输入
    reg[31:0] gpio_ctrl;
    // 输入输出数据
    reg[31:0] gpio_data;


    assign reg_ctrl = gpio_ctrl;
    assign reg_data = gpio_data;


    // 写寄存器
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            gpio_ctrl <= 32'h0;
            gpio_data <= 32'h0;
        end else begin
            if (we_i == `WriteEnable) begin
                case (addr_i[3:0])
                    4'h0: begin
                        if (sel_i[0]) gpio_ctrl[7:0] <= data_i[7:0];
                        if (sel_i[1]) gpio_ctrl[15:8] <= data_i[15:8];
                        if (sel_i[2]) gpio_ctrl[23:16] <= data_i[23:16];
                        if (sel_i[3]) gpio_ctrl[31:24] <= data_i[31:24];
                    end
                    4'h4: begin
                        if (sel_i[0]) gpio_data[7:0] <= data_i[7:0];
                        if (sel_i[1]) gpio_data[15:8] <= data_i[15:8];
                        if (sel_i[2]) gpio_data[23:16] <= data_i[23:16];
                        if (sel_i[3]) gpio_data[31:24] <= data_i[31:24];
                    end
                endcase
            end else begin
                if (gpio_ctrl[1:0] == 2'b10) begin
                    gpio_data[0] <= io_pin_i[0];
                end
                if (gpio_ctrl[3:2] == 2'b10) begin
                    gpio_data[1] <= io_pin_i[1];
                end
            end
        end
    end

    // 读寄存器
    always @ (*) begin
        if (rst == 1'b0) begin
            data_o = 32'h0;
        end else begin
            case (addr_i[3:0])
                GPIO_CTRL: begin
                    data_o = gpio_ctrl;
                end
                GPIO_DATA: begin
                    data_o = gpio_data;
                end
                default: begin
                    data_o = 32'h0;
                end
            endcase
        end
    end

endmodule
