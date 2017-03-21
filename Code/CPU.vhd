library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity CPU is
    port(
        --System clk
        clk : in std_logic;

        --Video memory
        v_mem_row : out unsigned(7 downto 0);
        v_mem_col : out unsigned(7 downto 0);
        v_mem_operation : out std_logic;
    );
end CPU;

architecture Behavioral of CPU is
    --Program Counter
    signal PC : unsigned(9 downto 0) := "000000000";
    signal PC2 : unsigned(9 downto 0); --Program counter 2, for jumps

    signal PC_jmp : unsigned(9 downto 0); --Calculated jmp PC
    signal relative_jmp : signed(10 downto 0);

    --Pipelined registers
    signal isntr_reg0 : unsigned(31 downto 0);
    signal isntr_reg1 : unsigned(31 downto 0);
    signal isntr_reg2 : unsigned(31 downto 0);
    signal isntr_reg3 : unsigned(31 downto 0);

    --NOP
    constant NOP : unsigned(31 downto 0) := x"00000000";
begin
    --Process for PC assignement
    process(clk)
    begin
        if rising_edge(clk) then
            PC2 <= PC;

        end if;
    end process;

    --JMP address calculation
    relative_jmp <= instr_reg0(10 downto 0);
    process(clk)
    begin
        if rising_edge(clk) then
            PC_jmp <= (relative_jmp + '0' & to_integer(PC2))(9 downto 0);
        end if;
    end process;



end Behavioral;
