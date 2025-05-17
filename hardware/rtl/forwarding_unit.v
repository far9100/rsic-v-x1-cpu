// RISC-V 32IM CPU - 前遞單元
// 檔案：hardware/rtl/forwarding_unit.v

`timescale 1ns / 1ps

module forwarding_unit (
    input  wire        clk,
    input  wire        rst_n,
    
    // 從 EX/MEM 階段的暫存器獲取上一條指令的資訊
    input  wire        ex_mem_reg_write_i,     // 暫存器寫入控制信號
    input  wire [4:0]  ex_mem_rd_addr_i,       // 目標暫存器位址
    
    // 從 MEM/WB 階段的暫存器獲取前前一條指令的資訊
    input  wire        mem_wb_reg_write_i,     // 暫存器寫入控制信號
    input  wire [4:0]  mem_wb_rd_addr_i,       // 目標暫存器位址
    
    // 當前在 EX 階段執行的指令的來源暫存器
    input  wire [4:0]  id_ex_rs1_addr_i,       // rs1 位址
    input  wire [4:0]  id_ex_rs2_addr_i,       // rs2 位址
    
    // 前遞選擇信號輸出
    output reg  [1:0]  forward_a_sel_o,        // rs1 的前遞選擇：00=ID/EX，01=EX/MEM，10=MEM/WB
    output reg  [1:0]  forward_b_sel_o         // rs2 的前遞選擇：00=ID/EX，01=EX/MEM，10=MEM/WB
);

    // 檢測和處理資料相依性，產生前遞控制信號
    always @(*) begin
        // 預設不前遞，使用 ID/EX 階段的資料
        forward_a_sel_o = 2'b00;
        forward_b_sel_o = 2'b00;
        
        // EX 相依性（從 EX/MEM 前遞）：當前指令的 rs1 與上一條指令的 rd 衝突
        if (ex_mem_reg_write_i && 
            (ex_mem_rd_addr_i != 5'b00000) && 
            (ex_mem_rd_addr_i == id_ex_rs1_addr_i)) begin
            forward_a_sel_o = 2'b01;
        end
        
        // MEM 相依性（從 MEM/WB 前遞）：當前指令的 rs1 與前前一條指令的 rd 衝突
        // 只有當沒有 EX 相依性時才考慮 MEM 相依性
        else if (mem_wb_reg_write_i && 
                (mem_wb_rd_addr_i != 5'b00000) && 
                (mem_wb_rd_addr_i == id_ex_rs1_addr_i)) begin
            forward_a_sel_o = 2'b10;
        end
        
        // EX 相依性（從 EX/MEM 前遞）：當前指令的 rs2 與上一條指令的 rd 衝突
        if (ex_mem_reg_write_i && 
            (ex_mem_rd_addr_i != 5'b00000) && 
            (ex_mem_rd_addr_i == id_ex_rs2_addr_i)) begin
            forward_b_sel_o = 2'b01;
        end
        
        // MEM 相依性（從 MEM/WB 前遞）：當前指令的 rs2 與前前一條指令的 rd 衝突
        // 只有當沒有 EX 相依性時才考慮 MEM 相依性
        else if (mem_wb_reg_write_i && 
                (mem_wb_rd_addr_i != 5'b00000) && 
                (mem_wb_rd_addr_i == id_ex_rs2_addr_i)) begin
            forward_b_sel_o = 2'b10;
        end
    end

endmodule 