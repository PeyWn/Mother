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
x"70000000", --BEEP
x"1000FFFF", --MOV R0 xFFFF
x"10100000", --MOV R1 0
x"10F00001", --MOV RF 1
x"3500F000", --SUB R0 R0 RF
x"60001000", --CMP R0 R1
x"5200fffa", --BRZ START
x"00000000", --NOP
x"5000fffb", --JMP LOOP
x"00000000", --NOP
others=>(others=>'0')
);

begin  -- pMem
pData <= p_mem(to_integer(pAddr));

end Behavioral;
