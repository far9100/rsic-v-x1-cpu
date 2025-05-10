# RISC-V Addition Test Program
# File: tests/asm_sources/add_test.asm

# Purpose: Test basic addition functionality.
# Adds two numbers and stores the result.
# Includes NOPs to mitigate data hazards in a pipeline without forwarding.

.globl _start
_start:
    # Initialize two registers with values
    addi x2, x0, 1      # x2 = 1
    addi x3, x0, 2      # x3 = 2

    # Insert NOPs to allow time for x2 and x3 to be written back
    # before being read by the 'add' instruction.
    # For a 5-stage pipeline (IF, ID, EX, MEM, WB):
    # I1 (addi x2) WB at end of cycle 5 (relative to I1's IF as cycle 1)
    # I2 (addi x3) WB at end of cycle 6
    # We need Iadd (add x4) to read x2 and x3 in its ID stage *after* they are written.
    # If Iadd's ID is at cycle 7, then x2 (WB C5) and x3 (WB C6) are available.
    # Sequence: I1, I2, NOP1, NOP2, NOP3, Iadd
    # IF: C1  C2  C3    C4    C5    C6
    # ID:     C2  C3    C4    C5    C6    C7 (Iadd ID)
    # EX:         C3    C4    C5    C6    C7
    # MEM:            C4    C5    C6    C7
    # WB:                 C5(x2)C6(x3)C7
    nop                      # Pipeline advances
    nop                      # Pipeline advances
    nop                      # Third NOP to ensure x3 is written back

    # Perform addition
    add  x4, x2, x3      # x4 = x2 + x3 (x4 should be 3)

    # Store the result in memory (optional, for verification via memory dump)
    # Assuming x28 (s12) is a base address for data memory, e.g., 0x100
    # addi x28, x0, 0x100 # Example base address for data
    # sw   x4, 0(x28)      # Store x4 at memory location M[x28 + 0]

    # Infinite loop to halt the processor for observation
halt_loop:
    beq  x0, x0, halt_loop # Branch to self (effectively a halt)
    nop                      # Should not be reached

# Expected outcome:
# Register x4 should contain the value 3 (0x3).
