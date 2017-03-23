library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity write_lookup is
    port(
        instr : in unsigned(7 downto 0);
        does_write : out std_logic
    );
end write_lookup;

architecture Behavioral of write_lookup is
    begin

    does_write <= '1' when instr = x"10" or --MOV
                        instr = x"20" or -- LDA
                        instr = x"30" or -- NOT
                        instr = x"31" or -- OR
                        instr = x"32" or -- AND
                        instr = x"33" or -- XOR
                        instr = x"34" or -- ADD
                        instr = x"35" or -- SUB
                        instr = x"36" or -- MUL
                        instr = x"37" or -- LSR
                        instr = x"38" or -- LSL
                        instr = x"40" or -- LDAV
                '0';
end Behavioral;
