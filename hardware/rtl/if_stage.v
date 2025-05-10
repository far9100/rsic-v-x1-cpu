// RISC-V 32IM CPU - Instruction Fetch (IF) Stage
// File: hardware/rtl/if_stage.v

`timescale 1ns / 1ps

module if_stage (
    input  wire        clk,
    input  wire        rst_n,

    // Inputs for branch/jump handling (from MEM/EX stage or Hazard Unit)
    // input  wire        pc_write_en,      // Enable PC update
    // input  wire        branch_taken,     // Indicates if a branch is taken
    // input  wire [31:0] branch_target_addr, // Target address for branch/jump

    // Instruction Memory Interface
    output wire [31:0] i_mem_addr,       // Address to instruction memory
    input  wire [31:0] i_mem_rdata,      // Instruction read from memory

    // Outputs to IF/ID Pipeline Register
    output wire [31:0] if_id_pc_plus_4_o, // PC + 4
    output wire [31:0] if_id_instr_o      // Fetched instruction
);

    reg [31:0] pc_reg; // Program Counter

    // PC update logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_reg <= 32'h00000000; // Reset PC to 0 (or specific start address)
        end else begin
            // if (pc_write_en) begin // Controlled by Hazard Unit for stalls
            //     if (branch_taken) begin
            //         pc_reg <= branch_target_addr; // Jump or taken branch
            //     end else begin
            //         pc_reg <= pc_reg + 4;         // Sequential execution
            //     end
            // end
            // Simplified: always increment PC by 4 for now
            pc_reg <= pc_reg + 4;
        end
    end

    // Outputs
    assign i_mem_addr = pc_reg;          // Send current PC to instruction memory
    assign if_id_instr_o = i_mem_rdata;  // Pass fetched instruction to next stage
    assign if_id_pc_plus_4_o = pc_reg + 4; // Calculate PC+4 for next stage (useful for branches/jumps)

endmodule
