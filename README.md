# RISC-V 32IM 處理器專案

本專案旨在設計和實作一個支援 RISC-V 32位元整數指令集 (RV32I) 以及乘除法擴展 (M Extension) 的五級管線處理器。

## 專案組成

- **硬體 (Hardware):** 使用 Verilog HDL 設計的處理器核心。
  - `hardware/rtl/`: 包含處理器各模組的 RTL 程式碼。
  - `hardware/sim/`: 包含用於模擬和驗證的測試平台 (Testbench)。
- **轉譯器 (Assembler):** 使用 Python 撰寫的組合語言轉譯器，可將 RISC-V 組合語言程式轉譯成處理器可執行的機器碼。
  - `assembler/assembler.py`: 轉譯器腳本。
- **測試程式 (Tests):** 用於驗證處理器功能的 RISC-V 組合語言程式。
  - `hardware/sim/tests/asm_sources/`: 存放組合語言原始檔 (.asm)。
  - `hardware/sim/tests/hex_outputs/`: 存放由轉譯器產生的十六進制機器碼檔案 (.hex)。
- **整合測試 (Integrated Tests):** 針對ADD、MUL和分支指令集的綜合測試。
  - `hardware/sim/tests/asm_sources/add_integrated_test.asm`: 加法指令整合測試。
  - `hardware/sim/tests/asm_sources/mul_integrated_test.asm`: 乘法指令整合測試。
  - `hardware/sim/tests/asm_sources/branch_integrated_test.asm`: 分支指令整合測試。

## 開發工具

- **硬體描述語言:** Verilog
- **模擬工具:** iVerilog
- **轉譯器開發語言:** Python

## 開發階段

1. **CPU 硬體設計 (Verilog)**
    - 五級管線：IF, ID, EX, MEM, WB
    - 支援 RV32IM 指令集
    - 危害處理機制
2. **Python 組合語言轉譯器開發**
    - 支援 RV32IM 組合語言指令
    - 輸出十六進制機器碼
3. **測試程式撰寫**
    - 加法測試
    - 乘法測試 (`mul` 指令)
    - 排序演算法測試
4. **整合與模擬測試**
    - 使用 iVerilog 進行模擬驗證

## 測試與模擬指令

以下步驟說明如何在 Windows 系統上執行 CPU 測試：

### 加法指令測試

1. **轉譯組合語言程式:**
    使用 Python 組譯器將加法測試的組合語言檔案轉譯成十六進制機器碼檔案。

    ```powershell
    python assembler/assembler.py hardware/sim/tests/asm_sources/add_integrated_test.asm -o hardware/sim/tests/hex_outputs/add_integrated_test.hex
    ```

2. **編譯 Verilog 原始碼與測試平台:**
    使用 iVerilog 編譯所有相關的 Verilog 檔案。

    ```powershell
    iverilog -o add_sim hardware/sim/tb_add_test.v hardware/rtl/*.v
    ```

3. **執行模擬:**
    執行編譯後的模擬檔。

    ```powershell
    vvp add_sim
    ```

4. **查看波形 (可選):**
    使用 GTKWave 開啟生成的波形檔案。

    ```powershell
    gtkwave tb_add_test.vcd
    ```

### 乘法指令測試

1. **轉譯組合語言程式:**
    ```powershell
    python assembler/assembler.py hardware/sim/tests/asm_sources/mul_integrated_test.asm -o hardware/sim/tests/hex_outputs/mul_integrated_test.hex
    ```

2. **編譯 Verilog 原始碼與測試平台:**
    ```powershell
    iverilog -o mul_sim hardware/sim/tb_mul_test.v hardware/rtl/*.v
    ```

3. **執行模擬:**
    ```powershell
    vvp mul_sim
    ```

4. **查看波形 (可選):**
    ```powershell
    gtkwave tb_mul_test.vcd
    ```

### 分支指令測試

分支測試包含對所有RISC-V分支指令的全面測試，包括BEQ、BNE、BLT、BGE、BLTU、BGEU以及跳轉指令JAL和JALR。測試涵蓋各種條件下的分支行為，包括前向分支、後向分支（迴圈）等。

1. **轉譯組合語言程式:**
    ```powershell
    python assembler/assembler.py hardware/sim/tests/asm_sources/branch_integrated_test.asm -o hardware/sim/tests/hex_outputs/branch_integrated_test.hex
    ```

2. **確保測試文件存在於正確位置:**
    ```powershell
    # 確認hex檔案已經成功生成
    ls hardware/sim/tests/hex_outputs/branch_integrated_test.hex
    ```

3. **編譯 Verilog 原始碼與測試平台:**
    ```powershell
    iverilog -o branch_test hardware/sim/tb_branch_test.v hardware/rtl/*.v
    ```

4. **執行模擬:**
    ```powershell
    vvp branch_test
    ```

5. **查看測試結果:**
    模擬完成後，測試結果會顯示在終端。

    測試平台使用英文輸出，避免終端編碼問題。

    每個測試案例顯示格式為"PASS/FAIL (Value=X)"，其中：
    - 值為0表示測試通過
    - 值為1表示測試失敗
    - 對於後向分支測試，值為0也表示通過，表示迴圈成功執行

    測試內容包括：
    - BEQ（相等時分支）指令正確與錯誤條件下的行為
    - BNE（不相等時分支）指令正確與錯誤條件下的行為
    - BLT/BGE（有符號比較）指令正確與錯誤條件下的行為
    - BLTU/BGEU（無符號比較）指令正確與錯誤條件下的行為
    - 後向分支（向後跳躍，形成迴圈）功能測試

6. **查看波形 (可選):**
    ```powershell
    gtkwave tb_branch_test.vcd
    ```

**注意:**
- 在執行測試前，請確保已安裝 Python 3 和 iVerilog。
- 路徑使用`./tests/hex_outputs/branch_integrated_test.hex`相對路徑。
- 每個步驟執行後，請確認是否有錯誤訊息。