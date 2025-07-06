# RISC-V 逻辑指令整合測試程式
# 檔案：tests/asm_sources/logic_integrated_test.asm

# 目的：全面測試逻辑指令功能
# 本測試包含 AND, OR, XOR, ANDI, ORI, XORI 指令的各種測試案例

.globl _start
_start:
    # 初始化測試資料
    addi x1, x0, 0x0F0      # x1 = 0x0F0 (240)
    addi x2, x0, 0x00FF     # x2 = 0x00FF (255)
    addi x3, x0, -1         # x3 = 0xFFFFFFFF (-1)
    addi x4, x0, 0x5A5      # x4 = 0x5A5 (1445)
    
    # 插入 NOP 指令以處理管線資料危害
    nop
    nop
    nop
    
    # 測試案例 1：AND 指令 - 0x0F0 & 0x00FF = 0x0F0 (240)
    and x5, x1, x2          # x5 = x1 & x2 (0x0F0 & 0x00FF = 0x0F0)
    
    # 測試案例 2：OR 指令 - 0x0F0 | 0x00FF = 0x0FF (255)
    or x6, x1, x2           # x6 = x1 | x2 (0x0F0 | 0x00FF = 0x0FF)
    
    # 測試案例 3：XOR 指令 - 0x0F0 ^ 0x00FF = 0x00F (15)
    xor x7, x1, x2          # x7 = x1 ^ x2 (0x0F0 ^ 0x00FF = 0x00F)
    
    # 測試案例 4：ANDI 指令 - 0x5A5 & 0x0F0 = 0x0A0 (160)
    andi x8, x4, 0x0F0      # x8 = x4 & 0x0F0 (0x5A5 & 0x0F0 = 0x0A0)
    
    # 測試案例 5：ORI 指令 - 0x5A5 | 0x0F0 = 0x5F5 (1525)
    ori x9, x4, 0x0F0       # x9 = x4 | 0x0F0 (0x5A5 | 0x0F0 = 0x5F5)
    
    # 測試案例 6：XORI 指令 - 0x5A5 ^ 0x0F0 = 0x555 (1365)
    xori x10, x4, 0x0F0     # x10 = x4 ^ 0x0F0 (0x5A5 ^ 0x0F0 = 0x555)
    
    # 測試案例 7：全零測試 - 0x0000 & 0xFFFF = 0x0000 (0)
    addi x11, x0, 0         # x11 = 0
    and x12, x11, x3        # x12 = 0 & 0xFFFFFFFF = 0
    
    # 測試案例 8：全一測試 - 0xFFFF | 0x0000 = 0xFFFF (-1)
    or x13, x3, x11         # x13 = 0xFFFFFFFF | 0 = 0xFFFFFFFF
    
    # 測試案例 9：自反測試 - 0xFFFF ^ 0xFFFF = 0x0000 (0)
    xor x14, x3, x3         # x14 = 0xFFFFFFFF ^ 0xFFFFFFFF = 0
    
    # 測試案例 10：負數立即數測試 - ANDI with negative immediate
    andi x15, x3, -256      # x15 = 0xFFFFFFFF & 0xFF00 = 0xFF00 (-256)
    
    # 測試案例 11：ORI with small immediate
    ori x16, x0, 0x00AA     # x16 = 0 | 0xAA = 0xAA (170)
    
    # 測試案例 12：XORI with all bits set
    xori x17, x0, -1        # x17 = 0 ^ 0xFFFFFFFF = 0xFFFFFFFF (-1)
    
    # 設定記憶體基底位址
    addi x28, x0, 0x100     # 設定記憶體基底位址 0x100
    
    # 插入 NOP 指令以處理管線資料危害
    nop
    nop
    nop
    
    # 將結果儲存到記憶體中以供驗證
    sw x5, 0(x28)           # 儲存 AND 結果 (15)
    sw x6, 4(x28)           # 儲存 OR 結果 (4095)
    sw x7, 8(x28)           # 儲存 XOR 結果 (4080)
    sw x8, 12(x28)          # 儲存 ANDI 結果 (2570)
    sw x9, 16(x28)          # 儲存 ORI 結果 (24415)
    sw x10, 20(x28)         # 儲存 XORI 結果 (21845)
    
    nop
    nop
    nop
    
    sw x12, 24(x28)         # 儲存 全零AND 結果 (0)
    sw x13, 28(x28)         # 儲存 全一OR 結果 (-1)
    sw x14, 32(x28)         # 儲存 自反XOR 結果 (0)
    sw x15, 36(x28)         # 儲存 負數ANDI 結果 (-256)
    sw x16, 40(x28)         # 儲存 ORI小立即數 結果 (170)
    sw x17, 44(x28)         # 儲存 XORI全位元 結果 (-1)
    
    # 無限迴圈以停止處理器供觀察
halt_loop:
    beq x0, x0, halt_loop   # 分支到自身（實質上為停止）
    nop                     # 不應該執行到這裡

# 預期結果：
# 暫存器 x5  應包含值 240    (0x0F0)   - AND 結果
# 暫存器 x6  應包含值 255    (0x0FF)   - OR 結果
# 暫存器 x7  應包含值 15     (0x00F)   - XOR 結果
# 暫存器 x8  應包含值 160    (0x0A0)   - ANDI 結果
# 暫存器 x9  應包含值 1525   (0x5F5)   - ORI 結果
# 暫存器 x10 應包含值 1365   (0x555)   - XORI 結果
# 暫存器 x12 應包含值 0      (0x0000)  - 全零AND 結果
# 暫存器 x13 應包含值 -1     (0xFFFFFFFF) - 全一OR 結果
# 暫存器 x14 應包含值 0      (0x0000)  - 自反XOR 結果
# 暫存器 x15 應包含值 -256   (0xFF00)  - 負數ANDI 結果
# 暫存器 x16 應包含值 170    (0x00AA)  - ORI小立即數 結果
# 暫存器 x17 應包含值 -1     (0xFFFFFFFF) - XORI全位元 結果 