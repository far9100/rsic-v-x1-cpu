// RISC-V 32I CPU - 簡單 JAL 指令測試台
// 檔案：hardware/sim/tb_simple_jal_test.v

`timescale 1ns / 1ps

module tb_simple_jal_test;

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

    // 調試信號
    wire [31:0] current_pc = u_cpu.u_if_stage.pc_reg;
    wire [31:0] current_instr = i_mem_rdata;
    wire branch_taken = u_cpu.branch_taken;
    wire [31:0] branch_target = u_cpu.branch_target_addr;
    wire ex_is_jal = u_cpu.ex_is_jal;
    wire ex_is_jalr = u_cpu.ex_is_jalr;

    // 測試程序
    initial begin
        // 初始化
        rst_n = 0;
        #20;
        rst_n = 1;

        // 載入測試程式
        $readmemh("./tests/hex_outputs/simple_jal_test.hex", instruction_memory);

        // 顯示程式內容
        $display("=== 程式內容 ===");
        $display("0x00: %08x", instruction_memory[0]);
        $display("0x04: %08x", instruction_memory[1]);
        $display("0x08: %08x", instruction_memory[2]);
        $display("0x0C: %08x", instruction_memory[3]);
        $display("0x10: %08x", instruction_memory[4]);
        $display("0x14: %08x", instruction_memory[5]);
        $display("0x18: %08x", instruction_memory[6]);
        $display("0x1C: %08x", instruction_memory[7]);

        // 運行測試並監控
        repeat (50) begin
            @(posedge clk);
            $display("PC=0x%08x, Instr=0x%08x, x6=%d, x7=0x%08x, JAL=%b, JALR=%b, BrTaken=%b, BrTarget=0x%08x", 
                     current_pc, current_instr, 
                     u_cpu.u_id_stage.u_reg_file.registers[6],
                     u_cpu.u_id_stage.u_reg_file.registers[7],
                     ex_is_jal, ex_is_jalr, branch_taken, branch_target);
        end

        // 檢查結果
        $display("=== 簡單 JAL 測試結果 ===");
        $display("x6 (結果暫存器) = %10d", u_cpu.u_id_stage.u_reg_file.registers[6]);
        $display("x7 (返回地址) = 0x%08x", u_cpu.u_id_stage.u_reg_file.registers[7]);
        
        if (u_cpu.u_id_stage.u_reg_file.registers[6] == 20) begin
            $display("✓ JAL 測試通過！");
        end else begin
            $display("✗ JAL 測試失敗！預期：20，實際：%d", u_cpu.u_id_stage.u_reg_file.registers[6]);
        end

        $finish;
    end

endmodule 