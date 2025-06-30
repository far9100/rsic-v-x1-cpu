# RISC-V 32I CPU 實現

這是一個基於 Verilog 的 RISC-V 32I CPU 實現，採用五級管線架構。

## 專案結構

```
rsic-v-x1-cpu/
├── assembler/               # 組譯器
│   └── assembler.py        # Python 組譯器
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
│   │   ├── pipeline_reg_if_id.v   # IF/ID 管線暫存器
│   │   ├── pipeline_reg_id_ex.v   # ID/EX 管線暫存器
│   │   ├── pipeline_reg_ex_mem.v  # EX/MEM 管線暫存器
│   │   ├── pipeline_reg_mem_wb.v  # MEM/WB 管線暫存器
│   └── sim/               # 模擬檔案
│       ├── tb_branch_test.v # 分支測試 testbench
│       ├── tb_add_test.v   # 加法測試 testbench
│       ├── tb_mul_test.v   # 乘法測試 testbench
│       ├── tb_fibonacci_test.v # 斐波那契測試 testbench
│       ├── tb_factorial_test.v # 階乘計算測試 testbench
│       ├── tb_gcd_test.v       # 輾轉相除法測試 testbench
│       ├── tb_div_integrated_test.v # 除法測試 testbench
│       ├── tb_prime_sieve_test.v    # 埃拉托色尼篩法測試 testbench
│       └── tb_hash_test.v           # 哈希運算測試 testbench
└── tests/                 # 測試程式
    ├── asm_sources/       # 組語原始檔
    │   ├── add_integrated_test.asm     # 加法測試
    │   ├── mul_integrated_test.asm     # 乘法測試
    │   ├── branch_integrated_test.asm  # 分支測試（包含LUI、JAL/JALR）
    │   ├── fibonacci_test.asm          # 斐波那契數列測試
    │   ├── factorial_test.asm          # 階乘計算測試
    │   ├── gcd_test.asm                # 輾轉相除法測試
    │   ├── div_integrated_test.asm     # 除法測試
    │   ├── prime_sieve_test.asm        # 埃拉托色尼篩法測試
    │   └── hash_test.asm               # 哈希運算測試
    └── hex_outputs/       # 組譯後的機器碼
```

## CPU 特性

- **架構**: RISC-V 32I 基礎整數指令集，支援 M 擴展 (MUL)
- **管線**: 五級管線 (IF, ID, EX, MEM, WB)
- **暫存器**: 32個 32-bit 通用暫存器
- **記憶體**: 分離式指令和資料記憶體
- **前遞**: 支援資料前遞避免部分危險
- **危險檢測**: 完整的危險檢測單元，支援載入-使用、分支等管線危險
- **分支**: 支援所有 RISC-V 分支指令，分支單元獨立模組
- **乘法**: 支援 MUL 指令（M 擴展）
- **除法**: 支援 DIV, DIVU, REM, REMU 指令（M 擴展）
- **管線暫存器**: 各階段皆有獨立管線暫存器

## 支援的指令

### 算術指令
- `ADD`, `SUB`, `ADDI`
- `AND`, `OR`, `XOR`, `ANDI`, `ORI`, `XORI`
- `SLL`, `SRL`, `SRA`, `SLLI`, `SRLI`, `SRAI`
- `SLT`, `SLTU`, `SLTI`, `SLTIU`
- `MUL` (M 擴展)
- `DIV`, `DIVU`, `REM`, `REMU` (M 擴展) - 除法和餘數運算

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

### 3. 分支測試
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
- 負數比較測試
- 零值比較測試
- 分支不採用情況
- 簡化向前跳轉迴圈
- 真實向後跳轉迴圈 (使用負數立即數)
- LUI指令支援 (Load Upper Immediate)
- JAL/JALR (跳轉並連結/暫存器跳轉並連結)
- 有符號/無符號分支差異測試
- 迴圈與跳轉邏輯完整驗證

### 4. 斐波那契數列測試
```bash
# 組譯測試程式
python assembler/assembler.py ./tests/asm_sources/fibonacci_test.asm -o ./tests/hex_outputs/fibonacci_test.hex

# 編譯 Verilog
iverilog -o fibonacci_sim hardware/sim/tb_fibonacci_test.v hardware/rtl/*.v

# 執行模擬
vvp fibonacci_sim
```

**斐波那契測試內容:**
- 使用迴圈計算前 10 個斐波那契數（1, 1, 2, 3, 5, 8, 13, 21, 34, 55）
- 結果會寫入資料記憶體 0x200 開始的連續位置
- 模擬結束後，`fibonacci_result.csv` 會顯示 PASS/FAIL 及每一項細節

### 5. 階乘計算測試
```bash
# 組譯測試程式
python assembler/assembler.py ./tests/asm_sources/factorial_test.asm -o ./tests/hex_outputs/factorial_test.hex

# 編譯 Verilog
iverilog -o factorial_sim hardware/sim/tb_factorial_test.v hardware/rtl/*.v

# 執行模擬
vvp factorial_sim
```

**階乘測試內容:**
- 使用迴圈計算 1 到 10 的階乘（1!, 2!, 3!, ..., 10!）
- 每個階乘值使用內部迴圈進行計算
- 結果會寫入資料記憶體 0x200 開始的連續位置
- 測試複雜的雙層迴圈邏輯和乘法運算
- 預期結果：1, 2, 6, 24, 120, 720, 5040, 40320, 362880, 3628800
- 模擬結束後，`factorial_result.csv` 會顯示 PASS/FAIL 及每一項細節

### 6. 除法測試 (新增)
```bash
# 組譯測試程式
python assembler/assembler.py ./tests/asm_sources/div_integrated_test.asm -o ./tests/hex_outputs/div_integrated_test.hex

# 編譯 Verilog
iverilog -o div_integrated_sim hardware/rtl/*.v hardware/sim/tb_div_integrated_test.v

# 執行模擬
vvp div_integrated_sim
```

**除法測試內容 (9項):**
- DIV 基本測試：84÷12 = 7 ✅
- DIV 負數測試：-84÷12 = -7 ✅
- DIVU 無符號測試：100÷4 = 25 ✅
- REM 有符號餘數：85%12 = 1 ✅
- REM 負數餘數：-85%12 = -1 ✅
- REMU 無符號餘數：87%13 = 9 ✅
- DIV 除零測試：10÷0 = -1 ✅
- DIVU 除零測試：10÷0 = 0xFFFFFFFF ✅
- 溢出測試：-2³¹÷(-1) = -2³¹ ✅

**測試輸出檔案:**
- 產生 `div_integrated_result.csv` 和 `div_integrated_process.csv`
- 支援完整的M擴展除法指令集 (DIV, DIVU, REM, REMU)
- 符合RISC-V規格的邊界情況處理
- **所有測試項目均完全通過** ✅

### 7. 輾轉相除法測試
```bash
# 組譯測試程式
python assembler/assembler.py ./tests/asm_sources/gcd_test.asm -o ./tests/hex_outputs/gcd_test.hex

# 編譯 Verilog
iverilog -o gcd_sim hardware/sim/tb_gcd_test.v hardware/rtl/*.v

# 執行模擬
vvp gcd_sim
```

**輾轉相除法測試內容:**
- 使用輾轉相除法（歐几里德算法）計算五對數字的最大公因數
- 測試數據對（100以內）：
  - GCD(12, 8) = 4
  - GCD(56, 42) = 14
  - GCD(48, 18) = 6
  - GCD(60, 48) = 12
  - GCD(81, 54) = 27
- 結果會寫入資料記憶體 0x200 開始的連續位置
- 模擬結束後，`gcd_result.csv` 會顯示 PASS/FAIL 及每一項細節

### 8. 埃拉托色尼篩法測試 (新增)
```bash
# 組譯測試程式
python assembler/assembler.py ./tests/asm_sources/prime_sieve_test.asm -o ./tests/hex_outputs/prime_sieve_test.hex

# 編譯 Verilog
iverilog -o prime_sieve_sim hardware/sim/tb_prime_sieve_test.v hardware/rtl/*.v

# 執行模擬
vvp prime_sieve_sim
```

**埃拉托色尼篩法測試內容:**
- 使用試除法計算五個二位數範圍內的質數個數
- 測試數據：
  - 15以內質數個數：6 (2,3,5,7,11,13)
  - 25以內質數個數：9 (+17,19,23)
  - 35以內質數個數：11 (+29,31)
  - 50以內質數個數：15 (+37,41,43,47)
  - 70以內質數個數：19 (+53,59,61,67)
- 結果會寫入資料記憶體 0x200 開始的連續位置
- 模擬結束後，`prime_sieve_result.csv` 會顯示 PASS/FAIL 及每一項細節
- 測試複雜的數學運算和迴圈邏輯
- **所有測試項目均完全通過** ✅

### 9. 哈希運算測試 (新增)
```bash
# 組譯測試程式
python assembler/assembler.py ./tests/asm_sources/hash_test.asm -o ./tests/hex_outputs/hash_test.hex

# 編譯 Verilog
iverilog -o hash_sim hardware/sim/tb_hash_test.v hardware/rtl/*.v

# 執行模擬
vvp hash_sim
```

**哈希運算測試內容:**
- 使用簡化哈希算法計算不同數值序列的哈希值
- 算法：`hash = 331; for each data: hash = (hash * 3) + data, hash %= 10000, 確保非零`
- 測試數據：
  - 測試1：{12, 34} - 2個數值 → 0xfffffcd1
  - 測試2：{56, 78, 90} - 3個數值 → 0xfffff695
  - 測試3：{11, 22, 33, 44} - 4個數值 → 0xffffe66a
  - 測試4：{1, 2, 3, 4, 5} - 5個數值 → 0xffffadee
  - 測試5：{99, 88, 77, 66, 55, 44} - 6個數值 → 0xffff046b
- 結果會寫入資料記憶體 0x300 開始的連續位置
- 測試位移、邏輯運算、迴圈控制和記憶體存取
- 驗證哈希值非零性和唯一性

**測試輸出檔案:**
- 產生 `hash_result.csv` 和 `hash_process.csv`
- 檢查所有哈希值都不為零且互不相同
- 提供統計資訊如哈希範圍和平均值
- **所有測試項目均完全通過 (5/5)** ✅


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
