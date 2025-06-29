# RISC-V 輾轉相除法測試程式
# 功能：使用輾轉相除法計算五對數字的最大公因數
# 結果會存儲在記憶體 0x200 開始的位置

# 測試資料對（100以內）：
# GCD(12, 8) = 4
# GCD(48, 18) = 6
# GCD(35, 21) = 7
# GCD(60, 45) = 15
# GCD(17, 13) = 1

.text
main:
    # 初始化暫存器
    addi x1, x0, 0          # x1 = 0 (索引)
    addi x2, x0, 512        # x2 = 512 = 0x200 (結果儲存的基地址，記憶體位址)
    
    # 測試對1: GCD(12, 8) = 4
    addi x3, x0, 12         # a = 12
    addi x4, x0, 8          # b = 8
    jal x31, gcd            # 呼叫 gcd 函數，結果在 x5
    sw x5, 0(x2)            # 儲存結果
    addi x2, x2, 4          # 移動指標
    
    # 測試對2: GCD(48, 18) = 6
    addi x3, x0, 48         # a = 48
    addi x4, x0, 18         # b = 18
    jal x31, gcd            # 呼叫 gcd 函數
    sw x5, 0(x2)            # 儲存結果
    addi x2, x2, 4          # 移動指標
    
    # 測試對3: GCD(35, 21) = 7
    addi x3, x0, 35         # a = 35
    addi x4, x0, 21         # b = 21
    jal x31, gcd            # 呼叫 gcd 函數
    sw x5, 0(x2)            # 儲存結果
    addi x2, x2, 4          # 移動指標
    
    # 測試對4: GCD(60, 45) = 15
    addi x3, x0, 60         # a = 60
    addi x4, x0, 45         # b = 45
    jal x31, gcd            # 呼叫 gcd 函數
    sw x5, 0(x2)            # 儲存結果
    addi x2, x2, 4          # 移動指標
    
    # 測試對5: GCD(17, 13) = 1
    addi x3, x0, 17         # a = 17
    addi x4, x0, 13         # b = 13
    jal x31, gcd            # 呼叫 gcd 函數
    sw x5, 0(x2)            # 儲存結果
    
    # 無限迴圈（程式結束）
end_loop:
    beq x0, x0, end_loop    # 無限迴圈

# 簡化的輾轉相除法函數
# 輸入：x3 = a, x4 = b
# 輸出：x5 = gcd(a, b)
# 使用暫存器：x6 (temp), x7 (remainder)
gcd:
    # 如果 b == 0，則返回 a
    beq x4, x0, gcd_return  # if b == 0, return a
    
gcd_loop:
    # 確保 a >= b，如果不是則交換
    blt x3, x4, swap_ab
    
    # 計算 a % b 使用簡化減法（最多進行有限次數）
    add x7, x3, x0          # remainder = a
    addi x6, x0, 100        # 設置迴圈次數限制（適應較大數字）
    
remainder_loop:
    beq x6, x0, remainder_done  # 如果達到迴圈限制，跳出
    blt x7, x4, remainder_done  # if remainder < b, done
    sub x7, x7, x4              # remainder = remainder - b
    addi x6, x6, -1             # 減少迴圈計數器
    beq x0, x0, remainder_loop  # continue loop
    
remainder_done:
    # 現在 x7 = a % b
    add x3, x4, x0          # a = b (新的a是舊的b)
    add x4, x7, x0          # b = remainder (新的b是餘數)
    
    bne x4, x0, gcd_loop    # if b != 0, continue
    beq x0, x0, gcd_return  # 跳到返回
    
swap_ab:
    # 交換 a 和 b
    add x6, x3, x0          # temp = a
    add x3, x4, x0          # a = b
    add x4, x6, x0          # b = temp
    beq x0, x0, gcd_loop    # 返回主迴圈
    
gcd_return:
    add x5, x3, x0          # return value = a
    jalr x0, x31, 0         # return 