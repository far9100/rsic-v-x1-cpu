    wire [31:0] id_ex_instr;                 // 從 IF/ID 到 ID 階段的指令
    wire [3:0]  ex_mem_alu_op;               // 從 ID/EX 到 EX 階段的 ALU 運算
    wire [31:0] ex_mem_alu_result;           // 從 EX 到 EX/MEM 階段的 ALU 結果
    wire        ex_zero_flag;                // 從 EX 階段的零值旗標
    wire [31:0] ex_mem_rs2_data_for_store;   // 用於儲存的 rs2 資料，從 ID/EX 到 EX/MEM
    wire [31:0] mem_wb_alu_result;           // 從 EX/MEM 到 MEM/WB 的 ALU 結果
    wire [4:0]  mem_wb_rd_addr;              // 從 EX/MEM 到 MEM/WB 的 rd 位址
    wire        mem_zero_flag;               // 從 EX/MEM 到 MEM 階段的零值旗標（用於分支）
    wire        d_mem_read_ctrl;             // 資料記憶體讀取控制
    wire        d_mem_write_ctrl;            // 資料記憶體寫入控制
    wire        mem_wb_reg_write;            // 從 EX/MEM 到 MEM/WB 的暫存器寫入控制
    wire [1:0]  mem_wb_mem_to_reg;           // 從 EX/MEM 到 MEM/WB 的記憶體到暫存器控制
    wire [31:0] mem_wb_mem_rdata;            // 從記憶體讀取的資料，從 MEM 到 MEM/WB
    wire [31:0] mem_wb_data;                 // 要寫回暫存器檔案的資料

    // 用於前遞/危險單元或複雜路徑的信號預留位置
    wire [31:0] ex_mem_pc_plus_4;
    wire [31:0] ex_mem_rs1_data;
    wire [31:0] ex_mem_rs2_data_for_alu;
    wire [31:0] ex_mem_imm_ext;
    wire [4:0]  ex_mem_rs1_addr;
    wire [4:0]  ex_mem_rs2_addr;
    wire [4:0]  ex_mem_rd_addr;             // 用於 EX 階段的 rd_addr
    wire        ex_mem_alu_src;
    wire        ex_mem_mem_read_ctrl;
    wire        ex_mem_mem_write_ctrl;
    wire        ex_mem_reg_write_ctrl;
    wire [1:0]  ex_mem_mem_to_reg_ctrl;
    wire [31:0] id_ex_pc_plus_4_for_jalr_jal; // JAL/JALR 的 PC+4 預留位置

    // 前遞單元信號
    wire [1:0] forward_a_sel;
    wire [1:0] forward_b_sel;

    // 分支和跳躍信號
    wire id_ex_branch_ctrl;           // 從 ID 階段的分支控制信號
    wire id_ex_jump_ctrl;             // 從 ID 階段的跳躍控制信號
    wire ex_mem_branch_ctrl;          // 從 ID/EX 到 EX/MEM 的分支控制信號
    wire ex_mem_jump_ctrl;            // 從 ID/EX 到 EX/MEM 的跳躍控制信號
    wire branch_taken;                // 分支採取決策
    wire [31:0] branch_target_addr;   // 分支目標位址 