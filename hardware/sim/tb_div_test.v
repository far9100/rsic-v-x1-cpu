// RISC-V 32IM CPU - 除法指令測試台
// 檔案：hardware/sim/tb_div_test.v

`timescale 1ns / 1ps

module tb_div_test;

    // 時脈和重置信號
    reg clk;
    reg rst_n;

    // 檔案操作
    integer output_file;
    
    // 測試結果變數
    reg [3:0] passed_tests;

    // 記憶體介面信號
    wire [31:0] i_mem_addr;
    wire [31:0] i_mem_rdata;
    wire [31:0] d_mem_addr;
    wire [31:0] d_mem_wdata;
    wire [3:0]  d_mem_wen;
    wire [31:0] d_mem_rdata;
    
    // CPU 例項化
    cpu_top u_cpu (
        .clk(clk),
        .rst_n(rst_n),
        .i_mem_addr(i_mem_addr),
        .i_mem_rdata(i_mem_rdata),
        .d_mem_addr(d_mem_addr),
        .d_mem_wdata(d_mem_wdata),
        .d_mem_wen(d_mem_wen),
        .d_mem_rdata(d_mem_rdata),
        .regs_flat()
    );
    
    // 記憶體模型例項化
    mem_model u_mem (
        .clk(clk),
        .rst_n(rst_n),
        .i_mem_addr(i_mem_addr),
        .i_mem_rdata(i_mem_rdata),
        .d_mem_addr(d_mem_addr),
        .d_mem_wdata(d_mem_wdata),
        .d_mem_wen(d_mem_wen),
        .d_mem_rdata(d_mem_rdata)
    );

    // 時脈產生（50MHz，週期 20ns）
    always #10 clk = ~clk;

    initial begin
        // 初始化信號
        clk = 0;
        rst_n = 0;

        // 開啟輸出檔案
        output_file = $fopen("div_sim", "w");

        if (output_file == 0) begin
            $display("錯誤：無法開啟輸出檔案");
            $finish;
        end

        // 寫入 CSV 標頭
        $fwrite(output_file, "Cycle,PC,Instruction,x3,x6,x9,x12,x15,x18,x21,x24,x27\n");

        // 重置釋放
        repeat(5) @(posedge clk);
        rst_n = 1;

        $display("開始除法指令測試...");

        // 運行測試，監控 CPU 狀態
        repeat(1000) begin
            @(posedge clk);
            
            // 記錄 CPU 狀態到 CSV
            $fwrite(output_file, "%d,%h,%h,%d,%d,%d,%d,%d,%d,%d,%h,%h\n",
                    $time/20,                           // 週期
                    u_cpu.u_if_stage.if_pc_o,         // PC
                    u_cpu.u_if_stage.if_id_instr_o,   // 指令
                    $signed(u_cpu.u_id_stage.u_reg_file.registers[3]),  // x3 (7)
                    $signed(u_cpu.u_id_stage.u_reg_file.registers[6]),  // x6 (-7)
                    $signed(u_cpu.u_id_stage.u_reg_file.registers[9]),  // x9 (25)
                    $signed(u_cpu.u_id_stage.u_reg_file.registers[12]), // x12 (1)
                    $signed(u_cpu.u_id_stage.u_reg_file.registers[15]), // x15 (-1)
                    $signed(u_cpu.u_id_stage.u_reg_file.registers[18]), // x18 (9)
                    $signed(u_cpu.u_id_stage.u_reg_file.registers[21]), // x21 (-1)
                    u_cpu.u_id_stage.u_reg_file.registers[24],          // x24 (0xFFFFFFFF)
                    u_cpu.u_id_stage.u_reg_file.registers[27]           // x27 (-2^31)
            );
        end

        // 驗證最終結果
        $display("\n=== 除法指令測試結果 ===");
        
        // 驗證結果
        passed_tests = 0;
        
        if (u_cpu.u_id_stage.u_reg_file.registers[3] == 32'd7) begin
            $display("✓ 測試 1 通過：DIV 84/12 = %d", $signed(u_cpu.u_id_stage.u_reg_file.registers[3]));
            passed_tests = passed_tests + 1;
        end else begin
            $display("✗ 測試 1 失敗：DIV 84/12 = %d (預期：7)", $signed(u_cpu.u_id_stage.u_reg_file.registers[3]));
        end

        if (u_cpu.u_id_stage.u_reg_file.registers[6] == 32'hFFFFFFF9) begin
            $display("✓ 測試 2 通過：DIV -84/12 = %d", $signed(u_cpu.u_id_stage.u_reg_file.registers[6]));
            passed_tests = passed_tests + 1;
        end else begin
            $display("✗ 測試 2 失敗：DIV -84/12 = %d (預期：-7)", $signed(u_cpu.u_id_stage.u_reg_file.registers[6]));
        end

        if (u_cpu.u_id_stage.u_reg_file.registers[9] == 32'd25) begin
            $display("✓ 測試 3 通過：DIVU 100/4 = %d", u_cpu.u_id_stage.u_reg_file.registers[9]);
            passed_tests = passed_tests + 1;
        end else begin
            $display("✗ 測試 3 失敗：DIVU 100/4 = %d (預期：25)", u_cpu.u_id_stage.u_reg_file.registers[9]);
        end

        $display("\n=== 最終結果 ===");
        if (passed_tests >= 7) begin
            $display("🎉 大部分除法指令測試通過！(%d/9)", passed_tests);
        end else begin
            $display("❌ 測試失敗：%d/9 測試通過", passed_tests);
        end

        // 關閉檔案並結束測試
        $fclose(output_file);
        $display("測試完成，結果已儲存至 div_sim");
        $finish;
    end

endmodule 