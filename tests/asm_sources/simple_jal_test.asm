# RISC-V 32I CPU - 簡單 JAL 指令測試
# 檔案：tests/asm_sources/simple_jal_test.asm

.text
.globl _start

_start:
    # 初始化
    addi x6, x0, 10      # x6 = 10，測試開始標記
    
    # 測試 JAL 指令
    jal x7, jal_target   # 跳轉到 jal_target，x7 = return address (下一條指令地址)
    
jal_return:
    addi x6, x6, 5       # x6 = 20，表示從 JAL 正確返回
    
    # 程式結束
    beq x0, x0, end_program

# JAL 目標
jal_target:
    addi x6, x6, 5       # x6 = 15，表示 JAL 正確跳轉
    jalr x0, x7, 0       # 使用 x7 返回（JAL 保存的地址）

# 程式結束
end_program:
    # 停止程式（無限迴圈）
    beq x0, x0, end_program 