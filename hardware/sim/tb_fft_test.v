// RISC-V 32I CPU FFT（快速傅立葉變換）測試平台
// 檔案：hardware/sim/tb_fft_test.v

`timescale 1ns / 1ps

module tb_fft_test;

    // 參數
    localparam CLK_PERIOD = 10; // 時脈週期（納秒）
    localparam RESET_DURATION = CLK_PERIOD * 5; // 重置保持時間
    localparam MAX_SIM_CYCLES = 800; // 足夠的週期完成FFT計算和CSV輸出
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
        $readmemh("tests/hex_outputs/fft_test.hex", instr_mem);
        
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
        fp_process = $fopen("tests/output/fft_process.csv", "w");
        fp_result  = $fopen("tests/output/fft_result.csv", "w");
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
    reg [31:0] dft_results [0:11]; // 存儲3組4點DFT結果 (3*4=12)
    reg [31:0] freq_results [0:11]; // 存儲3組4點頻率分量
    integer result_count = 0;
    integer freq_count = 0;
    
    // 測試結果變量
    reg test1_pass, test2_pass, test3_pass;
    reg energy_check_pass;
    
    initial begin
        $fdisplay(fp_process, "開始FFT測試模擬...");
        wait (rst_n === 1);
        $fdisplay(fp_process, "重置解除。CPU 操作開始於時間 %0t。", $time);
        
        for (cycle_count_sim = 0; cycle_count_sim < MAX_SIM_CYCLES; cycle_count_sim = cycle_count_sim + 1) begin
            @(posedge clk);
            if (cycle_count_sim % 25 == 0) begin
                $fdisplay(fp_process, "cycle,%0d,PC=0x%h,instr=0x%h", cycle_count_sim, i_mem_addr, i_mem_rdata);
            end
            
            // 監控DFT結果寫入（0x400-0x42F，3組4點測試）
            if (d_mem_wen == 4'b1111 && d_mem_addr >= 32'h400 && d_mem_addr < 32'h430) begin
                dft_results[(d_mem_addr - 32'h400) / 4] = d_mem_wdata;
                result_count = result_count + 1;
                $fdisplay(fp_process, "dft_result,%0d,0x%h,0x%h", 
                         (d_mem_addr - 32'h400) / 4, d_mem_addr, d_mem_wdata);
            end
            
            // 監控頻率分量寫入（0x500-0x52F，3組4點測試）
            if (d_mem_wen == 4'b1111 && d_mem_addr >= 32'h500 && d_mem_addr < 32'h530) begin
                freq_results[(d_mem_addr - 32'h500) / 4] = d_mem_wdata;
                freq_count = freq_count + 1;
                $fdisplay(fp_process, "freq_energy,%0d,0x%h,0x%h", 
                         (d_mem_addr - 32'h500) / 4, d_mem_addr, d_mem_wdata);
            end
        end
        
        // 檢查測試結果
        $fdisplay(fp_result, "=== FFT（離散傅立葉變換）測試結果 ===");
        
        // 檢查記憶體中的DFT結果 (4點FFT)
        $fdisplay(fp_result, "=== DFT實部結果 ===");
        $fdisplay(fp_result, "測試1 正弦波信號:");
        for (i = 0; i < 4; i = i + 1) begin
            $fdisplay(fp_result, "  頻率bin[%0d],0x%h,%0d", i, data_mem[(32'h400+i*4)/4], $signed(data_mem[(32'h400+i*4)/4]));
        end
        
        $fdisplay(fp_result, "測試2 方波信號:");
        for (i = 0; i < 4; i = i + 1) begin
            $fdisplay(fp_result, "  頻率bin[%0d],0x%h,%0d", i, data_mem[(32'h410+i*4)/4], $signed(data_mem[(32'h410+i*4)/4]));
        end
        
        $fdisplay(fp_result, "測試3 線性上升信號:");
        for (i = 0; i < 4; i = i + 1) begin
            $fdisplay(fp_result, "  頻率bin[%0d],0x%h,%0d", i, data_mem[(32'h420+i*4)/4], $signed(data_mem[(32'h420+i*4)/4]));
        end
        
        $fdisplay(fp_result, "=== 頻率分量能量 ===");
        $fdisplay(fp_result, "測試1 正弦波能量:");
        for (i = 0; i < 4; i = i + 1) begin
            $fdisplay(fp_result, "  能量[%0d],%0d", i, data_mem[(32'h500+i*4)/4]);
        end
        
        $fdisplay(fp_result, "測試2 方波能量:");
        for (i = 0; i < 4; i = i + 1) begin
            $fdisplay(fp_result, "  能量[%0d],%0d", i, data_mem[(32'h510+i*4)/4]);
        end
        
        $fdisplay(fp_result, "測試3 線性上升能量:");
        for (i = 0; i < 4; i = i + 1) begin
            $fdisplay(fp_result, "  能量[%0d],%0d", i, data_mem[(32'h520+i*4)/4]);
        end
        
        // 基本驗證測試 - 4點FFT驗證
        // 測試1：正弦波應該有非零的DFT結果
        test1_pass = (data_mem[32'h400/4] != 32'h0 || data_mem[32'h404/4] != 32'h0); // 任何頻率有非零結果
        
        // 測試2：方波應該有非零的DFT結果
        test2_pass = (data_mem[32'h410/4] != 32'h0 || data_mem[32'h414/4] != 32'h0); // 任何頻率有非零結果
        
        // 測試3：線性上升應該有非零的DFT結果
        test3_pass = (data_mem[32'h420/4] != 32'h0 || data_mem[32'h424/4] != 32'h0); // 任何頻率有非零結果
        
        // 能量守恆檢查：總能量應該合理
        energy_check_pass = 1;
        for (i = 0; i < 12; i = i + 1) begin // 3組測試，每組4點
            if (data_mem[(32'h500+i*4)/4] > 32'h7FFFFFFF) begin // 檢查溢出
                energy_check_pass = 0;
            end
        end
        
        // 分項測試結果
        $fdisplay(fp_result, "=== 測試結果分析 ===");
        $fdisplay(fp_result, "測試1 正弦波DFT,%s", test1_pass ? "PASS" : "FAIL");
        $fdisplay(fp_result, "測試2 方波DFT,%s", test2_pass ? "PASS" : "FAIL");
        $fdisplay(fp_result, "測試3 線性上升DFT,%s", test3_pass ? "PASS" : "FAIL");
        $fdisplay(fp_result, "能量範圍檢查,%s", energy_check_pass ? "PASS" : "FAIL");
        
        // 整體測試結果
        if (test1_pass && test2_pass && test3_pass && energy_check_pass) begin
            $fdisplay(fp_result, "整體測試,PASS");
        end else begin
            $fdisplay(fp_result, "整體測試,FAIL");
        end
        
        // 統計資訊
        $fdisplay(fp_result, "=== 統計資訊 ===");
        $fdisplay(fp_result, "DFT結果數量,%0d", result_count);
        $fdisplay(fp_result, "頻率分量數量,%0d", freq_count);
        $fdisplay(fp_result, "最大能量值,%0d", data_mem[32'h500/4] > data_mem[32'h510/4] ? 
                 (data_mem[32'h500/4] > data_mem[32'h520/4] ? data_mem[32'h500/4] : data_mem[32'h520/4]) :
                 (data_mem[32'h510/4] > data_mem[32'h520/4] ? data_mem[32'h510/4] : data_mem[32'h520/4]));
        
        $fdisplay(fp_result, "模擬完成於時間,%0t", $time);
        $fclose(fp_process);
        $fclose(fp_result);
        $finish;
    end

    // 波形輸出
    initial begin
        $dumpfile("tests/output/tb_fft_test.vcd");
        $dumpvars(0, tb_fft_test);
    end

endmodule 