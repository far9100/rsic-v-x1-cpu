// RISC-V 32IM CPU - Execute (EX) Stage
// File: hardware/rtl/ex_stage.v

`timescale 1ns / 1ps

module ex_stage (
    input  wire        clk,
    input  wire        rst_n,

    // Inputs from ID/EX Pipeline Register (Data Path)
    input  wire [31:0] rs1_data_i,     // Data from source register 1 
    input  wire [31:0] rs2_data_i,     // Data from source register 2 
    input  wire [31:0] imm_ext_i,      // Sign-extended immediate value
    // input  wire [31:0] pc_plus_4_i,    // PC + 4 (for branch target calculation, JALR)

    // Inputs from ID/EX Pipeline Register (Control Signals)
    input  wire        alu_src_i,      // ALU operand B source (0: rs2_data, 1: immediate)
    input  wire [3:0]  alu_op_i,       // ALU/Multiplier operation type
    input  wire [4:0]  rd_addr_i,      // Destination register address 

    // 前推輸入信號（從EX/MEM和MEM/WB階段）
    input  wire [31:0] ex_mem_alu_result_i, // Result from EX/MEM pipeline register
    input  wire [4:0]  ex_mem_rd_addr_i,    // Destination register from EX/MEM
    input  wire        ex_mem_reg_write_i,  // Register write enable from EX/MEM
    input  wire [31:0] mem_wb_alu_result_i, // Result from MEM/WB pipeline register
    input  wire [4:0]  mem_wb_rd_addr_i,    // Destination register from MEM/WB
    input  wire        mem_wb_reg_write_i,  // Register write enable from MEM/WB
    input  wire [4:0]  id_ex_rs1_addr_i,    // rs1 address from ID/EX
    input  wire [4:0]  id_ex_rs2_addr_i,    // rs2 address from ID/EX

    // 前推選擇信號（從前推單元）
    input  wire [1:0]  forward_a_sel_i,     // Selector for ALU operand A
    input  wire [1:0]  forward_b_sel_i,     // Selector for ALU operand B

    // Outputs to EX/MEM Pipeline Register
    output wire [31:0] alu_result_o,   // Result from ALU or Multiplier
    output wire        zero_flag_o     // Zero flag from ALU (for branch instructions)
    // output wire [31:0] branch_target_addr_o, // Calculated branch target address (if done in EX)
);

    // 使用前推機制選擇正確的操作數
    wire [31:0] forwarded_rs1_data;
    wire [31:0] forwarded_rs2_data;
    
    // 根據前推選擇信號選擇rs1數據
    assign forwarded_rs1_data = 
        (forward_a_sel_i == 2'b01) ? ex_mem_alu_result_i :  // 從EX/MEM前推
        (forward_a_sel_i == 2'b10) ? mem_wb_alu_result_i :  // 從MEM/WB前推
        rs1_data_i;                                         // 使用原始值
    
    // 根據前推選擇信號選擇rs2數據
    assign forwarded_rs2_data = 
        (forward_b_sel_i == 2'b01) ? ex_mem_alu_result_i :  // 從EX/MEM前推
        (forward_b_sel_i == 2'b10) ? mem_wb_alu_result_i :  // 從MEM/WB前推
        rs2_data_i;                                         // 使用原始值

    // ALU操作數選擇
    wire [31:0] alu_operand_a;
    wire [31:0] alu_operand_b;
    wire [31:0] alu_result_internal;
    wire [31:0] mul_result_internal;

    // 將前推后的操作數傳給ALU
    assign alu_operand_a = forwarded_rs1_data;
    assign alu_operand_b = alu_src_i ? imm_ext_i : forwarded_rs2_data;

    // ALU實例
    alu u_alu (
        .operand_a_i (alu_operand_a),
        .operand_b_i (alu_operand_b),
        .alu_op_i    (alu_op_i),
        .result_o    (alu_result_internal),
        .zero_flag_o (zero_flag_o)
    );

    // 乘法器實例 - 直接使用前推后的數據
    multiplier u_multiplier (
        .clk         (clk),
        .rst_n       (rst_n),
        .operand_a_i (forwarded_rs1_data),
        .operand_b_i (forwarded_rs2_data),
        .mul_op_i    (alu_op_i),
        .result_o    (mul_result_internal)
    );

    // 除錯輸出
    always @(posedge clk) begin
        if (alu_op_i == 4'b1010) begin // ALU_OP_MUL
            $display("DEBUG MUL: alu_op_i=%h, rs1_data_i=%h, rs2_data_i=%h, mul_result=%h", 
                    alu_op_i, forwarded_rs1_data, forwarded_rs2_data, mul_result_internal);
        end
    end
    
    // 根據操作類型選擇輸出結果
    assign alu_result_o = (alu_op_i == `ALU_OP_MUL) ? 
                         mul_result_internal : 
                         alu_result_internal;

endmodule
