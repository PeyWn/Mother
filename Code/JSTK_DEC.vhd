library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--Joystick interface
entity JSTK is
  port (
  CS           : out std_logic := '0';
  SCLK         : out std_logic;
  output_JSTK  : in std_logic;   -- döp om till rätt JSTK Pin 2
  CLK         : in std_logic;   -- JSTK Pin 4
  joy_btn1     : out std_logic;
  joy_btn2     : out std_logic;
  joy_left     : out std_logic;
  joy_right    : out std_logic;
  joy_up       : out std_logic;
  joy_down     : out std_logic
  );
end JSTK;

architecture Behavioral of JSTK is
  signal shift_reg   : unsigned(39 downto 0) := (others => '0');
  signal counter  : unsigned(5 downto 0)  := (others => '0');
  signal x_pos    : unsigned(9 downto 0);
  signal y_pos    : unsigned(9 downto 0);
  signal buttons  : unsigned(2 downto 0);

  -- System clock is 100 000 kHz
  -- Divide by 1500 to get 66.6666... kHz (suitable for joystick)
  signal clk_div_counter : unsigned(10 downto 0) := 0;
  signal low_clk : std_logic;

  begin

    -- clk divider counter
    process(clk)
    begin
        if rising_edge(clk) then
            if clk_div_counter = 1499 then
                clk_div_counter <= 0;
            else
                clk_div_counter <= clk_div_counter + 1;
            end if;
        end if;
    end process;

    process(clk, output_JSTK)
    begin
      if rising_edge(clk) and low_clk = '1' then
        --Shift in 40 bits from JOYSTK into shift_reg
        if counter < 40 then
          counter <= counter + 1;
          shift_reg(38 downto 0) <= shift_reg(39 downto 1);
          shift_reg(39) <= output_JSTK;

        else
          counter <= (others => '0');

          --Extract values from shift_reg into variables
          x_pos   <= shift_reg(9 downto 0);
          y_pos   <= shift_reg(25 downto 16);
          buttons <= shift_reg(34 downto 32);

        end if;
      end if;
    end process;

    --Set all output signals.
    -- x_/y_ pos is 2 to the power of 9, or 1024 dec large
    -- 1024 /4 and 3/4 equals 256 and 768 respectivly
    joy_up    <= '1' when (x_pos > 768) else '0';
    joy_down  <= '1' when (x_pos < 256) else '0';

    joy_right <= '1' when (y_pos > 768) else '0';
    joy_left  <= '1' when (y_pos < 256) else '0';

    joy_btn1 <= buttons(1);
    joy_btn2 <= buttons(2);

    SCLK <= low_clk;
end architecture;
