// Instruction-level trace debug testbench
// File: hardware/sim/tb_instruction_trace.v

`timescale 1ns / 1ps

module tb_instruction_trace();

    // Clock and reset
    reg clk;
    reg rst_n;
    
    // CPU interface
    wire [31:0] i_mem_addr;
    reg  [31:0] i_mem_rdata;
    wire [31:0] d_mem_addr;
    wire [31:0] d_mem_wdata;
    wire [3:0]  d_mem_wen;
    reg  [31:0] d_mem_rdata;
    
    // Memory arrays
    reg [31:0] instr_mem [0:1023];
    reg [31:0] data_mem [0:1023];
    
    // Instruction tracking
    reg [31:0] pc_history [0:1023];
    reg [31:0] instr_history [0:1023];
    integer instr_count = 0;
    
    // Register tracking
    reg [31:0] prev_registers [0:31];
    
    // CPU instantiation
    cpu_top u_cpu_top (
        .clk            (clk),
        .rst_n          (rst_n),
        .i_mem_addr     (i_mem_addr),
        .i_mem_rdata    (i_mem_rdata),
        .d_mem_addr     (d_mem_addr),
        .d_mem_wdata    (d_mem_wdata),
        .d_mem_wen      (d_mem_wen),
        .d_mem_rdata    (d_mem_rdata)
    );
    
    // Load test program
    initial begin
        $readmemh("tests/hex_outputs/convolution_test.hex", instr_mem);
        $display("=== INSTRUCTION TRACE DEBUG ===");
        $display("Loaded test program");
        
        // Initialize register tracking
        for (integer i = 0; i < 32; i = i + 1) begin
            prev_registers[i] = 32'h0;
        end
        
        // Print loaded instructions
        $display("\nLoaded Instructions:");
        for (integer i = 0; i < 24; i = i + 1) begin
            $display("  [%0d] 0x%08x", i*4, instr_mem[i]);
        end
        $display("");
    end
    
    // Instruction memory
    always @(*) begin
        if (i_mem_addr < 4*1024) begin
            i_mem_rdata = instr_mem[i_mem_addr / 4];
        end else begin
            i_mem_rdata = 32'h00000013; // NOP for out of bounds
        end
    end
    
    // Data memory read
    always @(*) begin
        if (d_mem_addr < 4*1024) begin
            d_mem_rdata = data_mem[d_mem_addr / 4];
        end else begin
            d_mem_rdata = 32'hxxxxxxxx;
        end
    end
    
    // Data memory write with detailed monitoring
    always @(posedge clk) begin
        if (rst_n) begin
            if (d_mem_wen != 4'b0000 && d_mem_addr < 4*1024) begin
                if (d_mem_wen == 4'b1111) begin
                    data_mem[d_mem_addr / 4] <= d_mem_wdata;
                    $display("[CYCLE %0d] MEMORY WRITE: addr=0x%08x, data=0x%08x (index=%0d)", 
                             cycle_count, d_mem_addr, d_mem_wdata, d_mem_addr / 4);
                end
            end
        end
    end
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Reset generation
    initial begin
        rst_n = 0;
        #50;
        rst_n = 1;
        $display("[RESET] Reset released at time %0t", $time);
    end
    
    // Instruction execution tracking
    integer cycle_count = 0;
    reg [31:0] last_pc = 32'hffffffff;
    
    always @(posedge clk) begin
        if (rst_n) begin
            cycle_count <= cycle_count + 1;
            
            // Track PC changes (new instruction fetch)
            if (i_mem_addr != last_pc && i_mem_addr < 96) begin // Only track program instructions
                pc_history[instr_count] = i_mem_addr;
                instr_history[instr_count] = i_mem_rdata;
                
                $display("[CYCLE %0d] FETCH: PC=0x%08x, Instr=0x%08x (%s)", 
                         cycle_count, i_mem_addr, i_mem_rdata, decode_instruction(i_mem_rdata));
                
                instr_count = instr_count + 1;
                last_pc = i_mem_addr;
            end
            
            // Track register file changes (simple approximation)
            if (cycle_count % 10 == 0) begin // Check every 10 cycles
                check_register_changes();
            end
            
            // Check for program end
            if (data_mem[768/4] == 32'h1) begin
                $display("\n=== PROGRAM COMPLETED ===");
                $display("Execution finished at cycle %0d", cycle_count);
                print_final_results();
                #100;
                $finish;
            end
            
            // Safety timeout
            if (cycle_count > 200) begin
                $display("\n=== TIMEOUT ===");
                $display("Test timeout at cycle %0d", cycle_count);
                print_final_results();
                $finish;
            end
        end
    end
    
    // Function to decode instruction for display
    function [127:0] decode_instruction;
        input [31:0] instr;
        begin
            case (instr[6:0])
                7'b0010011: begin // I-type (ADDI)
                    if (instr[14:12] == 3'b000) begin
                        decode_instruction = "ADDI";
                    end else begin
                        decode_instruction = "I-TYPE";
                    end
                end
                7'b0110011: begin // R-type (ADD, SUB)
                    if (instr[14:12] == 3'b000) begin
                        if (instr[30] == 1'b0) begin
                            decode_instruction = "ADD";
                        end else begin
                            decode_instruction = "SUB";
                        end
                    end else begin
                        decode_instruction = "R-TYPE";
                    end
                end
                7'b0100011: decode_instruction = "SW";    // Store
                7'b0000011: decode_instruction = "LW";    // Load
                7'b1100011: decode_instruction = "BEQ";   // Branch
                7'b0000000: decode_instruction = "NOP";   // NOP (if all zeros)
                default:    decode_instruction = "UNKNOWN";
            endcase
        end
    endfunction
    
    // Task to check register changes
    task check_register_changes;
        integer i;
        begin
            // Note: This is a simplified check - in real implementation we'd need
            // to access the register file directly, which requires modifying the CPU
            // For now, we'll rely on explicit register write monitoring elsewhere
        end
    endtask
    
    // Task to print final results
    task print_final_results;
        begin
            $display("\n=== EXECUTION SUMMARY ===");
            $display("Total instructions executed: %0d", instr_count);
            $display("Total cycles: %0d", cycle_count);
            if (cycle_count > 0) begin
                $display("Instructions per cycle: %0.2f", $itor(instr_count) / $itor(cycle_count));
            end
            
            $display("\n=== MEMORY DUMP ===");
            $display("Result area (0x200-0x218):");
            for (integer i = 128; i < 135; i = i + 1) begin
                $display("  mem[%0d] (0x%03x) = 0x%08x", i, i*4, data_mem[i]);
            end
            
            $display("\nEnd marker area (0x300):");
            $display("  mem[192] (0x300) = 0x%08x", data_mem[192]);
            
            $display("\n=== INSTRUCTION TRACE ===");
            for (integer i = 0; i < instr_count && i < 30; i = i + 1) begin
                $display("  [%0d] PC=0x%08x, Instr=0x%08x", i, pc_history[i], instr_history[i]);
            end
        end
    endtask
    
endmodule 