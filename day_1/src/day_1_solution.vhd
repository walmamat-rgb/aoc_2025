library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_pkg.all;
use work.day_1_solution_pkg.all;

entity day_1_solution is
  generic (
    G_NUM_INPUT_ROTATES     : positive  := 4;   -- array size of the input
    G_MAX_NUM_INPUT_BEATS		: positive  := 16  -- this defines the dimensions of the output
  );
  port (
    clk_i      : in  std_logic;
    rst_i      : in  std_logic;
    valid_i    : in  std_logic;     -- indicates rotate_i is valid
    last_i     : in  std_logic;     -- indicates this is the last rotate in the sequence
    keep_i     : in  std_logic_vector(0 to G_NUM_INPUT_ROTATES - 1); -- indicates which rotates are valid on this beat
    input_i    : in  input_array_t(0 to G_NUM_INPUT_ROTATES - 1);
    output_o   : out integer range 0 to (G_NUM_INPUT_ROTATES*G_MAX_NUM_INPUT_BEATS)-1 -- number of times the dial lands on 0
  );
end entity day_1_solution;

architecture rtl of day_1_solution is

type follow_input_state_t is (WAIT_FOR_START, PROCESSING_INPUT);
signal follow_input_state_r : follow_input_state_t := WAIT_FOR_START;

begin

  -- follow the input state machine
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      case follow_input_state_r is
      when WAIT_FOR_START =>
        if valid_i = '1' then
          -- process input_i and compute output_o
          follow_input_state_r <= PROCESSING_INPUT;
        end if;
      when PROCESSING_INPUT =>
        if last_i = '1' then
          follow_input_state_r <= WAIT_FOR_START;
        end if;
      when others =>
        follow_input_state_r <= WAIT_FOR_START;
      end case;

      if rst_i = '1' then
        follow_input_state_r <= WAIT_FOR_START;
      end if;
    end if;
  end process;

  -- modulo the inputs to be within the dial range

  -- adder tree to sum up all the rotates to figure out where each beat ends at

  -- dial starts on 50
  gen_adder_tree: for input_index in 0 to G_NUM_INPUT_ROTATES - 1 generate
  end generate gen_adder_tree;


end architecture rtl;