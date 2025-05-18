// RISC-V 32IM 五級管線 CPU 頂層模組
// 檔案：hardware/rtl/cpu_top.v

`timescale 1ns / 1ps

module cpu_top (
    input  wire        clk,
    input  wire        rst_n,

    // 指令記憶體介面（簡化版）
    output wire [31:0] i_mem_addr,
    input  wire [31:0] i_mem_rdata,
    // output wire        i_mem_read, // 目前假設永遠讀取

    // 資料記憶體介面（簡化版）
    output wire [31:0] d_mem_addr,
    output wire [31:0] d_mem_wdata,
    output wire [3:0]  d_mem_wen,    // 位元組啟用或字組啟用（例如：4'b1111 表示字組）
    input  wire [31:0] d_mem_rdata
    // output wire        d_mem_read,
    // output wire        d_mem_write
);

    // 內部連線（已定義位元寬度）
    wire [31:0] id_ex_instr;                 // 從 IF/ID 到 ID 階段的指令
    wire [3:0]  ex_mem_alu_op;               // 從 ID/EX 到 EX 階段的 ALU 運算
    wire [31:0] ex_mem_alu_result_pre_fwd;   // 從 EX 到 EX/MEM 階段的 ALU 結果
    wire        ex_zero_flag;                // 從 EX 階段的零值旗標
    wire [31:0] ex_mem_rs2_data_for_store;   // 用於儲存的 rs2 資料，從 ID/EX 到 EX/MEM
    wire [31:0] mem_wb_alu_result_from_exmem; // 從 EX/MEM 到 MEM/WB 的 ALU 結果
    wire [4:0]  mem_wb_rd_addr_from_exmem;   // 從 EX/MEM 到 MEM/WB 的 rd 位址
    wire        mem_zero_flag;               // 從 EX/MEM 到 MEM 階段的零值旗標（用於分支）
    wire        d_mem_read_ctrl;             // 資料記憶體讀取控制
    wire        d_mem_write_ctrl;            // 資料記憶體寫入控制
    wire        mem_wb_reg_write_ctrl_from_exmem; // 從 EX/MEM 到 MEM/WB 的暫存器寫入控制
    wire [1:0]  mem_wb_mem_to_reg_ctrl_from_exmem; // 從 EX/MEM 到 MEM/WB 的記憶體到暫存器控制
    wire [31:0] mem_wb_mem_rdata_from_mem;   // 從記憶體讀取的資料，從 MEM 到 MEM/WB
    wire [31:0] mem_wb_data;                 // 要寫回暫存器檔案的資料

    // 用於前遞/危險單元或複雜路徑的信號預留位置
    wire [31:0] ex_mem_pc_plus_4;
    wire [31:0] ex_mem_rs1_data;
    wire [31:0] ex_mem_rs2_data_for_alu;
    wire [31:0] ex_mem_imm_ext;
    wire [4:0]  ex_mem_rs1_addr;
    wire [4:0]  ex_mem_rs2_addr;
    wire [4:0]  ex_mem_rd_addr_for_ex;
    wire        ex_mem_alu_src;
    wire        ex_mem_mem_read_ctrl;
    wire        ex_mem_mem_write_ctrl;
    wire        ex_mem_reg_write_ctrl;
    wire [1:0]  ex_mem_mem_to_reg_ctrl;
    wire [31:0] id_ex_pc_plus_4_for_jalr_jal; // JAL/JALR 的 PC+4 預留位置

    // 前遞單元信號
    wire [1:0] forward_a_sel;
    wire [1:0] forward_b_sel;

    // 連接管線階段的連線（原始宣告，部分可能已包含在上述）
    // IF/ID
    wire [31:0] if_id_pc_plus_4;
    wire [31:0] if_id_instr;

    // ID/EX
    wire [31:0] id_ex_pc_plus_4;
    wire [31:0] id_ex_rs1_data;
    wire [31:0] id_ex_rs2_data;
    wire [31:0] id_ex_imm_ext;
    wire [4:0]  id_ex_rs1_addr;
    wire [4:0]  id_ex_rs2_addr;
    wire [4:0]  id_ex_rd_addr;
    // EX 階段的控制信號
    wire        id_ex_alu_src;
    wire [3:0]  id_ex_alu_op; // ALU 運算類型
    wire        id_ex_mem_read;
    wire        id_ex_mem_write;
    wire        id_ex_reg_write;
    wire [1:0]  id_ex_mem_to_reg; // 或 wb_sel

    // EX/MEM
    wire [31:0] ex_mem_alu_result;
    wire [31:0] ex_mem_rs2_data; // 用於 sw 指令
    wire [4:0]  ex_mem_rd_addr;
    // MEM 階段的控制信號
    wire        ex_mem_mem_read;
    wire        ex_mem_mem_write;
    wire        ex_mem_reg_write;
    wire [1:0]  ex_mem_mem_to_reg;

    // MEM/WB
    wire [31:0] mem_wb_mem_rdata;
    wire [31:0] mem_wb_alu_result;
    wire [4:0]  mem_wb_rd_addr;
    // WB 階段的控制信號
    wire        mem_wb_reg_write;
    wire [1:0]  mem_wb_mem_to_reg;

    // 指派 id_ex_pc_plus_4_for_jalr_jal（簡化版）
    assign id_ex_pc_plus_4_for_jalr_jal = id_ex_pc_plus_4;

    // 實例化管線階段
    //------------------------------------------------------------------------
    // IF 階段
    //------------------------------------------------------------------------
    if_stage u_if_stage (
        .clk            (clk),
        .rst_n          (rst_n),
        // .pc_write_en   (pc_write_en), // 來自危險單元
        // .branch_target_addr (ex_mem_branch_target_addr), // 來自 EX 或 MEM 的分支目標
        // .branch_taken    (ex_mem_branch_taken),      // 來自 EX 或 MEM 的分支決策
        .i_mem_addr     (i_mem_addr),
        .i_mem_rdata    (i_mem_rdata),
        .if_id_pc_plus_4_o (if_id_pc_plus_4),
        .if_id_instr_o     (if_id_instr)
    );

    //------------------------------------------------------------------------
    // IF/ID 管線暫存器
    //------------------------------------------------------------------------
    pipeline_reg_if_id u_pipeline_reg_if_id (
        .clk            (clk),
        .rst_n          (rst_n),
        // .if_id_write_en (if_id_write_en), // 來自危險單元
        .if_pc_plus_4_i (if_id_pc_plus_4),
        .if_instr_i     (if_id_instr),
        .id_pc_plus_4_o (id_ex_pc_plus_4), // 這將傳遞到 ID/EX 暫存器
        .id_instr_o     (id_ex_instr)      // 這是 ID 階段的指令
    );

    //------------------------------------------------------------------------
    // ID 階段
    //------------------------------------------------------------------------
    id_stage u_id_stage (
        .clk            (clk),
        .rst_n          (rst_n),
        .instr_i        (id_ex_instr), // 來自 IF/ID 暫存器的指令
        .pc_plus_4_i    (id_ex_pc_plus_4), // 來自 IF/ID 暫存器的 PC+4
        .wb_reg_write_i (mem_wb_reg_write), // 來自 WB 的寫入啟用
        .wb_rd_addr_i   (mem_wb_rd_addr),   // 來自 WB 的目標暫存器
        .wb_data_i      (mem_wb_data),      // 來自 WB 的寫入資料（ALU 結果或記憶體資料）

        .rs1_data_o     (id_ex_rs1_data),
        .rs2_data_o     (id_ex_rs2_data),
        .imm_ext_o      (id_ex_imm_ext),
        .rs1_addr_o     (id_ex_rs1_addr),
        .rs2_addr_o     (id_ex_rs2_addr),
        .rd_addr_o      (id_ex_rd_addr),

        // 輸出控制信號
        .alu_src_o      (id_ex_alu_src),
        .alu_op_o       (id_ex_alu_op),
        .mem_read_o     (id_ex_mem_read),
        .mem_write_o    (id_ex_mem_write),
        .reg_write_o    (id_ex_reg_write),
        .mem_to_reg_o   (id_ex_mem_to_reg)
        // .id_ex_bubble_o (id_ex_bubble) // 如果需要暫停則送到危險單元
    );

    //------------------------------------------------------------------------
    // ID/EX 管線暫存器
    //------------------------------------------------------------------------
    pipeline_reg_id_ex u_pipeline_reg_id_ex (
        .clk            (clk),
        .rst_n          (rst_n),
        // .id_ex_bubble_i  (id_ex_bubble), // 來自危險單元或 ID 階段
        .id_pc_plus_4_i (id_ex_pc_plus_4), // 來自 ID 階段（從 IF/ID 傳遞）
        .id_rs1_data_i  (id_ex_rs1_data),
        .id_rs2_data_i  (id_ex_rs2_data),
        .id_imm_ext_i   (id_ex_imm_ext),
        .id_rs1_addr_i  (id_ex_rs1_addr),
        .id_rs2_addr_i  (id_ex_rs2_addr),
        .id_rd_addr_i   (id_ex_rd_addr),
        .id_alu_src_i   (id_ex_alu_src),
        .id_alu_op_i    (id_ex_alu_op),
        .id_mem_read_i  (id_ex_mem_read),
        .id_mem_write_i (id_ex_mem_write),
        .id_reg_write_i (id_ex_reg_write),
        .id_mem_to_reg_i(id_ex_mem_to_reg),

        .ex_pc_plus_4_o (ex_mem_pc_plus_4), // 傳遞到 EX/MEM 暫存器
        .ex_rs1_data_o  (ex_mem_rs1_data),
        .ex_rs2_data_o  (ex_mem_rs2_data_for_alu), // 用於 ALU 的 rs2_data
        .ex_imm_ext_o   (ex_mem_imm_ext),
        .ex_rs1_addr_o  (ex_mem_rs1_addr),
        .ex_rs2_addr_o  (ex_mem_rs2_addr),
        .ex_rd_addr_o   (ex_mem_rd_addr_for_ex), // 用於 EX 階段的 rd_addr
        .ex_alu_src_o   (ex_mem_alu_src),
        .ex_alu_op_o    (ex_mem_alu_op),
        .ex_mem_read_o  (ex_mem_mem_read_ctrl),
        .ex_mem_write_o (ex_mem_mem_write_ctrl),
        .ex_reg_write_o (ex_mem_reg_write_ctrl),
        .ex_mem_to_reg_o(ex_mem_mem_to_reg_ctrl)
    );

    //------------------------------------------------------------------------
    // EX 階段
    //------------------------------------------------------------------------
    ex_stage u_ex_stage (
        .clk            (clk),
        .rst_n          (rst_n),
        .rs1_data_i     (ex_mem_rs1_data), // 可能經過前遞
        .rs2_data_i     (ex_mem_rs2_data_for_alu), // 可能經過前遞
        .imm_ext_i      (ex_mem_imm_ext),
        .alu_src_i      (ex_mem_alu_src),
        .alu_op_i       (ex_mem_alu_op),
        .rd_addr_i      (ex_mem_rd_addr_for_ex), // 傳遞目標暫存器位址

        // 連接前遞輸入以解決資料危險
        .ex_mem_alu_result_i(mem_wb_alu_result_from_exmem), // 來自 EX/MEM 管線暫存器的結果
        .ex_mem_rd_addr_i  (mem_wb_rd_addr_from_exmem),    // 來自 EX/MEM 的目標暫存器
        .ex_mem_reg_write_i(mem_wb_reg_write_ctrl_from_exmem), // 來自 EX/MEM 的暫存器寫入啟用
        .mem_wb_alu_result_i(mem_wb_alu_result),           // 來自 MEM/WB 管線暫存器的結果
        .mem_wb_rd_addr_i  (mem_wb_rd_addr),               // 來自 MEM/WB 的目標暫存器
        .mem_wb_reg_write_i(mem_wb_reg_write),             // 來自 MEM/WB 的暫存器寫入啟用
        .id_ex_rs1_addr_i  (ex_mem_rs1_addr),              // 來自 ID/EX 的 rs1 位址
        .id_ex_rs2_addr_i  (ex_mem_rs2_addr),              // 來自 ID/EX 的 rs2 位址
        
        // 連接來自前遞單元的選擇信號
        .forward_a_sel_i  (forward_a_sel),
        .forward_b_sel_i  (forward_b_sel),

        .alu_result_o   (ex_mem_alu_result_pre_fwd),
        .zero_flag_o    (ex_zero_flag) // 用於分支條件
    );

    //------------------------------------------------------------------------
    // EX/MEM 管線暫存器
    //------------------------------------------------------------------------
    pipeline_reg_ex_mem u_pipeline_reg_ex_mem (
        .clk            (clk),
        .rst_n          (rst_n),
        .ex_alu_result_i(ex_mem_alu_result_pre_fwd),
        .ex_rs2_data_i  (ex_mem_rs2_data_for_alu), // 來自 ID/EX 的 sw 用 rs2_data
        .ex_rd_addr_i   (ex_mem_rd_addr_for_ex),    // 修正：來自 ID/EX 輸出 ex_mem_rd_addr_for_ex 的 rd_addr
        .ex_zero_flag_i (ex_zero_flag),              // 用於 MEM 或之後的分支決策
        .ex_mem_read_i  (ex_mem_mem_read_ctrl),
        .ex_mem_write_i (ex_mem_mem_write_ctrl),
        .ex_reg_write_i (ex_mem_reg_write_ctrl),
        .ex_mem_to_reg_i(ex_mem_mem_to_reg_ctrl),
        // .ex_branch_target_addr_i (ex_branch_target_addr), // 如果在 EX 計算分支目標

        .mem_alu_result_o (mem_wb_alu_result_from_exmem),
        .mem_rs2_data_o   (d_mem_wdata), // 連接到資料記憶體寫入資料
        .mem_rd_addr_o    (mem_wb_rd_addr_from_exmem),
        .mem_zero_flag_o  (mem_zero_flag),
        .mem_mem_read_o   (d_mem_read_ctrl), // 到資料記憶體
        .mem_mem_write_o  (d_mem_write_ctrl),// 到資料記憶體
        .mem_reg_write_o  (mem_wb_reg_write_ctrl_from_exmem),
        .mem_mem_to_reg_o (mem_wb_mem_to_reg_ctrl_from_exmem)
    );

    //------------------------------------------------------------------------
    // MEM 階段
    //------------------------------------------------------------------------
    mem_stage u_mem_stage (
        .clk            (clk),
        .rst_n          (rst_n),
        .alu_result_i   (mem_wb_alu_result_from_exmem),
        .rs2_data_i     (d_mem_wdata),
        .mem_read_i     (d_mem_read_ctrl),
        .mem_write_i    (d_mem_write_ctrl),
        .d_mem_addr_o   (d_mem_addr),
        .d_mem_wdata_o  (d_mem_wdata),
        .d_mem_wen_o    (d_mem_wen),
        .d_mem_rdata_i  (d_mem_rdata),
        .mem_rdata_o    (mem_wb_mem_rdata_from_mem)
    );

    //------------------------------------------------------------------------
    // MEM/WB 管線暫存器
    //------------------------------------------------------------------------
    pipeline_reg_mem_wb u_pipeline_reg_mem_wb (
        .clk            (clk),
        .rst_n          (rst_n),
        .mem_rdata_i    (mem_wb_mem_rdata_from_mem),
        .mem_alu_result_i(mem_wb_alu_result_from_exmem),
        .mem_rd_addr_i  (mem_wb_rd_addr_from_exmem),
        .mem_reg_write_i(mem_wb_reg_write_ctrl_from_exmem),
        .mem_mem_to_reg_i(mem_wb_mem_to_reg_ctrl_from_exmem),

        .wb_mem_rdata_o (mem_wb_mem_rdata),
        .wb_alu_result_o(mem_wb_alu_result),
        .wb_rd_addr_o   (mem_wb_rd_addr),
        .wb_reg_write_o (mem_wb_reg_write),
        .wb_mem_to_reg_o(mem_wb_mem_to_reg)
    );

    //------------------------------------------------------------------------
    // WB 階段（寫回邏輯）
    //------------------------------------------------------------------------
    // 選擇要寫回暫存器檔案的資料來源
    assign mem_wb_data = (mem_wb_mem_to_reg == 2'b00) ? mem_wb_alu_result :  // ALU 結果
                        (mem_wb_mem_to_reg == 2'b01) ? mem_wb_mem_rdata :    // 記憶體資料
                        (mem_wb_mem_to_reg == 2'b10) ? id_ex_pc_plus_4 :    // PC+4（用於 JAL/JALR）
                        32'h0;                                                // 預設值

    //------------------------------------------------------------------------
    // 前遞單元
    //------------------------------------------------------------------------
    forwarding_unit u_forwarding_unit (
        .ex_mem_reg_write_i(mem_wb_reg_write_ctrl_from_exmem),
        .mem_wb_reg_write_i(mem_wb_reg_write),
        .ex_mem_rd_addr_i  (mem_wb_rd_addr_from_exmem),
        .mem_wb_rd_addr_i  (mem_wb_rd_addr),
        .id_ex_rs1_addr_i  (ex_mem_rs1_addr),
        .id_ex_rs2_addr_i  (ex_mem_rs2_addr),
        .forward_a_sel_o   (forward_a_sel),
        .forward_b_sel_o   (forward_b_sel)
    );

endmodule
