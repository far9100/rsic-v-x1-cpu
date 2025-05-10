// RISC-V 32IM CPU - Multiplier Unit (for M Extension)
// File: hardware/rtl/multiplier.v

`timescale 1ns / 1ps

// Define MUL operations if not globally included or use parameters from control_unit/alu_op
`ifndef MUL_OPS_DEFINED
`define MUL_OPS_DEFINED
    // These should correspond to specific alu_op_i values or a dedicated mul_op input
    `define ALU_OP_MUL    4'b1010 // Example from control_unit
    // Define others if this unit handles more than just MUL
    // `define ALU_OP_MULH   4'bxxxx
    // `define ALU_OP_MULHSU 4'bxxxx
    // `define ALU_OP_MULHU  4'bxxxx
`endif

module multiplier (
    input  wire        clk,            // Clock, if multi-cycle or pipelined
    input  wire        rst_n,          // Reset

    input  wire [31:0] operand_a_i,  // Operand A (from rs1_data)
    input  wire [31:0] operand_b_i,  // Operand B (from rs2_data)
    input  wire [3:0]  mul_op_i,     // Multiply operation selection (e.g., from alu_op_o)
                                    // This needs to distinguish MUL, MULH, MULHSU, MULHU

    output reg [31:0] result_o        // Result of multiplication (lower 32 bits for MUL)
                                    // For MULH/MULHSU/MULHU, this would be upper 32 bits
);

    // Internal result for full 64-bit product
    wire [63:0] product_full;

    // Perform multiplication
    // For MUL, we need the lower 32 bits of (rs1 * rs2)
    // For MULH, we need the upper 32 bits of ($signed(rs1) * $signed(rs2))
    // For MULHSU, we need the upper 32 bits of ($signed(rs1) * $unsigned(rs2))
    // For MULHU, we need the upper 32 bits of ($unsigned(rs1) * $unsigned(rs2))

    // Combinational multiplier (can be slow for synthesis, might need pipelining for performance)
    // Using SystemVerilog style casting for signed multiplication if needed.
    // Verilog's '*' operator on two 32-bit numbers results in a 32-bit number if not careful.
    // To get 64-bit result, operands might need to be extended or use specific signed multiply.

    // Simple combinational multiplier for MUL (lower 32 bits)
    // For signed operations, ensure operands are treated as signed.
    // $signed() converts a vector to a signed number for arithmetic.

    // Full 64-bit product for various multiplication types
    wire [63:0] product_signed_signed;
    wire [63:0] product_signed_unsigned;
    wire [63:0] product_unsigned_unsigned;

    assign product_signed_signed     = $signed(operand_a_i) * $signed(operand_b_i);
    assign product_signed_unsigned   = $signed(operand_a_i) * operand_b_i; // operand_b_i is unsigned by default
    assign product_unsigned_unsigned = operand_a_i * operand_b_i;


    always @(*) begin
        // Default result
        result_o = 32'hxxxxxxxx;

        // Select result based on mul_op_i
        // This assumes mul_op_i is encoded to select the type of multiplication.
        // The encoding must match what control_unit provides via alu_op_o.
        case (mul_op_i) // This should match the `define for ALU_OP_MUL etc.
            `ALU_OP_MUL: begin // MUL: Lower 32 bits of rs1 * rs2
                result_o = product_unsigned_unsigned[31:0];
            end
            // Add cases for MULH, MULHSU, MULHU if this module handles them
            // For example, if `ALU_OP_MULH` was defined as 4'b1011:
            // `ALU_OP_MULH: begin // MULH: Upper 32 bits of signed(rs1) * signed(rs2)
            //     result_o = product_signed_signed[63:32];
            // end
            // `ALU_OP_MULHSU: begin // MULHSU: Upper 32 bits of signed(rs1) * unsigned(rs2)
            //     result_o = product_signed_unsigned[63:32];
            // end
            // `ALU_OP_MULHU: begin // MULHU: Upper 32 bits of unsigned(rs1) * unsigned(rs2)
            //     result_o = product_unsigned_unsigned[63:32];
            // end
            default: begin
                // If mul_op_i is not a multiply operation this module handles,
                // output undefined or zero. Or this module should only be active
                // when a multiply op is decoded.
                // For now, if it's not MUL, output undefined.
                // This implies ex_stage selects between ALU and Multiplier output.
                if (mul_op_i == `ALU_OP_MUL) begin // Redundant check if case is exhaustive
                     result_o = product_unsigned_unsigned[31:0];
                end else begin
                     result_o = 32'hxxxxxxxx; // Not a recognized multiply op for this simple version
                end
            end
        endcase
    end

    // If this multiplier is multi-cycle, state machine and registers would be needed here.
    // For a simple single-cycle (combinational) version for MUL:
    // assign result_o = product_unsigned_unsigned[31:0]; // This would be if only MUL is supported

endmodule
