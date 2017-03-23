library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity read_lookup is
    port(
        instr : in unsigned(7 downto 0);
        does_read : out std_logic
    );
end read_lookup;

architecture Behavioral of read_lookup is
    begin

    does_read <= '1' when instr = x"21" or --STR
                        instr = x"30" or -- NOT
                        instr = x"31" or -- OR
                        instr = x"32" or -- AND
                        instr = x"33" or -- XOR
                        instr = x"34" or -- ADD
                        instr = x"35" or -- SUB
                        instr = x"36" or -- MUL
                        instr = x"37" or -- LSR
                        instr = x"38" or -- LSL
                        instr = x"41" or -- STRV
                        instr = x"60" else -- CMP
                '0';
end Behavioral;
