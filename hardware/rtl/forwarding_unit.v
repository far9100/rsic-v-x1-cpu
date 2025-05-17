// RISC-V 32IM CPU - Forwarding Unit
// File: hardware/rtl/forwarding_unit.v

`timescale 1ns / 1ps

module forwarding_unit (
    input  wire        clk,
    input  wire        rst_n,
    
    // 從EX/MEM階段的暫存器獲取上一條指令的資訊
    input  wire        ex_mem_reg_write_i,     // RegWrite控制信號
    input  wire [4:0]  ex_mem_rd_addr_i,       // 目的寄存器地址
    
    // 從MEM/WB階段的暫存器獲取前前一條指令的資訊
    input  wire        mem_wb_reg_write_i,     // RegWrite控制信號
    input  wire [4:0]  mem_wb_rd_addr_i,       // 目的寄存器地址
    
    // 當前在EX階段執行的指令的源寄存器
    input  wire [4:0]  id_ex_rs1_addr_i,       // rs1地址
    input  wire [4:0]  id_ex_rs2_addr_i,       // rs2地址
    
    // 前推選擇信號輸出
    output reg  [1:0]  forward_a_sel_o,        // rs1的前推選擇: 00=ID/EX, 01=EX/MEM, 10=MEM/WB
    output reg  [1:0]  forward_b_sel_o         // rs2的前推選擇: 00=ID/EX, 01=EX/MEM, 10=MEM/WB
);

    // 檢測和處理數據相依性，生成前推控制信號
    always @(*) begin
        // 默認不前推，使用ID/EX階段的數據
        forward_a_sel_o = 2'b00;
        forward_b_sel_o = 2'b00;
        
        // EX相依性（從EX/MEM前推）: 當前指令的rs1與上一條指令的rd衝突
        if (ex_mem_reg_write_i && 
            (ex_mem_rd_addr_i != 5'b00000) && 
            (ex_mem_rd_addr_i == id_ex_rs1_addr_i)) begin
            forward_a_sel_o = 2'b01;
        end
        
        // MEM相依性（從MEM/WB前推）: 當前指令的rs1與前前一條指令的rd衝突
        // 只有當沒有EX相依性時才考慮MEM相依性
        else if (mem_wb_reg_write_i && 
                (mem_wb_rd_addr_i != 5'b00000) && 
                (mem_wb_rd_addr_i == id_ex_rs1_addr_i)) begin
            forward_a_sel_o = 2'b10;
        end
        
        // EX相依性（從EX/MEM前推）: 當前指令的rs2與上一條指令的rd衝突
        if (ex_mem_reg_write_i && 
            (ex_mem_rd_addr_i != 5'b00000) && 
            (ex_mem_rd_addr_i == id_ex_rs2_addr_i)) begin
            forward_b_sel_o = 2'b01;
        end
        
        // MEM相依性（從MEM/WB前推）: 當前指令的rs2與前前一條指令的rd衝突
        // 只有當沒有EX相依性時才考慮MEM相依性
        else if (mem_wb_reg_write_i && 
                (mem_wb_rd_addr_i != 5'b00000) && 
                (mem_wb_rd_addr_i == id_ex_rs2_addr_i)) begin
            forward_b_sel_o = 2'b10;
        end
    end

endmodule 