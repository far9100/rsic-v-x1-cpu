// RISC-V 32I CPU 分支指令測試平台
// 檔案：hardware/sim/tb_branch_test.v

`timescale 1ns / 1ps

module tb_branch_test;

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
        // 從測試文件中加載指令
        $readmemh("../../tests/hex_outputs/branch_integrated_test.hex", instr_mem);
        
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

    // 資料記憶體寫入邏輯（同步於時脈）
    always @(posedge clk) begin
        if (rst_n) begin // 只在非重置狀態下寫入
            if (d_mem_wen != 4'b0000 && d_mem_addr < 4*MEM_SIZE_WORDS) begin
                if (d_mem_wen == 4'b1111) begin // 字組寫入
                    data_mem[d_mem_addr / 4] <= d_mem_wdata;
                    // 顯示記憶體寫入以進行除錯
                    $display("資料記憶體寫入：位址=0x%h，資料=0x%h", d_mem_addr, d_mem_wdata);
                end
            end
        end
    end

    // 時脈產生
    initial begin
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
        $display("開始 RISC-V CPU 分支指令測試模擬...");
        wait (rst_n === 1);
        $display("重置解除。CPU 操作開始於時間 %0t。", $time);

        for (cycle_count_sim = 0; cycle_count_sim < MAX_SIM_CYCLES; cycle_count_sim = cycle_count_sim + 1) begin
            @(posedge clk);
            // 每 50 個週期印出正在擷取的指令
            if (cycle_count_sim % 50 == 0) begin
                $display("週期 %0d（模擬）：擷取指令：%h", cycle_count_sim, i_mem_rdata);
            end
        end

        // 檢查分支測試結果
        $display("\n============= 分支指令測試結果 =============");
        $display("測試案例 1.1 (BEQ 成功測試): %s", (data_mem[64] == 0) ? "通過" : "失敗");
        $display("測試案例 1.2 (BEQ 失敗測試): %s", (data_mem[65] == 0) ? "通過" : "失敗");
        $display("測試案例 2.1 (BNE 成功測試): %s", (data_mem[66] == 0) ? "通過" : "失敗");
        $display("測試案例 2.2 (BNE 失敗測試): %s", (data_mem[67] == 0) ? "通過" : "失敗");
        $display("測試案例 3.1 (BLT 成功測試): %s", (data_mem[68] == 0) ? "通過" : "失敗");
        $display("測試案例 3.2 (BLT 失敗測試): %s", (data_mem[69] == 0) ? "通過" : "失敗");
        $display("測試案例 4.1 (BGE 成功測試): %s", (data_mem[70] == 0) ? "通過" : "失敗");
        $display("測試案例 4.2 (BGE 成功測試 - 相等): %s", (data_mem[71] == 0) ? "通過" : "失敗");
        $display("測試案例 5.1 (BLTU 成功測試): %s", (data_mem[72] == 0) ? "通過" : "失敗");
        $display("測試案例 5.2 (BLTU 特殊測試 - 負數): %s", (data_mem[73] == 0) ? "通過" : "失敗");
        $display("測試案例 6.1 (BGEU 成功測試): %s", (data_mem[74] == 0) ? "通過" : "失敗");
        $display("測試案例 6.2 (BGEU 特殊測試 - 負數): %s", (data_mem[75] == 0) ? "通過" : "失敗");
        $display("測試案例 7 (後向分支 - 迴圈): %s", (data_mem[76] == 3) ? "通過" : "失敗");
        $display("=============================================\n");

        $display("模擬完成於時間 %0t。", $time);
        $finish;
    end

    // 波形輸出
    initial begin
        $dumpfile("tb_branch_test.vcd");
        $dumpvars(0, tb_branch_test);
    end

endmodule 