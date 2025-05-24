// RISC-V 32I CPU - 分支單元
// 檔案：hardware/rtl/branch_unit.v

`timescale 1ns / 1ps

module branch_unit (
    input  wire        clk,
    input  wire        rst_n,
    
    // 來自 EX 階段的輸入
    input  wire [31:0] rs1_data_i,        // 第一個運算元
    input  wire [31:0] rs2_data_i,        // 第二個運算元
    input  wire [31:0] pc_i,              // 當前 PC 值
    input  wire [31:0] imm_i,             // 分支偏移量立即值
    input  wire [2:0]  funct3_i,          // 分支指令的 funct3 欄位
    input  wire        is_branch_i,       // 是否為分支指令
    input  wire        is_jal_i,          // 是否為 JAL 指令
    input  wire        is_jalr_i,         // 是否為 JALR 指令
    
    // 分支決策輸出
    output reg         branch_taken_o,    // 分支是否被採用
    output reg  [31:0] branch_target_o,   // 分支目標地址
    output wire        is_jump_o          // 是否為跳轉指令 (JAL/JALR)
);

    // RISC-V 分支指令 funct3 編碼
    localparam [2:0] FUNCT3_BEQ  = 3'b000;
    localparam [2:0] FUNCT3_BNE  = 3'b001;
    localparam [2:0] FUNCT3_BLT  = 3'b100;
    localparam [2:0] FUNCT3_BGE  = 3'b101;
    localparam [2:0] FUNCT3_BLTU = 3'b110;
    localparam [2:0] FUNCT3_BGEU = 3'b111;

    // 內部信號
    wire signed [31:0] rs1_signed = $signed(rs1_data_i);
    wire signed [31:0] rs2_signed = $signed(rs2_data_i);
    wire [31:0] rs1_unsigned = rs1_data_i;
    wire [31:0] rs2_unsigned = rs2_data_i;
    
    // 比較結果
    wire eq  = (rs1_data_i == rs2_data_i);
    wire ne  = !eq;
    wire lt  = (rs1_signed < rs2_signed);
    wire ge  = !lt;
    wire ltu = (rs1_unsigned < rs2_unsigned);
    wire geu = !ltu;
    
    // 跳轉指令檢測
    assign is_jump_o = is_jal_i || is_jalr_i;
    
    // 分支條件判斷
    reg branch_condition;
    always @(*) begin
        case (funct3_i)
            FUNCT3_BEQ:  branch_condition = eq;
            FUNCT3_BNE:  branch_condition = ne;
            FUNCT3_BLT:  branch_condition = lt;
            FUNCT3_BGE:  branch_condition = ge;
            FUNCT3_BLTU: branch_condition = ltu;
            FUNCT3_BGEU: branch_condition = geu;
            default:     branch_condition = 1'b0;
        endcase
    end
    
    // 分支決策邏輯
    always @(*) begin
        if (is_jal_i || is_jalr_i) begin
            // JAL 和 JALR 永遠跳轉
            branch_taken_o = 1'b1;
        end else if (is_branch_i) begin
            // 條件分支根據條件決定
            branch_taken_o = branch_condition;
        end else begin
            // 非分支/跳轉指令
            branch_taken_o = 1'b0;
        end
    end
    
    // 分支目標地址計算
    always @(*) begin
        if (is_jalr_i) begin
            // JALR: rs1 + imm，最低位設為 0
            branch_target_o = (rs1_data_i + imm_i) & 32'hfffffffe;
        end else if (is_jal_i || (is_branch_i && branch_condition)) begin
            // JAL 或採用的分支: PC + imm
            branch_target_o = pc_i + imm_i;
        end else begin
            // 不跳轉: PC + 4
            branch_target_o = pc_i + 32'd4;
        end
    end

endmodule 