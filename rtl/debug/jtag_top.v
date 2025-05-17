// -----------------------------------------------------------------------------
// File Name  : jtag_top.v
// Module Name: jtag_top
// Author     : sasathreena
// Version    : 0.9
// Description: JTAG调试接口顶层模块
//              实现处理器调试和外部通信功能
// -----------------------------------------------------------------------------
// Revision History:
// Date        By              Version         Change Description
// -----------------------------------------------------------------------------
// 2025/04/14  sasathreena     0.9             初始版本
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// 模块: jtag_top - JTAG调试顶层模块
// 功能: 集成JTAG协议控制器和调试模块
// 说明: 实现IEEE 1149.1标准接口，支持处理器状态控制和数据访问
// -----------------------------------------------------------------------------

`include "../core/defines.v"

// JTAG顶层模块
module jtag_top #(
    parameter DMI_ADDR_BITS = 6,
    parameter DMI_DATA_BITS = 32,
    parameter DMI_OP_BITS = 2)(

    input wire clk,
    input wire jtag_rst_n,

    input wire jtag_pin_TCK,
    input wire jtag_pin_TMS,
    input wire jtag_pin_TDI,
    output wire jtag_pin_TDO,

    output wire reg_we_o,
    output wire[4:0] reg_addr_o,
    output wire[31:0] reg_wdata_o,
    input wire[31:0] reg_rdata_i,
    output wire mem_we_o,
    output wire[31:0] mem_addr_o,
    output wire[31:0] mem_wdata_o,
    input wire[31:0] mem_rdata_i,
    output wire op_req_o,

    output wire halt_req_o,
    output wire reset_req_o

    );

    parameter DM_RESP_BITS = DMI_ADDR_BITS + DMI_DATA_BITS + DMI_OP_BITS;
    parameter DTM_REQ_BITS = DMI_ADDR_BITS + DMI_DATA_BITS + DMI_OP_BITS;

    // jtag_driver
    wire dtm_ack_o;
    wire dtm_req_valid_o;
    wire[DTM_REQ_BITS - 1:0] dtm_req_data_o;

    // jtag_dm
    wire dm_ack_o;
    wire[DM_RESP_BITS-1:0] dm_resp_data_o;
    wire dm_resp_valid_o;
    wire dm_op_req_o;
    wire dm_halt_req_o;
    wire dm_reset_req_o;

    jtag_driver #(
        .DMI_ADDR_BITS(DMI_ADDR_BITS),
        .DMI_DATA_BITS(DMI_DATA_BITS),
        .DMI_OP_BITS(DMI_OP_BITS)
    ) u_jtag_driver(
        .rst_n(jtag_rst_n),
        .jtag_TCK(jtag_pin_TCK),
        .jtag_TDI(jtag_pin_TDI),
        .jtag_TMS(jtag_pin_TMS),
        .jtag_TDO(jtag_pin_TDO),
        .dm_resp_i(dm_resp_valid_o),
        .dm_resp_data_i(dm_resp_data_o),
        .dtm_ack_o(dtm_ack_o),
        .dm_ack_i(dm_ack_o),
        .dtm_req_valid_o(dtm_req_valid_o),
        .dtm_req_data_o(dtm_req_data_o)
    );

    jtag_dm #(
        .DMI_ADDR_BITS(DMI_ADDR_BITS),
        .DMI_DATA_BITS(DMI_DATA_BITS),
        .DMI_OP_BITS(DMI_OP_BITS)
    ) u_jtag_dm(
        .clk(clk),
        .rst_n(jtag_rst_n),
        .dm_ack_o(dm_ack_o),
        .dtm_req_valid_i(dtm_req_valid_o),
        .dtm_req_data_i(dtm_req_data_o),
        .dtm_ack_i(dtm_ack_o),
        .dm_resp_data_o(dm_resp_data_o),
        .dm_resp_valid_o(dm_resp_valid_o),
        .dm_reg_we_o(reg_we_o),
        .dm_reg_addr_o(reg_addr_o),
        .dm_reg_wdata_o(reg_wdata_o),
        .dm_reg_rdata_i(reg_rdata_i),
        .dm_mem_we_o(mem_we_o),
        .dm_mem_addr_o(mem_addr_o),
        .dm_mem_wdata_o(mem_wdata_o),
        .dm_mem_rdata_i(mem_rdata_i),
        .dm_op_req_o(op_req_o),
        .dm_halt_req_o(halt_req_o),
        .dm_reset_req_o(reset_req_o)
    );

endmodule
