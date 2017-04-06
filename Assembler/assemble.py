import sys

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

#CONSTANTS

FILE_NAME = "pMem.vhd"

INSTR_WIDTH = 32
INST_COUNT = 1023

PRE_TEXT = """library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- pMem interface
entity pMem is
  port(
    pAddr : in unsigned(9 downto 0);
    pData : out unsigned(31 downto 0));
end pMem;

architecture Behavioral of pMem is

-- program Memory
type p_mem_t is array (0 to 1023) of unsigned(31 downto 0);
  signal p_mem : p_mem_t := (
"""

POST_TEXT = """);

begin  -- pMem
pData <= p_mem(to_integer(pAddr));

end Behavioral;
"""

#Erro class to raise for syntax errors in assembler code
class AssemblerError(Exception):
    def __init__(self, value):
        self.value = value
    def __str__(self):
        return repr(self.value)

"""
    Instruction format coded according to following:
    ABC

    Where every letter is either:
        0 - Don't care
        R - registers
        C - Constant (adress)

    Possible values are:
    A - 0/R
    B - 0/R
    C - 0/R/C
"""
valid_instr = {
    'NOP': '000',
    'MOV':'R0C',
    'LDA':'R0C',
    'STR':'0RC',
    'LDAR':'RR0',
    'STRR':'0RR',
    'NOT':'RR0',
    'OR' : 'RRR',
    'AND' : 'RRR',
    'XOR' : 'RRR',
    'ADD' : 'RRR',
    'SUB' : 'RRR',
    'MUL' : 'RRR',
    'LSR' : 'RRC',
    'LSL' : 'RRC',
    'LDAV' : 'R0C',
    'STRV' : '0RC',
    'LDAVR' : 'RR0',
    'STRVR' : '0RR',
    'JMP' : '00C',
    'BRN' : '00C',
    'BRZ' : '00C',
    'BRO' : '00C',
    'BRNN' : '00C',
    'BRNZ' : '00C',
    'BRNO' : '00C',
    'BRB1' : '00C',
    'BRB2' : '00C',
    'BRJU' : '00C',
    'BRJD' : '00C',
    'BRJR' : '00C',
    'BRJL' : '00C',
    'CMP' : '0RR'
    }

#List of symbloic adresses
sym_addr = {}

def decode_instruction(instr):
    return 0;

"""
Takes a string on the format RX and gives the hex value for the decimal number X.
"""
def decode_reg(reg):
    if reg[0]lower() != 'r' || len(reg) < 2 || len(reg) > 3:
        raise AssemblerError(reg + "is not a register")

    nr_str = reg[1:];
    reg_int = int(nr_str);

    if reg_int > 15:
        raise AssemblerError("Register nr " + reg_int + " does not exist");

    return dec_to_hex(reg_int)[-1];

def decode_const(const):
    return 0;

"""
Returns the given integer dec as a 16-bit hex number, stored in a string.
"""
def dec_to_hex(dec):
    #Needs to be able to handle both positive and negative numbers
    return 0;

def bin_to_hex(binary):
    if len(binary) > 16:
        raise AssemblerError(binary + " is not a valid 16 bit binary number.")

    tot = 0

    for i in range(0, len(binary)):
        cur_n = binary[(len(binary) - 1) - i]

        if cur_n  == '1':
            tot += pow(2,i)
        else if cur_n != '0':
            raise AssemblerError("Symbol " + cur_n + " of " + binary + "is not a binary symbol.")

    return dec_to_hex(tot);

"""
Returns the relative jump in hex.
"""
def get_jmp(cur_line, sym_address):
    try:
        jmp_line = sym_addr[sym_adress]
    except KeyError:
        raise AssemblerError("Symbolic adress " + sym_adress + " not found.");

    relative_jmp = jmp_line - cur_line;

    return dec_to_hex(relative_jmp);

# --     ***     --
# PROGRAM START
# --     ***     --
arguments = sys.argv;

if len(arguments) < 2:
    #No input file given
    sys.exit("Error: No input file given")

input_file_name = arguments[1]

try:
    prog_file = open(input_file_name, "r")
except IOError:
    sys.exit("Error: Can not open file " + input_file_name)

encoded = open("encoded_program.mom", "w")

#Add pre text

#Add instructions
for instr in prog_file:
    comment = "--" + instr
    decode_instruction(instr.split())
    encoded.write(comment)

#Add post text

prog_file.close
