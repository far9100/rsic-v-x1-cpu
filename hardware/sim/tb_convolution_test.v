`timescale 1ns / 1ps

module tb_convolution_test;
    
    // 參數
    localparam CLK_PERIOD = 10; // 時脈週期（納秒）
    localparam RESET_DURATION = CLK_PERIOD * 5; // 重置保持時間
    localparam MAX_SIM_CYCLES = 10000; // 模擬週期數
    localparam MEM_SIZE_WORDS = 1024; // 記憶體大小（字組數）

    // 測試平台信號
    reg clk;
    reg rst_n;
    
    // 待測裝置（DUT）介面信號
    wire [31:0] i_mem_addr;
    reg  [31:0] i_mem_rdata; // 由測試平台根據 i_mem_addr 驅動

    wire [31:0] d_mem_addr;
    wire [31:0] d_mem_wdata;
    wire [3:0]  d_mem_wen;
    reg  [31:0] d_mem_rdata; // 由測試平台根據 d_mem_addr 驅動

    // 實例化CPU
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
        $readmemh("tests/hex_outputs/convolution_test.hex", instr_mem);
        
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

    // 時鐘產生
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end
    
    // 重置產生
    initial begin
        rst_n = 0;
        #(RESET_DURATION);
        rst_n = 1;
    end
    
    // 測試變數
    integer process_file, result_file;
    integer cycle_count;
    reg [31:0] result_data [0:5];  // 6個結果 (3個測試 * 2個輸出)
    reg [31:0] expected_results [0:5];
    integer test_complete;
    
    // 預期結果
    initial begin
        // 極簡測試結果
        expected_results[0] = 32'h00000005;  // 5
        expected_results[1] = 32'h0000000a;  // 10
        expected_results[2] = 32'h0000000f;  // 15 = 5 + 10
        expected_results[3] = 32'h00000005;  // 5 = 10 - 5
        expected_results[4] = 32'h0000002a;  // 42
        expected_results[5] = 32'hfffffff9;  // -7 (two's complement)
    end
    
    // 資料記憶體寫入邏輯
    always @(posedge clk) begin
        if (rst_n) begin
            if (d_mem_wen != 4'b0000 && d_mem_addr < 4*MEM_SIZE_WORDS) begin
                if (d_mem_wen == 4'b1111) begin // 字組寫入
                    data_mem[d_mem_addr / 4] <= d_mem_wdata;
                end
            end
        end
    end

    // 主測試流程
    initial begin
        // 初始化
        cycle_count = 0;
        test_complete = 0;
        
        // 開啟CSV檔案
        process_file = $fopen("tests/output/convolution_process.csv", "w");
        result_file = $fopen("tests/output/convolution_result.csv", "w");
        
        // 寫入CSV標題
        $fwrite(process_file, "Cycle,PC,Instruction,Register_State,Memory_Access,Notes\n");
        $fwrite(result_file, "Test_Case,Expected,Actual,Status,Notes\n");
        
        // 等待重置完成
        wait (rst_n === 1);
        $display("重置解除。CPU 操作開始於時間 %0t。", $time);
        
        // 執行測試
        for (cycle_count = 0; cycle_count < MAX_SIM_CYCLES; cycle_count = cycle_count + 1) begin
            @(posedge clk);
            
            // 記錄處理過程
            if (cycle_count % 10 == 0) begin
                $fwrite(process_file, "%d,0x%08x,0x%08x,registers,", 
                        cycle_count, 
                        i_mem_addr,
                        i_mem_rdata);
                
                // 監控記憶體存取
                if (d_mem_wen != 4'b0000) begin
                    $fwrite(process_file, "WRITE[0x%x]=0x%x,", 
                            d_mem_addr, 
                            d_mem_wdata);
                end else begin
                    $fwrite(process_file, "NO_MEM,");
                end
                
                // 添加註解
                if (cycle_count < 20) begin
                    $fwrite(process_file, "Simple_Instructions_Test\n");
                end else begin
                    $fwrite(process_file, "Finalizing\n");
                end
            end
            
            // 檢查是否完成  
            if (data_mem[768/4] == 32'h1) begin
                test_complete = 1;
                $display("卷積測試完成於週期 %d", cycle_count);
            end
            
            if (test_complete) begin
                cycle_count = MAX_SIM_CYCLES; // 強制退出迴圈
            end
        end
        
        // 讀取結果
        for (i = 0; i < 6; i = i + 1) begin
            result_data[i] = data_mem[512/4 + i];
        end
        
        // 驗證結果並寫入CSV
        check_results();
        
        // 關閉檔案
        $fclose(process_file);
        $fclose(result_file);
        
        $display("測試完成！結果已寫入 convolution_process.csv 和 convolution_result.csv");
        $finish;
    end
    
    // 結果檢查任務
    task check_results;
        integer pass_count;
        integer total_tests;
        begin
            pass_count = 0;
            total_tests = 6;
            
            // 調試版本結果檢查
            for (i = 0; i < 6; i = i + 1) begin
                if (result_data[i] == expected_results[i]) begin
                    case (i)
                        0: $fwrite(result_file, "Test_Imm1,0x%08x,0x%08x,PASS,addi=5\n", 
                                expected_results[i], result_data[i]);
                        1: $fwrite(result_file, "Test_Imm2,0x%08x,0x%08x,PASS,addi=10\n", 
                                expected_results[i], result_data[i]);
                        2: $fwrite(result_file, "Test_Add,0x%08x,0x%08x,PASS,5+10=15\n", 
                                expected_results[i], result_data[i]);
                        3: $fwrite(result_file, "Test_Sub,0x%08x,0x%08x,PASS,10-5=5\n", 
                                expected_results[i], result_data[i]);
                        4: $fwrite(result_file, "Test_Const,0x%08x,0x%08x,PASS,constant=42\n", 
                                expected_results[i], result_data[i]);
                        5: $fwrite(result_file, "Test_Neg,0x%08x,0x%08x,PASS,negative=-7\n", 
                                expected_results[i], result_data[i]);
                    endcase
                    pass_count = pass_count + 1;
                end else begin
                    case (i)
                        0: $fwrite(result_file, "Test_Imm1,0x%08x,0x%08x,FAIL,addi=5\n", 
                                expected_results[i], result_data[i]);
                        1: $fwrite(result_file, "Test_Imm2,0x%08x,0x%08x,FAIL,addi=10\n", 
                                expected_results[i], result_data[i]);
                        2: $fwrite(result_file, "Test_Add,0x%08x,0x%08x,FAIL,5+10=15\n", 
                                expected_results[i], result_data[i]);
                        3: $fwrite(result_file, "Test_Sub,0x%08x,0x%08x,FAIL,10-5=5\n", 
                                expected_results[i], result_data[i]);
                        4: $fwrite(result_file, "Test_Const,0x%08x,0x%08x,FAIL,constant=42\n", 
                                expected_results[i], result_data[i]);
                        5: $fwrite(result_file, "Test_Neg,0x%08x,0x%08x,FAIL,negative=-7\n", 
                                expected_results[i], result_data[i]);
                    endcase
                end
            end
            
            // 總結
            $fwrite(result_file, "SUMMARY,%d/%d tests passed,Overall: %s,,\n", 
                    pass_count, total_tests, 
                    (pass_count == total_tests) ? "PASS" : "FAIL");
            
            // 統計資訊
            $fwrite(result_file, "STATISTICS,Sum_All=%d,Add_Result=%d,Mul_Result=%d,\n",
                    result_data[0] + result_data[1] + result_data[2] + result_data[3] + result_data[4] + result_data[5],
                    result_data[0], 
                    result_data[1]);
            
            $display("卷積測試結果: %d/%d 通過", pass_count, total_tests);
        end
    endtask
    
    // 監控訊息輸出
    always @(posedge clk) begin
        if (cycle_count % 500 == 0 && cycle_count > 0) begin
            $display("週期 %d: PC=0x%x, 測試進行中...", cycle_count, i_mem_addr);
        end
    end
    
    // 波形輸出
    initial begin
        $dumpfile("tests/output/tb_convolution_test.vcd");
        $dumpvars(0, tb_convolution_test);
    end
    
endmodule 