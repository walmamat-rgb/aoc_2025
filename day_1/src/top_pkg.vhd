library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package top_pkg is

constant C_ROTATE_MODULO : positive := 100; -- modulo for the dial
constant C_MAX_ROTATE_AMOUNT : positive := 999; -- maximum rotate amount
function clog2 (value : positive) return positive;

end package top_pkg;

package body top_pkg is

function clog2 (value : positive) return positive is
begin
    for i in 0 to 31 loop
        if value <= 2**i then
            return i;
        end if;
    end loop;
    return 32;
end function clog2;

end package body top_pkg;