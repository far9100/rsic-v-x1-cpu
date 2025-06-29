# RISC-V 階乘計算測試程式 (簡化版)
# 檔案：tests/asm_sources/factorial_test.asm

# 目的：測試階乘計算功能
# 本測試使用迴圈計算1到10的階乘：1!, 2!, 3!, 4!, 5!, 6!, 7!, 8!, 9!, 10!

.globl _start
_start:
    # 設定記憶體基底位址
    addi x28, x0, 512    # x28 = 0x200 = 512，記憶體基底位址
    
    # 設定主迴圈變數
    addi x1, x0, 1       # x1 = 當前計算的數字（從1開始）
    addi x2, x0, 10      # x2 = 最大計算到10
    addi x3, x0, 0       # x3 = 記憶體偏移量
    
    # 增加更多 NOP 以避免管線危害
    nop
    nop
    nop
    nop
    nop

# 主迴圈：計算每個數字的階乘
factorial_main_loop:
    # 初始化階乘計算變數
    addi x4, x0, 1       # x4 = 階乘結果（初始為1）
    addi x5, x0, 1       # x5 = 內部迴圈計數器（從1開始）
    
    # 增加 NOP 以避免管線危害
    nop
    nop
    nop
    nop
    nop
    
    # 內部迴圈：計算當前數字 x1 的階乘
factorial_inner_loop:
    # 檢查內部迴圈是否結束 (counter > current_number)
    blt x1, x5, factorial_inner_done
    
    # 增加 NOP 以避免分支後的管線危害
    nop
    nop
    nop
    
    # 計算階乘：result = result * counter
    mul x4, x4, x5       # x4 = x4 * x5
    
    # 增加更多 NOP 以處理乘法器延遲
    nop
    nop
    nop
    nop
    nop
    nop
    
    # 遞增內部迴圈計數器
    addi x5, x5, 1       # x5 = x5 + 1
    
    # 增加 NOP 以避免管線危害
    nop
    nop
    nop
    
    # 跳回內部迴圈開始
    beq x0, x0, factorial_inner_loop
    
factorial_inner_done:
    # 增加 NOP 以避免分支後的管線危害
    nop
    nop
    nop
    nop
    
    # 計算記憶體位址並儲存結果
    add x6, x28, x3      # x6 = 基底位址 + 偏移量
    
    # 增加 NOP 以避免位址計算危害
    nop
    nop
    nop
    
    sw x4, 0(x6)         # 儲存階乘結果
    
    # 增加 NOP 以處理記憶體寫入
    nop
    nop
    nop
    nop
    nop
    
    # 更新記憶體偏移量（每個整數佔4個位元組）
    addi x3, x3, 4       # x3 = x3 + 4
    
    # 遞增主迴圈計數器
    addi x1, x1, 1       # x1 = x1 + 1（下一個數字）
    
    # 增加 NOP 以避免管線危害
    nop
    nop
    nop
    
    # 檢查主迴圈是否結束 (如果 x1 <= x2，繼續迴圈)
    bge x2, x1, factorial_main_loop
    
    # 增加 NOP 以避免分支後的管線危害
    nop
    nop
    nop
    
    # 無限迴圈以停止處理器
halt_loop:
    beq x0, x0, halt_loop
    nop

# 預期結果：
# 記憶體位址 0x200 開始的連續位置應包含：
# 0x200: 1        (1!)
# 0x204: 2        (2!)
# 0x208: 6        (3!)
# 0x20C: 24       (4!)
# 0x210: 120      (5!)
# 0x214: 720      (6!)
# 0x218: 5040     (7!)
# 0x21C: 40320    (8!)
# 0x220: 362880   (9!)
# 0x224: 3628800  (10!) 