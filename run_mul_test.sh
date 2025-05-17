#!/bin/bash
# Script to run the Multiplication test for RISC-V CPU

echo "Running Multiplication Test for RISC-V CPU"
echo "=========================================="

# Step 1: Convert the ASM file to HEX using the assembler
echo "Step 1: Converting ASM to HEX..."
python3 assembler/assembler.py tests/asm_sources/mul_integrated_test.asm -o tests/hex_outputs/mul_integrated_test.hex
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to assemble the test file."
    exit 1
fi
echo "Assembly completed successfully."

# Step 2: Compile the Verilog files
echo "Step 2: Compiling Verilog files..."
iverilog -o mul_sim hardware/sim/tb_mul_test.v hardware/rtl/*.v
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to compile Verilog files."
    exit 1
fi
echo "Compilation completed successfully."

# Step 3: Run the simulation
echo "Step 3: Running simulation..."
vvp mul_sim
if [ $? -ne 0 ]; then
    echo "ERROR: Simulation failed."
    exit 1
fi
echo "Simulation completed successfully."

echo "Multiplication Test Finished"
echo "==========================="
echo "You can view the waveform by running: gtkwave tb_mul_test.vcd" 