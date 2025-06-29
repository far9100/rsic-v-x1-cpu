// 記憶體模型 - 用於測試CPU
// 檔案：hardware/sim/mem_model.v

`timescale 1ns / 1ps

module mem_model (
    input  wire        clk,
    input  wire        rst_n,
    
    // 指令記憶體介面
    input  wire [31:0] i_mem_addr,
    output reg  [31:0] i_mem_rdata,
    
    // 資料記憶體介面
    input  wire [31:0] d_mem_addr,
    input  wire [31:0] d_mem_wdata,
    input  wire [3:0]  d_mem_wen,
    output reg  [31:0] d_mem_rdata
);

    // 指令記憶體 (4KB)
    reg [31:0] i_memory [0:1023];
    
    // 資料記憶體 (4KB)
    reg [31:0] d_memory [0:1023];
    
    // 用於初始化的變數
    integer i;
    
    // 初始化記憶體
    initial begin
        // 載入測試程序
        $readmemh("tests/hex_outputs/div_integrated_test.hex", i_memory);
        
        // 清除資料記憶體
        for (i = 0; i < 1024; i = i + 1) begin
            d_memory[i] = 32'h00000000;
        end
    end
    
    // 指令記憶體讀取
    always @(*) begin
        if (i_mem_addr[31:2] < 1024) begin
            i_mem_rdata = i_memory[i_mem_addr[31:2]];
        end else begin
            i_mem_rdata = 32'h00000000; // NOP
        end
    end
    
    // 資料記憶體讀寫
    always @(*) begin
        if (d_mem_addr[31:2] < 1024) begin
            d_mem_rdata = d_memory[d_mem_addr[31:2]];
        end else begin
            d_mem_rdata = 32'h00000000;
        end
    end
    
    always @(posedge clk) begin
        if (d_mem_wen != 4'b0000 && d_mem_addr[31:2] < 1024) begin
            d_memory[d_mem_addr[31:2]] <= d_mem_wdata;
        end
    end

endmodule 