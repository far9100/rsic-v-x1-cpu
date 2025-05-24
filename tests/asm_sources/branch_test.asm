# RISC-V 32I CPU - 分支指令測試
# 檔案：tests/asm_sources/branch_test.asm
# 測試所有分支指令：BEQ, BNE, BLT, BGE, BLTU, BGEU
# 以及跳轉指令：JAL, JALR

.text
.globl _start

_start:
    # 初始化測試值
    addi x1, x0, 10      # x1 = 10
    addi x2, x0, 10      # x2 = 10 (相等)
    addi x3, x0, 5       # x3 = 5  (小於 x1)
    addi x4, x0, 15      # x4 = 15 (大於 x1)
    addi x5, x0, -5      # x5 = -5 (負數)
    addi x6, x0, 0       # x6 = 0  (結果暫存器)

# 測試 BEQ (Branch if Equal)
test_beq:
    beq x1, x2, beq_taken    # 應該跳轉，因為 x1 == x2
    addi x6, x6, 1           # 不應該執行
    
beq_taken:
    addi x6, x6, 10          # x6 = 10，表示 BEQ 正確跳轉

# 測試 BNE (Branch if Not Equal)
test_bne:
    bne x1, x3, bne_taken    # 應該跳轉，因為 x1 != x3
    addi x6, x6, 1           # 不應該執行
    
bne_taken:
    addi x6, x6, 10          # x6 = 20，表示 BNE 正確跳轉

# 測試 BLT (Branch if Less Than, signed)
test_blt:
    blt x3, x1, blt_taken    # 應該跳轉，因為 5 < 10
    addi x6, x6, 1           # 不應該執行
    
blt_taken:
    addi x6, x6, 10          # x6 = 30，表示 BLT 正確跳轉

# 測試 BGE (Branch if Greater or Equal, signed)
test_bge:
    bge x1, x3, bge_taken    # 應該跳轉，因為 10 >= 5
    addi x6, x6, 1           # 不應該執行
    
bge_taken:
    addi x6, x6, 10          # x6 = 40，表示 BGE 正確跳轉

# 測試 BLTU (Branch if Less Than, unsigned)
test_bltu:
    bltu x3, x1, bltu_taken  # 應該跳轉，因為 5 < 10 (unsigned)
    addi x6, x6, 1           # 不應該執行
    
bltu_taken:
    addi x6, x6, 10          # x6 = 50，表示 BLTU 正確跳轉

# 測試 BGEU (Branch if Greater or Equal, unsigned)
test_bgeu:
    bgeu x1, x3, bgeu_taken  # 應該跳轉，因為 10 >= 5 (unsigned)
    addi x6, x6, 1           # 不應該執行
    
bgeu_taken:
    addi x6, x6, 10          # x6 = 60，表示 BGEU 正確跳轉

# 測試 JAL (Jump and Link)
test_jal:
    jal x7, jal_target       # 跳轉到 jal_target，x7 = return address
    addi x6, x6, 1           # 不應該執行
    
jal_return:
    addi x6, x6, 10          # x6 = 80，表示從 JAL 返回

# 測試 JALR (Jump and Link Register)
test_jalr:
    addi x8, x0, jalr_target # x8 = jalr_target 的地址
    jalr x9, x8, 0           # 跳轉到 x8 指向的地址，x9 = return address
    addi x6, x6, 1           # 不應該執行
    
jalr_return:
    addi x6, x6, 10          # x6 = 100，表示從 JALR 返回

# 測試分支不採用的情況
test_branch_not_taken:
    beq x1, x3, should_not_jump  # 不應該跳轉，因為 x1 != x3
    addi x6, x6, 10              # x6 = 110，表示分支正確不跳轉
    bne x1, x2, should_not_jump  # 不應該跳轉，因為 x1 == x2
    addi x6, x6, 10              # x6 = 120，表示分支正確不跳轉

# 測試向後跳轉（迴圈）
test_loop:
    addi x10, x0, 3          # 迴圈計數器
    addi x11, x0, 0          # 迴圈累加器
    
loop_start:
    addi x11, x11, 1         # x11++
    addi x10, x10, -1        # x10--
    bne x10, x0, loop_start  # 如果 x10 != 0，繼續迴圈
    
    # 迴圈結束，x11 應該等於 3
    addi x6, x6, 10          # x6 = 130，表示迴圈正確執行

# 程式結束
end_program:
    addi x6, x6, 10          # x6 = 140，表示程式正常結束
    # 無限迴圈，停止程式
infinite_loop:
    beq x0, x0, infinite_loop

# JAL 目標
jal_target:
    addi x6, x6, 10          # x6 = 70，表示 JAL 正確跳轉
    jal x0, jal_return       # 返回（使用 x0 作為 link register）

# JALR 目標
jalr_target:
    addi x6, x6, 10          # x6 = 90，表示 JALR 正確跳轉
    jalr x0, x9, 0           # 返回到 x9 指向的地址

# 不應該到達的標籤
should_not_jump:
    addi x6, x6, 1000        # 如果執行到這裡，表示分支錯誤 