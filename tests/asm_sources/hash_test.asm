# RISC-V 哈希運算測試程式
# 功能：使用簡化哈希算法計算五個不同數值序列的哈希值
# 算法：hash = 331; for each data: hash = (hash * 3) + data, hash %= 10000, 確保非零
# 結果會存儲在記憶體 0x300 開始的位置
# 測試數據：{12, 34}, {56, 78, 90}, {11, 22, 33, 44}, {1, 2, 3, 4, 5}, {99, 88, 77, 66, 55, 44}

.text
main:
    # 初始化結果存儲地址
    addi x1, x0, 768        # x1 = 768 = 0x300 (結果儲存的基地址)
    
    # 測試1: 計算 {12, 34} 的哈希值
    addi x10, x0, 256       # x10 = 256 = 0x100 (資料起始地址)
    addi x2, x0, 12
    sw x2, 0(x10)           # data[0] = 12
    addi x2, x0, 34
    sw x2, 4(x10)           # data[1] = 34
    addi x3, x0, 2          # 資料長度 = 2
    jal x31, djb2_hash      # 呼叫哈希函數，結果在 x4
    sw x4, 0(x1)            # 儲存結果
    addi x1, x1, 4          # 移動指標
    
    # 測試2: 計算 {56, 78, 90} 的哈希值
    addi x10, x0, 256       # 重置資料地址
    addi x2, x0, 56
    sw x2, 0(x10)           # data[0] = 56
    addi x2, x0, 78
    sw x2, 4(x10)           # data[1] = 78
    addi x2, x0, 90
    sw x2, 8(x10)           # data[2] = 90
    addi x3, x0, 3          # 資料長度 = 3
    jal x31, djb2_hash      # 呼叫哈希函數
    sw x4, 0(x1)            # 儲存結果
    addi x1, x1, 4          # 移動指標
    
    # 測試3: 計算 {11, 22, 33, 44} 的哈希值
    addi x10, x0, 256       # 重置資料地址
    addi x2, x0, 11
    sw x2, 0(x10)           # data[0] = 11
    addi x2, x0, 22
    sw x2, 4(x10)           # data[1] = 22
    addi x2, x0, 33
    sw x2, 8(x10)           # data[2] = 33
    addi x2, x0, 44
    sw x2, 12(x10)          # data[3] = 44
    addi x3, x0, 4          # 資料長度 = 4
    jal x31, djb2_hash      # 呼叫哈希函數
    sw x4, 0(x1)            # 儲存結果
    addi x1, x1, 4          # 移動指標
    
    # 測試4: 計算 {1, 2, 3, 4, 5} 的哈希值
    addi x10, x0, 256       # 重置資料地址
    addi x2, x0, 1
    sw x2, 0(x10)           # data[0] = 1
    addi x2, x0, 2
    sw x2, 4(x10)           # data[1] = 2
    addi x2, x0, 3
    sw x2, 8(x10)           # data[2] = 3
    addi x2, x0, 4
    sw x2, 12(x10)          # data[3] = 4
    addi x2, x0, 5
    sw x2, 16(x10)          # data[4] = 5
    addi x3, x0, 5          # 資料長度 = 5
    jal x31, djb2_hash      # 呼叫哈希函數
    sw x4, 0(x1)            # 儲存結果
    addi x1, x1, 4          # 移動指標
    
    # 測試5: 計算 {99, 88, 77, 66, 55, 44} 的哈希值
    addi x10, x0, 256       # 重置資料地址
    addi x2, x0, 99
    sw x2, 0(x10)           # data[0] = 99
    addi x2, x0, 88
    sw x2, 4(x10)           # data[1] = 88
    addi x2, x0, 77
    sw x2, 8(x10)           # data[2] = 77
    addi x2, x0, 66
    sw x2, 12(x10)          # data[3] = 66
    addi x2, x0, 55
    sw x2, 16(x10)          # data[4] = 55
    addi x2, x0, 44
    sw x2, 20(x10)          # data[5] = 44
    addi x3, x0, 6          # 資料長度 = 6
    jal x31, djb2_hash      # 呼叫哈希函數
    sw x4, 0(x1)            # 儲存結果
    
    # 無限迴圈（程式結束）
end_loop:
    beq x0, x0, end_loop

# 簡化哈希算法函數
# 輸入：x10 = 資料陣列起始地址, x3 = 資料長度
# 輸出：x4 = 哈希值
# 算法：hash = 331; for each data: hash = (hash * 3) + data, hash %= 10000, 確保非零
djb2_hash:
    addi x4, x0, 331        # x4 = 331 (簡化初始值)
    add x5, x0, x0          # x5 = 0 (迴圈計數器)
    
hash_loop:
    beq x5, x3, hash_done   # if counter == length, 完成
    
    # 載入當前資料
    slli x6, x5, 2          # x6 = counter * 4 (字組偏移)
    add x7, x10, x6         # x7 = 基地址 + 偏移
    lw x8, 0(x7)            # x8 = data[counter]
    
    # 計算 hash = (hash * 3) + data (使用簡單的乘數)
    # 使用位移和加法: hash * 3 = hash * 2 + hash
    slli x9, x4, 1          # x9 = hash << 1 (hash * 2)
    add x9, x9, x4          # x9 = hash * 2 + hash = hash * 3
    add x4, x9, x8          # x4 = (hash * 3) + data
    
    # 簡單溢出處理：如果值太大，取模
    addi x9, x0, 10000      # x9 = 10000 (上限值)
    
overflow_loop:
    blt x4, x9, no_overflow # 如果 hash < 10000，完成
    sub x4, x4, x9          # hash = hash - 10000 (簡單模運算)
    beq x0, x0, overflow_loop # 繼續循環
    
no_overflow:
    # 確保非零（如果為0，設為1）
    bne x4, x0, non_zero    # 如果不為0，跳過
    addi x4, x0, 1          # 如果為0，設為1
non_zero:
    addi x5, x5, 1          # counter++
    beq x0, x0, hash_loop   # 繼續迴圈
    
hash_done:
    jalr x0, x31, 0         # 返回 