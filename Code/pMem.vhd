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
x"57000004", --BRB1 GAME_BOOT //Start game at button press
x"00000000", --NOP
x"50000002", --JMP GAME_BOOT
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
x"10400000", --MOV	R4 0
x"10500000", --MOV R5 0
x"50000013", --JMP INNER_LOOP
x"00000000", --NOP
x"10400000", --MOV R4 0 //sets x to 0
x"10F00001", --MOV RF 1
x"3455F000", --ADD R5 R5 RF //y++
x"10F00008", --MOV RF 8
x"6005F000", --CMP R5 RF	//all rooms generated check
x"5200004d", --BRZ LOAD_VM
x"00000000", --NOP
x"5000000a", --JMP INNER_LOOP
x"00000000", --NOP
x"10F00001", --MOV RF 1
x"3444F000", --ADD R4 R4 RF //x++
x"10F00008", --MOV RF 8
x"6004F000", --CMP R4 RF //all rooms in row generated check
x"5200fff3", --BRZ Y_SCREEN
x"00000000", --NOP
x"50000002", --JMP INNER_LOOP
x"00000000", --NOP
x"106003e8", --MOV R6 1000 //START VALUE IS 1000 IN MEM
x"10F008c0", --MOV RF 2240 //NEXT 5 LINES CALCULATES START ADDRESS OF CURRENT ROOM
x"36F5F000", --MUL RF R5 RF
x"3466F000", --ADD R6 R6 RF
x"10F00118", --MOV RF 280
x"36F4F000", --MUL RF R4 RF
x"3466F000", --ADD R6 R6 RF //R6 is now correct address
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
x"10F00014", --MOV RF 20
x"367F0000", --MUL R7 RF R0  //20*y
x"34776000", --ADD R7 R7 R6  //START ADDRESS + 20y
x"34717000", --ADD R7 R1 R7  //START AFFRESS + 20y + x, R7 now contains current address for tile
x"23037000", --STRR R3 R7 //WRITE TO VMEM FROM DMEM
x"10D00001", --MOV RD 1
x"3411D000", --ADD R1 R1 RD
x"10D00014", --MOV RD 20
x"6001D000", --CMP R1 RD //Check if col has reached 20
x"52000004", --BRZ VMEM_FILL_RST_X
x"00000000", --NOP
x"5000ffd4", --JMP VMEM_FILL_LOOP
x"00000000", --NOP
x"10100000", --MOV R1 0 //Reset col
x"10D00001", --MOV RD 1
x"340D0000", --ADD R0 RD R0 //add one to row
x"10D0000e", --MOV RD 14
x"6000D000", --CMP R0 RD //Check if row is 14
x"5200ffbb", --BRZ X_SCREEN
x"00000000", --NOP
x"5000ffcb", --JMP VMEM_FILL_LOOP
x"00000000", --NOP
x"10F00004", --MOV RF 4
x"210F000a", --STR RF 10  //ROOM X = 4
x"210F000b", --STR RF 11  //ROOM Y = 4
x"10202b48", --MOV R2 11080 // START ADDRESS FOR ROOM AT 4,4
x"10000001", --MOV R0 1 //y
x"10100000", --MOV R1 0 //x
x"22320000", --LDAR R3 R2 //Load tile to R3
x"10F00008", --MOV RF 8
x"3840F000", --LSL R4 R0 RF
x"34441000", --ADD R4 R4 R1 //Index for vmem in R4
x"43034000", --STRVR R3 R4 //Write tile to vmem
x"10F00001", --MOV RF 1
x"3411F000", --ADD R1 R1 RF //x++
x"3422F000", --ADD R2 R2 RF //D-mem adress ++
x"10F00014", --MOV RF 20
x"6001F000", --CMP R1 RF //Check if x==20
x"52000004", --BRZ VMEM_MOVE_RST_X
x"00000000", --NOP
x"5000fff4", --JMP VMEM_MOVE_LOOP
x"00000000", --NOP
x"10F02c60", --MOV RF 11360 //End of screen in Dmem
x"6002F000", --CMP R2 RF
x"52000007", --BRZ PLACE_PLAYER //Done with moving data to dmem
x"00000000", --NOP
x"10F00001", --MOV RF 1
x"3400F000", --ADD R0 R0 RF //y++
x"10100000", --MOV R1 0 //x = 0
x"5000ffeb", --JMP VMEM_MOVE_LOOP
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
x"50000002", --JMP MAIN_LOOP
x"00000000", --NOP
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
x"10E00014", --MOV RE 20 //Check if too far right
x"600E7000", --CMP RE R7
x"52000086", --BRZ NEXT_SCREEN
x"00000000", --NOP
x"10E0ffff", --MOV RE -1 //Check too far left
x"600E7000", --CMP RE R7
x"52000082", --BRZ NEXT_SCREEN
x"00000000", --NOP
x"10E00000", --MOV RE 0 //Check too far up
x"600E8000", --CMP RE R8
x"5200007e", --BRZ NEXT_SCREEN
x"00000000", --NOP
x"10E0000f", --MOV RE 15 //Check too far down
x"600E8000", --CMP RE R8
x"5200007a", --BRZ NEXT_SCREEN
x"00000000", --NOP
x"50000002", --JMP NO_BORDER_WRAP
x"00000000", --NOP
x"10F00008", --MOV RF 8 //No out of bounds, check if can drill/move
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
x"50000028", --JMP UPDATE_SCORE
x"00000000", --NOP
x"10F00008", --MOV RF 8
x"3832F000", --LSL R3 R2 RF //Shift up y
x"34331000", --ADD R3 R3 R1 //Vmem pos in R3
x"10F0000B", --MOV RF x0B //Start for player tiles
x"34F0F000", --ADD RF R0 RF
x"430F3000", --STRVR RF R3 //Write over new tile
x"5000ff8f", --JMP MAIN_LOOP
x"00000000", --NOP
x"10F00000", --MOV RF 0
x"6009F000", --CMP R9 RF //Check if ground
x"5200ffea", --BRZ CONT_MOVE
x"00000000", --NOP
x"70000000", --BEEP //Make sound
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
x"5200ffdd", --BRZ CONT_MOVE //go back if max drill level
x"00000000", --NOP
x"10E0000a", --MOV RE 10
x"36DDE000", --MUL RD RD RE
x"600DF000", --CMP RD RF
x"51000004", --BRN ADD_LEVEL
x"00000000", --NOP
x"5000ffd6", --JMP CONT_MOVE
x"00000000", --NOP
x"20E00003", --LDA RE 3
x"10F00001", --MOV RF 1
x"34EEF000", --ADD RE RE RF
x"210E0003", --STR RE 3
x"5000ffd0", --JMP CONT_MOVE
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
x"5000ff5f", --JMP MAIN_LOOP
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
x"20E0000a", --LDA RE 10 //old x
x"34EE4000", --ADD RE RE R4
x"10F00007", --MOV RF x0007
x"32EEF000", --AND RE RE RF //mod 8
x"210E000c", --STR RE 12 //Store new x
x"20E0000b", --LDA RE 11 //old y
x"34EE5000", --ADD RE RE R5
x"10F00007", --MOV RF x0007
x"32EEF000", --AND RE RE RF
x"210E000d", --STR RE 13 //Store new y
x"10E00000", --MOV RE 0
x"6004E000", --CMP R4 RE
x"52000006", --BRZ Y_BORDER_WRAP //No X-movement
x"00000000", --NOP
x"5100000b", --BRN X_WRAP_LEFT // delta X < 0
x"00000000", --NOP
x"5000007e", --JMP X_WRAP_RIGHT // delta X > 0
x"00000000", --NOP
x"6005E000", --CMP R5 RE
x"5200ff77", --BRZ NO_BORDER_WRAP //No Y-movement
x"00000000", --NOP
x"51000097", --BRN Y_WRAP_UP  // delta Y < 0
x"00000000", --NOP
x"500000af", --JMP Y_WRAP_DOWN // delta Y > 0
x"00000000", --NOP
x"10A003e8", --MOV RA 1000		// Calculate what tile is where we try to move on new screen all according to formula
x"20E0000c", --LDA RE 12  		 // X coord for room
x"20D0000d", --LDA RD 13 		 // Y coord for room
x"10C00008", --MOV RC 8
x"36DDC000", --MUL RD RD RC 	 // Y * 8
x"34EED000", --ADD RE RE RD 	 // X + Y*8
x"10C00118", --MOV RC 280
x"36EEC000", --MUL RE RE RC 	 // 280(X + Y*8)
x"34AAE000", --ADD RA RA RE 	 // 1000 + 280(X + Y *8) , start adress for tiles in new room
x"10E00000", --MOV RE 0
x"349AE000", --ADD R9 RA RE	//SAVE STARTADRESS FOR NEW ROOM FOR LATER
x"10E00014", --MOV RE 20		 //Calculate tile adress in room according to formula of tile we want to move to
x"10D00001", --MOV RD 1		 //Top row is not in the dMem, need to adjust for that
x"35D2D000", --SUB RD R2 RD
x"36EED000", --MUL RE RE RD         //20*Y
x"10D00013", --MOV RD 19 	       	 //When wrapping left, new X is 19
x"34EED000", --ADD RE RE RD         //20*Y + X
x"34BAE000", --ADD RB RA RE       	 //Room_adress + 20*Y + X = Tile_adress
x"22AB0000", --LDAR RA RB		 //New tile in RF
x"20E00003", --LDA RE 3  		 //Drill level
x"10D0000F", --MOV RD x0F		 //Start adress for breakable rocks
x"34EED000", --ADD RE RE RD	 //Highest tile that can be broken
x"600EA000", --CMP RE RA 		 //Can i breakz?
x"5100ff72", --BRN TURN 		 //NO BREAK ROCK CANCEL
x"00000000", --NOP
x"10500013", --MOV R5 19		//UPDATE PLAYER X, Y IS SAME
x"10600000", --MOV R6 0
x"34662000", --ADD R6 R6 R2
x"50000002", --JMP CHANGE_SCREEN
x"00000000", --NOP
x"10E00000", --MOV RE 0 //Before that calculate the new score
x"35AAD000", --SUB RA RA RD
x"600AE000", --CMP RA RE //Check if ground
x"52000017", --BRZ CONT_CHANGE_SCREEN
x"00000000", --NOP
x"70000000", --BEEP //Make sound
x"10E00001", --MOV RE 1
x"35AAE000", --SUB RA RA RE
x"20D00004", --LDA RD 4 //Load score to RD
x"38EEA000", --LSL RE RE RA
x"34DDE000", --ADD RD RD RE //New score in RD
x"210D0004", --STR RD 4
x"10E00004", --MOV RE 4
x"20A00003", --LDA RA 3 //Drill level in RF
x"600EA000", --CMP RE RA
x"5200000b", --BRZ CONT_CHANGE_SCREEN //go back if max drill level
x"00000000", --NOP
x"10E0000a", --MOV RE 10
x"36AAE000", --MUL RA RA RE
x"600DA000", --CMP RD RA
x"51000006", --BRN CONT_CHANGE_SCREEN //Not enough score to level up
x"00000000", --NOP
x"20E00003", --LDA RE 3 //Level up the drill
x"10A00001", --MOV RA 1
x"34EEA000", --ADD RE RE RA
x"210E0003", --STR RE 3
x"10E00008", --MOV RE 8
x"3822E000", --LSL R2 R2 RE
x"34221000", --ADD R2 R2 R1 //CURRENT ADRESS FOR PLAYER IN VMEM
x"10D0000F", --MOV RD x0F
x"430D2000", --STRVR RD R2 //OVERWRITE PLAYAH WITH GROUND BEFORE STORING/LOADING FROM MEMORY
x"21050000", --STR R5 0 	//Store new player X
x"21060001", --STR R6 1	//Store new player Y
x"2040000b", --LDA R4 11	//Current room Y
x"2030000a", --LDA R3 10	//Current room X
x"3644E000", --MUL R4 R4 RE	  //Calc start adress for current room in dMem
x"34443000", --ADD R4 R4 R3
x"10300118", --MOV R3 280
x"36443000", --MUL R4 R4 R3
x"103003e8", --MOV R3 1000
x"34443000", --ADD R4 R4 R3 //It is in R4
x"10C00008", --MOV RC 8	//For shifting 8 bits
x"10A00000", --MOV RA 0	   //Loop X
x"10E00000", --MOV RE 0	   //Loop Y
x"10D00001", --MOV RD 1	   //For inc/dec 1
x"10000014", --MOV R0 20
x"361E0000", --MUL R1 RE R0
x"3411A000", --ADD R1 R1 RA	//OFFSETT FOR CURRENT TILE IN THE ROOM IN R1
x"34314000", --ADD R3 R1 R4	//ADRESS TO STORE TILE X Y IN DMEM IN R3
x"342ED000", --ADD R2 RE RD
x"3822C000", --LSL R2 R2 RC
x"342A2000", --ADD R2 RA R2	//ADRESS TO CURRENT TILE IN VMEM IN R2
x"42520000", --LDAVR R5 R2		//Current tile in R5
x"23053000", --STRR R5 R3		//STR CURRENT TILE IN dMEM
x"34F91000", --ADD RF R9 R1 	//RF adress of tile to load from new room
x"225F0000", --LDAR R5 RF		//R5 IS TILE THAT IS NEWLY LOADED
x"43052000", --STRVR R5 R2
x"10000013", --MOV R0 19
x"600A0000", --CMP RA R0
x"5100000a", --BRN SCREEN_INC_X
x"00000000", --NOP
x"10A00000", --MOV RA 0 //x is 19
x"1000000d", --MOV R0 13
x"600E0000", --CMP RE R0
x"52000008", --BRZ SCREEN_PLACE_PLAYER //All rows are changed
x"00000000", --NOP
x"34EED000", --ADD RE RE RD
x"5000ffea", --JMP CHANGE_SCREEN_LOOP
x"00000000", --NOP
x"34AAD000", --ADD RA RA RD
x"5000ffe7", --JMP CHANGE_SCREEN_LOOP
x"00000000", --NOP
x"20000000", --LDA R0 0	//PLAYER X
x"20100001", --LDA R1 1	//PLAYER Y
x"10200008", --MOV R2 8
x"38112000", --LSL R1 R1 R2
x"34110000", --ADD R1 R1 R0
x"20300002", --LDA R3 2	//PLAYER DIRECTION
x"1040000B", --MOV R4 x0B
x"34334000", --ADD R3 R3 R4
x"43031000", --STRVR R3 R1
x"20E0000c", --LDA RE 12 //Copy over new screen x and y
x"210E000a", --STR RE 10
x"20E0000d", --LDA RE 13
x"210E000b", --STR RE 11
x"5000ff3c", --JMP UPDATE_SCORE
x"00000000", --NOP
x"10A003e8", --MOV RA 1000		// Calculate what tile is where we try to move on new screen all according to formula
x"20E0000c", --LDA RE 12  		 // X coord for room
x"20D0000d", --LDA RD 13 		 // Y coord for room
x"10C00008", --MOV RC 8
x"36DDC000", --MUL RD RD RC 	 // Y * 8
x"34EED000", --ADD RE RE RD 	 // X + Y*8
x"10C00118", --MOV RC 280
x"36EEC000", --MUL RE RE RC 	 // 280(X + Y*8)
x"34AAE000", --ADD RA RA RE 	 // 1000 + 280(X + Y *8) , start adress forTiles in new room
x"10E00000", --MOV RE 0
x"349AE000", --ADD R9 RA RE	//SAVE STARTADRESS FOR NEW ROOM FOR LATER
x"10E00014", --MOV RE 20		 //Calculate tile adress in room according to formula of tile we want to move to
x"10D00001", --MOV RD 1		 //Top row is not in the dMem, need to adjust for that
x"35D2D000", --SUB RD R2 RD
x"36EED000", --MUL RE RE RD         //20*Y
x"10D00000", --MOV RD 0 	       	 //When wrapping RIGHT, new X is 19
x"34EED000", --ADD RE RE RD         //20*Y + X
x"34BAE000", --ADD RB RA RE       	 //Room_adress + 20*Y + X = Tile_adress
x"22AB0000", --LDAR RA RB		 //New tile in RA
x"20E00003", --LDA RE 3  		 //Drill level
x"10D0000F", --MOV RD x0F		 //Start adress for breakable rocks
x"34EED000", --ADD RE RE RD	 //Highest tile that can be broken
x"600EA000", --CMP RE RA 		 //Can i breakz?
x"5100fefd", --BRN TURN 		 //NO BREAK ROCK CANCEL
x"00000000", --NOP
x"10500000", --MOV R5 0		//UPDATE PLAYER X, Y IS SAME
x"10600000", --MOV R6 0
x"34662000", --ADD R6 R6 R2
x"5000ff8d", --JMP CHANGE_SCREEN
x"00000000", --NOP
x"10A003e8", --MOV RA 1000		// Calculate what tile is where we try to move on new screen all according to formula
x"20E0000c", --LDA RE 12  		 // X coord for room
x"20D0000d", --LDA RD 13 		 // Y coord for room
x"10C00008", --MOV RC 8
x"36DDC000", --MUL RD RD RC 	 // Y * 8
x"34EED000", --ADD RE RE RD 	 // X + Y*8
x"10C00118", --MOV RC 280
x"36EEC000", --MUL RE RE RC 	 // 280(X + Y*8)
x"34AAE000", --ADD RA RA RE 	 // 1000 + 280(X + Y *8) , start adress for tiles in new room
x"10E00000", --MOV RE 0
x"349AE000", --ADD R9 RA RE	//SAVE STARTADRESS FOR NEW ROOM FOR LATER
x"10E00104", --MOV RE 260		 //Calculate tile adress in room according to formula of tile we want to move to when wrapping up new Y is 13 and 20 * Y is 260
x"34EE1000", --ADD RE RE R1         //20*Y + X
x"34BAE000", --ADD RB RA RE       	 //Room_adress + 20*Y + X = Tile_adress
x"22AB0000", --LDAR RA RB		 //New tile in RA
x"20E00003", --LDA RE 3  		 //Drill level
x"10D0000F", --MOV RD x0F		 //Start adress for breakable rocks
x"34EED000", --ADD RE RE RD	 //Highest tile that can be broken
x"600EA000", --CMP RE RA 		 //Can i breakz?
x"5100fee3", --BRN TURN 		 //NO BREAK ROCK CANCEL
x"00000000", --NOP
x"1060000e", --MOV R6 14		//UPDATE PLAYER Y, X IS SAME
x"10500000", --MOV R5 0
x"34551000", --ADD R5 R5 R1
x"5000ff73", --JMP CHANGE_SCREEN
x"00000000", --NOP
x"10A003e8", --MOV RA 1000		// Calculate what tile is where we try to move on new screen all according to formula
x"20E0000c", --LDA RE 12  		 // X coord for room
x"20D0000d", --LDA RD 13 		 // Y coord for room
x"10C00008", --MOV RC 8
x"36DDC000", --MUL RD RD RC 	 // Y * 8
x"34EED000", --ADD RE RE RD 	 // X + Y*8
x"10C00118", --MOV RC 280
x"36EEC000", --MUL RE RE RC 	 // 280(X + Y*8)
x"34AAE000", --ADD RA RA RE 	 // 1000 + 280(X + Y *8) , start adress for tiles in new room
x"10E00000", --MOV RE 0
x"349AE000", --ADD R9 RA RE	//SAVE STARTADRESS FOR NEW ROOM FOR LATER
x"10E00000", --MOV RE 0 	       	 //When wrapping DOWN, new Y is 0 and 20*Y = 0	 //Calculate tile adress in room according to formula of tile we want to move to
x"34EE1000", --ADD RE RE R1         //20*Y + X
x"34BAE000", --ADD RB RA RE       	 //Room_adress + 20*Y + X = Tile_adress
x"22AB0000", --LDAR RA RB		 //New tile in RA
x"20E00003", --LDA RE 3  		 //Drill level
x"10D0000F", --MOV RD x0F		 //Start adress for breakable rocks
x"34EED000", --ADD RE RE RD	 //Highest tile that can be broken
x"600EA000", --CMP RE RA 		 //Can i breakz?
x"5100fec9", --BRN TURN 		 //NO BREAK ROCK CANCEL
x"00000000", --NOP
x"10600001", --MOV R6 1		//UPDATE PLAYER Y, X IS SAME
x"10500000", --MOV R5 0
x"34551000", --ADD R5 R5 R1
x"5000ff59", --JMP CHANGE_SCREEN
x"00000000", --NOP
others=>(others=>'0')
);

begin  -- pMem
pData <= p_mem(to_integer(pAddr));

end Behavioral;
