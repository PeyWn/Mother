library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity regFile is
    port(
        clk : in std_logic;

        --Reading from registers
        read_alpha : in unsigned(3 downto 0);
        output_alpha : out unsigned(15 downto 0);
        read_beta : in unsigned(3 downto 0);
        output_beta : out unsigned(15 downto 0);

        --Writing to registers
        write_reg : in unsigned(3 downto 0);
        write_data : in unsigned(15 downto 0);
        write_enable : in std_logic
    );
end regFile;

architecture Behavioral of regFile is
    type reg_data is array (0 to 15) of unsigned(15 downto 0);
    constant default_reg : reg_data :=
        (
        x"0000",
        x"0000",
        x"0000",
        x"0000",
        x"0000",
        x"0000",
        x"0000",
        x"0000",
        x"0000",
        x"0000",
        x"0000",
        x"0000",
        x"0000",
        x"0000",
        x"0000",
        x"0000"
        );

    signal registers : reg_data := default_reg;
begin
    --Reading
    output_alpha <= write_data when write_enable = '1' and read_alpha = write_reg else
                    registers(to_integer(read_alpha));
    
    output_beta <= write_data when write_enable = '1' and read_beta = write_reg else
                   registers(to_integer(read_beta));

    process(clk)
    begin
        if rising_edge(clk) and write_enable = '1' then
            registers(to_integer(write_reg)) <= write_data;
        end if;
    end process;
end Behavioral;
