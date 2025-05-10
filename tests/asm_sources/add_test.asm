# RISC-V Addition Test Program
# File: tests/asm_sources/add_test.asm

# Purpose: Test basic addition functionality.
# Adds two numbers and stores the result.

.globl _start
_start:
    # Initialize two registers with values
    addi x5, x0, 10      # x5 = 10 (decimal)
    addi x6, x0, 25      # x6 = 25 (decimal)

    # Perform addition
    add  x7, x5, x6      # x7 = x5 + x6 (x7 should be 35)

    # Store the result in memory (optional, for verification via memory dump)
    # Assuming x28 (s12) is a base address for data memory, e.g., 0x100
    # addi x28, x0, 0x100 # Example base address for data
    # sw   x7, 0(x28)      # Store x7 at memory location M[x28 + 0]

    # Infinite loop to halt the processor for observation
halt_loop:
    beq  x0, x0, halt_loop # Branch to self (effectively a halt)
    nop                      # Should not be reached

# Expected outcome:
# Register x7 should contain the value 35 (0x23).
# If storing to memory, M[0x100] (or chosen address) should contain 35.
