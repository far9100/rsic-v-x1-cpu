# RISC-V 分支指令整合測試程式
# 檔案：tests/asm_sources/branch_integrated_test.asm

# 目的：全面測試分支指令功能
# 本測試包含多個不同條件的分支測試案例
# 注意：所有測試使用1值表示成功，-1值表示失敗。

.globl _start
_start:
    # 初始化暫存器
    addi x1, x0, 0      # x1 = 0
    addi x2, x0, 10     # x2 = 10
    addi x3, x0, 10     # x3 = 10
    addi x4, x0, 5      # x4 = 5
    addi x5, x0, -5     # x5 = -5
    addi x6, x0, 7      # x6 = 7
    addi x28, x0, 0x100 # x28 = 0x100 (記憶體基底位址)
    addi x29, x0, 0     # x29 = 0 (用於儲存測試結果)
    
    # ============== 測試案例 1: BEQ (相等時分支) ==============
    # 測試 1.1: BEQ 成功案例 - x2 == x3 應分支
    addi x29, x0, -1     # 預設失敗標記
    beq x2, x3, beq_pass_1
    # 若分支未採取，此處會被執行
    jal x0, beq_fail_1
beq_pass_1:
    addi x29, x0, 1     # 成功標記
beq_fail_1:
    sw x29, 0(x28)      # 儲存結果 (x29 應為 1 表示成功)
    
    # 測試 1.2: BEQ 失敗案例 - x2 != x4 不應分支
    addi x29, x0, 1     # 預設成功標記
    beq x2, x4, beq_fail_2
    # 若分支未採取，此處會被執行，這是正確的
    jal x0, beq_pass_2
beq_fail_2:
    addi x29, x0, -1     # 失敗標記
beq_pass_2:
    sw x29, 4(x28)      # 儲存結果 (x29 應為 1 表示成功)
    
    # ============== 測試案例 2: BNE (不相等時分支) ==============
    # 測試 2.1: BNE 成功案例 - x2 != x4 應分支
    addi x29, x0, -1     # 預設失敗標記
    bne x2, x4, bne_pass_1
    # 若分支未採取，此處會被執行
    jal x0, bne_fail_1
bne_pass_1:
    addi x29, x0, 1     # 成功標記
bne_fail_1:
    sw x29, 8(x28)      # 儲存結果 (x29 應為 1 表示成功)
    
    # 測試 2.2: BNE 失敗案例 - x2 == x3 不應分支
    addi x29, x0, 1     # 預設成功標記
    bne x2, x3, bne_fail_2
    # 若分支未採取，此處會被執行（期望的結果）
    jal x0, bne_pass_2
bne_fail_2:
    addi x29, x0, -1     # 失敗標記
bne_pass_2:
    sw x29, 12(x28)     # 儲存結果 (x29 應為 1 表示成功)
    
    # ============== 測試案例 3: BLT (小於時分支) ==============
    # 測試 3.1: BLT 成功案例 - x4 < x2 應分支
    addi x29, x0, -1     # 預設失敗標記
    blt x4, x2, blt_pass_1
    # 若分支未採取，此處會被執行
    jal x0, blt_fail_1
blt_pass_1:
    addi x29, x0, 1     # 成功標記
blt_fail_1:
    sw x29, 16(x28)     # 儲存結果 (x29 應為 1 表示成功)
    
    # 測試 3.2: BLT 失敗案例 - x2 == x3 不應分支
    addi x29, x0, 1     # 預設成功標記
    blt x2, x3, blt_fail_2
    # 若分支未採取，此處會被執行（期望的結果）
    jal x0, blt_pass_2
blt_fail_2:
    addi x29, x0, -1     # 失敗標記
blt_pass_2:
    sw x29, 20(x28)     # 儲存結果 (x29 應為 1 表示成功)
    
    # ============== 測試案例 4: BGE (大於或等於時分支) ==============
    # 測試 4.1: BGE 成功案例 - x2 > x4 應分支
    addi x29, x0, -1     # 預設失敗標記
    bge x2, x4, bge_pass_1
    # 若分支未採取，此處會被執行
    jal x0, bge_fail_1
bge_pass_1:
    addi x29, x0, 1     # 成功標記
bge_fail_1:
    sw x29, 24(x28)     # 儲存結果 (x29 應為 1 表示成功)
    
    # 測試 4.2: BGE 成功案例 - x2 == x3 應分支
    addi x29, x0, -1     # 預設失敗標記
    bge x2, x3, bge_pass_2
    # 若分支未採取，此處會被執行
    jal x0, bge_fail_2
bge_pass_2:
    addi x29, x0, 1     # 成功標記
bge_fail_2:
    sw x29, 28(x28)     # 儲存結果 (x29 應為 1 表示成功)
    
    # ============== 測試案例 5: BLTU (無符號小於時分支) ==============
    # 測試 5.1: BLTU 成功案例 - x1(0) < x6(7) 應分支
    addi x29, x0, -1     # 預設失敗標記
    bltu x1, x6, bltu_pass_1
    # 若分支未採取，此處會被執行
    jal x0, bltu_fail_1
bltu_pass_1:
    addi x29, x0, 1     # 成功標記
bltu_fail_1:
    sw x29, 32(x28)     # 儲存結果 (x29 應為 1 表示成功)
    
    # 測試 5.2: BLTU 特殊案例 - x5(-5) > x6(7) 在無符號比較下應不分支 (-5 被解釋為大的無符號數)
    addi x29, x0, 1     # 預設成功標記
    bltu x5, x6, bltu_fail_2
    # 若分支未採取，此處會被執行（期望的結果）
    jal x0, bltu_pass_2
bltu_fail_2:
    addi x29, x0, -1     # 失敗標記
bltu_pass_2:
    sw x29, 36(x28)     # 儲存結果 (x29 應為 1 表示成功)
    
    # ============== 測試案例 6: BGEU (無符號大於或等於時分支) ==============
    # 測試 6.1: BGEU 成功案例 - x6(7) > x1(0) 應分支
    addi x29, x0, -1     # 預設失敗標記
    bgeu x6, x1, bgeu_pass_1
    # 若分支未採取，此處會被執行
    jal x0, bgeu_fail_1
bgeu_pass_1:
    addi x29, x0, 1     # 成功標記
bgeu_fail_1:
    sw x29, 40(x28)     # 儲存結果 (x29 應為 1 表示成功)
    
    # 測試 6.2: BGEU 特殊案例 - x5(-5) > x2(10) 在無符號比較下應分支 (-5 被解釋為大的無符號數)
    addi x29, x0, -1     # 預設失敗標記
    bgeu x5, x2, bgeu_pass_2
    # 若分支未採取，此處會被執行
    jal x0, bgeu_fail_2
bgeu_pass_2:
    addi x29, x0, 1     # 成功標記
bgeu_fail_2:
    sw x29, 44(x28)     # 儲存結果 (x29 應為 1 表示成功)
    
    # ============== 測試案例 7: 後向分支 (向後跳躍) ==============
    addi x7, x0, 3      # x7 = 3 (迴圈計數器)
    addi x8, x0, 0      # x8 = 0 (迴圈累加結果)
backward_loop:
    addi x8, x8, 1      # x8 = x8 + 1
    addi x7, x7, -1     # x7 = x7 - 1
    bne x7, x0, backward_loop # 若 x7 != 0，繼續迴圈
    
    addi x8, x0, 1      # 設置x8為1表示成功
    sw x8, 48(x28)      # 儲存結果 (x8 應為 1，表示成功)
    
    # ============== 測試完成 ==============
    # 無限迴圈以停止處理器供觀察
halt_loop:
    beq x0, x0, halt_loop # 分支到自身（實質上為停止）
    nop                    # 不應該執行到這裡

# 預期結果：
# 記憶體位址 0x100 應包含值 1 (BEQ 成功測試)
# 記憶體位址 0x104 應包含值 1 (BEQ 失敗測試)
# 記憶體位址 0x108 應包含值 1 (BNE 成功測試)
# 記憶體位址 0x10C 應包含值 1 (BNE 失敗測試)
# 記憶體位址 0x110 應包含值 1 (BLT 成功測試)
# 記憶體位址 0x114 應包含值 1 (BLT 失敗測試)
# 記憶體位址 0x118 應包含值 1 (BGE 成功測試)
# 記憶體位址 0x11C 應包含值 1 (BGE 成功測試 - 相等情況)
# 記憶體位址 0x120 應包含值 1 (BLTU 成功測試)
# 記憶體位址 0x124 應包含值 1 (BLTU 特殊測試 - 負數比較)
# 記憶體位址 0x128 應包含值 1 (BGEU 成功測試)
# 記憶體位址 0x12C 應包含值 1 (BGEU 特殊測試 - 負數比較)
# 記憶體位址 0x130 應包含值 1 (後向分支測試 - 迴圈成功) 