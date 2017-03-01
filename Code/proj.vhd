library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--CPU interface
entity proj is
  port(clk: in std_logic;
	     rst: in std_logic);
end proj ;

architecture Behavioral of proj is


  -- micro Memory component
  component uMem
    port(uAddr : in unsigned(5 downto 0);
         uData : out unsigned(15 downto 0));
  end component;

  -- program Memory component
  component pMem
    port(pAddr : in unsigned(15 downto 0);
         pData : out unsigned(15 downto 0));
  end component;
  
  -- micro memory signals
  signal uM : unsigned(15 downto 0); -- micro Memory output
  signal uPC : unsigned(5 downto 0); -- micro Program Counter
  signal uPCsig : std_logic; -- (0:uPC++, 1:uPC=uAddr)
  signal uAddr : unsigned(5 downto 0); -- micro Address
  signal TB : unsigned(2 downto 0); -- To Bus field
  signal FB : unsigned(2 downto 0); -- From Bus field
	
  -- program memory signals
  signal PM : unsigned(15 downto 0); -- Program Memory output
  signal PC : unsigned(15 downto 0); -- Program Counter
  signal Pcsig : std_logic; -- 0:PC=PC, 1:PC++
  signal ASR : unsigned(15 downto 0); -- Address Register
  signal IR : unsigned(15 downto 0); -- Instruction Register
  signal DATA_BUS : unsigned(15 downto 0); -- Data Bus
	

begin

  -- mPC : micro Program Counter
  process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        uPC <= (others => '0');
      elsif (uPCsig = '1') then
        uPC <= uAddr;
      else
        uPC <= uPC + 1;
      end if;
    end if;
  end process;
	
  -- PC : Program Counter
  process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        PC <= (others => '0');
      elsif (FB = "011") then
        PC <= DATA_BUS;
      elsif (PCsig = '1') then
        PC <= PC + 1;
      end if;
    end if;
  end process;
	
  -- IR : Instruction Register
  process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        IR <= (others => '0');
      elsif (FB = "001") then
        IR <= DATA_BUS;
      end if;
    end if;
  end process;
	
  -- ASR : Address Register
  process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        ASR <= (others => '0');
      elsif (FB = "100") then
        ASR <= DATA_BUS;
      end if;
    end if;
  end process;
	
  -- micro memory component connection
  U0 : uMem port map(uAddr=>uPC, uData=>uM);

  -- program memory component connection
  U1 : pMem port map(pAddr=>ASR, pData=>PM);
	
  -- micro memory signal assignments
  uAddr <= uM(5 downto 0);
  uPCsig <= uM(6);
  PCsig <= uM(7);
  FB <= uM(10 downto 8);
  TB <= uM(13 downto 11);
	
  -- data bus assignment
  DATA_BUS <= IR when (TB = "001") else
    PM when (TB = "010") else
    PC when (TB = "011") else
    ASR when (TB = "100") else
   (others => '0');

end Behavioral;
