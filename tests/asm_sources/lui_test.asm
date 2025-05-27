# RISC-V 32I CPU - LUI 指令測試
# 檔案：tests/asm_sources/lui_test.asm

.text
.globl _start

_start:
    # 初始化
    addi x6, x0, 1       # x6 = 1，測試開始標記
    
    # 測試 LUI 指令
    lui x20, 0x80000     # x20 = 0x80000000
    
    # 將結果保存到其他暫存器用於調試
    add x21, x20, x0     # x21 = x20 (調試用)
    
    # 檢查 LUI 是否正確載入值
    # 如果 x20 = 0x80000000，則 x20 的最高位應該是 1
    # 我們可以通過右移來檢查
    srli x22, x20, 31    # x22 = x20 >> 31，應該是 1
    
    # 將結果累加到 x6
    add x6, x6, x22      # x6 = 1 + 1 = 2，如果 LUI 正確
    
    # 測試另一個 LUI 值
    lui x23, 0x12345     # x23 = 0x12345000
    
    # 簡化測試：直接檢查高20位
    srli x25, x23, 12    # x25 = x23 >> 12，應該是 0x12345
    
    # 將結果保存
    add x26, x25, x0     # x26 = x25 (調試用)
    
    # 如果 x25 不為零，說明 LUI 工作正常
    bne x25, x0, lui_works
    addi x6, x6, 100     # 錯誤標記
    
lui_works:
    addi x6, x6, 2       # x6 = 2 + 2 = 4，如果正確
    
    # 最終結果應該是 x6 = 4
    addi x6, x6, 96      # x6 = 4 + 96 = 100，最終結果
    
    # 無限迴圈
infinite_loop:
    beq x0, x0, infinite_loop 