library IEEE;
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
x"10000007", --MOV R0 7
x"10100010", --MOV R1 x10
x"10200084", --MOV R2 b10000100 //132
x"210000AA", --STR R0 xAA
x"20F000AA", --LDA RF xAA //Should put 7 in RF
x"23001000", --STRR R0 R1
x"22E10000", --LDAR RE R1 //Should put 7 in RE
x"1000f0f0", --MOV R0 b1111000011110000
x"30100000", --NOT R1 R0 //0000111100001111
x"32201000", --AND R2 R0 R1 //0000 in R2
x"31301000", --OR R3 R0 R1 //FFFF in R3
x"33403000", --XOR R4 R0 R3 //0000111100001111 in R4
x"1000002b", --MOV R0 43
x"10100d81", --MOV R1 3457
x"34301000", --ADD R3 R0 R1 //3500 in R3
x"35431000", --SUB R4 R3 R1 //43 in R0
x"10500003", --MOV R5 3
x"36605000", --MUL R6 R0 R5 //129 in R6
x"10900002", --MOV R9 2
x"37709000", --LSR R7 R0 R9 //10 in R7
x"10900001", --MOV R9 1
x"38879000", --LSL R8 R7 r9 //20 in R8
x"10000004", --MOV R0 4
x"10100007", --MOV R1 7
x"41000000", --STRV R0 0
x"41010001", --STRV R1 1
x"41000002", --STRV R0 x2
x"41010003", --STRV R1 b11
x"40200003", --LDAV R2 3 //7 in R2
x"10400002", --MOV R4 2
x"43044000", --STRVR R4 R4
x"42040000", --LDAVR R0 R4 //2 in R0
x"50000004", --JMP JUMP_HERE
x"00000000", --NOP
x"00000000", --NOP
x"00000000", --NOP //Not run
x"10000005", --MOV R0 5
x"10100007", --MOV R1 7
x"60001000", --CMP R0 R1
x"51000002", --BRN BRN_JMP //jump
x"00000000", --NOP
x"54000013", --BRNN DIE //not jump
x"00000000", --NOP
x"60000000", --CMP R0 R0
x"52000004", --BRZ BRZ_JMP //jump
x"00000000", --NOP
x"00000000", --NOP
x"00000000", --NOP
x"5500000c", --BRNZ DIE //not jump
x"00000000", --NOP
x"1000FFFF", --MOV R0 xFFFF
x"34100000", --ADD R1 R0 R0
x"53000002", --BRO BRO_JMP //jump
x"00000000", --NOP
x"56000006", --BRNO DIE //not jump
x"00000000", --NOP
x"00000000", --NOP
x"00000000", --NOP
x"00000000", --NOP
x"00000000", --NOP
x"50000000", --JMP DIE
x"00000000", --NOP
others=>(others=>'0')
);

begin  -- pMem
pData <= p_mem(to_integer(pAddr));

end Behavioral;
