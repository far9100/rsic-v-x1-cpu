// RISC-V 32IM CPU - 執行（EX）階段
// 檔案：hardware/rtl/ex_stage.v

`timescale 1ns / 1ps

module ex_stage (
    input  wire        clk,
    input  wire        rst_n,

    // 來自 ID/EX 管線暫存器的輸入（資料路徑）
    input  wire [31:0] rs1_data_i,     // 來源暫存器 1 的資料
    input  wire [31:0] rs2_data_i,     // 來源暫存器 2 的資料
    input  wire [31:0] imm_ext_i,      // 符號擴展的立即值
    input  wire [31:0] pc_plus_4_i,    // PC + 4（用於分支目標計算，JALR）

    // 來自 ID/EX 管線暫存器的輸入（控制信號）
    input  wire        alu_src_i,      // ALU 運算元 B 的來源（0：rs2_data，1：立即值）
    input  wire [3:0]  alu_op_i,       // ALU/乘法器運算類型
    input  wire [4:0]  rd_addr_i,      // 目標暫存器位址
    input  wire [2:0]  funct3_i,       // 分支指令的 funct3
    input  wire        is_branch_i,    // 是否為分支指令
    input  wire        is_jal_i,       // 是否為 JAL 指令
    input  wire        is_jalr_i,      // 是否為 JALR 指令

    // 前遞輸入信號（從 EX/MEM 和 MEM/WB 階段）
    input  wire [31:0] ex_mem_alu_result_i, // 來自 EX/MEM 管線暫存器的結果
    input  wire [4:0]  ex_mem_rd_addr_i,    // 來自 EX/MEM 的目標暫存器
    input  wire        ex_mem_reg_write_i,  // 來自 EX/MEM 的暫存器寫入啟用
    input  wire [31:0] mem_wb_alu_result_i, // 來自 MEM/WB 管線暫存器的結果
    input  wire [4:0]  mem_wb_rd_addr_i,    // 來自 MEM/WB 的目標暫存器
    input  wire        mem_wb_reg_write_i,  // 來自 MEM/WB 的暫存器寫入啟用
    input  wire [4:0]  id_ex_rs1_addr_i,    // 來自 ID/EX 的 rs1 位址
    input  wire [4:0]  id_ex_rs2_addr_i,    // 來自 ID/EX 的 rs2 位址

    // 前遞選擇信號（來自前遞單元）
    input  wire [1:0]  forward_a_sel_i,     // ALU 運算元 A 的選擇器
    input  wire [1:0]  forward_b_sel_i,     // ALU 運算元 B 的選擇器

    // 輸出到 EX/MEM 管線暫存器
    output wire [31:0] alu_result_o,   // 來自 ALU 或乘法器的結果
    output wire        zero_flag_o,    // 來自 ALU 的零旗標（用於分支指令）
    output wire [31:0] branch_target_addr_o, // 計算的分支目標位址
    output wire        branch_taken_o  // 分支是否被採用
);

    // 使用前遞機制選擇正確的操作數
    wire [31:0] forwarded_rs1_data;
    wire [31:0] forwarded_rs2_data;
    
    // 根據前遞選擇信號選擇 rs1 資料
    assign forwarded_rs1_data = 
        (forward_a_sel_i == 2'b01) ? ex_mem_alu_result_i :  // 從 EX/MEM 前遞
        (forward_a_sel_i == 2'b10) ? mem_wb_alu_result_i :  // 從 MEM/WB 前遞
        rs1_data_i;                                         // 使用原始值
    
    // 根據前遞選擇信號選擇 rs2 資料
    assign forwarded_rs2_data = 
        (forward_b_sel_i == 2'b01) ? ex_mem_alu_result_i :  // 從 EX/MEM 前遞
        (forward_b_sel_i == 2'b10) ? mem_wb_alu_result_i :  // 從 MEM/WB 前遞
        rs2_data_i;                                         // 使用原始值

    // ALU 操作數選擇
    wire [31:0] alu_operand_a;
    wire [31:0] alu_operand_b;
    wire [31:0] alu_result_internal;
    wire [31:0] mul_result_internal;

    // 將前遞後的操作數傳給 ALU
    assign alu_operand_a = forwarded_rs1_data;
    assign alu_operand_b = alu_src_i ? imm_ext_i : forwarded_rs2_data;

    // ALU 實例
    alu u_alu (
        .operand_a_i (alu_operand_a),
        .operand_b_i (alu_operand_b),
        .alu_op_i    (alu_op_i),
        .result_o    (alu_result_internal),
        .zero_flag_o (zero_flag_o)
    );

    // 乘法器實例 - 直接使用前遞後的資料
    multiplier u_multiplier (
        .clk         (clk),
        .rst_n       (rst_n),
        .operand_a_i (forwarded_rs1_data),
        .operand_b_i (forwarded_rs2_data),
        .mul_op_i    (alu_op_i),
        .result_o    (mul_result_internal)
    );

    // 分支單元實例
    branch_unit u_branch_unit (
        .clk             (clk),
        .rst_n           (rst_n),
        .rs1_data_i      (forwarded_rs1_data),
        .rs2_data_i      (forwarded_rs2_data),
        .pc_i            (pc_plus_4_i - 4), // 當前 PC
        .imm_i           (imm_ext_i),
        .funct3_i        (funct3_i),
        .is_branch_i     (is_branch_i),
        .is_jal_i        (is_jal_i),
        .is_jalr_i       (is_jalr_i),
        .branch_taken_o  (branch_taken_o),
        .branch_target_o (branch_target_addr_o),
        .is_jump_o       () // 未使用
    );

    // 選擇 ALU 或乘法器的結果
    assign alu_result_o = (alu_op_i == 4'b1010) ? mul_result_internal : alu_result_internal;

endmodule
