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
x"57000007", --BRB1 PRESS
x"00000000", --NOP
x"58000005", --BRB2 PRESS
x"00000000", --NOP
x"10000000", --MOV R0 0
x"5000fffb", --JMP START
x"00000000", --NOP
x"10100001", --MOV R1 1
x"60010000", --CMP R1 R0
x"5200fff7", --BRZ START
x"00000000", --NOP
x"10100001", --MOV R1 1
x"40300000", --LDAV R3 0
x"34331000", --ADD R3 R3 R1
x"41030000", --STRV R3 0
x"5000fff1", --JMP START
x"00000000", --NOP
others=>(others=>'0')
);

begin  -- pMem
pData <= p_mem(to_integer(pAddr));

end Behavioral;
