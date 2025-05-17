// RISC-V 32IM CPU - 乘法器單元（用於 M 擴充）
// 檔案：hardware/rtl/multiplier.v

`timescale 1ns / 1ps

// 如果未全域包含或使用 control_unit/alu_op 的參數，則定義 MUL 操作
`ifndef MUL_OPS_DEFINED
`define MUL_OPS_DEFINED
    // 這些應該對應到特定的 alu_op_i 值或專用的 mul_op 輸入
    `define ALU_OP_MUL    4'b1010 // 來自 control_unit 的範例
    // 如果此單元處理的不只是 MUL，則定義其他操作
    // `define ALU_OP_MULH   4'bxxxx
    // `define ALU_OP_MULHSU 4'bxxxx
    // `define ALU_OP_MULHU  4'bxxxx
`endif

module multiplier (
    input  wire        clk,            // 時脈，如果是多週期或管線化
    input  wire        rst_n,          // 重置

    input  wire [31:0] operand_a_i,    // 運算元 A（來自 rs1_data）
    input  wire [31:0] operand_b_i,    // 運算元 B（來自 rs2_data）
    input  wire [3:0]  mul_op_i,       // 乘法操作選擇（例如，來自 alu_op_o）
                                      // 需要區分 MUL、MULH、MULHSU、MULHU

    output reg [31:0] result_o         // 乘法結果（MUL 使用低 32 位元）
                                      // 對於 MULH/MULHSU/MULHU，這將是高 32 位元
);

    // 完整 64 位元乘積的內部結果
    wire [63:0] product_full;

    // 執行乘法
    // 對於 MUL，我們需要 (rs1 * rs2) 的低 32 位元
    // 對於 MULH，我們需要 ($signed(rs1) * $signed(rs2)) 的高 32 位元
    // 對於 MULHSU，我們需要 ($signed(rs1) * $unsigned(rs2)) 的高 32 位元
    // 對於 MULHU，我們需要 ($unsigned(rs1) * $unsigned(rs2)) 的高 32 位元

    // 組合邏輯乘法器（對於合成可能較慢，可能需要管線化以提高效能）
    // 如果需要，使用 SystemVerilog 風格的型別轉換進行有號乘法
    // 如果不小心，Verilog 的 '*' 運算子在兩個 32 位元數字上會產生 32 位元結果
    // 要獲得 64 位元結果，運算元可能需要擴展或使用特定的有號乘法

    // 用於 MUL 的簡單組合邏輯乘法器（低 32 位元）
    // 對於有號操作，確保運算元被視為有號數
    // $signed() 將向量轉換為有號數以進行算術運算

    // 各種乘法類型的完整 64 位元乘積
    wire [63:0] product_signed_signed;
    wire [63:0] product_signed_unsigned;
    wire [63:0] product_unsigned_unsigned;

    assign product_signed_signed     = $signed(operand_a_i) * $signed(operand_b_i);
    assign product_signed_unsigned   = $signed(operand_a_i) * operand_b_i; // operand_b_i 預設為無號數
    assign product_unsigned_unsigned = operand_a_i * operand_b_i;

    always @(*) begin
        // 預設結果
        result_o = 32'hxxxxxxxx;

        // 根據 mul_op_i 選擇結果
        // 這假設 mul_op_i 被編碼以選擇乘法類型
        // 編碼必須與 control_unit 通過 alu_op_o 提供的相符
        case (mul_op_i) // 這應該與 `define 的 ALU_OP_MUL 等相符
            `ALU_OP_MUL: begin // MUL：rs1 * rs2 的低 32 位元
                result_o = product_signed_signed[31:0];
            end
            // 如果此模組處理 MULH、MULHSU、MULHU，則添加相應的 case
            // 例如，如果 `ALU_OP_MULH` 被定義為 4'b1011：
            // `ALU_OP_MULH: begin // MULH：signed(rs1) * signed(rs2) 的高 32 位元
            //     result_o = product_signed_signed[63:32];
            // end
            // `ALU_OP_MULHSU: begin // MULHSU：signed(rs1) * unsigned(rs2) 的高 32 位元
            //     result_o = product_signed_unsigned[63:32];
            // end
            // `ALU_OP_MULHU: begin // MULHU：unsigned(rs1) * unsigned(rs2) 的高 32 位元
            //     result_o = product_unsigned_unsigned[63:32];
            // end
            default: begin
                // 如果 mul_op_i 不是此模組處理的乘法操作，
                // 輸出未定義或零。或者此模組應該只在解碼出乘法操作時啟動
                // 目前，如果不是 MUL，輸出未定義
                // 這意味著 ex_stage 在 ALU 和乘法器輸出之間選擇
                if (mul_op_i == `ALU_OP_MUL) begin // 如果 case 是完整的，這是多餘的檢查
                     result_o = product_signed_signed[31:0];
                end else begin
                     result_o = 32'hxxxxxxxx; // 對於這個簡單版本，不是識別的乘法操作
                end
            end
        endcase
    end

    // 如果這個乘法器是多週期的，這裡需要狀態機和暫存器
    // 對於只支援 MUL 的簡單單週期（組合邏輯）版本：
    // assign result_o = product_unsigned_unsigned[31:0]; // 如果只支援 MUL，這將是結果

endmodule
