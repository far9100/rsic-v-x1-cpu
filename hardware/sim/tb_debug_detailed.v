// Detailed debug testbench for pipeline and forwarding monitoring
// File: hardware/sim/tb_debug_detailed.v

`timescale 1ns / 1ps

module tb_debug_detailed();

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
        $display("Loaded test program");
        
        // Print first few instructions
        $display("First few instructions:");
        for (integer i = 0; i < 8; i = i + 1) begin
            $display("  instr[%0d] = 0x%08x", i, instr_mem[i]);
        end
    end
    
    // Instruction memory
    always @(*) begin
        if (i_mem_addr < 4*1024) begin
            i_mem_rdata = instr_mem[i_mem_addr / 4];
        end else begin
            i_mem_rdata = 32'hdeadbeef;
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
                    $display("MEMORY WRITE: addr=0x%08x, data=0x%08x, index=%0d", 
                             d_mem_addr, d_mem_wdata, d_mem_addr / 4);
                             
                    // Memory write detected - check ALU operands from previous cycle
                    $display("  Memory write detected");
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
        $display("Reset released at time %0t", $time);
    end
    
    // Test monitoring
    integer cycle_count = 0;
    integer instruction_count = 0;
    
    always @(posedge clk) begin
        if (rst_n) begin
            cycle_count <= cycle_count + 1;
            
            // Monitor pipeline stages
            if (i_mem_addr != 32'h40) begin // Not in infinite loop
                $display("Cycle %0d: PC=0x%08x, Instr=0x%08x", 
                         cycle_count, i_mem_addr, i_mem_rdata);
                         
                // Monitor ALU operands when ALU is active
                if (u_cpu_top.u_ex_stage.alu_op_i != 4'hx) begin
                    $display("  ALU: op=0x%x, a=0x%08x, b=0x%08x, result=0x%08x", 
                             u_cpu_top.u_ex_stage.alu_op_i,
                             u_cpu_top.u_ex_stage.alu_operand_a,
                             u_cpu_top.u_ex_stage.alu_operand_b,
                             u_cpu_top.u_ex_stage.alu_result_internal);
                end
                
                // Monitor forwarding signals
                $display("  Forward: a_sel=%0d, b_sel=%0d", 
                         u_cpu_top.u_forwarding_unit.forward_a_sel_o,
                         u_cpu_top.u_forwarding_unit.forward_b_sel_o);
                         
                instruction_count = instruction_count + 1;
            end
            
            // Check for program end
            if (data_mem[768/4] == 32'h1) begin
                $display("Program ended at cycle %0d", cycle_count);
                
                // Print memory contents
                $display("Memory dump:");
                for (integer i = 128; i < 134; i = i + 1) begin
                    $display("  mem[%0d] = 0x%08x", i, data_mem[i]);
                end
                
                #100;
                $finish;
            end
            
            // Safety timeout
            if (cycle_count > 500) begin
                $display("Test timeout at cycle %0d", cycle_count);
                $finish;
            end
        end
    end
    
endmodule 