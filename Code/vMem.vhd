library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vMem is
    port(
        --Ports to connect to CPU
        CPU_addr_row : in unsigned(7 downto 0);
        CPU_addr_col : in unsigned(7 downto 0);
        CPU_operation : in std_logic; --1 is write, 0 is read
        CPU_in : in unsigned(7 downto 0);
        CPU_out : out unsigned(7 downto 0);

        clk : in std_logic;

        --Ports for VGA_motor connection
        VGA_addr_row : in unsigned(7 downto 0);
        VGA_addr_col : in unsigned(7 downto 0);
        VGA_out : out unsigned(7 downto 0)
    );
end vMem;

architecture Behavioral of vMem is
    type v_mem_data is array (0 to 299) of unsigned(7 downto 0);

    signal memory : v_mem_data;

    signal VGA_addr : unsigned(7 downto 0);
    signal CPU_addr : unsigned(7 downto 0);
    signal VGA_row_start, CPU_row_start : unsigned(15 downto 0);
begin
    --Address calculations
    VGA_row_start <= VGA_addr_row * to_unsigned(15, 8);
    CPU_row_start <= CPU_addr_row * to_unsigned(15, 8);

    VGA_addr <= VGA_row_start(7 downto 0) + VGA_addr_col;
    CPU_addr <= CPU_row_start(7 downto 0) + CPU_addr_col;

    --Read operations
    VGA_out <= memory(to_integer(VGA_addr));
    WITH CPU_operation select
        CPU_out <=   memory(to_integer(CPU_addr)) when '0',
                    x"00" when others;

    --CPU writing to memory
    process(clk)
    begin
        if rising_edge(clk) AND CPU_operation = '1' then
            memory(to_integer(CPU_addr)) <= CPU_in;
        end if;
    end process;
end Behavioral;
