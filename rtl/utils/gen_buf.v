// -----------------------------------------------------------------------------
// File Name  : gen_buf.v
// Module Name: gen_buf
// Author     : sasathreena
// Version    : 0.9
// Description: 缓冲器和同步器模块
//              提供跨时钟域数据同步功能
// -----------------------------------------------------------------------------
// Revision History:
// Date        By              Version         Change Description
// -----------------------------------------------------------------------------
// 2025/04/22  sasathreena     0.9             初始版本
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// 模块: gen_buf - 缓冲器和同步器
// 功能: 实现数据延迟和时钟域同步
// 说明: 支持可配置级数的同步延迟链
// -----------------------------------------------------------------------------

// 将输入打DP拍后输出
module gen_ticks_sync #(
    parameter DP = 2,
    parameter DW = 32)(

    input wire rst,
    input wire clk,

    input wire[DW-1:0] din,
    output wire[DW-1:0] dout

    );

    wire[DW-1:0] sync_dat[DP-1:0];

    genvar i;

    generate 
        for (i = 0; i < DP; i = i + 1) begin: dp_width
            if (i == 0) begin: dp_is_0
                gen_rst_0_dff #(DW) rst_0_dff(clk, rst, din, sync_dat[0]);
            end else begin: dp_is_not_0
                gen_rst_0_dff #(DW) rst_0_dff(clk, rst, sync_dat[i-1], sync_dat[i]);
            end
        end
    endgenerate

    assign dout = sync_dat[DP-1];
  
endmodule
