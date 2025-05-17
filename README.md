# MyCPU RISC-V处理器核

MyCPU是一个基于RISC-V指令集架构的32位处理器核心，采用五级流水线架构实现，支持RV32IM指令集及中断功能，可在FPGA上实现并通过标准RISC-V指令集兼容性测试。

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
│   │   ├── id.v            # 译码阶段
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
│   └── tinyriscv_soc_tb.v  # SoC顶层测试平台
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

3. **带波形仿真**
   ```
   cd sim
   python sim_with_wave.py <测试程序路径> inst.data
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

## 5. 未来展望

- **扩展指令集**：计划支持RV32F等扩展指令集
- **多核支持**：设计多核互连架构
- **高级总线**：升级到AXI总线协议
- **缓存支持**：实现指令缓存和数据缓存
- **完善工具链**：开发更易用的开发和调试工具

## 6. 参考资料

- [RISC-V规范文档](https://riscv.org/specifications/)
- [RISC-V指令集手册](https://riscv.org/technical/specifications/)
- [Wishbone总线规范](https://wishbone-interconnect.readthedocs.io/) 