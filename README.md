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
iverilog -o add_sim hardware/sim/tb_simple_test.v hardware/rtl/*.v

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
iverilog -o mul_sim hardware/sim/tb_simple_test.v hardware/rtl/*.v

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

## 測試狀態

| 測試項目 | 狀態 | 說明 |
|---------|------|------|
| 加法測試 | ✅ 通過 | ADD 和 ADDI 指令運算正常 |
| 乘法測試 | ✅ 通過 | MUL 指令運算正常 |
| 分支測試 | ✅ 通過 | 所有分支指令和跳轉正常 |

## 最近修正的問題

### 分支測試修正 (已完成)
1. **無限迴圈問題**: 修正了管線控制邏輯，添加了正確的管線沖洗機制
2. **危險檢測**: 實現了完整的危險檢測單元，包含載入-使用危險檢測
3. **分支控制**: 添加了 `pc_write_en`, `if_id_write_en`, `if_id_flush_en`, `id_ex_flush_en` 控制信號
4. **信號連接**: 修正了 `d_mem_wdata` 的重複連接問題
5. **測試程式**: 簡化了迴圈測試邏輯，避免無限迴圈問題
6. **乘法支援**: 添加了乘法器模組，支援乘法運算

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

## 分支測試項目

### 已完成的測試項目 ✅
1. **BEQ (Branch if Equal)** - 相等分支
2. **BNE (Branch if Not Equal)** - 不相等分支  
3. **BLT (Branch if Less Than, signed)** - 有符號小於分支
4. **BGE (Branch if Greater or Equal, signed)** - 有符號大於等於分支
5. **BLTU (Branch if Less Than, unsigned)** - 無符號小於分支
6. **BGEU (Branch if Greater or Equal, unsigned)** - 無符號大於等於分支
7. **負數比較測試** - 測試負數的分支行為
8. **分支不採用測試** - 測試條件不滿足時的行為
9. **零值比較測試** - 測試與零值的比較
10. **簡化迴圈測試** - 測試向前跳轉的迴圈
11. **真實迴圈測試** - 測試向後跳轉的迴圈（使用負數立即數）
12. **LUI指令支援** - 實現Load Upper Immediate指令 ✅

### 已完成的測試項目 ✅ (續)
13. **有符號vs無符號差異測試** - 使用LUI指令產生0x80000000測試有符號/無符號比較差異 ✅

### 待完成的測試項目 🔄
1. **JAL (Jump and Link)** - 跳轉並連結指令
2. **JALR (Jump and Link Register)** - 暫存器跳轉並連結指令（需要AUIPC）

### LUI指令實現詳情 ✅
- **組譯器支援**：已實現U型指令組譯函數
- **硬體支援**：
  - 控制單元正確識別LUI opcode (0110111)
  - 立即值產生器正確處理U型立即值
  - ID階段強制LUI指令的rs1為x0暫存器
  - ALU執行 `0 + 立即值` 運算
- **測試驗證**：通過專門的LUI測試，正確載入0x80000000和0x12345000

### 有符號vs無符號差異測試詳情 ✅
- **測試值**：使用 `lui x20, 0x80000` 載入 `0x80000000`
- **有符號解釋**：`0x80000000` = `-2147483648` (最小負數)
- **無符號解釋**：`0x80000000` = `2147483648` (大正數)
- **測試案例**：
  1. `blt 0x80000000, 0` (有符號) → True ✅ (負數 < 0)
  2. `bltu 0x80000000, 0` (無符號) → False ✅ (大正數 > 0)
  3. `bge 0, 0x80000000` (有符號) → True ✅ (0 > 負數)
  4. `bgeu 0, 0x80000000` (無符號) → False ✅ (0 < 大正數)
- **結果**：所有測試正確通過，證明分支單元正確實現有符號/無符號比較

### 測試執行方法
