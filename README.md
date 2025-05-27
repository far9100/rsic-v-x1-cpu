# RISC-V 32I CPU 實現

這是一個基於 Verilog 的 RISC-V 32I CPU 實現，採用五級管線架構。

## 專案結構

```
rsic-v-x1-cpu/
├── assembler/               # 組譯器
│   ├── assembler.py        # Python 組譯器
│   └── instructions.py     # 指令定義
├── hardware/               # 硬體設計
│   ├── rtl/               # RTL 檔案
│   │   ├── cpu_top.v      # CPU 頂層模組
│   │   ├── if_stage.v     # IF 階段
│   │   ├── id_stage.v     # ID 階段
│   │   ├── ex_stage.v     # EX 階段
│   │   ├── mem_stage.v    # MEM 階段
│   │   ├── alu.v          # ALU
│   │   ├── branch_unit.v  # 分支單元
│   │   ├── reg_file.v     # 暫存器檔案
│   │   ├── control_unit.v # 控制單元
│   │   ├── forwarding_unit.v # 前遞單元
│   │   ├── hazard_detection_unit.v # 危險檢測單元
│   │   ├── immediate_generator.v # 立即數產生器
│   │   ├── multiplier.v   # 乘法器
│   │   └── pipeline_reg_*.v # 管線暫存器
│   └── sim/               # 模擬檔案
│       ├── tb_branch_test.v # 分支測試 testbench
│       ├── tb_simple_jal_test.v # JAL測試 testbench
│       ├── tb_add_test.v   # 加法測試 testbench
│       └── tb_mul_test.v   # 乘法測試 testbench
└── tests/                 # 測試程式
    ├── asm_sources/       # 組語原始檔
    │   ├── add_integrated_test.asm     # 加法測試
    │   ├── mul_integrated_test.asm     # 乘法測試
    │   ├── branch_integrated_test.asm  # 分支測試（包含LUI）
    │   └── simple_jal_test.asm        # JAL測試
    └── hex_outputs/       # 組譯後的機器碼
```

## CPU 特性

- **架構**: RISC-V 32I 基礎整數指令集
- **管線**: 五級管線 (IF, ID, EX, MEM, WB)
- **暫存器**: 32個 32-bit 通用暫存器
- **記憶體**: 分離式指令和資料記憶體
- **前遞**: 支援資料前遞避免部分危險
- **危險檢測**: 完整的危險檢測單元
- **分支**: 支援所有 RISC-V 分支指令
- **乘法**: 支援乘法運算

## 支援的指令

### 算術指令
- `ADD`, `SUB`, `ADDI`
- `AND`, `OR`, `XOR`, `ANDI`, `ORI`, `XORI`
- `SLL`, `SRL`, `SRA`, `SLLI`, `SRLI`, `SRAI`
- `SLT`, `SLTU`, `SLTI`, `SLTIU`

### 記憶體指令
- `LW`, `LH`, `LB`, `LHU`, `LBU`
- `SW`, `SH`, `SB`

### 分支指令
- `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`
- `JAL`, `JALR`

### 其他指令
- `LUI`, `AUIPC`

## 測試

### 1. 加法測試
```bash
# 組譯測試程式
python assembler/assembler.py ./tests/asm_sources/add_integrated_test.asm -o ./tests/hex_outputs/add_integrated_test.hex

# 編譯 Verilog
iverilog -o add_sim hardware/sim/tb_add_test.v hardware/rtl/*.v

# 執行模擬
vvp add_sim
```

**加法測試內容:**
- ADD 指令測試
- ADDI 指令測試
- 正數加法
- 負數加法
- 溢位情況

### 2. 乘法測試
```bash
# 組譯測試程式
python assembler/assembler.py ./tests/asm_sources/mul_integrated_test.asm -o ./tests/hex_outputs/mul_integrated_test.hex

# 編譯 Verilog
iverilog -o mul_sim hardware/sim/tb_mul_test.v hardware/rtl/*.v

# 執行模擬
vvp mul_sim
```

**乘法測試內容:**
- MUL 指令測試
- 正數乘法
- 負數乘法
- 大數乘法

### 3. 分支測試 ✅
```bash
# 組譯測試程式
python assembler/assembler.py ./tests/asm_sources/branch_integrated_test.asm -o ./tests/hex_outputs/branch_integrated_test.hex

# 編譯 Verilog
iverilog -o branch_sim hardware/sim/tb_branch_test.v hardware/rtl/*.v

# 執行模擬
vvp branch_sim
```

**分支測試內容:**
- ✅ BEQ (相等分支)
- ✅ BNE (不等分支)  
- ✅ BLT (小於分支, 有符號)
- ✅ BGE (大於等於分支, 有符號)
- ✅ BLTU (小於分支, 無符號)
- ✅ BGEU (大於等於分支, 無符號)
- ✅ 負數比較測試
- ✅ 零值比較測試
- ✅ 分支不採用情況
- ✅ 簡化向前跳轉迴圈
- ✅ 真實向後跳轉迴圈 (使用負數立即數)
- ✅ LUI指令支援 - 實現Load Upper Immediate指令 ✅

### 4. JAL測試 ✅ (獨立測試)
```bash
# 組譯測試程式
python assembler/assembler.py tests/asm_sources/simple_jal_test.asm -o tests/hex_outputs/simple_jal_test.hex

# 編譯 Verilog
iverilog -o simple_jal_sim -I hardware/rtl hardware/sim/tb_simple_jal_test.v hardware/rtl/*.v

# 執行模擬
vvp simple_jal_sim
```

**JAL測試內容:**
- ✅ JAL (跳轉並連結) - 獨立測試環境
- ✅ JALR (暫存器跳轉並連結) - 獨立測試環境
- ✅ 返回地址正確保存 (x7 = 0x00000008)
- ✅ 跳轉目標地址正確計算
- ✅ 最終結果驗證 (x6 = 20)

### 尚未完成的測試 🚧
| 測試項目 | 優先級 | 說明 |
|---------|--------|------|
| 分支測試中的JAL整合 | 高 | JAL (Jump and Link) 指令在分支測試中被註解，需要整合到分支測試流程 |
| 分支測試中的JALR整合 | 高 | JALR (Jump and Link Register) 指令在分支測試中被註解，需要整合到分支測試流程 |
| 記憶體測試 | 高 | 尚未實現 LW/LH/LB/LHU/LBU 和 SW/SH/SB 指令的完整測試 |?
| 中斷處理 | 中 | 尚未實現中斷和異常處理機制 |?
| 效能測試 | 低 | 尚未進行管線效能和吞吐量測試 |?
| 邊界測試 | 中 | 尚未進行極端情況和邊界條件測試 |?

## 已知問題 ⚠️
- JAL/JALR指令未能整合至分支測試
- 負數立即數測試部分疑似有 bug 尚未解決

| 問題描述 | 嚴重程度 | 影響範圍 | 解決方案 |
|---------|----------|----------|----------|
| JAL/JALR指令未整合到分支測試 | 中 | 分支測試完整性 | 需要將註解的JAL/JALR測試重新整合到分支測試流程中 |
| 前遞單元未處理分支指令 | 高 | 分支測試 | 需要修改前遞單元，增加對分支指令的支援 |
| 記憶體存取未對齊 | 中 | 記憶體操作 | 需要實現記憶體對齊檢查和處理 |
| 缺少除錯介面 | 低 | 開發效率 | 需要添加除錯介面，方便問題診斷 |
| 缺少時序約束 | 中 | 時序分析 | 需要添加時序約束檔案 |

## 開發工具

- **模擬器**: Icarus Verilog
- **組譯器**: 自製 Python 組譯器
- **測試**: 自製 testbench

## 使用方法

1. 確保安裝了 Icarus Verilog 和 Python
2. 將組語程式放在 `tests/asm_sources/` 目錄
3. 使用組譯器將組語轉換為機器碼
4. 執行對應的 testbench 進行模擬

## 注意事項

- 目前實現為教育用途，不包含所有 RISC-V 特性
- 記憶體系統為簡化版本
- 管線控制邏輯針對基本情況設計
