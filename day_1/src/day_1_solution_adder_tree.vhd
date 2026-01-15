library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.top_pkg.all;
use work.day_1_solution_pkg.all;

-- add all the rotate_i to overall rotation for this group of rotations
-- use an adder tree structure to do this efficiently
entity day_1_solution_adder_tree is
  generic (
    G_NUM_INPUT_ROTATES     : positive  := 4;   -- array size of the input
    G_REGISTER_STAGES       : std_logic_vector := X"FFFFFFFFFFFFFFFF"  -- which stages to register
  );
  port (
    clk_i      : in  std_logic;
    rst_i      : in  std_logic;
    valid_i    : in  std_logic;
    last_i     : in  std_logic;
    keep_i     : in  std_logic_vector(0 to G_NUM_INPUT_ROTATES - 1);
    rotate_i   : in  moduloed_input_array_t(0 to G_NUM_INPUT_ROTATES - 1);
    valid_o    : out std_logic;
    last_o     : out std_logic;
    keep_o     : out std_logic_vector(0 to G_NUM_INPUT_ROTATES - 1);
    rotate_o   : out moduloed_input_array_t(0 to G_NUM_INPUT_ROTATES - 1);
    added_o    : out integer range 0 to C_ROTATE_MODULO-1
  );
end entity day_1_solution_adder_tree;

architecture rtl of day_1_solution_adder_tree is

type input_record_t is record
    valid          : std_logic;     -- indicates rotate_i is valid
    last           : std_logic;     -- indicates this is the last rotate in the sequence
    keep           : std_logic_vector(0 to G_NUM_INPUT_ROTATES - 1); -- indicates which rotates are valid on this beat
    rotate         : moduloed_input_array_t(0 to G_NUM_INPUT_ROTATES - 1);
    rotate_added   : moduloed_input_array_t(0 to G_NUM_INPUT_ROTATES - 1);
end record;


constant C_NUM_STAGES : integer :=  clog2(G_NUM_INPUT_ROTATES);

type input_record_array_t is array (natural range <>) of input_record_t;
signal input_record_array_x : input_record_array_t(0 to C_NUM_STAGES-1) := (others => (valid => '0', last => '0', keep => (others => '0'), rotate | rotate_added => (others => (rotate_amount => 0))));
signal input_record_array_r : input_record_array_t(0 to C_NUM_STAGES-1) := (others => (valid => '0', last => '0', keep => (others => '0'), rotate | rotate_added => (others => (rotate_amount => 0))));

begin

  process(all)
  begin
    -- first stage is the input
    input_record_array_x(0).valid        <= valid_i;
    input_record_array_x(0).last         <= last_i;
    input_record_array_x(0).keep         <= keep_i;
    input_record_array_x(0).rotate       <= rotate_i;
    input_record_array_x(0).rotate_added <= rotate_i;

    -- pipeline the rest of the stages
    for stage_index in 1 to C_NUM_STAGES - 1 loop
      input_record_array_x(stage_index) <= input_record_array_r(stage_index-1);
    end loop;
  end process;

  gen_stages: for stage_index in 0 to C_NUM_STAGES - 1 generate
    gen_reg: if G_REGISTER_STAGES(stage_index)='1' generate
      process(clk_i)
      variable sum_v : integer range 0 to (C_ROTATE_MODULO-1);
      begin
        if rising_edge(clk_i) then
          input_record_array_r(stage_index).valid        <= input_record_array_x(stage_index).valid;
          input_record_array_r(stage_index).last         <= input_record_array_x(stage_index).last;
          input_record_array_r(stage_index).keep         <= input_record_array_x(stage_index).keep;
          input_record_array_r(stage_index).rotate       <= input_record_array_x(stage_index).rotate;
          input_record_array_r(stage_index).rotate_added <= (others => (rotate_amount => 0));
          -- add this row of values, each stage halves the number of inputs
          for input_index in 0 to (G_NUM_INPUT_ROTATES/(2**(stage_index+1))) - 1 loop
            sum_v := func_mod(input_record_array_x(stage_index).rotate_added(2*input_index).rotate_amount,input_record_array_x(stage_index).rotate_added(2*input_index + 1).rotate_amount);
            input_record_array_r(stage_index).rotate_added(input_index).rotate_amount <= sum_v;
          end loop;

          if rst_i='1' then
            input_record_array_r(stage_index).valid  <= '0';
            input_record_array_r(stage_index).last   <= '0';
            input_record_array_r(stage_index).keep   <= (others => '0');
            input_record_array_r(stage_index).rotate <= (others => (rotate_amount => 0));
            input_record_array_r(stage_index).rotate_added <= (others => (rotate_amount => 0));
          end if;
        end if;
      end process;
    end generate gen_reg;

    gen_no_reg: if G_REGISTER_STAGES(stage_index)='0' generate
      process(all)
      variable sum_v : integer range 0 to (C_ROTATE_MODULO-1);
      begin
          input_record_array_r(stage_index).valid        <= input_record_array_x(stage_index).valid;
          input_record_array_r(stage_index).last         <= input_record_array_x(stage_index).last;
          input_record_array_r(stage_index).keep         <= input_record_array_x(stage_index).keep;
          input_record_array_r(stage_index).rotate       <= input_record_array_x(stage_index).rotate;
          input_record_array_r(stage_index).rotate_added <= (others => (rotate_amount => 0));
          -- add this row of values, each stage halves the number of inputs
          for input_index in 0 to (G_NUM_INPUT_ROTATES/(2**(stage_index+1))) - 1 loop
            sum_v := func_mod(input_record_array_x(stage_index).rotate_added(2*input_index).rotate_amount,input_record_array_x(stage_index).rotate_added(2*input_index + 1).rotate_amount);
            input_record_array_r(stage_index).rotate_added(input_index).rotate_amount <= sum_v;
          end loop;
      end process;
    end generate gen_no_reg;
  end generate gen_stages;

  valid_o    <= input_record_array_r(C_NUM_STAGES-1).valid;  -- : out std_logic;
  last_o     <= input_record_array_r(C_NUM_STAGES-1).last;   -- : out std_logic;
  keep_o     <= input_record_array_r(C_NUM_STAGES-1).keep;   -- : out std_logic_vector(0 to G_NUM_INPUT_ROTATES - 1);
  rotate_o   <= input_record_array_r(C_NUM_STAGES-1).rotate; -- : out input_array_t(0 to G_NUM_INPUT_ROTATES - 1);
  added_o    <= input_record_array_r(C_NUM_STAGES-1).rotate_added(0).rotate_amount; -- : out integer range 0 to C_ROTATE_MODULO-1

end architecture rtl;