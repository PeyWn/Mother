library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dMem is
    port(
        --Ports to connect to CPU
      dMem_adress : in unsigned(15 downto 0);               
      dMem_operation : in std_logic; --1 is write
      dMem_in : in unsigned(15 downto 0);
      dMem_out : out unsigned(15 downto 0);
      clk : in std_logic);
end dMem;

architecture Behavioral of dMem is
    type dMemData is array (0 to 32767) of unsigned(15 downto 0);

    signal memory : dMemData := (others=>(others=>'0'));
    
begin
--Write
  process(clk) begin
     if rising_edge(clk) and dMem_operation = '1' then
       memory(to_integer(dMem_adress)) <= dMem_in;
     end if;
  end process;

  --Read
  dMem_out <= memory(to_integer(dMem_adress(14 downto 0)));

end Behavioral;
