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
                  x"00",x"10",x"20",x"30",x"40",x"50",x"60",x"70",x"80",x"90",x"A0",x"B0",x"C0",x"D0",x"E0",x"F0",
                  x"01",x"11",x"21",x"31",x"41",x"51",x"61",x"71",x"81",x"91",x"A1",x"B1",x"C1",x"D1",x"E1",x"F1",
                  x"02",x"12",x"22",x"32",x"42",x"52",x"62",x"72",x"82",x"92",x"A2",x"B2",x"C2",x"D2",x"E2",x"F2",
                  x"03",x"13",x"23",x"33",x"43",x"53",x"63",x"73",x"83",x"93",x"A3",x"B3",x"C3",x"D3",x"E3",x"F3",
                  x"04",x"14",x"24",x"34",x"44",x"54",x"64",x"74",x"84",x"94",x"A4",x"B4",x"C4",x"D4",x"E4",x"F4",
                  x"05",x"15",x"25",x"35",x"45",x"55",x"65",x"75",x"85",x"95",x"A5",x"B5",x"C5",x"D5",x"E5",x"F5",
                  x"06",x"16",x"26",x"36",x"46",x"56",x"66",x"76",x"86",x"96",x"A6",x"B6",x"C6",x"D6",x"E6",x"F6",
                  x"07",x"17",x"27",x"37",x"47",x"57",x"67",x"77",x"87",x"97",x"A7",x"B7",x"C7",x"D7",x"E7",x"F7",
                  x"08",x"18",x"28",x"38",x"48",x"58",x"68",x"78",x"88",x"98",x"A8",x"B8",x"C8",x"D8",x"E8",x"F8",
                  x"09",x"19",x"29",x"39",x"49",x"59",x"69",x"79",x"89",x"99",x"A9",x"B9",x"C9",x"D9",x"E9",x"F9",
                  x"0A",x"1A",x"2A",x"3A",x"4A",x"5A",x"6A",x"7A",x"8A",x"9A",x"AA",x"BA",x"CA",x"DA",x"EA",x"FA",
                  x"0B",x"1B",x"2B",x"3B",x"4B",x"5B",x"6B",x"7B",x"8B",x"9B",x"AB",x"BB",x"CB",x"DB",x"EB",x"FB",
                  x"0C",x"1C",x"2C",x"3C",x"4C",x"5C",x"6C",x"7C",x"8C",x"9C",x"AC",x"BC",x"CC",x"DC",x"EC",x"FC",
                  x"0D",x"1D",x"2D",x"3D",x"4D",x"5D",x"6D",x"7D",x"8D",x"9D",x"AD",x"BD",x"CD",x"DD",x"ED",x"FD",
                  x"0E",x"1E",x"2E",x"3E",x"4E",x"5E",x"6E",x"7E",x"8E",x"9E",x"AE",x"BE",x"CE",x"DE",x"EE",x"FE",
                  x"0F",x"1F",x"2F",x"3F",x"4F",x"5F",x"6F",x"7F",x"8F",x"9F",x"AF",x"BF",x"CF",x"DF",x"EF",x"FF",
                  
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
