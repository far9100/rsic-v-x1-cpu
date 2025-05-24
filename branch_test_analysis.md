# 分支測試程式分析

## 初始化階段
```asm
addi x1, x0, 10      # x1 = 10
addi x2, x0, 10      # x2 = 10 (相等)
addi x3, x0, 5       # x3 = 5  (小於 x1)
addi x4, x0, 15      # x4 = 15 (大於 x1)
addi x5, x0, -5      # x5 = -5 (負數)
addi x6, x0, 0       # x6 = 0  (結果暫存器)
```

## 執行路徑分析

### 1. 測試 BEQ (Branch if Equal)
```asm
test_beq:
    beq x1, x2, beq_taken    # x1 (10) == x2 (10)，跳轉到 beq_taken
    addi x6, x6, 1           # 跳過，不執行
    
beq_taken:
    addi x6, x6, 10          # x6 = 0 + 10 = 10
```

### 2. 測試 BNE (Branch if Not Equal)
```asm
test_bne:
    bne x1, x3, bne_taken    # x1 (10) != x3 (5)，跳轉到 bne_taken
    addi x6, x6, 1           # 跳過，不執行
    
bne_taken:
    addi x6, x6, 10          # x6 = 10 + 10 = 20
```

### 3. 測試 BLT (Branch if Less Than, signed)
```asm
test_blt:
    blt x3, x1, blt_taken    # x3 (5) < x1 (10)，跳轉到 blt_taken
    addi x6, x6, 1           # 跳過，不執行
    
blt_taken:
    addi x6, x6, 10          # x6 = 20 + 10 = 30
```

### 4. 測試 BGE (Branch if Greater or Equal, signed)
```asm
test_bge:
    bge x1, x3, bge_taken    # x1 (10) >= x3 (5)，跳轉到 bge_taken
    addi x6, x6, 1           # 跳過，不執行
    
bge_taken:
    addi x6, x6, 10          # x6 = 30 + 10 = 40
```

### 5. 測試 BLTU (Branch if Less Than, unsigned)
```asm
test_bltu:
    bltu x3, x1, bltu_taken  # x3 (5) < x1 (10) (unsigned)，跳轉到 bltu_taken
    addi x6, x6, 1           # 跳過，不執行
    
bltu_taken:
    addi x6, x6, 10          # x6 = 40 + 10 = 50
```

### 6. 測試 BGEU (Branch if Greater or Equal, unsigned)
```asm
test_bgeu:
    bgeu x1, x3, bgeu_taken  # x1 (10) >= x3 (5) (unsigned)，跳轉到 bgeu_taken
    addi x6, x6, 1           # 跳過，不執行
    
bgeu_taken:
    addi x6, x6, 10          # x6 = 50 + 10 = 60
```

### 7. 測試 JAL (Jump and Link)
```asm
test_jal:
    jal x7, jal_target       # 跳轉到 jal_target，x7 = return address
    addi x6, x6, 1           # 跳過，不執行

jal_target:
    addi x6, x6, 10          # x6 = 60 + 10 = 70
    jal x0, jal_return       # 返回到 jal_return

jal_return:
    addi x6, x6, 10          # x6 = 70 + 10 = 80
```

### 8. 測試 JALR (Jump and Link Register)
**問題在這裡！**
```asm
test_jalr:
    addi x8, x0, jalr_target # 這裡有問題！
    jalr x9, x8, 0           # x8 需要是地址，但 jalr_target 是標籤
    addi x6, x6, 1           # 跳過，不執行

jalr_target:
    addi x6, x6, 10          # x6 = 80 + 10 = 90
    jalr x0, x9, 0           # 返回

jalr_return:
    addi x6, x6, 10          # x6 = 90 + 10 = 100
```

### 9. 測試分支不採用的情況
```asm
test_branch_not_taken:
    beq x1, x3, should_not_jump  # x1 (10) != x3 (5)，不跳轉
    addi x6, x6, 10              # 執行：x6 = 100 + 10 = 110
    bne x1, x2, should_not_jump  # x1 (10) == x2 (10)，不跳轉
    addi x6, x6, 10              # 執行：x6 = 110 + 10 = 120
```

### 10. 測試向後跳轉（迴圈）
```asm
test_loop:
    addi x10, x0, 3          # x10 = 3 (迴圈計數器)
    addi x11, x0, 0          # x11 = 0 (累加器)
    
loop_start:
    addi x11, x11, 1         # x11++
    addi x10, x10, -1        # x10--
    bne x10, x0, loop_start  # 如果 x10 != 0，繼續迴圈
    
    # 迴圈結束，x11 = 3
    addi x6, x6, 10          # x6 = 120 + 10 = 130
```

### 11. 程式結束
```asm
end_program:
    addi x6, x6, 10          # x6 = 130 + 10 = 140
```