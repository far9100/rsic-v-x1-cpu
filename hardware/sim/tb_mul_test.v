// RISC-V 32IM CPU 乘法測試平台
// 檔案：hardware/sim/tb_mul_test.v

`timescale 1ns / 1ps

module tb_mul_test;

    // 參數
    localparam CLK_PERIOD = 10; // 時脈週期（納秒）（例如，100 MHz 時脈）
    localparam RESET_DURATION = CLK_PERIOD * 5; // 重置保持時間
    localparam MAX_SIM_CYCLES = 500; // 最大模擬週期數
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
        $readmemh("tests/hex_outputs/mul_integrated_test.hex", instr_mem);
        
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
        fp_process = $fopen("mul_process.csv", "w");
        fp_result  = $fopen("mul_result.csv", "w");
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
        $fdisplay(fp_process, "開始 RISC-V CPU 乘法測試模擬...");
        wait (rst_n === 1);
        $fdisplay(fp_process, "重置解除。CPU 操作開始於時間 %0t。", $time);
        for (cycle_count_sim = 0; cycle_count_sim < MAX_SIM_CYCLES; cycle_count_sim = cycle_count_sim + 1) begin
            @(posedge clk);
            if (cycle_count_sim % 50 == 0) begin
                $fdisplay(fp_process, "cycle,%0d,%h", cycle_count_sim, i_mem_rdata);
            end
        end
        // 結果csv：測試結果
        $fdisplay(fp_result, "=== 乘法測試結果 ===");
        if ($signed(regs_flat_local[7*32 +: 32]) == 42 &&
            $signed(regs_flat_local[8*32 +: 32]) == -42 &&
            $signed(regs_flat_local[13*32 +: 32]) == 123456789 &&
            $signed(regs_flat_local[17*32 +: 32]) == 0 &&
            $signed(regs_flat_local[19*32 +: 32]) == 1) begin
            $fdisplay(fp_result, "PASS");
        end else begin
            $fdisplay(fp_result, "FAIL");
        end
        // 細項測試
        $fdisplay(fp_result, "=== 細項測試 ===");
        $fdisplay(fp_result, "正數乘法,%s", ($signed(regs_flat_local[7*32 +: 32]) == 42) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "負數乘法,%s", ($signed(regs_flat_local[8*32 +: 32]) == -42) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "大數乘法,%s", ($signed(regs_flat_local[13*32 +: 32]) == 123456789) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "測試點4,%s", ($signed(regs_flat_local[17*32 +: 32]) == 0) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "測試點5,%s", ($signed(regs_flat_local[19*32 +: 32]) == 1) ? "PASS" : "FAIL");
        // 暫存器狀態
        $fdisplay(fp_result, "=== 暫存器狀態 ===");
        $fdisplay(fp_result, "x7,%0d", $signed(regs_flat_local[7*32 +: 32]));
        $fdisplay(fp_result, "x8,%0d", $signed(regs_flat_local[8*32 +: 32]));
        $fdisplay(fp_result, "x13,%0d", $signed(regs_flat_local[13*32 +: 32]));
        $fdisplay(fp_result, "x17,%0d", $signed(regs_flat_local[17*32 +: 32]));
        $fdisplay(fp_result, "x19,%0d", $signed(regs_flat_local[19*32 +: 32]));
        // 調試信息
        $fdisplay(fp_result, "=== 調試信息 ===");
        $fdisplay(fp_result, "模擬完成於時間,%0t", $time);
        $fclose(fp_process);
        $fclose(fp_result);
        $finish;
    end

    // 波形輸出
    initial begin
        $dumpfile("tb_mul_test.vcd");
        $dumpvars(0, tb_mul_test);
    end

    // 在 module 內部宣告 local wire
    wire [1023:0] regs_flat_local;
    assign regs_flat_local = u_cpu.regs_flat;

endmodule 