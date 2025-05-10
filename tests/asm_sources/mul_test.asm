# RISC-V Multiplication Test Program (M Extension)
# File: tests/asm_sources/mul_test.asm

# Purpose: Test basic multiplication functionality using the MUL instruction.
# Multiplies two numbers and stores the result.

.globl _start
_start:
    # Initialize two registers with values
    addi x5, x0, 7       # x5 = 7
    addi x6, x0, 6       # x6 = 6

    # Perform multiplication using MUL instruction (M extension)
    # MUL rd, rs1, rs2 : rd = rs1 * rs2 (lower 32 bits of product)
    mul  x7, x5, x6      # x7 = x5 * x6 (x7 should be 7 * 6 = 42)

    # Another example with a negative number (if signed behavior is as expected)
    addi x8, x0, -3      # x8 = -3
    addi x9, x0, 5       # x9 = 5
    mul  x10, x8, x9     # x10 = x8 * x9 (x10 should be -3 * 5 = -15)
                         # -15 in 32-bit 2's complement is 0xFFFFFFF1

    # Store results (optional)
    # addi x28, x0, 0x100
    # sw   x7, 0(x28)      # Store 42
    # sw   x10, 4(x28)     # Store -15

    # Infinite loop to halt
halt_loop:
    beq  x0, x0, halt_loop
    nop

# Expected outcome:
# Register x7 should contain 42 (0x2A).
# Register x10 should contain -15 (0xFFFFFFF1).
