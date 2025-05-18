// RISC-V 32I CPU Branch Instruction Test Platform
// File: hardware/sim/tb_branch_test.v

`timescale 1ns / 1ps

module tb_branch_test;

    // Parameters
    localparam CLK_PERIOD = 10; // Clock period (ns) (e.g., 100 MHz clock)
    localparam RESET_DURATION = CLK_PERIOD * 5; // Reset hold time
    localparam MAX_SIM_CYCLES = 2000; // Maximum simulation cycles
    localparam MEM_SIZE_WORDS = 1024; // Memory size (words)
    
    // Test result memory addresses
    localparam RESULT_BASE_ADDR = 256;  // 0x100 / 4 = 64 * 4

    // Testbench signals
    reg         clk;
    reg         rst_n;

    // Device Under Test (DUT) interface signals
    wire [31:0] i_mem_addr;
    reg  [31:0] i_mem_rdata; // Driven by testbench based on i_mem_addr

    wire [31:0] d_mem_addr;
    wire [31:0] d_mem_wdata;
    wire [3:0]  d_mem_wen;
    reg  [31:0] d_mem_rdata; // Driven by testbench based on d_mem_addr

    // Instantiate CPU
    cpu_top u_cpu (
        .clk            (clk),
        .rst_n          (rst_n),
        .i_mem_addr     (i_mem_addr),
        .i_mem_rdata    (i_mem_rdata),
        .d_mem_addr     (d_mem_addr),
        .d_mem_wdata    (d_mem_wdata),
        .d_mem_wen      (d_mem_wen),
        .d_mem_rdata    (d_mem_rdata)
    );

    // Memory model (simplified)
    // Instruction memory (like ROM)
    reg [31:0] instr_mem [0:MEM_SIZE_WORDS-1];
    integer i;
    initial begin
        // Load instructions from test file - using relative path corrected
        $readmemh("./tests/hex_outputs/branch_integrated_test.hex", instr_mem);
        
        // Display first 10 instructions for debugging
        $display("Instruction Memory Initialization:");
        for (i = 0; i < 10; i = i + 1) begin
            $display("instr_mem[%0d] = %h", i, instr_mem[i]);
        end

        // Initialize data memory (e.g., set to zero)
        for (i = 0; i < MEM_SIZE_WORDS; i = i + 1) begin
            data_mem[i] = 32'b0;
        end
    end

    // Instruction memory read logic (combinational)
    always @(*) begin
        if (i_mem_addr < 4*MEM_SIZE_WORDS) begin // Check boundary (byte addr vs word array)
            i_mem_rdata = instr_mem[i_mem_addr / 4];
        end else begin
            i_mem_rdata = 32'hdeadbeef; // Outside boundary, return identifiable invalid instruction
        end
    end

    // Data memory (like RAM)
    reg [31:0] data_mem [0:MEM_SIZE_WORDS-1];

    // Enhanced debug information for instruction fetching
    reg [31:0] prev_pc = 0;
    always @(posedge clk) begin
        if (rst_n) begin
            // Track PC changes to detect branches
            if (prev_pc != i_mem_addr) begin
                $display("PC changed from 0x%h to 0x%h at cycle %0d", prev_pc, i_mem_addr, cycle_count_sim);
                
                // Specifically look for backward branch (around address 0x94-0x9C in the ASM)
                if (i_mem_addr >= 32'h00000094 && i_mem_addr <= 32'h0000009C) begin
                    $display("*** DETECTED BACKWARD BRANCH REGION at cycle %0d, PC=0x%h, instr=0x%h ***", 
                             cycle_count_sim, i_mem_addr, i_mem_rdata);
                end
            end
            prev_pc = i_mem_addr;
        end
    end

    // Data memory read logic (combinational)
    always @(*) begin
        if (d_mem_addr < 4*MEM_SIZE_WORDS) begin // Check boundary
            d_mem_rdata = data_mem[d_mem_addr / 4];
        end else begin
            d_mem_rdata = 32'hxxxxxxxx; // Outside boundary
        end
    end

    // Data memory write logic (synchronized to clock)
    always @(posedge clk) begin
        if (rst_n) begin // Only write when not in reset
            if (d_mem_wen != 4'b0000 && d_mem_addr < 4*MEM_SIZE_WORDS) begin
                if (d_mem_wen == 4'b1111) begin // Word write
                    data_mem[d_mem_addr / 4] <= d_mem_wdata;
                    // Enhanced debugging for memory writes, especially for test results
                    $display("*** MEMORY WRITE: Addr=0x%h, Index=%0d, Data=0x%h, Value=%0d, Cycle=%0d ***", 
                              d_mem_addr, d_mem_addr / 4, d_mem_wdata, d_mem_wdata, cycle_count_sim);
                    
                    // Special check for writes to test result memory area
                    if (d_mem_addr >= 256 && d_mem_addr <= 304) begin
                        $display(">>> TEST RESULT WRITE: Test=%0d, Data=%0d, Pass=%s", 
                                 (d_mem_addr - 256)/4, d_mem_wdata, 
                                 (d_mem_wdata == 1) ? "TRUE(1)" : "FALSE(-1)");
                    end
                end
            end
        end
    end

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Reset generation
    initial begin
        rst_n = 0; // Start reset
        #(RESET_DURATION);
        rst_n = 1; // Release reset
    end

    // Simulation control and monitoring
    integer cycle_count_sim = 0;
    initial begin
        $display("Starting RISC-V CPU Branch Instruction Test Simulation...");
        wait (rst_n === 1);
        $display("Reset released. CPU operation begins at time %0t.", $time);

        // Enhanced monitoring for test case 7
        $display("Monitoring for Backward Branch Test (Test Case 7)...");
        
        for (cycle_count_sim = 0; cycle_count_sim < MAX_SIM_CYCLES; cycle_count_sim = cycle_count_sim + 1) begin
            @(posedge clk);
            // Print fetched instruction every 50 cycles
            if (cycle_count_sim % 50 == 0) begin
                $display("Cycle %0d (Sim): Fetching Instruction: %h, PC Address: %h", 
                          cycle_count_sim, i_mem_rdata, i_mem_addr);
            end
        end

        // Check branch test results: 1 means PASS, -1 means FAIL (per ASM convention)
        $display("\n============= Branch Instruction Test Results =============");
        $display("Test Case 1.1 (BEQ Success Test): %s (Value=%0d, Expected=1)", 
                 (data_mem[64] == 1) ? "PASS" : "FAIL", data_mem[64]);
        $display("Test Case 1.2 (BEQ Fail Test): %s (Value=%0d, Expected=1)", 
                 (data_mem[65] == 1) ? "PASS" : "FAIL", data_mem[65]);
        $display("Test Case 2.1 (BNE Success Test): %s (Value=%0d, Expected=1)", 
                 (data_mem[66] == 1) ? "PASS" : "FAIL", data_mem[66]);
        $display("Test Case 2.2 (BNE Fail Test): %s (Value=%0d, Expected=1)", 
                 (data_mem[67] == 1) ? "PASS" : "FAIL", data_mem[67]);
        $display("Test Case 3.1 (BLT Success Test): %s (Value=%0d, Expected=1)", 
                 (data_mem[68] == 1) ? "PASS" : "FAIL", data_mem[68]);
        $display("Test Case 3.2 (BLT Fail Test): %s (Value=%0d, Expected=1)", 
                 (data_mem[69] == 1) ? "PASS" : "FAIL", data_mem[69]);
        $display("Test Case 4.1 (BGE Success Test): %s (Value=%0d, Expected=1)", 
                 (data_mem[70] == 1) ? "PASS" : "FAIL", data_mem[70]);
        $display("Test Case 4.2 (BGE Success Test - Equal): %s (Value=%0d, Expected=1)", 
                 (data_mem[71] == 1) ? "PASS" : "FAIL", data_mem[71]);
        $display("Test Case 5.1 (BLTU Success Test): %s (Value=%0d, Expected=1)", 
                 (data_mem[72] == 1) ? "PASS" : "FAIL", data_mem[72]);
        $display("Test Case 5.2 (BLTU Special Test - Negative): %s (Value=%0d, Expected=1)", 
                 (data_mem[73] == 1) ? "PASS" : "FAIL", data_mem[73]);
        $display("Test Case 6.1 (BGEU Success Test): %s (Value=%0d, Expected=1)", 
                 (data_mem[74] == 1) ? "PASS" : "FAIL", data_mem[74]);
        $display("Test Case 6.2 (BGEU Special Test - Negative): %s (Value=%0d, Expected=1)", 
                 (data_mem[75] == 1) ? "PASS" : "FAIL", data_mem[75]);
        $display("Test Case 7 (Backward Branch - Loop): %s (Value=%0d, Expected=1)", 
                 (data_mem[76] == 1) ? "PASS" : "FAIL", data_mem[76]);
        $display("=============================================\n");

        $display("Dumping Memory Contents for Analysis:");
        for (i = 64; i < 77; i = i + 1) begin
            $display("Memory[%0d] = 0x%h (%0d)", i, data_mem[i], data_mem[i]);
        end

        $display("Simulation completed at time %0t.", $time);
        $finish;
    end

    // Waveform output
    initial begin
        $dumpfile("tb_branch_test.vcd");
        $dumpvars(0, tb_branch_test);
        // Add instruction memory contents to waveform file
        for (i = 0; i < 32; i = i + 1) begin
            $dumpvars(0, instr_mem[i]);
        end
        // Add data memory contents to waveform file
        for (i = 64; i < 77; i = i + 1) begin  // From 256/4 to 304/4
            $dumpvars(0, data_mem[i]);
        end
    end

endmodule 