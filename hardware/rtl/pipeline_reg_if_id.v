// RISC-V 32IM CPU - IF/ID Pipeline Register
// File: hardware/rtl/pipeline_reg_if_id.v

`timescale 1ns / 1ps

module pipeline_reg_if_id (
    input  wire        clk,
    input  wire        rst_n,
    // input  wire        if_id_write_en, // From Hazard Unit (to enable/disable register update - stall)
    // input  wire        if_id_flush_en, // From Hazard Unit (to clear register - branch mispredict)

    // Inputs from IF Stage
    input  wire [31:0] if_pc_plus_4_i,
    input  wire [31:0] if_instr_i,

    // Outputs to ID Stage
    output reg [31:0] id_pc_plus_4_o,
    output reg [31:0] id_instr_o
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset state: typically to NOP instruction or 0s
            id_pc_plus_4_o <= 32'b0;
            id_instr_o     <= 32'h00000013; // NOP instruction (addi x0, x0, 0)
        end 
        // else if (if_id_flush_en) begin
        //     // Flush: insert NOP
        //     id_pc_plus_4_o <= 32'b0; // Or some default PC value
        //     id_instr_o     <= 32'h00000013; // NOP
        // end
        // else if (if_id_write_en) begin
        //     // Normal operation: latch inputs
        //     id_pc_plus_4_o <= if_pc_plus_4_i;
        //     id_instr_o     <= if_instr_i;
        // end
        // else begin
        //     // Stall: keep current values (do nothing to regs)
        // end
        // Simplified: always latch for now
        else begin
            id_pc_plus_4_o <= if_pc_plus_4_i;
            id_instr_o     <= if_instr_i;
        end
    end

endmodule
