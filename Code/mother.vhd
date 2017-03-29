library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--CPU interface
entity mother is
  port(clk: in std_logic;
	     rst: in std_logic);
end mother ;

architecture Behavioral of mother is
  -- program Memory component
  component CPU
    port(
         --System clk
         clk : in std_logic;

         --Video memory
         v_mem_row : out unsigned(7 downto 0);
         v_mem_col : out unsigned(7 downto 0);
         v_mem_operation : out std_logic
         v_mem_data_out : out unsigned(7 downto 0);
         v_mem_data_in : in unsigned(7 downto 0)
         );
  end component;

  component vMem
    port(
        --Ports to connect to CPU
        CPU_addr_row : in unsigned(7 downto 0);
        CPU_addr_col : in unsigned(7 downto 0);
        CPU_operation : in std_logic; --1 is write, 0 is read
        CPU_in : in unsigned(7 downto 0);
        CPU_out : out unsigned(7 downto 0);

        clk : in std_logic();

        --Ports for VGA_motor connection
        VGA_addr_row : in std_logic_vector(7 downto 0);
        VGA_addr_col : in std_logic_vector(7 downto 0);
        VGA_out : out std_logic_vector(7 downto 0)
    );
  end component;

  signal vMem_row_cpu : unsigned(7 downto 0);
  signal vMem_col_cpu : unsigned(7 downto 0);
  signal vMem_row_vga : unsigned(7 downto 0);
  signal vMem_col_vga : unsigned(7 downto 0);
  signal vMem_out_cpu : unsigned(7 downto 0);
  signal vMem_out_vga : unsigned(7 downto 0);

  signal vMem_in_cpu : unsigned(7 downto 0);
  signal vMem_operation : std_logic;
begin

  -- Connect CPU
  C1 : CPU port map(clk=>clk, v_mem_row=>vMem_row_cpu, v_mem_col=>vMem_col_cpu,
                    v_mem_operation=>vMem_operation, v_mem_data_out=>vMem_in_cpu,
                    v_mem_data_in=>vMem_out_cpu);

  -- Connect video memeory
  C2 : vMem port map(clk=>clk, CPU_addr_row=>vMem_row_cpu,
                    CPU_addr_col=>vMem_col_cpu, CPU_operation=>vMem_operation,
                    CPU_in=>vMem_in_cpu, CPU_out=>vMem_out_cpu,
                    VGA_addr_row=>vMem_row_vga, VGA_addr_col=>vMem_col_vga,
                    VGA_out=>vMem_out_vga);

end Behavioral;
