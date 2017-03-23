library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity CPU_comb_net is
  port(ir0, ir1, ir2, ir3: in unsigned(31 downto 0);
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
       --00     TMP             Ingen
       --01     TMP             ir2
       --10     TMP             ir3
       --11     TMP             båda
       
       ALU_operation : out unsigned(3 downto 0);
       
end CPU_comb_net;

architecture net of CPU_comb_net is

  signal read_reg_ir0 : std_logic;
  signal read_reg_ir1 : std_logic;
  signal mem_access : std_logic;
  signal DF_ir2 : std_logic;
  signal DF_ir3 : std_logic;
  signal DF_ir2_a, DF_ir2_b, DF_ir3_a, DF_ir3_b : std_logic;
  --Signals to calculate if ir2/ir3 wants to dataforward to operand a or b
  
begin

  --read_reg
  read_reg_ir0 <= '1' when
                  ir0(32 downto 24) = x"21" or      -- STR
                  ir0(32 downto 24) = x"30" or      -- NOT
                  ir0(32 downto 24) = x"31" or      -- OR
                  ir0(32 downto 24) = x"32" or      -- AND
                  ir0(32 downto 24) = x"33" or      -- XOR
                  ir0(32 downto 24) = x"34" or      -- ADD
                  ir0(32 downto 24) = x"35" or      -- SUB
                  ir0(32 downto 24) = x"36" or      -- MUL
                  ir0(32 downto 24) = x"37" or      -- LSR
                  ir0(32 downto 24) = x"38" or      -- LSL
                  ir0(32 downto 24) = x"41" or      -- STRV
                  ir0(32 downto 24) = x"60" else    -- CMP
                  '0';
  
  read_reg_next <= read_reg_ir0;
  read_reg_ir1 <= read_reg_prev; 
  
  --DF_ALU 
  DF_ir2 <= '1' when
            ir2(31 downto 24) = "00010000" or    --MOV
            ir2(31 downto 24) = "00100000" or    --LDA
            ir2(31 downto 24) = "00110000" or    --NOT
            ir2(31 downto 24) = "00110001" or    --OR
            ir2(31 downto 24) = "00110010" or    --AND
            ir2(31 downto 24) = "00110011" or    --XOR
            ir2(31 downto 24) = "00110100" or    --ADD
            ir2(31 downto 24) = "00110101" or    --SUB
            ir2(31 downto 24) = "00110110" or    --MUL
            ir2(31 downto 24) = "00110111" or    --LSR
            ir2(31 downto 24) = "00111000" or    --LSL
            ir2(31 downto 24) = "01000000" else  --LDAV
            '0';
  --DF_mem
  DF_ir3 <= DF_prev;
  
  DF_next <= DF_ir2; --Save the result to use in the next step instead of doing
                     --the same comparison twice

  --DF muxxing and fluxxing
  DF_ir2_a <= "1" when (DF_ir2 = '1' and read_reg_ir1 = '1') and
              ir2(23 downto 20) = ir1(19 downto 16) else
              '0';

  DF_ir2_b <= "1" when (DF_ir2 = '1' and read_reg_ir1 = '1') and
              ir2(23 downto 20) = ir1(15 downto 12) else
              '0';
  
  DF_ir3_a <= "1" when (DF_ir3 = '1' and read_reg_ir1 = '1') and
              ir3(23 downto 20) = ir1(19 downto 16) else
              '0';

  DF_ir3_b <= "1" when (DF_ir3 = '1' and read_reg_ir1 = '1') and
              ir3(23 downto 20) = ir1(15 downto 12) else
              '0';

  DF_mux_a <= DF_ir3_a & DF_ir2_a;
  DF_mux_b <= DF_ir3_b & DF_ir2_b;
  
  --mem_access
  mem_accsess <= '1' when
                 ir1(31 downto 24) = x"20" or   --LDA
                 ir1(31 downto 24) = x"40" else --LDAV
                 '0';
                  
  --jump
  jmp <= '1' when (ir1(31 downto 24) = "01010000") or           --JMP
         (ir1(31 downto 24) = "01010001" and N = '1') or        --BRN
         (ir1(31 downto 24) = "01010010" and Z = '1') or        --BRZ
         (ir1(31 downto 24) = "01010011" and O = '1') or        --BRO
         (ir1(31 downto 24) = "01010100" and N = '0') or        --BRNN
         (ir1(31 downto 24) = "01010101" and Z = '0') or        --BRNZ
         (ir1(31 downto 24) = "01010110" and O = '0') or        --BRNO
         (ir1(31 downto 24) = "01010111" and btn1 = '0') or     --BRB1
         (ir1(31 downto 24) = "01011000" and btn2 = '0') or     --BRB2
         (ir1(31 downto 24) = "01011001" and up = '0') or       --BRJU
         (ir1(31 downto 24) = "01011010" and down = '0') or     --BRJD
         (ir1(31 downto 24) = "01011011" and left = '0') or     --BRJL
         (ir1(31 downto 24) = "01011100" and right = '0') else  --BRJR
         '0';
 
  
  --ALU
  ALU_operation <= ir1(27 downto 24) when ir1(31 downto 28) = "0011" else
                   x"F";

  ALU1_mux <= '1' when ir1(31 downto 24) = "00010000" else
              '0'; -- 1 indicates read constant, 0 indicates read from register

  --dMem_write
  dMem_write <= '1' when ir2(31 downto 24) = "00100001" else
                '0';

  --vMem_write
  vMem_write <= '1' when ir2(31 downto 24) = "01000001" else
                '0';

  --writeback_mux
  
  --regFile_write
  --regFile_write is 1 when the instruction wants to write to the register file, otherwise 0.
  regFile_write <= DF_mem;
  
  --stall need read_reg to check if inst contain read reg
  stall <= '1' when (mem_access = '1' and read_red_ir0 = '1') and
           (ir1(23 downto 20) = ir0(19 downto 16) or
            ir1(23 downot 20) = ir0(15 dwonto 12)) else
        <= '0';
  --Stall when instruction in ir1 wants to read from memory, instruction in ir0
  --wants to read from register file and the register file that ir1 wants to
  --store to is one of the registers ir0 wants to read from


           
end net;
