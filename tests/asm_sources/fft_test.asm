# RISC-V 簡化快速傅立葉變換（FFT）測試程式
# 功能：使用極簡化的DFT算法，重點在於測試CPU的運算能力
# 測試數據：三種4點信號（縮小規模以提高效率）
# 結果會存儲在記憶體 0x400 開始的位置

.text
main:
    # 初始化結果存儲地址
    addi x1, x0, 1024       # x1 = 1024 = 0x400 (DFT結果儲存的基地址)
    addi x2, x0, 1280       # x2 = 1280 = 0x500 (頻率分量儲存的基地址)
    
    # 測試1: 4點信號 [4, 0, -4, 0] (簡單正弦波)
    addi x10, x0, 512       # x10 = 512 = 0x200 (測試1信號資料地址)
    
    # 填入測試信號數據，增加更多防護延遲
    addi x3, x0, 4          # x3 = 4
    nop                     # 防止hazard
    nop                     # 防止hazard
    nop                     # 額外防護
    nop                     # 額外防護
    sw x3, 0(x10)           # data[0] = 4
    
    addi x3, x0, 0          # x3 = 0
    nop                     # 防止hazard
    nop                     # 防止hazard
    nop                     # 額外防護
    nop                     # 額外防護
    sw x3, 4(x10)           # data[1] = 0
    
    addi x3, x0, -4         # x3 = -4
    nop                     # 防止hazard
    nop                     # 防止hazard
    nop                     # 額外防護
    nop                     # 額外防護
    sw x3, 8(x10)           # data[2] = -4
    
    addi x3, x0, 0          # x3 = 0
    nop                     # 防止hazard
    nop                     # 防止hazard
    nop                     # 額外防護
    nop                     # 額外防護
    sw x3, 12(x10)          # data[3] = 0
    
    # 確保記憶體寫入完成再呼叫函數
    nop
    nop
    nop
    nop
    nop
    nop
    jal x31, simple_dft     # 呼叫簡化DFT計算函數
    
    # 測試2: 4點信號 [2, 2, -2, -2] (方波)
    addi x10, x0, 528       # x10 = 528 = 0x210 (測試2信號資料地址)
    
    # 填入測試信號數據，增加更多防護延遲
    addi x3, x0, 2          # x3 = 2
    nop                     # 防止hazard
    nop                     # 防止hazard
    nop                     # 額外防護
    nop                     # 額外防護
    sw x3, 0(x10)           # data[0] = 2
    
    # x3已經是2，直接使用
    nop                     # 防止hazard
    nop                     # 防止hazard
    nop                     # 額外防護
    nop                     # 額外防護
    sw x3, 4(x10)           # data[1] = 2
    
    addi x3, x0, -2         # x3 = -2
    nop                     # 防止hazard
    nop                     # 防止hazard
    nop                     # 額外防護
    nop                     # 額外防護
    sw x3, 8(x10)           # data[2] = -2
    
    # x3已經是-2，直接使用
    nop                     # 防止hazard
    nop                     # 防止hazard
    nop                     # 額外防護
    nop                     # 額外防護
    sw x3, 12(x10)          # data[3] = -2
    
    addi x1, x1, 16         # 移動到下一組結果位置 (4點*4字節=16)
    addi x2, x2, 16         # 移動到下一組頻率位置
    # 確保記憶體寫入完成再呼叫函數
    nop
    nop
    nop
    nop
    nop
    nop
    jal x31, simple_dft     # 呼叫簡化DFT計算函數
    
    # 測試3: 4點信號 [1, 2, 3, 4] (線性上升)
    addi x10, x0, 544       # x10 = 544 = 0x220 (測試3信號資料地址)
    
    # 填入測試信號數據，增加更多防護延遲
    addi x3, x0, 1          # x3 = 1
    nop                     # 防止hazard
    nop                     # 防止hazard
    nop                     # 額外防護
    nop                     # 額外防護
    sw x3, 0(x10)           # data[0] = 1
    
    addi x3, x0, 2          # x3 = 2
    nop                     # 防止hazard
    nop                     # 防止hazard
    nop                     # 額外防護
    nop                     # 額外防護
    sw x3, 4(x10)           # data[1] = 2
    
    addi x3, x0, 3          # x3 = 3
    nop                     # 防止hazard
    nop                     # 防止hazard
    nop                     # 額外防護
    nop                     # 額外防護
    sw x3, 8(x10)           # data[2] = 3
    
    addi x3, x0, 4          # x3 = 4
    nop                     # 防止hazard
    nop                     # 防止hazard
    nop                     # 額外防護
    nop                     # 額外防護
    sw x3, 12(x10)          # data[3] = 4
    
    addi x1, x1, 16         # 移動到下一組結果位置
    addi x2, x2, 16         # 移動到下一組頻率位置
    # 確保記憶體寫入完成再呼叫函數
    nop
    nop
    nop
    nop
    nop
    nop
    jal x31, simple_dft     # 呼叫簡化DFT計算函數
    
    # 無限迴圈（程式結束）
end_loop:
    beq x0, x0, end_loop

# 極簡化DFT計算函數（4點固定）
# 輸入：x10 = 信號資料起始地址, x1 = 結果存儲地址, x2 = 頻率分量地址
# 輸出：DFT結果存儲在指定記憶體位置
# 算法：只計算DC分量和基頻分量，避免複雜的三角函數計算
simple_dft:
    # 在load之前增加大量延遲確保記憶體寫入已完成
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    
    # 載入4個信號值，增加更多延遲
    lw x11, 0(x10)          # x11 = data[0]
    nop                     # load-use hazard防護
    nop
    nop
    nop
    lw x12, 4(x10)          # x12 = data[1]
    nop                     # load-use hazard防護
    nop
    nop
    nop
    lw x13, 8(x10)          # x13 = data[2]
    nop                     # load-use hazard防護
    nop
    nop
    nop
    lw x14, 12(x10)         # x14 = data[3]
    nop                     # load-use hazard防護
    nop
    nop
    nop
    
    # 計算並立即存儲DC分量 (頻率bin 0): sum of all samples
    add x15, x11, x12       # x11 + x12
    nop
    nop
    add x15, x15, x13       # + x13
    nop
    nop
    add x15, x15, x14       # + x14
    nop
    nop
    nop
    nop
    sw x15, 0(x1)           # 立即存儲DC分量
    nop
    nop
    nop
    nop
    mul x20, x15, x15       # 立即計算DC²
    nop
    nop
    nop
    nop
    sw x20, 0(x2)           # 立即存儲DC能量
    nop
    nop
    nop
    nop
    
    # 計算並立即存儲頻率bin 1: data[0] - data[2] (簡化的正弦分量)
    sub x16, x11, x13       # data[0] - data[2]
    nop
    nop
    nop
    nop
    sw x16, 4(x1)           # 立即存儲頻率bin 1
    nop
    nop
    nop
    nop
    mul x21, x16, x16       # 立即計算bin1²
    nop
    nop
    nop
    nop
    sw x21, 4(x2)           # 立即存儲bin1能量
    nop
    nop
    nop
    nop
    
    # 計算並立即存儲頻率bin 2: data[0] - data[1] + data[2] - data[3] (奈奎斯特頻率)
    sub x17, x11, x12       # data[0] - data[1]
    nop
    nop
    add x17, x17, x13       # + data[2]
    nop
    nop
    sub x17, x17, x14       # - data[3]
    nop
    nop
    nop
    nop
    sw x17, 8(x1)           # 立即存儲頻率bin 2
    nop
    nop
    nop
    nop
    mul x22, x17, x17       # 立即計算bin2²
    nop
    nop
    nop
    nop
    sw x22, 8(x2)           # 立即存儲bin2能量
    nop
    nop
    nop
    nop
    
    # 計算並立即存儲頻率bin 3: data[1] - data[3] (另一個簡化分量)
    sub x18, x12, x14       # data[1] - data[3]
    nop
    nop
    nop
    nop
    sw x18, 12(x1)          # 立即存儲頻率bin 3
    nop
    nop
    nop
    nop
    mul x23, x18, x18       # 立即計算bin3²
    nop
    nop
    nop
    nop
    sw x23, 12(x2)          # 立即存儲bin3能量
    nop
    nop
    nop
    nop
    
    # 直接返回（不使用堆疊）
    jalr x0, x31, 0         # 返回 