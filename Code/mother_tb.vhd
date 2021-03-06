LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY mother_tb IS
END mother_tb;

ARCHITECTURE behavior OF mother_tb IS

  --Component Declaration for the Unit Under Test (UUT)
  COMPONENT mother
  PORT(clk : IN std_logic;
       rst : IN std_logic;
       MISO: in std_logic
       );
  END COMPONENT;

  --Inputs
  signal clk : std_logic:= '0';
  signal rst : std_logic:= '0';
  signal miso : std_logic:= '0';
  
  --Clock period definitions
  constant clk_period : time:= 1 us;

BEGIN
  -- Instantiate the Unit Under Test (UUT)
  uut: mother PORT MAP (
    clk => clk,
    rst => rst,
    MISO=> miso
  );

  -- Clock process definitions
  clk_process :process
  begin
    clk <= '0';
    wait for clk_period/2;
    clk <= '1';
    wait for clk_period/2;
  end process;

    -- Reset does nothing yet
	-- rst <= '1', '0' after 1.7 us;
END;
