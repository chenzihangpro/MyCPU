# MyCPU RISC-V处理器核

MyCPU是我们设计的基于RISC-V指令集架构的32位处理器核心，采用五级流水线架构实现，支持RV32IM指令集及中断功能，可在FPGA上实现并通过标准RISC-V指令集兼容性测试。

## 1. 处理器核心架构

### 1.1 核心特性

- **指令集支持**：实现RV32IM指令集，包括整数基础指令(I)和乘除法指令(M)
- **流水线架构**：经典五级流水线设计 (取指IF、译码ID、执行EX、访存MEM、写回WB)
- **中断处理**：支持标准RISC-V中断机制，内置CLINT核心中断控制器
- **CSR寄存器**：支持必要的控制状态寄存器，如mtvec、mepc、mcause等
- **总线接口**：基于Wishbone总线协议，便于外设扩展
- **外设支持**：集成UART、GPIO、Timer、SPI等基本外设
- **Debug支持**：支持JTAG调试及UART调试下载接口

### 1.2 流水线设计

MyCPU采用经典的五级流水线架构：

- **取指 (IF)**：负责根据PC获取指令
- **译码 (ID)**：对指令进行解码，确定操作类型
- **执行 (EX)**：执行ALU运算及跳转指令
- **访存 (MEM)**：访问数据存储器
- **写回 (WB)**：将结果写回寄存器

流水线设计包含数据前递、流水线暂停等机制，解决数据相关及控制相关问题。

### 1.3 设计亮点

- **高效乘除法实现**：乘法采用阵列乘法器，除法采用迭代试商法
- **完整的CSR机制**：支持RISC-V特权架构中的CSR操作
- **灵活的中断控制**：包含时钟中断和外部中断支持
- **模块化设计**：核心与外设分离，便于功能扩展和维护
- **完善的验证体系**：支持RISC-V官方指令集兼容性测试

## 2. 系统架构

### 2.1 SoC架构

MyCPU SoC系统采用总线互连架构，主要组件包括：

- **处理器核心**：MyCPU RISC-V处理器核
- **存储器**：ROM（指令存储）和RAM（数据存储）
- **外设模块**：UART、GPIO、Timer、SPI等
- **调试模块**：JTAG接口和UART调试下载接口
- **总线互连**：基于Wishbone总线协议的RIB总线

### 2.2 存储映射

| 地址范围           | 模块           | 描述                 |
|-------------------|---------------|---------------------|
| 0x00000000-0x00002FFF | ROM         | 指令存储ROM，12KB     |
| 0x00003000-0x00003FFF | RAM         | 数据存储RAM，4KB      |
| 0x00010000-0x0001FFFF | UART        | 串口通信控制器         |
| 0x00020000-0x00020FFF | Timer       | 定时器0-2            |
| 0x00030000-0x0003000F | GPIO        | 通用IO控制器          |
| 0x00040000-0x0004FFFF | SPI         | SPI控制器            |

## 3. 目录结构

```
MyCPU/
├── fpga/                   # FPGA实现相关文件
│   ├── constrs/            # 约束文件
│   └── images/             # FPGA实现相关图片
├── rtl/                    # RTL源代码
│   ├── core/               # 处理器核心模块
│   │   ├── MyCPU.v         # 处理器核心顶层
│   │   ├── defines.v       # 全局宏定义
│   │   ├── clint.v         # 中断控制器
│   │   ├── csr_reg.v       # CSR寄存器模块
│   │   ├── ctrl.v          # 控制模块
│   │   ├── div.v           # 除法器
│   │   ├── ex.v            # 执行阶段
│   │   ├── id.v            # 译码阶段及数据前递
│   │   ├── if_id.v         # IF/ID流水线寄存器
│   │   ├── id_ex.v         # ID/EX流水线寄存器
│   │   ├── ex_mem.v        # EX/MEM流水线寄存器
│   │   ├── mem.v           # 访存阶段
│   │   ├── mem_wb.v        # MEM/WB流水线寄存器
│   │   ├── pc_reg.v        # PC寄存器
│   │   ├── regs.v          # 通用寄存器组
│   │   ├── rib.v           # 总线互连模块
│   │   └── wb.v            # 写回阶段
│   └── soc/                # SoC集成模块
│       ├── MyCPU_soc.v     # SoC顶层模块
│       ├── uart.v          # UART控制器
│       ├── timer.v         # 定时器
│       ├── spi.v           # SPI控制器
│       ├── rom.v           # ROM模块
│       ├── ram.v           # RAM模块
│       └── gpio.v          # GPIO控制器
├── sim/                    # 仿真测试代码
│   ├── test_all_isa.py     # 指令集测试脚本
│   ├── sim_new_nowave.py   # 不带波形的仿真脚本
│   └── sim_with_wave.py    # 带波形的仿真脚本
├── tb/                     # 测试平台代码
│   └── MyCPU_soc_tb.v      # SoC顶层测试平台
├── tests/                  # 测试程序代码
│   ├── example/            # 软件例程
│   │   ├── coremark/       # CoreMark测试程序
│   │   ├── FreeRTOS/       # FreeRTOS移植
│   │   ├── gpio/           # GPIO测试例程
│   │   ├── uart_tx/        # UART发送测试例程
│   │   └── timer_int/      # 定时器中断测试例程
│   └── isa/                # 指令集测试
│       ├── rv32ui/         # RV32I指令测试
│       └── rv32um/         # RV32M指令测试
└── tools/                  # 工具程序
    ├── gnu-mcu-eclipse/    # RISC-V GNU工具链
    └── openocd/            # OpenOCD调试工具
```

## 4. 使用指南

### 4.1 编译仿真

1. **准备仿真环境**
   - 安装iverilog和GTKWave波形查看器
   - 安装Python环境及相关依赖

2. **运行指令集测试**
   ```
   cd sim
   python test_all_isa.py
   ```

3. **查看波形**
   
   ```
   cd sim
   gtkwave MyCPU_soc_tb.vcd
   ```

### 4.2 FPGA实现

1. **创建FPGA工程**
   - 使用Vivado或Quartus等FPGA开发工具创建工程
   - 添加rtl目录下的所有源文件
   - 添加fpga/constrs中对应的约束文件

2. **生成比特流**
   - 综合、实现并生成比特流文件
   - 下载到FPGA开发板

3. **程序下载**
   - 通过JTAG或UART接口下载应用程序
   - 使用tools目录下的工具进行下载和调试

### 4.3 应用程序开发

1. **设置工具链**
   - 使用tools目录下的RISC-V GNU工具链
   - 编写自定义程序时参考tests/example中的例程

2. **编译程序**
   ```
   riscv-none-embed-gcc -march=rv32im -mabi=ilp32 -nostartfiles -Wl,-Bstatic,-T,<链接脚本> -o <输出文件>.elf <源文件>.c
   riscv-none-embed-objcopy -O binary <输出文件>.elf <输出文件>.bin
   ```

3. **下载测试**
   - 通过JTAG或UART接口下载编译好的二进制文件
   - 使用OpenOCD或自定义下载工具

## 5. 代码实现说明

### 5.1 核心流水线实现

MyCPU采用五级流水线架构，以下是关键模块的实现细节：

#### 5.1.1 数据前递机制

数据前递机制是解决流水线数据相关问题的关键技术，以下是`id.v`中的相关实现：

```verilog
// 检测寄存器1数据相关
always @ (*) begin
    // 默认值
    reg1_raw_ex = 1'b0;
    reg1_raw_mem = 1'b0;
    reg1_raw_wb = 1'b0;
    
    // 检测EX阶段数据相关
    if ((ex_reg_we_i == `WriteEnable) && (ex_reg_waddr_i != `ZeroReg) && (ex_reg_waddr_i == rs1)) begin
        reg1_raw_ex = 1'b1;
    // 检测MEM阶段数据相关
    end else if ((mem_reg_we_i == `WriteEnable) && (mem_reg_waddr_i != `ZeroReg) && (mem_reg_waddr_i == rs1)) begin
        reg1_raw_mem = 1'b1;
    // 检测WB阶段数据相关
    end else if ((wb_reg_we_i == `WriteEnable) && (wb_reg_waddr_i != `ZeroReg) && (wb_reg_waddr_i == rs1)) begin
        reg1_raw_wb = 1'b1;
    end
end

// 确定寄存器1最终使用的数据
assign reg1_data = (rs1 == `ZeroReg) ? `ZeroWord :
                   reg1_raw_ex ? ex_reg_wdata_i :
                   reg1_raw_mem ? mem_reg_wdata_i :
                   reg1_raw_wb ? wb_reg_wdata_i :
                   reg1_rdata_i;
```

这段代码通过检测各阶段的寄存器写回信息，识别数据相关，并从最近的阶段前递数据。

#### 5.1.2 流水线暂停控制

在`ctrl.v`模块中实现了流水线暂停控制逻辑，主要处理以下几种暂停情况：
- 加载使用型相关 (load-use hazard)
- 除法器忙时的暂停
- 总线访问冲突时的暂停
- 中断处理时的暂停

#### 5.1.3 分支预测与跳转控制

MyCPU采用静态分支预测策略，在执行阶段确定是否跳转：

```verilog
// 分支指令处理
case (funct3)
    `INST_BEQ: begin
        jump_flag = op1_eq_op2 ? `JumpEnable : `JumpDisable;
        jump_addr = op1_eq_op2 ? op1_jump_add_op2_jump_res : inst_addr_i + 4'h4;
    end
    `INST_BNE: begin
        jump_flag = (!op1_eq_op2) ? `JumpEnable : `JumpDisable;
        jump_addr = (!op1_eq_op2) ? op1_jump_add_op2_jump_res : inst_addr_i + 4'h4;
    end
    `INST_BLT: begin
        jump_flag = (!op1_ge_op2_signed) ? `JumpEnable : `JumpDisable;
        jump_addr = (!op1_ge_op2_signed) ? op1_jump_add_op2_jump_res : inst_addr_i + 4'h4;
    end
    // 其他分支指令...
endcase
```

### 5.2 高效算术单元

#### 5.2.1 Radix-8 除法器

MyCPU实现了高效的Radix-8除法器，每次尝试除以7/6/5/4/3/2/1倍的除数，大大提高了除法效率：

```verilog
// 比较结果
wire minuend_ge_divisor = minuend >= divisor_r;
wire minuend_ge_2x_divisor = minuend >= divisor_2x;
wire minuend_ge_3x_divisor = minuend >= divisor_3x;
wire minuend_ge_4x_divisor = minuend >= divisor_4x;
wire minuend_ge_5x_divisor = minuend >= divisor_5x;
wire minuend_ge_6x_divisor = minuend >= divisor_6x;
wire minuend_ge_7x_divisor = minuend >= divisor_7x;

// 根据比较结果计算下一个减数和余数位
always @(*) begin
    if (minuend_ge_7x_divisor) begin
        next_minuend = minuend_sub_7x;
        next_quotient_bits = 3'b111; // 7
    end else if (minuend_ge_6x_divisor) begin
        next_minuend = minuend_sub_6x;
        next_quotient_bits = 3'b110; // 6
    end
    // 其他情况...
end
```

此外，还优化了除以2^n的特殊情况，使其可以在一个周期内完成：

```verilog
// 2^n快速路径检测 - 检查除数是否为2的幂次方
wire is_power_of_two = (divisor_r & (divisor_r - 1)) == 32'h0 && divisor_r != 32'h0;

// 计算快速路径结果 - 商和余数
wire[31:0] fast_quotient = dividend_r >> shift_count;
wire[31:0] fast_remainder = dividend_r & ((1 << shift_count) - 1);
```

#### 5.2.2 乘法器实现

乘法器支持各种有符号和无符号乘法操作：

```verilog
// 乘法指令处理
case (funct3)
    `INST_MUL: begin
        // 低32位乘法结果
        reg_wdata = mul_temp[31:0];
    end
    `INST_MULH: begin
        // 有符号数乘法，取高32位
        if ((reg1_rdata_i[31] ^ reg2_rdata_i[31]) == 1'b1) begin
            reg_wdata = mul_temp_invert[63:32];
        end else begin
            reg_wdata = mul_temp[63:32];
        end
    end
    // 其他乘法指令...
endcase
```

### 5.3 多主多从总线架构

MyCPU采用一种多主多从的总线结构，提供了高效的设备互连方案：

```verilog
// 仲裁逻辑
// 固定优先级仲裁机制
// 优先级由高到低：主设备3，主设备0，主设备2，主设备1
always @ (*) begin
    if (req[3]) begin
        grant = grant3;
        hold_flag_o = `HoldEnable;
    end else if (req[0]) begin
        grant = grant0;
        hold_flag_o = `HoldEnable;
    end else if (req[2]) begin
        grant = grant2;
        hold_flag_o = `HoldEnable;
    end else begin
        grant = grant1;
        hold_flag_o = `HoldDisable;
    end
end
```

这种结构支持多达4个主设备和6个从设备，通过地址高位解码选择从设备：

```verilog
// 访问地址的最高4位决定要访问的是哪一个从设备
// 因此最多支持16个从设备
parameter [3:0]slave_0 = 4'b0000;
parameter [3:0]slave_1 = 4'b0001;
parameter [3:0]slave_2 = 4'b0010;
parameter [3:0]slave_3 = 4'b0011;
parameter [3:0]slave_4 = 4'b0100;
parameter [3:0]slave_5 = 4'b0101;
```

### 5.4 访存优化实现

MyCPU实现了灵活的访存机制，支持不同数据宽度的加载和存储操作。相关优化包括：

#### 5.4.1 精确的字节选择逻辑

在执行阶段，根据指令类型和地址低位生成精确的字节选择信号，确保只有必要的字节被访问：

```verilog
// 字节存储指令的字节选择逻辑
case (op1_add_op2_res[1:0])
    2'b00: begin
        mem_wdata_o = {24'b0, reg2_rdata_i[7:0]};
        mem_sel_o = 4'b0001;
    end
    2'b01: begin
        mem_wdata_o = {16'b0, reg2_rdata_i[7:0], 8'b0};
        mem_sel_o = 4'b0010;
    end
    2'b10: begin
        mem_wdata_o = {8'b0, reg2_rdata_i[7:0], 16'b0};
        mem_sel_o = 4'b0100;
    end
    2'b11: begin
        mem_wdata_o = {reg2_rdata_i[7:0], 24'b0};
        mem_sel_o = 4'b1000;
    end
endcase
```

#### 5.4.2 加载指令数据扩展处理

在访存阶段，根据加载指令的类型对读取的数据进行符号或零扩展，支持字节(LB/LBU)、半字(LH/LHU)和字(LW)操作：

```verilog
// 字节加载指令的符号扩展
case (mem_raddr_i[1:0])
    2'b00: reg_wdata = {{24{mem_data_i[7]}}, mem_data_i[7:0]};
    2'b01: reg_wdata = {{24{mem_data_i[15]}}, mem_data_i[15:8]};
    2'b10: reg_wdata = {{24{mem_data_i[23]}}, mem_data_i[23:16]};
    2'b11: reg_wdata = {{24{mem_data_i[31]}}, mem_data_i[31:24]};
    default: reg_wdata = `ZeroWord;
endcase

// 无符号字节加载指令的零扩展
case (mem_raddr_i[1:0])
    2'b00: reg_wdata = {24'b0, mem_data_i[7:0]};
    2'b01: reg_wdata = {24'b0, mem_data_i[15:8]};
    2'b10: reg_wdata = {24'b0, mem_data_i[23:16]};
    2'b11: reg_wdata = {24'b0, mem_data_i[31:24]};
    default: reg_wdata = `ZeroWord;
endcase
```

#### 5.4.3 Load-Use冲突检测

为解决加载指令与其后续指令之间的数据相关问题，实现了专门的Load-Use冲突检测机制：

```verilog
// load-use相关性检测 - 当前指令要读取的寄存器是EX阶段的load指令要写的寄存器
always @ (*) begin
    // 默认没有load-use相关
    load_use_relevant_o = 1'b0;
    
    // 如果EX阶段指令是load类型，且当前指令读取的寄存器与EX阶段要写入的寄存器相同
    if (ex_inst_is_load && ex_reg_we_i && ex_reg_waddr_i != `ZeroReg) begin
        if ((reg1_raddr_o != `ZeroReg && reg1_raddr_o == ex_reg_waddr_i) || 
            (reg2_raddr_o != `ZeroReg && reg2_raddr_o == ex_reg_waddr_i)) begin
            load_use_relevant_o = 1'b1;
        end
    end
end
```

当检测到Load-Use冲突时，控制器会插入流水线气泡：

```verilog
// 在ctrl.v中处理load-use冲突
else if (load_use_relevant_i == `HoldEnable) begin
    hold_flag_o = `HOLD_PC | `HOLD_IF | `HOLD_ID;
end
```

#### 5.4.4 访存操作分类

MyCPU通过opcode和funct3字段识别不同类型的访存操作：

```verilog
// 识别加载指令类型
`define INST_TYPE_L  7'b0000011
`define INST_LB      3'b000
`define INST_LH      3'b001
`define INST_LW      3'b010
`define INST_LBU     3'b100
`define INST_LHU     3'b101

// 识别存储指令类型
`define INST_TYPE_S  7'b0100011
`define INST_SB      3'b000
`define INST_SH      3'b001
`define INST_SW      3'b010
```

### 5.5 中断处理机制

MyCPU实现了符合RISC-V特权架构规范的中断处理机制，支持异常、软件中断和外部中断：

#### 5.5.1 中断控制器状态机

`clint.v`模块实现了完整的中断状态机，包括空闲、同步中断断言、异步中断断言、中断返回等状态：

```verilog
// 中断处理逻辑
always @ (*) begin
    if (rst == `RstEnable) begin
        int_state = S_INT_IDLE;
    end else begin
        if (inst_i == `INST_ECALL || inst_i == `INST_EBREAK) begin
            // 当执行阶段的指令为陷阱指令且除法器未工作时触发中断
            if (div_started_i == `DivStop) begin
                int_state = S_INT_SYNC_ASSERT;
            end else begin
                int_state = S_INT_IDLE;
            end
        end else if (int_flag_i != `INT_NONE && global_int_en_i == `True) begin
            int_state = S_INT_ASYNC_ASSERT;
        end else if (inst_i == `INST_MRET) begin
            int_state = S_INT_MRET;
        end else begin
            int_state = S_INT_IDLE;
        end
    end
end
```

#### 5.5.2 CSR寄存器访问与修改

中断控制器根据中断类型和状态自动修改相关的CSR寄存器：

```verilog
// 写中断相关CSR寄存器
case (csr_state)
    // 将mepc寄存器赋值为当前指令地址
    S_CSR_MEPC: begin
        we_o <= `WriteEnable;
        waddr_o <= {20'h0, `CSR_MEPC};
        data_o <= inst_addr;
    end
    // 写中断产生的原因
    S_CSR_MCAUSE: begin
        we_o <= `WriteEnable;
        waddr_o <= {20'h0, `CSR_MCAUSE};
        data_o <= cause;
    end
    // 关闭全局中断
    S_CSR_MSTATUS: begin
        we_o <= `WriteEnable;
        waddr_o <= {20'h0, `CSR_MSTATUS};
        data_o <= {csr_mstatus[31:4], 1'b0, csr_mstatus[2:0]};
    end
    // 中断返回时恢复全局中断状态
    S_CSR_MSTATUS_MRET: begin
        we_o <= `WriteEnable;
        waddr_o <= {20'h0, `CSR_MSTATUS};
        data_o <= {csr_mstatus[31:4], csr_mstatus[7], csr_mstatus[2:0]};
    end
    default: begin
        we_o <= `WriteDisable;
        waddr_o <= `ZeroWord;
        data_o <= `ZeroWord;
    end
endcase
```

#### 5.5.3 中断向量和返回地址管理

中断控制器负责生成中断向量地址和管理中断返回：

```verilog
// 向执行单元发出中断信号
always @ (*) begin
    if (rst == `RstEnable) begin
        int_assert_o = `INT_DEASSERT;
        int_addr_o = `ZeroWord;
    end else begin
        case (csr_state)
            // 当完成CSR寄存器的修改后，跳转到中断处理程序
            S_CSR_MCAUSE: begin
                int_assert_o = `INT_ASSERT;
                int_addr_o = csr_mtvec;
            end
            // 中断返回时跳转到保存的返回地址
            S_CSR_MSTATUS_MRET: begin
                int_assert_o = `INT_ASSERT;
                int_addr_o = csr_mepc;
            end
            default: begin
                int_assert_o = `INT_DEASSERT;
                int_addr_o = `ZeroWord;
            end
        endcase
    end
end
```

#### 5.5.4 中断优先级和嵌套

MyCPU支持基于硬件的中断优先级机制，可通过修改CSR寄存器实现中断嵌套：

```verilog
// 在异步中断处理中根据中断类型确定优先级和处理方式
if (int_flag_i != `INT_NONE && global_int_en_i == `True) begin
    // 时钟中断
    cause <= 32'h80000004;
    csr_state <= S_CSR_MEPC;
    // 自动保存当前PC值
    if (jump_flag_i == `JumpEnable) begin
        inst_addr <= jump_addr_i;
    // 异步中断可能中断长指令的执行，中断处理程序需执行长指令
    end else if (div_started_i == `DivStart) begin
        inst_addr <= inst_addr_i - 4'h4;
    end else begin
        inst_addr <= inst_addr_i;
    end
end
```

## 6. 未来展望

- **扩展指令集**：计划支持RV32F等扩展指令集
- **多核支持**：设计多核互连架构
- **高级总线**：升级到AXI总线协议
- **缓存支持**：实现指令缓存和数据缓存
- **完善工具链**：开发更易用的开发和调试工具

## 7. 参考资料

- [RISC-V规范文档](https://riscv.org/specifications/)
- [RISC-V指令集手册](https://riscv.org/technical/specifications/)
- [Wishbone总线规范](https://wishbone-interconnect.readthedocs.io/) 
- [liangkangnan/tinyriscv: A very simple and easy to understand RISC-V core.](https://github.com/liangkangnan/tinyriscv)