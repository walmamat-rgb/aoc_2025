library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.top.all;

entity day_1_solution_modulo_input is
  generic (
    G_NUM_INPUT_ROTATES     : positive  := 4;   -- array size of the input
    G_MAX_NUM_INPUT_BEATS		: positive  := 16  -- this defines the dimensions of the output
    G_REGISTER_STAGES       : std_logic_vector := "1111"  -- which stages to register
  );
  port (
    clk_i             : in  std_logic;
    rst_i             : in  std_logic;
    valid_i           : in  std_logic;     -- indicates rotate_i is valid
    last_i            : in  std_logic;     -- indicates this is the last rotate in the sequence
    keep_i            : in  std_logic_vector(0 to G_NUM_INPUT_ROTATES - 1); -- indicates which rotates are valid on this beat
    rotate_i          : in  input_array_t(0 to G_NUM_INPUT_ROTATES - 1);
    valid_o           : out std_logic;     -- indicates rotate_i is valid
    last_o            : out std_logic;     -- indicates this is the last rotate in the sequence
    keep_o            : out std_logic_vector(0 to G_NUM_INPUT_ROTATES - 1); -- indicates which rotates are valid on this beat
    rotate_moduloed_o : out moduloed_input_array_t(0 to G_NUM_INPUT_ROTATES - 1)
  );
end entity day_1_solution_modulo_input;

architecture rtl of day_1_solution_modulo_input is

type input_record_t is record
    valid    : std_logic;     -- indicates rotate_i is valid
    last     : std_logic;     -- indicates this is the last rotate in the sequence
    keep     : std_logic_vector(0 to G_NUM_INPUT_ROTATES - 1); -- indicates which rotates are valid on this beat
    rotate   : input_array_t(0 to G_NUM_INPUT_ROTATES - 1);
end record;


constant C_ROTATE_MODULO : positive := 100; -- modulo for the dial
constant C_MAX_ROTATE_AMOUNT : positive := 999; -- maximum rotate amount

-- this would be 4 for 999 and 100
constant C_NUM_STAGES : integer :=  integer(ceil(log2(real(C_MAX_ROTATE_AMOUNT)/real(C_ROTATE_MODULO))));

type modulo_factor_array_t is array (0 to C_NUM_STAGES - 1) of positive;

-- should be 800 for 999 and 100
constant C_FIRST_MODULO_FACTOR : integer :=  C_ROTATE_MODULO*(2**(C_NUM_STAGES-1));

function calc_MODULO_FACTORS return modulo_factor_array_t is
variable modulo_value_v : positive := C_FIRST_MODULO_FACTOR;
variable return_value_v : modulo_factor_array_t;
begin
  for stage_index in 0 to C_NUM_STAGES - 1 loop 
    return_value_v(stage_index) := modulo_value_v;

    modulo_value_v := modulo_value_v/2;
  end loop;
  return return_value_v;
end function calc_MODULO_FACTORS;

-- should be 800,400,200,100 for 999 and 100
constant C_MODULO_FACTORS : modulo_factor_array_t := calc_MODULO_FACTORS;

type input_record_array_t is array (natural range <>) of input_record_t;
signal input_record_array_x : input_record_array_t(0 to C_NUM_STAGES);
signal input_record_array_r : input_record_array_t(0 to C_NUM_STAGES);

begin

  process(all)
  begin
    -- first stage is the input
    input_record_array_x(0).valid <= valid_i;
    input_record_array_x(0).last  <= last_i;
    input_record_array_x(0).keep  <= keep_i;
    input_record_array_x(0).rotate <= rotate_i;

    -- pipeline the rest of the stages
    for stage_index in 1 to C_NUM_STAGES - 1 loop
      input_record_array_x(stage_index) <= input_record_array_r(stage_index-1);
    end loop;
  end process;

  gen_stages: for stage_index in 0 to C_NUM_STAGES - 1 generate
    gen_reg: if G_REGISTER_STAGES(stage_index)='1' generate
      process(clk_i)
      variable diff_v : integer range -C_MAX_ROTATE_AMOUNT to C_MAX_ROTATE_AMOUNT;
      begin
        if rising_edge(clk_i) then
        -- process each stage
          for input_index in 0 to G_NUM_INPUT_ROTATES - 1 loop
            diff_v := input_record_array_x(stage_index).rotate(input_index).rotate_amount - C_MODULO_FACTORS(stage_index);
            if diff_v >= 0 then
              input_record_array_r(stage_index).rotate(input_index).rotate_amount <= diff_v;
            else
              input_record_array_r(stage_index).rotate(input_index).rotate_amount <= input_record_array_x(stage_index).rotate(input_index).rotate_amount;
            end if;
          end loop;
        end if;
      end process;
    end generate gen_reg;

    gen_no_reg: if G_REGISTER_STAGES(stage_index)='0' generate
      process(clk_i)
      variable diff_v : integer range -C_MAX_ROTATE_AMOUNT to C_MAX_ROTATE_AMOUNT;
      begin
      -- process each stage
        for input_index in 0 to G_NUM_INPUT_ROTATES - 1 loop
          diff_v := input_record_array_x(stage_index).rotate(input_index).rotate_amount - C_MODULO_FACTORS(stage_index);
          if diff_v >= 0 then
            input_record_array_r(stage_index).rotate(input_index).rotate_amount <= diff_v;
          else
            input_record_array_r(stage_index).rotate(input_index).rotate_amount <= input_record_array_x(stage_index).rotate(input_index).rotate_amount;
          end if;
        end loop;
      end process;
    end generate gen_no_reg;
  end generate gen_stages;

  -- convert L rotations to R rotations
  process(all)
  begin  
    valid_o  <= input_record_array_r(C_NUM_STAGES - 1).valid;        -- : out std_logic;     -- indicates rotate_i is valid
    last_o   <= input_record_array_r(C_NUM_STAGES - 1).last;         -- : out std_logic;     -- indicates this is the last rotate in the sequence
    keep_o   <= input_record_array_r(C_NUM_STAGES - 1).keep;         -- : out std_logic_vector(0 to G_NUM_INPUT_ROTATES - 1); -- indicates which rotates are valid on this beat

    rotate_moduloed_o(input_index).
    for input_index in 0 to G_NUM_INPUT_ROTATES - 1 loop
      if input_record_array_r(C_NUM_STAGES - 1).rotate(input_index).direction = E_LEFT then
        rotate_moduloed_o(input_index).rotate_amount <= (C_ROTATE_MODULO - input_record_array_r(C_NUM_STAGES - 1).rotate(input_index).rotate_amount) mod C_ROTATE_MODULO;
      else
        rotate_moduloed_o(input_index).rotate_amount <= input_record_array_r(C_NUM_STAGES - 1).rotate(input_index).rotate_amount;
      end if;
    end loop;
  end process;



end architecture rtl;