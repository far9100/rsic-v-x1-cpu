// RISC-V 32IM CPU - Arithmetic Logic Unit (ALU)
// File: hardware/rtl/alu.v

`timescale 1ns / 1ps

// Re-define ALU operations if not globally included, or use parameters
`ifndef ALU_OPS_DEFINED
`define ALU_OPS_DEFINED
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
    // Note: MUL operations are handled by a separate multiplier unit in this design
    // LUI/AUIPC might be handled by passing operand_b or specific logic if rs1 is PC/zero.
`endif

module alu (
    input  wire [31:0] operand_a_i,  // Operand A
    input  wire [31:0] operand_b_i,  // Operand B (can be rs2_data or immediate)
    input  wire [3:0]  alu_op_i,     // ALU operation selection

    output reg [31:0] result_o,     // Result of ALU operation
    output reg        zero_flag_o   // Zero flag (result_o == 0)
);

    // Internal wire for shift amount (lower 5 bits of operand_b)
    wire [4:0] shift_amount = operand_b_i[4:0];

    always @(*) begin
        // Default assignment to avoid latches if a case is not covered
        result_o = 32'hxxxxxxxx; // Undefined for safety

        case (alu_op_i)
            `ALU_OP_ADD:  result_o = operand_a_i + operand_b_i;
            `ALU_OP_SUB:  result_o = operand_a_i - operand_b_i;
            `ALU_OP_SLL:  result_o = operand_a_i << shift_amount;
            `ALU_OP_SLT:  result_o = ($signed(operand_a_i) < $signed(operand_b_i)) ? 32'd1 : 32'd0;
            `ALU_OP_SLTU: result_o = (operand_a_i < operand_b_i) ? 32'd1 : 32'd0;
            `ALU_OP_XOR:  result_o = operand_a_i ^ operand_b_i;
            `ALU_OP_SRL:  result_o = operand_a_i >> shift_amount;
            `ALU_OP_SRA:  result_o = $signed(operand_a_i) >>> shift_amount;
            `ALU_OP_OR:   result_o = operand_a_i | operand_b_i;
            `ALU_OP_AND:  result_o = operand_a_i & operand_b_i;
            // LUI: operand_a is 0 (forced by control or wiring), operand_b is imm_u. Result is imm_u.
            // AUIPC: operand_a is PC, operand_b is imm_u. Result is PC + imm_u.
            // These are typically handled by ADD op with appropriate inputs.
            // If alu_op_i had specific codes for LUI/AUIPC, they could be:
            // `ALU_OP_LUI_AUIPC: result_o = operand_b_i; // If operand_a is pre-added or zero.
            // Or, more commonly, LUI uses ADD with x0 as rs1. AUIPC uses ADD with PC as rs1.
            default:      result_o = 32'hxxxxxxxx; // Undefined operation
        endcase
    end

    // Zero flag calculation
    // assign zero_flag_o = (result_o == 32'b0);
    // Combinational always block for zero_flag to ensure it's based on the final result_o
    always @(*) begin
        if (result_o == 32'b0) begin
            zero_flag_o = 1'b1;
        end else begin
            zero_flag_o = 1'b0;
        end
    end

endmodule
