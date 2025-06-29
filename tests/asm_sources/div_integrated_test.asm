# RISC-V 除法指令整合測試
# 測試 DIV, DIVU, REM, REMU 指令
# 檔案：tests/asm_sources/div_integrated_test.asm

.text
.global _start

_start:
    # 測試 1: 基本有符號除法 (DIV)
    # 計算 84 / 12 = 7
    addi x1, x0, 84
    addi x2, x0, 12
    div x3, x1, x2          # x3 = 84 / 12 = 7
    
    # 測試 2: 負數除法 (DIV)
    # 計算 -84 / 12 = -7
    addi x4, x0, -84
    addi x5, x0, 12
    div x6, x4, x5          # x6 = -84 / 12 = -7
    
    # 測試 3: 無符號除法 (DIVU)
    # 計算 100 / 4 = 25
    addi x7, x0, 100
    addi x8, x0, 4
    divu x9, x7, x8         # x9 = 100 / 4 = 25
    
    # 測試 4: 有符號餘數 (REM)
    # 計算 85 % 12 = 1
    addi x10, x0, 85
    addi x11, x0, 12
    rem x12, x10, x11       # x12 = 85 % 12 = 1
    
    # 測試 5: 負數餘數 (REM)
    # 計算 -85 % 12 = -1
    addi x13, x0, -85
    addi x14, x0, 12
    rem x15, x13, x14       # x15 = -85 % 12 = -1
    
    # 測試 6: 無符號餘數 (REMU)
    # 計算 87 % 13 = 9
    addi x16, x0, 87
    addi x17, x0, 13
    remu x18, x16, x17      # x18 = 87 % 13 = 9
    
    # 測試 7: 除零測試 (DIV)
    # 計算 10 / 0 = -1 (RISC-V 規範)
    addi x19, x0, 10
    addi x20, x0, 0
    div x21, x19, x20       # x21 = 10 / 0 = -1
    
    # 測試 8: 除零測試 (DIVU)
    # 計算 10 / 0 = 0xFFFFFFFF (RISC-V 規範)
    addi x22, x0, 10
    addi x23, x0, 0
    divu x24, x22, x23      # x24 = 10 / 0 = 0xFFFFFFFF
    
    # 測試 9: 溢出測試 (DIV)
    # 使用 ADDI 構造 -2^31
    addi x25, x0, -1        # x25 = -1 (0xFFFFFFFF)
    slli x25, x25, 31       # x25 = 0x80000000 (-2^31)
    addi x26, x0, -1
    div x27, x25, x26       # x27 = -2^31 / -1 = -2^31
    
    # 將結果儲存到記憶體（從位址 0x400 開始）
    addi x28, x0, 0x400
    sw x3, 0(x28)          # 儲存 x3 (7)
    sw x6, 4(x28)          # 儲存 x6 (-7)
    sw x9, 8(x28)          # 儲存 x9 (25)
    sw x12, 12(x28)        # 儲存 x12 (1)
    sw x15, 16(x28)        # 儲存 x15 (-1)
    sw x18, 20(x28)        # 儲存 x18 (9)
    sw x21, 24(x28)        # 儲存 x21 (-1)
    sw x24, 28(x28)        # 儲存 x24 (0xFFFFFFFF)
    sw x27, 32(x28)        # 儲存 x27 (-2^31)
    
    # 程式結束
    nop
    nop
    nop
    
    # 無限迴圈
loop:
    beq x0, x0, loop 