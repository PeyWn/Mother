library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- uMem interface
entity uMem is
  port (
    uAddr : in unsigned(5 downto 0);
    uData : out unsigned(15 downto 0));
end uMem;

architecture Behavioral of uMem is

-- micro Memory
type u_mem_t is array (0 to 15) of unsigned(15 downto 0);
constant u_mem_c : u_mem_t :=
   --OP_TB_FB_PC_uPC_uAddr
  (b"00_011_100_0_0_000000", -- ASR:=PC
   b"00_010_001_1_1_000000", -- IR:=PM, PC:=PC+1
   b"00_000_000_0_0_000000",
   b"00_000_000_0_0_000000",
   b"00_000_000_0_0_000000",
   b"00_000_000_0_0_000000",
   b"00_000_000_0_0_000000",
   b"00_000_000_0_0_000000",
   b"00_000_000_0_0_000000",
   b"00_000_000_0_0_000000",
   b"00_000_000_0_0_000000",
   b"00_000_000_0_0_000000",
   b"00_000_000_0_0_000000",
   b"00_000_000_0_0_000000",
   b"00_000_000_0_0_000000",
   b"00_000_000_0_0_000000");

signal u_mem : u_mem_t := u_mem_c;

begin  -- Behavioral
  uData <= u_mem(to_integer(uAddr));

end Behavioral;
