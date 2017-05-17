library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity soundModule is
    port(
        clk : in std_logic;
        data_out : out std_logic := '0';
        send : in std_logic;
        sound_select : in unsigned(1 downto 0)  --what sound to play
    );
end soundModule;

--Divide clock with 500000 to get 200Hz

architecture Behavioral of soundModule is
    signal counter : unsigned(17 downto 0);
    signal clk_c : unsigned(17 downto 0) := to_unsigned(0, 18); -- enough to count to 250000
    signal clk_divider : unsigned(17 downto 0) := (others=>'0');  --Sets the limit forthe clock
    signal sound_cycles : unsigned(17 downto 0) := (others=>'0');  --How many cycles should be beeping
    signal low_clk : std_logic := '1';
    signal send_prev : std_logic := '1';
    signal send_ep : std_logic := '0';

    begin

    process(clk)
    begin
      if rising_edge(clk) then
        if send = '1' then
          case sound_select is
            when "00" => clk_divider <= to_unsigned(250000,18);
            when "01" => clk_divider <= to_unsigned(150000,18);
            when "10" => clk_divider <= to_unsigned(50000,18);
            when "11" => clk_divider <= to_unsigned(20000,18);
            when others => null;
          end case;
       case sound_select is
            when "00" => sound_cycles <= to_unsigned(40,18);
            when "01" => sound_cycles <= to_unsigned(120,18);
            when "10" => sound_cycles <= to_unsigned(200,18);
            when "11" => sound_cycles <= to_unsigned(500,18);
            when others => null;
          end case;
        end if;
        send_prev <= send;
        send_ep <= send_prev and (not send);

      end if;
    end process;
    
    -- CLK divider process
    process(clk) begin
        if rising_edge(clk) then
            if clk_c = clk_divider then
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
            if send_ep = '1' then
                counter <= sound_cycles;
            elsif (low_clk = '1') and (clk_c = 0) and (not (counter = 0)) then
                counter <= counter - 1;
            end if;
        end if;
    end process;

    --Sound out signal
    data_out <= counter(0);

end architecture;
