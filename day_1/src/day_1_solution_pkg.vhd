library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_pkg.all;

package day_1_solution_pkg is

type direction_t is (E_LEFT, E_RIGHT);

type input_t is record
  rotate_amount : integer range 0 to C_MAX_ROTATE_AMOUNT;
  direction     : direction_t;
end record;

type input_array_t is array (natural range <>) of input_t;

type moduloed_input_t is record
  rotate_amount : integer range 0 to C_ROTATE_MODULO-1;
end record;

type moduloed_input_array_t is array (natural range <>) of moduloed_input_t;

function func_mod (a : integer; b : integer) return integer;

end package day_1_solution_pkg;

package body day_1_solution_pkg is

  -- mod 5
  -- 0+0=0
  -- 0+1=1
  -- 0+2=2
  -- 0+3=3
  -- 0+4=4
  -- 1+1=2
  -- 1+2=3
  -- 1+3=4
  -- 1+4=0
  -- 2+2=4
  -- 2+3=0
  -- 2+4=1
  -- 3+3=1
  -- 3+4=2
  -- 4+4=3
  function func_mod (a : integer; b : integer) return integer is
  variable sum1_v   : integer range 0 to 2*(C_ROTATE_MODULO-1);
  variable sum2_v   : integer range -C_ROTATE_MODULO to C_ROTATE_MODULO-2;
  variable result_v : integer range 0 to C_ROTATE_MODULO-1; 
  begin
    sum1_v := a + b;
    sum2_v := sum1_v-C_ROTATE_MODULO;
    if sum2_v >= 0 then -- easier to compare the sign bit
      result_v := sum2_v;
    else
      result_v := sum1_v; 
    end if;

    return result_v;
  end function func_mod;


end package body day_1_solution_pkg;