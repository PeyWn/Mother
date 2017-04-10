library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--LFSR interface, random vector generator
entity LFSR is
  port(rnd : out unsigned(15 downto 0);
    clk : in std_logic);
end LFSR;

architecture random_gen of LFSR is
  signal vector : unsigned(15 downto 0) := (others => '0');
  begin
    process(clk)
    begin
      if rising_edge(clk) then
        -- vector|15 feedback|14|13|11|10|9|8|7|6|5|4 taps|3|2 taps|1 taps|0|--
        -- tap: instead of shift one bit take tap bit XOR feedback and pass to next bit.

        vector(0) <= vector(15); -- vector(15) feedback
        vector(1) <= vector(0);
        vector(2) <= vector(1) xnor vector(15);
        vector(3) <= vector(2) xnor vector(15);
        vector(4) <= vector(3);
        vector(5) <= vector(4) xnor vector(15);
        vector(15 downto 6) <= vector(14 downto 5);

        rnd <= vector;
      end if;
    end process;
end random_gen;
