// RISC-V 32IM CPU - MEM/WB Pipeline Register
// File: hardware/rtl/pipeline_reg_mem_wb.v

`timescale 1ns / 1ps

module pipeline_reg_mem_wb (
    input  wire        clk,
    input  wire        rst_n,

    // Inputs from MEM Stage (Data Path)
    input  wire [31:0] mem_rdata_i,      // Data read from memory (for LW)
    // Inputs from EX/MEM Register (Data Path passed through MEM)
    input  wire [31:0] mem_alu_result_i, // ALU result
    input  wire [4:0]  mem_rd_addr_i,    // Destination register address

    // Inputs from EX/MEM Register (Control Signals passed through MEM)
    // WB controls
    input  wire        mem_reg_write_i,
    input  wire [1:0]  mem_mem_to_reg_i,

    // Outputs to WB Stage (conceptually, these feed back to ID's RegFile)
    // Data Path
    output reg [31:0] wb_mem_rdata_o,
    output reg [31:0] wb_alu_result_o,
    output reg [4:0]  wb_rd_addr_o,

    // Control Signals
    output reg        wb_reg_write_o,
    output reg [1:0]  wb_mem_to_reg_o
);

    // Default control signals for a bubble (NOP)
    localparam NOP_REG_WRITE  = 1'b0;
    localparam [1:0] NOP_MEM_TO_REG = 2'b00;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset to NOP-like state
            wb_mem_rdata_o  <= 32'b0;
            wb_alu_result_o <= 32'b0;
            wb_rd_addr_o    <= 5'b0;

            wb_reg_write_o  <= NOP_REG_WRITE;
            wb_mem_to_reg_o <= NOP_MEM_TO_REG;
        end else begin
            // Normal operation: latch inputs
            wb_mem_rdata_o  <= mem_rdata_i;
            wb_alu_result_o <= mem_alu_result_i;
            wb_rd_addr_o    <= mem_rd_addr_i;

            wb_reg_write_o  <= mem_reg_write_i;
            wb_mem_to_reg_o <= mem_mem_to_reg_i;
        end
    end

endmodule
