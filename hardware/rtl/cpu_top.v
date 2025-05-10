// RISC-V 32IM Five-Stage Pipelined CPU Top Module
// File: hardware/rtl/cpu_top.v

`timescale 1ns / 1ps

module cpu_top (
    input  wire        clk,
    input  wire        rst_n,

    // Instruction Memory Interface (Simplified)
    output wire [31:0] i_mem_addr,
    input  wire [31:0] i_mem_rdata,
    // output wire        i_mem_read, // Assuming always read for now

    // Data Memory Interface (Simplified)
    output wire [31:0] d_mem_addr,
    output wire [31:0] d_mem_wdata,
    output wire [3:0]  d_mem_wen,    // Byte enable or word enable (e.g., 4'b1111 for word)
    input  wire [31:0] d_mem_rdata
    // output wire        d_mem_read,
    // output wire        d_mem_write
);

    // Wires connecting pipeline stages
    // IF/ID
    wire [31:0] if_id_pc_plus_4;
    wire [31:0] if_id_instr;

    // ID/EX
    wire [31:0] id_ex_pc_plus_4;
    wire [31:0] id_ex_rs1_data;
    wire [31:0] id_ex_rs2_data;
    wire [31:0] id_ex_imm_ext;
    wire [4:0]  id_ex_rs1_addr;
    wire [4:0]  id_ex_rs2_addr;
    wire [4:0]  id_ex_rd_addr;
    // Control signals for EX
    wire        id_ex_alu_src;
    wire [3:0]  id_ex_alu_op; // ALU operation type
    wire        id_ex_mem_read;
    wire        id_ex_mem_write;
    wire        id_ex_reg_write;
    wire [1:0]  id_ex_mem_to_reg; // Or wb_sel

    // EX/MEM
    wire [31:0] ex_mem_alu_result;
    wire [31:0] ex_mem_rs2_data; // For sw instruction
    wire [4:0]  ex_mem_rd_addr;
    // Control signals for MEM
    wire        ex_mem_mem_read;
    wire        ex_mem_mem_write;
    wire        ex_mem_reg_write;
    wire [1:0]  ex_mem_mem_to_reg;

    // MEM/WB
    wire [31:0] mem_wb_mem_rdata;
    wire [31:0] mem_wb_alu_result;
    wire [4:0]  mem_wb_rd_addr;
    // Control signals for WB
    wire        mem_wb_reg_write;
    wire [1:0]  mem_wb_mem_to_reg;

    // Forwarding Unit signals (Example)
    // wire [1:0] forward_a_sel;
    // wire [1:0] forward_b_sel;

    // Hazard Detection Unit signals (Example)
    // wire        pc_write_en;
    // wire        if_id_write_en;
    // wire        id_ex_bubble; // or stall


    // Instantiate Pipeline Stages
    //------------------------------------------------------------------------
    // IF Stage
    //------------------------------------------------------------------------
    if_stage u_if_stage (
        .clk            (clk),
        .rst_n          (rst_n),
        // .pc_write_en   (pc_write_en), // From Hazard Unit
        // .branch_target_addr (ex_mem_branch_target_addr), // From EX or MEM for branch
        // .branch_taken    (ex_mem_branch_taken),      // From EX or MEM for branch
        .i_mem_addr     (i_mem_addr),
        .i_mem_rdata    (i_mem_rdata),
        .if_id_pc_plus_4_o (if_id_pc_plus_4),
        .if_id_instr_o     (if_id_instr)
    );

    //------------------------------------------------------------------------
    // IF/ID Pipeline Register
    //------------------------------------------------------------------------
    pipeline_reg_if_id u_pipeline_reg_if_id (
        .clk            (clk),
        .rst_n          (rst_n),
        // .if_id_write_en (if_id_write_en), // From Hazard Unit
        .if_pc_plus_4_i (if_id_pc_plus_4),
        .if_instr_i     (if_id_instr),
        .id_pc_plus_4_o (id_ex_pc_plus_4), // This will pass through to ID/EX reg
        .id_instr_o     (id_ex_instr)      // This is the instruction for ID stage
    );

    //------------------------------------------------------------------------
    // ID Stage
    //------------------------------------------------------------------------
    // wire [31:0] id_ex_instr; // Instruction for ID stage, from IF/ID register
    id_stage u_id_stage (
        .clk            (clk),
        .rst_n          (rst_n),
        .instr_i        (id_ex_instr), // Instruction from IF/ID reg
        .pc_plus_4_i    (id_ex_pc_plus_4), // PC+4 from IF/ID reg
        .wb_reg_write_i (mem_wb_reg_write), // Write enable from WB
        .wb_rd_addr_i   (mem_wb_rd_addr),   // Destination register from WB
        .wb_data_i      (mem_wb_data),      // Data to write from WB (ALU result or Mem data)

        .rs1_data_o     (id_ex_rs1_data),
        .rs2_data_o     (id_ex_rs2_data),
        .imm_ext_o      (id_ex_imm_ext),
        .rs1_addr_o     (id_ex_rs1_addr),
        .rs2_addr_o     (id_ex_rs2_addr),
        .rd_addr_o      (id_ex_rd_addr),

        // Control signals out
        .alu_src_o      (id_ex_alu_src),
        .alu_op_o       (id_ex_alu_op),
        .mem_read_o     (id_ex_mem_read),
        .mem_write_o    (id_ex_mem_write),
        .reg_write_o    (id_ex_reg_write),
        .mem_to_reg_o   (id_ex_mem_to_reg)
        // .id_ex_bubble_o (id_ex_bubble) // To Hazard Unit if stall needed
    );

    //------------------------------------------------------------------------
    // ID/EX Pipeline Register
    //------------------------------------------------------------------------
    pipeline_reg_id_ex u_pipeline_reg_id_ex (
        .clk            (clk),
        .rst_n          (rst_n),
        // .id_ex_bubble_i  (id_ex_bubble), // From Hazard Unit or ID stage
        .id_pc_plus_4_i (id_ex_pc_plus_4), // From ID stage (passed from IF/ID)
        .id_rs1_data_i  (id_ex_rs1_data),
        .id_rs2_data_i  (id_ex_rs2_data),
        .id_imm_ext_i   (id_ex_imm_ext),
        .id_rs1_addr_i  (id_ex_rs1_addr),
        .id_rs2_addr_i  (id_ex_rs2_addr),
        .id_rd_addr_i   (id_ex_rd_addr),
        .id_alu_src_i   (id_ex_alu_src),
        .id_alu_op_i    (id_ex_alu_op),
        .id_mem_read_i  (id_ex_mem_read),
        .id_mem_write_i (id_ex_mem_write),
        .id_reg_write_i (id_ex_reg_write),
        .id_mem_to_reg_i(id_ex_mem_to_reg),

        .ex_pc_plus_4_o (ex_mem_pc_plus_4), // Passed to EX/MEM reg
        .ex_rs1_data_o  (ex_mem_rs1_data),
        .ex_rs2_data_o  (ex_mem_rs2_data_for_alu), // rs2_data for ALU
        .ex_imm_ext_o   (ex_mem_imm_ext),
        .ex_rs1_addr_o  (ex_mem_rs1_addr),
        .ex_rs2_addr_o  (ex_mem_rs2_addr),
        .ex_rd_addr_o   (ex_mem_rd_addr_for_ex), // rd_addr for EX stage
        .ex_alu_src_o   (ex_mem_alu_src),
        .ex_alu_op_o    (ex_mem_alu_op),
        .ex_mem_read_o  (ex_mem_mem_read_ctrl),
        .ex_mem_write_o (ex_mem_mem_write_ctrl),
        .ex_reg_write_o (ex_mem_reg_write_ctrl),
        .ex_mem_to_reg_o(ex_mem_mem_to_reg_ctrl)
    );

    //------------------------------------------------------------------------
    // EX Stage
    //------------------------------------------------------------------------
    // wire [31:0] ex_mem_rs1_data; // from ID/EX reg
    // wire [31:0] ex_mem_rs2_data_for_alu; // from ID/EX reg
    // wire [31:0] ex_mem_imm_ext; // from ID/EX reg
    // wire [4:0]  ex_mem_rd_addr_for_ex; // from ID/EX reg
    // wire        ex_mem_alu_src; // from ID/EX reg
    // wire [3:0]  ex_mem_alu_op; // from ID/EX reg
    // Forwarding inputs for ALU
    // wire [31:0] forwarded_rs1_data;
    // wire [31:0] forwarded_rs2_data;

    ex_stage u_ex_stage (
        .clk            (clk),
        .rst_n          (rst_n),
        .rs1_data_i     (ex_mem_rs1_data), // Potentially forwarded
        .rs2_data_i     (ex_mem_rs2_data_for_alu), // Potentially forwarded
        .imm_ext_i      (ex_mem_imm_ext),
        .alu_src_i      (ex_mem_alu_src),
        .alu_op_i       (ex_mem_alu_op),
        // .pc_plus_4_i    (ex_mem_pc_plus_4), // For branch calculation if done here
        // .rs1_addr_i     (ex_mem_rs1_addr), // For forwarding logic
        // .rs2_addr_i     (ex_mem_rs2_addr), // For forwarding logic

        // Forwarding Unit inputs
        // .ex_mem_reg_write_i (ex_mem_reg_write_fwd), // from EX/MEM reg (previous instr)
        // .ex_mem_rd_addr_i   (ex_mem_rd_addr_fwd),   // from EX/MEM reg
        // .mem_wb_reg_write_i (mem_wb_reg_write_fwd), // from MEM/WB reg (instr before previous)
        // .mem_wb_rd_addr_i   (mem_wb_rd_addr_fwd),   // from MEM/WB reg
        // .forward_a_sel_i (forward_a_sel),
        // .forward_b_sel_i (forward_b_sel),

        .alu_result_o   (ex_mem_alu_result_pre_fwd),
        .zero_flag_o    (ex_zero_flag) // For branch condition
        // .branch_target_addr_o (ex_branch_target_addr) // If branch calc in EX
    );

    //------------------------------------------------------------------------
    // EX/MEM Pipeline Register
    //------------------------------------------------------------------------
    // wire ex_mem_alu_result_pre_fwd; // from EX stage
    // wire [31:0] ex_mem_rs2_data_for_store; // from ID/EX reg (original rs2_data for sw)
    // wire [4:0]  ex_mem_rd_addr_for_mem; // from ID/EX reg (passed through)
    // wire        ex_mem_mem_read_ctrl; // from ID/EX reg
    // wire        ex_mem_mem_write_ctrl; // from ID/EX reg
    // wire        ex_mem_reg_write_ctrl; // from ID/EX reg
    // wire [1:0]  ex_mem_mem_to_reg_ctrl; // from ID/EX reg
    // wire        ex_zero_flag; // from EX stage

    pipeline_reg_ex_mem u_pipeline_reg_ex_mem (
        .clk            (clk),
        .rst_n          (rst_n),
        .ex_alu_result_i(ex_mem_alu_result_pre_fwd),
        .ex_rs2_data_i  (ex_mem_rs2_data_for_store), // rs2_data for sw, from ID/EX
        .ex_rd_addr_i   (ex_mem_rd_addr_for_mem),    // rd_addr, from ID/EX
        .ex_zero_flag_i (ex_zero_flag),              // For branch decision in MEM or later
        .ex_mem_read_i  (ex_mem_mem_read_ctrl),
        .ex_mem_write_i (ex_mem_mem_write_ctrl),
        .ex_reg_write_i (ex_mem_reg_write_ctrl),
        .ex_mem_to_reg_i(ex_mem_mem_to_reg_ctrl),
        // .ex_branch_target_addr_i (ex_branch_target_addr), // If branch calc in EX

        .mem_alu_result_o (mem_wb_alu_result_from_exmem),
        .mem_rs2_data_o   (d_mem_wdata), // Connects to data memory write data
        .mem_rd_addr_o    (mem_wb_rd_addr_from_exmem),
        .mem_zero_flag_o  (mem_zero_flag),
        .mem_mem_read_o   (d_mem_read_ctrl), // To data memory
        .mem_mem_write_o  (d_mem_write_ctrl),// To data memory
        .mem_reg_write_o  (mem_wb_reg_write_ctrl_from_exmem),
        .mem_mem_to_reg_o (mem_wb_mem_to_reg_ctrl_from_exmem)
        // .mem_branch_target_addr_o (mem_branch_target_addr_out)
    );

    //------------------------------------------------------------------------
    // MEM Stage
    //------------------------------------------------------------------------
    // wire [31:0] mem_wb_alu_result_from_exmem; // from EX/MEM reg
    // wire        d_mem_read_ctrl;  // from EX/MEM reg
    // wire        d_mem_write_ctrl; // from EX/MEM reg
    // Data memory interface signals are directly connected from/to top level or EX/MEM reg

    mem_stage u_mem_stage (
        .clk            (clk),
        .rst_n          (rst_n),
        .alu_result_i   (mem_wb_alu_result_from_exmem), // Used as address for lw/sw
        .mem_read_i     (d_mem_read_ctrl),
        .mem_write_i    (d_mem_write_ctrl),
        // .zero_flag_i    (mem_zero_flag), // For branch decision if made here
        // .pc_plus_4_i    (ex_mem_pc_plus_4), // Passed from ID/EX via EX/MEM
        // .imm_ext_i      (ex_mem_imm_ext),   // Passed from ID/EX via EX/MEM, for branch target

        .d_mem_addr_o   (d_mem_addr),
        // d_mem_wdata is connected from EX/MEM pipeline register's rs2_data output
        .d_mem_wen_o    (d_mem_wen), // Assuming word write for now if d_mem_write_ctrl is active
        .d_mem_rdata_i  (d_mem_rdata),

        .mem_rdata_o    (mem_wb_mem_rdata_from_mem)
        // .branch_taken_o (actual_branch_taken),
        // .branch_target_addr_o (actual_branch_target_addr)
    );

    //------------------------------------------------------------------------
    // MEM/WB Pipeline Register
    //------------------------------------------------------------------------
    // wire [31:0] mem_wb_mem_rdata_from_mem; // from MEM stage (d_mem_rdata)
    // wire [31:0] mem_wb_alu_result_passthru; // from EX/MEM reg (passed through)
    // wire [4:0]  mem_wb_rd_addr_passthru;    // from EX/MEM reg (passed through)
    // wire        mem_wb_reg_write_ctrl_passthru; // from EX/MEM reg
    // wire [1:0]  mem_wb_mem_to_reg_ctrl_passthru; // from EX/MEM reg

    pipeline_reg_mem_wb u_pipeline_reg_mem_wb (
        .clk            (clk),
        .rst_n          (rst_n),
        .mem_rdata_i    (mem_wb_mem_rdata_from_mem),
        .mem_alu_result_i(mem_wb_alu_result_from_exmem), // ALU result from EX/MEM
        .mem_rd_addr_i  (mem_wb_rd_addr_from_exmem),   // rd_addr from EX/MEM
        .mem_reg_write_i(mem_wb_reg_write_ctrl_from_exmem),
        .mem_mem_to_reg_i(mem_wb_mem_to_reg_ctrl_from_exmem),

        .wb_mem_rdata_o (mem_wb_mem_rdata),
        .wb_alu_result_o(mem_wb_alu_result),
        .wb_rd_addr_o   (mem_wb_rd_addr),
        .wb_reg_write_o (mem_wb_reg_write),
        .wb_mem_to_reg_o(mem_wb_mem_to_reg)
    );

    //------------------------------------------------------------------------
    // WB Stage (Conceptually, just muxing and writing to RegFile in ID stage)
    //------------------------------------------------------------------------
    // The actual write to the register file happens in the ID stage during the first half of the clock cycle.
    // The signals mem_wb_reg_write, mem_wb_rd_addr, and the data to be written (selected by mem_wb_mem_to_reg)
    // are fed back to the ID stage's register file.

    wire [31:0] mem_wb_data; // Data to be written back to register file

    assign mem_wb_data = (mem_wb_mem_to_reg == 2'b01) ? mem_wb_mem_rdata    // Load
                       : (mem_wb_mem_to_reg == 2'b00) ? mem_wb_alu_result   // ALU op
                       : (mem_wb_mem_to_reg == 2'b10) ? id_ex_pc_plus_4_for_jalr_jal // For JAL/JALR (PC+4) - simplified, needs proper source
                       : 32'hxxxxxxxx; // Default, should not happen

    //------------------------------------------------------------------------
    // Hazard Detection Unit (Placeholder)
    //------------------------------------------------------------------------
    // hazard_detection_unit u_hazard_detection_unit (
    //     .clk                (clk),
    //     .rst_n              (rst_n),
    //     .id_ex_mem_read_i  (id_ex_mem_read), // From ID stage output (before ID/EX reg)
    //     .id_ex_rd_addr_i   (id_ex_rd_addr),  // From ID stage output
    //     .if_id_rs1_addr_i  (if_id_instr[19:15]), // rs1 of current instr in ID
    //     .if_id_rs2_addr_i  (if_id_instr[24:20]), // rs2 of current instr in ID
        
    //     .pc_write_en_o    (pc_write_en),
    //     .if_id_write_en_o (if_id_write_en),
    //     .id_ex_bubble_o   (id_ex_bubble_ctrl) // Control for ID/EX reg
    // );
    // assign id_ex_bubble = id_ex_bubble_ctrl; // Connect to ID/EX register's bubble/stall input

    //------------------------------------------------------------------------
    // Forwarding Unit (Placeholder)
    //------------------------------------------------------------------------
    // forwarding_unit u_forwarding_unit (
    //     .clk                (clk),
    //     .rst_n              (rst_n),
    //     .ex_mem_reg_write_i (ex_mem_reg_write), // From EX/MEM pipeline register
    //     .ex_mem_rd_addr_i   (ex_mem_rd_addr),   // From EX/MEM pipeline register
    //     .mem_wb_reg_write_i (mem_wb_reg_write), // From MEM/WB pipeline register
    //     .mem_wb_rd_addr_i   (mem_wb_rd_addr),   // From MEM/WB pipeline register
    //     .id_ex_rs1_addr_i   (id_ex_rs1_addr),   // rs1 of current instr in EX (from ID/EX reg)
    //     .id_ex_rs2_addr_i   (id_ex_rs2_addr),   // rs2 of current instr in EX (from ID/EX reg)

    //     .forward_a_sel_o   (forward_a_sel),    // To EX stage mux for rs1
    //     .forward_b_sel_o   (forward_b_sel)     // To EX stage mux for rs2
    // );

    // Temporary assignments for signals that would come from Hazard/Forwarding or are complex
    // These should be properly driven by Hazard Detection and Control Logic
    // wire pc_write_en = 1'b1;
    // wire if_id_write_en = 1'b1;
    // wire id_ex_bubble = 1'b0;

    // Simplified connections, assuming no stalls or flushes for now
    // Many signals in pipeline registers are just passed through if not generated by hazard unit
    wire [31:0] id_ex_pc_plus_4_for_jalr_jal; // Placeholder for PC+4 for JAL/JALR
    assign id_ex_pc_plus_4_for_jalr_jal = id_ex_pc_plus_4; // Simplified

    // Placeholder for signals that need proper definition based on control logic
    wire [31:0] ex_mem_pc_plus_4;
    wire [31:0] ex_mem_rs1_data;
    wire [31:0] ex_mem_rs2_data_for_alu;
    wire [31:0] ex_mem_imm_ext;
    wire [4:0]  ex_mem_rs1_addr;
    wire [4:0]  ex_mem_rs2_addr;
    wire [4:0]  ex_mem_rd_addr_for_ex;
    wire        ex_mem_alu_src;
    // wire [3:0]  ex_mem_alu_op; // Already defined
    wire        ex_mem_mem_read_ctrl;
    wire        ex_mem_mem_write_ctrl;
    wire        ex_mem_reg_write_ctrl;
    wire [1:0]  ex_mem_mem_to_reg_ctrl;

    wire [31:0] ex_mem_rs2_data_for_store;
    wire [4:0]  ex_mem_rd_addr_for_mem;

    wire [31:0] mem_wb_alu_result_from_exmem;
    wire [4:0]  mem_wb_rd_addr_from_exmem;
    wire        mem_zero_flag;
    wire        d_mem_read_ctrl;
    wire        d_mem_write_ctrl;
    wire        mem_wb_reg_write_ctrl_from_exmem;
    wire [1:0]  mem_wb_mem_to_reg_ctrl_from_exmem;
    wire [31:0] mem_wb_mem_rdata_from_mem;


endmodule
