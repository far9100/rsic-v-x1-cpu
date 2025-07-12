# RISC-V 氣泡排序測試程式 - 修復版本
# 檔案：tests/asm_sources/bubble_sort_test.asm

# 目的：實現完整的氣泡排序算法（10個元素）
# 測試數據：[9, 3, 7, 1, 5, 8, 2, 6, 4, 10]
# 預期結果：[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

.text
.globl _start
_start:
    # 設定記憶體基底位址（使用十進制避免立即值問題）
    addi x28, x0, 512    # 工作陣列基底位址 512 (0x200)
    addi x29, x0, 768    # 排序結果基底位址 768 (0x300)
    addi x30, x0, 1024   # 完成標記位址 1024 (0x400)
    
    # 增加 NOP 指令避免管線危險
    nop
    nop
    nop
    nop
    nop
    
    # 初始化陣列資料 [9, 3, 7, 1, 5, 8, 2, 6, 4, 10]
    addi x1, x0, 9       # x1 = 9
    addi x2, x0, 3       # x2 = 3
    addi x3, x0, 7       # x3 = 7
    addi x4, x0, 1       # x4 = 1
    addi x5, x0, 5       # x5 = 5
    addi x6, x0, 8       # x6 = 8
    addi x7, x0, 2       # x7 = 2
    addi x8, x0, 6       # x8 = 6
    addi x9, x0, 4       # x9 = 4
    addi x10, x0, 10     # x10 = 10
    
    # 增加 NOP 指令避免管線危險
    nop
    nop
    nop
    nop
    nop
    
    # 將初始資料儲存到記憶體 512（工作陣列）
    sw x1, 0(x28)        # mem[512] = 9
    nop
    nop
    sw x2, 4(x28)        # mem[516] = 3
    nop
    nop
    sw x3, 8(x28)        # mem[520] = 7
    nop
    nop
    sw x4, 12(x28)       # mem[524] = 1
    nop
    nop
    sw x5, 16(x28)       # mem[528] = 5
    nop
    nop
    sw x6, 20(x28)       # mem[532] = 8
    nop
    nop
    sw x7, 24(x28)       # mem[536] = 2
    nop
    nop
    sw x8, 28(x28)       # mem[540] = 6
    nop
    nop
    sw x9, 32(x28)       # mem[544] = 4
    nop
    nop
    sw x10, 36(x28)      # mem[548] = 10
    
    # 確保記憶體寫入完成
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
    
    # 氣泡排序算法實現
    # 外層循環：i = 0 to n-1 (x11 = i)
    # 內層循環：j = 0 to n-1-i (x12 = j)
    # 陣列大小 n = 10
    
    addi x11, x0, 0      # x11 = i = 0 (外層循環變數)
    addi x31, x0, 10     # x31 = n = 10 (陣列大小)
    
    # 增加 NOP 指令避免管線危險
    nop
    nop
    nop
    nop
    nop
    
outer_loop:
    # 外層循環條件：i < n
    bge x11, x31, sort_complete    # 如果 i >= n，跳出外層循環
    
    # 增加 NOP 指令避免分支後的管線危險
    nop
    nop
    nop
    nop
    nop
    
    addi x12, x0, 0      # x12 = j = 0 (內層循環變數)
    sub x13, x31, x11    # x13 = n - i
    addi x13, x13, -1    # x13 = n - i - 1 (內層循環上限)
    
    # 增加 NOP 指令避免管線危險
    nop
    nop
    nop
    nop
    nop
    
inner_loop:
    # 內層循環條件：j < n-i-1
    bge x12, x13, inner_loop_end   # 如果 j >= n-i-1，跳出內層循環
    
    # 增加 NOP 指令避免分支後的管線危險
    nop
    nop
    nop
    nop
    nop
    
    # 計算陣列元素位址
    slli x14, x12, 2     # x14 = j * 4 (字組偏移)
    add x15, x28, x14    # x15 = 基底位址 + j*4
    
    # 增加 NOP 指令避免位址計算危險
    nop
    nop
    nop
    nop
    nop
    
    # 載入 arr[j] 和 arr[j+1]
    lw x16, 0(x15)       # x16 = arr[j]
    nop
    nop
    nop
    nop
    nop
    lw x17, 4(x15)       # x17 = arr[j+1]
    nop
    nop
    nop
    nop
    nop
    
    # 比較 arr[j] 和 arr[j+1]
    blt x16, x17, no_swap          # 如果 arr[j] < arr[j+1]，不交換
    
    # 增加 NOP 指令避免分支後的管線危險
    nop
    nop
    nop
    nop
    nop
    
    # 交換 arr[j] 和 arr[j+1]
    sw x17, 0(x15)       # arr[j] = arr[j+1]
    nop
    nop
    nop
    nop
    nop
    sw x16, 4(x15)       # arr[j+1] = arr[j]
    nop
    nop
    nop
    nop
    nop
    
no_swap:
    # 增加 NOP 指令避免管線危險
    nop
    nop
    nop
    nop
    nop
    
    addi x12, x12, 1     # j++
    jal x0, inner_loop   # 繼續內層循環
    
inner_loop_end:
    # 增加 NOP 指令避免分支後的管線危險
    nop
    nop
    nop
    nop
    nop
    
    addi x11, x11, 1     # i++
    jal x0, outer_loop   # 繼續外層循環
    
sort_complete:
    # 確保排序完成
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
    
    # 將排序結果複製到結果陣列 768
    addi x18, x0, 0      # x18 = 複製計數器
    addi x19, x0, 10     # x19 = 元素總數
    
    # 增加 NOP 指令避免管線危險
    nop
    nop
    nop
    nop
    nop
    
copy_loop:
    bge x18, x19, copy_complete    # 如果已複製完所有元素
    
    # 增加 NOP 指令避免分支後的管線危險
    nop
    nop
    nop
    nop
    nop
    
    # 計算來源和目標位址
    slli x20, x18, 2     # x20 = i * 4
    add x21, x28, x20    # x21 = 來源位址 (512 + i*4)
    add x22, x29, x20    # x22 = 目標位址 (768 + i*4)
    
    # 增加 NOP 指令避免位址計算危險
    nop
    nop
    nop
    nop
    nop
    
    # 複製元素
    lw x23, 0(x21)       # 載入來源元素
    nop
    nop
    nop
    nop
    nop
    sw x23, 0(x22)       # 儲存到目標位址
    nop
    nop
    nop
    nop
    nop
    
    addi x18, x18, 1     # 計數器++
    jal x0, copy_loop    # 繼續複製
    
copy_complete:
    # 確保複製完成
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
    
    # 設定完成標記
    addi x24, x0, 1      # x24 = 1 (完成標記)
    sw x24, 0(x30)       # mem[1024] = 1
    
    # 增加 NOP 指令避免記憶體寫入危險
    nop
    nop
    nop
    nop
    nop
    
    # 結束程式，使用固定的循環次數
    addi x25, x0, 0      # x25 = 0 (計數器)
    addi x26, x0, 100    # x26 = 100 (循環限制)
    
    # 增加 NOP 指令避免管線危險
    nop
    nop
    nop
    nop
    nop
    
finish_loop:
    addi x25, x25, 1     # x25 = x25 + 1
    blt x25, x26, finish_loop  # 如果 x25 < 100，繼續循環
    
    # 100次循環後，程式自然結束
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

# 預期結果：
# 原始陣列: [9, 3, 7, 1, 5, 8, 2, 6, 4, 10] 儲存在 512-548
# 排序後陣列: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] 儲存在 768-804
# 完成標記: 1 儲存在 1024
# 
# 演算法說明：
# 1. 外層循環 (i): 控制排序輪數，共 n-1 輪
# 2. 內層循環 (j): 進行相鄰元素比較，每輪比較 n-i-1 次
# 3. 比較邏輯: 如果 arr[j] > arr[j+1]，則交換兩個元素
# 4. 每輪結束後，最大元素會"浮"到陣列末尾
# 5. n-1 輪後，整個陣列完成排序
# 
# 修復說明：
# 1. 將所有十六進制立即值改為十進制，避免組合器問題
# 2. 在所有記憶體操作後增加 NOP 指令，避免管線危險
# 3. 在所有分支操作後增加 NOP 指令，避免分支危險
# 4. 在位址計算後增加 NOP 指令，避免位址計算危險 