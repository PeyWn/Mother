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
x"10100000", --MOV R1 0 //X-index
x"10F00000", --MOV RF 0
x"430F1000", --STRVR RF R1
x"10F00001", --MOV RF 1
x"3411F000", --ADD R1 R1 RF
x"10F00014", --MOV RF 20
x"6001F000", --CMP R1 RF
x"52000004", --BRZ TOP_ROW_DONE
x"00000000", --NOP
x"5000fff8", --JMP TOP_ROW_LOOP
x"00000000", --NOP
x"10F00001", --MOV RF 1 //Number 0 tile
x"10100013", --MOV R1 x0013 // left on top row
x"430F1000", --STRVR RF R1 //Score 0
x"10100012", --MOV R1 x0012
x"430F1000", --STRVR RF R1 //Score 0
x"10100011", --MOV R1 x0011
x"430F1000", --STRVR RF R1 //Score 0
x"10100010", --MOV R1 x0010
x"430F1000", --STRVR RF R1 //Score 0
x"10F00015", --MOV RF x15 //Peng symbol
x"1010000F", --MOV R1 x000F //Where money symbol should be
x"430F1000", --STRVR RF R1 //Put money symbol
x"10F00014", --MOV RF x14	//Drill symbol
x"1010000C", --MOV R1 xC  	//screen addres for symbol
x"430F1000", --STRVR RF R1	//Put drill icon
x"10F00002", --MOV RF x2	//1 symbol
x"1010000D", --MOV R1 xD  	//screen addres for symbol
x"430F1000", --STRVR RF R1	//Put 1 icon
x"10000001", --MOV R0 1 //Row
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
x"10000000", --MOV R0 0
x"21000004", --STR R0 4 //Score
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
x"51000010", --BRN TURN
x"00000000", --NOP
x"50000016", --JMP AWARD_SCORE
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
x"50000027", --JMP UPDATE_SCORE
x"00000000", --NOP
x"10F00008", --MOV RF 8
x"3832F000", --LSL R3 R2 RF //Shift up y
x"34331000", --ADD R3 R3 R1 //Vmem pos in R3
x"10F0000B", --MOV RF x0B //Start for player tiles
x"34F0F000", --ADD RF R0 RF
x"430F3000", --STRVR RF R3 //Write over new tile
x"5000ffa1", --JMP MAIN_LOOP
x"00000000", --NOP
x"10F00000", --MOV RF 0
x"6009F000", --CMP R9 RF //Check if ground
x"5200ffea", --BRZ CONT_MOVE
x"00000000", --NOP
x"10F00001", --MOV RF 1
x"3599F000", --SUB R9 R9 RF
x"20F00004", --LDA RF 4 //Load score to RF
x"10E00001", --MOV RE 1
x"38EE9000", --LSL RE RE R9
x"34FFE000", --ADD RF RF RE //New score in RF
x"210F0004", --STR RF 4
x"10E00004", --MOV RE 4
x"20D00003", --LDA RD 3 //Drill level in RD
x"600ED000", --CMP RE RD
x"5200ffde", --BRZ CONT_MOVE //go back if max drill level
x"00000000", --NOP
x"10E0000a", --MOV RE 10
x"36DDE000", --MUL RD RD RE
x"600DF000", --CMP RD RF
x"51000004", --BRN ADD_LEVEL
x"00000000", --NOP
x"5000ffd7", --JMP CONT_MOVE
x"00000000", --NOP
x"20E00003", --LDA RE 3
x"10F00001", --MOV RF 1
x"34EEF000", --ADD RE RE RF
x"210E0003", --STR RE 3
x"5000ffd1", --JMP CONT_MOVE
x"00000000", --NOP
x"20000004", --LDA R0 4 //Score to R0
x"50000011", --JMP GET_BCD
x"00000000", --NOP
x"10F00001", --MOV RF 1
x"3433F000", --ADD R3 R3 RF //Add one to get to correct number tile
x"3444F000", --ADD R4 R4 RF
x"3455F000", --ADD R5 R5 RF
x"3466F000", --ADD R6 R6 RF
x"41030010", --STRV R3 X10
x"41040011", --STRV R4 X11
x"41050012", --STRV R5 X12
x"41060013", --STRV R6 X13
x"20F00003", --LDA RF 3 // LOAD DRILL LVL
x"10E00001", --MOV RE 1
x"34FFE000", --ADD RF RF RE //RF IS NOW TILE ADDERSS
x"410F000D", --STRV RF XD // Put drill lvl on D tile
x"5000ff72", --JMP MAIN_LOOP
x"00000000", --NOP
x"10300000", --MOV R3 0 //Dest for 1000
x"10400000", --MOV R4 0 //Dest for 100
x"10500000", --MOV R5 0 //Dest for 10
x"10600000", --MOV R6 0 //Dest for 1
x"10F00001", --MOV RF 1
x"10100000", --MOV R1 0 //Loop counter
x"102003e8", --MOV R2 1000
x"60002000", --CMP R0 R2
x"51000006", --BRN HUNDRED
x"00000000", --NOP
x"35002000", --SUB R0 R0 R2
x"3411F000", --ADD R1 R1 RF
x"5000fffb", --JMP THOUSAND_LOOP
x"00000000", --NOP
x"34331000", --ADD R3 R3 R1
x"10100000", --MOV R1 0 //Loop counter
x"10200064", --MOV R2 100
x"60002000", --CMP R0 R2
x"51000006", --BRN TEN
x"00000000", --NOP
x"35002000", --SUB R0 R0 R2
x"3411F000", --ADD R1 R1 RF
x"5000fffb", --JMP HUNDRED_LOOP
x"00000000", --NOP
x"34441000", --ADD R4 R4 R1
x"10100000", --MOV R1 0 //Loop counter
x"1020000a", --MOV R2 10
x"60002000", --CMP R0 R2
x"51000006", --BRN ONE
x"00000000", --NOP
x"35002000", --SUB R0 R0 R2
x"3411F000", --ADD R1 R1 RF
x"5000fffb", --JMP TEN_LOOP
x"00000000", --NOP
x"34551000", --ADD R5 R5 R1
x"34660000", --ADD R6 R6 R0
x"5000ffcd", --JMP BCD_RETURN
x"00000000", --NOP
others=>(others=>'0')
);

begin  -- pMem
pData <= p_mem(to_integer(pAddr));

end Behavioral;
