import sys

#CONSTANTS
FILE_NAME = "pMem.vhd"

INSTR_WIDTH = 32
INST_COUNT = 1024

OTHERS_SYNTAX = "others=>(others=>'0')"

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
    'NOP': ('000','00'),
    'MOV': ('R0C','10'),
    'LDA': ('R0C','20'),
    'STR': ('0RC','21'),
    'LDAR': ('RR0','22'),
    'STRR': ('0RR','23'),
    'NOT': ('RR0','30'),
    'OR' : ('RRR','31'),
    'AND' : ('RRR','32'),
    'XOR' : ('RRR','33'),
    'ADD' : ('RRR','34'),
    'SUB' : ('RRR','35'),
    'MUL' : ('RRR','36'),
    'LSR' : ('RRC','37'),
    'LSL' : ('RRC','38'),
    'LDAV' : ('R0C','40'),
    'STRV' : ('0RC','41'),
    'LDAVR' : ('RR0','42'),
    'STRVR' : ('0RR','43'),
    'JMP' : ('00S','50'),
    'BRN' : ('00S','51'),
    'BRZ' : ('00S','52'),
    'BRO' : ('00S','53'),
    'BRNN' : ('00S','54'),
    'BRNZ' : ('00S','55'),
    'BRNO' : ('00S','56'),
    'BRB1' : ('00S','57'),
    'BRB2' : ('00S','58'),
    'BRJU' : ('00S','59'),
    'BRJD' : ('00S','5A'),
    'BRJR' : ('00S','5B'),
    'BRJL' : ('00S','5C'),
    'CMP' : ('0RR','60')
    }

#List of symbloic adresses, formar is {SYMBOLIC_ADRESS:(PROGRAM_LINE, FILE_LINE)} to generate good error message"
sym_addr = {}

#Counter to know what program line the assembler is at, used for relative jumps and similar
prog_line = 0

def decode_instruction(instr):
    """
    Takes a line of assembly code and converts it to a hex instruction.
    Returns the hex encoded instruction if succesful, otherwise it returns an empty string
    """
    global sym_addr
    global prog_line
    global file_line

    program_hex = ""

    instr = instr.upper()
    instr = instr.split()

    try:
        instr_data = valid_instr[instr[0]]    #Check if it is an instruction
        instr_format =  instr_data[0]           #The general structure of the instruction
        program_hex = instr_data[1]             #The hexcode for the instruction
        instr = instr[1:]                       #Remove the instruction so that the first in instr is the next register/constant to be evaluated
        for char in instr_format:
            if char == '0':
                program_hex = program_hex + "0"
            else:
                if len(instr) == 0:
                    raise AssemblerError("Too few arguments given.")

                if char == 'R':
                    program_hex = program_hex + decode_reg(instr[0])
                    instr = instr[1:]
                elif char == 'C':
                    program_hex = program_hex + decode_const(instr[0])
                    instr = instr[1:]
                elif char == 'S':
                    program_hex = program_hex + get_jmp(instr[0])
                    instr = instr[1:]

        program_hex = program_hex + ((8 - len(program_hex)) * '0') #Fill it to 8 hex characters with 0's

    except KeyError:
        raise AssemblerError("Invalid instruction: " + instr[0])

    return program_hex

HEX_VALUES = [hex(i)[2].upper() for i in range(16)]

"""
Takes a string on the format RX and gives the hex value for the decimal number X.
"""
def decode_reg(reg):
    if reg[0] != 'R' or len(reg) < 2 or len(reg) > 3:
        raise AssemblerError(reg + "is not a register")

    reg_i = reg[1:];

    if not (reg_i in HEX_VALUES):
        raise AssemblerError("Register nr " + reg_int + " does not exist");

    return reg_i;

def decode_const(const):
    """
    Decodes constant from a decimal, binary or hexadecimal. Returns a 4 character long string of hexadecimal numbers.
    """

    if const[0] == 'X':
        res = const[1:]
    elif const[0] == 'B':
        res = bin_to_hex(const[1:])
    else:
        try:
            res = dec_to_hex(int(const));
        except ValueError:
            raise AssemblerError(const + " is not a decimal number.")

    zeroes = 4-len(res)

    if zeroes < 0:
        raise AssemblerError("Hexadecimal number " + res + " exceeded the size of a 16-bit number.")

    return zeroes*'0' + res

def dec_to_hex(dec):
    """
    Converts a decimal number to a 4 digit hex number. Negative numbers are handled as two-complement binary numbers.
    """
    upper_limit = pow(2,16)
    if dec > upper_limit:
        print(dec)
        print("Wut?")
        raise AssemblerError("Decimal number " + dec + " exceeded the size of a 16-bit number.")

    negative_num = False
    if(dec < 0):
        dec = upper_limit + dec #
        negative_num = True

    hex_res = hex(dec)[2:]

    for i in range(4-len(hex_res)):
        hex_res = "F" + hex_res if negative_num else "0" + hex_res

    return hex_res;

def bin_to_hex(binary):
    """
    Converts a string of 1s and 0s from a binary number to a string of hexadecimal numbers.
    """
    if len(binary) > 16:
        raise AssemblerError(binary + " is not a valid 16 bit binary number.")

    tot = 0

    for i in range(0, len(binary)):
        cur_n = binary[(len(binary) - 1) - i]

        if cur_n  == '1':
            tot += pow(2,i)
        elif cur_n != '0':
            raise AssemblerError("Symbol " + cur_n + " of " + binary + "is not a binary symbol.")

    return dec_to_hex(tot);

def get_jmp(sym_address):
    """
    Returns the relative jump in hex.
    """
    global prog_line

    try:
        jmp_line = sym_addr[sym_address]
    except KeyError:
        raise AssemblerError("Symbolic adress " + sym_adress + " not found.");

    relative_jmp = jmp_line - prog_line;

    return dec_to_hex(relative_jmp)

def find_sym_adresses(rows):
    """
    Loops through all rows and finds the symbolic addresses.
    """
    global sym_addr

    cur_row = 0
    while cur_row < len(rows):
        row = rows[cur_row]
        operation = row[1].split()[0]

        try:
            valid_instr[operation]
            cur_row += 1
        except KeyError:
            #Is symbolic adress
            sym_addr[operation] = cur_row
            del rows[cur_row]

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

#==============================================================================
# File rows to list with elements => (row, row number)
#==============================================================================
rows = [];  #list if file rows and there number
lnr = 1;    #line number in file

for line in prog_file:
    #Check so line is not empty
    line = line.strip()

    if line:
        rows.append((lnr, line));

    lnr = lnr + 1
#==============================================================================
# Pre Process symbolic adresses
#==============================================================================
find_sym_adresses(rows)

#==============================================================================
#Add instructions
#==============================================================================
program_hexes = []

for row in rows:
    instr = row[1]
    file_lnr = row[0]
    comment = "--" + instr
    try:
        hex_instr = decode_instruction(instr)
        prog_line += 1
    except AssemblerError as e:
        print("Syntax Error: Instruction " + instr)
        print(input_file_name + ": line " + str(file_lnr) + " | " + e.value)
        sys.exit(0);

    program_hexes.append((hex_instr, comment))
#==============================================================================
# Write to file
#==============================================================================
output_file = open(FILE_NAME, "w")

output_file.write(PRE_TEXT)

for i in range(len(program_hexes)):
    write_hex = program_hexes[i]
    output_file.write("x\"" + write_hex[0] + "\",")

    output_file.write(" " + write_hex[1])

    output_file.write("\n")

output_file.write(OTHERS_SYNTAX + "\n")

output_file.write(POST_TEXT)
prog_file.close

print("Assembly Succesfull")
