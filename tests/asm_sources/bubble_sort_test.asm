# RISC-V 氣泡排序測試程式 - 真正的氣泡排序實現
# 檔案：tests/asm_sources/bubble_sort_test.asm

# 目的：實現完整的氣泡排序算法（10個元素）
# 測試數據：[9, 3, 7, 1, 5, 8, 2, 6, 4, 10]
# 預期結果：[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

.text
.globl _start
_start:
    # 設定記憶體基底位址
    addi x28, x0, 0x200  # 工作陣列基底位址 0x200
    addi x29, x0, 0x300  # 排序結果基底位址 0x300
    addi x30, x0, 0x400  # 完成標記位址 0x400
    
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
    
    # 將初始資料儲存到記憶體 0x200（工作陣列）
    sw x1, 0(x28)        # mem[0x200] = 9
    sw x2, 4(x28)        # mem[0x204] = 3
    sw x3, 8(x28)        # mem[0x208] = 7
    sw x4, 12(x28)       # mem[0x20C] = 1
    sw x5, 16(x28)       # mem[0x210] = 5
    sw x6, 20(x28)       # mem[0x214] = 8
    sw x7, 24(x28)       # mem[0x218] = 2
    sw x8, 28(x28)       # mem[0x21C] = 6
    sw x9, 32(x28)       # mem[0x220] = 4
    sw x10, 36(x28)      # mem[0x224] = 10
    
    # 氣泡排序算法實現
    # 外層循環：i = 0 to n-1 (x11 = i)
    # 內層循環：j = 0 to n-1-i (x12 = j)
    # 陣列大小 n = 10
    
    addi x11, x0, 0      # x11 = i = 0 (外層循環變數)
    addi x31, x0, 10     # x31 = n = 10 (陣列大小)
    
outer_loop:
    # 外層循環條件：i < n
    bge x11, x31, sort_complete    # 如果 i >= n，跳出外層循環
    
    addi x12, x0, 0      # x12 = j = 0 (內層循環變數)
    sub x13, x31, x11    # x13 = n - i
    addi x13, x13, -1    # x13 = n - i - 1 (內層循環上限)
    
inner_loop:
    # 內層循環條件：j < n-i-1
    bge x12, x13, inner_loop_end   # 如果 j >= n-i-1，跳出內層循環
    
    # 計算陣列元素位址
    slli x14, x12, 2     # x14 = j * 4 (字組偏移)
    add x15, x28, x14    # x15 = 基底位址 + j*4
    
    # 載入 arr[j] 和 arr[j+1]
    lw x16, 0(x15)       # x16 = arr[j]
    lw x17, 4(x15)       # x17 = arr[j+1]
    
    # 比較 arr[j] 和 arr[j+1]
    blt x16, x17, no_swap          # 如果 arr[j] < arr[j+1]，不交換
    
    # 交換 arr[j] 和 arr[j+1]
    sw x17, 0(x15)       # arr[j] = arr[j+1]
    sw x16, 4(x15)       # arr[j+1] = arr[j]
    
no_swap:
    addi x12, x12, 1     # j++
    jal x0, inner_loop   # 繼續內層循環
    
inner_loop_end:
    addi x11, x11, 1     # i++
    jal x0, outer_loop   # 繼續外層循環
    
sort_complete:
    # 將排序結果複製到結果陣列 0x300
    addi x18, x0, 0      # x18 = 複製計數器
    addi x19, x0, 10     # x19 = 元素總數
    
copy_loop:
    bge x18, x19, copy_complete    # 如果已複製完所有元素
    
    # 計算來源和目標位址
    slli x20, x18, 2     # x20 = i * 4
    add x21, x28, x20    # x21 = 來源位址 (0x200 + i*4)
    add x22, x29, x20    # x22 = 目標位址 (0x300 + i*4)
    
    # 複製元素
    lw x23, 0(x21)       # 載入來源元素
    sw x23, 0(x22)       # 儲存到目標位址
    
    addi x18, x18, 1     # 計數器++
    jal x0, copy_loop    # 繼續複製
    
copy_complete:
    # 設定完成標記
    addi x24, x0, 1      # x24 = 1 (完成標記)
    sw x24, 0(x30)       # mem[0x400] = 1
    
    # 結束程式，使用固定的循環次數
    addi x25, x0, 0      # x25 = 0 (計數器)
    addi x26, x0, 100    # x26 = 100 (循環限制)
    
finish_loop:
    addi x25, x25, 1     # x25 = x25 + 1
    blt x25, x26, finish_loop  # 如果 x25 < 100，繼續循環
    
    # 100次循環後，程式自然結束
    nop
    nop
    nop

# 預期結果：
# 原始陣列: [9, 3, 7, 1, 5, 8, 2, 6, 4, 10] 儲存在 0x200-0x224
# 排序後陣列: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] 儲存在 0x300-0x324
# 完成標記: 1 儲存在 0x400
# 
# 演算法說明：
# 1. 外層循環 (i): 控制排序輪數，共 n-1 輪
# 2. 內層循環 (j): 進行相鄰元素比較，每輪比較 n-i-1 次
# 3. 比較邏輯: 如果 arr[j] > arr[j+1]，則交換兩個元素
# 4. 每輪結束後，最大元素會"浮"到陣列末尾
# 5. n-1 輪後，整個陣列完成排序 