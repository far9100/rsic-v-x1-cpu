// RISC-V 32IM CPU - EX/MEM 管線暫存器
// 檔案：hardware/rtl/pipeline_reg_ex_mem.v

`timescale 1ns / 1ps

module pipeline_reg_ex_mem (
    input  wire        clk,
    input  wire        rst_n,
    // input  wire        ex_mem_flush_en, // 來自危害單元（例如：在 MEM 階段檢測到分支預測錯誤）

    // 來自 EX 階段的輸入（資料路徑）
    input  wire [31:0] ex_alu_result_i,    // 來自 EX 階段的 ALU/乘法器結果
    input  wire [31:0] ex_rs2_data_i,      // rs2 資料（用於儲存指令）
    input  wire [4:0]  ex_rd_addr_i,       // 目標暫存器位址
    input  wire        ex_zero_flag_i,     // 來自 ALU 的零旗標
    input  wire [31:0] ex_pc_plus_4_i,     // PC+4（用於 JAL/JALR）

    // 來自 ID/EX 暫存器的輸入（通過 EX 階段的控制信號）
    // MEM 控制
    input  wire        ex_mem_read_i,
    input  wire        ex_mem_write_i,
    // WB 控制
    input  wire        ex_reg_write_i,
    input  wire [1:0]  ex_mem_to_reg_i,

    // 輸出到 MEM 階段（資料路徑）
    output reg [31:0] mem_alu_result_o,
    output reg [31:0] mem_rs2_data_o,    // 要寫入記憶體的資料
    output reg [4:0]  mem_rd_addr_o,
    output reg        mem_zero_flag_o,
    output reg [31:0] mem_pc_plus_4_o,   // PC+4（傳遞到 WB 階段）

    // 輸出到 MEM 階段（控制信號）
    // MEM 控制
    output reg        mem_mem_read_o,
    output reg        mem_mem_write_o,
    // WB 控制（傳遞到 MEM/WB 暫存器）
    output reg        mem_reg_write_o,
    output reg [1:0]  mem_mem_to_reg_o
);

    // 氣泡（NOP）的預設控制信號
    localparam NOP_MEM_READ   = 1'b0;
    localparam NOP_MEM_WRITE  = 1'b0;
    localparam NOP_REG_WRITE  = 1'b0;
    localparam [1:0] NOP_MEM_TO_REG = 2'b00;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 重置為類似 NOP 的狀態
            mem_alu_result_o <= 32'b0;
            mem_rs2_data_o   <= 32'b0;
            mem_rd_addr_o    <= 5'b0;
            mem_zero_flag_o  <= 1'b0;
            mem_pc_plus_4_o  <= 32'b0;

            mem_mem_read_o   <= NOP_MEM_READ;
            mem_mem_write_o  <= NOP_MEM_WRITE;
            mem_reg_write_o  <= NOP_REG_WRITE;
            mem_mem_to_reg_o <= NOP_MEM_TO_REG;
        end
        // else if (ex_mem_flush_en) begin // 如果因分支預測錯誤等原因需要清除
        //     // 插入 NOP（或等效的氣泡）
        //     mem_alu_result_o <= 32'b0; // 資料路徑對 NOP 不重要
        //     mem_rs2_data_o   <= 32'b0;
        //     mem_rd_addr_o    <= 5'b0; // NOP 的 rd = x0
        //     mem_zero_flag_o  <= 1'b0;
        //     mem_pc_plus_4_o  <= 32'b0;

        //     mem_mem_read_o   <= NOP_MEM_READ;
        //     mem_mem_write_o  <= NOP_MEM_WRITE;
        //     mem_reg_write_o  <= NOP_REG_WRITE; // 關鍵：NOP 不寫入暫存器
        //     mem_mem_to_reg_o <= NOP_MEM_TO_REG;
        // end
        else begin // 正常運作：鎖存輸入
            mem_alu_result_o <= ex_alu_result_i;
            mem_rs2_data_o   <= ex_rs2_data_i;
            mem_rd_addr_o    <= ex_rd_addr_i;
            mem_zero_flag_o  <= ex_zero_flag_i;
            mem_pc_plus_4_o  <= ex_pc_plus_4_i;

            mem_mem_read_o   <= ex_mem_read_i;
            mem_mem_write_o  <= ex_mem_write_i;
            mem_reg_write_o  <= ex_reg_write_i;
            mem_mem_to_reg_o <= ex_mem_to_reg_i;
        end
    end

endmodule
