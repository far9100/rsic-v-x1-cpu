// RISC-V 32IM CPU - Register File
// File: hardware/rtl/reg_file.v

`timescale 1ns / 1ps

module reg_file (
    input  wire        clk,
    input  wire        rst_n,

    // Read Ports
    input  wire [4:0]  rs1_addr,       // Address for read port 1 (rs1)
    input  wire [4:0]  rs2_addr,       // Address for read port 2 (rs2)
    output wire [31:0] rs1_data,       // Data from read port 1
    output wire [31:0] rs2_data,       // Data from read port 2

    // Write Port (from WB stage)
    input  wire [4:0]  rd_addr,        // Address for write port (rd)
    input  wire [31:0] rd_data,        // Data to write
    input  wire        wen             // Write enable
);

    // 32 registers, each 32 bits wide
    reg [31:0] registers [0:31];

    integer i;

    // Write operation (synchronous)
    // Occurs on the positive edge of the clock if write enable is high
    // and rd_addr is not x0.
    always @(posedge clk) begin
        if (wen && (rd_addr != 5'b00000)) begin // Do not write to x0
            registers[rd_addr] <= rd_data;
        end
    end

    // Read operations (asynchronous)
    // x0 always reads as 0.
    assign rs1_data = (rs1_addr == 5'b00000) ? 32'b0 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 5'b00000) ? 32'b0 : registers[rs2_addr];

    // Reset logic (optional, can be part of initialization in simulation)
    // For synthesis, explicit reset might be desired.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end
    end

endmodule
