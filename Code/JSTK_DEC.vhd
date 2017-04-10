library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--Joystick interface
entity JSTK is
  port (
  enable : std_logic; 
  clk : in std_logic
  );
end entity;
