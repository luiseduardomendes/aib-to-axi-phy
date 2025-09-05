import sys
import os
import subprocess
import shutil
import argparse
from typing import List
from scripts.process_filelist import process_filelist

def create_build_environment(channel: str) -> None:
    """
    Create build environment, process filelist, and set up for TCL execution
    """
    # Determine the filelist based on the channel
    rtl_impl_dir = os.environ.get('IMPL_RTL_DIR')
    if not rtl_impl_dir:
        print("Error: IMPL_RTL_DIR environment variable not set.")
        sys.exit(1)

    flists_dir = os.environ.get('FLISTS_DIR')
    if not flists_dir:
        print("Error: FLISTS_DIR environment variable not set.")
        sys.exit(1)

    if channel == "single":
        source_file = os.path.join(flists_dir, "aib-to-axi-phy-single-channel.flist")
        project_name = "aib_project_single"
        waveform_file = os.path.join(rtl_impl_dir, "axi4_aib_tools", "wave", "aib_axi_bridge_tb_behav_single.wcfg")
        top_module = "aib_axi_top_single"
        tb_module = "aib_axi_bridge_tb_single"
        tb_file = os.path.join(rtl_impl_dir, "..", "tb", "tb_aib_axi_top_modif.v")
    elif channel == "multi":
        source_file = os.path.join(flists_dir, "aib-to-axi-phy.flist")
        project_name = "aib_project"
        waveform_file = os.path.join(rtl_impl_dir, "..", "wave", "aib_axi_bridge_tb_behav.wcfg")
        top_module = "aib_axi_m2s2_top"
        tb_module = "tb_aib_axi_top_modif"
        tb_file = os.path.join(rtl_impl_dir, "..", "tb", "tb_aib_axi_top_modif.v")
    else:
        print("Error: Invalid channel. Choose 'single' or 'multi'.")
        sys.exit(1)

    if not os.path.exists(source_file):
        print(f"Error: File '{source_file}' not found")
        sys.exit(1)
    
    # Create build directory
    build_dir = "build"
    if not os.path.exists(build_dir):
        #shutil.rmtree(build_dir)
        os.makedirs(build_dir)
    
    # Process the filelist
    all_entries = process_filelist(source_file, expand=True, verify=True)
    
    # Separate files from directives
    source_files = []
    defines = []
    include_dirs = []
    libraries = []
    
    for entry in all_entries:
        if entry.startswith('-d '):
            defines.append(entry[3:])
        elif entry.startswith('-i '):
            include_dirs.append(entry[3:])
        elif entry.startswith('-L '):
            libraries.append(entry[3:])
        else:
            source_files.append(entry)
    
    # Create filelist with only source files (for TCL script)
    source_files_file = os.path.join(build_dir, "source_files.txt")
    with open(source_files_file, 'w') as f:
        for file in source_files:
            f.write(f"{file}\n")
    
    # Set environment variables for TCL script
    env = os.environ.copy()
    env['SYNTH_INCLUDE_DIRS'] = ' '.join(include_dirs)
    env['SYNTH_DEFINES'] = ' '.join(defines)
    env['PROJECT_NAME'] = project_name
    env['WAVEFORM_FILE'] = waveform_file
    env['TOP_MODULE'] = top_module
    env['TB_MODULE'] = tb_module
    env['TB_FILE']   = tb_file
    # env['SYNTH_CONSTRAINTS_FILE'] = 'constraints.xdc'  # Uncomment if needed
    
    print("Environment variables set:")
    print(f"  SYNTH_INCLUDE_DIRS: {env['SYNTH_INCLUDE_DIRS']}")
    print(f"  SYNTH_DEFINES: {env['SYNTH_DEFINES']}")
    print(f"  PROJECT_NAME: {env['PROJECT_NAME']}")
    print(f"  WAVEFORM_FILE: {env['WAVEFORM_FILE']}")
    print(f"  TOP_MODULE: {env['TOP_MODULE']}")
    print(f"  TB_MODULE: {env['TB_MODULE']}")
    print(f"  TB_FILE: {env['TB_FILE']}")
    print(f"  Source files written to: {source_files_file}")
    
    # Change to build directory for all subsequent operations
    os.chdir(build_dir)
    
    # Step 1: Run scripts/env.sh
    print("\nStep 1: Running scripts/env.sh")
    env_script = "../scripts/env.sh"
    if os.path.exists(env_script):
        try:
            result = subprocess.run(['bash', env_script], env=env, capture_output=True, text=True)
            if result.returncode != 0:
                print(f"Warning: env.sh script returned non-zero exit code: {result.returncode}")
                print(f"stderr: {result.stderr}")
            else:
                print("env.sh executed successfully")
        except Exception as e:
            print(f"Error running env.sh: {e}")
    else:
        print("Warning: scripts/env.sh not found, skipping")
    
    # Step 2: Run tcl/xsim_import.tcl with source files as argument
    print("\nStep 2: Running tcl/xsim_import.tcl")
    tcl_script = "../tcl/xsim_import.tcl"
    if os.path.exists(tcl_script):
        try:
            # Use absolute path for source files file
            abs_source_files = os.path.abspath("source_files.txt")
            
            result = subprocess.run([
                'vivado', '-mode', 'batch', '-source', tcl_script, 
                '-tclargs', abs_source_files
            ], env=env, capture_output=True, text=True)
            
            print(f"Vivado exit code: {result.returncode}")
            if result.stdout:
                print("Vivado stdout:")
                print(result.stdout)
            if result.stderr:
                print("Vivado stderr:")
                print(result.stderr)
                
            if result.returncode != 0:
                print("Error: Vivado script failed")
                sys.exit(1)
            else:
                print("TCL script executed successfully")
                
        except FileNotFoundError:
            print("Error: 'vivado' command not found. Make sure Vivado is in your PATH")
            sys.exit(1)
        except Exception as e:
            print(f"Error running TCL script: {e}")
            sys.exit(1)
    else:
        print(f"Error: TCL script {tcl_script} not found")
        sys.exit(1)

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description="Build script for AIB project.")
    parser.add_argument("--channel", choices=['single', 'multi'], required=True, help="Specify the AIB channel to build (single or multi)")
    args = parser.parse_args()
    
    try:
        create_build_environment(args.channel)
        print("\nBuild process completed successfully!")
    except Exception as e:
        print(f"Error during build process: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()