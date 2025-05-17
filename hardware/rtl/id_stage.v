// RISC-V 32IM CPU - Instruction Decode (ID) Stage
// File: hardware/rtl/id_stage.v

`timescale 1ns / 1ps

module id_stage (
    input  wire        clk,
    input  wire        rst_n,

    // Inputs from IF/ID Pipeline Register
    input  wire [31:0] instr_i,      // Current instruction
    input  wire [31:0] pc_plus_4_i,  // PC + 4 from IF stage

    // Write-back data from MEM/WB pipeline register (for register file write)
    input  wire        wb_reg_write_i, // Write enable signal from WB stage
    input  wire [4:0]  wb_rd_addr_i,   // Destination register address from WB stage
    input  wire [31:0] wb_data_i,      // Data to write back from WB stage

    // Outputs to ID/EX Pipeline Register
    // Data path
    output wire [31:0] rs1_data_o,     // Data from source register 1
    output wire [31:0] rs2_data_o,     // Data from source register 2
    output wire [31:0] imm_ext_o,      // Sign-extended immediate value
    output wire [4:0]  rs1_addr_o,     // Address of source register 1
    output wire [4:0]  rs2_addr_o,     // Address of source register 2
    output wire [4:0]  rd_addr_o,      // Address of destination register
    output wire [31:0] id_pc_plus_4_o, // PC + 4 passed through

    // Control signals for EX stage
    output wire        alu_src_o,      // ALU operand B source (0: rs2_data, 1: immediate)
    output wire [3:0]  alu_op_o,       // ALU operation type
    // Control signals for MEM stage (passed through EX)
    output wire        mem_read_o,     // Memory read enable
    output wire        mem_write_o,    // Memory write enable
    // Control signals for WB stage (passed through EX, MEM)
    output wire        reg_write_o,    // Register write enable
    output wire [1:0]  mem_to_reg_o    // Data source for write-back (00: ALU, 01: Mem, 10: PC+4 for JAL/JALR)

    // Output to Hazard Unit (if stall is detected here due to data dependency on load)
    // output wire        id_stall_o
);

    // Instruction fields extraction
    wire [6:0]  opcode  = instr_i[6:0];
    wire [4:0]  rd      = instr_i[11:7];
    wire [2:0]  funct3  = instr_i[14:12];
    wire [4:0]  rs1     = instr_i[19:15];
    wire [4:0]  rs2     = instr_i[24:20];
    wire [6:0]  funct7  = instr_i[31:25];

    // Register File
    reg_file u_reg_file (
        .clk         (clk),
        .rst_n       (rst_n),
        .rs1_addr    (instr_i[19:15]),
        .rs2_addr    (instr_i[24:20]),
        .rd_addr     (wb_rd_addr_i),
        .rd_data     (wb_data_i),
        .wen         (wb_reg_write_i),
        .rs1_data    (rs1_data_o),
        .rs2_data    (rs2_data_o)
    );

    // Debug printout for register values after write
    // always @(posedge clk) begin
    //     if (wb_reg_write_i) begin
    //         $display("DEBUG REG WRITE: rd_addr=%h, rd_data=%h", wb_rd_addr_i, wb_data_i);
    //     end
    // end

    // Immediate Generator instance
    immediate_generator u_imm_gen (
        .instr    (instr_i),
        .imm_ext_o(imm_ext_o)
    );

    // Control Unit instance
    control_unit u_control_unit (
        .opcode      (opcode),
        .funct3      (funct3),
        .funct7      (funct7),
        .alu_src_o   (alu_src_o),
        .alu_op_o    (alu_op_o),
        .mem_read_o  (mem_read_o),
        .mem_write_o (mem_write_o),
        .reg_write_o (reg_write_o),
        .mem_to_reg_o(mem_to_reg_o)
    );

    // Debug output for when MUL instruction is processed
    // always @(*) begin
    //     if (opcode == 7'b0110011 && funct3 == 3'b000 && funct7 == 7'b0000001) begin
    //         $display("DEBUG ID MUL: rs1_addr=%h, rs2_addr=%h, rs1_data=%h, rs2_data=%h, alu_op=%h", 
    //                 instr_i[19:15], instr_i[24:20], rs1_data_o, rs2_data_o, alu_op_o);
    //     end
    // end

    // Pass through PC+4
    assign id_pc_plus_4_o = pc_plus_4_i;

    // Pass through register addresses
    assign rs1_addr_o = rs1;
    assign rs2_addr_o = rs2;
    assign rd_addr_o  = rd;

    // Stall detection logic (simplified placeholder)
    // assign id_stall_o = (mem_read_o && reg_write_o && ((rd == rs1) || (rd == rs2))); // Basic load-use hazard

endmodule
