// RISC-V 32I CPU 氣泡排序測試平台
// 檔案：hardware/sim/tb_bubble_sort_test.v
// 功能：測試三個數值的氣泡排序功能

`timescale 1ns / 1ps

module tb_bubble_sort_test;

    // 參數
    localparam CLK_PERIOD = 10;         // 時脈週期（納秒）
    localparam RESET_DURATION = CLK_PERIOD * 5; // 重置保持時間
    localparam MAX_SIM_CYCLES = 5000;   // 最大模擬週期數（10個數值需要更多週期）
    localparam MEM_SIZE_WORDS = 1024;   // 記憶體大小（字組數）

    // 測試平台信號
    reg         clk;
    reg         rst_n;

    // 待測裝置（DUT）介面信號
    wire [31:0] i_mem_addr;
    reg  [31:0] i_mem_rdata;

    wire [31:0] d_mem_addr;
    wire [31:0] d_mem_wdata;
    wire [3:0]  d_mem_wen;
    reg  [31:0] d_mem_rdata;

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
    reg [31:0] instr_mem [0:MEM_SIZE_WORDS-1];
    reg [31:0] data_mem [0:MEM_SIZE_WORDS-1];
    integer i;

    // 初始化記憶體
    initial begin
        // 從 .hex 檔案載入指令
        $readmemh("tests/hex_outputs/bubble_sort_test.hex", instr_mem);
        
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
                    
                    // 記錄重要的記憶體寫入操作
                    if (d_mem_addr >= 32'h200 && d_mem_addr <= 32'h224) begin
                        $fdisplay(fp_process, "array_write,%0t,原始陣列[%0d],0x%h,%0d", $time, (d_mem_addr - 32'h200)/4, d_mem_addr, d_mem_wdata);
                    end else if (d_mem_addr >= 32'h300 && d_mem_addr <= 32'h324) begin
                        $fdisplay(fp_process, "result_write,%0t,排序結果[%0d],0x%h,%0d", $time, (d_mem_addr - 32'h300)/4, d_mem_addr, d_mem_wdata);
                    end else if (d_mem_addr == 32'h400) begin
                        $fdisplay(fp_process, "completion_flag,%0t,完成標記,0x%h,%0d", $time, d_mem_addr, d_mem_wdata);
                    end
                end
            end
        end
    end

    // 時脈產生
    initial begin
        fp_process = $fopen("bubble_sort_process.csv", "w");
        fp_result  = $fopen("bubble_sort_result.csv", "w");
        
        // 寫入CSV標頭
        $fdisplay(fp_process, "==== 氣泡排序執行過程記錄 ====");
        $fdisplay(fp_process, "時間,事件類型,描述,位址/數值,備註");
        $fdisplay(fp_process, "");
        
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
    reg test_completed = 0;
    
    initial begin
        $fdisplay(fp_process, "%0t,simulation_start,開始 RISC-V CPU 氣泡排序測試模擬,,%s", $time, "測試數據：[9, 3, 7, 1, 5, 8, 2, 6, 4, 10] → 排序後: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]");
        
        wait (rst_n === 1);
        $fdisplay(fp_process, "%0t,reset_release,重置解除 CPU 操作開始,,%s", $time, "進入執行階段");
        
        // 等待測試完成標記
        for (cycle_count_sim = 0; cycle_count_sim < MAX_SIM_CYCLES; cycle_count_sim = cycle_count_sim + 1) begin : main_loop
            @(posedge clk);
            
            // 檢查完成標記 (address 0x400)
            if (data_mem[32'h400/4] == 1) begin
                test_completed = 1;
                $fdisplay(fp_process, "%0t,test_completed,測試完成於週期 %0d,,%s", $time, cycle_count_sim, "完成標記檢測成功");
                disable main_loop;
            end
            
            // 定期輸出進度和指令信息
            if (cycle_count_sim % 50 == 0) begin
                $fdisplay(fp_process, "%0t,cycle_progress,週期進度 %0d,0x%h,當前指令", $time, cycle_count_sim, i_mem_rdata);
            end
            
            // 監控PC位址變化（用於追蹤排序進度）
            if (cycle_count_sim % 10 == 0) begin
                $fdisplay(fp_process, "%0t,pc_trace,PC位址追蹤,0x%h,指令追蹤", $time, i_mem_addr);
            end
        end
        
        if (!test_completed) begin
            $fdisplay(fp_process, "%0t,timeout_warning,警告：測試未完成達到最大週期限制 %0d,,%s", $time, MAX_SIM_CYCLES, "可能存在無限循環");
        end
        
        // 結果驗證
        verify_sorting_results();
        
        $fdisplay(fp_process, "%0t,simulation_end,模擬結束,,%s", $time, "關閉所有文件");
        $fclose(fp_process);
        $fclose(fp_result);
        $finish;
    end

    // 驗證排序結果的任務
    task verify_sorting_results;
        reg [31:0] result [0:9];
        reg [31:0] expected [0:9];
        integer pass_count;
        integer i;
        integer sorted_correctly;
        
        begin
            // 預期結果：[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
            expected[0] = 1;
            expected[1] = 2;
            expected[2] = 3;
            expected[3] = 4;
            expected[4] = 5;
            expected[5] = 6;
            expected[6] = 7;
            expected[7] = 8;
            expected[8] = 9;
            expected[9] = 10;
            
            // 從記憶體讀取排序結果
            for (i = 0; i < 10; i = i + 1) begin
                result[i] = data_mem[32'h300/4 + i];
            end
            
            pass_count = 0;
            
            $fdisplay(fp_result, "=== 氣泡排序測試結果 ===");
            $fdisplay(fp_result, "輸入陣列：[9, 3, 7, 1, 5, 8, 2, 6, 4, 10]");
            $fdisplay(fp_result, "排序結果：[%0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d]", 
                     result[0], result[1], result[2], result[3], result[4], 
                     result[5], result[6], result[7], result[8], result[9]);
            $fdisplay(fp_result, "預期結果：[%0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d]", 
                     expected[0], expected[1], expected[2], expected[3], expected[4], 
                     expected[5], expected[6], expected[7], expected[8], expected[9]);
            $fdisplay(fp_result, "");
            
            // 逐項測試
            for (i = 0; i < 10; i = i + 1) begin
                if (result[i] == expected[i]) begin
                    pass_count = pass_count + 1;
                end
            end
            
            // 檢查排序正確性（遞增順序）
            sorted_correctly = 1;
            for (i = 0; i < 9; i = i + 1) begin
                if (result[i] > result[i+1]) begin
                    sorted_correctly = 0;
                end
            end
            
            if (sorted_correctly) begin
                pass_count = pass_count + 1;
            end
            
            // 總體結果判斷
            if (pass_count == 11) begin
                $fdisplay(fp_result, "PASS");
            end else begin
                $fdisplay(fp_result, "FAIL");
            end
            
            // 細項測試
            $fdisplay(fp_result, "=== 細項測試 ===");
            
            for (i = 0; i < 10; i = i + 1) begin
                if (result[i] == expected[i]) begin
                    $fdisplay(fp_result, "第%0d個元素,%s", i+1, "PASS");
                end else begin
                    $fdisplay(fp_result, "第%0d個元素,%s", i+1, "FAIL");
                end
            end
            
            // 檢查排序正確性（遞增順序）
            if (sorted_correctly) begin
                $fdisplay(fp_result, "排序順序,%s", "PASS");
            end else begin
                $fdisplay(fp_result, "排序順序,%s", "FAIL");
            end
            
            // 記憶體狀態
            $fdisplay(fp_result, "=== 記憶體狀態 ===");
            $fdisplay(fp_result, "原始陣列位址 0x200:");
            for (i = 0; i < 10; i = i + 1) begin
                $fdisplay(fp_result, "data_mem[%0d],%0d", i, data_mem[32'h200/4+i]);
            end
            $fdisplay(fp_result, "排序結果位址 0x300:");
            for (i = 0; i < 10; i = i + 1) begin
                $fdisplay(fp_result, "result_mem[%0d],%0d", i, data_mem[32'h300/4+i]);
            end
            $fdisplay(fp_result, "完成標記位址 0x400: %0d", data_mem[32'h400/4]);
            
            // 調試信息
            $fdisplay(fp_result, "=== 調試信息 ===");
            $fdisplay(fp_result, "模擬週期數,%0d", cycle_count_sim);
            $fdisplay(fp_result, "測試完成,%s", test_completed ? "是" : "否");
            $fdisplay(fp_result, "模擬完成於時間,%0t", $time);
            $fdisplay(fp_result, "通過測試項目,%0d/11", pass_count);
            
            // 詳細結果驗證
            $fdisplay(fp_result, "=== 詳細驗證 ===");
            for (i = 0; i < 10; i = i + 1) begin
                $fdisplay(fp_result, "第%0d個元素: 實際=%0d, 預期=%0d, 結果=%s", 
                         i+1, result[i], expected[i], (result[i] == expected[i]) ? "PASS" : "FAIL");
            end
            $fdisplay(fp_result, "遞增順序檢查: 結果=%s", sorted_correctly ? "PASS" : "FAIL");
            
            // 最終總結
            if (pass_count == 11) begin
                $fdisplay(fp_result, "=== 最終結果 ===");
                $fdisplay(fp_result, "整體結果: PASS - 氣泡排序功能正常");
            end else begin
                $fdisplay(fp_result, "=== 最終結果 ===");
                $fdisplay(fp_result, "整體結果: FAIL - 氣泡排序功能異常");
            end
        end
    endtask

    // 波形輸出
    initial begin
        $dumpfile("tb_bubble_sort_test.vcd");
        $dumpvars(0, tb_bubble_sort_test);
    end

endmodule 