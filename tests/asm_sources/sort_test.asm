# RISC-V Bubble Sort Test Program
# File: tests/asm_sources/sort_test.asm

# Purpose: Test various instructions (load, store, branch, compare, arithmetic)
# by implementing a simple bubble sort algorithm.

.globl _start
_start:
    # Initialize array in memory.
    # Let's use a section of data memory starting at address DATA_BASE_ADDR.
    # For simulation, we can pre-load this or use store instructions.
    # We'll use registers to hold pointers and loop counters.

    # Define array base address and size
    # For simplicity, let's assume DATA_BASE_ADDR is 0x200 for this test.
    # And array size N = 5
    lui  x5, 0x0      # x5 (array_base_ptr) = 0x00000000 (upper bits)
    addi x5, x5, 0x200 # x5 = 0x00000200 (lower bits) -> Base address of array

    addi x6, x0, 5     # x6 (N) = 5, size of the array

    # Initialize array elements in memory: [5, 1, 4, 2, 8]
    addi x10, x0, 5
    sw   x10, 0(x5)    # M[0x200] = 5
    addi x10, x0, 1
    sw   x10, 4(x5)    # M[0x204] = 1
    addi x10, x0, 4
    sw   x10, 8(x5)    # M[0x208] = 4
    addi x10, x0, 2
    sw   x10, 12(x5)   # M[0x20C] = 2
    addi x10, x0, 8
    sw   x10, 16(x5)   # M[0x210] = 8

    # Bubble Sort Algorithm:
    # for (i = 0; i < N-1; i++)
    #   for (j = 0; j < N-i-1; j++)
    #     if (array[j] > array[j+1])
    #       swap(array[j], array[j+1])

    # Registers:
    # x5: array_base_ptr
    # x6: N (size of array)
    # x7: i (outer loop counter)
    # x8: j (inner loop counter)
    # x9: N-1 (outer loop limit)
    # x10: temp for N-i-1 (inner loop limit)
    # x11: array[j]
    # x12: array[j+1]
    # x13: address of array[j]
    # x14: address of array[j+1]

    addi x7, x0, 0       # i = 0
    addi x9, x6, -1      # N-1

outer_loop_start:
    # Check condition for outer loop: i < N-1
    blt  x7, x9, outer_loop_body  # if i < N-1, continue
    beq  x0, x0, sort_done        # else, sort is done

outer_loop_body:
    addi x8, x0, 0       # j = 0

    # Calculate inner loop limit: N-i-1
    sub  x10, x6, x7      # N-i
    addi x10, x10, -1    # N-i-1 (inner_loop_limit)

inner_loop_start:
    # Check condition for inner loop: j < N-i-1
    blt  x8, x10, inner_loop_body # if j < N-i-1, continue
    beq  x0, x0, outer_loop_increment # else, end of inner loop

inner_loop_body:
    # Calculate address of array[j]: base + j * 4
    slli x13, x8, 2      # j * 4 (offset)
    add  x13, x5, x13   # address of array[j]

    # Calculate address of array[j+1]: base + (j+1) * 4
    addi x14, x8, 1      # j+1
    slli x14, x14, 2     # (j+1) * 4 (offset)
    add  x14, x5, x14   # address of array[j+1]

    # Load array[j] and array[j+1]
    lw   x11, 0(x13)    # x11 = array[j]
    lw   x12, 0(x14)    # x12 = array[j+1]

    # Compare: if (array[j] > array[j+1]) -> if (x11 > x12)
    # bgt is pseudo, use blt: if x12 < x11 then swap
    blt  x12, x11, swap_elements # if array[j+1] < array[j], then swap
    beq  x0, x0, inner_loop_increment # else, no swap, increment j

swap_elements:
    # Swap array[j] and array[j+1]
    sw   x12, 0(x13)    # array[j] = x12 (original array[j+1])
    sw   x11, 0(x14)    # array[j+1] = x11 (original array[j])

inner_loop_increment:
    addi x8, x8, 1       # j++
    beq  x0, x0, inner_loop_start # Go to start of inner loop

outer_loop_increment:
    addi x7, x7, 1       # i++
    beq  x0, x0, outer_loop_start # Go to start of outer loop

sort_done:
    # Infinite loop to halt
halt_loop:
    beq  x0, x0, halt_loop
    nop

# Expected outcome (in memory at DATA_BASE_ADDR = 0x200):
# M[0x200] = 1
# M[0x204] = 2
# M[0x208] = 4
# M[0x20C] = 5
# M[0x210] = 8
