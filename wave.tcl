# wave.tcl — open waveform with all MAC unit signals

# Add all top-level testbench signals
add_wave /mac_unit_tb/clk
add_wave /mac_unit_tb/rst_n
add_wave /mac_unit_tb/a
add_wave /mac_unit_tb/b
add_wave /mac_unit_tb/acc_in
add_wave /mac_unit_tb/acc_out

# Run the full simulation
run -all
