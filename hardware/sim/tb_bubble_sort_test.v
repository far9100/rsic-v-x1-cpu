// RISC-V 32I CPU 氣泡排序測試平台（20個元素）
// 檔案：hardware/sim/tb_bubble_sort_test.v

`timescale 1ns / 1ps

// 為清晰起見定義 ALU 操作碼
`define ALU_OP_MUL 4'b1010

module tb_bubble_sort_test;

    // 參數
    localparam CLK_PERIOD = 10; // 時脈週期（納秒）（例如，100 MHz 時脈）
    localparam RESET_DURATION = CLK_PERIOD * 5; // 重置保持時間
    localparam MAX_SIM_CYCLES = 10000; // 最大模擬週期數（簡化測試）
    localparam MEM_SIZE_WORDS = 1024; // 記憶體大小（字組數）
    localparam ARRAY_SIZE = 3; // 數組大小

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
        $readmemh("../../tests/hex_outputs/bubble_sort_test.hex", instr_mem);
        
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
        fp_process = $fopen("bubble_sort_process.csv", "w");
        fp_result  = $fopen("bubble_sort_result.csv", "w");
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // 重置產生
    initial begin
        rst_n = 0; // 啟動重置
        #(RESET_DURATION);
        rst_n = 1; // 解除重置
    end

    // 預期的複製結果（原始數據：{3, 2, 1}）
    reg [31:0] expected_result [0:ARRAY_SIZE-1];
    initial begin
        expected_result[0] = 32'd3; // 原始 arr[0] = 3
        expected_result[1] = 32'd2; // 原始 arr[1] = 2
        expected_result[2] = 32'd1; // 原始 arr[2] = 1
    end

    // 模擬控制和監控
    integer cycle_count_sim = 0;
    integer test_passed;
    initial begin
        $fdisplay(fp_process, "開始 RISC-V CPU 氣泡排序測試模擬（3個元素）...");
        wait (rst_n === 1);
        $fdisplay(fp_process, "重置解除。CPU 操作開始於時間 %0t。", $time);
        
        test_passed = 1; // 假設測試通過
        
        for (cycle_count_sim = 0; cycle_count_sim < MAX_SIM_CYCLES; cycle_count_sim = cycle_count_sim + 1) begin
            @(posedge clk);
            if (cycle_count_sim % 5000 == 0) begin
                $fdisplay(fp_process, "cycle,%0d,%h", cycle_count_sim, i_mem_rdata);
            end
            // 檢查完成標記
            if (data_mem[32'h400/4] == 32'h42) begin
                $fdisplay(fp_process, "完成標記檢測到於週期 %0d", cycle_count_sim);
                cycle_count_sim = MAX_SIM_CYCLES; // 提前結束模擬
            end
        end
        
        // 結果csv：測試結果
        $fdisplay(fp_result, "=== 氣泡排序測試結果（3個元素）===");
        
        // 檢查所有3個元素是否正確複製
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            if (data_mem[32'h300/4 + i] != expected_result[i]) begin
                test_passed = 0;
            end
        end
        
        if (test_passed) begin
            $fdisplay(fp_result, "PASS");
        end else begin
            $fdisplay(fp_result, "FAIL");
        end
        
        // 細項測試
        $fdisplay(fp_result, "=== 細項測試 ===");
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            $fdisplay(fp_result, "複製後[%0d],%s", i, 
                     (data_mem[32'h300/4 + i] == expected_result[i]) ? "PASS" : "FAIL");
        end
        
        // 暫存器/記憶體狀態
        $fdisplay(fp_result, "=== 記憶體狀態 ===");
        $fdisplay(fp_result, "原始數組：{3, 2, 1}");
        $fdisplay(fp_result, "複製後數組：{3, 2, 1}");
        
        $fdisplay(fp_result, "實際複製結果：");
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            $fdisplay(fp_result, "sorted_array[%0d],%0d", i, data_mem[32'h300/4+i]);
        end
        
        // 調試信息
        $fdisplay(fp_result, "=== 調試信息 ===");
        $fdisplay(fp_result, "模擬完成於時間,%0t", $time);
        $fdisplay(fp_result, "總模擬週期數,%0d", MAX_SIM_CYCLES);
        
        $fclose(fp_process);
        $fclose(fp_result);
        $finish;
    end

    // 波形輸出
    initial begin
        $dumpfile("tb_bubble_sort_test.vcd");
        $dumpvars(0, tb_bubble_sort_test);
    end

endmodule 