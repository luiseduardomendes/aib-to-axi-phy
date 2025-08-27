import sys
import os
import subprocess
import shutil
from typing import List
from scripts.process_filelist import process_filelist

def create_build_environment(source_file: str) -> None:
    """
    Create build environment, process filelist, and set up for TCL execution
    """
    # Create build directory
    build_dir = "build"
    if os.path.exists(build_dir):
        shutil.rmtree(build_dir)
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
    # env['SYNTH_CONSTRAINTS_FILE'] = 'constraints.xdc'  # Uncomment if needed
    
    print("Environment variables set:")
    print(f"  SYNTH_INCLUDE_DIRS: {env['SYNTH_INCLUDE_DIRS']}")
    print(f"  SYNTH_DEFINES: {env['SYNTH_DEFINES']}")
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
    if len(sys.argv) != 2:
        print("Usage: python make.py <filelist_file>")
        sys.exit(1)
    
    source_file = sys.argv[1]
    
    if not os.path.exists(source_file):
        print(f"Error: File '{source_file}' not found")
        sys.exit(1)
    
    try:
        create_build_environment(source_file)
        print("\nBuild process completed successfully!")
    except Exception as e:
        print(f"Error during build process: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()