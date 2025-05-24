// RISC-V 32I CPU - 危險檢測單元
// 檔案：hardware/rtl/hazard_detection_unit.v

`timescale 1ns / 1ps

module hazard_detection_unit (
    input  wire        clk,
    input  wire        rst_n,
    
    // 來自 IF 階段
    input  wire [31:0] if_pc_i,
    
    // 來自 ID 階段
    input  wire [4:0]  id_rs1_addr_i,
    input  wire [4:0]  id_rs2_addr_i,
    input  wire [6:0]  id_opcode_i,
    input  wire [2:0]  id_funct3_i,
    
    // 來自 EX 階段
    input  wire [4:0]  ex_rd_addr_i,
    input  wire        ex_mem_read_i,
    input  wire        ex_is_branch_i,
    input  wire        ex_is_jal_i,
    input  wire        ex_is_jalr_i,
    input  wire        ex_branch_taken_i,
    input  wire [31:0] ex_branch_target_i,
    input  wire [31:0] ex_pc_i,
    
    // 來自 MEM 階段
    input  wire        mem_branch_taken_i,
    input  wire [31:0] mem_branch_target_i,
    input  wire [31:0] mem_pc_i,
    
    // 控制輸出
    output reg         pc_write_en_o,        // PC 寫入啟用
    output reg         if_id_write_en_o,     // IF/ID 管線暫存器寫入啟用
    output reg         if_id_flush_o,        // IF/ID 管線暫存器清除
    output reg         id_ex_flush_o,        // ID/EX 管線暫存器清除
    output reg         ex_mem_flush_o,       // EX/MEM 管線暫存器清除
    output reg [31:0]  branch_target_pc_o,   // 分支目標 PC
    output reg         take_branch_o,        // 分支採用信號
    
    // 停滯信號
    output wire        load_use_hazard_o     // 載入-使用危險
);

    // RISC-V 操作碼
    localparam [6:0] OPCODE_LOAD   = 7'b0000011;
    localparam [6:0] OPCODE_BRANCH = 7'b1100011;
    localparam [6:0] OPCODE_JALR   = 7'b1100111;
    localparam [6:0] OPCODE_JAL    = 7'b1101111;
    
    // 載入-使用危險檢測
    wire load_hazard_rs1 = (ex_mem_read_i && (ex_rd_addr_i != 5'b0) && (ex_rd_addr_i == id_rs1_addr_i));
    wire load_hazard_rs2 = (ex_mem_read_i && (ex_rd_addr_i != 5'b0) && (ex_rd_addr_i == id_rs2_addr_i));
    
    assign load_use_hazard_o = load_hazard_rs1 || load_hazard_rs2;
    
    // 分支危險檢測
    wire is_branch_instruction = (id_opcode_i == OPCODE_BRANCH);
    wire is_jalr_instruction = (id_opcode_i == OPCODE_JALR);
    wire is_jal_instruction = (id_opcode_i == OPCODE_JAL);
    wire has_control_hazard = is_branch_instruction || is_jalr_instruction;
    
    // 分支預測錯誤檢測 (簡單的靜態預測: 向後跳轉採用，向前跳轉不採用)
    reg branch_prediction;
    always @(*) begin
        if (is_jal_instruction) begin
            branch_prediction = 1'b1; // JAL 永遠跳轉
        end else if (is_branch_instruction) begin
            // 簡單的靜態預測：如果是負偏移（向後跳轉），預測採用
            // 在 ID 階段我們還沒有立即值，所以使用簡單的策略
            branch_prediction = 1'b0; // 預設不採用分支
        end else begin
            branch_prediction = 1'b0;
        end
    end
    
    // 分支預測錯誤檢測
    wire branch_misprediction = ex_is_branch_i && (ex_branch_taken_i != branch_prediction);
    wire jump_detected = ex_is_jal_i || ex_is_jalr_i;
    
    // 管線控制邏輯
    always @(*) begin
        // 預設值 - 正常管線運作
        pc_write_en_o = 1'b1;
        if_id_write_en_o = 1'b1;
        if_id_flush_o = 1'b0;
        id_ex_flush_o = 1'b0;
        ex_mem_flush_o = 1'b0;
        branch_target_pc_o = 32'b0;
        take_branch_o = 1'b0;
        
        // 載入-使用危險處理
        if (load_use_hazard_o) begin
            // 停滯 PC 和 IF/ID 管線暫存器
            pc_write_en_o = 1'b0;
            if_id_write_en_o = 1'b0;
            // 在 ID/EX 管線暫存器中插入氣泡 (NOP)
            id_ex_flush_o = 1'b1;
        end
        // 分支/跳轉處理
        else if (jump_detected || branch_misprediction || ex_branch_taken_i) begin
            // 清除已錯誤取得的指令
            if_id_flush_o = 1'b1;
            id_ex_flush_o = 1'b1;
            
            // 設定新的 PC 目標
            branch_target_pc_o = ex_branch_target_i;
            take_branch_o = 1'b1;
        end
        // MEM 階段的分支處理 (如果分支在 MEM 階段解決)
        else if (mem_branch_taken_i) begin
            if_id_flush_o = 1'b1;
            id_ex_flush_o = 1'b1;
            ex_mem_flush_o = 1'b1;
            
            branch_target_pc_o = mem_branch_target_i;
            take_branch_o = 1'b1;
        end
    end
    
    // 分支預測統計 (可選，用於除錯)
    reg [31:0] branch_count;
    reg [31:0] branch_correct;
    reg [31:0] branch_incorrect;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            branch_count <= 32'b0;
            branch_correct <= 32'b0;
            branch_incorrect <= 32'b0;
        end else begin
            if (ex_is_branch_i) begin
                branch_count <= branch_count + 1;
                if (branch_misprediction) begin
                    branch_incorrect <= branch_incorrect + 1;
                end else begin
                    branch_correct <= branch_correct + 1;
                end
            end
        end
    end

endmodule 