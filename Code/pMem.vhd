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
x"5900000e", --BRJU COUNT_UP
x"00000000", --NOP
x"5A000015", --BRJD COUNT_DOWN
x"00000000", --NOP
x"5C00001c", --BRJL COUNT_LEFT
x"00000000", --NOP
x"5B000023", --BRJR COUNT_RIGHT
x"00000000", --NOP
x"5700002a", --BRB1 COUNT_B1
x"00000000", --NOP
x"58000031", --BRB2 COUTN_B2
x"00000000", --NOP
x"5000fff4", --JMP LOOP_START
x"10200000", --MOV R2 0
x"40000000", --LDAV R0 0
x"10100001", --MOV R1 1
x"60021000", --CMP R2 R1
x"5200ffef", --BRZ LOOP_START
x"00000000", --NOP
x"34001000", --ADD R0 R0 R1
x"41000000", --STRV R0 0
x"5000ffeb", --JMP LOOP_START
x"10200001", --MOV R2 1
x"40000000", --LDAV R0 0
x"1010ffff", --MOV R1 -1
x"60012000", --CMP R1 R2
x"5200ffe6", --BRZ LOOP_START
x"00000000", --NOP
x"34001000", --ADD R0 R0 R1
x"41000000", --STRV R0 0
x"5000ffe2", --JMP LOOP_START
x"1020ffff", --MOV R2 -1
x"40000001", --LDAV R0 1
x"10100001", --MOV R1 1
x"60012000", --CMP R1 R2
x"5200ffdd", --BRZ LOOP_START
x"00000000", --NOP
x"34001000", --ADD R0 R0 R1
x"41000001", --STRV R0 1
x"5000ffd9", --JMP LOOP_START
x"10200001", --MOV R2 1
x"40000001", --LDAV R0 1
x"1010ffff", --MOV R1 -1
x"60012000", --CMP R1 R2
x"5200ffd4", --BRZ LOOP_START
x"00000000", --NOP
x"34001000", --ADD R0 R0 R1
x"41000001", --STRV R0 1
x"5000ffd0", --JMP LOOP_START
x"1020ffff", --MOV R2 -1
x"40000002", --LDAV R0 2
x"10100001", --MOV R1 1
x"60012000", --CMP R1 R2
x"5200ffcb", --BRZ LOOP_START
x"00000000", --NOP
x"34001000", --ADD R0 R0 R1
x"41000002", --STRV R0 2
x"5000ffc7", --JMP LOOP_START
x"10200001", --MOV R2 1
x"40000002", --LDAV R0 2
x"1010ffff", --MOV R1 -1
x"60012000", --CMP R1 R2
x"5200ffc2", --BRZ LOOP_START
x"00000000", --NOP
x"34001000", --ADD R0 R0 R1
x"41000002", --STRV R0 2
x"5000ffbe", --JMP LOOP_START
x"1020ffff", --MOV R2 -1
others=>(others=>'0')
);

begin  -- pMem
pData <= p_mem(to_integer(pAddr));

end Behavioral;
