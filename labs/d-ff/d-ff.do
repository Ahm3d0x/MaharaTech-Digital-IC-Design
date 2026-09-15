# 1. Close any active simulation
quit -sim

# 2. Create and map the work library (if not already exists)
vlib work
vmap work work

# 3. Compile Verilog source files (RTL and Testbench)
vlog d-ff.v
vlog d_ff_tp.v

# 4. Load the testbench for simulation
vsim work.d_ff_tb

# 5. Add all top-level signals to the Wave window
add wave -position insertpoint sim:/d_ff_tb/*

# 6. Change wave format to show time cleanly (Optional)
configure wave -timelineunits ns

# 7. Run the simulation until $finish is encountered
run 160ns
