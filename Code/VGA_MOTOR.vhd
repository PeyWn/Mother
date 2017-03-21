--------------------------------------------------------------------------------
-- VGA MOTOR
-- Anders Nilsson
-- 16-feb-2016
-- Version 1.1


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type


-- entity
entity VGA_MOTOR is
  port ( clk			: in std_logic;
	 data			: in std_logic_vector(7 downto 0);
	 addr			: out unsigned(10 downto 0);
	 rst			: in std_logic;
	 vgaRed		        : out std_logic_vector(2 downto 0);
	 vgaGreen	        : out std_logic_vector(2 downto 0);
	 vgaBlue		: out std_logic_vector(2 downto 1);
	 Hsync		        : out std_logic;
	 Vsync		        : out std_logic);
end VGA_MOTOR;


-- architecture
architecture Behavioral of VGA_MOTOR is

  signal	Xpixel	        : unsigned(9 downto 0);         -- Horizontal pixel counter
  signal	Ypixel	        : unsigned(9 downto 0);		-- Vertical pixel counter
  signal	ClkDiv	        : unsigned(1 downto 0);		-- Clock divisor, to generate 25 MHz signal
  signal	Clk25		: std_logic;			-- One pulse width 25 MHz signal
		
  signal 	tilePixel       : std_logic_vector(7 downto 0);	-- Tile pixel data
  signal	tileAddr	: unsigned(10 Downto 0);	-- Tile address

  signal        blank           : std_logic;                    -- blanking signal
	

  -- Tile memory type
  type ram_t is array (0 to 2047) of std_logic_vector(7 downto 0);

-- Tile memory
  signal tileMem : ram_t := 
		( x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",      -- space
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",

		  x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",	-- A
		  x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",

		  x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",      -- B
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",

		  x"FF",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",      -- C
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"FF",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",

		  x"FF",x"FF",x"00",x"FF",x"FF",x"FF",x"00",x"D4",  -- D
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"D4",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"D4",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",
                  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
                  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
                  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
                  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
                  
		  x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"FF",  -- E
		  x"AB",x"AB",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"AB",x"AB",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"AB",x"AB",x"AB",x"AB",x"AB",x"FF",x"FF",x"FF",
		  x"AB",x"AB",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"AB",x"AB",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",


		  x"D4",x"D4",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",  -- F
		  x"D4",x"D4",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"D4",x"D4",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
                  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
                  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
                  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
                  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
                  
                  x"00",x"D4",x"D4",x"D4",x"00",x"FF",x"FF",x"FF",  -- G
		  x"00",x"D4",x"D4",x"D4",x"00",x"FF",x"FF",x"FF",
		  x"00",x"D4",x"D4",x"D4",x"00",x"FF",x"FF",x"FF",
		  x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",
                  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
                  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
                  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
                  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
                  
                  x"FF",x"FF",x"00",x"FF",x"FF",x"FF",x"00",x"D4",  -- H
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"D4",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"D4",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",
                  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
                  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
                  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
                  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
   

		  x"D4",x"D4",x"D4",x"D4",x"00",x"00",x"FF",x"FF",  -- I
		  x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		  x"D4",x"D4",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"D4",x"D4",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"D4",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",

		  x"FF",x"FF",x"FF",x"AA",x"AA",x"AA",x"AA",x"FF",  -- J
		  x"FF",x"FF",x"FF",x"FF",x"AA",x"AA",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"AA",x"AA",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"AA",x"AA",x"FF",x"FF",
		  x"FF",x"AA",x"FF",x"FF",x"AA",x"AA",x"FF",x"FF",
		  x"FF",x"AA",x"AA",x"FF",x"AA",x"AA",x"FF",x"FF",
		  x"FF",x"FF",x"AA",x"AA",x"AA",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",

		  x"E0",x"E3",x"CD",x"00",x"00",x"D4",x"D4",x"D4",  -- K
		  x"E0",x"E3",x"CD",x"00",x"D4",x"00",x"00",x"00",
		  x"E3",x"E3",x"CD",x"00",x"D4",x"D4",x"D4",x"D4",
		  x"E0",x"E3",x"CD",x"00",x"D4",x"D4",x"D4",x"D4",
		  x"E0",x"E3",x"CD",x"00",x"D4",x"D4",x"D4",x"D4",
		  x"E3",x"E3",x"CD",x"00",x"D4",x"D4",x"D4",x"D4",
		  x"CD",x"CD",x"CD",x"00",x"D4",x"D4",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"D4",x"00",x"FF",x"FF",

		  x"CD",x"CD",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",  -- L
		  x"CD",x"CD",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"CD",x"CD",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"CD",x"CD",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"CD",x"CD",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"CD",x"CD",x"CD",x"CD",x"CD",x"CD",x"CD",x"FF",
		  x"CD",x"CD",x"CD",x"CD",x"CD",x"CD",x"CD",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",

		  x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"CD",x"E3",  -- M
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"CD",x"E3",
		  x"FF",x"FF",x"FF",x"00",x"00",x"00",x"CD",x"E3",
		  x"FF",x"FF",x"00",x"D4",x"D4",x"00",x"CD",x"E3",
		  x"FF",x"00",x"D4",x"D4",x"00",x"00",x"CD",x"E3",
		  x"FF",x"00",x"D4",x"00",x"FF",x"00",x"CD",x"E3",
		  x"FF",x"00",x"D4",x"00",x"FF",x"00",x"CD",x"CD",
		  x"FF",x"00",x"D4",x"00",x"FF",x"00",x"00",x"00",

		  x"E0",x"E0",x"E3",x"E0",x"E0",x"E0",x"E3",x"E0",  -- N
		  x"E0",x"E0",x"E3",x"E0",x"E0",x"E0",x"E3",x"E0",
		  x"E3",x"E3",x"E3",x"E3",x"E3",x"E3",x"E3",x"E3",
		  x"E0",x"E0",x"E3",x"E0",x"E0",x"E0",x"E3",x"E0",
		  x"E0",x"E0",x"E3",x"E0",x"E0",x"E0",x"E3",x"E0",
		  x"E3",x"E3",x"E3",x"E3",x"E3",x"E3",x"E3",x"E3",
		  x"CD",x"CD",x"CD",x"CD",x"CD",x"CD",x"CD",x"CD",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",

		  x"FF",x"FF",x"15",x"15",x"15",x"FF",x"FF",x"FF",  -- O
		  x"FF",x"15",x"15",x"15",x"15",x"15",x"FF",x"FF",
		  x"15",x"15",x"FF",x"FF",x"FF",x"15",x"15",x"FF",
		  x"15",x"15",x"FF",x"FF",x"FF",x"15",x"15",x"FF",
		  x"15",x"15",x"FF",x"FF",x"FF",x"15",x"15",x"FF",
		  x"FF",x"15",x"15",x"15",x"15",x"15",x"FF",x"FF",
		  x"FF",x"FF",x"15",x"15",x"15",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",

		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",  -- P
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"02",x"02",x"02",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"02",x"02",x"02",x"02",x"02",x"02",
		  x"FF",x"FF",x"02",x"02",x"02",x"02",x"02",x"02",
		  x"FF",x"FF",x"FC",x"FC",x"FC",x"02",x"02",x"02",
		  x"FF",x"FF",x"02",x"02",x"FC",x"FC",x"FC",x"FC",
		  x"FF",x"FF",x"02",x"02",x"02",x"02",x"02",x"02",

		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",  -- Q
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FC",x"02",x"02",x"02",x"00",x"00",x"00",x"FF",
		  x"FC",x"02",x"02",x"02",x"00",x"CD",x"00",x"FF",
		  x"FC",x"02",x"02",x"02",x"00",x"CD",x"00",x"FF",
		  x"FC",x"FC",x"FC",x"FC",x"00",x"CD",x"00",x"FF",
		  x"FC",x"02",x"02",x"02",x"00",x"CD",x"00",x"FF",
		  x"FC",x"02",x"02",x"02",x"00",x"CD",x"00",x"FF",

		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",  -- R
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"00",x"D4",x"00",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"00",x"D4",x"00",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"00",x"D4",x"D4",x"00",x"FF",

		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",  -- S
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"00",x"D4",x"00",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"00",x"D4",x"00",x"FF",x"FF",
		  x"FF",x"FF",x"00",x"D4",x"D4",x"00",x"FF",x"FF",

		  x"FF",x"FF",x"02",x"02",x"02",x"02",x"02",x"02",  -- T
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"02",x"02",x"02",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"CD",x"CD",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"CD",x"E3",

		  x"FC",x"02",x"02",x"02",x"00",x"CD",x"00",x"FF",  -- U
		  x"FC",x"FF",x"FF",x"FF",x"00",x"CD",x"00",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"00",x"CD",x"00",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"00",x"CD",x"00",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"00",x"CD",x"00",x"FF",
		  x"00",x"00",x"00",x"00",x"00",x"CD",x"00",x"00",
		  x"CD",x"CD",x"CD",x"CD",x"CD",x"CD",x"CD",x"CD",
		  x"E3",x"E3",x"E3",x"E3",x"E3",x"E3",x"E3",x"E3",

		  x"FF",x"FF",x"00",x"D4",x"D4",x"D4",x"D4",x"00",  -- V
		  x"FF",x"FF",x"00",x"D4",x"D4",x"D4",x"D4",x"D4",
		  x"FF",x"00",x"D4",x"D4",x"D4",x"00",x"00",x"D4",
		  x"FF",x"00",x"D4",x"D4",x"D4",x"00",x"FF",x"D4",
		  x"FF",x"00",x"D4",x"D4",x"D4",x"D4",x"D4",x"D4",
		  x"00",x"00",x"D4",x"D4",x"D4",x"D4",x"D4",x"D4",
		  x"CD",x"CD",x"00",x"D4",x"D4",x"00",x"D4",x"D4",
		  x"E3",x"E3",x"00",x"D4",x"D4",x"D4",x"00",x"00",

		  x"00",x"00",x"D4",x"D4",x"D4",x"D4",x"00",x"FF",  -- W
		  x"D4",x"D4",x"D4",x"D4",x"D4",x"D4",x"00",x"FF",
		  x"D4",x"D4",x"00",x"00",x"D4",x"D4",x"D4",x"00",
		  x"D4",x"D4",x"FF",x"00",x"D4",x"D4",x"D4",x"00",
		  x"D4",x"D4",x"D4",x"D4",x"D4",x"D4",x"D4",x"00",
		  x"D4",x"D4",x"D4",x"D4",x"D4",x"D4",x"D4",x"00",
		  x"00",x"D4",x"D4",x"00",x"D4",x"D4",x"00",x"FF",
		  x"00",x"00",x"00",x"D4",x"D4",x"D4",x"00",x"FF",

		  x"E0",x"E0",x"FF",x"FF",x"FF",x"E0",x"E0",x"FF",	-- X
		  x"FF",x"E0",x"E0",x"FF",x"E0",x"E0",x"FF",x"FF",
		  x"FF",x"FF",x"E0",x"E0",x"E0",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"E0",x"E0",x"E0",x"FF",x"FF",x"FF",
		  x"FF",x"E0",x"E0",x"FF",x"E0",x"E0",x"FF",x"FF",
		  x"E0",x"E0",x"FF",x"FF",x"FF",x"E0",x"E0",x"FF",
		  x"E0",x"FF",x"FF",x"FF",x"FF",x"FF",x"E0",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",

		  x"FF",x"1C",x"1C",x"FF",x"FF",x"1C",x"1C",x"FF",      -- Y
		  x"FF",x"1C",x"1C",x"FF",x"FF",x"1C",x"1C",x"FF",
		  x"FF",x"1C",x"1C",x"FF",x"FF",x"1C",x"1C",x"FF",
		  x"FF",x"FF",x"1C",x"1C",x"1C",x"1C",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"1C",x"1C",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"1C",x"1C",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"1C",x"1C",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",

		  x"03",x"03",x"03",x"03",x"03",x"03",x"03",x"FF",      -- Z
		  x"FF",x"FF",x"FF",x"FF",x"03",x"03",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"03",x"03",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"03",x"03",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"03",x"03",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"03",x"03",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"03",x"03",x"03",x"03",x"03",x"03",x"03",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",

		  x"FF",x"FF",x"FF",x"00",x"FF",x"FF",x"FF",x"FF",      -- Å
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",

		  x"FF",x"FF",x"00",x"FF",x"00",x"FF",x"FF",x"FF",      -- Ä
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",

		  x"FF",x"FF",x"00",x"FF",x"00",x"FF",x"FF",x"FF",      -- Ö
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"FF",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",

		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",

		--x"FF",x"FF",x"FC",x"FC",x"FC",x"FC",x"FF",x"FF",      -- PACMAN CURSOR
		--x"FF",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FF",
		--x"FC",x"FC",x"FC",x"FC",x"00",x"FC",x"FF",x"FF",
		--x"FC",x"FC",x"FC",x"FC",x"FC",x"FF",x"FF",x"FF",
		--x"FC",x"FC",x"FC",x"FC",x"FC",x"FF",x"FF",x"FF",
		--x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FF",x"FF",
		--x"FF",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FF",
		--x"FF",x"FF",x"FC",x"FC",x"FC",x"FC",x"FF",x"FF"

                  x"FF",x"FF",x"FC",x"FC",x"FC",x"FC",x"FF",x"FF",      -- PACMAN CURSOR
		  x"FF",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FF",
		  x"FF",x"FF",x"FC",x"00",x"FC",x"FC",x"FC",x"FC",
		  x"FF",x"FF",x"FF",x"FC",x"FC",x"FC",x"FC",x"FC",
		  x"FF",x"FF",x"FF",x"FC",x"FC",x"FC",x"FC",x"FC",
		  x"FF",x"FF",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",
		  x"FF",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FF",
		  x"FF",x"FF",x"FC",x"FC",x"FC",x"FC",x"FF",x"FF"

                  

                  );
		  
begin

  -- Clock divisor
  -- Divide system clock (100 MHz) by 4
  process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
	ClkDiv <= (others => '0');
      else
	ClkDiv <= ClkDiv + 1;
      end if;
    end if;
  end process;
	
  -- 25 MHz clock (one system clock pulse width)
  Clk25 <= '1' when (ClkDiv = 3) else '0';
	
	
  -- Horizontal pixel counter

  process(clk)
    begin
      if rising_edge(clk) then
        if Clk25 = '1' then
          Xpixel <= Xpixel + 1;
          if Xpixel = 799 then
            Xpixel <= "0000000000";
          end if;
        end if;
      end if;
    end process;

  
  -- Horizontal sync


    Hsync <= '0' when Xpixel >= 656 and Xpixel < 752 else
             '1';
  
  -- Vertical pixel counter
  
  process(clk)
    begin
      if rising_edge(clk) then
         if Xpixel = 799 and Clk25 = '1' then
           if Ypixel = 520 then
             Ypixel <= "0000000000";
           else
           Ypixel <= Ypixel + 1;
           end if;
         end if;
      end if;
    end process;	

  -- Vertical sync

   Vsync <= '0' when Ypixel >= 490 and Ypixel < 492 else
            '1';
    
  -- Blank

  blank <= '1' when Xpixel >= 640 or Ypixel >= 480 else
           '0';

    
  -- Tile memory
  process(clk)
  begin
    if rising_edge(clk) then
      if (blank = '0') then
        tilePixel <= tileMem(to_integer(tileAddr));
      else
        tilePixel <= (others => '0');
      end if;
    end if;
  end process;
	


  -- Tile memory address composite
  tileAddr <= unsigned(data(4 downto 0)) & Ypixel(4 downto 2) & Xpixel(4 downto 2);


  -- Picture memory address composite
  addr <= to_unsigned(20, 7) * Ypixel(8 downto 5) + Xpixel(9 downto 5);


  -- VGA generation
  vgaRed(2) 	<= tilePixel(7);
  vgaRed(1) 	<= tilePixel(6);
  vgaRed(0) 	<= tilePixel(5);
  vgaGreen(2)   <= tilePixel(4);
  vgaGreen(1)   <= tilePixel(3);
  vgaGreen(0)   <= tilePixel(2);
  vgaBlue(2) 	<= tilePixel(1);
  vgaBlue(1) 	<= tilePixel(0);


end Behavioral;

-- FF VIT
-- 00 SVART
-- 02 BLÅ
-- D4 KATT 25
-- CD BRUN
-- FC GUL 1E
-- E3 ROSA?
-- E0 RÖD
