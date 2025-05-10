// RISC-V 32IM CPU - Immediate Generator
// File: hardware/rtl/immediate_generator.v

`timescale 1ns / 1ps

module immediate_generator (
    input  wire [31:0] instr,      // Input instruction
    output wire [31:0] imm_ext_o   // Output sign-extended immediate
);

    // Instruction fields used for immediate generation
    wire [6:0] opcode = instr[6:0];
    // wire [2:0] funct3 = instr[14:12]; // Not directly used for selection here, but opcode is key

    // Immediate types based on RISC-V spec
    wire [31:0] imm_i_type;
    wire [31:0] imm_s_type;
    wire [31:0] imm_b_type;
    wire [31:0] imm_u_type;
    wire [31:0] imm_j_type;

    // I-type immediate (instructions like ADDI, SLTI, LW, JALR)
    // imm[11:0] = instr[31:20]
    assign imm_i_type = {{20{instr[31]}}, instr[31:20]};

    // S-type immediate (store instructions like SW, SB)
    // imm[11:0] = {instr[31:25], instr[11:7]}
    assign imm_s_type = {{20{instr[31]}}, instr[31:25], instr[11:7]};

    // B-type immediate (branch instructions like BEQ, BNE)
    // imm[12|10:5|4:1|11] = {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}
    assign imm_b_type = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};

    // U-type immediate (LUI, AUIPC)
    // imm[31:12] = instr[31:12]
    assign imm_u_type = {instr[31:12], 12'b0};

    // J-type immediate (JAL instruction)
    // imm[20|10:1|11|19:12] = {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}
    assign imm_j_type = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};


    // Select the correct immediate based on opcode
    // This logic needs to be precise according to RISC-V opcode map.
    // Using localparam for opcodes for clarity.
    localparam OPCODE_LOAD   = 7'b0000011; // I-type (LW, LB, LH, etc.)
    localparam OPCODE_IMM    = 7'b0010011; // I-type (ADDI, SLTI, XORI, etc.)
    localparam OPCODE_AUIPC  = 7'b0010111; // U-type
    localparam OPCODE_STORE  = 7'b0100011; // S-type (SW, SB, SH)
    localparam OPCODE_AMO    = 7'b0101111; // Not fully handled here, R-type like but some have imm
    localparam OPCODE_OP     = 7'b0110011; // R-type (ADD, SUB, MUL, etc.) - No immediate from here
    localparam OPCODE_LUI    = 7'b0110111; // U-type
    localparam OPCODE_BRANCH = 7'b1100011; // B-type (BEQ, BNE, etc.)
    localparam OPCODE_JALR   = 7'b1100111; // I-type (JALR)
    localparam OPCODE_JAL    = 7'b1101111; // J-type (JAL)
    localparam OPCODE_SYSTEM = 7'b1110011; // I-type (CSR instructions)

    // Default to 0 if no specific immediate type matches (e.g., for R-type)
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
            OPCODE_SYSTEM: selected_imm = imm_i_type; // For CSRI instructions
            default:       selected_imm = 32'b0;     // R-type or other non-immediate instructions
        endcase
    end

    assign imm_ext_o = selected_imm;

endmodule
