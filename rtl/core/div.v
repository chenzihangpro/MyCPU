// -----------------------------------------------------------------------------
// File Name  : div.v
// Module Name: div
// Author     : sasathreena
// Version    : 1.2
// Description: 除法器模块
//              实现有符号和无符号整数除法运算
// -----------------------------------------------------------------------------
// Revision History:
// Date        By              Version         Change Description
// -----------------------------------------------------------------------------
// 2025/04/25  sasathreena     0.9             初始版本
// 2025/05/02  sasathreena     1.0             优化为Radix-4除法器，将时钟周期从33减少到17
// 2025/05/03  sasathreena     1.1             进一步优化为Radix-8除法器，将时钟周期从17减少到11
// 2025/05/08  sasathreena     1.2             添加除以2^n的快速路径，实现一周期除法
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// 模块: div - 除法器
// 功能: 提供整数除法和取模运算功能
// 说明: 支持有符号和无符号运算，采用Radix-8迭代方法实现
//       包含对除以2^n的快速路径优化
// -----------------------------------------------------------------------------

`include "defines.v"

// 除法模块
// Radix-8试商法实现32位整数除法
// 每次除法运算至少需要11个时钟周期才能完成
// 对除以2^n的情况进行了特殊优化，可在1个周期内完成
module div(

    input wire clk,
    input wire rst,

    // from ex
    input wire[`RegBus] dividend_i,      // 被除数
    input wire[`RegBus] divisor_i,       // 除数
    input wire start_i,                  // 开始信号，运算期间这个信号需要一直保持有效
    input wire[2:0] op_i,                // 具体是哪一条指令
    input wire[`RegAddrBus] reg_waddr_i, // 运算结束后需要写的寄存器

    // to ex
    output reg[`RegBus] result_o,        // 除法结果，高32位是余数，低32位是商
    output reg ready_o,                  // 运算结束信号
    output reg busy_o,                   // 正在运算信号
    output reg[`RegAddrBus] reg_waddr_o  // 运算结束后需要写的寄存器

    );

    // 状态定义
    localparam STATE_IDLE  = 4'b0001;
    localparam STATE_START = 4'b0010;
    localparam STATE_CALC  = 4'b0100;
    localparam STATE_END   = 4'b1000;

    reg[`RegBus] dividend_r;
    reg[`RegBus] divisor_r;
    reg[2:0] op_r;
    reg[3:0] state;
    reg[31:0] count;
    reg[`RegBus] div_result;
    reg[`RegBus] div_remain;
    reg[`RegBus] minuend;
    reg invert_result;

    wire op_div = (op_r == `INST_DIV);
    wire op_divu = (op_r == `INST_DIVU);
    wire op_rem = (op_r == `INST_REM);
    wire op_remu = (op_r == `INST_REMU);

    wire[31:0] dividend_invert = (-dividend_r);
    wire[31:0] divisor_invert = (-divisor_r);
    
    // 2^n快速路径检测 - 检查除数是否为2的幂次方
    wire is_power_of_two = (divisor_r & (divisor_r - 1)) == 32'h0 && divisor_r != 32'h0;
    
    // 获取最高位1的位置 (Leading Zero Count取反)
    wire[4:0] shift_count;
    
    // 计算最高位1的位置 - 简化的前导零计数实现
    function [4:0] get_highest_bit;
        input [31:0] value;
        begin
            if (value[31]) get_highest_bit = 5'd31;
            else if (value[30]) get_highest_bit = 5'd30;
            else if (value[29]) get_highest_bit = 5'd29;
            else if (value[28]) get_highest_bit = 5'd28;
            else if (value[27]) get_highest_bit = 5'd27;
            else if (value[26]) get_highest_bit = 5'd26;
            else if (value[25]) get_highest_bit = 5'd25;
            else if (value[24]) get_highest_bit = 5'd24;
            else if (value[23]) get_highest_bit = 5'd23;
            else if (value[22]) get_highest_bit = 5'd22;
            else if (value[21]) get_highest_bit = 5'd21;
            else if (value[20]) get_highest_bit = 5'd20;
            else if (value[19]) get_highest_bit = 5'd19;
            else if (value[18]) get_highest_bit = 5'd18;
            else if (value[17]) get_highest_bit = 5'd17;
            else if (value[16]) get_highest_bit = 5'd16;
            else if (value[15]) get_highest_bit = 5'd15;
            else if (value[14]) get_highest_bit = 5'd14;
            else if (value[13]) get_highest_bit = 5'd13;
            else if (value[12]) get_highest_bit = 5'd12;
            else if (value[11]) get_highest_bit = 5'd11;
            else if (value[10]) get_highest_bit = 5'd10;
            else if (value[9]) get_highest_bit = 5'd9;
            else if (value[8]) get_highest_bit = 5'd8;
            else if (value[7]) get_highest_bit = 5'd7;
            else if (value[6]) get_highest_bit = 5'd6;
            else if (value[5]) get_highest_bit = 5'd5;
            else if (value[4]) get_highest_bit = 5'd4;
            else if (value[3]) get_highest_bit = 5'd3;
            else if (value[2]) get_highest_bit = 5'd2;
            else if (value[1]) get_highest_bit = 5'd1;
            else get_highest_bit = 5'd0;
        end
    endfunction
    
    // 对除数计算移位数
    assign shift_count = get_highest_bit(divisor_r);
    
    // 计算快速路径结果 - 商和余数
    wire[31:0] fast_quotient = dividend_r >> shift_count;
    wire[31:0] fast_remainder = dividend_r & ((1 << shift_count) - 1);
    
    // Radix-8比较逻辑
    wire[31:0] divisor_2x = {divisor_r[30:0], 1'b0};  // 2倍除数
    wire[31:0] divisor_3x = divisor_r + divisor_2x;   // 3倍除数
    wire[31:0] divisor_4x = {divisor_r[29:0], 2'b0};  // 4倍除数
    wire[31:0] divisor_5x = divisor_r + divisor_4x;   // 5倍除数 
    wire[31:0] divisor_6x = divisor_2x + divisor_4x;  // 6倍除数
    wire[31:0] divisor_7x = divisor_r + divisor_6x;   // 7倍除数
    
    // 比较结果
    wire minuend_ge_divisor = minuend >= divisor_r;
    wire minuend_ge_2x_divisor = minuend >= divisor_2x;
    wire minuend_ge_3x_divisor = minuend >= divisor_3x;
    wire minuend_ge_4x_divisor = minuend >= divisor_4x;
    wire minuend_ge_5x_divisor = minuend >= divisor_5x;
    wire minuend_ge_6x_divisor = minuend >= divisor_6x;
    wire minuend_ge_7x_divisor = minuend >= divisor_7x;
    
    // 减法结果
    wire[31:0] minuend_sub_1x = minuend - divisor_r;
    wire[31:0] minuend_sub_2x = minuend - divisor_2x;
    wire[31:0] minuend_sub_3x = minuend - divisor_3x;
    wire[31:0] minuend_sub_4x = minuend - divisor_4x;
    wire[31:0] minuend_sub_5x = minuend - divisor_5x;
    wire[31:0] minuend_sub_6x = minuend - divisor_6x;
    wire[31:0] minuend_sub_7x = minuend - divisor_7x;
    
    // 根据比较结果选择下一个减数值
    reg[31:0] next_minuend;
    reg[2:0] next_quotient_bits;
    
    // 根据比较结果计算下一个减数和余数位
    always @(*) begin
        if (minuend_ge_7x_divisor) begin
            next_minuend = minuend_sub_7x;
            next_quotient_bits = 3'b111; // 7
        end else if (minuend_ge_6x_divisor) begin
            next_minuend = minuend_sub_6x;
            next_quotient_bits = 3'b110; // 6
        end else if (minuend_ge_5x_divisor) begin
            next_minuend = minuend_sub_5x;
            next_quotient_bits = 3'b101; // 5
        end else if (minuend_ge_4x_divisor) begin
            next_minuend = minuend_sub_4x;
            next_quotient_bits = 3'b100; // 4
        end else if (minuend_ge_3x_divisor) begin
            next_minuend = minuend_sub_3x;
            next_quotient_bits = 3'b011; // 3
        end else if (minuend_ge_2x_divisor) begin
            next_minuend = minuend_sub_2x;
            next_quotient_bits = 3'b010; // 2
        end else if (minuend_ge_divisor) begin
            next_minuend = minuend_sub_1x;
            next_quotient_bits = 3'b001; // 1
        end else begin
            next_minuend = minuend;
            next_quotient_bits = 3'b000; // 0
        end
    end

    // 状态机实现
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            state <= STATE_IDLE;
            ready_o <= `DivResultNotReady;
            result_o <= `ZeroWord;
            div_result <= `ZeroWord;
            div_remain <= `ZeroWord;
            op_r <= 3'h0;
            reg_waddr_o <= `ZeroWord;
            dividend_r <= `ZeroWord;
            divisor_r <= `ZeroWord;
            minuend <= `ZeroWord;
            invert_result <= 1'b0;
            busy_o <= `False;
            count <= `ZeroWord;
        end else begin
            case (state)
                STATE_IDLE: begin
                    if (start_i == `DivStart) begin
                        op_r <= op_i;
                        dividend_r <= dividend_i;
                        divisor_r <= divisor_i;
                        reg_waddr_o <= reg_waddr_i;
                        state <= STATE_START;
                        busy_o <= `True;
                    end else begin
                        op_r <= 3'h0;
                        reg_waddr_o <= `ZeroWord;
                        dividend_r <= `ZeroWord;
                        divisor_r <= `ZeroWord;
                        ready_o <= `DivResultNotReady;
                        result_o <= `ZeroWord;
                        busy_o <= `False;
                    end
                end

                STATE_START: begin
                    if (start_i == `DivStart) begin
                        // 除数为0
                        if (divisor_r == `ZeroWord) begin
                            if (op_div | op_divu) begin
                                result_o <= 32'hffffffff;
                            end else begin
                                result_o <= dividend_r;
                            end
                            ready_o <= `DivResultReady;
                            state <= STATE_IDLE;
                            busy_o <= `False;
                        // 除数是2的幂次方 - 快速路径
                        end else if (is_power_of_two) begin
                            // 处理符号位
                            if ((op_div | op_rem) && divisor_r[31]) begin
                                // 如果是有符号除法并且除数为负
                                if (op_div && dividend_r[31]) begin
                                    // 除数和被除数都为负，结果为正
                                    result_o <= fast_quotient;
                                end else if (op_div) begin
                                    // 除数为负，被除数为正，结果为负
                                    result_o <= -fast_quotient;
                                end else if (op_rem && dividend_r[31]) begin
                                    // 取余，被除数为负，余数为负
                                    result_o <= -fast_remainder;
                                end else begin
                                    // 取余，被除数为正，余数为正
                                    result_o <= fast_remainder;
                                end
                            end else if ((op_div | op_rem) && dividend_r[31]) begin
                                // 有符号除法，被除数为负，除数为正
                                if (op_div) begin
                                    result_o <= -fast_quotient;
                                end else begin
                                    result_o <= -fast_remainder;
                                end
                            end else begin
                                // 简单情况：无符号除法或有符号数但都是正数
                                if (op_div | op_divu) begin
                                    result_o <= fast_quotient;
                                end else begin
                                    result_o <= fast_remainder;
                                end
                            end
                            ready_o <= `DivResultReady;
                            state <= STATE_IDLE;
                            busy_o <= `False;
                        // 被除数小于除数 - 除法提前结束优化
                        end else if (dividend_r < divisor_r) begin
                            if (op_div | op_divu) begin
                                result_o <= 32'h0; // 商为0
                            end else begin
                                result_o <= dividend_r; // 余数等于被除数
                            end
                            ready_o <= `DivResultReady;
                            state <= STATE_IDLE;
                            busy_o <= `False;
                        // 除数不为0且被除数大于等于除数，且不是2的幂
                        end else begin
                            busy_o <= `True;
                            count <= 32'h20000000;
                            state <= STATE_CALC;
                            div_result <= `ZeroWord;
                            div_remain <= `ZeroWord;

                            // DIV和REM这两条指令是有符号数运算指令
                            if (op_div | op_rem) begin
                                // 被除数求补码
                                if (dividend_r[31] == 1'b1) begin
                                    dividend_r <= dividend_invert;
                                    minuend <= dividend_invert[31:29];
                                end else begin
                                    // 初始化首3位
                                    minuend <= dividend_r[31:29];
                                end
                                // 除数求补码
                                if (divisor_r[31] == 1'b1) begin
                                    divisor_r <= divisor_invert;
                                end
                            end else begin
                                // 无符号数初始化首3位
                                minuend <= dividend_r[31:29];
                            end

                            // 运算结束后是否要对结果取补码
                            if ((op_div && (dividend_r[31] ^ divisor_r[31] == 1'b1))
                                || (op_rem && (dividend_r[31] == 1'b1))) begin
                                invert_result <= 1'b1;
                            end else begin
                                invert_result <= 1'b0;
                            end
                        end
                    end else begin
                        state <= STATE_IDLE;
                        result_o <= `ZeroWord;
                        ready_o <= `DivResultNotReady;
                        busy_o <= `False;
                    end
                end

                STATE_CALC: begin
                    if (start_i == `DivStart) begin
                        // 将被除数左移3位 (Radix-8)
                        dividend_r <= {dividend_r[28:0], 3'b000};
                        
                        // 根据比较结果更新商寄存器
                        div_result <= {div_result[28:0], next_quotient_bits};
                        
                        // 更新计数器 - 每次循环减少为原来的1/8
                        count <= {3'b000, count[31:3]};
                        
                        if (|count) begin
                            // 更新下一轮的除数和部分余数
                            minuend <= {next_minuend[28:0], dividend_r[28:26]};
                        end else begin
                            state <= STATE_END;
                            // 最终余数
                            div_remain <= next_minuend;
                        end
                    end else begin
                        state <= STATE_IDLE;
                        result_o <= `ZeroWord;
                        ready_o <= `DivResultNotReady;
                        busy_o <= `False;
                    end
                end

                STATE_END: begin
                    if (start_i == `DivStart) begin
                        ready_o <= `DivResultReady;
                        state <= STATE_IDLE;
                        busy_o <= `False;
                        if (op_div | op_divu) begin
                            if (invert_result) begin
                                result_o <= (-div_result);
                            end else begin
                                result_o <= div_result;
                            end
                        end else begin
                            if (invert_result) begin
                                result_o <= (-div_remain);
                            end else begin
                                result_o <= div_remain;
                            end
                        end
                    end else begin
                        state <= STATE_IDLE;
                        result_o <= `ZeroWord;
                        ready_o <= `DivResultNotReady;
                        busy_o <= `False;
                    end
                end

            endcase
        end
    end

endmodule
