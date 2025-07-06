// RISC-V 32I CPU 逻辑指令測試平台
// 檔案：hardware/sim/tb_logic_test.v

`timescale 1ns / 1ps

module tb_logic_test;

    // 參數
    localparam CLK_PERIOD = 10; // 時脈週期（納秒）
    localparam RESET_DURATION = CLK_PERIOD * 5; // 重置保持時間
    localparam MAX_SIM_CYCLES = 300; // 最大模擬週期數
    localparam MEM_SIZE_WORDS = 1024; // 記憶體大小（字組數）

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
    // 指令記憶體
    reg [31:0] instr_mem [0:MEM_SIZE_WORDS-1];
    integer i;
    initial begin
        $readmemh("tests/hex_outputs/logic_integrated_test.hex", instr_mem);
        
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

    // 資料記憶體
    reg [31:0] data_mem [0:MEM_SIZE_WORDS-1];

    // 資料記憶體讀取邏輯
    always @(*) begin
        if (d_mem_addr < 4*MEM_SIZE_WORDS) begin
            d_mem_rdata = data_mem[d_mem_addr / 4];
        end else begin
            d_mem_rdata = 32'hxxxxxxxx;
        end
    end

    // 宣告 file handle
    integer fp_process, fp_result;

    // 資料記憶體寫入邏輯
    always @(posedge clk) begin
        if (rst_n) begin
            if (d_mem_wen != 4'b0000 && d_mem_addr < 4*MEM_SIZE_WORDS) begin
                if (d_mem_wen == 4'b1111) begin
                    data_mem[d_mem_addr / 4] <= d_mem_wdata;
                    $fdisplay(fp_process, "mem_write,%0t,0x%h,0x%h", $time, d_mem_addr, d_mem_wdata);
                end
            end
        end
    end

    // 時脈產生
    initial begin
        fp_process = $fopen("tests/output/logic_process.csv", "w");
        fp_result  = $fopen("tests/output/logic_result.csv", "w");
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
    initial begin
        $fdisplay(fp_process, "開始 RISC-V CPU 逻辑指令測試模擬...");
        wait (rst_n === 1);
        $fdisplay(fp_process, "重置解除。CPU 操作開始於時間 %0t。", $time);
        for (cycle_count_sim = 0; cycle_count_sim < MAX_SIM_CYCLES; cycle_count_sim = cycle_count_sim + 1) begin
            @(posedge clk);
            if (cycle_count_sim % 50 == 0) begin
                $fdisplay(fp_process, "cycle,%0d,%h", cycle_count_sim, i_mem_rdata);
            end
        end
        
        // 驗證結果
        $fdisplay(fp_result, "=== 逻辑指令測試結果 ===");
        if (data_mem[32'h100/4]   == 240   &&    // AND 結果
            data_mem[32'h100/4+1] == 255   &&    // OR 結果  
            data_mem[32'h100/4+2] == 15    &&    // XOR 結果
            data_mem[32'h100/4+3] == 160   &&    // ANDI 結果
            data_mem[32'h100/4+4] == 1525  &&    // ORI 結果
            data_mem[32'h100/4+5] == 1365  &&    // XORI 結果
            data_mem[32'h100/4+6] == 0     &&    // 全零AND
            data_mem[32'h100/4+7] == -1    &&    // 全一OR
            data_mem[32'h100/4+8] == 0     &&    // 自反XOR
            data_mem[32'h100/4+9] == -256  &&    // 負數ANDI
            data_mem[32'h100/4+10] == 170  &&    // ORI小立即數
            data_mem[32'h100/4+11] == -1) begin   // XORI全位元
            $fdisplay(fp_result, "PASS");
        end else begin
            $fdisplay(fp_result, "FAIL");
        end
        
        // 細項測試
        $fdisplay(fp_result, "=== 細項測試 ===");
        $fdisplay(fp_result, "AND,%s", (data_mem[32'h100/4] == 240) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "OR,%s", (data_mem[32'h100/4+1] == 255) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "XOR,%s", (data_mem[32'h100/4+2] == 15) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "ANDI,%s", (data_mem[32'h100/4+3] == 160) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "ORI,%s", (data_mem[32'h100/4+4] == 1525) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "XORI,%s", (data_mem[32'h100/4+5] == 1365) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "全零AND,%s", (data_mem[32'h100/4+6] == 0) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "全一OR,%s", (data_mem[32'h100/4+7] == -1) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "自反XOR,%s", (data_mem[32'h100/4+8] == 0) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "負數ANDI,%s", (data_mem[32'h100/4+9] == -256) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "ORI小立即數,%s", (data_mem[32'h100/4+10] == 170) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "XORI全位元,%s", (data_mem[32'h100/4+11] == -1) ? "PASS" : "FAIL");
        
        // 記憶體狀態
        $fdisplay(fp_result, "=== 記憶體狀態 ===");
        for (i = 0; i < 12; i = i + 1) begin
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
        $dumpfile("tests/output/tb_logic_test.vcd");
        $dumpvars(0, tb_logic_test);
    end

endmodule 