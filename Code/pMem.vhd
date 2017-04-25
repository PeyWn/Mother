library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- pMem interface
entity pMem is
  port(
    pAddr : in unsigned(9 downto 0);
    pData : out unsigned(31 downto 0));
end pMem;

architecture Behavioral of pMem is

-- program Memory
type p_mem_t is array (0 to 1023) of unsigned(31 downto 0);
  signal p_mem : p_mem_t := (
x"00000000", --NOP
x"57000004", --BRB1 GAME_BOOT //Start game at button press
x"00000000", --NOP
x"5000fffd", --JMP PROGRAM_START
x"00000000", --NOP
x"1000000a", --MOV R0 10 //Set player default coordinates
x"10100008", --MOV R1 8
x"21000000", --STR R0 0 //X
x"21010001", --STR R1 1 //Y
x"10000000", --MOV R0 0 //Row
x"10100000", --MOV R1 0 //Col
x"10E000FF", --MOV RE x00FF //For masking
x"11200000", --LFSR R2 //Move random number to R2
x"3222E000", --AND R2 R2 RE //Only keep one byte of R2
x"10F0007d", --MOV RF 125 //Start comparing for which tile to place
x"6002F000", --CMP R2 RF
x"51000011", --BRN VMEM_FILL_STONE
x"00000000", --NOP
x"10F000a3", --MOV RF 163 //These numbers are carefully choosen
x"6002F000", --CMP R2 RF
x"51000010", --BRN VMEM_FILL_SILVER
x"00000000", --NOP
x"10F000bd", --MOV RF 189
x"6002F000", --CMP R2 RF
x"5100000f", --BRN VMEM_FILL_GOLD
x"00000000", --NOP
x"10F000ca", --MOV RF 202
x"6002F000", --CMP R2 RF
x"5100000e", --BRN VMEM_FILL_RUBY
x"00000000", --NOP
x"1030000F", --MOV R3 x0F //Stone Tile address
x"5000000e", --JMP VMEM_FILL_END_LOOP
x"00000000", --NOP
x"10300010", --MOV R3 x10 //Tile address
x"5000000b", --JMP VMEM_FILL_END_LOOP
x"00000000", --NOP
x"10300011", --MOV R3 x11 //Tile address
x"50000008", --JMP VMEM_FILL_END_LOOP
x"00000000", --NOP
x"10300012", --MOV R3 x12 //Tile address
x"50000005", --JMP VMEM_FILL_END_LOOP
x"00000000", --NOP
x"10300013", --MOV R3 x13 //Tile address
x"50000002", --JMP VMEM_FILL_END_LOOP
x"00000000", --NOP
x"10D00008", --MOV RD 8
x"3840D000", --LSL R4 R0 RD
x"34441000", --ADD R4 R4 R1 //R4 contains indexing for vmem
x"43034000", --STRVR R3 R4 //Write tile address
x"10D00001", --MOV RD 1
x"3411D000", --ADD R1 R1 RD
x"10D00015", --MOV RD 21
x"6001D000", --CMP R1 RD //Check if col has reached 21
x"52000004", --BRZ VMEM_FILL_RST_X
x"00000000", --NOP
x"5000ffd5", --JMP VMEM_FILL_LOOP
x"00000000", --NOP
x"10100000", --MOV R1 0 //Reset col
x"10D00001", --MOV RD 1
x"340D0000", --ADD R0 RD R0 //add one to row
x"10D00011", --MOV RD 17
x"6000D000", --CMP R0 RD //Check if row is 17
x"52000004", --BRZ PLACE_PLAYER
x"00000000", --NOP
x"5000ffcc", --JMP VMEM_FILL_LOOP
x"00000000", --NOP
x"1000000D", --MOV R0 x0D //Player down tile
x"4100070A", --STRV R0 x070A
x"10000007", --MOV R0 x7
x"21000001", --STR R0 1 // y-pos
x"1000000A", --MOV R0 xA
x"21000000", --STR R0 0 //x-pos
x"10000001", --MOV R0 1
x"21000003", --STR R0 3 //Drill level
x"10F00000", --MOV RF 0
x"5900000e", --BRJU JOY_UP
x"00000000", --NOP
x"210F0066", --STR RF 102
x"5A000016", --BRJD JOY_DOWN
x"00000000", --NOP
x"210F0067", --STR RF 103
x"5B00001e", --BRJR JOY_RIGHT
x"00000000", --NOP
x"210F0069", --STR RF 105
x"5C000026", --BRJL JOY_LEFT
x"00000000", --NOP
x"210F0068", --STR RF 104
x"5000fff3", --JMP MAIN_LOOP //Restart loop
x"00000000", --NOP
x"10F00001", --MOV RF 1
x"20000066", --LDA R0 102
x"600F0000", --CMP RF R0
x"5200ffee", --BRZ MAIN_LOOP
x"00000000", --NOP
x"210F0066", --STR RF 102
x"10000003", --MOV R0 3
x"10400000", --MOV R4 0
x"1050ffff", --MOV R5 -1
x"50000023", --JMP MOVE
x"00000000", --NOP
x"10F00001", --MOV RF 1
x"20000067", --LDA R0 103
x"600F0000", --CMP RF R0
x"5200ffe3", --BRZ MAIN_LOOP
x"00000000", --NOP
x"210F0067", --STR RF 103
x"10000002", --MOV R0 2
x"10400000", --MOV R4 0
x"10500001", --MOV R5 1
x"50000018", --JMP MOVE
x"00000000", --NOP
x"10F00001", --MOV RF 1
x"20000069", --LDA R0 105
x"600F0000", --CMP RF R0
x"5200ffd8", --BRZ MAIN_LOOP
x"00000000", --NOP
x"210F0069", --STR RF 105
x"10000001", --MOV R0 1
x"10400001", --MOV R4 1
x"10500000", --MOV R5 0
x"5000000d", --JMP MOVE
x"00000000", --NOP
x"10F00001", --MOV RF 1
x"20000068", --LDA R0 104
x"600F0000", --CMP RF R0
x"5200ffcd", --BRZ MAIN_LOOP
x"00000000", --NOP
x"210F0068", --STR RF 104
x"10000000", --MOV R0 0
x"1040ffff", --MOV R4 -1
x"10500000", --MOV R5 0
x"50000002", --JMP MOVE
x"00000000", --NOP
x"21000002", --STR R0 2
x"20100000", --LDA R1 0 //X pos
x"20200001", --LDA R2 1 //Y pos
x"20600003", --LDA R6 3 //Drill level
x"34714000", --ADD R7 R1 R4 //New x-pos
x"34825000", --ADD R8 R2 R5 //New y-pos
x"10F00008", --MOV RF 8
x"38B8F000", --LSL RB R8 RF //Shift new y
x"34BB7000", --ADD RB RB R7 //Vmem new pos in RB
x"429B0000", --LDAVR R9 RB //Tile where player tries to move in R9
x"20A00003", --LDA RA 3 //Drill level in RA
x"10F0000F", --MOV RF x0F
x"3599F000", --SUB R9 R9 RF
x"600A9000", --CMP RA R9
x"5100000e", --BRN TURN
x"00000000", --NOP
x"10F00008", --MOV RF 8
x"3832F000", --LSL R3 R2 RF //Shift old y
x"34331000", --ADD R3 R3 R1 //Vmem old pos in R3
x"10F0000F", --MOV RF x0F
x"430F3000", --STRVR RF R3 //Write over old tile
x"21070000", --STR R7 0
x"21080001", --STR R8 1
x"10F0000B", --MOV RF x0B //Start for player sprites
x"34F0F000", --ADD RF R0 RF
x"430FB000", --STRVR RF RB //Write over new tile
x"5000ffab", --JMP MAIN_LOOP
x"00000000", --NOP
x"10F00008", --MOV RF 8
x"3832F000", --LSL R3 R2 RF //Shift up y
x"34331000", --ADD R3 R3 R1 //Vmem pos in R3
x"10F0000B", --MOV RF x0B //Start for player tiles
x"34F0F000", --ADD RF R0 RF
x"430F3000", --STRVR RF R3 //Write over new tile
x"5000ffa3", --JMP MAIN_LOOP
x"00000000", --NOP
others=>(others=>'0')
);

begin  -- pMem
pData <= p_mem(to_integer(pAddr));

end Behavioral;
