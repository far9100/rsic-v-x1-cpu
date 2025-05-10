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

## 開發工具

- **硬體描述語言:** Verilog
- **模擬工具:** iVerilog
- **轉譯器開發語言:** Python

## 開發階段

1.  **CPU 硬體設計 (Verilog)**
    - 五級管線：IF, ID, EX, MEM, WB
    - 支援 RV32IM 指令集
    - 危害處理機制
2.  **Python 組合語言轉譯器開發**
    - 支援 RV32IM 組合語言指令
    - 輸出十六進制機器碼
3.  **測試程式撰寫**
    - 加法測試
    - 乘法測試 (`mul` 指令)
    - 排序演算法測試
4.  **整合與模擬測試**
    - 使用 iVerilog 進行模擬驗證

## 測試與模擬指令

以下步驟說明如何轉譯組合語言程式並使用 iVerilog 進行模擬：

1.  **轉譯組合語言程式:**
    使用 `assembler/assembler.py` 將測試用的組合語言檔案 (例如 `tests/asm_sources/add_test.asm`) 轉譯成十六進制機器碼檔案。

    ```bash
    python assembler/assembler.py tests/asm_sources/add_test.asm -o tests/hex_outputs/add_test.hex
    ```
    您可以替換 `add_test.asm` 和 `add_test.hex` 為其他測試程式，例如 `mul_test.asm` 或 `sort_test.asm`。

2.  **準備測試平台 (Testbench):**
    開啟 `hardware/sim/tb_cpu.v` 檔案。找到以下這行：
    ```verilog
    // $readmemh("path_to_your_instruction_hex_file.hex", instr_mem);
    ```
    取消註解並將 `"path_to_your_instruction_hex_file.hex"` 修改為您剛產生的十六進制檔案的路徑，例如：
    ```verilog
    $readmemh("tests/hex_outputs/add_test.hex", instr_mem);
    ```
    如果您不想每次修改 testbench，也可以在 testbench 中移除預設的 `instr_mem` 初始化，並在 iVerilog 編譯指令中透過 `+define+HEX_FILE_PATH` 傳入路徑 (這需要 testbench 支援)。目前提供的 testbench 骨架使用直接修改路徑的方式。

3.  **編譯 Verilog 原始碼與測試平台:**
    使用 iVerilog 編譯所有相關的 Verilog 檔案。請確保您在專案的根目錄下執行此指令。

    ```bash
    iverilog -o cpu_sim hardware/sim/tb_cpu.v hardware/rtl/*.v
    ```
    這會產生一個名為 `cpu_sim` 的可執行檔。

4.  **執行模擬:**
    執行先前編譯產生的檔案。

    ```bash
    vvp cpu_sim
    ```
    模擬過程中的輸出訊息 (例如 `$display` 內容) 將會顯示在終端機上。

5.  **查看波形 (可選):**
    測試平台已設定會產生一個名為 `tb_cpu.vcd` 的波形檔案。您可以使用波形查看工具 (如 GTKWave) 開啟此檔案來觀察訊號變化。

    ```bash
    gtkwave tb_cpu.vcd
    ```

**注意:**
- 在實際執行前，請確保您已安裝 Python 和 iVerilog。
- `assembler.py` 目前僅為骨架，需要完整實作才能正確轉譯所有指令。
- Verilog 模組也僅為骨架，需要完整實作 CPU 邏輯。
