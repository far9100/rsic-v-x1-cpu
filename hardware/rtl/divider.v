// RISC-V 32IM CPU - 除法器單元（用於 M 擴充）
// 檔案：hardware/rtl/divider.v

`timescale 1ns / 1ps

// 除法器運算定義
`ifndef DIV_OPS_DEFINED
`define DIV_OPS_DEFINED
    `define ALU_OP_DIV    4'b1100 // 有符號除法
    `define ALU_OP_DIVU   4'b1101 // 無符號除法
    `define ALU_OP_REM    4'b1110 // 有符號餘數
    `define ALU_OP_REMU   4'b1111 // 無符號餘數
`endif

module divider (
    input  wire        clk,            // 時脈
    input  wire        rst_n,          // 重置

    input  wire [31:0] operand_a_i,    // 被除數（來自 rs1_data）
    input  wire [31:0] operand_b_i,    // 除數（來自 rs2_data）
    input  wire [3:0]  div_op_i,       // 除法操作選擇
    input  wire        div_valid_i,    // 除法操作有效信號

    output reg [31:0] result_o,        // 除法結果
    output reg        div_ready_o      // 除法完成信號
);

    // 除零檢測
    wire div_by_zero = (operand_b_i == 32'b0);
    
    // 符號位處理
    wire dividend_sign = operand_a_i[31];
    wire divisor_sign = operand_b_i[31];
    wire result_sign = dividend_sign ^ divisor_sign;
    
    // 絕對值計算
    wire [31:0] abs_dividend = dividend_sign ? (~operand_a_i + 1) : operand_a_i;
    wire [31:0] abs_divisor = divisor_sign ? (~operand_b_i + 1) : operand_b_i;
    
    // 無符號除法結果
    reg [31:0] unsigned_quotient;
    reg [31:0] unsigned_remainder;
    
    // 組合邏輯除法器（簡化實現）
    always @(*) begin
        // 預設值
        unsigned_quotient = 32'b0;
        unsigned_remainder = 32'b0;
        
        if (!div_by_zero) begin
            // 使用Verilog內建的除法和餘數運算
            case (div_op_i)
                `ALU_OP_DIV, `ALU_OP_REM: begin
                    // 有符號運算使用絕對值
                    unsigned_quotient = abs_dividend / abs_divisor;
                    unsigned_remainder = abs_dividend % abs_divisor;
                end
                `ALU_OP_DIVU, `ALU_OP_REMU: begin
                    // 無符號運算直接計算
                    unsigned_quotient = operand_a_i / operand_b_i;
                    unsigned_remainder = operand_a_i % operand_b_i;
                end
                default: begin
                    unsigned_quotient = 32'b0;
                    unsigned_remainder = 32'b0;
                end
            endcase
        end
    end
    
    // 結果選擇和符號處理
    always @(*) begin
        div_ready_o = 1'b1; // 組合邏輯除法器，立即完成
        
        if (div_by_zero) begin
            // RISC-V 除零處理規範
            case (div_op_i)
                `ALU_OP_DIV: result_o = 32'hFFFFFFFF; // -1
                `ALU_OP_DIVU: result_o = 32'hFFFFFFFF; // 2^32-1
                `ALU_OP_REM: result_o = operand_a_i;   // 被除數
                `ALU_OP_REMU: result_o = operand_a_i;  // 被除數
                default: result_o = 32'b0;
            endcase
        end else begin
            case (div_op_i)
                `ALU_OP_DIV: begin
                    // 有符號除法結果
                    if (operand_a_i == 32'h80000000 && operand_b_i == 32'hFFFFFFFF) begin
                        // 溢出情況：-2^31 / -1 = 2^31（溢出）
                        result_o = 32'h80000000; // 返回 -2^31
                    end else begin
                        result_o = result_sign ? (~unsigned_quotient + 1) : unsigned_quotient;
                    end
                end
                `ALU_OP_DIVU: begin
                    // 無符號除法結果
                    result_o = unsigned_quotient;
                end
                `ALU_OP_REM: begin
                    // 有符號餘數
                    if (operand_a_i == 32'h80000000 && operand_b_i == 32'hFFFFFFFF) begin
                        result_o = 32'b0; // 溢出情況的餘數為0
                    end else begin
                        // 餘數的符號與被除數相同
                        result_o = dividend_sign ? (~unsigned_remainder + 1) : unsigned_remainder;
                    end
                end
                `ALU_OP_REMU: begin
                    // 無符號餘數
                    result_o = unsigned_remainder;
                end
                default: begin
                    result_o = 32'b0;
                end
            endcase
        end
    end

endmodule 