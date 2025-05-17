// RISC-V 32IM CPU - 暫存器檔案
// 檔案：hardware/rtl/reg_file.v

`timescale 1ns / 1ps

module reg_file (
    input  wire        clk,
    input  wire        rst_n,

    // 讀取埠
    input  wire [4:0]  rs1_addr,       // 讀取埠 1 的位址（rs1）
    input  wire [4:0]  rs2_addr,       // 讀取埠 2 的位址（rs2）
    output wire [31:0] rs1_data,       // 讀取埠 1 的資料
    output wire [31:0] rs2_data,       // 讀取埠 2 的資料

    // 寫入埠（來自 WB 階段）
    input  wire [4:0]  rd_addr,        // 寫入埠的位址（rd）
    input  wire [31:0] rd_data,        // 要寫入的資料
    input  wire        wen             // 寫入致能
);

    // 32 個暫存器，每個 32 位元寬
    reg [31:0] registers [0:31];

    integer i;

    // 寫入操作（同步）
    // 在時脈正緣且寫入致能為高時執行
    // 且 rd_addr 不為 x0
    always @(posedge clk) begin
        if (wen && (rd_addr != 5'b00000)) begin // 不寫入 x0
            registers[rd_addr] <= rd_data;
            // $display("暫存器寫入：x%0d = %h", rd_addr, rd_data);
        end
    end

    // 讀取操作（非同步）
    // x0 永遠讀取為 0
    assign rs1_data = (rs1_addr == 5'b00000) ? 32'b0 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 5'b00000) ? 32'b0 : registers[rs2_addr];

    // 暫存器讀取的除錯輸出
    // always @(*) begin
    //     if (rs1_addr != 0) $display("暫存器讀取：rs1_addr=%0d, data=%h", rs1_addr, registers[rs1_addr]);
    //     if (rs2_addr != 0) $display("暫存器讀取：rs2_addr=%0d, data=%h", rs2_addr, registers[rs2_addr]);
    // end

    // 重置邏輯（可選，可作為模擬中的初始化部分）
    // 對於合成，可能需要明確的重置
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end
    end

endmodule
