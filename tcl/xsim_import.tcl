############################################
# Set up Environment
############################################
if { $argc != 1 } {
    puts "Error: Provide source files file"
    exit 1
}
set source_files_file [lindex $argv 0]
set source_files [list]
set fp [open $source_files_file r]
while {[gets $fp line] >= 0} {
   lappend source_files $line
}
close $fp

# Get environment variables
if {[info exists ::env(SYNTH_INCLUDE_DIRS)]} {
    set include_dirs [split $::env(SYNTH_INCLUDE_DIRS) " "]
} else {
    set include_dirs [list]
    puts "Warning: SYNTH_INCLUDE_DIRS environment variable not set"
}

if {[info exists ::env(SYNTH_DEFINES)]} {
    set defines [split $::env(SYNTH_DEFINES) " "]
} else {
    set defines [list]
    puts "Warning: SYNTH_DEFINES environment variable not set"
}

# set constrains_file $::env(SYNTH_CONSTRAINTS_FILE)
set top_module aib_axi_top
set tb_file "$::env(IMPL_RTL_DIR)/../tb/tb_aib_axi_top.v"
set tb_module aib_axi_bridge_tb

############################################
# Create Project
############################################
create_project -force aib_project ./aib_project 

############################################
# Load Source Files, Include Directories, Defines and Constraints
############################################
add_files -sv {*}$source_files
add_files -fileset sim_1 $tb_file
# add_files -fileset constrs_1 $constrains_file
set_property file_type SystemVerilog [get_files *.v]

foreach dir $include_dirs {
    set_property include_dirs $dir [current_fileset]
    set_property include_dirs $dir [get_filesets sim_1]
}

foreach define $defines {
    set_property verilog_define $define [current_fileset]
    set_property verilog_define $define [get_filesets sim_1]
}

############################################
# Set Top Module
############################################
set_property top $top_module [current_fileset]
set_property top $tb_module [get_filesets sim_1]

############################################
# Finish Project Creation
############################################
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

############################################
# Waveform
############################################
set WAVEFORM "${IMPL_RTL_DIR}/axi4_aib_tools/wave/aib_axi_bridge_tb_behav.wcfg"
add_files -fileset [current_fileset -simset] -norecurse $WAVEFORM
set_property xsim.view { $WAVEFORM } [current_fileset -simset]
set_property xsim.simulate.runtime "10us" [current_fileset -simset]

puts "Project setup completed successfully!"