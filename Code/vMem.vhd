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

    signal memory : v_mem_data :=
      (
        x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",
        x"0F",x"0F",x"10",x"10",x"0F",x"0F",x"12",x"12",x"0F",x"0F",x"11",x"11",x"0F",x"0D",x"0B",x"0F",x"13",x"13",x"0F",x"0F",
        x"0F",x"0F",x"10",x"0F",x"10",x"0F",x"12",x"0F",x"11",x"0F",x"11",x"0F",x"0F",x"0D",x"0F",x"0F",x"13",x"0F",x"0F",x"0F",
        x"0F",x"0F",x"10",x"10",x"0F",x"0F",x"12",x"12",x"0F",x"0F",x"11",x"11",x"0F",x"0C",x"0D",x"0F",x"13",x"13",x"0F",x"0F",
        x"0F",x"0F",x"10",x"0F",x"0F",x"0F",x"12",x"0F",x"12",x"0F",x"11",x"0F",x"0F",x"0F",x"0D",x"0F",x"0F",x"13",x"0F",x"0F",
        x"0F",x"0F",x"10",x"0F",x"0F",x"0F",x"12",x"0F",x"12",x"0F",x"11",x"11",x"0F",x"0B",x"0B",x"0F",x"13",x"13",x"0F",x"0F",
        x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",
        x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",x"0F",
        x"10",x"10",x"10",x"0F",x"0F",x"10",x"11",x"12",x"11",x"10",x"0F",x"11",x"0F",x"0F",x"0F",x"13",x"0F",x"0F",x"13",x"0F",
        x"10",x"0F",x"0F",x"10",x"0F",x"0F",x"0F",x"13",x"0F",x"0F",x"0F",x"11",x"12",x"0F",x"0F",x"13",x"0F",x"13",x"13",x"0F",
        x"10",x"0F",x"0F",x"10",x"0F",x"0F",x"0F",x"12",x"0F",x"0F",x"0F",x"11",x"0F",x"12",x"0F",x"13",x"0F",x"0F",x"13",x"0F",
        x"10",x"10",x"10",x"0F",x"0F",x"0F",x"0F",x"11",x"0F",x"0F",x"0F",x"11",x"0F",x"12",x"0F",x"13",x"0F",x"0F",x"13",x"0F",
        x"10",x"0F",x"0F",x"10",x"0F",x"0F",x"0F",x"0E",x"0F",x"0F",x"0F",x"11",x"0F",x"12",x"0F",x"13",x"0F",x"0F",x"13",x"0F",
        x"10",x"0F",x"0F",x"10",x"0F",x"0F",x"0F",x"10",x"0F",x"0F",x"0F",x"11",x"0F",x"0F",x"12",x"13",x"0F",x"0F",x"0E",x"0F",
        x"10",x"10",x"10",x"0F",x"0F",x"0F",x"0F",x"10",x"0F",x"0F",x"0F",x"11",x"0F",x"0F",x"0F",x"13",x"0F",x"13",x"13",x"13"
      );

    signal VGA_addr : unsigned(8 downto 0);
    signal CPU_addr : unsigned(8 downto 0);
    signal VGA_row_start, CPU_row_start : unsigned(15 downto 0);
begin
    --Address calculations
    VGA_row_start <= VGA_addr_row * to_unsigned(20, 8);
    CPU_row_start <= CPU_addr_row * to_unsigned(20, 8);

    VGA_addr <= VGA_row_start(8 downto 0) + VGA_addr_col;
    CPU_addr <= CPU_row_start(8 downto 0) + CPU_addr_col;

    --Read operations
    VGA_out <= memory(to_integer(VGA_addr));
    CPU_out <= memory(to_integer(CPU_addr)) when CPU_operation = '0' and CPU_addr < 300 else
                   x"0F";

    --CPU writing to memory
    process(clk)
    begin
        if rising_edge(clk) then
          if CPU_operation = '1' then
            memory(to_integer(CPU_addr)) <= CPU_in;
          end if;
        end if;
    end process;
end Behavioral;
