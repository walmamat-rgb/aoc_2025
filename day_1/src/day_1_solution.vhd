library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_pkg.all;
use work.day_1_solution_pkg.all;

entity day_1_solution is
  generic (
    G_NUM_INPUT_ROTATES          : positive  := 4;   -- array size of the input
    G_MAX_NUM_INPUT_BEATS		     : positive  := 16;  -- this defines the dimensions of the output
    G_STARTING_DIAL_POSITION     : integer range 0 to C_ROTATE_MODULO-1 := 0;  -- starting position of the dial
    G_REGISTER_STAGES_COUNT_ZERO : std_logic_vector := X"0000000000000000";  -- which stages to register
    G_REGISTER_STAGES_MODULO     : std_logic_vector := X"0000000000000000";
    G_REGISTER_STAGES_ADDER      : std_logic_vector := X"0000000000000000"
  );
  port (
    clk_i                   : in  std_logic;
    rst_i                   : in  std_logic;
    valid_i                 : in  std_logic;     -- indicates rotate_i is valid
    last_i                  : in  std_logic;     -- indicates this is the last rotate in the sequence
    keep_i                  : in  std_logic_vector(0 to G_NUM_INPUT_ROTATES - 1); -- indicates which rotates are valid on this beat
    rotate_i                : in  input_array_t(0 to G_NUM_INPUT_ROTATES - 1);
    num_zero_counts_o       : out integer range 0 to (G_NUM_INPUT_ROTATES*G_MAX_NUM_INPUT_BEATS)-1; -- number of times the dial lands on 0
    num_zero_counts_valid_o : out std_logic
  );
end entity day_1_solution;

architecture rtl of day_1_solution is

type follow_input_state_t is (WAIT_FOR_START, PROCESSING_INPUT);
signal follow_input_state_r : follow_input_state_t := WAIT_FOR_START;

signal moduloed_valid_x    : std_logic;     -- indicates rotate_i is valid
signal moduloed_last_x     : std_logic;     -- indicates this is the last rotate in the sequence
signal moduloed_keep_x     : std_logic_vector(0 to G_NUM_INPUT_ROTATES - 1); -- indicates which rotates are valid on this beat
signal moduloed_rotate_x   : moduloed_input_array_t(0 to G_NUM_INPUT_ROTATES - 1);

signal adder_valid_x      : std_logic;     -- indicates rotate_i is valid
signal adder_last_x       : std_logic;     -- indicates this is the last rotate in the sequence
signal adder_keep_x       : std_logic_vector(0 to G_NUM_INPUT_ROTATES - 1); -- indicates which rotates are valid on this beat
signal adder_rotate_x     : moduloed_input_array_t(0 to G_NUM_INPUT_ROTATES - 1);
signal adder_added_x      : integer range 0 to C_ROTATE_MODULO-1;              -- the result of each beat added

signal dial_position_r : integer range 0 to C_ROTATE_MODULO-1 := 0;

signal num_zero_counts_x       : integer range 0 to (G_NUM_INPUT_ROTATES*G_MAX_NUM_INPUT_BEATS)-1;
signal num_zero_counts_valid_x : std_logic;

begin

  day_1_solution_modulo_input_inst : entity work.day_1_solution_modulo_input
  generic map (
    G_NUM_INPUT_ROTATES => G_NUM_INPUT_ROTATES,
    G_REGISTER_STAGES   => G_REGISTER_STAGES_MODULO
  )
  port map (
    clk_i             => clk_i,
    rst_i             => rst_i,
    valid_i           => valid_i,
    last_i            => last_i,
    keep_i            => keep_i,
    rotate_i          => rotate_i,
    valid_o           => moduloed_valid_x,
    last_o            => moduloed_last_x,
    keep_o            => moduloed_keep_x,
    rotate_moduloed_o => moduloed_rotate_x
  );

  day_1_solution_adder_tree_inst : entity work.day_1_solution_adder_tree
  generic map (
    G_NUM_INPUT_ROTATES => G_NUM_INPUT_ROTATES,
    G_REGISTER_STAGES   => G_REGISTER_STAGES_ADDER
  )
  port map (
    clk_i             => clk_i,
    rst_i             => rst_i,
    valid_i           => moduloed_valid_x,
    last_i            => moduloed_last_x,
    keep_i            => moduloed_keep_x,
    rotate_i          => moduloed_rotate_x,
    valid_o           => adder_valid_x,
    last_o            => adder_last_x,
    keep_o            => adder_keep_x,  
    rotate_o          => adder_rotate_x,
    added_o           => adder_added_x              -- the result of each beat added
  );

  -- follow the adder tree state machine
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      case follow_input_state_r is
      when WAIT_FOR_START =>
        dial_position_r <= G_STARTING_DIAL_POSITION;
        if adder_valid_x = '1' then
          -- process input_i and compute output_o
          if adder_last_x = '0' then
            follow_input_state_r <= PROCESSING_INPUT;
          end if;
          dial_position_r <= func_mod(G_STARTING_DIAL_POSITION, adder_added_x);
        end if;
      when PROCESSING_INPUT =>
        if adder_valid_x = '1' then
          dial_position_r <= func_mod(dial_position_r, adder_added_x);
          if adder_last_x = '1' then
            follow_input_state_r <= WAIT_FOR_START;
            dial_position_r      <= G_STARTING_DIAL_POSITION;
          end if;
        end if;
      when others =>
        follow_input_state_r <= WAIT_FOR_START;
        dial_position_r      <= G_STARTING_DIAL_POSITION;
      end case;

      if rst_i = '1' then
        follow_input_state_r <= WAIT_FOR_START;
        dial_position_r      <= G_STARTING_DIAL_POSITION;
      end if;
    end if;
  end process;

  -- count number of times dial lands on 0
  day_1_solution_count_zero_inst : entity work.day_1_solution_count_zero
  generic map (
    G_MAX_NUM_INPUT_BEATS     => G_MAX_NUM_INPUT_BEATS,
    G_NUM_INPUT_ROTATES       => G_NUM_INPUT_ROTATES,
    G_REGISTER_STAGES         => G_REGISTER_STAGES_COUNT_ZERO
  )
  port map (
    clk_i                   => clk_i,
    rst_i                   => rst_i,
    valid_i                 => adder_valid_x,
    last_i                  => adder_last_x,
    keep_i                  => adder_keep_x,
    rotate_i                => adder_rotate_x,
    dial_position_i         => dial_position_r,
    num_zero_counts_o       => num_zero_counts_x,
    num_zero_counts_valid_o => num_zero_counts_valid_x
  );

  num_zero_counts_o <= num_zero_counts_x;
  num_zero_counts_valid_o <= num_zero_counts_valid_x;


end architecture rtl;