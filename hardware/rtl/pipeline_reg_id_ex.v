// RISC-V 32IM CPU - ID/EX Pipeline Register
// File: hardware/rtl/pipeline_reg_id_ex.v

`timescale 1ns / 1ps

module pipeline_reg_id_ex (
    input  wire        clk,
    input  wire        rst_n,
    // input  wire        id_ex_bubble_i, // From Hazard Unit (to insert bubble/stall)
    // input  wire        id_ex_flush_en, // From Hazard Unit (to clear register - branch mispredict)

    // Inputs from ID Stage (Data Path)
    input  wire [31:0] id_pc_plus_4_i,
    input  wire [31:0] id_rs1_data_i,
    input  wire [31:0] id_rs2_data_i,
    input  wire [31:0] id_imm_ext_i,
    input  wire [4:0]  id_rs1_addr_i, // For forwarding
    input  wire [4:0]  id_rs2_addr_i, // For forwarding
    input  wire [4:0]  id_rd_addr_i,

    // Inputs from ID Stage (Control Signals)
    // EX controls
    input  wire        id_alu_src_i,
    input  wire [3:0]  id_alu_op_i,
    // MEM controls
    input  wire        id_mem_read_i,
    input  wire        id_mem_write_i,
    // WB controls
    input  wire        id_reg_write_i,
    input  wire [1:0]  id_mem_to_reg_i,

    // Outputs to EX Stage (Data Path)
    output reg [31:0] ex_pc_plus_4_o,
    output reg [31:0] ex_rs1_data_o,
    output reg [31:0] ex_rs2_data_o,
    output reg [31:0] ex_imm_ext_o,
    output reg [4:0]  ex_rs1_addr_o,
    output reg [4:0]  ex_rs2_addr_o,
    output reg [4:0]  ex_rd_addr_o,

    // Outputs to EX Stage (Control Signals)
    // EX controls
    output reg        ex_alu_src_o,
    output reg [3:0]  ex_alu_op_o,
    // MEM controls (passed to EX/MEM register)
    output reg        ex_mem_read_o,
    output reg        ex_mem_write_o,
    // WB controls (passed to EX/MEM and MEM/WB registers)
    output reg        ex_reg_write_o,
    output reg [1:0]  ex_mem_to_reg_o
);

    // Default control signals for a bubble (NOP)
    localparam NOP_ALU_SRC    = 1'b0;
    localparam [3:0] NOP_ALU_OP = 4'b0000; // e.g., ADD
    localparam NOP_MEM_READ   = 1'b0;
    localparam NOP_MEM_WRITE  = 1'b0;
    localparam NOP_REG_WRITE  = 1'b0;
    localparam [1:0] NOP_MEM_TO_REG = 2'b00;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset to NOP-like state
            ex_pc_plus_4_o  <= 32'b0;
            ex_rs1_data_o   <= 32'b0;
            ex_rs2_data_o   <= 32'b0;
            ex_imm_ext_o    <= 32'b0;
            ex_rs1_addr_o   <= 5'b0;
            ex_rs2_addr_o   <= 5'b0;
            ex_rd_addr_o    <= 5'b0;

            ex_alu_src_o    <= NOP_ALU_SRC;
            ex_alu_op_o     <= NOP_ALU_OP;
            ex_mem_read_o   <= NOP_MEM_READ;
            ex_mem_write_o  <= NOP_MEM_WRITE;
            ex_reg_write_o  <= NOP_REG_WRITE;
            ex_mem_to_reg_o <= NOP_MEM_TO_REG;
        end
        // else if (id_ex_flush_en || id_ex_bubble_i) begin // If flushing or bubbling
        //     // Insert NOP (or bubble equivalent)
        //     ex_pc_plus_4_o  <= ex_pc_plus_4_o; // Keep PC for potential use or let it be don't care
        //     ex_rs1_data_o   <= 32'b0; // Data paths don't matter for NOP
        //     ex_rs2_data_o   <= 32'b0;
        //     ex_imm_ext_o    <= 32'b0;
        //     ex_rs1_addr_o   <= 5'b0;
        //     ex_rs2_addr_o   <= 5'b0;
        //     ex_rd_addr_o    <= 5'b0; // rd = x0 for NOP

        //     ex_alu_src_o    <= NOP_ALU_SRC;
        //     ex_alu_op_o     <= NOP_ALU_OP;
        //     ex_mem_read_o   <= NOP_MEM_READ;
        //     ex_mem_write_o  <= NOP_MEM_WRITE;
        //     ex_reg_write_o  <= NOP_REG_WRITE; // Critical: NOP does not write to reg
        //     ex_mem_to_reg_o <= NOP_MEM_TO_REG;
        // end
        else begin // Normal operation: latch inputs
            ex_pc_plus_4_o  <= id_pc_plus_4_i;
            ex_rs1_data_o   <= id_rs1_data_i;
            ex_rs2_data_o   <= id_rs2_data_i;
            ex_imm_ext_o    <= id_imm_ext_i;
            ex_rs1_addr_o   <= id_rs1_addr_i;
            ex_rs2_addr_o   <= id_rs2_addr_i;
            ex_rd_addr_o    <= id_rd_addr_i;

            ex_alu_src_o    <= id_alu_src_i;
            ex_alu_op_o     <= id_alu_op_i;
            ex_mem_read_o   <= id_mem_read_i;
            ex_mem_write_o  <= id_mem_write_i;
            ex_reg_write_o  <= id_reg_write_i;
            ex_mem_to_reg_o <= id_mem_to_reg_i;
        end
    end

endmodule
