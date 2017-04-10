library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--Joystick interface
entity JSTK is
  port (
  CS           : out std_logic := '0';
  output_JSTK  : in std_logic;   -- döp om till rätt JSTK Pin 2
  SCLK         : in std_logic;   -- JSTK Pin 4
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

  begin
    process(clk, output_JSTK)
    begin
      if rising_edge(clk) then

        --Shift in 40 bits from JOYSTK into shift_reg
        if counter < 40 then
          counter <= counter + '1';
          shift_reg(38 downto 0) <= shift_reg(39 downto 1);
          shift_reg(39) <= output_JSTK;

        else
          counter <= counter(others => '0');

          --Extract values from shift_reg into variables
          x_pos   <= shift_reg(9 downto 0);
          y_pos   <= shift_reg(25 downto 16);
          buttons <= shift_reg(34 downto 32);

        end if;
      end if;
    end process;

    --Set all output signals.
    -- x_/y_ pos is 2 to the power of 9, or 512 bits large
    -- 512 /4 and 3/4 equals 128 and 384 respectivly
    joy_up    <= '1' when (x_pos > 384) else '0';
    joy_down  <= '1' when (x_pos < 128) else '0';

    joy_right <= '1' when (y_pos > 384) else '0';
    joy_left  <= '1' when (y_pos < 128) else '0';

    joy_btn1 <= buttons(1);
    joy_btn2 <= buttons(2);

end architecture;
