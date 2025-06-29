// RISC-V 32I CPU 輾轉相除法測試平台
// 檔案：hardware/sim/tb_gcd_test.v

`timescale 1ns / 1ps

module tb_gcd_test;

    // 參數
    localparam CLK_PERIOD = 10; // 時脈週期（納秒）（例如，100 MHz 時脈）
    localparam RESET_DURATION = CLK_PERIOD * 5; // 重置保持時間
    localparam MAX_SIM_CYCLES = 3000; // 最大模擬週期數（增加以容納 5 組測試）
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
        $readmemh("./tests/hex_outputs/gcd_test.hex", instr_mem);
        
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
        fp_process = $fopen("gcd_process.csv", "w");
        fp_result  = $fopen("gcd_result.csv", "w");
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
        $fdisplay(fp_process, "開始 RISC-V CPU 輾轉相除法測試模擬...");
        wait (rst_n === 1);
        $fdisplay(fp_process, "重置解除。CPU 操作開始於時間 %0t。", $time);
        for (cycle_count_sim = 0; cycle_count_sim < MAX_SIM_CYCLES; cycle_count_sim = cycle_count_sim + 1) begin
            @(posedge clk);
            if (cycle_count_sim % 50 == 0) begin
                $fdisplay(fp_process, "cycle,%0d,%h", cycle_count_sim, i_mem_rdata);
            end
        end
        // 結果csv：測試結果
        $fdisplay(fp_result, "=== 輾轉相除法測試結果 ===");
        if (data_mem[32'h200/4]   == 4  &&  // GCD(12, 8) = 4
            data_mem[32'h200/4+1] == 6  &&  // GCD(48, 18) = 6
            data_mem[32'h200/4+2] == 7  &&  // GCD(35, 21) = 7
            data_mem[32'h200/4+3] == 15 &&  // GCD(60, 45) = 15
            data_mem[32'h200/4+4] == 1) begin  // GCD(17, 13) = 1
            $fdisplay(fp_result, "PASS");
        end else begin
            $fdisplay(fp_result, "FAIL");
        end
        // 細項測試
        $fdisplay(fp_result, "=== 細項測試 ===");
        $fdisplay(fp_result, "GCD(12,8),%s (Expected: 4, Got: %0d)", 
                 (data_mem[32'h200/4] == 4) ? "PASS" : "FAIL", data_mem[32'h200/4]);
        $fdisplay(fp_result, "GCD(48,18),%s (Expected: 6, Got: %0d)", 
                 (data_mem[32'h200/4+1] == 6) ? "PASS" : "FAIL", data_mem[32'h200/4+1]);
        $fdisplay(fp_result, "GCD(35,21),%s (Expected: 7, Got: %0d)", 
                 (data_mem[32'h200/4+2] == 7) ? "PASS" : "FAIL", data_mem[32'h200/4+2]);
        $fdisplay(fp_result, "GCD(60,45),%s (Expected: 15, Got: %0d)", 
                 (data_mem[32'h200/4+3] == 15) ? "PASS" : "FAIL", data_mem[32'h200/4+3]);
        $fdisplay(fp_result, "GCD(17,13),%s (Expected: 1, Got: %0d)", 
                 (data_mem[32'h200/4+4] == 1) ? "PASS" : "FAIL", data_mem[32'h200/4+4]);
        
        // 暫存器/記憶體狀態
        $fdisplay(fp_result, "=== 記憶體狀態 ===");
        for (i = 0; i < 5; i = i + 1) begin
            $fdisplay(fp_result, "data_mem[%0d],%0d", 128+i, data_mem[32'h200/4+i]);
        end
        
        // 調試信息
        $fdisplay(fp_result, "=== 調試信息 ===");
        $fdisplay(fp_result, "模擬完成於時間,%0t", $time);
        $fdisplay(fp_result, "總模擬週期數,%0d", cycle_count_sim);
        $fclose(fp_process);
        $fclose(fp_result);
        $finish;
    end

    // 波形輸出
    initial begin
        $dumpfile("tb_gcd_test.vcd");
        $dumpvars(0, tb_gcd_test);
    end

endmodule 