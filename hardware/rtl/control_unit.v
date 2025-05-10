// RISC-V 32IM CPU - Control Unit
// File: hardware/rtl/control_unit.v

`timescale 1ns / 1ps

// Define ALU operations (example, can be expanded)
`define ALU_OP_ADD  4'b0000
`define ALU_OP_SUB  4'b0001
`define ALU_OP_SLL  4'b0010
`define ALU_OP_SLT  4'b0011
`define ALU_OP_SLTU 4'b0100
`define ALU_OP_XOR  4'b0101
`define ALU_OP_SRL  4'b0110
`define ALU_OP_SRA  4'b0111
`define ALU_OP_OR   4'b1000
`define ALU_OP_AND  4'b1001
`define ALU_OP_MUL  4'b1010 // For MUL instruction (M extension)
// Add other MUL ops like MULH, MULHSU, MULHU if needed
// `define ALU_OP_LUI_AUIPC 4'b1011 // Special case for LUI/AUIPC if ALU passes through operand B

module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7, // Specifically bit 5 for SUB/SRA, and bits for MUL ops

    // Control signals for EX stage
    output reg        alu_src_o,      // ALU operand B source (0: rs2_data, 1: immediate)
    output reg [3:0]  alu_op_o,       // ALU operation type

    // Control signals for MEM stage
    output reg        mem_read_o,     // Memory read enable (for LW)
    output reg        mem_write_o,    // Memory write enable (for SW)

    // Control signals for WB stage
    output reg        reg_write_o,    // Register write enable
    output reg [1:0]  mem_to_reg_o    // Data source for write-back (00: ALU, 01: Mem, 10: PC+4 for JAL/JALR)

    // Potentially other control signals:
    // output reg branch_o; // If branch instruction
    // output reg jump_o;   // If jump instruction (JAL, JALR)
);

    // RISC-V Opcode definitions
    localparam OPCODE_LOAD   = 7'b0000011;
    localparam OPCODE_IMM    = 7'b0010011;
    localparam OPCODE_AUIPC  = 7'b0010111;
    localparam OPCODE_STORE  = 7'b0100011;
    localparam OPCODE_OP     = 7'b0110011; // R-type (ADD, SUB, SLL, etc. and MUL from M-ext)
    localparam OPCODE_LUI    = 7'b0110111;
    localparam OPCODE_BRANCH = 7'b1100011;
    localparam OPCODE_JALR   = 7'b1100111;
    localparam OPCODE_JAL    = 7'b1101111;
    // localparam OPCODE_SYSTEM = 7'b1110011; // Not fully handled here

    // Default values (typically for NOP or undefined instruction)
    localparam DEFAULT_ALU_SRC    = 1'b0;
    localparam DEFAULT_ALU_OP     = `ALU_OP_ADD; // Or some NOP equivalent
    localparam DEFAULT_MEM_READ   = 1'b0;
    localparam DEFAULT_MEM_WRITE  = 1'b0;
    localparam DEFAULT_REG_WRITE  = 1'b0;
    localparam DEFAULT_MEM_TO_REG = 2'b00;

    always @(*) begin
        // Initialize to default (safe) values
        alu_src_o      = DEFAULT_ALU_SRC;
        alu_op_o       = DEFAULT_ALU_OP;
        mem_read_o     = DEFAULT_MEM_READ;
        mem_write_o    = DEFAULT_MEM_WRITE;
        reg_write_o    = DEFAULT_REG_WRITE;
        mem_to_reg_o   = DEFAULT_MEM_TO_REG;
        // branch_o       = 1'b0;
        // jump_o         = 1'b0;

        case (opcode)
            OPCODE_LOAD: begin // LW, LH, LB, LHU, LBU
                alu_src_o    = 1'b1; // Immediate for offset calculation
                alu_op_o     = `ALU_OP_ADD; // Base + Offset
                mem_read_o   = 1'b1;
                reg_write_o  = 1'b1;
                mem_to_reg_o = 2'b01; // Data from memory
            end
            OPCODE_IMM: begin // ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
                alu_src_o    = 1'b1; // Immediate operand
                reg_write_o  = 1'b1;
                mem_to_reg_o = 2'b00; // Data from ALU
                case (funct3)
                    3'b000: alu_op_o = `ALU_OP_ADD;  // ADDI
                    3'b010: alu_op_o = `ALU_OP_SLT;  // SLTI
                    3'b011: alu_op_o = `ALU_OP_SLTU; // SLTIU
                    3'b100: alu_op_o = `ALU_OP_XOR;  // XORI
                    3'b110: alu_op_o = `ALU_OP_OR;   // ORI
                    3'b111: alu_op_o = `ALU_OP_AND;  // ANDI
                    3'b001: alu_op_o = `ALU_OP_SLL;  // SLLI (funct7[5] is 0)
                    3'b101: begin // SRLI, SRAI
                        if (funct7[5]) // Check for SRAI (funct7[5] == 1)
                            alu_op_o = `ALU_OP_SRA;
                        else // SRLI (funct7[5] == 0)
                            alu_op_o = `ALU_OP_SRL;
                    end
                    default: ; // Should not happen for valid IMM
                endcase
            end
            OPCODE_AUIPC: begin
                alu_src_o    = 1'b1; // Immediate (U-type)
                // ALU needs to be configured to pass PC + immediate.
                // Or handle PC addition outside ALU, and ALU just passes immediate.
                // For simplicity, assume ALU can take PC as op_a and imm as op_b.
                // This requires pc to be an input to ALU, or a special ALU_OP.
                // Let's assume a dedicated ALU op for AUIPC or handle it by selecting PC as op_a.
                // For now, let's say ALU_OP_ADD and rs1_data is PC.
                alu_op_o     = `ALU_OP_ADD; // PC + imm_u
                reg_write_o  = 1'b1;
                mem_to_reg_o = 2'b00; // Data from ALU
            end
            OPCODE_STORE: begin // SW, SH, SB
                alu_src_o    = 1'b1; // Immediate for offset calculation
                alu_op_o     = `ALU_OP_ADD; // Base + Offset
                mem_write_o  = 1'b1;
                reg_write_o  = 1'b0; // No register write for stores
            end
            OPCODE_OP: begin // R-type: ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
                           // M-extension: MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU
                alu_src_o    = 1'b0; // rs2_data as operand
                reg_write_o  = 1'b1;
                mem_to_reg_o = 2'b00; // Data from ALU/Multiplier
                if (funct7 == 7'b0000001) begin // M-extension instructions
                    case (funct3)
                        3'b000: alu_op_o = `ALU_OP_MUL;   // MUL
                        // Add other M-extension ops like MULH, DIV etc.
                        // 3'b001: alu_op_o = `ALU_OP_MULH;  // MULH
                        // 3'b010: alu_op_o = `ALU_OP_MULHSU;// MULHSU
                        // 3'b011: alu_op_o = `ALU_OP_MULHU; // MULHU
                        // 3'b100: alu_op_o = `ALU_OP_DIV;   // DIV
                        // 3'b101: alu_op_o = `ALU_OP_DIVU;  // DIVU
                        // 3'b110: alu_op_o = `ALU_OP_REM;   // REM
                        // 3'b111: alu_op_o = `ALU_OP_REMU;  // REMU
                        default: alu_op_o = `ALU_OP_ADD; // Default for unhandled M-ext
                    endcase
                end else begin // Standard R-type I-extension
                    case (funct3)
                        3'b000: alu_op_o = funct7[5] ? `ALU_OP_SUB : `ALU_OP_ADD; // ADD/SUB
                        3'b001: alu_op_o = `ALU_OP_SLL;  // SLL
                        3'b010: alu_op_o = `ALU_OP_SLT;  // SLT
                        3'b011: alu_op_o = `ALU_OP_SLTU; // SLTU
                        3'b100: alu_op_o = `ALU_OP_XOR;  // XOR
                        3'b101: alu_op_o = funct7[5] ? `ALU_OP_SRA : `ALU_OP_SRL; // SRL/SRA
                        3'b110: alu_op_o = `ALU_OP_OR;   // OR
                        3'b111: alu_op_o = `ALU_OP_AND;  // AND
                        default: ; // Should not happen
                    endcase
                end
            end
            OPCODE_LUI: begin
                alu_src_o    = 1'b1; // Immediate (U-type)
                // ALU needs to be configured to pass operand B (immediate) directly.
                // Or a special ALU_OP for LUI.
                // Let's assume ALU_OP_ADD with rs1_data = 0.
                alu_op_o     = `ALU_OP_ADD; // Effectively 0 + imm_u if rs1 is forced to 0 for LUI
                reg_write_o  = 1'b1;
                mem_to_reg_o = 2'b00; // Data from ALU
            end
            OPCODE_BRANCH: begin // BEQ, BNE, BLT, BGE, BLTU, BGEU
                alu_src_o    = 1'b0; // Compare rs1 and rs2
                // ALU operation depends on branch type (SUB for comparison)
                alu_op_o     = `ALU_OP_SUB; // Used to set flags for comparison
                reg_write_o  = 1'b0;   // Branches do not write to registers
                // branch_o     = 1'b1;
            end
            OPCODE_JALR: begin
                alu_src_o    = 1'b1; // Immediate for offset
                alu_op_o     = `ALU_OP_ADD; // rs1 + offset
                reg_write_o  = 1'b1;
                mem_to_reg_o = 2'b10; // PC + 4
                // jump_o       = 1'b1;
            end
            OPCODE_JAL: begin
                // JAL doesn't strictly need ALU for target, but writes PC+4
                // We can use ALU to calculate PC + imm_j if PC is an input,
                // or handle jump target calculation elsewhere.
                // For PC+4 writeback:
                alu_src_o    = 1'b0; // Doesn't matter for PC+4 writeback path
                alu_op_o     = `ALU_OP_ADD; // Doesn't matter
                reg_write_o  = 1'b1;
                mem_to_reg_o = 2'b10; // PC + 4
                // jump_o       = 1'b1;
            end
            // OPCODE_SYSTEM: begin // CSR instructions, FENCE - more complex
            //     // Handle CSR if implemented
            // end
            default: begin
                // Undefined or NOP instruction
                // Keep default values
            end
        endcase
    end

endmodule
