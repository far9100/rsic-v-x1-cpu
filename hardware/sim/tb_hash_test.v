// RISC-V 32I CPU 哈希運算測試平台
// 檔案：hardware/sim/tb_hash_test.v

`timescale 1ns / 1ps

module tb_hash_test;

    // 參數
    localparam CLK_PERIOD = 10; // 時脈週期（納秒）
    localparam RESET_DURATION = CLK_PERIOD * 5; // 重置保持時間
    localparam MAX_SIM_CYCLES = 800; // 較長的模擬週期數
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

    // 記憶體模型
    // 指令記憶體（類似 ROM）
    reg [31:0] instr_mem [0:MEM_SIZE_WORDS-1];
    integer i;
    initial begin
        // 從 .hex 檔案載入指令
        $readmemh("tests/hex_outputs/hash_test.hex", instr_mem);
        
        // 初始化資料記憶體
        for (i = 0; i < MEM_SIZE_WORDS; i = i + 1) begin
            data_mem[i] = 32'b0;
        end
    end

    // 指令記憶體讀取邏輯
    always @(*) begin
        if (i_mem_addr < 4*MEM_SIZE_WORDS) begin
            i_mem_rdata = instr_mem[i_mem_addr / 4];
        end else begin
            i_mem_rdata = 32'hdeadbeef;
        end
    end

    // 資料記憶體（類似 RAM）
    reg [31:0] data_mem [0:MEM_SIZE_WORDS-1];

    // 資料記憶體讀取邏輯
    always @(*) begin
        if (d_mem_addr < 4*MEM_SIZE_WORDS) begin
            d_mem_rdata = data_mem[d_mem_addr / 4];
        end else begin
            d_mem_rdata = 32'hxxxxxxxx;
        end
    end

    // 檔案處理
    integer fp_process, fp_result;

    // 資料記憶體寫入邏輯
    always @(posedge clk) begin
        if (rst_n) begin
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
        fp_process = $fopen("hash_process.csv", "w");
        fp_result  = $fopen("hash_result.csv", "w");
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // 重置產生
    initial begin
        rst_n = 0;
        #(RESET_DURATION);
        rst_n = 1;
    end

    // 模擬控制和監控
    integer cycle_count_sim = 0;
    reg [31:0] hash_results [0:4]; // 存儲5個哈希結果
    integer result_count = 0;
    
    // 測試結果變量
    reg test1_pass, test2_pass, test3_pass, test4_pass, test5_pass;
    reg uniqueness_pass;
    
    initial begin
        $fdisplay(fp_process, "開始哈希運算測試模擬...");
        wait (rst_n === 1);
        $fdisplay(fp_process, "重置解除。CPU 操作開始於時間 %0t。", $time);
        
        for (cycle_count_sim = 0; cycle_count_sim < MAX_SIM_CYCLES; cycle_count_sim = cycle_count_sim + 1) begin
            @(posedge clk);
            if (cycle_count_sim % 20 == 0) begin
                $fdisplay(fp_process, "cycle,%0d,PC=0x%h,instr=0x%h", cycle_count_sim, i_mem_addr, i_mem_rdata);
            end
            
            // 監控寫入到結果記憶體的操作
            if (d_mem_wen == 4'b1111 && d_mem_addr >= 32'h300 && d_mem_addr < 32'h314) begin
                hash_results[(d_mem_addr - 32'h300) / 4] = d_mem_wdata;
                result_count = result_count + 1;
                $fdisplay(fp_process, "hash_result,%0d,0x%h,0x%h", 
                         (d_mem_addr - 32'h300) / 4, d_mem_addr, d_mem_wdata);
            end
        end
        
        // 檢查測試結果
        $fdisplay(fp_result, "=== 哈希運算測試結果 ===");
        
        // 檢查記憶體中的哈希結果
        $fdisplay(fp_result, "=== 記憶體哈希結果 ===");
        $fdisplay(fp_result, "測試1 {12,34},0x%h", data_mem[32'h300/4]);
        $fdisplay(fp_result, "測試2 {56,78,90},0x%h", data_mem[32'h304/4]);
        $fdisplay(fp_result, "測試3 {11,22,33,44},0x%h", data_mem[32'h308/4]);
        $fdisplay(fp_result, "測試4 {1,2,3,4,5},0x%h", data_mem[32'h30c/4]);
        $fdisplay(fp_result, "測試5 {99,88,77,66,55,44},0x%h", data_mem[32'h310/4]);
        
        // 檢查哈希值的有效性（非零且互不相同）
        
        test1_pass = (data_mem[32'h300/4] != 32'h0);
        test2_pass = (data_mem[32'h304/4] != 32'h0);
        test3_pass = (data_mem[32'h308/4] != 32'h0);
        test4_pass = (data_mem[32'h30c/4] != 32'h0);
        test5_pass = (data_mem[32'h310/4] != 32'h0);
        
        // 檢查唯一性（所有哈希值都不相同）
        uniqueness_pass = 1;
        if (data_mem[32'h300/4] == data_mem[32'h304/4] ||
            data_mem[32'h300/4] == data_mem[32'h308/4] ||
            data_mem[32'h300/4] == data_mem[32'h30c/4] ||
            data_mem[32'h300/4] == data_mem[32'h310/4] ||
            data_mem[32'h304/4] == data_mem[32'h308/4] ||
            data_mem[32'h304/4] == data_mem[32'h30c/4] ||
            data_mem[32'h304/4] == data_mem[32'h310/4] ||
            data_mem[32'h308/4] == data_mem[32'h30c/4] ||
            data_mem[32'h308/4] == data_mem[32'h310/4] ||
            data_mem[32'h30c/4] == data_mem[32'h310/4]) begin
            uniqueness_pass = 0;
        end
        
        // 分項測試結果
        $fdisplay(fp_result, "=== 測試結果分析 ===");
        $fdisplay(fp_result, "測試1 非零檢查,%s", test1_pass ? "PASS" : "FAIL");
        $fdisplay(fp_result, "測試2 非零檢查,%s", test2_pass ? "PASS" : "FAIL");
        $fdisplay(fp_result, "測試3 非零檢查,%s", test3_pass ? "PASS" : "FAIL");
        $fdisplay(fp_result, "測試4 非零檢查,%s", test4_pass ? "PASS" : "FAIL");
        $fdisplay(fp_result, "測試5 非零檢查,%s", test5_pass ? "PASS" : "FAIL");
        $fdisplay(fp_result, "唯一性檢查,%s", uniqueness_pass ? "PASS" : "FAIL");
        
        // 整體測試結果
        if (test1_pass && test2_pass && test3_pass && test4_pass && test5_pass && uniqueness_pass) begin
            $fdisplay(fp_result, "整體測試,PASS");
        end else begin
            $fdisplay(fp_result, "整體測試,FAIL");
        end
        
        // 統計資訊
        $fdisplay(fp_result, "=== 統計資訊 ===");
        $fdisplay(fp_result, "哈希範圍,0x%h - 0x%h", 
                 (data_mem[32'h300/4] < data_mem[32'h304/4]) ? data_mem[32'h300/4] : data_mem[32'h304/4],
                 (data_mem[32'h300/4] > data_mem[32'h304/4]) ? data_mem[32'h300/4] : data_mem[32'h304/4]);
        $fdisplay(fp_result, "平均哈希值,0x%h", 
                 (data_mem[32'h300/4] + data_mem[32'h304/4] + data_mem[32'h308/4] + 
                  data_mem[32'h30c/4] + data_mem[32'h310/4]) / 5);
        
        $fdisplay(fp_result, "模擬完成於時間,%0t", $time);
        $fclose(fp_process);
        $fclose(fp_result);
        $finish;
    end

    // 波形輸出
    initial begin
        $dumpfile("tb_hash_test.vcd");
        $dumpvars(0, tb_hash_test);
    end

    // 調試介面
    wire [1023:0] regs_flat_local;
    assign regs_flat_local = u_cpu.regs_flat;

endmodule 