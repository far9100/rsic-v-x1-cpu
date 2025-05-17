#!/bin/bash
# Script to run the Addition test for RISC-V CPU

echo "Running Addition Test for RISC-V CPU"
echo "======================================"

# Step 1: Convert the ASM file to HEX using the assembler
echo "Step 1: Converting ASM to HEX..."
python3 assembler/assembler.py tests/asm_sources/add_integrated_test.asm -o tests/hex_outputs/add_integrated_test.hex
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to assemble the test file."
    exit 1
fi
echo "Assembly completed successfully."

# Step 2: Compile the Verilog files
echo "Step 2: Compiling Verilog files..."
iverilog -o add_sim hardware/sim/tb_add_test.v hardware/rtl/*.v
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to compile Verilog files."
    exit 1
fi
echo "Compilation completed successfully."

# Step 3: Run the simulation
echo "Step 3: Running simulation..."
vvp add_sim
if [ $? -ne 0 ]; then
    echo "ERROR: Simulation failed."
    exit 1
fi
echo "Simulation completed successfully."

echo "Addition Test Finished"
echo "======================="
echo "You can view the waveform by running: gtkwave tb_add_test.vcd" 