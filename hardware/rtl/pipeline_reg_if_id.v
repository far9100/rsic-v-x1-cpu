// RISC-V 32IM CPU - IF/ID 管線暫存器
// 檔案：hardware/rtl/pipeline_reg_if_id.v

`timescale 1ns / 1ps

module pipeline_reg_if_id (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        if_id_write_en, // 來自危險單元（用於啟用/停用暫存器更新 - 停滯）
    input  wire        if_id_flush_en, // 來自危險單元（用於清除暫存器 - 分支預測錯誤）

    // 來自 IF 階段的輸入
    input  wire [31:0] if_pc_plus_4_i,
    input  wire [31:0] if_instr_i,

    // 輸出到 ID 階段
    output reg [31:0] id_pc_plus_4_o,
    output reg [31:0] id_instr_o
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 重置狀態：通常為 NOP 指令或全 0
            id_pc_plus_4_o <= 32'b0;
            id_instr_o     <= 32'h00000013; // NOP 指令（addi x0, x0, 0）
        end 
        else if (if_id_flush_en) begin
            // 清除：插入 NOP
            id_pc_plus_4_o <= 32'b0; // 或某些預設的 PC 值
            id_instr_o     <= 32'h00000013; // NOP
        end
        else if (if_id_write_en) begin
            // 正常運作：鎖存輸入
            id_pc_plus_4_o <= if_pc_plus_4_i;
            id_instr_o     <= if_instr_i;
        end
        // else begin
        //     // 停滯：保持當前值（不改變暫存器）
        // end
    end

endmodule
