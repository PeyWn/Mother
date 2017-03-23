library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;



 -- CODE FROM THIS SHALL BE MOVED AND FILE DELETED




entity stall_jmp_logic is
    port(
        --instructions to compare
        inst0 : in unsigned(31 downto 0);
        inst1 : in unsigned(31 downto 0);
        status_reg : in unsigned(2 downto 0)           --|Z|N|O| flags
    );
end stall_jmp_logic;

architecture Behavioral of stall_jmp_logic is
    signal do_jmp : std_logic;
    signal does_read : std_logic;
    signal mem_access : std_logic;

    signal op1 : unsigned(7 downto 0);
    signal op2 : unsigned(7 downto 0);

    begin
        Z := status_reg(0);
        N
        O
        op1 := inst0(31 downto 24);

        do_jmp <= '1' when
                (op1 = "01010000") or                   --JMP
                (op1 = "01010001" and N = '1') or       --BRN
                (op1 = "01010010" and Z = '1') or       --BRZ
                (op1 = "01010011" and O = '1') or       --BRO
                (op1 = "01010100" and N = '0') or       --BRNN
                (op1 = "01010101" and Z = '0') or       --BRNZ
                (op1 = "01010110" and O = '0') or       --BRNO
                (op1 = "01010111") or


end Behavioral;
