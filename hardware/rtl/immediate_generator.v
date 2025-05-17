// RISC-V 32IM CPU - 立即值產生器
// 檔案：hardware/rtl/immediate_generator.v

`timescale 1ns / 1ps

module immediate_generator (
    input  wire [31:0] instr,      // 輸入指令
    output wire [31:0] imm_ext_o   // 輸出符號擴展的立即值
);

    // 用於產生立即值的指令欄位
    wire [6:0] opcode = instr[6:0];
    // wire [2:0] funct3 = instr[14:12]; // 這裡不直接用於選擇，但 opcode 是關鍵

    // 根據 RISC-V 規格的立即值類型
    wire [31:0] imm_i_type;
    wire [31:0] imm_s_type;
    wire [31:0] imm_b_type;
    wire [31:0] imm_u_type;
    wire [31:0] imm_j_type;

    // I 型立即值（如 ADDI、SLTI、LW、JALR 等指令）
    // imm[11:0] = instr[31:20]
    assign imm_i_type = {{20{instr[31]}}, instr[31:20]};

    // S 型立即值（如 SW、SB 等儲存指令）
    // imm[11:0] = {instr[31:25], instr[11:7]}
    assign imm_s_type = {{20{instr[31]}}, instr[31:25], instr[11:7]};

    // B 型立即值（如 BEQ、BNE 等分支指令）
    // imm[12|10:5|4:1|11] = {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}
    assign imm_b_type = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};

    // U 型立即值（LUI、AUIPC）
    // imm[31:12] = instr[31:12]
    assign imm_u_type = {instr[31:12], 12'b0};

    // J 型立即值（JAL 指令）
    // imm[20|10:1|11|19:12] = {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}
    assign imm_j_type = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

    // 根據操作碼選擇正確的立即值
    // 此邏輯需要根據 RISC-V 操作碼對應表精確實現
    // 使用 localparam 定義操作碼以提高可讀性
    localparam OPCODE_LOAD   = 7'b0000011; // I 型（LW、LB、LH 等）
    localparam OPCODE_IMM    = 7'b0010011; // I 型（ADDI、SLTI、XORI 等）
    localparam OPCODE_AUIPC  = 7'b0010111; // U 型
    localparam OPCODE_STORE  = 7'b0100011; // S 型（SW、SB、SH）
    localparam OPCODE_AMO    = 7'b0101111; // 這裡未完全處理，類似 R 型但有些有立即值
    localparam OPCODE_OP     = 7'b0110011; // R 型（ADD、SUB、MUL 等）- 不從這裡產生立即值
    localparam OPCODE_LUI    = 7'b0110111; // U 型
    localparam OPCODE_BRANCH = 7'b1100011; // B 型（BEQ、BNE 等）
    localparam OPCODE_JALR   = 7'b1100111; // I 型（JALR）
    localparam OPCODE_JAL    = 7'b1101111; // J 型（JAL）
    localparam OPCODE_SYSTEM = 7'b1110011; // I 型（CSR 指令）

    // 如果沒有特定的立即值類型匹配（例如，R 型），預設為 0
    reg [31:0] selected_imm;

    always @(*) begin
        case (opcode)
            OPCODE_LOAD:   selected_imm = imm_i_type;
            OPCODE_IMM:    selected_imm = imm_i_type;
            OPCODE_AUIPC:  selected_imm = imm_u_type;
            OPCODE_STORE:  selected_imm = imm_s_type;
            OPCODE_LUI:    selected_imm = imm_u_type;
            OPCODE_BRANCH: selected_imm = imm_b_type;
            OPCODE_JALR:   selected_imm = imm_i_type;
            OPCODE_JAL:    selected_imm = imm_j_type;
            OPCODE_SYSTEM: selected_imm = imm_i_type; // 用於 CSRI 指令
            default:       selected_imm = 32'b0;     // R 型或其他非立即值指令
        endcase
    end

    assign imm_ext_o = selected_imm;

endmodule
