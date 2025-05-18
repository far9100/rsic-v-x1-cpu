// RISC-V 32IM CPU - 指令解碼（ID）階段
// 檔案：hardware/rtl/id_stage.v

`timescale 1ns / 1ps

module id_stage (
    input  wire        clk,
    input  wire        rst_n,

    // 來自 IF/ID 管線暫存器的輸入
    input  wire [31:0] instr_i,      // 當前指令
    input  wire [31:0] pc_plus_4_i,  // 來自 IF 階段的 PC + 4

    // 來自 MEM/WB 管線暫存器的寫回資料（用於暫存器檔案寫入）
    input  wire        wb_reg_write_i, // 來自 WB 階段的寫入啟用信號
    input  wire [4:0]  wb_rd_addr_i,   // 來自 WB 階段的目標暫存器位址
    input  wire [31:0] wb_data_i,      // 來自 WB 階段的寫回資料

    // 輸出到 ID/EX 管線暫存器
    // 資料路徑
    output wire [31:0] rs1_data_o,     // 來源暫存器 1 的資料
    output wire [31:0] rs2_data_o,     // 來源暫存器 2 的資料
    output wire [31:0] imm_ext_o,      // 符號擴展的立即值
    output wire [4:0]  rs1_addr_o,     // 來源暫存器 1 的位址
    output wire [4:0]  rs2_addr_o,     // 來源暫存器 2 的位址
    output wire [4:0]  rd_addr_o,      // 目標暫存器的位址
    output wire [31:0] id_pc_plus_4_o, // 傳遞的 PC + 4

    // EX 階段的控制信號
    output wire        alu_src_o,      // ALU 運算元 B 的來源（0：rs2_data，1：立即值）
    output wire [3:0]  alu_op_o,       // ALU 運算類型
    // MEM 階段的控制信號（通過 EX 階段）
    output wire        mem_read_o,     // 記憶體讀取啟用
    output wire        mem_write_o,    // 記憶體寫入啟用
    // WB 階段的控制信號（通過 EX、MEM 階段）
    output wire        reg_write_o,    // 暫存器寫入啟用
    output wire [1:0]  mem_to_reg_o,   // 寫回資料來源（00：ALU，01：記憶體，10：PC+4 用於 JAL/JALR）
    // 分支和跳躍控制信號
    output wire        branch_o,       // 分支指令標誌
    output wire        jump_o          // 跳躍指令標誌

    // 輸出到危害單元（如果在這裡檢測到因載入指令的資料相依性而需要停滯）
    // output wire        id_stall_o
);

    // 指令欄位提取
    wire [6:0]  opcode  = instr_i[6:0];
    wire [4:0]  rd      = instr_i[11:7];
    wire [2:0]  funct3  = instr_i[14:12];
    wire [4:0]  rs1     = instr_i[19:15];
    wire [4:0]  rs2     = instr_i[24:20];
    wire [6:0]  funct7  = instr_i[31:25];

    // 暫存器檔案
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

    // 寫入後暫存器值的除錯輸出
    // always @(posedge clk) begin
    //     if (wb_reg_write_i) begin
    //         $display("DEBUG REG WRITE: rd_addr=%h, rd_data=%h", wb_rd_addr_i, wb_data_i);
    //     end
    // end

    // 立即值產生器實例
    immediate_generator u_imm_gen (
        .instr    (instr_i),
        .imm_ext_o(imm_ext_o)
    );

    // 控制單元實例
    control_unit u_control_unit (
        .opcode      (opcode),
        .funct3      (funct3),
        .funct7      (funct7),
        .alu_src_o   (alu_src_o),
        .alu_op_o    (alu_op_o),
        .mem_read_o  (mem_read_o),
        .mem_write_o (mem_write_o),
        .reg_write_o (reg_write_o),
        .mem_to_reg_o(mem_to_reg_o),
        .branch_o    (branch_o),      // 分支指令標誌
        .jump_o      (jump_o)         // 跳躍指令標誌
    );

    // MUL 指令處理時的除錯輸出
    // always @(*) begin
    //     if (opcode == 7'b0110011 && funct3 == 3'b000 && funct7 == 7'b0000001) begin
    //         $display("DEBUG ID MUL: rs1_addr=%h, rs2_addr=%h, rs1_data=%h, rs2_data=%h, alu_op=%h", 
    //                 instr_i[19:15], instr_i[24:20], rs1_data_o, rs2_data_o, alu_op_o);
    //     end
    // end

    // 傳遞 PC+4
    assign id_pc_plus_4_o = pc_plus_4_i;

    // 傳遞暫存器位址
    assign rs1_addr_o = rs1;
    assign rs2_addr_o = rs2;
    assign rd_addr_o  = rd;

    // 停滯檢測邏輯（簡化的佔位符）
    // assign id_stall_o = (mem_read_o && reg_write_o && ((rd == rs1) || (rd == rs2))); // 基本的載入-使用危害

endmodule
