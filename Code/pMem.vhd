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
x"59000006", --BRJU COUNT_UP
x"00000000", --NOP
x"5A00000d", --BRJD COUNT_DOWN
x"00000000", --NOP
x"5000fffc", --JMP LOOP_START
x"10200000", --MOV R2 0
x"40000000", --LDAV R0 0
x"10100001", --MOV R1 1
x"60021000", --CMP R2 R1
x"5200fff7", --BRZ LOOP_START
x"00000000", --NOP
x"34001000", --ADD R0 R0 R1
x"41000000", --STRV R0 0
x"5000fff3", --JMP LOOP_START
x"10200001", --MOV R2 1
x"40000000", --LDAV R0 0
x"1010ffff", --MOV R1 -1
x"60012000", --CMP R1 R2
x"5200ffee", --BRZ LOOP_START
x"00000000", --NOP
x"34001000", --ADD R0 R0 R1
x"41000000", --STRV R0 0
x"5000ffea", --JMP LOOP_START
x"1020ffff", --MOV R2 -1
others=>(others=>'0')
);

begin  -- pMem
pData <= p_mem(to_integer(pAddr));

end Behavioral;
