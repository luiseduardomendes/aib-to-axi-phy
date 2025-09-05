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
    set include_dirs $::env(SYNTH_INCLUDE_DIRS) 
} else {
    puts "Warning: SYNTH_INCLUDE_DIRS environment variable not set"
}

if {[info exists ::env(SYNTH_DEFINES)]} {
    set defines $::env(SYNTH_DEFINES)
} else {
    puts "Warning: SYNTH_DEFINES environment variable not set"
}

set project_name $::env(PROJECT_NAME)
set waveform_file $::env(WAVEFORM_FILE)
set top_module $::env(TOP_MODULE)
set tb_file $::env(TB_FILE)
set tb_module $::env(TB_MODULE)

# set constrains_file $::env(SYNTH_CONSTRAINTS_FILE)

############################################
# Create Project
############################################
create_project -force $project_name ./$project_name

############################################
# Load Source Files, Include Directories, Defines and Constraints
############################################
add_files  {*}$source_files
add_files -fileset sim_1 $tb_file
# add_files -fileset constrs_1 $constrains_file
set_property file_type SystemVerilog [get_files *.v]


set_property include_dirs $include_dirs [current_fileset]
set_property include_dirs $include_dirs [get_filesets sim_1]


set_property verilog_define $defines [current_fileset]
set_property verilog_define $defines [get_filesets sim_1]


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
add_files -fileset [current_fileset -simset] -norecurse $waveform_file
set_property xsim.view { $waveform_file } [current_fileset -simset]
set_property xsim.simulate.runtime "10us" [current_fileset -simset]

puts "Project setup completed successfully!"