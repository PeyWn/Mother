library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vMem is
    port(
        --Ports to connect to CPU
        CPUaddrRow : in unsigned(7 downto 0);
        CPUaddrCol : in unsigned(7 downto 0);
        CPUoperation : in std_logic(); --1 is write, 0 is read
        CPUin : in unsigned(7 downto 0);
        CPUout : out unsigned(7 downto 0);

        clk : in std_logic();

        --Ports for VGA_motor connection
        VGAaddrRow : in std_logic_vector(7 downto 0);
        VGAaddrCol : in std_logic_vector(7 downto 0);
        VGAout : out std_logic_vector(7 downto 0);
    );
end vMem;

architecture Behavioral of vMem is
    type vMemData is array (0 to 299) of unsigned(7 downto 0);

    signal memory : vMemData;
begin
    --Read operations
    VGAout <= memory(VGAaddrRow * to_unsigned(15, 8) + );

end Behavioral;
