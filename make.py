import sys
import os
import subprocess
import shutil
import argparse
from typing import List
from scripts.process_filelist import process_filelist

class Configuration:
    """
    Configuration class to store build parameters based on the channel.
    """
    def __init__(self, channel: str):
        self.rtl_impl_dir = os.environ.get('IMPL_RTL_DIR')
        if not self.rtl_impl_dir:
            print("Error: IMPL_RTL_DIR environment variable not set.")
            sys.exit(1)

        self.flists_dir = os.environ.get('FLISTS_DIR')
        if not self.flists_dir:
            print("Error: FLISTS_DIR environment variable not set.")
            sys.exit(1)

        channel_configs = {
            "single": {
                "source_file": os.path.join(self.flists_dir, "aib-to-axi-phy-single-channel.flist"),
                "project_name": "aib_single_ch_project",
                "waveform_file": os.path.join(self.rtl_impl_dir, "..", "wave", "tb_aib_axi_ch_top_behav.wcfg"),
                "top_module": "aib_axi_ch_top",
                "tb_module": "tb_aib_axi_ch_top",
                "tb_file": os.path.join(self.rtl_impl_dir, "..", "tb", "tb_aib_axi_ch_top.v"),
            },
            "multi": {
                "source_file": os.path.join(self.flists_dir, "aib-to-axi-phy.flist"),
                "project_name": "aib_project",
                "waveform_file": os.path.join(self.rtl_impl_dir, "..", "wave", "tb_aib_axi_top_modif_behav.wcfg"),
                "top_module": "aib_axi_m2s2_top",
                "tb_module": "tb_aib_axi_top_modif",
                "tb_file": os.path.join(self.rtl_impl_dir, "..", "tb", "tb_aib_axi_top_modif.v"),
            },
        }

        if channel not in channel_configs:
            print("Error: Invalid channel. Available [ 'single', 'multi' ].")
            sys.exit(1)

        self.config = channel_configs[channel]

def create_build_environment(config: Configuration) -> None:
    """
    Create build environment, process filelist, and set up for TCL execution
    """
    # Use the configuration object to access parameters
    source_file = config.config['source_file']
    project_name = config.config['project_name']
    waveform_file = config.config['waveform_file']
    top_module = config.config['top_module']
    tb_module = config.config['tb_module']
    tb_file = config.config['tb_file']

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
        config = Configuration(args.channel)
        create_build_environment(config)
        print("\nBuild process completed successfully!")
    except Exception as e:
        print(f"Error during build process: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()