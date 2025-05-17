// RISC-V 32IM CPU - 記憶體存取（MEM）階段
// 檔案：hardware/rtl/mem_stage.v

`timescale 1ns / 1ps

module mem_stage (
    input  wire        clk,
    input  wire        rst_n,

    // 來自 EX/MEM 管線暫存器的輸入（資料路徑）
    input  wire [31:0] alu_result_i,   // ALU 結果（用作 LW/SW 的記憶體位址）
    input  wire [31:0] rs2_data_i,     // 來自 rs2 的資料（用於儲存指令）
    // input  wire        zero_flag_i,    // 來自 ALU 的零旗標（如果在此處進行分支決策）
    // input  wire [31:0] pc_plus_4_i,    // PC+4（如果在此處進行分支目標計算）
    // input  wire [31:0] imm_ext_i,      // 立即值（如果在此處進行分支目標計算）

    // 來自 EX/MEM 管線暫存器的輸入（控制信號）
    input  wire        mem_read_i,     // 記憶體讀取啟用（用於 LW）
    input  wire        mem_write_i,    // 記憶體寫入啟用（用於 SW）

    // 資料記憶體介面
    output wire [31:0] d_mem_addr_o,   // 資料記憶體位址
    output wire [31:0] d_mem_wdata_o,  // 要寫入資料記憶體的資料
    output wire [3:0]  d_mem_wen_o,    // 資料記憶體的寫入啟用（位元組級或字組）
    input  wire [31:0] d_mem_rdata_i,  // 從資料記憶體讀取的資料

    // 輸出到 MEM/WB 管線暫存器
    output wire [31:0] mem_rdata_o     // 從記憶體讀取的資料（用於 LW）
    // output wire        branch_taken_o, // 如果在 MEM 階段進行分支決策
    // output wire [31:0] branch_target_addr_o // 如果在 MEM 階段進行分支決策
);

    // 資料記憶體存取邏輯
    assign d_mem_addr_o  = alu_result_i; // ALU 結果用作載入/儲存的位址
    assign d_mem_wdata_o = rs2_data_i;   // rs2_data 是要儲存的資料

    // 產生資料記憶體的寫入啟用信號
    // 假設為字組存取以簡化。對於位元組/半字組，需要根據 funct3 增加更多邏輯。
    assign d_mem_wen_o = mem_write_i ? 4'b1111 : 4'b0000; // 如果 mem_write 啟用則進行完整字組寫入

    // 輸出從記憶體讀取的資料
    assign mem_rdata_o = d_mem_rdata_i; // 直接傳遞從記憶體讀取的資料

    // 分支邏輯（如果在 MEM 階段進行分支決策）
    // 如果使用來自 ALU 的零旗標（在 EX/MEM 暫存器中）則常見於此。
    // wire branch_condition_met = (mem_read_i == `IS_BRANCH_OP` && zero_flag_i == `EXPECTED_ZERO_FOR_BRANCH`);
    // assign branch_taken_o = branch_condition_met;
    // assign branch_target_addr_o = (branch_condition_met) ? (pc_plus_4_i + imm_ext_i - 4) : pc_plus_4_i; // 簡化版

endmodule
