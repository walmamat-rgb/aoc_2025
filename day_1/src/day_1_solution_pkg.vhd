library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use top_pkg.all;

package day_1_solution_pkg is

enum direction_t is (E_LEFT, E_RIGHT);

type input_t is record
  rotate_amount : integer range 0 to C_MAX_ROTATE_AMOUNT;
  direction     : direction_t;
end record;

type input_array_t is array (natural range <>) of input_t;

type moduloed_input_t is record
  rotate_amount : integer range 0 to C_ROTATE_MODULO-1;
end record;

type moduloed_input_array_t is array (natural range <>) of moduloed_input_t;


end package top_pkg;

package body top_pkg is


end package body top_pkg;