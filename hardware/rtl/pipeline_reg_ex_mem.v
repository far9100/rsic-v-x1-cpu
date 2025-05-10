// RISC-V 32IM CPU - EX/MEM Pipeline Register
// File: hardware/rtl/pipeline_reg_ex_mem.v

`timescale 1ns / 1ps

module pipeline_reg_ex_mem (
    input  wire        clk,
    input  wire        rst_n,
    // input  wire        ex_mem_flush_en, // From Hazard Unit (e.g. branch misprediction detected in MEM)

    // Inputs from EX Stage (Data Path)
    input  wire [31:0] ex_alu_result_i,    // ALU/Multiplier result from EX stage
    input  wire [31:0] ex_rs2_data_i,      // rs2 data (for store instructions)
    input  wire [4:0]  ex_rd_addr_i,       // Destination register address
    input  wire        ex_zero_flag_i,     // Zero flag from ALU

    // Inputs from ID/EX Register (Control Signals passed through EX)
    // MEM controls
    input  wire        ex_mem_read_i,
    input  wire        ex_mem_write_i,
    // WB controls
    input  wire        ex_reg_write_i,
    input  wire [1:0]  ex_mem_to_reg_i,

    // Outputs to MEM Stage (Data Path)
    output reg [31:0] mem_alu_result_o,
    output reg [31:0] mem_rs2_data_o,    // Data to be written to memory
    output reg [4:0]  mem_rd_addr_o,
    output reg        mem_zero_flag_o,

    // Outputs to MEM Stage (Control Signals)
    // MEM controls
    output reg        mem_mem_read_o,
    output reg        mem_mem_write_o,
    // WB controls (passed to MEM/WB register)
    output reg        mem_reg_write_o,
    output reg [1:0]  mem_mem_to_reg_o
);

    // Default control signals for a bubble (NOP)
    localparam NOP_MEM_READ   = 1'b0;
    localparam NOP_MEM_WRITE  = 1'b0;
    localparam NOP_REG_WRITE  = 1'b0;
    localparam [1:0] NOP_MEM_TO_REG = 2'b00;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset to NOP-like state
            mem_alu_result_o <= 32'b0;
            mem_rs2_data_o   <= 32'b0;
            mem_rd_addr_o    <= 5'b0;
            mem_zero_flag_o  <= 1'b0;

            mem_mem_read_o   <= NOP_MEM_READ;
            mem_mem_write_o  <= NOP_MEM_WRITE;
            mem_reg_write_o  <= NOP_REG_WRITE;
            mem_mem_to_reg_o <= NOP_MEM_TO_REG;
        end
        // else if (ex_mem_flush_en) begin // If flushing due to branch mispredict etc.
        //     // Insert NOP (or bubble equivalent)
        //     mem_alu_result_o <= 32'b0; // Data paths don't matter for NOP
        //     mem_rs2_data_o   <= 32'b0;
        //     mem_rd_addr_o    <= 5'b0; // rd = x0 for NOP
        //     mem_zero_flag_o  <= 1'b0;

        //     mem_mem_read_o   <= NOP_MEM_READ;
        //     mem_mem_write_o  <= NOP_MEM_WRITE;
        //     mem_reg_write_o  <= NOP_REG_WRITE; // Critical: NOP does not write to reg
        //     mem_mem_to_reg_o <= NOP_MEM_TO_REG;
        // end
        else begin // Normal operation: latch inputs
            mem_alu_result_o <= ex_alu_result_i;
            mem_rs2_data_o   <= ex_rs2_data_i;
            mem_rd_addr_o    <= ex_rd_addr_i;
            mem_zero_flag_o  <= ex_zero_flag_i;

            mem_mem_read_o   <= ex_mem_read_i;
            mem_mem_write_o  <= ex_mem_write_i;
            mem_reg_write_o  <= ex_reg_write_i;
            mem_mem_to_reg_o <= ex_mem_to_reg_i;
        end
    end

endmodule
