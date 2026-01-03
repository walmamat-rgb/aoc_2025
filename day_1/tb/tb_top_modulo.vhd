library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.top_pkg.all;
use work.day_1_solution_pkg.all;

entity tb_top_modulo is
end entity;

architecture behavioral of tb_top_modulo is
-- Clock and reset signals
signal clk : std_logic := '0';
signal rst : std_logic := '1';

constant C_NUM_INPUT_ROTATES : positive := 4;
constant C_REGISTER_STAGES   : std_logic_vector := X"55555";

signal valid_i           : std_logic;     -- indicates rotate_i is valid
signal last_i            : std_logic;     -- indicates this is the last rotate in the sequence
signal keep_i            : std_logic_vector(0 to C_NUM_INPUT_ROTATES - 1); -- indicates which rotates are valid on this beat
signal rotate_i          : input_array_t(0 to C_NUM_INPUT_ROTATES - 1);
signal valid_o           : std_logic;     -- indicates rotate_i is valid
signal last_o            : std_logic;     -- indicates this is the last rotate in the sequence
signal keep_o            : std_logic_vector(0 to C_NUM_INPUT_ROTATES - 1); -- indicates which rotates are valid on this beat
signal rotate_moduloed_o : moduloed_input_array_t(0 to C_NUM_INPUT_ROTATES - 1);

-- Procedure to generate a random integer in a range [min, max]
procedure get_rand_int(
variable s1 : inout positive; 
variable s2 : inout positive; 
constant min : in integer; 
constant max : in integer; 
variable result : out integer
) is
variable r : real;
begin
    -- Generates a pseudo-random real number between 0.0 and 1.0
    UNIFORM(s1, s2, r);
    -- Scale to range and convert to integer
    result := integer(floor(r * real(max - min + 1))) + min;
end procedure;

type inject_data_state_t is (START_INJECT, INJECT_DATA);
signal inject_data_state_r : inject_data_state_t := START_INJECT;

type moduloed_input_array_array_t is array (natural range <>) of moduloed_input_array_t;
signal moduloed_input_array_r : moduloed_input_array_array_t(0 to 1023)(0 to C_NUM_INPUT_ROTATES - 1);
signal  moduloed_input_array_head_r : integer range 0 to 1023 := 0;
signal  moduloed_input_array_tail_r : integer range 0 to 1023 := 0;


begin


    -- Clock generation: 100 MHz (10 ns period)
    clk_gen : process
    begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end process clk_gen;

    -- Reset stimulus
    reset_proc : process
    begin
        -- hold reset active for 100 ns
        rst <= '1';
        wait for 100 ns;
        rst <= '0';

        wait;
    end process reset_proc;

    process
    variable seed1  : positive := 12345; -- Initial seeds
    variable seed2  : positive := 67890;
    variable rand_v : integer;    
    begin
        valid_i  <= '0';
        last_i   <= '0';
        keep_i   <= (others => '0');
        rotate_i <= (others => (rotate_amount => 0, direction => E_RIGHT));
        wait until rst = '0';

        loop 
            wait until rising_edge(clk);

            case inject_data_state_r is 
            when START_INJECT =>
                valid_i  <= '0';
                last_i   <= '0';
                keep_i   <= (others => '0');
                rotate_i <= (others => (rotate_amount => 0, direction => E_RIGHT));
                get_rand_int(seed1, seed2, 0, 15, rand_v);
                if rand_v = 0 then
                    inject_data_state_r <= INJECT_DATA;
                end if;
            when INJECT_DATA =>
                valid_i  <= '1';
                last_i   <= '0';
                keep_i   <= (others => '1');
                get_rand_int(seed1, seed2, 0, 15, rand_v);
                if rand_v = 0 then
                    last_i <= '1';
                    get_rand_int(seed1, seed2, 1, keep_i'length, rand_v);
                    keep_i <= (others => '0');
                    for index in 0 to rand_v-1 loop
                        keep_i(index) <= '1';
                    end loop;
                    inject_data_state_r <= START_INJECT;
                end if;
                for index in 0 to C_NUM_INPUT_ROTATES - 1 loop
                    get_rand_int(seed1, seed2, 0, C_MAX_ROTATE_AMOUNT, rand_v);
                    rotate_i(index).rotate_amount <= rand_v;
                    get_rand_int(seed1, seed2, 0, 1, rand_v);
                    if rand_v = 0 then
                        rotate_i(index).direction  <= E_RIGHT;
                    else
                        rotate_i(index).direction  <= E_LEFT;
                    end if;
                end loop;
            end case;
        end loop;

        wait;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if valid_i='1' then
                moduloed_input_array_r(moduloed_input_array_head_r) <= (others => (rotate_amount => 0));        
                -- monitor input and store predicted output
                for index in 0 to C_NUM_INPUT_ROTATES - 1 loop
                    if keep_i(index) = '1' then
                        if rotate_i(index).direction = E_LEFT then
                            moduloed_input_array_r(moduloed_input_array_head_r)(index).rotate_amount <= (0-rotate_i(index).rotate_amount) mod C_ROTATE_MODULO;
                        else
                            moduloed_input_array_r(moduloed_input_array_head_r)(index).rotate_amount <= rotate_i(index).rotate_amount mod C_ROTATE_MODULO;
                        end if;
                    end if;
                end loop;

                moduloed_input_array_head_r <= (moduloed_input_array_head_r + 1) mod 1024;
            end if;
        end if;
    end process;

    day_1_solution_modulo_input_inst : entity work.day_1_solution_modulo_input 
    generic map 
    (
        G_NUM_INPUT_ROTATES  => C_NUM_INPUT_ROTATES,  -- : positive  := 4;   -- array size of the input
        G_REGISTER_STAGES    => C_REGISTER_STAGES     -- : std_logic_vector := X"FFFFFFFFFFFFFFFF"  -- which stages to register
    )
    port map (
        clk_i             => clk,
        rst_i             => rst,
        valid_i           => valid_i,
        last_i            => last_i,
        keep_i            => keep_i,
        rotate_i          => rotate_i,
        valid_o           => valid_o,
        last_o            => last_o,
        keep_o            => keep_o,
        rotate_moduloed_o => rotate_moduloed_o
    );

    process(clk)
    begin
        if rising_edge(clk) then
            if valid_o='1' then
                -- check output against expected
                for index in 0 to C_NUM_INPUT_ROTATES - 1 loop
                    if keep_o(index) = '1' then
                        assert rotate_moduloed_o(index).rotate_amount = moduloed_input_array_r(moduloed_input_array_tail_r)(index).rotate_amount
                        report "Mismatch on output index " & integer'image(index) & 
                               ": expected " & integer'image(moduloed_input_array_r(moduloed_input_array_tail_r)(index).rotate_amount) & 
                               ", got " & integer'image(rotate_moduloed_o(index).rotate_amount)
                        severity error;
                    end if;
                end loop;

                moduloed_input_array_tail_r <= (moduloed_input_array_tail_r + 1) mod 1024;
            end if;
        end if;
    end process;


end architecture behavioral;