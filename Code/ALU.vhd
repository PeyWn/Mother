library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--ALU
entity ALU is
  port(op_a,op_b: in unsigned(15 downto 0);
       op_code: in unsigned(3 downto 0);  --op_code counts from 0 to 9 in order
                                          --The op_code hex F is reserved for no operation, op_a just bleeds through
       res: buffer unsigned(15 downto 0);
       z,n,o: out std_logic);
end ALU;

architecture calc of ALU is
  signal op_a_signed, op_b_signed, res_signed : signed(15 downto 0);

  signal mult_32 : signed(31 downto 0);
begin

  --Calculations
  op_a_signed <= signed(std_logic_vector(op_a));
  op_b_signed <= signed(std_logic_vector(op_b));
  res <= unsigned(std_logic_vector(res_signed));

  mult_32 <= (op_a_signed * op_b_signed);
  
  with op_code select
    res_signed <=
    (not op_a_signed)                                   when x"0",        --NOT
    (op_a_signed or op_b_signed)                        when x"1",        --OR
    (op_a_signed and op_b_signed)                       when x"2",        --AND
    (op_a_signed xor op_b_signed)                       when x"3",        --XOR
    (op_a_signed + op_b_signed)                         when x"4",        --ADD
    (op_a_signed - op_b_signed)                         when x"5",        --SUB
    mult_32(15 downto 0)                                 when x"6",        --MUL
    (op_a_signed srl to_integer(op_b_signed))           when x"7",        --LSR
    (op_a_signed sll to_integer(op_b_signed))           when x"8",        --LSL
    op_b_signed                                         when x"9",        --Pass B through
    op_a_signed                                         when others; 



  --Update flags
  z <= '1' when res = 0 else
       '0';

  n <= '1' when res(15) = '1' else
       '0';

  --Overflow when sum of 2 positive is negative or sum of 2 negative is positive
  o <= '1' when (op_code = x"4" and ((res_signed(15) = '1' and op_a_signed(15) = '0' and op_b_signed(15) = '0') or (res_signed(15) = '0' and op_a_signed(15) = '1' and op_b_signed(15) = '1'))) else
       '0';
end calc;
