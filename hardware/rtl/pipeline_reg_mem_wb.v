// RISC-V 32IM CPU - MEM/WB 管線暫存器
// 檔案：hardware/rtl/pipeline_reg_mem_wb.v

`timescale 1ns / 1ps

module pipeline_reg_mem_wb (
    input  wire        clk,
    input  wire        rst_n,

    // 來自 MEM 階段的輸入（資料路徑）
    input  wire [31:0] mem_rdata_i,      // 從記憶體讀取的資料（用於 LW 指令）
    // 來自 EX/MEM 暫存器的輸入（通過 MEM 階段的資料路徑）
    input  wire [31:0] mem_alu_result_i, // ALU 結果
    input  wire [4:0]  mem_rd_addr_i,    // 目標暫存器位址
    input  wire [31:0] mem_pc_plus_4_i,  // PC+4（用於 JAL/JALR）

    // 來自 EX/MEM 暫存器的輸入（通過 MEM 階段的控制信號）
    // WB 控制
    input  wire        mem_reg_write_i,
    input  wire [1:0]  mem_mem_to_reg_i,

    // 輸出到 WB 階段（概念上，這些會回饋到 ID 階段的暫存器檔案）
    // 資料路徑
    output reg [31:0] wb_mem_rdata_o,
    output reg [31:0] wb_alu_result_o,
    output reg [4:0]  wb_rd_addr_o,
    output reg [31:0] wb_pc_plus_4_o,    // PC+4（傳遞到 WB 階段）

    // 控制信號
    output reg        wb_reg_write_o,
    output reg [1:0]  wb_mem_to_reg_o
);

    // 氣泡（NOP）的預設控制信號
    localparam NOP_REG_WRITE  = 1'b0;
    localparam [1:0] NOP_MEM_TO_REG = 2'b00;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 重置為類似 NOP 的狀態
            wb_mem_rdata_o  <= 32'b0;
            wb_alu_result_o <= 32'b0;
            wb_rd_addr_o    <= 5'b0;
            wb_pc_plus_4_o  <= 32'b0;

            wb_reg_write_o  <= NOP_REG_WRITE;
            wb_mem_to_reg_o <= NOP_MEM_TO_REG;
        end else begin
            // 正常運作：鎖存輸入
            wb_mem_rdata_o  <= mem_rdata_i;
            wb_alu_result_o <= mem_alu_result_i;
            wb_rd_addr_o    <= mem_rd_addr_i;
            wb_pc_plus_4_o  <= mem_pc_plus_4_i;

            wb_reg_write_o  <= mem_reg_write_i;
            wb_mem_to_reg_o <= mem_mem_to_reg_i;
        end
    end

endmodule
