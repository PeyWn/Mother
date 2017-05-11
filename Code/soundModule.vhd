library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity soundModule is
    port(
        clk : in std_logic;
        data_out : out std_logic := '0';
        send : in std_logic
    );
end soundModule;

--Divide clock with 500000 to get 200Hz

architecture Behavioral of soundModule is
    signal counter : unsigned(7 downto 0);
    signal clk_c : unsigned(17 downto 0) := to_unsigned(0, 18); -- enough to count to 250000
    signal low_clk : std_logic := '1';

    --constant SOUND_TIME : unsigned(7 downto 0) := to_unsigned(200, 8);

    begin

    -- CLK divider process
    process(clk) begin
        if rising_edge(clk) then
            if clk_c = 250000 then
                low_clk <= not low_clk;
                clk_c <= to_unsigned(0, 18);
            else
                clk_c <= clk_c + 1;
            end if;
        end if;
    end process;

    -- counter
    process(clk) begin
        if rising_edge(clk) then
            if send = '1' then
                counter <= to_unsigned(40,8);
            elsif (low_clk = '1') and (clk_c = 0) and (not (counter = 0)) then
                counter <= counter - 1;
            end if;
        end if;
    end process;

    --Sound out signal
    data_out <= counter(0);

end architecture;
