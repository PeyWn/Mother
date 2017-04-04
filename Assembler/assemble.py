"""
Assembler for motherlode project

program.mtr -> pMem.vhd

Should work according to the following format
- Add neccesary text to top of file
- Decode instructions one at a time
    - Read one line
    - Split line at spaces
    - Lookup instructions
    - If symbolic adress
        - Add to list of symbolic adresses
    - If operation
        - Write hex code of Operation
        - Follow structure for Operation
            - Convert registers to hex
            - Convert constant to hex
            - Lookup symbolic adress and calculate relative jmp
- Add neccesary text after

"""
valid_instr = {}

def decode_instruction(instr):

    return 0;

def decode_reg(reg):
    return 0;

def decode_const(const):
    return 0;

def dec_to_hex(decimal):
    return 0;

def bin_to_hex(binary):
    return 0;

def get_jmp(cur_line, sym_address):
    return 0;


prog_file = open("test_prog.mom", "r")
encoded = open("encoded_program.mom", "w")

for instr in prog_file:
    comment = "--" + instr
    decode_instruction(instr.split())
    encoded.write(comment)

prog_file.close
