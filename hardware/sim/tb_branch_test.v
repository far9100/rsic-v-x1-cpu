// RISC-V 32I CPU - 分支測試台
// 檔案：hardware/sim/tb_branch_test.v

`timescale 1ns / 1ps

module tb_branch_test;

    // 時鐘和重置信號
    reg clk;
    reg rst_n;
    
    // 指令記憶體介面
    wire [31:0] i_mem_addr;
    reg  [31:0] i_mem_rdata;
    
    // 資料記憶體介面
    wire [31:0] d_mem_addr;
    wire [31:0] d_mem_wdata;
    wire [3:0]  d_mem_wen;
    reg  [31:0] d_mem_rdata;
    
    // 指令記憶體
    reg [31:0] instruction_memory [0:1023];
    
    // 資料記憶體
    reg [31:0] data_memory [0:1023];
    
    // 實例化 CPU
    cpu_top u_cpu (
        .clk(clk),
        .rst_n(rst_n),
        .i_mem_addr(i_mem_addr),
        .i_mem_rdata(i_mem_rdata),
        .d_mem_addr(d_mem_addr),
        .d_mem_wdata(d_mem_wdata),
        .d_mem_wen(d_mem_wen),
        .d_mem_rdata(d_mem_rdata)
    );
    
    // 宣告 file handle
    integer fp_process, fp_result;
    
    // 時鐘產生
    initial begin
        fp_process = $fopen("tests/output/branch_process.csv", "w");
        fp_result  = $fopen("tests/output/branch_result.csv", "w");
        clk = 0;
        forever #5 clk = ~clk; // 100MHz 時鐘
    end
    
    // 指令記憶體讀取
    always @(*) begin
        if (i_mem_addr[31:2] < 1024) begin
            i_mem_rdata = instruction_memory[i_mem_addr[31:2]];
        end else begin
            i_mem_rdata = 32'h00000013; // NOP
        end
    end
    
    // 資料記憶體存取
    always @(posedge clk) begin
        if (d_mem_wen != 4'b0000 && d_mem_addr[31:2] < 1024) begin
            data_memory[d_mem_addr[31:2]] <= d_mem_wdata;
        end
    end
    
    always @(*) begin
        if (d_mem_addr[31:2] < 1024) begin
            d_mem_rdata = data_memory[d_mem_addr[31:2]];
        end else begin
            d_mem_rdata = 32'h00000000;
        end
    end
    
    // 測試程序
    initial begin
        // 初始化
        rst_n = 0;
        
        // 載入測試程式（分支測試）
        $readmemh("./tests/hex_outputs/branch_integrated_test.hex", instruction_memory);
        
        // 初始化資料記憶體
        for (integer i = 0; i < 1024; i = i + 1) begin
            data_memory[i] = 32'h00000000;
        end
        
        // 重置釋放
        #20;
        rst_n = 1;
        
        // 運行測試
        #50000; // 運行足夠長的時間（增加運行時間）
        
        // 檢查結果
        $fdisplay(fp_result, "=== 分支測試結果 ===");
        $fdisplay(fp_result, "x6,%d", u_cpu.u_id_stage.u_reg_file.registers[6]);
        if (u_cpu.u_id_stage.u_reg_file.registers[6] == 100) begin
            $fdisplay(fp_result, "PASS");
        end else begin
            $fdisplay(fp_result, "FAIL,%d", u_cpu.u_id_stage.u_reg_file.registers[6]);
        end
        // 詳細記錄分支測試每一項
        $fdisplay(fp_result, "=== 分支細項測試 ===");
        $fdisplay(fp_result, "BEQ,%s", (u_cpu.u_id_stage.u_reg_file.registers[1] == 10) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "BNE,%s", (u_cpu.u_id_stage.u_reg_file.registers[2] == 10) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "BLT,%s", (u_cpu.u_id_stage.u_reg_file.registers[3] == 5) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "BGE,%s", (u_cpu.u_id_stage.u_reg_file.registers[4] == 15) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "BLTU,%s", (u_cpu.u_id_stage.u_reg_file.registers[5] == 4294967291) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "BGEU,%s", (u_cpu.u_id_stage.u_reg_file.registers[6] == 100) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "NEGATIVE,%s", (u_cpu.u_id_stage.u_reg_file.registers[7] == 0) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "ZERO,%s", (u_cpu.u_id_stage.u_reg_file.registers[8] == 0) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "NOT_TAKEN,%s", (u_cpu.u_id_stage.u_reg_file.registers[9] == 0) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "SIMPLE_LOOP,%s", (u_cpu.u_id_stage.u_reg_file.registers[10] == 0) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "REAL_LOOP,%s", (u_cpu.u_id_stage.u_reg_file.registers[11] == 3) ? "PASS" : "FAIL");
        $fdisplay(fp_result, "SIGNED_UNSIGNED_DIFF,%s", (u_cpu.u_id_stage.u_reg_file.registers[12] == 3) ? "PASS" : "FAIL");
        // 顯示其他暫存器的值
        $fdisplay(fp_result, "=== 暫存器狀態 ===");
        for (integer i = 1; i < 16; i = i + 1) begin
            $fdisplay(fp_result, "x%0d,%d", i, u_cpu.u_id_stage.u_reg_file.registers[i]);
        end
        // 專門顯示調試信息
        $fdisplay(fp_result, "=== 調試信息 ===");
        $fdisplay(fp_result, "x13,%d", u_cpu.u_id_stage.u_reg_file.registers[13]);
        $fdisplay(fp_result, "x14,%d", u_cpu.u_id_stage.u_reg_file.registers[14]);
        $fdisplay(fp_result, "x15,%d", u_cpu.u_id_stage.u_reg_file.registers[15]);
        $fdisplay(fp_result, "x12,%d", u_cpu.u_id_stage.u_reg_file.registers[12]);
        $fclose(fp_process);
        $fclose(fp_result);
        $finish;
    end
    
    // 監控分支行為
    always @(posedge clk) begin
        if (rst_n && u_cpu.u_ex_stage.u_branch_unit.branch_taken_o) begin
            $fdisplay(fp_process, "%0t,branch_taken,%08x", $time, u_cpu.u_ex_stage.u_branch_unit.branch_target_o);
        end
    end
    
    // 監控指令執行和無限迴圈檢測
    reg [31:0] instruction_count;
    reg [31:0] last_pc;
    reg [31:0] same_pc_count;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            instruction_count <= 0;
            last_pc <= 0;
            same_pc_count <= 0;
        end else begin
            instruction_count <= instruction_count + 1;
            
            // 檢測程式結束（infinite_loop）
            if (i_mem_addr == last_pc) begin
                same_pc_count <= same_pc_count + 1;
                // 如果在 infinite_loop 地址（0x00000134），這是正常的程式結束
                if (i_mem_addr == 32'h00000134 && same_pc_count > 10) begin
                    $fdisplay(fp_result, "程式正常結束於 infinite_loop (PC = 0x%08x)", i_mem_addr);
                    $fdisplay(fp_result, "最終結果檢查...");
                    #100; // 等待一點時間讓暫存器穩定
                    $fclose(fp_process);
                    $fclose(fp_result);
                    $finish;
                end
                // 其他地址的無限迴圈是錯誤
                else if (same_pc_count > 1000) begin
                    $fdisplay(fp_result, "錯誤：檢測到無限迴圈在 PC = 0x%08x", i_mem_addr);
                    $fdisplay(fp_result, "指令 = 0x%08x", i_mem_rdata);
                    $fdisplay(fp_result, "x10,%d", u_cpu.u_id_stage.u_reg_file.registers[10]);
                    $fclose(fp_process);
                    $fclose(fp_result);
                    $finish;
                end
            end else begin
                same_pc_count <= 0;
            end
            last_pc <= i_mem_addr;
            
            // 只顯示前100條指令的執行
            if (instruction_count < 100) begin
                $fdisplay(fp_process, "%0t,PC,%08x,%08x", $time, i_mem_addr, i_mem_rdata);
            end
        end
    end
    
    // 產生波形檔案
    initial begin
        $dumpfile("tests/output/tb_branch_test.vcd");
        $dumpvars(0, tb_branch_test);
    end

endmodule 