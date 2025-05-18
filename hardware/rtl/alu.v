// RISC-V 32IM CPU - 算術邏輯單元 (ALU)
// 檔案：hardware/rtl/alu.v

`timescale 1ns / 1ps

// 如果尚未全域定義，則重新定義 ALU 運算，或使用參數
`ifndef ALU_OPS_DEFINED
`define ALU_OPS_DEFINED
    `define ALU_OP_ADD  4'b0000  // 加法
    `define ALU_OP_SUB  4'b0001  // 減法
    `define ALU_OP_SLL  4'b0010  // 邏輯左移
    `define ALU_OP_SLT  4'b0011  // 有號數小於
    `define ALU_OP_SLTU 4'b0100  // 無號數小於
    `define ALU_OP_XOR  4'b0101  // 互斥或
    `define ALU_OP_SRL  4'b0110  // 邏輯右移
    `define ALU_OP_SRA  4'b0111  // 算術右移
    `define ALU_OP_OR   4'b1000  // 或
    `define ALU_OP_AND  4'b1001  // 且
    // 注意：乘法運算在此設計中由獨立的乘法器單元處理
    // LUI/AUIPC 可能通過傳遞 operand_b 或特定邏輯處理（如果 rs1 是 PC/零）
`endif

module alu (
    input  wire [31:0] operand_a_i,  // 運算元 A
    input  wire [31:0] operand_b_i,  // 運算元 B（可以是 rs2_data 或立即值）
    input  wire [3:0]  alu_op_i,     // ALU 運算選擇

    output reg [31:0] result_o,     // ALU 運算結果
    output reg        zero_flag_o   // 零值旗標（result_o == 0）
);

    // 內部連線用於移位量（operand_b 的低 5 位元）
    wire [4:0] shift_amount = operand_b_i[4:0];

    always @(*) begin
        // 預設賦值以避免未覆蓋的情況產生鎖存器
        result_o = 32'hxxxxxxxx; // 未定義值（安全考量）

        case (alu_op_i)
            `ALU_OP_ADD:  result_o = operand_a_i + operand_b_i;
            `ALU_OP_SUB:  result_o = operand_a_i - operand_b_i;
            `ALU_OP_SLL:  result_o = operand_a_i << shift_amount;
            `ALU_OP_SLT:  result_o = ($signed(operand_a_i) < $signed(operand_b_i)) ? 32'd1 : 32'd0;
            `ALU_OP_SLTU: result_o = (operand_a_i < operand_b_i) ? 32'd1 : 32'd0;
            `ALU_OP_XOR:  result_o = operand_a_i ^ operand_b_i;
            `ALU_OP_SRL:  result_o = operand_a_i >> shift_amount;
            `ALU_OP_SRA:  result_o = $signed(operand_a_i) >>> shift_amount;
            `ALU_OP_OR:   result_o = operand_a_i | operand_b_i;
            `ALU_OP_AND:  result_o = operand_a_i & operand_b_i;
            // LUI：operand_a 為 0（由控制或連線強制），operand_b 為 imm_u。結果為 imm_u。
            // AUIPC：operand_a 為 PC，operand_b 為 imm_u。結果為 PC + imm_u。
            // 這些通常通過 ADD 運算配合適當的輸入來處理。
            // 如果 alu_op_i 有 LUI/AUIPC 的特定編碼，它們可能是：
            // `ALU_OP_LUI_AUIPC: result_o = operand_b_i; // 如果 operand_a 已預先加入或為零
            // 或者，更常見的是，LUI 使用 ADD 並以 x0 作為 rs1。AUIPC 使用 ADD 並以 PC 作為 rs1。
            default:      result_o = 32'hxxxxxxxx; // 未定義的運算
        endcase
    end

    // 零值旗標計算
    always @(*) begin
        if (result_o == 32'b0) begin
            zero_flag_o = 1'b1;
        end else begin
            zero_flag_o = 1'b0;
        end
    end

endmodule
