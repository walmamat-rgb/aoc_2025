library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.top_pkg.all;
use work.day_1_solution_pkg.all;

entity day_1_solution_count_zero is
  generic (
    G_MAX_NUM_INPUT_BEATS   : positive  := 16;  -- this defines the dimensions of the output
    G_NUM_INPUT_ROTATES     : positive  := 4;   -- array size of the input
    G_REGISTER_STAGES       : std_logic_vector := X"FFFFFFFFFFFFFFFF"  -- which stages to register
  );
  port (
    clk_i                   : in  std_logic;
    rst_i                   : in  std_logic;
    valid_i                 : in  std_logic;     -- indicates rotate_i is valid
    last_i                  : in  std_logic;     -- indicates this is the last rotate in the sequence
    keep_i                  : in  std_logic_vector(0 to G_NUM_INPUT_ROTATES - 1); -- indicates which rotates are valid on this beat
    rotate_i                : in  moduloed_input_array_t(0 to G_NUM_INPUT_ROTATES - 1);
    dial_position_i         : in  integer range 0 to C_ROTATE_MODULO-1; -- dial location for this beat
    num_zero_counts_o       : out integer range 0 to (G_NUM_INPUT_ROTATES*G_MAX_NUM_INPUT_BEATS)-1; -- number of times the dial lands on 0
    num_zero_counts_valid_o : out std_logic
  );
end entity day_1_solution_count_zero;

architecture rtl of day_1_solution_count_zero is

type count_zero_t is record
    valid            : std_logic;     -- indicates rotate_i is valid
    last             : std_logic;     -- indicates this is the last rotate in the sequence
    keep             : std_logic_vector(0 to G_NUM_INPUT_ROTATES - 1); -- indicates which rotates are valid on this beat
    rotate           : moduloed_input_array_t(0 to G_NUM_INPUT_ROTATES - 1);
    num_zero_counts  : integer range 0 to G_NUM_INPUT_ROTATES-1; -- number of times the dial lands on 0
    dial_position    : integer range 0 to C_ROTATE_MODULO-1; -- dial location for this beat
end record;

type count_zero_array_t is array (natural range <>) of count_zero_t;
signal count_zero_array_r : count_zero_array_t(0 to G_NUM_INPUT_ROTATES - 1);
signal count_zero_array_x : count_zero_array_t(0 to G_NUM_INPUT_ROTATES - 1);

type follow_input_state_t is (WAIT_FOR_START, PROCESSING_INPUT);
signal follow_input_state_r : follow_input_state_t := WAIT_FOR_START;

signal num_zero_counts_x : integer range 0 to (G_NUM_INPUT_ROTATES*G_MAX_NUM_INPUT_BEATS) := 0;
signal num_zero_counts_valid_x : std_logic;

signal num_zero_counts_r : integer range 0 to (G_NUM_INPUT_ROTATES*G_MAX_NUM_INPUT_BEATS) := 0;

begin

    -- shift
    process(all)
    begin
      count_zero_array_x(0).valid           <= valid_i;
      count_zero_array_x(0).last            <= last_i;
      count_zero_array_x(0).keep            <= keep_i;
      count_zero_array_x(0).rotate          <= rotate_i;
      count_zero_array_x(0).num_zero_counts <= 0;
      count_zero_array_x(0).dial_position   <= dial_position_i;

      for index in 1 to G_NUM_INPUT_ROTATES - 1 loop
        count_zero_array_x(index) <= count_zero_array_r(index - 1);
      end loop;
    end process;

     gen_adder_row: for stage_index in 0 to G_NUM_INPUT_ROTATES-1 generate
         gen_reg: if G_REGISTER_STAGES(stage_index) = '1' generate
            process(clk_i)
            variable sum_v : integer range 0 to (C_ROTATE_MODULO-1);
            begin
              if rising_edge(clk_i) then
                -- copy over all fields by default
                count_zero_array_r(stage_index) <= count_zero_array_x(stage_index);
                sum_v := func_mod(count_zero_array_x(stage_index).dial_position,  count_zero_array_x(stage_index).rotate(stage_index).rotate_amount);
                count_zero_array_r(stage_index).dial_position <= sum_v;
                -- check for zero landings
                if sum_v=0 and count_zero_array_x(stage_index).keep(stage_index)='1' then
                    count_zero_array_r(stage_index).num_zero_counts <= count_zero_array_x(stage_index).num_zero_counts + 1;
                end if;

                if rst_i='1' then
                    count_zero_array_r(stage_index).valid           <= '0';
                    count_zero_array_r(stage_index).last            <= '0';
                    count_zero_array_r(stage_index).keep            <= (others => '0');
                    count_zero_array_r(stage_index).rotate          <= (others => (rotate_amount => 0));
                    count_zero_array_r(stage_index).num_zero_counts <= 0;
                    count_zero_array_r(stage_index).dial_position   <= 0;
                end if;
              end if;
            end process;
        end generate gen_reg;

        gen_no_reg: if G_REGISTER_STAGES(stage_index) = '0' generate
            process(all)
            variable sum_v : integer range 0 to (C_ROTATE_MODULO-1);
            begin
              -- copy over all fields by default
              count_zero_array_r(stage_index) <= count_zero_array_x(stage_index);
              sum_v := func_mod(count_zero_array_x(stage_index).dial_position,  count_zero_array_x(stage_index).rotate(stage_index).rotate_amount);
              count_zero_array_r(stage_index).dial_position <= sum_v;
              -- check for zero landings
              if sum_v=0 and count_zero_array_x(stage_index).keep(stage_index)='1' then
                count_zero_array_r(stage_index).num_zero_counts <= count_zero_array_x(stage_index).num_zero_counts + 1;
              end if;

            end process;
        end generate gen_no_reg;
    end generate gen_adder_row;

  process(all)
  begin
    num_zero_counts_valid_x <= '0';
    num_zero_counts_x       <= num_zero_counts_r;

    case follow_input_state_r is
    when WAIT_FOR_START =>
        if count_zero_array_r(G_NUM_INPUT_ROTATES - 1).valid = '1' then
            num_zero_counts_x <= count_zero_array_r(G_NUM_INPUT_ROTATES - 1).num_zero_counts;
            if count_zero_array_r(G_NUM_INPUT_ROTATES - 1).last = '0' then
                null;
            else
                num_zero_counts_valid_x <= '1';
            end if;
        end if;
    when PROCESSING_INPUT =>
        if count_zero_array_r(G_NUM_INPUT_ROTATES - 1).valid = '1' then
            num_zero_counts_x <= num_zero_counts_r + count_zero_array_r(G_NUM_INPUT_ROTATES - 1).num_zero_counts;
            if count_zero_array_r(G_NUM_INPUT_ROTATES - 1).last = '1' then
                num_zero_counts_valid_x <= '1';
            end if;
        end if;
    end case;

  end process;

  -- follow the stream state machine
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      num_zero_counts_r <= num_zero_counts_x;

      case follow_input_state_r is
      when WAIT_FOR_START =>
        if count_zero_array_r(G_NUM_INPUT_ROTATES - 1).valid = '1' then
          -- process input_i and compute output_o
          if count_zero_array_r(G_NUM_INPUT_ROTATES - 1).last = '0' then
            follow_input_state_r <= PROCESSING_INPUT;
          end if;
        end if;
      when PROCESSING_INPUT =>
        if count_zero_array_r(G_NUM_INPUT_ROTATES - 1).valid = '1' then
          if count_zero_array_r(G_NUM_INPUT_ROTATES - 1).last = '1' then
            follow_input_state_r <= WAIT_FOR_START;
          end if;
        end if;
      when others =>
        follow_input_state_r <= WAIT_FOR_START;
      end case;

      if rst_i = '1' then
        num_zero_counts_r        <= 0;
        follow_input_state_r <= WAIT_FOR_START;
      end if;
    end if;
  end process;

  g_reg_output: if G_REGISTER_STAGES( G_NUM_INPUT_ROTATES ) = '1' generate
    process(clk_i)
    begin
      if rising_edge(clk_i) then
        num_zero_counts_o       <= num_zero_counts_x;
        num_zero_counts_valid_o <= num_zero_counts_valid_x;
      end if;
    end process;
  end generate;

  g_noreg_output: if G_REGISTER_STAGES( G_NUM_INPUT_ROTATES ) = '0' generate
    process(all)
    begin
      num_zero_counts_o       <= num_zero_counts_x;
      num_zero_counts_valid_o <= num_zero_counts_valid_x;
    end process;
  end generate;
  

end architecture rtl;