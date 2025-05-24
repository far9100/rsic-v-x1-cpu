// RISC-V 32IM CPU - 指令擷取（IF）階段
// 檔案：hardware/rtl/if_stage.v

`timescale 1ns / 1ps

module if_stage (
    input  wire        clk,
    input  wire        rst_n,

    // 分支/跳躍處理的輸入（來自危險檢測單元）
    input  wire        pc_write_en,       // 啟用 PC 更新
    input  wire        branch_taken,      // 指示分支是否被採用
    input  wire [31:0] branch_target_addr, // 分支/跳躍的目標位址

    // 指令記憶體介面
    output wire [31:0] i_mem_addr,       // 指令記憶體位址
    input  wire [31:0] i_mem_rdata,      // 從記憶體讀取的指令

    // 輸出到 IF/ID 管線暫存器
    output wire [31:0] if_id_pc_plus_4_o, // PC + 4
    output wire [31:0] if_id_instr_o,      // 擷取的指令
    output wire [31:0] if_pc_o             // 當前 PC（用於分支計算）
);

    reg [31:0] pc_reg; // 程式計數器

    // PC 更新邏輯
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_reg <= 32'h00000000; // 重置 PC 為 0（或特定起始位址）
        end else begin
            if (pc_write_en) begin // 由危險檢測單元控制停滯
                if (branch_taken) begin
                    pc_reg <= branch_target_addr; // 跳躍或採用分支
                end else begin
                    pc_reg <= pc_reg + 4;         // 順序執行
                end
            end
            // 如果 pc_write_en 為 0，PC 保持不變（停滯）
        end
    end

    // 輸出
    assign i_mem_addr = pc_reg;          // 將當前 PC 送到指令記憶體
    assign if_id_instr_o = i_mem_rdata;  // 將擷取的指令傳遞到下一階段
    assign if_id_pc_plus_4_o = pc_reg + 4; // 計算下一階段的 PC+4（用於分支/跳躍）
    assign if_pc_o = pc_reg;             // 輸出當前 PC

endmodule
