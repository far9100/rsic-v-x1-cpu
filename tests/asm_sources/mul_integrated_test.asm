# RISC-V Multiplication Integrated Test Program (M Extension)
# File: tests/asm_sources/mul_integrated_test.asm

# Purpose: Test multiplication functionality thoroughly.
# This test includes multiple multiplication test cases with different values.

.globl _start
_start:
    # Test case 1: Basic multiplication 7 * 6 = 42
    addi x5, x0, 7       # x5 = 7
    addi x6, x0, 6       # x6 = 6

    # Perform multiplication
    mul  x7, x5, x6      # x7 = x5 * x6 (x7 should be 7 * 6 = 42)

    # Test case 2: Multiplication with negative number -3 * 5 = -15
    addi x8, x0, -3      # x8 = -3
    addi x9, x0, 5       # x9 = 5
    mul  x10, x8, x9     # x10 = x8 * x9 (x10 should be -3 * 5 = -15)
                         # -15 in 32-bit 2's complement is 0xFFFFFFF1

    # Test case 3: 8 * 6 = 48
    addi x11, x0, 8      # x11 = 8
    addi x12, x0, 6      # x12 = 6
    mul  x13, x11, x12   # x13 = x11 * x12 (x13 should be 8 * 6 = 48)

    # Test case 4: 7 * 9 = 63
    addi x14, x0, 7      # x14 = 7
    addi x15, x0, 9      # x15 = 9
    mul  x16, x14, x15   # x16 = x14 * x15 (x16 should be 7 * 9 = 63)
    
    # Test case 5: 120 * 140 = 16800
    addi x17, x0, 120    # x17 = 120
    addi x18, x0, 140    # x18 = 140
    mul  x19, x17, x18   # x19 = x17 * x18 (x19 should be 120 * 140 = 16800 = 0x41A0)

    # Test case 6: Multiplication by 0: 5 * 0 = 0
    addi x20, x0, 5      # x20 = 5
    addi x21, x0, 0      # x21 = 0
    mul  x22, x20, x21   # x22 = x20 * x21 (x22 should be 5 * 0 = 0)

    # Test case 7: Multiplication by 1: 5 * 1 = 5
    addi x23, x0, 5      # x23 = 5
    addi x24, x0, 1      # x24 = 1
    mul  x25, x23, x24   # x25 = x23 * x24 (x25 should be 5 * 1 = 5)

    # Test case 8: Multiplication of negative numbers: -4 * -3 = 12
    addi x26, x0, -4     # x26 = -4
    addi x27, x0, -3     # x27 = -3
    mul  x28, x26, x27   # x28 = x26 * x27 (x28 should be -4 * -3 = 12)

    # Test case 9: Multiplication table demonstration (specific entries)
    # Store table values in memory starting at address 0x200
    addi x1, x0, 0x200   # Base address for multiplication table storage
    
    # Store 1*1 = 1
    addi x2, x0, 1
    addi x3, x0, 1
    mul  x4, x2, x3
    sw   x4, 0(x1)
    
    # Store 2*2 = 4
    addi x2, x0, 2
    addi x3, x0, 2
    mul  x4, x2, x3
    sw   x4, 4(x1)
    
    # Store 3*3 = 9
    addi x2, x0, 3
    addi x3, x0, 3
    mul  x4, x2, x3
    sw   x4, 8(x1)
    
    # Store 4*4 = 16
    addi x2, x0, 4
    addi x3, x0, 4
    mul  x4, x2, x3
    sw   x4, 12(x1)
    
    # Store 5*5 = 25
    addi x2, x0, 5
    addi x3, x0, 5
    mul  x4, x2, x3
    sw   x4, 16(x1)
    
    # Store 6*6 = 36
    addi x2, x0, 6
    addi x3, x0, 6
    mul  x4, x2, x3
    sw   x4, 20(x1)
    
    # Store 7*7 = 49
    addi x2, x0, 7
    addi x3, x0, 7
    mul  x4, x2, x3
    sw   x4, 24(x1)
    
    # Store 8*8 = 64
    addi x2, x0, 8
    addi x3, x0, 8
    mul  x4, x2, x3
    sw   x4, 28(x1)
    
    # Store 9*9 = 81
    addi x2, x0, 9
    addi x3, x0, 9
    mul  x4, x2, x3
    sw   x4, 32(x1)
    
    # Infinite loop to halt the processor for observation
halt_loop:
    beq  x0, x0, halt_loop # Branch to self (effectively a halt)
    nop                     # Should not be reached

# Expected results:
# Register x7  should contain the value 42     (0x2A)
# Register x10 should contain the value -15    (0xFFFFFFF1)
# Register x13 should contain the value 48     (0x30)
# Register x16 should contain the value 63     (0x3F)
# Register x19 should contain the value 16800  (0x41A0)
# Register x22 should contain the value 0      (0x0)
# Register x25 should contain the value 5      (0x5)
# Register x28 should contain the value 12     (0xC)
# Memory[0x200/4] should contain the value 1   (0x1)
# Memory[0x204/4] should contain the value 4   (0x4)
# Memory[0x208/4] should contain the value 9   (0x9)
# Memory[0x20C/4] should contain the value 16  (0x10)
# Memory[0x210/4] should contain the value 25  (0x19)
# Memory[0x214/4] should contain the value 36  (0x24)
# Memory[0x218/4] should contain the value 49  (0x31)
# Memory[0x21C/4] should contain the value 64  (0x40)
# Memory[0x220/4] should contain the value 81  (0x51) 