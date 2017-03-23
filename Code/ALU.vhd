library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--ALU
entity ALU is
  port(op_a,op_b: in signed(15 downto 0);
       op_code: in signed(3 downto 0);  --op_code counts from 0 to 9 in order
                                        --that is written in the enumeration
       res: buffer signed(15 downto 0);
       z,n,o: out std_logic);
end ALU;

architecture calc of ALU is
  type operation is (op_NOT, op_OR, op_AND, op_XOR, op_ADD, op_SUB, op_MUL, op_LSR, op_LSL);

begin

  --Calculations
  with op_code select
    res <=
    (not op_a)          when op_NOT,
    (op_a or op_b)      when op_OR,
    (op_a and op_b)     when op_AND,
    (op_a xor op_b)     when op_XOR,
    (op_a + op_b)       when op_ADD,
    (op_a - op_b)       when op_SUB,
    (op_a * op_b)       when op_MUL,
    (op_a slr op_b)     when op_LSR,
    (op_a sll op_b)     when op_LSL,
    op_a                when others; 



  --Update flags
  z <= '1' when res = 0 else
       '0';

  n <= '1' when res(15) = '1' else
       '0';

  --Overflow when sum of 2 positive is negative or sum of 2 negative is positive
  o <= '1' when (op_code = op_ADD and ((res(15) = '1' and op_a(15) = '0' and op_b(15) = '0') or (res(15) = '0' and op_a(15) = '1' and op_b(15) = '1')) else
       '0';

end calc;
