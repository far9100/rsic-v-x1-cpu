// RISC-V 32I CPU - LUI 指令測試台
// 檔案：hardware/sim/tb_lui_test.v

`timescale 1ns / 1ps

module tb_lui_test;

    // 時鐘和重置信號
    reg clk;
    reg rst_n;

    // 指令記憶體信號
    wire [31:0] i_mem_addr;
    wire [31:0] i_mem_rdata;
    
    // 資料記憶體信號
    wire [31:0] d_mem_addr;
    wire [31:0] d_mem_wdata;
    wire [3:0]  d_mem_wen;
    wire [31:0] d_mem_rdata;

    // 指令記憶體
    reg [31:0] instruction_memory [0:1023];
    assign i_mem_rdata = instruction_memory[i_mem_addr[31:2]];

    // 資料記憶體
    reg [31:0] data_memory [0:1023];
    assign d_mem_rdata = data_memory[d_mem_addr[31:2]];
    
    always @(posedge clk) begin
        if (d_mem_wen != 4'b0000) begin
            data_memory[d_mem_addr[31:2]] <= d_mem_wdata;
        end
    end

    // CPU 實例
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
        forever #5 clk = ~clk; // 10ns 週期
    end

    // 測試程序
    initial begin
        // 初始化
        rst_n = 0;
        #20;
        rst_n = 1;

        // 載入測試程式
        $readmemh("./tests/hex_outputs/lui_test.hex", instruction_memory);

        // 運行測試
        #1000; // 運行足夠長的時間

        // 檢查結果
        $display("=== LUI 測試結果 ===");
        $display("x6 (結果暫存器) = %10d", u_cpu.u_id_stage.u_reg_file.registers[6]);
        $display("x20 (LUI 0x80000) = 0x%08x", u_cpu.u_id_stage.u_reg_file.registers[20]);
        $display("x21 (x20 備份) = 0x%08x", u_cpu.u_id_stage.u_reg_file.registers[21]);
        $display("x22 (x20>>31) = %10d", u_cpu.u_id_stage.u_reg_file.registers[22]);
        $display("x23 (LUI 0x12345) = 0x%08x", u_cpu.u_id_stage.u_reg_file.registers[23]);
        $display("x25 (x23>>12) = 0x%08x", u_cpu.u_id_stage.u_reg_file.registers[25]);
        $display("x26 (x25 備份) = 0x%08x", u_cpu.u_id_stage.u_reg_file.registers[26]);

        if (u_cpu.u_id_stage.u_reg_file.registers[6] == 100) begin
            $display("✓ LUI 測試通過！");
        end else begin
            $display("✗ LUI 測試失敗！預期：100，實際：%10d", u_cpu.u_id_stage.u_reg_file.registers[6]);
        end

        $finish;
    end

    // 監控 PC 和指令執行（前幾個週期）
    integer cycle_count = 0;
    always @(posedge clk) begin
        if (rst_n && cycle_count < 50) begin
            $display("時間 %0t: PC = 0x%08x, 指令 = 0x%08x", 
                     $time, i_mem_addr, i_mem_rdata);
            cycle_count = cycle_count + 1;
        end
    end

endmodule 