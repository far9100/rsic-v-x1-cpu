# RISC-V 32I CPU - 分支指令測試 (逐步測試 - 添加真實迴圈)
# 檔案：tests/asm_sources/branch_integrated_test.asm
# 目前測試：BEQ, BNE, BLT, BGE, BLTU, BGEU, 負數比較, 分支不採用, 簡化迴圈, 真實向後跳轉迴圈(使用負數立即數)
# 註解掉：JAL, JALR, 有符號vs無符號差異測試

.text
.globl _start

_start:
    # 初始化測試值
    addi x1, x0, 10      # x1 = 10
    addi x2, x0, 10      # x2 = 10 (相等)
    addi x3, x0, 5       # x3 = 5  (小於 x1)
    addi x4, x0, 15      # x4 = 15 (大於 x1)
    addi x5, x0, -5      # x5 = -5 (負數)
    addi x6, x0, 1       # x6 = 1  (結果暫存器，起始值1表示初始化完成)

# 測試 BEQ (Branch if Equal)
test_beq:
    beq x1, x2, beq_taken    # 應該跳轉，因為 x1 == x2
    addi x6, x6, 100         # 不應該執行 - 如果執行了，x6會+100表示BEQ失敗
    
beq_taken:
    addi x6, x6, 1           # x6 = 2，表示 BEQ 正確跳轉

# 測試 BNE (Branch if Not Equal)
test_bne:
    bne x1, x3, bne_taken    # 應該跳轉，因為 x1 != x3
    addi x6, x6, 200         # 不應該執行 - 如果執行了，x6會+200表示BNE失敗
    
bne_taken:
    addi x6, x6, 1           # x6 = 3，表示 BNE 正確跳轉

# 測試 BLT (Branch if Less Than, signed)
test_blt:
    blt x3, x1, blt_taken    # 應該跳轉，因為 5 < 10
    addi x6, x6, 300         # 不應該執行 - 如果執行了，x6會+300表示BLT失敗
    
blt_taken:
    addi x6, x6, 1           # x6 = 4，表示 BLT 正確跳轉

# 測試 BGE (Branch if Greater or Equal, signed)
test_bge:
    bge x1, x3, bge_taken    # 應該跳轉，因為 10 >= 5
    addi x6, x6, 400         # 不應該執行 - 如果執行了，x6會+400表示BGE失敗
    
bge_taken:
    addi x6, x6, 1           # x6 = 5，表示 BGE 正確跳轉

# 測試 BLTU (Branch if Less Than, unsigned)
test_bltu:
    bltu x3, x1, bltu_taken  # 應該跳轉，因為 5 < 10 (unsigned)
    addi x6, x6, 500         # 不應該執行 - 如果執行了，x6會+500表示BLTU失敗
    
bltu_taken:
    addi x6, x6, 1           # x6 = 6，表示 BLTU 正確跳轉

# 測試 BGEU (Branch if Greater or Equal, unsigned)
test_bgeu:
    bgeu x1, x3, bgeu_taken  # 應該跳轉，因為 10 >= 5 (unsigned)
    addi x6, x6, 600         # 不應該執行 - 如果執行了，x6會+600表示BGEU失敗
    
bgeu_taken:
    addi x6, x6, 1           # x6 = 7，表示 BGEU 正確跳轉

# 測試負數比較 (重要的邊界條件)
test_negative:
    blt x5, x0, neg_taken    # x5 (-5) < 0，應該跳轉
    addi x6, x6, 700         # 不應該執行 - 如果執行了，x6會+700表示負數比較失敗
    
neg_taken:
    addi x6, x6, 1           # x6 = 8，表示負數比較正確

# 測試分支不採用的情況
test_branch_not_taken:
    beq x1, x3, should_not_jump  # 不應該跳轉，因為 x1 != x3
    addi x6, x6, 1               # x6 = 9，表示分支正確不跳轉
    bne x1, x2, should_not_jump  # 不應該跳轉，因為 x1 == x2
    addi x6, x6, 1               # x6 = 10，表示分支正確不跳轉

# 測試零值比較
test_zero:
    beq x0, x0, zero_equal   # x0 == x0，應該跳轉
    addi x6, x6, 800         # 不應該執行 - 如果執行了表示零值比較失敗

zero_equal:
    addi x6, x6, 1           # x6 = 11

# 測試簡化的向後跳轉迴圈 (避免負數立即數) - 增強調試版本
test_simple_loop:
    # 調試點1：記錄迴圈前的x6值到x13
    add x13, x6, x0          # x13 = x6 (應該是11)
    
    addi x10, x0, 0          # x10 = 0 (迴圈計數器，從0開始)
    addi x11, x0, 3          # x11 = 3 (目標值)
    addi x12, x0, 0          # x12 = 0 (累加器)
    
simple_loop_start:
    addi x12, x12, 1         # x12++ (累加器遞增)
    addi x10, x10, 1         # x10++ (計數器遞增，避免使用負數)
    bne x10, x11, simple_loop_start  # 如果 x10 != 3，繼續迴圈
    
    # 調試點2：記錄迴圈後但add前的狀態到x14
    add x14, x6, x0          # x14 = x6 (應該還是11)
    
    # 迴圈結束，x12 應該 = 3
    add x6, x6, x12          # x6 = 11 + 3 = 14，表示簡化迴圈正確執行
    
    # 調試點3：記錄add後的x6值到x15
    add x15, x6, x0          # x15 = x6 (應該是14)
    
    # 添加調試標記
    addi x6, x6, 10          # x6 = 14 + 10 = 24，表示迴圈測試完成

# 測試真正的向後跳轉（迴圈）- 使用負數立即數
test_real_loop:
    # 調試點4：記錄真實迴圈前的x6值到x16
    add x16, x6, x0          # x16 = x6 (應該是24)
    
    addi x10, x0, 3          # x10 = 3 (迴圈計數器)
    addi x11, x0, 0          # x11 = 0 (累加器)
    
    # 調試點5：記錄迴圈初始化後的狀態到x17
    add x17, x10, x0         # x17 = x10 (應該是3)
    
loop_start:
    addi x11, x11, 1         # x11++ (累加器遞增)
    addi x10, x10, -1        # x10-- (計數器遞減，使用負數立即數)
    bne x10, x0, loop_start  # 如果 x10 != 0，向後跳轉繼續迴圈
    
    # 調試點6：記錄迴圈結束後的狀態到x18和x19
    add x18, x10, x0         # x18 = x10 (應該是0)
    add x19, x11, x0         # x19 = x11 (應該是3)
    
    # 迴圈結束，x11 應該 = 3
    add x6, x6, x11          # x6 = 24 + 3 = 27，表示真實迴圈正確執行
    
    # 添加調試標記
    addi x6, x6, 3           # x6 = 27 + 3 = 30，表示真實迴圈測試完成

# 程式結束
end_program:
    addi x6, x6, 70          # x6 = 30 + 70 = 100，最終預期結果
    
    # 停止程式（無限迴圈）
infinite_loop:
    beq x0, x0, infinite_loop

# 不應該到達的標籤
should_not_jump:
    addi x6, x6, 1000        # 如果執行到這裡，表示分支錯誤
    beq x0, x0, infinite_loop

# === 以下為註解掉的測試，待逐步添加 ===

# # 測試有符號vs無符號差異 (需要 LUI 指令)
# test_signed_unsigned_diff:
#     # 使用大的正數來測試有符號/無符號差異
#     lui x20, 0x80000         # x20 = 0x80000000 (最大負數 in signed, 大正數 in unsigned)
#     blt x20, x0, signed_neg  # 有符號：0x80000000 < 0 (true)
#     addi x6, x6, 1           # 不應該執行
#     
# signed_neg:
#     addi x6, x6, 5           # x6 = 70
#     
#     bltu x20, x0, unsigned_check # 無符號：0x80000000 < 0 (false)
#     addi x6, x6, 5               # 應該執行，x6 = 75

# unsigned_check:
#     addi x6, x6, 1000            # 如果執行，表示 BLTU 錯誤

# # 測試 JAL (Jump and Link)
# test_jal:
#     jal x7, jal_target       # 跳轉到 jal_target，x7 = return address
#     addi x6, x6, 1           # 不應該執行
#     
# jal_return:
#     addi x6, x6, 5           # x6 = 85，表示從 JAL 正確返回

# # 測試 JALR (Jump and Link Register) - 需要 AUIPC 指令
# test_jalr:
#     # 計算 jalr_target 的地址
#     auipc x8, 0              # x8 = 當前 PC
#     addi x8, x8, 12          # x8 = PC + 12 (指向 jalr_target)
#     jalr x9, x8, 0           # 跳轉到 x8 地址，x9 = return address
#     addi x6, x6, 1           # 不應該執行

# jalr_target:
#     addi x6, x6, 5           # x6 = 90，表示 JALR 正確跳轉
#     jalr x0, x9, 0           # 返回到 x9 地址

# jalr_return:
#     addi x6, x6, 5           # x6 = 95，表示 JALR 正確返回

# # JAL 目標
# jal_target:
#     addi x6, x6, 5           # x6 = 80，表示 JAL 正確跳轉
#     jalr x0, x7, 0           # 使用 x7 返回（JAL 保存的地址）

# # JAL 目標
# jal_target:
#     addi x6, x6, 5           # x6 = 80，表示 JAL 正確跳轉
#     jalr x0, x7, 0           # 使用 x7 返回（JAL 保存的地址） 