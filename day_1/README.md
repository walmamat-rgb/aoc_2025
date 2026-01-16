# Introduction

This directory implements the solution to Advent of Code 2025 day 1, part A.

That turned out to be time consuming enough, so I didn't attempt part B.  As an aside, it turns out that the solution to Part B would require reversing some of the optimizations I made for Part A.

To compile and run use from modelsim or questasim:

do build.do
do sim.do

Modify sim.do to change which top level to use.  There were a few different ones to test different parts of the design.

tb_file_input.vhd - inputs the challenge file, outputs the result
tb_top.vhd - runs a randomized test and compares against the model
tb_top_modulo.vhd - tests first stage of solution

# Parameters
## C_ROTATE_MODULO - in fpga_top.vhd
Defines the modulo amount, in the problem statement this is 100.

It relates to the total number of tick marks on the lock dial.

## C_MAX_ROTATE_AMOUNT - fpga_top.vhd 
Defines the maximum input value from the input txt file.

By examining the problem input this is 999. 

## G_NUM_INPUT_ROTATES - in fpga_top.vhd
The number of parallel rotate operations this design is required to support

## G_MAX_NUM_INPUT_BEATS - in fpga_top.vhd
The number of beats of rotate information this design is required to support.  This defines the range of values on the output of fpga_top.vhd

## G_STARTING_DIAL_POSITION - in fpga_top.vhd
The starting dial position has been parameterized

## G_REGISTER_STAGES_COUNT_ZERO
## G_REGISTER_STAGES_MODULO
## G_REGISTER_STAGES_ADDER
Vectors that allow register placement anywhere in the pipeline, allowing finetuning of the latency, while still meeting timing.

# Solution Description

The input to the design models an AXI streaming interface.  This allows a variable length total number of rotates, even though the input is fixed at G_NUM_INPUT_ROTATES rotates wide.

The solution to Part A takes three steps.  

## Step 1 - Modulo Input - day_1_solution_modulo_input.vhd
This step reduces the input rotation values to be between 0 and C_ROTATE_MODULO-1 inclusive.

It also converts left rotations into right rotations.  This saves 
on logic later on, however it breaks the design from being able 
to solve Problem 1B.

To solve Problem 1B this stage would need to preserve the rotation direction, and in addition output the number of times passed zero.  That's unnecessary for 1A though.

This stage is pipelinable to meet the required clock frequency.

The modulo is done by removing powers of 2 times the modulo amount from the larger value.  Each stage removes one bit, probably multiple stages can be done in one cycle.

## Step 2 - Adder Tree - day_1_solution_adder_tree.vhd
Entering this stage we now have much smaller values.

This step is necessary in order to calculate the starting dial position of every beat of data.  An adder tree is able to be used because we don't care at this point if any particular summation results on landing on 0.  That's for the next stage.  Using an adder tree allows the latency of this stage to be approximately log2(G_NUM_INPUT_ROTATES) deep.  After the summation of each pair, the result is moduloed back down again.  

## Step 2 - Couont Zero - day_1_solution_count_zero.vhd
Each stage iterates over the next rotation, and increments a counter if we land on 0.  The final output is the total number of times we landed on 0 during the entire packet of rotates.

There's an additional optionally registered pipeline stage on the output of this block where the total number of rotations is calculated.

# Scalability
The design as it is should be able to scale to pretty large values of G_NUM_INPUT_ROTATES, limited I guess to getting rotate data onto the FPGA device.

I used the integer datatype all throughout, which is convenient because it allows defining a non-power of 2 range.  However it does have limitations, it's limited to 32 bits signed values.  If a greater range is required, then I would switch to signed and unsigned types.  

For even larger rotate values (like hundreds of bits) it may be necessary to pipeline even the simplest operations in this design, which probably would be func_mod in day_1_solution_pkg.vhd.  This has two add operations, and some muxing logic.  

# Conclusion
I enjoyed the challenge of implementing this, although when comparing it to serial implementation it's quite a lot of extra code.

In the future I'll look at hardcaml to see how much simpler it would be to implement it there.

