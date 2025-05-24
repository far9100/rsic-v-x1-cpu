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
    
    // 時鐘產生
    initial begin
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
        #10000; // 運行足夠長的時間
        
        // 檢查結果
        $display("=== 分支測試結果 ===");
        $display("x6 (結果暫存器) = %d", u_cpu.u_id_stage.u_reg_file.registers[6]);
        
        // 預期結果：x6 應該等於 100 (簡化版測試)
        if (u_cpu.u_id_stage.u_reg_file.registers[6] == 100) begin
            $display("✓ 分支測試通過！");
        end else begin
            $display("✗ 分支測試失敗！預期：100，實際：%d", 
                    u_cpu.u_id_stage.u_reg_file.registers[6]);
        end
        
        // 顯示其他暫存器的值
        $display("=== 暫存器狀態 ===");
        for (integer i = 1; i < 12; i = i + 1) begin
            $display("x%0d = %d", i, u_cpu.u_id_stage.u_reg_file.registers[i]);
        end
        
        $finish;
    end
    
    // 監控分支行為
    always @(posedge clk) begin
        if (rst_n && u_cpu.u_ex_stage.u_branch_unit.branch_taken_o) begin
            $display("時間 %0t: 分支被採用，目標地址 = 0x%08x", 
                    $time, u_cpu.u_ex_stage.u_branch_unit.branch_target_o);
        end
    end
    
    // 監控指令執行
    always @(posedge clk) begin
        if (rst_n) begin
            $display("時間 %0t: PC = 0x%08x, 指令 = 0x%08x", 
                    $time, i_mem_addr, i_mem_rdata);
        end
    end
    
    // 產生波形檔案
    initial begin
        $dumpfile("tb_branch_test.vcd");
        $dumpvars(0, tb_branch_test);
    end

endmodule 