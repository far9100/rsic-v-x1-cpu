# RISC-V 埃拉托色尼篩法測試程式
# 功能：使用埃拉托色尼篩法計算五個二位數以內的質數個數
# 結果會存儲在記憶體 0x200 開始的位置
# 測試數據：15, 25, 35, 50, 70
# 預期結果：6, 9, 11, 15, 19

.text
main:
    # 初始化結果存儲地址
    addi x1, x0, 512        # x1 = 512 = 0x200 (結果儲存的基地址)
    
    # 測試1: 計算 15 以內的質數個數 (2,3,5,7,11,13 = 6個)
    addi x2, x0, 15         # n = 15
    jal x31, sieve_count    # 呼叫篩法函數，結果在 x3
    sw x3, 0(x1)            # 儲存結果
    addi x1, x1, 4          # 移動指標
    
    # 測試2: 計算 25 以內的質數個數 (2,3,5,7,11,13,17,19,23 = 9個)
    addi x2, x0, 25         # n = 25
    jal x31, sieve_count    # 呼叫篩法函數
    sw x3, 0(x1)            # 儲存結果
    addi x1, x1, 4          # 移動指標
    
    # 測試3: 計算 35 以內的質數個數 (增加29,31 = 11個)
    addi x2, x0, 35         # n = 35
    jal x31, sieve_count    # 呼叫篩法函數
    sw x3, 0(x1)            # 儲存結果
    addi x1, x1, 4          # 移動指標
    
    # 測試4: 計算 50 以內的質數個數 (增加37,41,43,47 = 15個)
    addi x2, x0, 50         # n = 50
    jal x31, sieve_count    # 呼叫篩法函數
    sw x3, 0(x1)            # 儲存結果
    addi x1, x1, 4          # 移動指標
    
    # 測試5: 計算 70 以內的質數個數 (增加53,59,61,67 = 19個)
    addi x2, x0, 70         # n = 70
    jal x31, sieve_count    # 呼叫篩法函數
    sw x3, 0(x1)            # 儲存結果
    
    # 無限迴圈（程式結束）
end_loop:
    beq x0, x0, end_loop

# 簡化的質數計算函數 (使用試除法，更適合小範圍)
# 輸入：x2 = n (計算範圍)
# 輸出：x3 = 質數個數
sieve_count:
    add x3, x0, x0          # x3 = 0 (質數計數器)
    addi x4, x0, 2          # x4 = 2 (當前檢查的數字)
    
outer_loop:
    blt x2, x4, count_done  # if n < current, 計算完成
    
    # 檢查 x4 是否為質數
    addi x5, x0, 1          # x5 = 1 (假設是質數)
    addi x6, x0, 2          # x6 = 2 (除數從2開始)
    
check_prime:
    mul x7, x6, x6          # x7 = x6 * x6 (除數的平方)
    blt x4, x7, is_prime    # if current < divisor^2, 是質數
    
    # 檢查能否被 x6 整除
    add x8, x0, x0          # x8 = 0 (餘數)
    add x9, x4, x0          # x9 = 被除數
div_loop:
    blt x9, x6, check_remainder # if 被除數 < 除數, 檢查餘數
    sub x9, x9, x6              # 被除數 -= 除數
    beq x0, x0, div_loop        # 繼續除法
    
check_remainder:
    bne x9, x0, next_divisor    # if 餘數 != 0, 檢查下一個除數
    add x5, x0, x0              # x5 = 0 (不是質數)
    beq x0, x0, not_prime       # 跳出質數檢查
    
next_divisor:
    addi x6, x6, 1              # 除數 + 1
    beq x0, x0, check_prime     # 繼續檢查
    
is_prime:
    addi x3, x3, 1          # 質數計數器 + 1
    
not_prime:
    addi x4, x4, 1          # 當前數字 + 1
    beq x0, x0, outer_loop  # 繼續外層迴圈
    
count_done:
    jalr x0, x31, 0         # 返回 