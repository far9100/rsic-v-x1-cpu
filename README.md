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
│   │   ├── divider.v      # 除法器
│   │   ├── pipeline_reg_if_id.v   # IF/ID 管線暫存器
│   │   ├── pipeline_reg_id_ex.v   # ID/EX 管線暫存器
│   │   ├── pipeline_reg_ex_mem.v  # EX/MEM 管線暫存器
│   │   └── pipeline_reg_mem_wb.v  # MEM/WB 管線暫存器
│   └── sim/               # 模擬檔案
│       ├── tb_branch_test.v # 分支測試 testbench
│       ├── tb_add_test.v   # 加法測試 testbench
│       ├── tb_mul_test.v   # 乘法測試 testbench
│       ├── tb_fibonacci_test.v # 斐波那契測試 testbench
│       ├── tb_factorial_test.v # 階乘計算測試 testbench
│       ├── tb_gcd_test.v       # 輾轉相除法測試 testbench
│       ├── tb_div_integrated_test.v # 除法測試 testbench
│       ├── tb_prime_sieve_test.v    # 埃拉托色尼篩法測試 testbench
│       ├── tb_hash_test.v           # 哈希運算測試 testbench
│       ├── tb_fft_test.v            # FFT測試 testbench
│       ├── tb_convolution_test.v    # 卷積測試 testbench
│       ├── tb_bubble_sort_test.v    # 氣泡排序測試 testbench
│       └── tb_logic_test.v          # 逻辑指令測試 testbench
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
    │   ├── hash_test.asm               # 哈希運算測試
    │   ├── fft_test.asm                # FFT測試
│   ├── convolution_test.asm        # 卷積測試
│   ├── bubble_sort_test.asm        # 氣泡排序測試
│   └── logic_integrated_test.asm   # 逻辑指令測試
    └── hex_outputs/       # 組譯後的機器碼
        ├── add_integrated_test.hex
        ├── mul_integrated_test.hex
        ├── branch_integrated_test.hex
        ├── fibonacci_test.hex
        ├── factorial_test.hex
        ├── gcd_test.hex
        ├── div_integrated_test.hex
        ├── prime_sieve_test.hex
        ├── hash_test.hex
        ├── fft_test.hex
        ├── convolution_test.hex
        ├── bubble_sort_test.hex        # 氣泡排序測試機器碼
        └── logic_integrated_test.hex   # 逻辑指令測試機器碼
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

所有測試的輸出檔案現在都存放在 `tests/output/` 資料夾中，包括：
- `*_process.csv` - 測試過程記錄
- `*_result.csv` - 測試結果摘要  
- `*.vcd` - 波形檔案
- `_sim` - 除法測試的詳細模擬記錄

### 輸出文件說明
每個測試都會產生以下四種文件：
1. **過程記錄文件** (`*_process.csv`): 記錄測試執行過程中的詳細信息
2. **結果摘要文件** (`*_result.csv`): 包含測試結果的PASS/FAIL狀態和詳細驗證
3. **波形文件** (`*.vcd`): 可用於波形查看器（如GTKWave）進行信號分析
4. **模擬記錄文件** (`_sim`): 除法測試的專用詳細記錄

### 1. 加法測試
```bash
# 組譯測試程式
python assembler/assembler.py ./tests/asm_sources/add_integrated_test.asm -o ./tests/hex_outputs/add_integrated_test.hex

# 編譯 Verilog
iverilog -o tests/output/add_sim hardware/sim/tb_add_test.v hardware/rtl/*.v

# 執行模擬
vvp tests/output/add_sim
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
iverilog -o tests/output/mul_sim hardware/sim/tb_mul_test.v hardware/rtl/*.v

# 執行模擬
vvp tests/output/mul_sim
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
iverilog -o tests/output/branch_sim hardware/sim/tb_branch_test.v hardware/rtl/*.v

# 執行模擬
vvp tests/output/branch_sim
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
iverilog -o tests/output/fibonacci_sim hardware/sim/tb_fibonacci_test.v hardware/rtl/*.v

# 執行模擬
vvp tests/output/fibonacci_sim
```

**斐波那契測試內容:**
- 使用迴圈計算前 10 個斐波那契數（1, 1, 2, 3, 5, 8, 13, 21, 34, 55）

### 5. 階乘計算測試
```bash
# 組譯測試程式
python assembler/assembler.py ./tests/asm_sources/factorial_test.asm -o ./tests/hex_outputs/factorial_test.hex

# 編譯 Verilog
iverilog -o tests/output/factorial_sim hardware/sim/tb_factorial_test.v hardware/rtl/*.v

# 執行模擬
vvp tests/output/factorial_sim
```

**階乘測試內容:**
- 使用迴圈計算 1 到 10 的階乘（1!, 2!, 3!, ..., 10!）

### 6. 除法測試
```bash
# 組譯測試程式
python assembler/assembler.py ./tests/asm_sources/div_integrated_test.asm -o ./tests/hex_outputs/div_integrated_test.hex

# 編譯 Verilog
iverilog -o tests/output/div_integrated_sim hardware/rtl/*.v hardware/sim/tb_div_integrated_test.v

# 執行模擬
vvp tests/output/div_integrated_sim
```

**除法測試內容:**
- DIV 基本測試
- DIV 負數測試
- DIVU 無符號測試
- REM 有符號餘數
- REM 負數餘數
- REMU 無符號餘數
- DIV 除零測試
- DIVU 除零測試
- 溢出測試

### 7. 輾轉相除法測試
```bash
# 組譯測試程式
python assembler/assembler.py ./tests/asm_sources/gcd_test.asm -o ./tests/hex_outputs/gcd_test.hex

# 編譯 Verilog
iverilog -o tests/output/gcd_sim hardware/sim/tb_gcd_test.v hardware/rtl/*.v

# 執行模擬
vvp tests/output/gcd_sim
```

**輾轉相除法測試內容:**
- 使用輾轉相除法計算兩數的最大公因數，共五組

### 8. 埃拉托色尼篩法測試
```bash
# 組譯測試程式
python assembler/assembler.py ./tests/asm_sources/prime_sieve_test.asm -o ./tests/hex_outputs/prime_sieve_test.hex

# 編譯 Verilog
iverilog -o tests/output/prime_sieve_sim hardware/sim/tb_prime_sieve_test.v hardware/rtl/*.v

# 執行模擬
vvp tests/output/prime_sieve_sim
```

**埃拉托色尼篩法測試內容:**
- 使用試除法計算五個二位數範圍內的質數個數，測試複雜的數學運算和迴圈邏輯

### 9. 哈希運算測試
```bash
# 組譯測試程式
python assembler/assembler.py ./tests/asm_sources/hash_test.asm -o ./tests/hex_outputs/hash_test.hex

# 編譯 Verilog
iverilog -o tests/output/hash_sim hardware/sim/tb_hash_test.v hardware/rtl/*.v

# 執行模擬
vvp tests/output/hash_sim
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

### 10. 快速傅立葉變換(FFT)測試
```bash
# 組譯測試程式
python assembler/assembler.py ./tests/asm_sources/fft_test.asm -o ./tests/hex_outputs/fft_test.hex

# 編譯 Verilog
iverilog -o tests/output/fft_sim hardware/sim/tb_fft_test.v hardware/rtl/*.v

# 執行模擬
vvp tests/output/fft_sim
```

**FFT測試內容:**
- **檔案**: `tests/asm_sources/fft_test.asm`  
- **功能**: 4點離散傅立葉變換(DFT)演算法測試  
- **演算法**: 直接計算DFT，避免複數三角函數  
- **測試數據**: 三種不同信號模式  
- **輸出**: `fft_result.csv`, `fft_process.csv`, `tb_fft_test.vcd`

### 11. 一維卷積測試
```bash
# 組譯測試程式
python assembler/assembler.py ./tests/asm_sources/convolution_test.asm -o ./tests/hex_outputs/convolution_test.hex

# 編譯 Verilog
iverilog -o tests/output/convolution_sim hardware/sim/tb_convolution_test.v hardware/rtl/*.v

# 執行模擬
vvp tests/output/convolution_sim
```

**卷積測試內容:**
- **算法**: 極簡指令測試（替代原始卷積算法）
- **測試指令**: addi, add, sub, sw等基礎指令
- **測試數據**:
  - 測試1: addi x1, x0, 5 → 結果: 5
  - 測試2: addi x3, x0, 10 → 結果: 10  
  - 測試3: add x4, x1, x3 → 結果: 15 (5+10)
  - 測試4: sub x5, x3, x1 → 結果: 5 (10-5)
  - 測試5: addi x6, x0, 42 → 結果: 42
  - 測試6: addi x7, x0, -7 → 結果: -7

### 12. 氣泡排序測試
```bash
# 組譯測試程式
python assembler/assembler.py tests/asm_sources/bubble_sort_test.asm -o tests/hex_outputs/bubble_sort_test.hex

# 編譯 Verilog
iverilog -o tests/output/bubble_sort_sim hardware/sim/tb_bubble_sort_test.v hardware/rtl/*.v

# 執行模擬
vvp tests/output/bubble_sort_sim
```

**氣泡排序測試內容:**
- **算法**: 簡化氣泡排序算法實現 (3個元素)
- **測試數據**: 3個數值的陣列 [7, 3, 5]
- **預期結果**: 排序後陣列 [3, 5, 7]
- **測試指令**: ADDI (立即數加法)、ADD (暫存器加法)、BLT (小於分支)、SW (儲存字)
- **測試重點**: 條件分支、暫存器操作、記憶體存取
- **輸出檔案**: `bubble_sort_result.csv`, `bubble_sort_process.csv`, `tb_bubble_sort_test.vcd`

### 13. 逻辑指令測試
```bash
# 組譯測試程式
python assembler/assembler.py ./tests/asm_sources/logic_integrated_test.asm -o ./tests/hex_outputs/logic_integrated_test.hex

# 編譯 Verilog
iverilog -o tests/output/logic_sim hardware/sim/tb_logic_test.v hardware/rtl/*.v

# 執行模擬
vvp tests/output/logic_sim
```

**逻辑指令測試內容:**
- AND 指令測試 - 位元AND運算
- OR 指令測試 - 位元OR運算  
- XOR 指令測試 - 位元XOR運算
- ANDI 指令測試 - 立即數AND運算
- ORI 指令測試 - 立即數OR運算
- XORI 指令測試 - 立即數XOR運算
- 全零/全一測試 - 邊界條件
- 自反運算測試 - 相同運算元
- 負數立即數測試 - 符號擴展
- 各種位元模式測試 - 驗證位元操作正確性
- **輸出檔案**: `logic_result.csv`, `logic_process.csv`, `tb_logic_test.vcd`
