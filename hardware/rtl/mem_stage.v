// RISC-V 32IM CPU - Memory Access (MEM) Stage
// File: hardware/rtl/mem_stage.v

`timescale 1ns / 1ps

module mem_stage (
    input  wire        clk,
    input  wire        rst_n,

    // Inputs from EX/MEM Pipeline Register (Data Path)
    input  wire [31:0] alu_result_i,   // ALU result (used as memory address for LW/SW)
    input  wire [31:0] rs2_data_i,     // Data from rs2 (for store instructions)
    // input  wire        zero_flag_i,    // Zero flag from ALU (for branch decision if made here)
    // input  wire [31:0] pc_plus_4_i,    // PC+4 (for branch target calculation if branch decision here)
    // input  wire [31:0] imm_ext_i,      // Immediate (for branch target calculation if branch decision here)


    // Inputs from EX/MEM Pipeline Register (Control Signals)
    input  wire        mem_read_i,     // Memory read enable (for LW)
    input  wire        mem_write_i,    // Memory write enable (for SW)

    // Data Memory Interface
    output wire [31:0] d_mem_addr_o,   // Address to data memory
    output wire [31:0] d_mem_wdata_o,  // Data to write to data memory
    output wire [3:0]  d_mem_wen_o,    // Write enable (byte-level or word) for data memory
    input  wire [31:0] d_mem_rdata_i,  // Data read from data memory

    // Outputs to MEM/WB Pipeline Register
    output wire [31:0] mem_rdata_o     // Data read from memory (for LW)
    // output wire        branch_taken_o, // If branch decision is made in MEM stage
    // output wire [31:0] branch_target_addr_o // If branch decision is made in MEM stage
);

    // Data Memory Access Logic
    assign d_mem_addr_o  = alu_result_i; // ALU result is used as the address for loads/stores
    assign d_mem_wdata_o = rs2_data_i;   // rs2_data is the data to be stored

    // Generate write enable signals for data memory
    // Assuming word access for simplicity. For byte/half-word, this needs more logic based on funct3.
    assign d_mem_wen_o = mem_write_i ? 4'b1111 : 4'b0000; // Full word write if mem_write is active

    // Output data read from memory
    assign mem_rdata_o = d_mem_rdata_i; // Pass through data read from memory

    // Branch logic (if branch decision is made in MEM stage)
    // This is common if the zero flag from ALU (in EX/MEM reg) is used here.
    // wire branch_condition_met = (mem_read_i == `IS_BRANCH_OP` && zero_flag_i == `EXPECTED_ZERO_FOR_BRANCH`);
    // assign branch_taken_o = branch_condition_met;
    // assign branch_target_addr_o = (branch_condition_met) ? (pc_plus_4_i + imm_ext_i - 4) : pc_plus_4_i; // Simplified

endmodule
