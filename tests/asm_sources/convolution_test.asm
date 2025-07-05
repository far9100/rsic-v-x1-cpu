# RISC-V 極簡測試 - 添加指令間隔避免複雜數據依賴
# 測試基本的 addi 和 sw 指令

_start:
    # 測試1: 簡單的立即數加法
    addi x1, x0, 5          # x1 = 5
    addi x2, x0, 512        # x2 = 0x200 (結果地址)
    addi x10, x0, 1         # x10 = 1 (間隔指令)
    sw x1, 0(x2)            # 儲存 5 到 result[0]
    
    # 測試2: 另一個立即數
    addi x3, x0, 10         # x3 = 10
    addi x11, x0, 2         # x11 = 2 (間隔指令)
    sw x3, 4(x2)            # 儲存 10 到 result[1]
    
    # 測試3: 簡單加法
    add x4, x1, x3          # x4 = x1 + x3 = 5 + 10 = 15
    addi x12, x0, 3         # x12 = 3 (間隔指令)
    sw x4, 8(x2)            # 儲存 15 到 result[2]
    
    # 測試4: 簡單減法  
    sub x5, x3, x1          # x5 = x3 - x1 = 10 - 5 = 5
    addi x13, x0, 4         # x13 = 4 (間隔指令)
    sw x5, 12(x2)           # 儲存 5 到 result[3]
    
    # 測試5: 常數42
    addi x6, x0, 42         # x6 = 42
    addi x14, x0, 5         # x14 = 5 (間隔指令)
    sw x6, 16(x2)           # 儲存 42 到 result[4]
    
    # 測試6: 負數
    addi x7, x0, -7         # x7 = -7
    addi x15, x0, 6         # x15 = 6 (間隔指令)
    sw x7, 20(x2)           # 儲存 -7 到 result[5]
    
    # 設置結束標記
    addi x8, x0, 1          # x8 = 1
    addi x9, x0, 768        # x9 = 0x300
    addi x16, x0, 7         # x16 = 7 (間隔指令)
    sw x8, 0(x9)            # 設置結束標記
    
    # 結束：無限循環
    beq x0, x0, _start 