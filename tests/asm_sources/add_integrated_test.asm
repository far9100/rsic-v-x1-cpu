# RISC-V Addition Integrated Test Program
# File: tests/asm_sources/add_integrated_test.asm

# Purpose: Test addition functionality thoroughly.
# This test includes multiple addition test cases with different values.

.globl _start
_start:
    # Test case 1: Simple addition 1 + 2 = 3
    addi x2, x0, 1      # x2 = 1
    addi x3, x0, 2      # x3 = 2
    
    # Insert NOPs to handle pipeline data hazards
    nop
    nop
    nop
    
    # Perform addition
    add  x4, x2, x3     # x4 = x2 + x3 (x4 should be 3)
    
    # Test case 2: Addition with larger numbers 10 + 20 = 30
    addi x5, x0, 10     # x5 = 10
    addi x6, x0, 20     # x6 = 20
    
    # Insert NOPs to handle pipeline data hazards
    nop
    nop
    nop
    
    # Perform addition
    add  x7, x5, x6     # x7 = x5 + x6 (x7 should be 30)
    
    # Test case 3: Addition with negative number 5 + (-3) = 2
    addi x8, x0, 5      # x8 = 5
    addi x9, x0, -3     # x9 = -3
    
    # Insert NOPs to handle pipeline data hazards
    nop
    nop
    nop
    
    # Perform addition
    add  x10, x8, x9    # x10 = x8 + x9 (x10 should be 2)
    
    # Test case 4: Addition resulting in zero 5 + (-5) = 0
    addi x11, x0, 5     # x11 = 5
    addi x12, x0, -5    # x12 = -5
    
    # Insert NOPs to handle pipeline data hazards
    nop
    nop
    nop
    
    # Perform addition
    add  x13, x11, x12  # x13 = x11 + x12 (x13 should be 0)
    
    # Test case 5: Addition with zero 7 + 0 = 7
    addi x14, x0, 7     # x14 = 7
    addi x15, x0, 0     # x15 = 0
    
    # Insert NOPs to handle pipeline data hazards
    nop
    nop
    nop
    
    # Perform addition
    add  x16, x14, x15  # x16 = x14 + x15 (x16 should be 7)
    
    # Test case 6: Larger addition 100 + 200 = 300
    addi x17, x0, 100   # x17 = 100
    addi x18, x0, 200   # x18 = 200
    
    # Insert NOPs to handle pipeline data hazards
    nop
    nop
    nop
    
    # Perform addition
    add  x19, x17, x18  # x19 = x17 + x18 (x19 should be 300)
    
    # Store results in memory for verification (optional)
    # Assuming memory starts at address 0x100
    addi x28, x0, 0x100  # Set base memory address
    
    # Store results
    sw x4, 0(x28)        # Store result of 1 + 2 = 3
    sw x7, 4(x28)        # Store result of 10 + 20 = 30
    sw x10, 8(x28)       # Store result of 5 + (-3) = 2
    sw x13, 12(x28)      # Store result of 5 + (-5) = 0
    sw x16, 16(x28)      # Store result of 7 + 0 = 7
    sw x19, 20(x28)      # Store result of 100 + 200 = 300
    
    # Infinite loop to halt the processor for observation
halt_loop:
    beq  x0, x0, halt_loop # Branch to self (effectively a halt)
    nop                     # Should not be reached

# Expected results:
# Register x4  should contain the value 3   (0x3)
# Register x7  should contain the value 30  (0x1E)
# Register x10 should contain the value 2   (0x2)
# Register x13 should contain the value 0   (0x0)
# Register x16 should contain the value 7   (0x7)
# Register x19 should contain the value 300 (0x12C) 