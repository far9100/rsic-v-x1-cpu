// RISC-V 32IM CPU - ID/EX 管線暫存器
// 檔案：hardware/rtl/pipeline_reg_id_ex.v

`timescale 1ns / 1ps

module pipeline_reg_id_ex (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        id_ex_bubble_i, // 來自危險單元（用於插入氣泡/停滯）
    input  wire        id_ex_flush_en, // 來自危險單元（用於清除暫存器 - 分支預測錯誤）

    // 來自 ID 階段的輸入（資料路徑）
    input  wire [31:0] id_pc_plus_4_i,
    input  wire [31:0] id_rs1_data_i,
    input  wire [31:0] id_rs2_data_i,
    input  wire [31:0] id_imm_ext_i,
    input  wire [4:0]  id_rs1_addr_i, // 用於前遞
    input  wire [4:0]  id_rs2_addr_i, // 用於前遞
    input  wire [4:0]  id_rd_addr_i,

    // 來自 ID 階段的輸入（控制信號）
    // EX 控制
    input  wire        id_alu_src_i,
    input  wire [3:0]  id_alu_op_i,
    // MEM 控制
    input  wire        id_mem_read_i,
    input  wire        id_mem_write_i,
    // WB 控制
    input  wire        id_reg_write_i,
    input  wire [1:0]  id_mem_to_reg_i,
    // 分支控制
    input  wire        id_branch_i,
    input  wire        id_is_jal_i,
    input  wire        id_is_jalr_i,
    input  wire [2:0]  id_funct3_i,      // 分支指令的 funct3 欄位

    // 輸出到 EX 階段（資料路徑）
    output reg [31:0] ex_pc_plus_4_o,
    output reg [31:0] ex_rs1_data_o,
    output reg [31:0] ex_rs2_data_o,
    output reg [31:0] ex_imm_ext_o,
    output reg [4:0]  ex_rs1_addr_o,
    output reg [4:0]  ex_rs2_addr_o,
    output reg [4:0]  ex_rd_addr_o,

    // 輸出到 EX 階段（控制信號）
    // EX 控制
    output reg        ex_alu_src_o,
    output reg [3:0]  ex_alu_op_o,
    // MEM 控制（傳遞到 EX/MEM 暫存器）
    output reg        ex_mem_read_o,
    output reg        ex_mem_write_o,
    // WB 控制（傳遞到 EX/MEM 和 MEM/WB 暫存器）
    output reg        ex_reg_write_o,
    output reg [1:0]  ex_mem_to_reg_o,
    // 分支控制
    output reg        ex_branch_o,
    output reg        ex_is_jal_o,
    output reg        ex_is_jalr_o,
    output reg [2:0]  ex_funct3_o          // 分支指令的 funct3 欄位
);

    // 氣泡（NOP）的預設控制信號
    localparam NOP_ALU_SRC    = 1'b0;
    localparam [3:0] NOP_ALU_OP = 4'b0000; // ADD
    localparam NOP_MEM_READ   = 1'b0;
    localparam NOP_MEM_WRITE  = 1'b0;
    localparam NOP_REG_WRITE  = 1'b0;
    localparam [1:0] NOP_MEM_TO_REG = 2'b00;
    localparam NOP_BRANCH     = 1'b0;
    localparam NOP_IS_JAL     = 1'b0;
    localparam NOP_IS_JALR    = 1'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 重置為類似 NOP 的狀態
            ex_pc_plus_4_o <= 32'b0;
            ex_rs1_data_o  <= 32'b0;
            ex_rs2_data_o  <= 32'b0;
            ex_imm_ext_o   <= 32'b0;
            ex_rs1_addr_o  <= 5'b0;
            ex_rs2_addr_o  <= 5'b0;
            ex_rd_addr_o   <= 5'b0;

            ex_alu_src_o   <= NOP_ALU_SRC;
            ex_alu_op_o    <= NOP_ALU_OP;
            ex_mem_read_o  <= NOP_MEM_READ;
            ex_mem_write_o <= NOP_MEM_WRITE;
            ex_reg_write_o <= NOP_REG_WRITE;
            ex_mem_to_reg_o<= NOP_MEM_TO_REG;
            ex_branch_o    <= NOP_BRANCH;
            ex_is_jal_o    <= NOP_IS_JAL;
            ex_is_jalr_o   <= NOP_IS_JALR;
            ex_funct3_o    <= 3'b0;
        end
        else if (id_ex_bubble_i || id_ex_flush_en) begin // 如果需要插入氣泡或清除
            // 插入 NOP（或等效的氣泡）
            ex_pc_plus_4_o <= 32'b0; // 資料路徑對 NOP 不重要
            ex_rs1_data_o  <= 32'b0;
            ex_rs2_data_o  <= 32'b0;
            ex_imm_ext_o   <= 32'b0;
            ex_rs1_addr_o  <= 5'b0; // NOP 的 rs1 = x0
            ex_rs2_addr_o  <= 5'b0; // NOP 的 rs2 = x0
            ex_rd_addr_o   <= 5'b0; // NOP 的 rd = x0

            ex_alu_src_o   <= NOP_ALU_SRC;
            ex_alu_op_o    <= NOP_ALU_OP;
            ex_mem_read_o  <= NOP_MEM_READ;
            ex_mem_write_o <= NOP_MEM_WRITE;
            ex_reg_write_o <= NOP_REG_WRITE; // 關鍵：NOP 不寫入暫存器
            ex_mem_to_reg_o<= NOP_MEM_TO_REG;
            ex_branch_o    <= NOP_BRANCH;
            ex_is_jal_o    <= NOP_IS_JAL;
            ex_is_jalr_o   <= NOP_IS_JALR;
            ex_funct3_o    <= 3'b0;
            $display("[ID/EX] FLUSH/BUBBLE at cycle %0t: rd_addr=%0d, reg_write=0", $time, id_rd_addr_i, id_reg_write_i);
        end
        else begin // 正常運作：鎖存輸入
            ex_pc_plus_4_o <= id_pc_plus_4_i;
            ex_rs1_data_o  <= id_rs1_data_i;
            ex_rs2_data_o  <= id_rs2_data_i;
            ex_imm_ext_o   <= id_imm_ext_i;
            ex_rs1_addr_o  <= id_rs1_addr_i;
            ex_rs2_addr_o  <= id_rs2_addr_i;
            ex_rd_addr_o   <= id_rd_addr_i;

            ex_alu_src_o   <= id_alu_src_i;
            ex_alu_op_o    <= id_alu_op_i;
            ex_mem_read_o  <= id_mem_read_i;
            ex_mem_write_o <= id_mem_write_i;
            ex_reg_write_o <= id_reg_write_i;
            ex_mem_to_reg_o<= id_mem_to_reg_i;
            ex_branch_o    <= id_branch_i;
            ex_is_jal_o    <= id_is_jal_i;
            ex_is_jalr_o   <= id_is_jalr_i;
            ex_funct3_o    <= id_funct3_i;
            $display("[ID/EX] NORMAL at cycle %0t: rd_addr=%0d, reg_write=%0d", $time, id_rd_addr_i, id_reg_write_i);
        end
    end

endmodule
