import sys

"""
TODO: Write the hex program and similar to the pMem.vhd file
Catch all exceptions and add where the error occured

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
INST_COUNT = 1024

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

#Error class to raise for syntax errors in assembler code
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
    'NOP': ('000','0000'),
    'MOV': ('R0C','0100'),
    'LDA': ('R0C','0200'),
    'STR': ('0RC','0201'),
    'LDAR': ('RR0','0202'),
    'STRR': ('0RR','0203'),
    'NOT': ('RR0','0300'),
    'OR' : ('RRR','0301'),
    'AND' : ('RRR','0302'),
    'XOR' : ('RRR','0303'),
    'ADD' : ('RRR','0304'),
    'SUB' : ('RRR','0305'),
    'MUL' : ('RRR','0306'),
    'LSR' : ('RRC','0307'),
    'LSL' : ('RRC','0308'),
    'LDAV' : ('R0C','0400'),
    'STRV' : ('0RC','0401'),
    'LDAVR' : ('RR0','0402'),
    'STRVR' : ('0RR','0403'),
    'JMP' : ('00C','0500'),
    'BRN' : ('00C','0501'),
    'BRZ' : ('00C','0502'),
    'BRO' : ('00C','0503'),
    'BRNN' : ('00C','0504'),
    'BRNZ' : ('00C','0505'),
    'BRNO' : ('00C','0506'),
    'BRB1' : ('00C','0507'),
    'BRB2' : ('00C','0508'),
    'BRJU' : ('00C','0509'),
    'BRJD' : ('00C','050A'),
    'BRJR' : ('00C','050B'),
    'BRJL' : ('00C','050C'),
    'CMP' : ('0RR','0600')
    }

#List of symbloic adresses, formar is {SYMBOLIC_ADRESS:(PROGRAM_LINE, FILE_LINE)} to generate good error message"
sym_addr = {}

#Counter to know what program line the assembler is at, used for relative jumps and similar
prog_line = 0
#Counter to know what line of the source program we are at, used for showing syntax errors
file_line = 0

def decode_instruction(instr):
    """
    Takes a line of assembly code and converts it to a hex instruction.
    Returns the hex encoded instruction if succesful, otherwise it returns an empty string
    """
    global sym_addr
    global prog_line
    global file_line

    file_line ++
    program_hex = ""

    instr = instr.upper()
    instr = instr.split()

    try:
        instr_data = valid_instr[instr[0]]    #Check if it is an instruction
        instr_format =  instr_data[0]           #The general structure of the instruction
        program_hex = instr_data[1]             #The hexcode for the instruction
        instr = instr[1:]                       #Remove the instruction so that the first in instr is the next register/constant to be evaluated

        for i in instr_format:
            if char == 'R':
                program_hex = program_hex + decode_reg(instr[0])
                instr = instr[1:]

            elif char == '0':
                program_hex = program_hex + "0"

            elif char == 'C'
                program_hex = program_hex + decode_const(instr[0])
                instr = instr[1:]

            program_hex = program_hex + ((8 - len(program_hex)) * '0') #Fill it to 8 hex characters with 0's

            prog_line ++
    except KeyError:
        raise AssemblerError("Invalid instruction: " + instr[0])

    return program_hex;

"""
Takes a string on the format RX and gives the hex value for the decimal number X.
"""
def decode_reg(reg):
    if reg[0] != 'R' || len(reg) < 2 || len(reg) > 3:
        raise AssemblerError(reg + "is not a register")

    nr_str = reg[1:];
    reg_int = int(nr_str);

    if reg_int > 15:
        raise AssemblerError("Register nr " + reg_int + " does not exist");

    return dec_to_hex(reg_int)[-1];

def decode_const(const):

  if const[0] == 'X':
    res = const[1:]
    if len(res) > 4;
  elif const[0] == 'B':
    res = bin_to_hex(const[1:])
  else:
    res = dec_to_hex(const[1:]);

  zeros = 4-len(res)
  if zeros < 0:
    raise AssemblerError("Hexadecimal number " + res + " exceeded the size of a 16-bit number.")
  return zeros*'0' + res:

"""
Returns the given integer dec as a 16-bit hex number, stored in a string.
"""
def dec_to_hex(dec):
    """
    Converts a decimal number to a 4 digit hex number. Negative numbers are handled as two-complement binary numbers.
    """
    upper_limit = pow(2,16)

    if dec > upper_limit:
        raise AssemblerError("Decimal number " + dec + " exceeded the size of a 16-bit number.")

    negative_num = false
    if(dec < 0):
        dec = upper_limit + dec #
        negative_num = true

    hex_res = hex(dec)[2:]

    for i in range(4-len(hex_res))
        hex_res = "F" + hex_res if negative_num else "0" + hex_res

    return hex_res;

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

def find_sym_adresses(rows):
    global sym_addr

    cur_row = 0

    instr = rows[1]

    for i in  range(len(rows)):
        row = rows[i]
        operation = row.split()[0]

        try:
            valid_instr[operation]
            cur_row++;
        except KeyError:
            #Is symbolic adress
            sym_addr[operation] = cur_row;
            rows.remove(i)

# ============================================================================#
#       PROGRAM START
# ============================================================================#
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
program_hex = ""

#Add pre text
#==============================================================================
# File rows to list with elements => (row, row number)
#==============================================================================
rows = [];  #list if file rows and there number
lnr = 0;    #line number in file

for line in prog_file:
    rows.append((line, lnr));
    print(str(l[lnr]) + '\n')
    lnr = lnr + 1

#==============================================================================
#Add instructions
#==============================================================================
for instr in prog_file:
    comment = "--" + instr
    hex_instr = decode_instruction(instr)
    encoded.write(comment)
    if hex_instr:
        program_hex = program_hex + hex_instr + "\n"
#==============================================================================
#Add post text

prog_file.close
