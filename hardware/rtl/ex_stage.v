// RISC-V 32IM CPU - Execute (EX) Stage
// File: hardware/rtl/ex_stage.v

`timescale 1ns / 1ps

module ex_stage (
    input  wire        clk,
    input  wire        rst_n,

    // Inputs from ID/EX Pipeline Register (Data Path)
    input  wire [31:0] rs1_data_i,     // Data from source register 1 (potentially forwarded)
    input  wire [31:0] rs2_data_i,     // Data from source register 2 (potentially forwarded)
    input  wire [31:0] imm_ext_i,      // Sign-extended immediate value
    // input  wire [31:0] pc_plus_4_i,    // PC + 4 (for branch target calculation, JALR)

    // Inputs from ID/EX Pipeline Register (Control Signals)
    input  wire        alu_src_i,      // ALU operand B source (0: rs2_data, 1: immediate)
    input  wire [3:0]  alu_op_i,       // ALU/Multiplier operation type

    // Inputs for Forwarding (from Forwarding Unit)
    // input  wire [1:0]  forward_a_sel_i, // Selector for ALU operand A
    // input  wire [1:0]  forward_b_sel_i, // Selector for ALU operand B
    // Input data for forwarding paths (from EX/MEM and MEM/WB stages)
    // input  wire [31:0] ex_mem_alu_result_fwd_i, // ALU result from EX/MEM stage
    // input  wire [31:0] mem_wb_data_fwd_i,       // Data from MEM/WB stage (either ALU result or Mem data)


    // Outputs to EX/MEM Pipeline Register
    output wire [31:0] alu_result_o,   // Result from ALU or Multiplier
    output wire        zero_flag_o     // Zero flag from ALU (for branch instructions)
    // output wire [31:0] branch_target_addr_o, // Calculated branch target address (if done in EX)
);

    wire [31:0] alu_operand_a;
    wire [31:0] alu_operand_b;
    wire [31:0] alu_result_internal;
    wire [31:0] mul_result_internal;

    // Operand Selection for ALU/Multiplier
    // Implement forwarding logic here if Forwarding Unit is separate
    // For now, directly use inputs assuming forwarding is handled before this stage or integrated
    assign alu_operand_a = rs1_data_i;
    assign alu_operand_b = alu_src_i ? imm_ext_i : rs2_data_i;

    // ALU instance
    alu u_alu (
        .operand_a_i (alu_operand_a),
        .operand_b_i (alu_operand_b),
        .alu_op_i    (alu_op_i), // Lower bits of alu_op_i might select ALU func
        .result_o    (alu_result_internal),
        .zero_flag_o (zero_flag_o)
    );

    // Multiplier instance (for 'M' extension)
    // The alu_op_i needs to be designed to select between ALU and Multiplier,
    // or have specific opcodes for multiply operations.
    // Example: if alu_op_i indicates a multiply operation
    multiplier u_multiplier (
        .clk         (clk), // If multiplier is pipelined or multi-cycle
        .rst_n       (rst_n),
        .operand_a_i (rs1_data_i), // Multiplier always uses rs1, rs2
        .operand_b_i (rs2_data_i),
        .mul_op_i    (alu_op_i), // Specific bits of alu_op_i for mul type (mul, mulh, etc.)
        .result_o    (mul_result_internal)
    );

    // Select final result based on operation type (ALU vs MUL)
    // This selection logic depends on how alu_op_i is defined.
    // For simplicity, assuming a bit in alu_op_i or a range of opcodes distinguishes them.
    // Example: if alu_op_i[3] is 1 for multiply, 0 for ALU (this is just an example)
    // More realistically, control unit would provide a separate signal or specific alu_op values.
    
    // Simplified: For now, let's assume alu_op_i covers both.
    // A more robust solution would involve the control unit generating a select signal
    // or the ALU module itself handling multiplication if alu_op_i is designed for it.
    // If `mul` is one of the `alu_op_i` values:
    // assign alu_result_o = (alu_op_i == `MUL_OP_CODE`) ? mul_result_internal : alu_result_internal;
    // For now, let's assume ALU handles basic ops and MUL handles mul.
    // The `cpu_top` will need to be more specific about how these are chosen.
    // For this skeleton, we'll just output the ALU result.
    // Proper integration of multiplier result needs refinement in control signals.
    assign alu_result_o = alu_result_internal; // Placeholder: Needs logic to select mul_result

    // Branch target calculation (if done in EX)
    // assign branch_target_addr_o = pc_plus_4_i + imm_ext_i; // For conditional branches (incorrect for JALR)
                                                            // JALR: rs1_data_i + imm_ext_i

endmodule
