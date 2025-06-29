// RISC-V 32IM CPU 完整除法測試平台
// 檔案：hardware/sim/tb_div_integrated_test.v

`timescale 1ns / 1ps

module tb_div_integrated_test;

    // 參數
    localparam CLK_PERIOD = 10; // 時脈週期（納秒）
    localparam RESET_DURATION = CLK_PERIOD * 5; // 重置保持時間
    localparam MAX_SIM_CYCLES = 500; // 較長的模擬週期數
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
        $readmemh("tests/hex_outputs/div_integrated_test.hex", instr_mem);
        
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
        fp_process = $fopen("div_integrated_process.csv", "w");
        fp_result  = $fopen("div_integrated_result.csv", "w");
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
        $fdisplay(fp_process, "開始完整除法測試模擬...");
        wait (rst_n === 1);
        $fdisplay(fp_process, "重置解除。CPU 操作開始於時間 %0t。", $time);
        
        for (cycle_count_sim = 0; cycle_count_sim < MAX_SIM_CYCLES; cycle_count_sim = cycle_count_sim + 1) begin
            @(posedge clk);
            if (cycle_count_sim % 10 == 0) begin
                $fdisplay(fp_process, "cycle,%0d,PC=0x%h,instr=0x%h", cycle_count_sim, i_mem_addr, i_mem_rdata);
            end
        end
        
        // 檢查測試結果
        $fdisplay(fp_result, "=== 完整除法測試結果 ===");
        
        // 檢查暫存器值 (9個測試)
        $fdisplay(fp_result, "=== 暫存器狀態 ===");
        $fdisplay(fp_result, "x3 (84/12),%0d", $signed(regs_flat_local[3*32 +: 32]));
        $fdisplay(fp_result, "x6 (-84/12),%0d", $signed(regs_flat_local[6*32 +: 32]));
        $fdisplay(fp_result, "x9 (100u/4u),%0d", $signed(regs_flat_local[9*32 +: 32]));
        $fdisplay(fp_result, "x12 (85%%12),%0d", $signed(regs_flat_local[12*32 +: 32]));
        $fdisplay(fp_result, "x15 (-85%%12),%0d", $signed(regs_flat_local[15*32 +: 32]));
        $fdisplay(fp_result, "x18 (87u%%13u),%0d", $signed(regs_flat_local[18*32 +: 32]));
        $fdisplay(fp_result, "x21 (10/0),%0d", $signed(regs_flat_local[21*32 +: 32]));
        $fdisplay(fp_result, "x24 (10u/0u),0x%h", regs_flat_local[24*32 +: 32]);
        $fdisplay(fp_result, "x27 (-2^31/-1),0x%h", regs_flat_local[27*32 +: 32]);
        
        // 檢查記憶體中的結果
        $fdisplay(fp_result, "=== 記憶體結果 ===");
        $fdisplay(fp_result, "mem[0x400] (84/12),%0d", $signed(data_mem[32'h400/4]));
        $fdisplay(fp_result, "mem[0x404] (-84/12),%0d", $signed(data_mem[32'h404/4]));
        $fdisplay(fp_result, "mem[0x408] (100u/4u),%0d", $signed(data_mem[32'h408/4]));
        $fdisplay(fp_result, "mem[0x40c] (85%%12),%0d", $signed(data_mem[32'h40c/4]));
        $fdisplay(fp_result, "mem[0x410] (-85%%12),%0d", $signed(data_mem[32'h410/4]));
        $fdisplay(fp_result, "mem[0x414] (87u%%13u),%0d", $signed(data_mem[32'h414/4]));
        $fdisplay(fp_result, "mem[0x418] (10/0),%0d", $signed(data_mem[32'h418/4]));
        $fdisplay(fp_result, "mem[0x41c] (10u/0u),0x%h", data_mem[32'h41c/4]);
        $fdisplay(fp_result, "mem[0x420] (-2^31/-1),0x%h", data_mem[32'h420/4]);
        
        // 整體測試結果 (檢查9個測試案例)
        if ($signed(regs_flat_local[3*32 +: 32]) == 7 &&
            $signed(regs_flat_local[6*32 +: 32]) == -7 &&
            $signed(regs_flat_local[9*32 +: 32]) == 25 &&
            $signed(regs_flat_local[12*32 +: 32]) == 1 &&
            $signed(regs_flat_local[15*32 +: 32]) == -1 &&
            $signed(regs_flat_local[18*32 +: 32]) == 9 &&
            $signed(regs_flat_local[21*32 +: 32]) == -1 &&
            regs_flat_local[24*32 +: 32] == 32'hFFFFFFFF &&
            regs_flat_local[27*32 +: 32] == 32'h80000000) begin
            $fdisplay(fp_result, "整體測試,PASS");
        end else begin
            $fdisplay(fp_result, "整體測試,FAIL");
        end
        
        // 分項測試結果
        $fdisplay(fp_result, "基本除法,%s", ($signed(regs_flat_local[3*32 +: 32]) == 7) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "負數除法,%s", ($signed(regs_flat_local[6*32 +: 32]) == -7) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "無號除法,%s", ($signed(regs_flat_local[9*32 +: 32]) == 25) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "有符號餘數,%s", ($signed(regs_flat_local[12*32 +: 32]) == 1) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "負數餘數,%s", ($signed(regs_flat_local[15*32 +: 32]) == -1) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "無號餘數,%s", ($signed(regs_flat_local[18*32 +: 32]) == 9) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "除零(DIV),%s", ($signed(regs_flat_local[21*32 +: 32]) == -1) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "除零(DIVU),%s", (regs_flat_local[24*32 +: 32] == 32'hFFFFFFFF) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "溢出測試,%s", (regs_flat_local[27*32 +: 32] == 32'h80000000) ? "PASS" : "FAIL");
        
        $fdisplay(fp_result, "模擬完成於時間,%0t", $time);
        $fclose(fp_process);
        $fclose(fp_result);
        $finish;
    end

    // 波形輸出
    initial begin
        $dumpfile("tb_div_integrated_test.vcd");
        $dumpvars(0, tb_div_integrated_test);
    end

    // 調試介面
    wire [1023:0] regs_flat_local;
    assign regs_flat_local = u_cpu.regs_flat;

endmodule 