# create_project.tcl
# Vivado script to automate project creation and synthesis for the 4x4 Systolic Array

set project_name "mac_unit_project"
set project_dir "vivado_project"
set part "xc7z020clg400-1"

# Create project
if {[file exists $project_dir]} {
    file delete -force $project_dir
}
create_project $project_name $project_dir -part $part

# Add source files
add_files mac_unit.v
add_files systolic_array_4x4.v
add_files top_level.v
add_files -fileset constrs_1 constraints.xdc

# Set top-level module
set_property top top_level [current_fileset]

# Run Synthesis
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Check for synthesis success
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed!"
    exit 1
}

# Open synthesized design
open_run synth_1

# Generate Reports
report_utilization -file utilization.txt
report_timing_summary -file timing.txt

puts "Vivado project creation and synthesis complete."
puts "Utilization report saved to utilization.txt"
puts "Timing report saved to timing.txt"

exit 0
