# RISC-V 32IM 處理器專案

本專案旨在設計和實作一個支援 RISC-V 32位元整數指令集 (RV32I) 以及乘除法擴展 (M Extension) 的五級管線處理器。

## 專案組成

- **硬體 (Hardware):** 使用 Verilog HDL 設計的處理器核心。
  - `hardware/rtl/`: 包含處理器各模組的 RTL 程式碼。
  - `hardware/sim/`: 包含用於模擬和驗證的測試平台 (Testbench)。
- **轉譯器 (Assembler):** 使用 Python 撰寫的組合語言轉譯器，可將 RISC-V 組合語言程式轉譯成處理器可執行的機器碼。
  - `assembler/assembler.py`: 轉譯器腳本。
- **測試程式 (Tests):** 用於驗證處理器功能的 RISC-V 組合語言程式。
  - `tests/asm_sources/`: 存放組合語言原始檔 (.asm)。
  - `tests/hex_outputs/`: 存放由轉譯器產生的十六進制機器碼檔案 (.hex)。
- **整合測試 (Integrated Tests):** 針對ADD和MUL指令集的綜合測試。
  - `tests/asm_sources/add_integrated_test.asm`: 加法指令整合測試。
  - `tests/asm_sources/mul_integrated_test.asm`: 乘法指令整合測試。
  - `run_add_test.sh`: 執行加法指令整合測試的腳本。
  - `run_mul_test.sh`: 執行乘法指令整合測試的腳本。

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

以下步驟說明如何轉譯組合語言程式並使用 iVerilog 進行模擬：

1. **轉譯組合語言程式:**
    使用 `assembler/assembler.py` 將測試用的組合語言檔案 (例如 `tests/asm_sources/add_test.asm`) 轉譯成十六進制機器碼檔案。

    ```bash
    python3 assembler/assembler.py tests/asm_sources/add_integrated_test.asm -o tests/hex_outputs/add_integrated_test.hex
    ```

    您可以替換檔案名稱來測試其他程式。

2. **編譯 Verilog 原始碼與測試平台:**
    使用 iVerilog 編譯所有相關的 Verilog 檔案。請確保您在專案的根目錄下執行此指令。

    ```bash
    iverilog -o add_sim hardware/sim/tb_add_test.v hardware/rtl/*.v
    ```

    這會產生一個名為 `add_sim` 的可執行檔。

3. **執行模擬:**
    執行先前編譯產生的檔案。

    ```bash
    vvp add_sim
    ```

    模擬過程中的輸出訊息 (例如 `$display` 內容) 將會顯示在終端機上。

4. **查看波形 (可選):**
    測試平台已設定會產生一個波形檔案。您可以使用波形查看工具 (如 GTKWave) 開啟此檔案來觀察訊號變化。

    ```bash
    gtkwave tb_add_test.vcd
    ```

## 整合測試腳本

本專案提供了兩個整合測試腳本，可自動執行上述步驟：

1. **加法指令整合測試:**

    ```bash
    ./run_add_test.sh
    ```

    此腳本會自動轉譯加法測試程式，編譯測試平台，並執行模擬。測試結果將顯示於終端機上。

2. **乘法指令整合測試:**

    ```bash
    ./run_mul_test.sh
    ```

    此腳本會自動轉譯乘法測試程式，編譯測試平台，並執行模擬。測試結果將顯示於終端機上。

**注意:**

- 在實際執行前，請確保您已安裝 Python 3 和 iVerilog。
- 執行腳本前，請確保腳本具有執行權限 (`chmod +x run_*.sh`)。
