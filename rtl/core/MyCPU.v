// -----------------------------------------------------------------------------
// File Name  : MyCPU.v
// Module Name: MyCPU
// Author     : sasathreena
// Version    : 0.9
// Description: RISC-V处理器内核顶层模块
//              实现RV32I指令集架构的处理器核心
// -----------------------------------------------------------------------------
// Revision History:
// Date        By              Version         Change Description
// -----------------------------------------------------------------------------
// 2025/04/10  sasathreena     0.9             初始版本
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// 模块: MyCPU - RISC-V处理器核心
// 功能: 实现RV32I基本指令集架构，提供流水线执行单元
// 说明: 包含取指、译码、执行、访存、写回五级流水线结构
// -----------------------------------------------------------------------------

`include "defines.v"

//顶层模块
module MyCPU(

    input wire clk,
    input wire rst,

    output wire[`MemAddrBus] rib_ex_addr_o,    // 读、写外设的地址
    input wire[`MemBus] rib_ex_data_i,         // 从外设读取的数据
    output wire[`MemBus] rib_ex_data_o,        // 写入外设的数据
    output wire rib_ex_req_o,                  // 访问外设请求
    output wire rib_ex_we_o,                   // 写外设标志
    output wire[3:0] rib_ex_sel_o,             // 写外设字节选择信号

    output wire[`MemAddrBus] rib_pc_addr_o,    // 取指地址
    input wire[`MemBus] rib_pc_data_i,         // 取到的指令内容

    input wire[`RegAddrBus] jtag_reg_addr_i,   // jtag模块读、写寄存器的地址
    input wire[`RegBus] jtag_reg_data_i,       // jtag模块写寄存器数据
    input wire jtag_reg_we_i,                  // jtag模块写寄存器标志
    output wire[`RegBus] jtag_reg_data_o,      // jtag模块读取到的寄存器数据

    input wire rib_hold_flag_i,                // 总线暂停标志
    input wire jtag_halt_flag_i,               // jtag暂停标志
    input wire jtag_reset_flag_i,              // jtag复位PC标志

    input wire[`INT_BUS] int_i                 // 中断信号

    );

    // pc_reg模块输出信号
	wire[`InstAddrBus] pc_pc_o;

    // if_id模块输出信号
	wire[`InstBus] if_inst_o;
    wire[`InstAddrBus] if_inst_addr_o;
    wire[`INT_BUS] if_int_flag_o;

    // id模块输出信号
    wire[`RegAddrBus] id_reg1_raddr_o;
    wire[`RegAddrBus] id_reg2_raddr_o;
    wire[`InstBus] id_inst_o;
    wire[`InstAddrBus] id_inst_addr_o;
    wire[`RegBus] id_reg1_rdata_o;
    wire[`RegBus] id_reg2_rdata_o;
    wire id_reg_we_o;
    wire[`RegAddrBus] id_reg_waddr_o;
    wire[`MemAddrBus] id_csr_raddr_o;
    wire id_csr_we_o;
    wire[`RegBus] id_csr_rdata_o;
    wire[`MemAddrBus] id_csr_waddr_o;
    wire[`MemAddrBus] id_op1_o;
    wire[`MemAddrBus] id_op2_o;
    wire[`MemAddrBus] id_op1_jump_o;
    wire[`MemAddrBus] id_op2_jump_o;
    wire id_load_use_relevant_o;          // load-use相关信号

    // id_ex模块输出信号
    wire[`InstBus] ie_inst_o;
    wire[`InstAddrBus] ie_inst_addr_o;
    wire ie_reg_we_o;
    wire[`RegAddrBus] ie_reg_waddr_o;
    wire[`RegBus] ie_reg1_rdata_o;
    wire[`RegBus] ie_reg2_rdata_o;
    wire ie_csr_we_o;
    wire[`MemAddrBus] ie_csr_waddr_o;
    wire[`RegBus] ie_csr_rdata_o;
    wire[`MemAddrBus] ie_op1_o;
    wire[`MemAddrBus] ie_op2_o;
    wire[`MemAddrBus] ie_op1_jump_o;
    wire[`MemAddrBus] ie_op2_jump_o;

    // ex模块输出信号
    wire[`MemBus] ex_mem_wdata_o;
    wire[`MemAddrBus] ex_mem_raddr_o;
    wire[`MemAddrBus] ex_mem_waddr_o;
    wire ex_mem_we_o;
    wire ex_mem_req_o;
    wire[3:0] ex_mem_sel_o;
    wire[`RegBus] ex_reg_wdata_o;
    wire ex_reg_we_o;
    wire[`RegAddrBus] ex_reg_waddr_o;
    wire ex_hold_flag_o;
    wire ex_jump_flag_o;
    wire[`InstAddrBus] ex_jump_addr_o;
    wire ex_div_start_o;
    wire[`RegBus] ex_div_dividend_o;
    wire[`RegBus] ex_div_divisor_o;
    wire[2:0] ex_div_op_o;
    wire[`RegAddrBus] ex_div_reg_waddr_o;
    wire[`RegBus] ex_csr_wdata_o;
    wire ex_csr_we_o;
    wire[`MemAddrBus] ex_csr_waddr_o;
    wire ex_inst_is_load_o;              // load指令标志
    
    // ex_mem模块输出信号
    wire[`InstBus] exm_inst_o;
    wire[`InstAddrBus] exm_inst_addr_o;
    wire exm_reg_we_o;
    wire[`RegAddrBus] exm_reg_waddr_o;
    wire[`RegBus] exm_reg_wdata_o;
    wire exm_csr_we_o;
    wire[`MemAddrBus] exm_csr_waddr_o;
    wire[`RegBus] exm_csr_wdata_o;
    wire[`MemBus] exm_mem_wdata_o;
    wire[`MemAddrBus] exm_mem_raddr_o;
    wire[`MemAddrBus] exm_mem_waddr_o;
    wire exm_mem_we_o;
    wire exm_mem_req_o;
    wire[3:0] exm_mem_sel_o;
    wire exm_jump_flag_o;
    wire[`InstAddrBus] exm_jump_addr_o;
    
    // mem模块输出信号
    wire[`InstBus] mem_inst_o;
    wire[`InstAddrBus] mem_inst_addr_o;
    wire mem_reg_we_o;
    wire[`RegAddrBus] mem_reg_waddr_o;
    wire[`RegBus] mem_reg_wdata_o;
    wire mem_csr_we_o;
    wire[`MemAddrBus] mem_csr_waddr_o;
    wire[`RegBus] mem_csr_wdata_o;
    wire[`MemBus] mem_mem_wdata_o;
    wire[`MemAddrBus] mem_mem_raddr_o;
    wire[`MemAddrBus] mem_mem_waddr_o;
    wire mem_mem_we_o;
    wire mem_mem_req_o;
    wire[3:0] mem_mem_sel_o;
    wire mem_jump_flag_o;
    wire[`InstAddrBus] mem_jump_addr_o;
    
    // mem_wb模块输出信号
    wire[`InstBus] mw_inst_o;
    wire[`InstAddrBus] mw_inst_addr_o;
    wire mw_reg_we_o;
    wire[`RegAddrBus] mw_reg_waddr_o;
    wire[`RegBus] mw_reg_wdata_o;
    wire mw_csr_we_o;
    wire[`MemAddrBus] mw_csr_waddr_o;
    wire[`RegBus] mw_csr_wdata_o;
    wire mw_jump_flag_o;
    wire[`InstAddrBus] mw_jump_addr_o;
    
    // wb模块输出信号
    wire wb_reg_we_o;
    wire[`RegAddrBus] wb_reg_waddr_o;
    wire[`RegBus] wb_reg_wdata_o;
    wire wb_csr_we_o;
    wire[`MemAddrBus] wb_csr_waddr_o;
    wire[`RegBus] wb_csr_wdata_o;
    wire wb_jump_flag_o;
    wire[`InstAddrBus] wb_jump_addr_o;

    // regs模块输出信号
    wire[`RegBus] regs_rdata1_o;
    wire[`RegBus] regs_rdata2_o;

    // csr_reg模块输出信号
    wire[`RegBus] csr_data_o;
    wire[`RegBus] csr_clint_data_o;
    wire csr_global_int_en_o;
    wire[`RegBus] csr_clint_csr_mtvec;
    wire[`RegBus] csr_clint_csr_mepc;
    wire[`RegBus] csr_clint_csr_mstatus;

    // ctrl模块输出信号
    wire[`Hold_Flag_Bus] ctrl_hold_flag_o;
    wire ctrl_jump_flag_o;
    wire[`InstAddrBus] ctrl_jump_addr_o;

    // div模块输出信号
    wire[`RegBus] div_result_o;
	wire div_ready_o;
    wire div_busy_o;
    wire[`RegAddrBus] div_reg_waddr_o;

    // clint模块输出信号
    wire clint_we_o;
    wire[`MemAddrBus] clint_waddr_o;
    wire[`MemAddrBus] clint_raddr_o;
    wire[`RegBus] clint_data_o;
    wire[`InstAddrBus] clint_int_addr_o;
    wire clint_int_assert_o;
    wire clint_hold_flag_o;


    assign rib_ex_addr_o = mem_mem_we_o ? mem_mem_waddr_o : mem_mem_raddr_o;
    assign rib_ex_data_o = mem_mem_wdata_o;
    assign rib_ex_req_o = mem_mem_req_o;
    assign rib_ex_we_o = mem_mem_we_o;
    assign rib_ex_sel_o = mem_mem_sel_o;

    assign rib_pc_addr_o = pc_pc_o;


    // pc_reg模块例化
    pc_reg u_pc_reg(
        .clk(clk),
        .rst(rst),
        .jtag_reset_flag_i(jtag_reset_flag_i),
        .pc_o(pc_pc_o),
        .hold_flag_i(ctrl_hold_flag_o),
        .jump_flag_i(ctrl_jump_flag_o),
        .jump_addr_i(ctrl_jump_addr_o)
    );

    // ctrl模块例化
    ctrl u_ctrl(
        .rst(rst),
        .jump_flag_i(wb_jump_flag_o),
        .jump_addr_i(wb_jump_addr_o),
        .hold_flag_ex_i(ex_hold_flag_o),
        .hold_flag_rib_i(rib_hold_flag_i),
        .hold_flag_o(ctrl_hold_flag_o),
        .hold_flag_clint_i(clint_hold_flag_o),
        .jump_flag_o(ctrl_jump_flag_o),
        .jump_addr_o(ctrl_jump_addr_o),
        .jtag_halt_flag_i(jtag_halt_flag_i),
        .load_use_relevant_i(id_load_use_relevant_o)
    );

    // regs模块例化
    regs u_regs(
        .clk(clk),
        .rst(rst),
        .we_i(wb_reg_we_o),
        .waddr_i(wb_reg_waddr_o),
        .wdata_i(wb_reg_wdata_o),
        .raddr1_i(id_reg1_raddr_o),
        .rdata1_o(regs_rdata1_o),
        .raddr2_i(id_reg2_raddr_o),
        .rdata2_o(regs_rdata2_o),
        .jtag_we_i(jtag_reg_we_i),
        .jtag_addr_i(jtag_reg_addr_i),
        .jtag_data_i(jtag_reg_data_i),
        .jtag_data_o(jtag_reg_data_o)
    );

    // csr_reg模块例化
    csr_reg u_csr_reg(
        .clk(clk),
        .rst(rst),
        .we_i(wb_csr_we_o),
        .raddr_i(id_csr_raddr_o),
        .waddr_i(wb_csr_waddr_o),
        .data_i(wb_csr_wdata_o),
        .data_o(csr_data_o),
        .global_int_en_o(csr_global_int_en_o),
        .clint_we_i(clint_we_o),
        .clint_raddr_i(clint_raddr_o),
        .clint_waddr_i(clint_waddr_o),
        .clint_data_i(clint_data_o),
        .clint_data_o(csr_clint_data_o),
        .clint_csr_mtvec(csr_clint_csr_mtvec),
        .clint_csr_mepc(csr_clint_csr_mepc),
        .clint_csr_mstatus(csr_clint_csr_mstatus)
    );

    // if_id模块例化
    if_id u_if_id(
        .clk(clk),
        .rst(rst),
        .inst_i(rib_pc_data_i),
        .inst_addr_i(pc_pc_o),
        .int_flag_i(int_i),
        .int_flag_o(if_int_flag_o),
        .hold_flag_i(ctrl_hold_flag_o),
        .inst_o(if_inst_o),
        .inst_addr_o(if_inst_addr_o)
    );

    // id模块例化
    id u_id(
        .rst(rst),
        .inst_i(if_inst_o),
        .inst_addr_i(if_inst_addr_o),
        .reg1_rdata_i(regs_rdata1_o),
        .reg2_rdata_i(regs_rdata2_o),
        .ex_jump_flag_i(ex_jump_flag_o),
        .ex_reg_we_i(ex_reg_we_o),
        .ex_reg_waddr_i(ex_reg_waddr_o),
        .ex_reg_wdata_i(ex_reg_wdata_o),
        .ex_inst_is_load(ex_inst_is_load_o),
        .mem_reg_we_i(mem_reg_we_o),
        .mem_reg_waddr_i(mem_reg_waddr_o),
        .mem_reg_wdata_i(mem_reg_wdata_o),
        .wb_reg_we_i(wb_reg_we_o),
        .wb_reg_waddr_i(wb_reg_waddr_o),
        .wb_reg_wdata_i(wb_reg_wdata_o),
        .reg1_raddr_o(id_reg1_raddr_o),
        .reg2_raddr_o(id_reg2_raddr_o),
        .inst_o(id_inst_o),
        .inst_addr_o(id_inst_addr_o),
        .reg1_rdata_o(id_reg1_rdata_o),
        .reg2_rdata_o(id_reg2_rdata_o),
        .reg_we_o(id_reg_we_o),
        .reg_waddr_o(id_reg_waddr_o),
        .op1_o(id_op1_o),
        .op2_o(id_op2_o),
        .op1_jump_o(id_op1_jump_o),
        .op2_jump_o(id_op2_jump_o),
        .csr_rdata_i(csr_data_o),
        .csr_raddr_o(id_csr_raddr_o),
        .csr_we_o(id_csr_we_o),
        .csr_rdata_o(id_csr_rdata_o),
        .csr_waddr_o(id_csr_waddr_o),
        .load_use_relevant_o(id_load_use_relevant_o)
    );

    // id_ex模块例化
    id_ex u_id_ex(
        .clk(clk),
        .rst(rst),
        .inst_i(id_inst_o),
        .inst_addr_i(id_inst_addr_o),
        .reg_we_i(id_reg_we_o),
        .reg_waddr_i(id_reg_waddr_o),
        .reg1_rdata_i(id_reg1_rdata_o),
        .reg2_rdata_i(id_reg2_rdata_o),
        .hold_flag_i(ctrl_hold_flag_o),
        .inst_o(ie_inst_o),
        .inst_addr_o(ie_inst_addr_o),
        .reg_we_o(ie_reg_we_o),
        .reg_waddr_o(ie_reg_waddr_o),
        .reg1_rdata_o(ie_reg1_rdata_o),
        .reg2_rdata_o(ie_reg2_rdata_o),
        .op1_i(id_op1_o),
        .op2_i(id_op2_o),
        .op1_jump_i(id_op1_jump_o),
        .op2_jump_i(id_op2_jump_o),
        .op1_o(ie_op1_o),
        .op2_o(ie_op2_o),
        .op1_jump_o(ie_op1_jump_o),
        .op2_jump_o(ie_op2_jump_o),
        .csr_we_i(id_csr_we_o),
        .csr_waddr_i(id_csr_waddr_o),
        .csr_rdata_i(id_csr_rdata_o),
        .csr_we_o(ie_csr_we_o),
        .csr_waddr_o(ie_csr_waddr_o),
        .csr_rdata_o(ie_csr_rdata_o)
    );

    // ex模块例化
    ex u_ex(
        .rst(rst),
        .inst_i(ie_inst_o),
        .inst_addr_i(ie_inst_addr_o),
        .reg_we_i(ie_reg_we_o),
        .reg_waddr_i(ie_reg_waddr_o),
        .reg1_rdata_i(ie_reg1_rdata_o),
        .reg2_rdata_i(ie_reg2_rdata_o),
        .op1_i(ie_op1_o),
        .op2_i(ie_op2_o),
        .op1_jump_i(ie_op1_jump_o),
        .op2_jump_i(ie_op2_jump_o),
        .mem_wdata_o(ex_mem_wdata_o),
        .mem_raddr_o(ex_mem_raddr_o),
        .mem_waddr_o(ex_mem_waddr_o),
        .mem_we_o(ex_mem_we_o),
        .mem_req_o(ex_mem_req_o),
        .mem_sel_o(ex_mem_sel_o),
        .reg_wdata_o(ex_reg_wdata_o),
        .reg_we_o(ex_reg_we_o),
        .reg_waddr_o(ex_reg_waddr_o),
        .hold_flag_o(ex_hold_flag_o),
        .jump_flag_o(ex_jump_flag_o),
        .jump_addr_o(ex_jump_addr_o),
        .int_assert_i(clint_int_assert_o),
        .int_addr_i(clint_int_addr_o),
        .div_ready_i(div_ready_o),
        .div_result_i(div_result_o),
        .div_busy_i(div_busy_o),
        .div_reg_waddr_i(div_reg_waddr_o),
        .div_start_o(ex_div_start_o),
        .div_dividend_o(ex_div_dividend_o),
        .div_divisor_o(ex_div_divisor_o),
        .div_op_o(ex_div_op_o),
        .div_reg_waddr_o(ex_div_reg_waddr_o),
        .csr_we_i(ie_csr_we_o),
        .csr_waddr_i(ie_csr_waddr_o),
        .csr_rdata_i(ie_csr_rdata_o),
        .csr_wdata_o(ex_csr_wdata_o),
        .csr_we_o(ex_csr_we_o),
        .csr_waddr_o(ex_csr_waddr_o),
        .inst_is_load_o(ex_inst_is_load_o)
    );

    // ex_mem模块例化
    ex_mem u_ex_mem(
        .clk(clk),
        .rst(rst),
        .inst_i(ie_inst_o),
        .inst_addr_i(ie_inst_addr_o),
        .reg_we_i(ex_reg_we_o),
        .reg_waddr_i(ex_reg_waddr_o),
        .reg_wdata_i(ex_reg_wdata_o),
        .csr_we_i(ex_csr_we_o),
        .csr_waddr_i(ex_csr_waddr_o),
        .csr_wdata_i(ex_csr_wdata_o),
        .mem_wdata_i(ex_mem_wdata_o),
        .mem_raddr_i(ex_mem_raddr_o),
        .mem_waddr_i(ex_mem_waddr_o),
        .mem_we_i(ex_mem_we_o),
        .mem_req_i(ex_mem_req_o),
        .mem_sel_i(ex_mem_sel_o),
        .jump_flag_i(ex_jump_flag_o),
        .jump_addr_i(ex_jump_addr_o),
        .hold_flag_i(ctrl_hold_flag_o),
        .inst_o(exm_inst_o),
        .inst_addr_o(exm_inst_addr_o),
        .reg_we_o(exm_reg_we_o),
        .reg_waddr_o(exm_reg_waddr_o),
        .reg_wdata_o(exm_reg_wdata_o),
        .csr_we_o(exm_csr_we_o),
        .csr_waddr_o(exm_csr_waddr_o),
        .csr_wdata_o(exm_csr_wdata_o),
        .mem_wdata_o(exm_mem_wdata_o),
        .mem_raddr_o(exm_mem_raddr_o),
        .mem_waddr_o(exm_mem_waddr_o),
        .mem_we_o(exm_mem_we_o),
        .mem_req_o(exm_mem_req_o),
        .mem_sel_o(exm_mem_sel_o),
        .jump_flag_o(exm_jump_flag_o),
        .jump_addr_o(exm_jump_addr_o)
    );

    // mem模块例化
    mem u_mem(
        .rst(rst),
        .inst_i(exm_inst_o),
        .inst_addr_i(exm_inst_addr_o),
        .reg_we_i(exm_reg_we_o),
        .reg_waddr_i(exm_reg_waddr_o),
        .reg_wdata_i(exm_reg_wdata_o),
        .csr_we_i(exm_csr_we_o),
        .csr_waddr_i(exm_csr_waddr_o),
        .csr_wdata_i(exm_csr_wdata_o),
        .mem_wdata_i(exm_mem_wdata_o),
        .mem_raddr_i(exm_mem_raddr_o),
        .mem_waddr_i(exm_mem_waddr_o),
        .mem_we_i(exm_mem_we_o),
        .mem_req_i(exm_mem_req_o),
        .mem_sel_i(exm_mem_sel_o),
        .mem_data_i(rib_ex_data_i),
        .jump_flag_i(exm_jump_flag_o),
        .jump_addr_i(exm_jump_addr_o),
        .inst_o(mem_inst_o),
        .inst_addr_o(mem_inst_addr_o),
        .reg_we_o(mem_reg_we_o),
        .reg_waddr_o(mem_reg_waddr_o),
        .reg_wdata_o(mem_reg_wdata_o),
        .csr_we_o(mem_csr_we_o),
        .csr_waddr_o(mem_csr_waddr_o),
        .csr_wdata_o(mem_csr_wdata_o),
        .mem_wdata_o(mem_mem_wdata_o),
        .mem_raddr_o(mem_mem_raddr_o),
        .mem_waddr_o(mem_mem_waddr_o),
        .mem_we_o(mem_mem_we_o),
        .mem_req_o(mem_mem_req_o),
        .mem_sel_o(mem_mem_sel_o),
        .jump_flag_o(mem_jump_flag_o),
        .jump_addr_o(mem_jump_addr_o)
    );

    // mem_wb模块例化
    mem_wb u_mem_wb(
        .clk(clk),
        .rst(rst),
        .inst_i(mem_inst_o),
        .inst_addr_i(mem_inst_addr_o),
        .reg_we_i(mem_reg_we_o),
        .reg_waddr_i(mem_reg_waddr_o),
        .reg_wdata_i(mem_reg_wdata_o),
        .csr_we_i(mem_csr_we_o),
        .csr_waddr_i(mem_csr_waddr_o),
        .csr_wdata_i(mem_csr_wdata_o),
        .jump_flag_i(mem_jump_flag_o),
        .jump_addr_i(mem_jump_addr_o),
        .hold_flag_i(ctrl_hold_flag_o),
        .inst_o(mw_inst_o),
        .inst_addr_o(mw_inst_addr_o),
        .reg_we_o(mw_reg_we_o),
        .reg_waddr_o(mw_reg_waddr_o),
        .reg_wdata_o(mw_reg_wdata_o),
        .csr_we_o(mw_csr_we_o),
        .csr_waddr_o(mw_csr_waddr_o),
        .csr_wdata_o(mw_csr_wdata_o),
        .jump_flag_o(mw_jump_flag_o),
        .jump_addr_o(mw_jump_addr_o)
    );

    // wb模块例化
    wb u_wb(
        .rst(rst),
        .inst_i(mw_inst_o),
        .inst_addr_i(mw_inst_addr_o),
        .reg_we_i(mw_reg_we_o),
        .reg_waddr_i(mw_reg_waddr_o),
        .reg_wdata_i(mw_reg_wdata_o),
        .csr_we_i(mw_csr_we_o),
        .csr_waddr_i(mw_csr_waddr_o),
        .csr_wdata_i(mw_csr_wdata_o),
        .jump_flag_i(mw_jump_flag_o),
        .jump_addr_i(mw_jump_addr_o),
        .reg_we_o(wb_reg_we_o),
        .reg_waddr_o(wb_reg_waddr_o),
        .reg_wdata_o(wb_reg_wdata_o),
        .csr_we_o(wb_csr_we_o),
        .csr_waddr_o(wb_csr_waddr_o),
        .csr_wdata_o(wb_csr_wdata_o),
        .jump_flag_o(wb_jump_flag_o),
        .jump_addr_o(wb_jump_addr_o)
    );

    // div模块例化
    div u_div(
        .clk(clk),
        .rst(rst),
        .dividend_i(ex_div_dividend_o),
        .divisor_i(ex_div_divisor_o),
        .start_i(ex_div_start_o),
        .op_i(ex_div_op_o),
        .reg_waddr_i(ex_div_reg_waddr_o),
        .result_o(div_result_o),
        .ready_o(div_ready_o),
        .busy_o(div_busy_o),
        .reg_waddr_o(div_reg_waddr_o)
    );

    // clint模块例化
    clint u_clint(
        .clk(clk),
        .rst(rst),
        .int_flag_i(if_int_flag_o),
        .inst_i(mem_inst_o),
        .inst_addr_i(mem_inst_addr_o),
        .jump_flag_i(ex_jump_flag_o),
        .jump_addr_i(ex_jump_addr_o),
        .hold_flag_i(ctrl_hold_flag_o),
        .div_started_i(ex_div_start_o),
        .data_i(csr_clint_data_o),
        .csr_mtvec(csr_clint_csr_mtvec),
        .csr_mepc(csr_clint_csr_mepc),
        .csr_mstatus(csr_clint_csr_mstatus),
        .we_o(clint_we_o),
        .waddr_o(clint_waddr_o),
        .raddr_o(clint_raddr_o),
        .data_o(clint_data_o),
        .hold_flag_o(clint_hold_flag_o),
        .global_int_en_i(csr_global_int_en_o),
        .int_addr_o(clint_int_addr_o),
        .int_assert_o(clint_int_assert_o)
    );

endmodule
