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
│   │   ├── register_file.v # 暫存器檔案
│   │   ├── control_unit.v # 控制單元
│   │   ├── forwarding_unit.v # 前遞單元
│   │   └── pipeline_reg_*.v # 管線暫存器
│   └── sim/               # 模擬檔案
│       ├── tb_branch_test.v # 分支測試 testbench
│       ├── tb_alu_test.v   # ALU 測試 testbench
│       ├── tb_load_store_test.v # 載入/儲存測試 testbench
│       └── tb_simple_test.v # 簡單測試 testbench
└── tests/                 # 測試程式
    ├── asm_sources/       # 組語原始檔
    └── hex_outputs/       # 組譯後的機器碼
```

## CPU 特性

- **架構**: RISC-V 32I 基礎整數指令集
- **管線**: 五級管線 (IF, ID, EX, MEM, WB)
- **暫存器**: 32個 32-bit 通用暫存器
- **記憶體**: 分離式指令和資料記憶體
- **前遞**: 支援資料前遞避免部分危險
- **分支**: 支援所有 RISC-V 分支指令

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

### 1. ALU 測試
```bash
# 組譯測試程式
python assembler/assembler.py ./tests/asm_sources/alu_test.asm -o ./tests/hex_outputs/alu_test.hex

# 編譯 Verilog
iverilog -o alu_sim hardware/sim/tb_alu_test.v hardware/rtl/*.v

# 執行模擬
vvp alu_sim
```

### 2. 載入/儲存測試
```bash
# 組譯測試程式
python assembler/assembler.py ./tests/asm_sources/load_store_test.asm -o ./tests/hex_outputs/load_store_test.hex

# 編譯 Verilog
iverilog -o load_store_sim hardware/sim/tb_load_store_test.v hardware/rtl/*.v

# 執行模擬
vvp load_store_sim
```

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
- BEQ (相等分支)
- BNE (不等分支)  
- BLT (小於分支, 有符號)
- BGE (大於等於分支, 有符號)
- BLTU (小於分支, 無符號)
- BGEU (大於等於分支, 無符號)
- JAL (跳轉並連結)
- JALR (暫存器跳轉並連結)
- 負數比較測試
- 有符號vs無符號差異測試
- 真實向後跳轉迴圈
- 零值比較測試
- 分支不採用情況
- 程式流程控制

### 4. 簡單測試
```bash
# 組譯測試程式
python assembler/assembler.py ./tests/asm_sources/simple_test.asm -o ./tests/hex_outputs/simple_test.hex

# 編譯 Verilog
iverilog -o simple_sim hardware/sim/tb_simple_test.v hardware/rtl/*.v

# 執行模擬
vvp simple_sim
```

## 測試狀態

| 測試項目 | 狀態 | 說明 |
|---------|------|------|
| ALU 測試 | ✅ 通過 | 所有算術邏輯運算正常 |
| 載入/儲存測試 | ✅ 通過 | 記憶體存取功能正常 |
| 分支測試 | ✅ 通過 | 所有分支指令和跳轉正常 |
| 簡單測試 | ✅ 通過 | 基本指令執行正常 |

## 最近修正的問題

### 分支測試修正 (已完成)
1. **無限迴圈問題**: 修正了管線控制邏輯，添加了正確的管線沖洗機制
2. **危險檢測**: 實現了載入-使用危險檢測邏輯  
3. **分支控制**: 添加了 `pc_write_en`, `if_id_write_en`, `if_id_flush_en`, `id_ex_flush_en` 控制信號
4. **信號連接**: 修正了 `d_mem_wdata` 的重複連接問題
5. **測試程式**: 簡化了迴圈測試邏輯，避免無限迴圈問題

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
- 分支預測功能尚未實現
