// RISC-V 32IM CPU - 控制單元
// 檔案：hardware/rtl/control_unit.v

`timescale 1ns / 1ps

// 定義 ALU 運算（可擴充）
`define ALU_OP_ADD  4'b0000  // 加法
`define ALU_OP_SUB  4'b0001  // 減法
`define ALU_OP_SLL  4'b0010  // 邏輯左移
`define ALU_OP_SLT  4'b0011  // 有號數小於
`define ALU_OP_SLTU 4'b0100  // 無號數小於
`define ALU_OP_XOR  4'b0101  // 互斥或
`define ALU_OP_SRL  4'b0110  // 邏輯右移
`define ALU_OP_SRA  4'b0111  // 算術右移
`define ALU_OP_OR   4'b1000  // 或
`define ALU_OP_AND  4'b1001  // 且
`define ALU_OP_MUL  4'b1010  // 乘法指令（M 擴展）
// 如果需要，可加入其他乘法運算如 MULH, MULHSU, MULHU
// `define ALU_OP_LUI_AUIPC 4'b1011 // 如果 ALU 直接傳遞運算元 B，則為 LUI/AUIPC 的特殊情況

module control_unit (
    input  wire [6:0] opcode,    // 操作碼
    input  wire [2:0] funct3,    // 功能碼 3 位元
    input  wire [6:0] funct7,    // 功能碼 7 位元（特別用於 SUB/SRA 的第 5 位元和乘法運算）

    // EX 階段的控制訊號
    output reg        alu_src_o,      // ALU 運算元 B 來源（0：rs2_data，1：立即值）
    output reg [3:0]  alu_op_o,       // ALU 運算類型

    // MEM 階段的控制訊號
    output reg        mem_read_o,     // 記憶體讀取啟用（用於 LW）
    output reg        mem_write_o,    // 記憶體寫入啟用（用於 SW）

    // WB 階段的控制訊號
    output reg        reg_write_o,    // 暫存器寫入啟用
    output reg [1:0]  mem_to_reg_o,   // 寫回資料來源（00：ALU，01：記憶體，10：PC+4 用於 JAL/JALR）

    // 分支和跳躍控制訊號
    output reg        branch_o,       // 如果是分支指令
    output reg        jump_o          // 如果是跳躍指令（JAL, JALR）
);

    // RISC-V 操作碼定義
    localparam OPCODE_LOAD   = 7'b0000011;  // 載入指令
    localparam OPCODE_IMM    = 7'b0010011;  // 立即值運算
    localparam OPCODE_AUIPC  = 7'b0010111;  // AUIPC 指令
    localparam OPCODE_STORE  = 7'b0100011;  // 儲存指令
    localparam OPCODE_OP     = 7'b0110011;  // R 型指令（ADD, SUB, SLL 等和 M 擴展的 MUL）
    localparam OPCODE_LUI    = 7'b0110111;  // LUI 指令
    localparam OPCODE_BRANCH = 7'b1100011;  // 分支指令
    localparam OPCODE_JALR   = 7'b1100111;  // JALR 指令
    localparam OPCODE_JAL    = 7'b1101111;  // JAL 指令
    // localparam OPCODE_SYSTEM = 7'b1110011; // 系統指令（此處未完全處理）

    // 預設值（通常用於 NOP 或未定義指令）
    localparam DEFAULT_ALU_SRC    = 1'b0;
    localparam DEFAULT_ALU_OP     = `ALU_OP_ADD; // 或某種 NOP 等效值
    localparam DEFAULT_MEM_READ   = 1'b0;
    localparam DEFAULT_MEM_WRITE  = 1'b0;
    localparam DEFAULT_REG_WRITE  = 1'b0;
    localparam DEFAULT_MEM_TO_REG = 2'b00;
    localparam DEFAULT_BRANCH     = 1'b0;
    localparam DEFAULT_JUMP       = 1'b0;

    always @(*) begin
        // 初始化為預設（安全）值
        alu_src_o      = DEFAULT_ALU_SRC;
        alu_op_o       = DEFAULT_ALU_OP;
        mem_read_o     = DEFAULT_MEM_READ;
        mem_write_o    = DEFAULT_MEM_WRITE;
        reg_write_o    = DEFAULT_REG_WRITE;
        mem_to_reg_o   = DEFAULT_MEM_TO_REG;
        branch_o       = DEFAULT_BRANCH;
        jump_o         = DEFAULT_JUMP;

        case (opcode)
            OPCODE_LOAD: begin // LW, LH, LB, LHU, LBU
                alu_src_o    = 1'b1; // 立即值用於偏移量計算
                alu_op_o     = `ALU_OP_ADD; // 基底位址 + 偏移量
                mem_read_o   = 1'b1;
                reg_write_o  = 1'b1;
                mem_to_reg_o = 2'b01; // 資料來自記憶體
            end
            OPCODE_IMM: begin // ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
                alu_src_o    = 1'b1; // 立即值運算元
                reg_write_o  = 1'b1;
                mem_to_reg_o = 2'b00; // 資料來自 ALU
                case (funct3)
                    3'b000: alu_op_o = `ALU_OP_ADD;  // ADDI
                    3'b010: alu_op_o = `ALU_OP_SLT;  // SLTI
                    3'b011: alu_op_o = `ALU_OP_SLTU; // SLTIU
                    3'b100: alu_op_o = `ALU_OP_XOR;  // XORI
                    3'b110: alu_op_o = `ALU_OP_OR;   // ORI
                    3'b111: alu_op_o = `ALU_OP_AND;  // ANDI
                    3'b001: alu_op_o = `ALU_OP_SLL;  // SLLI（funct7[5] 為 0）
                    3'b101: begin // SRLI, SRAI
                        if (funct7[5]) // 檢查是否為 SRAI（funct7[5] == 1）
                            alu_op_o = `ALU_OP_SRA;
                        else // SRLI（funct7[5] == 0）
                            alu_op_o = `ALU_OP_SRL;
                    end
                    default: ; // 對於有效的 IMM 指令不應該發生
                endcase
            end
            OPCODE_AUIPC: begin
                alu_src_o    = 1'b1; // 立即值（U 型）
                // ALU 需要配置為 PC + 立即值
                // 或在 ALU 外部處理 PC 加法，ALU 只傳遞立即值
                // 為簡化起見，假設 ALU 可以接受 PC 作為 op_a 和 imm 作為 op_b
                // 這需要 PC 作為 ALU 的輸入，或特殊的 ALU_OP
                // 假設有專門的 ALU 運算用於 AUIPC 或通過選擇 PC 作為 op_a 來處理
                // 目前，假設使用 ALU_OP_ADD 且 rs1_data 是 PC
                alu_op_o     = `ALU_OP_ADD; // PC + imm_u
                reg_write_o  = 1'b1;
                mem_to_reg_o = 2'b00; // 資料來自 ALU
            end
            OPCODE_STORE: begin // SW, SH, SB
                alu_src_o    = 1'b1; // 立即值用於偏移量計算
                alu_op_o     = `ALU_OP_ADD; // 基底位址 + 偏移量
                mem_write_o  = 1'b1;
                reg_write_o  = 1'b0; // 儲存指令不寫入暫存器
            end
            OPCODE_OP: begin // R 型：ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
                           // M 擴展：MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU
                alu_src_o    = 1'b0; // rs2_data 作為運算元
                reg_write_o  = 1'b1;
                mem_to_reg_o = 2'b00; // 資料來自 ALU/乘法器
                if (funct7 == 7'b0000001) begin // M 擴展指令
                    case (funct3)
                        3'b000: alu_op_o = `ALU_OP_MUL;   // MUL
                        // 加入其他 M 擴展運算如 MULH, DIV 等
                        // 3'b001: alu_op_o = `ALU_OP_MULH;  // MULH
                        // 3'b010: alu_op_o = `ALU_OP_MULHSU;// MULHSU
                        // 3'b011: alu_op_o = `ALU_OP_MULHU; // MULHU
                        // 3'b100: alu_op_o = `ALU_OP_DIV;   // DIV
                        // 3'b101: alu_op_o = `ALU_OP_DIVU;  // DIVU
                        // 3'b110: alu_op_o = `ALU_OP_REM;   // REM
                        // 3'b111: alu_op_o = `ALU_OP_REMU;  // REMU
                        default: alu_op_o = `ALU_OP_ADD; // 未處理的 M 擴展指令預設值
                    endcase
                end else begin // 標準 R 型 I 擴展
                    case (funct3)
                        3'b000: alu_op_o = funct7[5] ? `ALU_OP_SUB : `ALU_OP_ADD; // ADD/SUB
                        3'b001: alu_op_o = `ALU_OP_SLL;  // SLL
                        3'b010: alu_op_o = `ALU_OP_SLT;  // SLT
                        3'b011: alu_op_o = `ALU_OP_SLTU; // SLTU
                        3'b100: alu_op_o = `ALU_OP_XOR;  // XOR
                        3'b101: alu_op_o = funct7[5] ? `ALU_OP_SRA : `ALU_OP_SRL; // SRL/SRA
                        3'b110: alu_op_o = `ALU_OP_OR;   // OR
                        3'b111: alu_op_o = `ALU_OP_AND;  // AND
                        default: ; // 不應該發生
                    endcase
                end
            end
            OPCODE_LUI: begin
                alu_src_o    = 1'b1; // 立即值（U 型）
                // ALU 需要配置為直接傳遞運算元 B（立即值）
                // 或特殊的 ALU_OP 用於 LUI
                // 假設使用 ALU_OP_ADD 且 rs1_data = 0
                alu_op_o     = `ALU_OP_ADD; // 如果 LUI 的 rs1 強制為 0，則實際上是 0 + imm_u
                reg_write_o  = 1'b1;
                mem_to_reg_o = 2'b00; // 資料來自 ALU
            end
            OPCODE_BRANCH: begin // BEQ, BNE, BLT, BGE, BLTU, BGEU
                alu_src_o    = 1'b0; // 比較 rs1 和 rs2
                // ALU 運算取決於分支類型（用於比較的 SUB）
                alu_op_o     = `ALU_OP_SUB; // 用於設置比較的旗標
                reg_write_o  = 1'b0;   // 分支指令不寫入暫存器
                branch_o     = 1'b1;   // 啟用分支評估
            end
            OPCODE_JALR: begin
                alu_src_o    = 1'b1; // 立即值用於偏移量
                alu_op_o     = `ALU_OP_ADD; // rs1 + 偏移量
                reg_write_o  = 1'b1;
                mem_to_reg_o = 2'b10; // PC + 4
                jump_o       = 1'b1;   // 啟用跳躍
            end
            OPCODE_JAL: begin
                // JAL 嚴格來說不需要 ALU 來計算目標位址，但需要寫入 PC+4
                // 如果 PC 是輸入，我們可以使用 ALU 來計算 PC + imm_j
                // 或在其他地方處理跳躍目標位址的計算
                // 對於 PC+4 寫回：
                alu_src_o    = 1'b0; // 對於 PC+4 寫回路徑無關緊要
                alu_op_o     = `ALU_OP_ADD; // 無關緊要
                reg_write_o  = 1'b1;
                mem_to_reg_o = 2'b10; // PC + 4
                jump_o       = 1'b1;   // 啟用跳躍
            end
            // OPCODE_SYSTEM: begin // CSR 指令，FENCE - 較複雜
            //     // 如果實作了 CSR，則處理它
            // end
            default: begin
                // 未定義或 NOP 指令
                // 保持預設值
            end
        endcase
    end

endmodule
