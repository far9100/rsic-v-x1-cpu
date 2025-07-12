// RISC-V 32I CPU 加減法測試平台
// 檔案：hardware/sim/tb_add_sub_test.v

`timescale 1ns / 1ps

// 為清晰起見定義 ALU 操作碼
`define ALU_OP_MUL 4'b1010

module tb_add_sub_test;

    // 參數
    localparam CLK_PERIOD = 10; // 時脈週期（納秒）（例如，100 MHz 時脈）
    localparam RESET_DURATION = CLK_PERIOD * 5; // 重置保持時間
    localparam MAX_SIM_CYCLES = 400; // 最大模擬週期數（增加以處理更多測試）
    localparam MEM_SIZE_WORDS = 1024; // 記憶體大小（字組數）

    // 測試平台信號
    reg         clk;
    reg         rst_n;

    // 待測裝置（DUT）介面信號
    wire [31:0] i_mem_addr;
    reg  [31:0] i_mem_rdata; // 由測試平台根據 i_mem_addr 驅動

    wire [31:0] d_mem_addr;
    wire [31:0] d_mem_wdata;
    wire [3:0]  d_mem_wen;
    reg  [31:0] d_mem_rdata; // 由測試平台根據 d_mem_addr 驅動

    // 實例化 CPU
    cpu_top u_cpu (
        .clk            (clk),
        .rst_n          (rst_n),
        .i_mem_addr     (i_mem_addr),
        .i_mem_rdata    (i_mem_rdata),
        .d_mem_addr     (d_mem_addr),
        .d_mem_wdata    (d_mem_wdata),
        .d_mem_wen      (d_mem_wen),
        .d_mem_rdata    (d_mem_rdata)
    );

    // 記憶體模型（簡化版）
    // 指令記憶體（類似 ROM）
    reg [31:0] instr_mem [0:MEM_SIZE_WORDS-1];
    integer i;
    initial begin
        // 從 .hex 檔案載入指令（例如，由組譯器產生）
        // 重要：確保此路徑相對於執行 vvp 的位置是正確的（通常是專案根目錄）
        $readmemh("tests/hex_outputs/add_sub_integrated_test.hex", instr_mem);
        
        // 初始化資料記憶體（例如，設為零）
        for (i = 0; i < MEM_SIZE_WORDS; i = i + 1) begin
            data_mem[i] = 32'b0;
        end
    end

    // 指令記憶體讀取邏輯（組合邏輯）
    always @(*) begin
        if (i_mem_addr < 4*MEM_SIZE_WORDS) begin // 檢查邊界（位元組位址 vs 字組陣列）
            i_mem_rdata = instr_mem[i_mem_addr / 4];
        end else begin
            i_mem_rdata = 32'hdeadbeef; // 超出邊界，回傳可識別的無效指令
        end
    end

    // 資料記憶體（類似 RAM）
    reg [31:0] data_mem [0:MEM_SIZE_WORDS-1];

    // 資料記憶體讀取邏輯（組合邏輯）
    always @(*) begin
        if (d_mem_addr < 4*MEM_SIZE_WORDS) begin // 檢查邊界
            d_mem_rdata = data_mem[d_mem_addr / 4];
        end else begin
            d_mem_rdata = 32'hxxxxxxxx; // 超出邊界
        end
    end

    // 宣告 file handle
    integer fp_process, fp_result;

    // 資料記憶體寫入邏輯（同步於時脈）
    always @(posedge clk) begin
        if (rst_n) begin // 只在非重置狀態下寫入
            if (d_mem_wen != 4'b0000 && d_mem_addr < 4*MEM_SIZE_WORDS) begin
                if (d_mem_wen == 4'b1111) begin // 字組寫入
                    data_mem[d_mem_addr / 4] <= d_mem_wdata;
                    $fdisplay(fp_process, "mem_write,%0t,0x%h,0x%h", $time, d_mem_addr, d_mem_wdata);
                end
            end
        end
    end

    // 時脈產生
    initial begin
        fp_process = $fopen("tests/output/add_sub_process.csv", "w");
        fp_result  = $fopen("tests/output/add_sub_result.csv", "w");
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // 重置產生
    initial begin
        rst_n = 0; // 啟動重置
        #(RESET_DURATION);
        rst_n = 1; // 解除重置
    end

    // 模擬控制和監控
    integer cycle_count_sim = 0;
    initial begin
        $fdisplay(fp_process, "開始 RISC-V CPU 加減法測試模擬...");
        wait (rst_n === 1);
        $fdisplay(fp_process, "重置解除。CPU 操作開始於時間 %0t。", $time);
        for (cycle_count_sim = 0; cycle_count_sim < MAX_SIM_CYCLES; cycle_count_sim = cycle_count_sim + 1) begin
            @(posedge clk);
            if (cycle_count_sim % 50 == 0) begin
                $fdisplay(fp_process, "cycle,%0d,%h", cycle_count_sim, i_mem_rdata);
            end
        end
        // 結果csv：測試結果
        $fdisplay(fp_result, "=== 加減法測試結果 ===");
        // 驗證加法和減法測試結果
        if (data_mem[32'h100/4]   == 3   &&  // ADD: 1 + 2 = 3
            data_mem[32'h100/4+1] == 30  &&  // ADD: 10 + 20 = 30
            data_mem[32'h100/4+2] == 2   &&  // ADD: 5 + (-3) = 2
            data_mem[32'h100/4+3] == 0   &&  // ADD: 5 + (-5) = 0
            data_mem[32'h100/4+4] == 7   &&  // ADD: 7 + 0 = 7
            data_mem[32'h100/4+5] == 300 &&  // ADD: 100 + 200 = 300
            data_mem[32'h100/4+6] == 3   &&  // SUB: 5 - 2 = 3
            data_mem[32'h100/4+7] == 20  &&  // SUB: 30 - 10 = 20
            data_mem[32'h100/4+8] == 5   &&  // SUB: 3 - (-2) = 5
            data_mem[32'h100/4+9] == 0) begin // SUB: 8 - 8 = 0
            $fdisplay(fp_result, "PASS");
        end else begin
            $fdisplay(fp_result, "FAIL");
        end
        // 細項測試
        $fdisplay(fp_result, "=== 加法測試細項 ===");
        $fdisplay(fp_result, "ADD 基本測試,%s", (data_mem[32'h100/4] == 3) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "ADD 較大數字,%s", (data_mem[32'h100/4+1] == 30) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "ADD 正負數,%s", (data_mem[32'h100/4+2] == 2) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "ADD 結果為零,%s", (data_mem[32'h100/4+3] == 0) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "ADD 加零測試,%s", (data_mem[32'h100/4+4] == 7) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "ADD 大數測試,%s", (data_mem[32'h100/4+5] == 300) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "=== 減法測試細項 ===");
        $fdisplay(fp_result, "SUB 基本測試,%s", (data_mem[32'h100/4+6] == 3) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "SUB 較大數字,%s", (data_mem[32'h100/4+7] == 20) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "SUB 減負數,%s", (data_mem[32'h100/4+8] == 5) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "SUB 結果為零,%s", (data_mem[32'h100/4+9] == 0) ? "PASS" : "FAIL");
        // 暫存器/記憶體狀態
        $fdisplay(fp_result, "=== 記憶體狀態 ===");
        for (i = 0; i < 10; i = i + 1) begin
            $fdisplay(fp_result, "data_mem[%0d],%0d", i, data_mem[32'h100/4+i]);
        end
        // 調試信息
        $fdisplay(fp_result, "=== 調試信息 ===");
        $fdisplay(fp_result, "模擬完成於時間,%0t", $time);
        $fclose(fp_process);
        $fclose(fp_result);
        $finish;
    end

    // 波形輸出
    initial begin
        $dumpfile("tests/output/tb_add_sub_test.vcd");
        $dumpvars(0, tb_add_sub_test);
    end

endmodule 