library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;
use ieee.std_logic_textio.all;

library work;
use work.top_pkg.all;
use work.day_1_solution_pkg.all;

entity tb_file_input is
end entity;

architecture behavioral of tb_file_input is
-- Clock and reset signals
signal clk : std_logic := '0';
signal rst : std_logic := '1';

constant C_NUM_INPUT_ROTATES      : positive := 16;
constant C_MAX_NUM_INPUT_BEATS    : positive := 512;       -- : positive  := 16;  -- this defines the dimensions of the output
constant C_STARTING_DIAL_POSITION : positive := 50;   -- : integer range 0 to C_ROTATE_MODULO-1 := 0  -- starting position of the dial

-- no registers 
constant C_REGISTER_STAGES_COUNT_ZERO : std_logic_vector(C_NUM_INPUT_ROTATES downto 0) := (0=>'1', 1=>'1',others => '1');  -- which stages to register
constant C_REGISTER_STAGES_MODULO     : std_logic_vector(C_NUM_INPUT_ROTATES-1 downto 0) := (0=>'1',1=>'1',others => '1');
constant C_REGISTER_STAGES_ADDER      : std_logic_vector(C_NUM_INPUT_ROTATES-1 downto 0) := (0=>'1',1=>'1',others => '1');


signal valid_i           : std_logic;     -- indicates rotate_i is valid
signal last_i            : std_logic;     -- indicates this is the last rotate in the sequence
signal keep_i            : std_logic_vector(0 to C_NUM_INPUT_ROTATES - 1); -- indicates which rotates are valid on this beat
signal rotate_i          : input_array_t(0 to C_NUM_INPUT_ROTATES - 1);

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

type scorboard_record_t is record
    num_zero_counts : integer; -- number of times the dial lands on 0
end record;

type scoreboard_array_t is array (natural range <>) of scorboard_record_t;
signal scoreboard_array_r : scoreboard_array_t(0 to 1023);
signal  scoreboard_array_head_r : integer range 0 to 1023 := 0;
signal  scoreboard_array_tail_r : integer range 0 to 1023 := 0;

signal num_zero_counts_o       : integer range 0 to (C_NUM_INPUT_ROTATES*C_MAX_NUM_INPUT_BEATS)-1; -- number of times the dial lands on 0
signal num_zero_counts_valid_o : std_logic;

type follow_input_state_t is (WAIT_FOR_START, FOLLOW_INPUT);
signal follow_input_state_r : follow_input_state_t := WAIT_FOR_START;

-- File declaration
file input_file : text;

-- Procedure to process each line
procedure process_line(
    variable line_buffer : inout line;
    variable direction : out character;
    variable value : out integer;
    variable valid : out boolean
) is
variable char_read : character;
variable int_read : integer;
begin
    valid := false;
    
    -- Check if line is not empty
    if line_buffer'length > 0 then
        -- Read first character (L or R)
        read(line_buffer, char_read);
        
        -- Validate first character
        if char_read = 'L' or char_read = 'R' then
            direction := char_read;
            
            -- Read the integer part
            if line_buffer'length > 0 then
                read(line_buffer, int_read);
                value := int_read;
                valid := true;
            end if;
        end if;
    end if;
end procedure;

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
    variable line_buffer : line;
    variable direction : character;
    variable value : integer;
    variable valid : boolean;
    variable file_status : file_open_status;
    variable index : integer;
    variable rotate_v : input_array_t(0 to C_NUM_INPUT_ROTATES - 1);
    variable keep_v : std_logic_vector(0 to C_NUM_INPUT_ROTATES - 1);
    begin
        -- Open the input file
        file_open(file_status, input_file, "../data/input.txt", read_mode);
        
        -- Check if file opened successfully
        if file_status /= open_ok then
            report "Error: Could not open input file" severity error;
            wait;
        end if;
        
        index := 0;
        valid_i  <= '0';         --: std_logic;     -- indicates rotate_i is valid
        last_i   <= '0';         --: std_logic;     -- indicates this is the last rotate in the sequence
        keep_i   <= (others=>'0');         --: std_logic_vector(0 to C_NUM_INPUT_ROTATES - 1); -- indicates which rotates are valid on this beat
        rotate_i <= (others => (direction => E_RIGHT, rotate_amount => 0));

        wait until rising_edge(clk);
        wait until rst = '0';
        wait until rising_edge(clk);

        -- Read file until end of file
        while not endfile(input_file) loop
            -- Read a line from the file
            readline(input_file, line_buffer);
            
            -- Process the line
            process_line(line_buffer, direction, value, valid);
            
            -- Display results if valid
            if valid then
                report "Direction: " & direction & ", Value: " & integer'image(value);
                
                if direction='L' then
                    rotate_v(index mod C_NUM_INPUT_ROTATES).direction := E_LEFT;
                else
                    rotate_v(index mod C_NUM_INPUT_ROTATES).direction := E_RIGHT;
                end if;

                rotate_v(index mod C_NUM_INPUT_ROTATES).rotate_amount := value;

                keep_v(index mod C_NUM_INPUT_ROTATES) := '1';

                if (index mod C_NUM_INPUT_ROTATES) = C_NUM_INPUT_ROTATES - 1 then
                    valid_i  <= '1';
                    rotate_i <= rotate_v;
                    keep_i   <= keep_v;
                    wait until rising_edge(clk);
                    keep_v   := (others=>'0');         --: std_logic_vector(0 to C_NUM_INPUT_ROTATES - 1); -- indicates which rotates are valid on this beat
                    rotate_v := (others => (direction => E_RIGHT, rotate_amount => 0));
                    valid_i  <= '0';
                    rotate_i <= (others => (direction => E_RIGHT, rotate_amount => 0));
                    keep_i   <= (others=>'0');
                end if;
                index := index + 1;
                
            else
                report "Invalid line format detected" severity warning;
            end if;
            
        end loop;

        valid_i  <= '1';
        rotate_i <= rotate_v;
        keep_i   <= keep_v;
        last_i   <= '1';

        wait until rising_edge(clk);

        valid_i  <= '0';         --: std_logic;     -- indicates rotate_i is valid
        last_i   <= '0';         --: std_logic;     -- indicates this is the last rotate in the sequence
        keep_i   <= (others=>'0');         --: std_logic_vector(0 to C_NUM_INPUT_ROTATES - 1); -- indicates which rotates are valid on this beat
        rotate_i <= (others => (direction => E_RIGHT, rotate_amount => 0));

        -- Close the file
        file_close(input_file);
        
        report "File processing completed";
        wait; -- End simulation    
    end process;

    -- calculate expected output
    process(clk)
    variable num_zero_counts_v : integer;
    variable position_v        : integer;
    begin
        if rising_edge(clk) then
            case follow_input_state_r is
            when WAIT_FOR_START =>
                num_zero_counts_v := 0;
                position_v := C_STARTING_DIAL_POSITION;
                if valid_i='1' then
                    for index in 0 to C_NUM_INPUT_ROTATES - 1 loop
                        if keep_i(index) = '1' then
                            if rotate_i(index).direction = E_LEFT then
                                position_v := (position_v - rotate_i(index).rotate_amount) mod C_ROTATE_MODULO;
                                -- left rotate
                                if (position_v = 0) then
                                    num_zero_counts_v := num_zero_counts_v + 1;
                                end if;
                            else
                                position_v := (position_v + rotate_i(index).rotate_amount) mod C_ROTATE_MODULO;
                                -- right rotate
                                if (position_v = 0) then
                                    num_zero_counts_v := num_zero_counts_v + 1;
                                end if;
                            end if;
                        end if;
                    end loop;

                    if last_i='1' then
                        -- store result
                        scoreboard_array_r(scoreboard_array_head_r).num_zero_counts <= num_zero_counts_v;
                        scoreboard_array_head_r <= (scoreboard_array_head_r + 1) mod 1024;
                    else
                        follow_input_state_r <= FOLLOW_INPUT;
                    end if;
                end if;
            when FOLLOW_INPUT =>
                if valid_i='1' then
                    for index in 0 to C_NUM_INPUT_ROTATES - 1 loop
                        if keep_i(index) = '1' then
                            if rotate_i(index).direction = E_LEFT then
                                position_v := (position_v - rotate_i(index).rotate_amount) mod C_ROTATE_MODULO;
                                -- left rotate
                                if (position_v = 0) then
                                    num_zero_counts_v := num_zero_counts_v + 1;
                                end if;
                            else
                                position_v := (position_v + rotate_i(index).rotate_amount) mod C_ROTATE_MODULO;
                                -- right rotate
                                if (position_v = 0) then
                                    num_zero_counts_v := num_zero_counts_v + 1;
                                end if;
                            end if;
                        end if;
                    end loop;

                    if last_i='1' then
                        -- store result
                        scoreboard_array_r(scoreboard_array_head_r).num_zero_counts <= num_zero_counts_v;
                        scoreboard_array_head_r <= (scoreboard_array_head_r + 1) mod 1024;
                        follow_input_state_r <= WAIT_FOR_START;
                    end if;
                end if;
            end case;

            if rst='1' then
                follow_input_state_r <= WAIT_FOR_START; 
            end if;    
        end if;
    end process;

  day_1_solution_inst : entity work.day_1_solution
  generic map
  (
    G_NUM_INPUT_ROTATES          => C_NUM_INPUT_ROTATES,          -- : positive  := 4;   -- array size of the input
    G_MAX_NUM_INPUT_BEATS        => C_MAX_NUM_INPUT_BEATS,        -- : positive  := 16;  -- this defines the dimensions of the output
    G_STARTING_DIAL_POSITION     => C_STARTING_DIAL_POSITION,     -- : integer range 0 to C_ROTATE_MODULO-1 := 0  -- starting position of the dial
    G_REGISTER_STAGES_COUNT_ZERO => C_REGISTER_STAGES_COUNT_ZERO, -- : std_logic_vector := X"00000000";  -- which stages to register
    G_REGISTER_STAGES_MODULO     => C_REGISTER_STAGES_MODULO,     -- : std_logic_vector := X"00000000";
    G_REGISTER_STAGES_ADDER      => C_REGISTER_STAGES_ADDER       -- : std_logic_vector := X"00000000";
  )
  port map
  (
    clk_i                   => clk,
    rst_i                   => rst,
    valid_i                 => valid_i,  -- indicates rotate_i is valid
    last_i                  => last_i,   -- indicates this is the last rotate in the sequence
    keep_i                  => keep_i,   -- indicates which rotates are valid on this beat
    rotate_i                => rotate_i,
    num_zero_counts_o       => num_zero_counts_o,
    num_zero_counts_valid_o => num_zero_counts_valid_o
  );

  -- verify the output
  process(clk)
  begin
    if rising_edge(clk) then
        if num_zero_counts_valid_o='1' then
            if num_zero_counts_o /= scoreboard_array_r(scoreboard_array_tail_r).num_zero_counts then
                report "Mismatch detected: expected " & integer'image(scoreboard_array_r(scoreboard_array_tail_r).num_zero_counts) &
                       ", got " & integer'image(num_zero_counts_o)
                       severity error;
            else
                report "Output verified: " & integer'image(num_zero_counts_o);
            end if;

            scoreboard_array_tail_r <= (scoreboard_array_tail_r + 1) mod 1024;
        end if;
    end if;
  end process;

end architecture behavioral;