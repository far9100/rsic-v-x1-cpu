# RISC-V 32IM Assembler
# File: assembler/assembler.py

import argparse
import re

# Instruction type formats and opcodes (incomplete, expand as needed)
# For RV32I + M extension
# Opcodes
OPCODE_LUI    = 0b0110111
OPCODE_AUIPC  = 0b0010111
OPCODE_JAL    = 0b1101111
OPCODE_JALR   = 0b1100111
OPCODE_BRANCH = 0b1100011
OPCODE_LOAD   = 0b0000011
OPCODE_STORE  = 0b0100011
OPCODE_IMM    = 0b0010011 # ADDI, SLTI, etc.
OPCODE_OP     = 0b0110011 # ADD, SUB, MUL, etc. R-type

# Funct3 for IMM instructions
FUNCT3_ADDI   = 0b000
FUNCT3_SLTI   = 0b010
FUNCT3_SLTIU  = 0b011
FUNCT3_XORI   = 0b100
FUNCT3_ORI    = 0b101
FUNCT3_ANDI   = 0b111
FUNCT3_SLLI   = 0b001 # RV32I
FUNCT3_SRLI   = 0b101 # RV32I
FUNCT3_SRAI   = 0b101 # RV32I

# Funct3 for OP (R-type) instructions
FUNCT3_ADD    = 0b000
FUNCT3_SUB    = 0b000
FUNCT3_SLL    = 0b001
FUNCT3_SLT    = 0b010
FUNCT3_SLTU   = 0b011
FUNCT3_XOR    = 0b100
FUNCT3_SRL    = 0b101
FUNCT3_SRA    = 0b101
FUNCT3_OR     = 0b110
FUNCT3_AND    = 0b111
# M-extension R-type
FUNCT3_MUL    = 0b000
FUNCT3_MULH   = 0b001
FUNCT3_MULHSU = 0b010
FUNCT3_MULHU  = 0b011
FUNCT3_DIV    = 0b100
FUNCT3_DIVU   = 0b101
FUNCT3_REM    = 0b110
FUNCT3_REMU   = 0b111

# Funct7 for some R-type and I-type shifts
FUNCT7_SUB    = 0b0100000
FUNCT7_SRA    = 0b0100000
FUNCT7_SLLI   = 0b0000000 # RV32I
FUNCT7_SRLI   = 0b0000000 # RV32I
FUNCT7_SRAI   = 0b0100000 # RV32I
# M-extension R-type
FUNCT7_MULDIV = 0b0000001


# Funct3 for BRANCH instructions
FUNCT3_BEQ    = 0b000
FUNCT3_BNE    = 0b001
FUNCT3_BLT    = 0b100
FUNCT3_BGE    = 0b101
FUNCT3_BLTU   = 0b110
FUNCT3_BGEU   = 0b111

# Funct3 for LOAD instructions
FUNCT3_LB     = 0b000
FUNCT3_LH     = 0b001
FUNCT3_LW     = 0b010
FUNCT3_LBU    = 0b100
FUNCT3_LHU    = 0b101

# Funct3 for STORE instructions
FUNCT3_SB     = 0b000
FUNCT3_SH     = 0b001
FUNCT3_SW     = 0b010


def register_to_int(reg_str):
    """Converts a register string like 'x10' or 'a0' to its integer number."""
    if reg_str.startswith('x'):
        return int(reg_str[1:])
    # Add ABI names if desired
    abi_map = {
        'zero': 0, 'ra': 1, 'sp': 2, 'gp': 3, 'tp': 4,
        't0': 5, 't1': 6, 't2': 7,
        's0': 8, 'fp': 8, 's1': 9,
        'a0': 10, 'a1': 11, 'a2': 12, 'a3': 13, 'a4': 14, 'a5': 15, 'a6': 16, 'a7': 17,
        's2': 18, 's3': 19, 's4': 20, 's5': 21, 's6': 22, 's7': 23, 's8': 24, 's9': 25, 's10': 26, 's11': 27,
        't3': 28, 't4': 29, 't5': 30, 't6': 31
    }
    if reg_str in abi_map:
        return abi_map[reg_str]
    raise ValueError(f"Unknown register: {reg_str}")

def parse_immediate(imm_str, labels=None, current_address=0):
    """Parses an immediate string, which can be a number or a label."""
    imm_str = imm_str.strip()
    if labels and imm_str in labels: # It's a label
        # For branches, immediate is PC-relative offset
        # For JAL, immediate is PC-relative offset
        # For others (LUI, AUIPC, ADDI), it's an absolute value or offset
        # This needs to be handled based on instruction type later
        return labels[imm_str] # Return address of label for now
    try:
        if imm_str.lower().startswith('0x'):
            return int(imm_str, 16)
        elif imm_str.lower().startswith('0b'):
            return int(imm_str, 2)
        else:
            return int(imm_str)
    except ValueError:
        raise ValueError(f"Invalid immediate value: {imm_str}")


def assemble_r_type(rd, rs1, rs2, funct3, funct7, opcode):
    """Assembles an R-type instruction."""
    rd_int = register_to_int(rd)
    rs1_int = register_to_int(rs1)
    rs2_int = register_to_int(rs2)
    return (funct7 << 25) | (rs2_int << 20) | (rs1_int << 15) | \
           (funct3 << 12) | (rd_int << 7) | opcode

def assemble_i_type(rd, rs1, imm, funct3, opcode, labels=None, current_address=0):
    """Assembles an I-type instruction."""
    rd_int = register_to_int(rd)
    rs1_int = register_to_int(rs1)
    imm_val = parse_immediate(imm, labels, current_address)
    if not (-2048 <= imm_val <= 2047):
        print(f"Warning: I-type immediate {imm_val} out of 12-bit signed range.")
    return ((imm_val & 0xFFF) << 20) | (rs1_int << 15) | \
           (funct3 << 12) | (rd_int << 7) | opcode

# Add functions for S, B, U, J types
# def assemble_s_type(rs1, rs2, imm, funct3, opcode, labels=None, current_address=0): ...
# def assemble_b_type(rs1, rs2, label, funct3, opcode, labels, current_address): ...
# def assemble_u_type(rd, imm, opcode, labels=None, current_address=0): ...
# def assemble_j_type(rd, label, opcode, labels, current_address): ...


def assemble_line(line, labels, current_address):
    """Assembles a single line of assembly code."""
    parts = re.split(r'[, ()\s]+', line.strip())
    parts = [p for p in parts if p] # Remove empty strings

    instr = parts[0].lower()
    args = parts[1:]

    machine_code = None

    if instr == 'nop': # Pseudo-instruction: addi x0, x0, 0
        machine_code = assemble_i_type('x0', 'x0', '0', FUNCT3_ADDI, OPCODE_IMM)
    elif instr == 'addi':
        machine_code = assemble_i_type(args[0], args[1], args[2], FUNCT3_ADDI, OPCODE_IMM)
    elif instr == 'add':
        machine_code = assemble_r_type(args[0], args[1], args[2], FUNCT3_ADD, 0b0000000, OPCODE_OP)
    elif instr == 'sub':
        machine_code = assemble_r_type(args[0], args[1], args[2], FUNCT3_SUB, FUNCT7_SUB, OPCODE_OP)
    elif instr == 'mul': # M-extension
        machine_code = assemble_r_type(args[0], args[1], args[2], FUNCT3_MUL, FUNCT7_MULDIV, OPCODE_OP)
    # Add more instructions here...
    # Example for LW: lw rd, offset(rs1) -> ADDI rd, rs1, offset (I-type)
    elif instr == 'lw': # lw rd, imm(rs1)
        # Args: rd, imm_rs1_combined -> e.g. "x5", "128(x2)"
        rd_arg = args[0]
        imm_str, rs1_str = args[1].replace(')','').split('(')
        machine_code = assemble_i_type(rd_arg, rs1_str, imm_str, FUNCT3_LW, OPCODE_LOAD)
    # Example for SW: sw rs2, offset(rs1) -> S-type
    # elif instr == 'sw':
    #     rs2_arg = args[0]
    #     imm_str, rs1_str = args[1].replace(')','').split('(')
    #     machine_code = assemble_s_type(rs1_str, rs2_arg, imm_str, FUNCT3_SW, OPCODE_STORE)


    # Handle other instructions (lui, auipc, jal, jalr, branches, other R, I, S, U, J types)

    if machine_code is not None:
        return f"{machine_code:08x}" # Format as 8-digit hex
    else:
        print(f"Warning: Instruction not implemented or unknown: {line.strip()}")
        return None


def main():
    parser = argparse.ArgumentParser(description="RISC-V 32IM Assembler")
    parser.add_argument("input_file", help="Input assembly file (.asm)")
    parser.add_argument("-o", "--output_file", help="Output HEX file (.hex)")
    args = parser.parse_args()

    if not args.output_file:
        args.output_file = args.input_file.rsplit('.', 1)[0] + ".hex"

    lines = []
    with open(args.input_file, 'r') as f:
        lines = f.readlines()

    labels = {}
    cleaned_lines = []
    current_address = 0

    # First pass: identify labels and clean lines
    for line_num, line in enumerate(lines):
        line = line.strip()
        # Remove comments
        if '#' in line:
            line = line.split('#', 1)[0].strip()
        if not line:
            continue

        # Check for labels
        if ':' in line:
            label, rest_of_line = line.split(':', 1)
            label = label.strip()
            if label in labels:
                raise ValueError(f"Duplicate label '{label}' at line {line_num + 1}")
            labels[label] = current_address
            line = rest_of_line.strip() # Process instruction on the same line if any

        if line: # If there's an instruction after the label or on a non-label line
            cleaned_lines.append({'line': line, 'address': current_address, 'original_num': line_num + 1})
            current_address += 4 # Assuming 4 bytes per instruction

    # Second pass: assemble instructions
    output_hex_lines = []
    for item in cleaned_lines:
        line = item['line']
        address = item['address']
        try:
            hex_code = assemble_line(line, labels, address)
            if hex_code:
                output_hex_lines.append(hex_code)
        except Exception as e:
            print(f"Error assembling line {item['original_num']} ('{line}'): {e}")
            # Decide if to stop or continue with a placeholder
            output_hex_lines.append("deadbeef") # Placeholder for error

    with open(args.output_file, 'w') as f:
        for hex_line in output_hex_lines:
            f.write(hex_line + "\n")

    print(f"Assembly complete. Output written to {args.output_file}")
    print("Labels found:", labels)

if __name__ == "__main__":
    main()
