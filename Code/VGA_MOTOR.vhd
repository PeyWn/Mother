--------------------------------------------------------------------------------
-- Based on:

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
  port (
    clk	: in std_logic;
    --rst : in std_logic;

    -- Connection to vMem
	tileNr : in unsigned(7 downto 0);
	row	: out unsigned(7 downto 0);
    col	: out unsigned(7 downto 0);

    -- VGA out connection
	vgaRed_port : out std_logic_vector(2 downto 0);
	vgaGreen_port : out std_logic_vector(2 downto 0);
	vgaBlue_port : out std_logic_vector(2 downto 1);
	Hsync_port : out std_logic;
	Vsync_port : out std_logic
    );
end VGA_MOTOR;


-- architecture
architecture Behavioral of VGA_MOTOR is

  signal	Xpixel	        : unsigned(9 downto 0) := "0000000000";         -- Horizontal pixel counter
  signal	Ypixel	        : unsigned(9 downto 0) := "0000000000";		-- Vertical pixel counter
  signal	ClkDiv	        : unsigned(1 downto 0) := "00";		-- Clock divisor, to generate 25 MHz signal
  signal	Clk25		    : std_logic;			-- One pulse width 25 MHz signal

  signal 	tilePixel       : std_logic_vector(7 downto 0);	-- Tile pixel data
  signal	tileAddr	    : unsigned(13 Downto 0);	-- Tile address

  signal    blank : std_logic;                    -- blanking signal


  -- Tile memory type
  type ram_t is array (0 to 16383) of std_logic_vector(7 downto 0);

-- Tile memory
  signal tileMem : ram_t :=
		(
                x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC", -- One Tile
		x"FC",x"e3",x"e3",x"E3",x"e3",x"e3",x"E3",x"E3",x"E3",x"E3",x"e3",x"e3",x"e3",x"E3",x"E3",x"FC",
		x"FC",x"e3",x"E3",x"E3",x"E3",x"e3",x"e3",x"E3",x"E3",x"E3",x"e3",x"e3",x"e3",x"E3",x"E3",x"FC",
		x"FC",x"e3",x"E3",x"E3",x"E3",x"e3",x"e3",x"E3",x"E3",x"E3",x"e3",x"e3",x"e3",x"E3",x"E3",x"FC",
		x"FC",x"e3",x"e3",x"e3",x"e3",x"e3",x"e3",x"E3",x"E3",x"E3",x"e3",x"e3",x"e3",x"E3",x"E3",x"FC",
		x"FC",x"e3",x"E3",x"E3",x"E3",x"e3",x"e3",x"E3",x"E3",x"E3",x"e3",x"e3",x"e3",x"E3",x"E3",x"FC",
		x"FC",x"e3",x"E3",x"E3",x"E3",x"e3",x"e3",x"E3",x"E3",x"E3",x"e3",x"e3",x"e3",x"E3",x"E3",x"FC",
		x"FC",x"E3",x"E3",x"E3",x"E3",x"E3",x"E3",x"E3",x"E3",x"E3",x"e3",x"e3",x"e3",x"E3",x"E3",x"FC",
                x"FC",x"E3",x"e3",x"e3",x"e3",x"E3",x"E3",x"E3",x"E3",x"E3",x"e3",x"e3",x"e3",x"E3",x"E3",x"FC",
  		x"FC",x"e3",x"e3",x"E3",x"e3",x"e3",x"E3",x"E3",x"E3",x"E3",x"e3",x"e3",x"e3",x"E3",x"E3",x"FC",
  		x"FC",x"e3",x"E3",x"E3",x"E3",x"e3",x"e3",x"E3",x"E3",x"E3",x"e3",x"e3",x"e3",x"E3",x"E3",x"FC",
  		x"FC",x"e3",x"E3",x"E3",x"E3",x"e3",x"e3",x"E3",x"E3",x"E3",x"e3",x"e3",x"e3",x"E3",x"E3",x"FC",
  		x"FC",x"e3",x"e3",x"e3",x"e3",x"e3",x"e3",x"E3",x"E3",x"E3",x"e3",x"e3",x"e3",x"E3",x"E3",x"FC",
  		x"FC",x"e3",x"E3",x"E3",x"E3",x"e3",x"e3",x"E3",x"E3",x"E3",x"e3",x"e3",x"e3",x"E3",x"E3",x"FC",
  		x"FC",x"e3",x"E3",x"E3",x"E3",x"e3",x"e3",x"E3",x"E3",x"E3",x"e3",x"e3",x"e3",x"E3",x"E3",x"FC",
                x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",

        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- One Tile
		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",
  		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF"
        );

begin

  -- Clock divisor
  -- Divide system clock (100 MHz) by 4
  process(clk)
  begin
    if rising_edge(clk) then
        clkDiv <= clkDiv + 1;
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
    Hsync_port <= '0' when Xpixel >= 656 and Xpixel < 752 else
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
   Vsync_port <= '0' when Ypixel >= 490 and Ypixel < 492 else
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
  tileAddr <= unsigned(tileNr(5 downto 0)) & Ypixel(4 downto 1) & Xpixel(4 downto 1);


  -- Picture memory address composite
  row <= "0000" & Ypixel(8 downto 5) when blank = '0' else
         x"00";
  col <= "000" & Xpixel(9 downto 5) when blank = '0' else
         x"00";

  -- VGA generation
  vgaRed_port(2) 	<= tilePixel(7);
  vgaRed_port(1) 	<= tilePixel(6);
  vgaRed_port(0) 	<= tilePixel(5);
  vgaGreen_port(2)   <= tilePixel(4);
  vgaGreen_port(1)   <= tilePixel(3);
  vgaGreen_port(0)   <= tilePixel(2);
  vgaBlue_port(2) 	<= tilePixel(1);
  vgaBlue_port(1) 	<= tilePixel(0);


end Behavioral;

-- FF VIT
-- 00 SVART
-- 02 BL�
-- D4 KATT 25
-- CD BRUN
-- FC GUL 1E
-- E3 ROSA?
-- E0 R�D
