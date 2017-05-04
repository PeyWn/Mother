library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity CPU is
    port(
        --System clk
        clk : in std_logic;


        --JSTK
        decoded_joy_btn1     : in std_logic;
        decoded_joy_btn2     : in std_logic;
        decoded_joy_left     : in std_logic;
        decoded_joy_right    : in std_logic;
        decoded_joy_up       : in std_logic;
        decoded_joy_down     : in std_logic;

        --Video memory
        v_mem_row : out unsigned(7 downto 0);
        v_mem_col : out unsigned(7 downto 0);
        v_mem_operation : out std_logic;
        v_mem_data_read : in unsigned(7 downto 0);
        v_mem_data_write : out unsigned(7 downto 0);

        --Sound out
        send_sound : out std_logic
    );
end CPU;

architecture Behavioral of CPU is
    -- || Components ||
    -- Program memory
    component pMem port(
        pAddr : in unsigned(9 downto 0);
        pData : out unsigned(31 downto 0));
    end component;

    component regFile port(
            clk : in std_logic;

            --Reading from registers
            read_alpha : in unsigned(3 downto 0);
            output_alpha : out unsigned(15 downto 0);
            read_beta : in unsigned(3 downto 0);
            output_beta : out unsigned(15 downto 0);

            --Writing to registers
            write_reg : in unsigned(3 downto 0);
            write_data : in unsigned(15 downto 0);
            write_enable : in std_logic);
    end component;

    component CPU_comb_net port(
      ir0, ir1, ir2, ir3: in unsigned(31 downto 0);
       z, n, o, btn1, btn2, left, right, up, down, DF_prev, read_reg_prev : in std_logic;
       -- Flags in from CPU
       -- Z N O: Alu flags
       -- btn1, btn2, left, right, up, down: Joystick flags
       -- DF_prev: The value that DF_ir3 sould be.
       -- read reg prev: If previus instruction readed reg or not.

       ALU1_mux, dMem_write, vMem_write, regFile_write, jmp, stall, DF_next, read_reg_next  : out std_logic;
       -- ALU1_mux: if the mux should use constant or value from the register file.
       -- DF next: The value of DF_ir2.
       -- read reg next: If instrcution in ir0 reads reg, next clk the same is
       -- true for ir1.

       writeback_mux, DF_mux_a, DF_mux_b : out unsigned(1 downto 0);
       --       writeback_mux   DF_mux_*
       --00     vMem             Ingen
       --01     dMem             ir2
       --10     ALU              ir3
       --11     --               båda

       ALU_operation : out unsigned(3 downto 0);
       flag_update : out std_logic;
       play_sound : out std_logic);
    end component;

    component dMem
      port(
        --Ports to connect to CPU
        dMem_adress : in unsigned(15 downto 0);
        dMem_operation : in std_logic; --1 is write
        dMem_in : in unsigned(15 downto 0);
        dMem_out : out unsigned(15 downto 0);
        clk : in std_logic);
    end component;

    component ALU
      port(op_a,op_b: in unsigned(15 downto 0);
           op_code: in unsigned(3 downto 0);  --op_code counts from 0 to 9 in order
                                              --that is written in the enumeration
                                              --The op_code 1111 is reserved for no operation, op_a just bleeds through
           res: buffer unsigned(15 downto 0);
           z,n,o: out std_logic);
    end component;

    component LFSR
        port(rnd : out unsigned(15 downto 0);
            clk : in std_logic
          );
    end component;

    --|| End Components ||

    --Program Counter
    signal PC : unsigned(9 downto 0) := "0000000000";
    signal PC2 : unsigned(9 downto 0); --Program counter 2, for jumps

    signal PC_mux : unsigned(9 downto 0); --Mux for next PC value
    signal PC_jmp : unsigned(9 downto 0); --Calculated jmp PC
    signal relative_jmp : signed(10 downto 0);


    --Pipelined registers
    signal instr_reg0 : unsigned(31 downto 0);
    signal instr_reg1 : unsigned(31 downto 0);
    signal instr_reg3 : unsigned(31 downto 0);
    signal instr_reg2 : unsigned(31 downto 0);

    --NOP
    constant NOP : unsigned(31 downto 0) := x"00000000";

    --Instruction from program memory
    signal new_inst : unsigned(31 downto 0);

    --ALU Status flags
    signal ALU_Z, ALU_N, ALU_O : std_logic;  -- Statusflags received from ALU
                                             -- to be updated next clkcycle
    signal Z : std_logic; --Result is zero
    signal N : std_logic; --Result is negative (2 complement)
    signal O : std_logic; --Overflow

    --ALU registers
    signal pre_ALU_a, pre_ALU_b : unsigned(15 downto 0);
    signal ALU_res, ALU_res_reg : unsigned(15 downto 0);

    --Stage 3 data register
    signal stage3_data : unsigned(15 downto 0);

    --Joystick status flags
    signal joy_btn1 : std_logic;
    signal joy_btn2 : std_logic;
    signal joy_left : std_logic;
    signal joy_right : std_logic;
    signal joy_up : std_logic;
    signal joy_down : std_logic;

    --LFSR random signal vector
    signal rnd : unsigned(15 downto 0);

    --NOP, jmp and stall muxes
    signal reg0_mux : unsigned(31 downto 0);
    signal reg1_mux : unsigned(31 downto 0);

    --!!!!Control signals!!!!
    signal stall : std_logic; --stall (leave instruction in reg0)
    signal jmp : std_logic; --jmp next CPU cycle
    signal ALU_operation : unsigned(3 downto 0);  --Operation to send to ALU
    signal flag_update : std_logic;

    --Control signals for Dataforwarding (sending and receiving
    signal ir2_DF, ir3_DF, ir0_read_reg, ir1_read_reg : std_logic;

    --ALU,DF and writeback mux control signals
    signal ALU_mux : std_logic;
    signal DF_mux_a, DF_mux_b : unsigned(1 downto 0);
    signal writeback_mux : unsigned(1 downto 0);

    -- Register file registers
    signal reg_a : unsigned(15 downto 0); --First register under register file
    signal reg_b : unsigned(15 downto 0); --Second register under register file

    signal instr_const_reg : unsigned(15 downto 0); --Register for adress or constant directly from instruction

    -- Data memory registers
    signal pre_dMem : unsigned(15 downto 0);
    signal post_dMem : unsigned(15 downto 0);
    signal post_dMem_data : unsigned(15 downto 0);
    signal dMem_write : std_logic;

    --Video memory registers
    signal pre_vMem : unsigned(15 downto 0);
    signal post_vMem : unsigned(15 downto 0);
    signal vMem_write : std_logic;

    --Register file in signals
    signal regFile_read1 : unsigned(3 downto 0);
    signal regFile_output1 : unsigned(15 downto 0);
    signal regFile_read2 : unsigned(3 downto 0);
    signal regFile_output2 : unsigned(15 downto 0);

    signal regFile_wReg : unsigned(3 downto 0);
    signal regFile_wData : unsigned(15 downto 0);
    signal regFile_wEnable : std_logic;

    --Muxes
    signal constant_mux : unsigned(15 downto 0);
    signal alu1_mux : unsigned(15 downto 0);
    signal alu2_mux : unsigned(15 downto 0);

    signal writeback_mux_data : unsigned(15 downto 0);

begin
  --Connect combinatoric net for control signals -- read in control_Signals.vhd
  --for more info
  comb_net : CPU_comb_net port map (ir0 => instr_reg0, ir1 => instr_reg1, ir2 => instr_reg2, ir3 => instr_reg3,
                                    z => Z, n => N, o => O,

                                    btn1 => joy_btn1, btn2 => joy_btn2,
                                    left => joy_left, right => joy_right, up => joy_up, down => joy_down,

                                    DF_prev => ir3_DF, DF_next => ir2_DF,
                                    read_reg_prev => ir1_read_reg, read_reg_next => ir0_read_reg,

                                    ALU1_mux => ALU_mux, DF_mux_a => DF_mux_a, DF_mux_b => DF_mux_b,
                                    writeback_mux => writeback_mux,

                                    dMem_write => dMem_write, vMem_write => vMem_write,
                                    regFile_write => regFile_wEnable,
                                    jmp => jmp, stall => stall,

                                    ALU_operation => ALU_operation,
                                    flag_update=>flag_update
                                    play_sound=>send_sound);


  --Process for forwarding of the DF and read_reg values from one ir step to
  --the next
  process(clk)
  begin
    if rising_edge(clk) then
      ir3_DF <= ir2_DF;
      ir1_read_reg <= ir0_read_reg;
    end if;
  end process;

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
    relative_jmp <= signed(std_logic_vector(instr_reg0(10 downto 0)));
    process(clk)
    begin
        if rising_edge(clk) then
            PC_jmp <= to_unsigned(to_integer(relative_jmp) + to_integer(PC2), 10);
        end if;
    end process;

  --Connect ALU
  A1 : ALU port map
    (op_a => pre_ALU_A, op_b => pre_ALU_B, op_code => ALU_operation,
     res => ALU_res,
     z => ALU_Z, n => ALU_N, o => ALU_O);

  pre_ALU_a <= constant_mux;
  pre_ALU_b <= alu2_mux;

    --Pipelining forward
    process(clk)
    begin
        if(rising_edge(clk)) then
            instr_reg0 <= reg0_mux;
            instr_reg1 <= reg1_mux;
            instr_reg2 <= instr_reg1;
            instr_reg3 <= instr_reg2;
        end if;
    end process;

    --Jmp and stall mux
    reg0_mux <= NOP when jmp = '1' else
                instr_reg0 when stall = '1' else
                new_inst;

    reg1_mux <= NOP when stall = '1' else
                instr_reg0;

  --Connect data memory
  D1 : dMem port map ( dMem_in => pre_dMem, dMem_out => post_dMem_data,
                       clk => clk,
                       dMem_adress => ALU_res_reg, dMem_operation => dMem_write);

  process(clk)
    begin
      if rising_edge(clk) then
        pre_dMem <= alu1_mux;
        pre_vMem <= alu1_mux;

        post_dMem <= post_dMem_data;
      end if;
  end process;

  --Connect register file
  C2 : regFile port map(clk => clk, read_alpha => regFile_read1,
                                read_beta => regFile_read2,
                                output_alpha => regFile_output1,
                                output_beta => regFile_output2,
                                write_reg => regFile_wReg,
                                write_data => regFile_wData,
                                write_enable => regFile_wEnable);

  regFile_read1 <= instr_reg0(19 downto 16);
  regFile_read2 <= instr_reg0(15 downto 12);
  regFile_wReg <= instr_reg3(23 downto 20);
  regFile_wData <= writeback_mux_data;

  -- Connect LFS-register
  L1 : LFSR port map( clk => clk, rnd => rnd);

  -- Registers around register file
  process(clk)
  begin
    if rising_edge(clk) then
      instr_const_reg <= instr_reg0(15 downto 0);

      reg_a <= regFile_output1;
      reg_b <= regFile_output2;
    end if;
  end process;

  --Muxes above ALU
  constant_mux <= instr_const_reg when ALU_mux = '1' else
                  alu1_mux;

  alu1_mux <= ALU_res_reg when DF_mux_a(1) = '1' else
              writeback_mux_data when DF_mux_a(0) = '1' else
              reg_a;

  alu2_mux <= ALU_res_reg when DF_mux_b(1) = '1' else
              writeback_mux_data when DF_mux_b(0) = '1' else
              reg_b;

  --writeback MUX
  writeback_mux_data <= stage3_data when writeback_mux = "10" else
                        post_dMem when writeback_mux = "01" else
                        rnd when writeback_mux = "11" else
                        post_vMem;

  --Pass ALU res to next step
  process(clk)
    begin
      if rising_edge(clk) then
        ALU_res_reg <= ALU_res;
        stage3_data <= ALU_res_reg;
      end if;
    end process;

    --Update status flags
    process(clk)
      begin
        if rising_edge(clk) and flag_update = '1' then
          Z <= ALU_Z;
          N <= ALU_N;
          O <= ALU_O;
        end if;
      end process;

    --vMem connections
    v_mem_row <= ALU_res_reg(15 downto 8);
    v_mem_col <= ALU_res_reg(7 downto 0);
    v_mem_operation <= vMem_write;
    v_mem_data_write <= pre_vMem(7 downto 0);

    -- Move data forwarding information forward
    process(clk)
      begin
        if rising_edge(clk) then
          post_vMem <= x"00" & v_mem_data_read;
        end if;
      end process;

    --JSTK connection
    joy_btn1 <= decoded_joy_btn1;
    joy_btn2 <= decoded_joy_btn2;
    joy_up   <= decoded_joy_up;
    joy_down <= decoded_joy_down;
    joy_right <= decoded_joy_right;
    joy_left <= decoded_joy_left;

end Behavioral;
