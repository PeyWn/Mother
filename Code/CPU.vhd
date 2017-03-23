library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity CPU is
    port(
        --System clk
        clk : in std_logic;

        --Video memory
        v_mem_row : out unsigned(7 downto 0);
        v_mem_col : out unsigned(7 downto 0);
        v_mem_operation : out std_logic
    );
end CPU;

architecture Behavioral of CPU is
    -- || Components ||
    -- Program memory
    component pMem port(
        pAddr : in unsigned(9 downto 0);
        pData : out unsigned(31 downto 0));
    end component;

    --Program Counter
    signal PC : unsigned(9 downto 0) := "000000000";
    signal PC2 : unsigned(9 downto 0); --Program counter 2, for jumps

    signal PC_mux : unsigned(9 downto 0); --Mux for next PC value
    signal PC_jmp : unsigned(9 downto 0); --Calculated jmp PC
    signal relative_jmp : signed(10 downto 0);


    --Pipelined registers
    signal isntr_reg0 : unsigned(31 downto 0);
    signal isntr_reg1 : unsigned(31 downto 0);
    signal isntr_reg3 : unsigned(31 downto 0);
    signal isntr_reg2 : unsigned(31 downto 0);

    --NOP
    constant NOP : unsigned(31 downto 0) := x"00000000";

    --Instruction from program memory
    signal new_inst : unsigned(31 downto 0);

    --ALU Status flags
    signal Z : std_logic; --Result is zero
    signal N : std_logic; --Result is negative (2 complement)
    signal O : std_logic; --Overflow

    --Joystick status flags
    signal joy_btn1 : std_logic;
    signal joy_btn2 : std_logic;
    signal joy_left : std_logic;
    signal joy_right : std_logic;
    signal joy_up : std_logic;
    signal joy_down : std_logic;

    --NOP, jmp and stall muxes
    signal reg0_mux : unsigned(15 downto 0);
    signal reg1_mux : unsigned(15 downto 0);

    --!!!!Control signals!!!!
    signal stall : std_logic; --stall (leave instruction in reg0)
    signal jmp : std_logic; --jmp next CPU cycle



    -- Register file registers
    signal reg_n : unsigned(15 downto 0); --First register under register file
    signal reg_m : unsigned(15 downto 0); --Second register under register file

    signal instr_const_reg : unsigned(15 downto 0); --Register for adress or constant directly from instruction

    -- Data memory registers
    signal pre_dMem : unsigned(15 downto 0);
    signal post_dMem : unsigned(15 downto 0);

    --Video memory registers
    signal pre_vMem : unsigned(15 downto 0);
    signal post_vMem : unsigned(15 downto 0);

begin
    --Process for PC assignement
    process(clk)
    begin
        if rising_edge(clk) then
            PC2 <= PC;

            --PC Mux
            PC <= PC_mux;
        end if;
    end process;

    --PC Mux
    PC_mux <= PC when stall = '1' else
            PC_jmp when jmp = '1' else
            PC + 1;

    --Connect program memory
    C1 : pMem  port map(pAddr => PC, pData => new_inst);

    --JMP address calculation
    relative_jmp <= instr_reg0(10 downto 0);
    process(clk)
    begin
        if rising_edge(clk) then
            PC_jmp <= (relative_jmp + '0' & to_integer(PC2))(9 downto 0);
        end if;
    end process;

    --Pipelining forward
    process(clk)
    begin
        if(rising_edge(clk)) then
            reg0 <= reg0_mux;
            reg1 <= reg1_mux;
            reg2 <= reg1;
            reg3 <= reg2;
        end if;
    end process;

    --Jmp and stall mux
    reg0_mux <= NOP when jmp = '1' else
                reg0 when stall = '1' else
                new_inst;

    reg1_mux <= NOp when stall = '1' else
                reg0;



end Behavioral;
