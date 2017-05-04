library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity soundModule is
    port(
        clk : in std_logic;
        data_out : std_logic := '0';
        send : in std_logic
    );
end soundModule;

--Divide clock with 500000 to get 200Hz

architecture Behavioral of soundModule is
    signal counter : unsigned(7 downto 0);
    signal clk_c : unsigned(17 downto 0); -- enough to count to 250000
    signal low_clk : std_logic := '0';

    constant SOUND_TIME : unsigned(7 downto 0);

    begin

    -- CLK divider process
    process(clk) begin
        if rising_edge(clk) then
            if clk_c = 250000 then
                low_clk <= not low_clk;
                clk_c <= 0;
            else
                low_clk <= low_clk + 1;
            end if;
        end if;
    end process;

    -- counter
    process(clk) begin
        if rising_edge(clk) then
            if send = 1 then
                counter <= SOUND_TIME;
            elsif low_clk = 1 and clk_c = 0 and not counter = 0 then
                counter <= counter - 1;
            end if;
        end if;
    end process;

    --Sound out signal
    data_out <= counter(0);

end architecture;
