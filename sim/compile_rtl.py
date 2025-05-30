import sys
import filecmp
import subprocess
import sys
import os


# 主函数
def main():
    rtl_dir = sys.argv[1]

    if rtl_dir != r'..':
        tb_file = r'/tb/compliance_test/MyCPU_soc_tb.v'
    else:
        tb_file = r'/tb/MyCPU_soc_tb.v'

    # iverilog程序
    iverilog_cmd = ['iverilog']
    # 顶层模块
    #iverilog_cmd += ['-s', r'MyCPU_soc_tb']
    # 编译生成文件
    iverilog_cmd += ['-o', r'out.vvp']
    # 头文件(defines.v)路径
    iverilog_cmd += ['-I', rtl_dir + r'/rtl/core']
    # 宏定义，仿真输出文件
    iverilog_cmd += ['-D', r'OUTPUT="signature.output"']
    # testbench文件
    iverilog_cmd.append(rtl_dir + tb_file)
    # ../rtl/core
    iverilog_cmd.append(rtl_dir + r'/rtl/core/clint.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/csr_reg.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/ctrl.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/defines.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/div.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/ex.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/id.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/id_ex.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/if_id.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/pc_reg.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/regs.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/rib.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/wb.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/mem.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/ex_mem.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/mem_wb.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/branch_prediction.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/MyCPU.v')
    # ../rtl/soc
    iverilog_cmd.append(rtl_dir + r'/rtl/soc/ram.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/soc/rom.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/soc/timer.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/soc/uart.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/soc/gpio.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/soc/spi.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/soc/MyCPU_soc_top.v')
    # ../rtl/debug
    iverilog_cmd.append(rtl_dir + r'/rtl/debug/jtag_dm.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/debug/jtag_driver.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/debug/jtag_top.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/debug/uart_debug.v')
    # ../rtl/utils
    iverilog_cmd.append(rtl_dir + r'/rtl/utils/full_handshake_rx.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/utils/full_handshake_tx.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/utils/gen_buf.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/utils/gen_dff.v')

    # 编译
    process = subprocess.Popen(iverilog_cmd)
    process.wait(timeout=5)

if __name__ == '__main__':
    sys.exit(main())
