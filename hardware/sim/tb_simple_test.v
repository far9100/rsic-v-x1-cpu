// Simple test testbench for store instruction forwarding
// File: hardware/sim/tb_simple_test.v

`timescale 1ns / 1ps

module tb_simple_test();

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
    
    // Test result variables
    reg [31:0] expected_result;
    reg [31:0] actual_result;
    integer test_pass = 0;
    
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
        $readmemh("tests/hex_outputs/simple_test.hex", instr_mem);
        $display("=== SIMPLE STORE FORWARDING TEST ===");
        $display("Testing basic store instruction forwarding");
        
        // Print loaded instructions
        $display("Loaded Instructions:");
        for (integer i = 0; i < 8; i = i + 1) begin
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
                    $display("[CYCLE %0d] MEMORY WRITE: addr=0x%08x, data=0x%08x", 
                             cycle_count, d_mem_addr, d_mem_wdata);
                    
                    // Check if this is the test result
                    if (d_mem_addr == 32'h200) begin
                        $display("  -> This is the test result!");
                        if (d_mem_wdata == 32'h5) begin
                            $display("  -> CORRECT: Expected 0x5, got 0x%08x", d_mem_wdata);
                            test_pass = 1;
                        end else begin
                            $display("  -> ERROR: Expected 0x5, got 0x%08x", d_mem_wdata);
                            test_pass = 0;
                        end
                    end
                    
                    // Check for end marker
                    if (d_mem_addr == 32'h300) begin
                        $display("  -> End marker detected!");
                        #50;
                        print_results();
                        $finish;
                    end
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
        $display("[RESET] Reset released");
    end
    
    // Cycle counter and timeout
    integer cycle_count = 0;
    
    always @(posedge clk) begin
        if (rst_n) begin
            cycle_count <= cycle_count + 1;
            
            // Safety timeout
            if (cycle_count > 100) begin
                $display("ERROR: Test timeout at cycle %0d", cycle_count);
                print_results();
                $finish;
            end
        end
    end
    
    // Print test results
    task print_results;
        begin
            $display("\n=== TEST RESULTS ===");
            if (test_pass) begin
                $display("✓ PASS: Store instruction forwarding works correctly");
            end else begin
                $display("✗ FAIL: Store instruction forwarding failed");
            end
            $display("Expected: 0x00000005 at address 0x200");
            $display("Actual: 0x%08x at address 0x200", data_mem[128]);
            $display("Total cycles: %0d", cycle_count);
        end
    endtask
    
endmodule 