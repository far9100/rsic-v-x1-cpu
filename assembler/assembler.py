# RISC-V 32IM Assembler
# File: assembler/assembler.py

import argparse
import re
import os # Added for directory creation

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
FUNCT7_ADD    = 0b0000000
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
    reg_str = reg_str.lower()
    if reg_str.startswith('x'):
        try:
            val = int(reg_str[1:])
            if not (0 <= val <= 31):
                raise ValueError
            return val
        except ValueError:
            raise ValueError(f"Invalid register number: {reg_str}")
            
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

def parse_immediate(imm_str, labels=None, current_address=0, is_branch_or_jal=False):
    """Parses an immediate string, which can be a number or a label."""
    imm_str = imm_str.strip()
    if labels and imm_str in labels:
        label_address = labels[imm_str]
        if is_branch_or_jal:
            offset = label_address - current_address
            return offset
        return label_address
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
    rd_int = register_to_int(rd)
    rs1_int = register_to_int(rs1)
    rs2_int = register_to_int(rs2)
    return (funct7 << 25) | (rs2_int << 20) | (rs1_int << 15) | \
           (funct3 << 12) | (rd_int << 7) | opcode

def assemble_i_type(rd, rs1, imm_str, funct3, opcode, labels=None, current_address=0):
    rd_int = register_to_int(rd)
    rs1_int = register_to_int(rs1)
    imm_val = parse_immediate(imm_str, labels, current_address, is_branch_or_jal=False)
    if not (-2048 <= imm_val <= 2047): # 12-bit signed
        print(f"Warning: I-type immediate {imm_val} for {rd},{rs1},{imm_str} out of 12-bit signed range.")
    return ((imm_val & 0xFFF) << 20) | (rs1_int << 15) | \
           (funct3 << 12) | (rd_int << 7) | opcode

def assemble_s_type(rs1, rs2, imm_str, funct3, opcode, labels=None, current_address=0):
    rs1_int = register_to_int(rs1)
    rs2_int = register_to_int(rs2)
    imm_val = parse_immediate(imm_str, labels, current_address, is_branch_or_jal=False)
    if not (-2048 <= imm_val <= 2047): # 12-bit signed
        print(f"Warning: S-type immediate {imm_val} out of 12-bit signed range.")
    imm11_5 = (imm_val >> 5) & 0x7F
    imm4_0  = imm_val & 0x1F
    return (imm11_5 << 25) | (rs2_int << 20) | (rs1_int << 15) | \
           (funct3 << 12) | (imm4_0 << 7) | opcode

def assemble_b_type(rs1, rs2, label_str, funct3, opcode, labels, current_address):
    rs1_int = register_to_int(rs1)
    rs2_int = register_to_int(rs2)
    offset = parse_immediate(label_str, labels, current_address, is_branch_or_jal=True)

    if not (-4096 <= offset <= 4094) or (offset % 2 != 0):
        # B-type immediate is 13-bit signed, scaled by 2 (effectively 12-bit word offset)
        # Range is -4096 to +4094, must be even
        raise ValueError(f"B-type offset {offset} for label '{label_str}' out of range or not even.")

    imm12  = (offset >> 12) & 0x1   # imm[12]
    imm10_5= (offset >> 5) & 0x3F  # imm[10:5]
    imm4_1 = (offset >> 1) & 0xF   # imm[4:1]
    imm11  = (offset >> 11) & 0x1  # imm[11]

    return (imm12 << 31) | (imm10_5 << 25) | (rs2_int << 20) | (rs1_int << 15) | \
           (funct3 << 12) | (imm4_1 << 8) | (imm11 << 7) | opcode


def assemble_line(line_content, labels, current_address):
    """Assembles a single line of assembly code."""
    # Improved parsing for instructions like lw x5, 0(x6)
    match = re.match(r"([a-zA-Z.]+)\s*([^#]*)", line_content)
    if not match:
        if line_content and not line_content.isspace(): # Non-empty, non-comment line that doesn't match
             print(f"Warning: Could not parse instruction part of line: {line_content}")
        return None # Skip if truly empty or unparsable

    instr = match.group(1).lower()
    args_str = match.group(2).strip()
    
    # Argument parsing robustly handling spaces around commas and parentheses
    args = []
    if args_str:
        # Split by comma, then process load/store format "offset(reg)"
        raw_args = [a.strip() for a in args_str.split(',')]
        for arg in raw_args:
            if '(' in arg and arg.endswith(')'): # For "offset(reg)" format
                offset, base_reg = arg.split('(', 1)
                args.append(offset.strip())
                args.append(base_reg[:-1].strip()) # Remove ')' and strip
            else:
                args.append(arg)

    machine_code = None

    # Handle pseudo-instructions and directives first
    if instr.startswith('.'): # like .globl, .data, .text etc.
        print(f"Info: Directive '{instr}' encountered, currently ignored.")
        return None # Ignored for now

    if instr == 'nop':
        machine_code = assemble_i_type('x0', 'x0', '0', FUNCT3_ADDI, OPCODE_IMM, labels, current_address)
    elif instr == 'addi':
        machine_code = assemble_i_type(args[0], args[1], args[2], FUNCT3_ADDI, OPCODE_IMM, labels, current_address)
    elif instr == 'add':
        machine_code = assemble_r_type(args[0], args[1], args[2], FUNCT3_ADD, FUNCT7_ADD, OPCODE_OP)
    elif instr == 'sub':
        machine_code = assemble_r_type(args[0], args[1], args[2], FUNCT3_SUB, FUNCT7_SUB, OPCODE_OP)
    elif instr == 'mul':
        machine_code = assemble_r_type(args[0], args[1], args[2], FUNCT3_MUL, FUNCT7_MULDIV, OPCODE_OP)
    elif instr == 'lw': # lw rd, offset(rs1) -> args: rd, offset, rs1
        machine_code = assemble_i_type(args[0], args[2], args[1], FUNCT3_LW, OPCODE_LOAD, labels, current_address)
    elif instr == 'sw': # sw rs2, offset(rs1) -> args: rs2, offset, rs1
        machine_code = assemble_s_type(args[2], args[0], args[1], FUNCT3_SW, OPCODE_STORE, labels, current_address)
    elif instr == 'beq': # beq rs1, rs2, label -> args: rs1, rs2, label
        machine_code = assemble_b_type(args[0], args[1], args[2], FUNCT3_BEQ, OPCODE_BRANCH, labels, current_address)
    # Add more instructions here...
    # SLLI, SRLI, SRAI (I-type, but shamt is in imm field)
    elif instr == 'slli': # slli rd, rs1, shamt
        shamt = int(args[2]) & 0x1F # shamt is 5 bits for RV32I
        imm_val_for_slli = (FUNCT7_SLLI << 5) | shamt # For RV32I, funct7 for SLLI is 0000000
        machine_code = assemble_i_type(args[0], args[1], str(imm_val_for_slli), FUNCT3_SLLI, OPCODE_IMM, labels, current_address)
    elif instr == 'srli': # srli rd, rs1, shamt
        shamt = int(args[2]) & 0x1F
        imm_val_for_srli = (FUNCT7_SRLI << 5) | shamt # For RV32I, funct7 for SRLI is 0000000
        machine_code = assemble_i_type(args[0], args[1], str(imm_val_for_srli), FUNCT3_SRLI, OPCODE_IMM, labels, current_address)
    elif instr == 'srai': # srai rd, rs1, shamt
        shamt = int(args[2]) & 0x1F
        imm_val_for_srai = (FUNCT7_SRAI << 5) | shamt # For RV32I, funct7 for SRAI is 0100000
        machine_code = assemble_i_type(args[0], args[1], str(imm_val_for_srai), FUNCT3_SRAI, OPCODE_IMM, labels, current_address)


    if machine_code is not None:
        return f"{machine_code:08x}"
    else:
        if not instr.startswith('.'): # Avoid warning for known ignored directives
            print(f"Warning: Instruction not implemented or unknown: {instr} with args {args}")
        return None


def main():
    parser = argparse.ArgumentParser(description="RISC-V 32IM Assembler")
    parser.add_argument("input_file", help="Input assembly file (.asm)")
    parser.add_argument("-o", "--output_file", help="Output HEX file (.hex)")
    args = parser.parse_args()

    if not args.output_file:
        args.output_file = args.input_file.rsplit('.', 1)[0] + ".hex"

    # Ensure output directory exists
    output_dir = os.path.dirname(args.output_file)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir)

    lines = []
    with open(args.input_file, 'r') as f:
        lines = f.readlines()

    labels = {}
    cleaned_lines_and_labels = [] # Stores {'line': str, 'address': int, 'original_num': int} or {'label_name': str, 'address': int}
    current_address = 0
    known_directives = ['.globl', '.global', '.text', '.data', '.align', '.word', '.byte', '.half', '.space', '.string', '.asciz']


    # First pass: identify labels, clean lines, handle directives
    for line_num, line_content in enumerate(lines):
        line = line_content.strip()
        if '#' in line: # Remove comments
            line = line.split('#', 1)[0].strip()
        
        if not line: # Skip empty lines
            continue

        # Check for labels: "label_name:"
        label_match = re.match(r"^\s*([a-zA-Z_][a-zA-Z0-9_]*):\s*(.*)", line)
        if label_match:
            label, rest_of_line = label_match.groups()
            if label in labels:
                raise ValueError(f"Duplicate label '{label}' at line {line_num + 1}")
            labels[label] = current_address
            # cleaned_lines_and_labels.append({'label_name': label, 'address': current_address, 'original_num': line_num + 1})
            line = rest_of_line.strip() # Continue processing the rest of the line

        if not line: # If line was only a label or became empty
            continue
            
        # Check for directives like .globl
        first_word = line.split(maxsplit=1)[0]
        if first_word.lower() in known_directives:
            print(f"Info: Directive '{line}' at line {line_num+1} ignored.")
            # cleaned_lines_and_labels.append({'directive': line, 'address': current_address, 'original_num': line_num + 1})
            # Directives usually don't take space unless they are .word, .byte etc.
            # For simplicity, this assembler doesn't advance PC for data directives yet.
            continue # Skip to next line

        # If it's an instruction (or what's left of a line with a label)
        cleaned_lines_and_labels.append({'line': line, 'address': current_address, 'original_num': line_num + 1})
        current_address += 4


    # Second pass: assemble instructions
    output_hex_lines = []
    for item in cleaned_lines_and_labels:
        if 'line' in item: # It's an instruction line
            line_text = item['line']
            address = item['address']
            try:
                hex_code = assemble_line(line_text, labels, address)
                if hex_code:
                    output_hex_lines.append(hex_code)
                elif line_text and not line_text.split(maxsplit=1)[0].lower() in known_directives : # If assemble_line returned None for a non-directive
                    print(f"Error: Failed to assemble line {item['original_num']}: '{line_text}'. Outputting placeholder.")
                    output_hex_lines.append("deadbeef") # Placeholder for error
            except Exception as e:
                print(f"Critical Error assembling line {item['original_num']} ('{line_text}'): {e}")
                output_hex_lines.append("fa11fa11") # Different placeholder for critical error
        # elif 'directive' in item or 'label_name' in item:
            # These are handled/ignored in first pass or used by assemble_line via `labels` dict
            # No direct hex output for these meta-items themselves.
            # pass


    with open(args.output_file, 'w') as f:
        for hex_line in output_hex_lines:
            f.write(hex_line + "\n")

    print(f"Assembly complete. Output written to {args.output_file}")
    if labels:
      print("Labels found:", labels)

if __name__ == "__main__":
    main()
