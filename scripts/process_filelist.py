import sys
import os
from typing import List, Set
import re
import argparse

def expand_env_vars(path: str) -> str:
    """
    Expand environment variables in a path string.
    Handles ${VAR} and $VAR syntax.
    """
    def replace_env(match):
        var_name = match.group(1) or match.group(2)
        return os.environ.get(var_name, '')
    
    # Match ${VAR} and $VAR patterns
    pattern = r'\$\{([^}]+)\}|\$([a-zA-Z_][a-zA-Z0-9_]*)'
    return re.sub(pattern, replace_env, path)

def process_filelist(file_path: str, expand: bool, verify: bool) -> List[str]:
    """
    Process a filelist file and return a flat list of entries.
    
    Args:
        file_path: Path to the filelist file
        expand: whether to expand environment variables
        verify: whether to verify file existence
        
    Returns:
        List of processed entries with filelist content expanded and organized
    """
    # Separate storage for different types of entries (store values without prefixes)
    defines: List[str] = []
    includes: List[str] = []
    libraries: List[str] = []
    files: Set[str] = set()  # Use set to avoid duplicates
    
    def process_line(line: str, current_dir: str, expand: bool, verify: bool) -> None:
        """Process a single line from the file"""
        line = line.strip()
        
        # Skip empty lines and comments
        if not line or line.startswith('//'):
            return
        
        # Handle different types of entries
        if line.startswith('-d '):
            # Store without the '-d ' prefix
            defines.append(line[3:].strip())
        elif line.startswith('-i '):
            # Store without the '-i ' prefix
            line = line[3:].strip()
            expanded_line = expand_env_vars(line) if expand else line

            if verify:
                if not os.path.exists(expand_env_vars(line)):
                    print(f"Warning: Include file not found: {expand_env_vars(line)} (expanded from: {line})")
                    
            includes.append(expanded_line)
        elif line.startswith('-L '):
            # Store without the '-L ' prefix
            libraries.append(line[3:].strip())
        elif line.startswith('-f '):
            # Process filelist recursively with environment variable expansion
            flist_path = line[3:].strip()  # Remove '-f ' prefix
            
            # Expand environment variables
            expanded_path = expand_env_vars(flist_path)
            
            # Handle relative paths relative to the current file's directory
            if not os.path.isabs(expanded_path):
                expanded_path = os.path.join(current_dir, expanded_path)
            
            if os.path.exists(expanded_path):
                try:
                    # Get directory of the filelist for relative path resolution
                    flist_dir = os.path.dirname(os.path.abspath(expanded_path))
                    with open(expanded_path, 'r') as f:
                        for sub_line in f:
                            process_line(sub_line, flist_dir, expand, verify)
                except IOError as e:
                    print(f"Warning: Could not read filelist {expanded_path}: {e}")
            else:
                print(f"Warning: Filelist not found: {expanded_path} (expanded from: {flist_path})")
        else:
            # Regular file entry - expand environment variables
            expanded_line = expand_env_vars(line)
            
            if verify:
                if not os.path.exists(expanded_line):
                    print(f"Warning: File not found: {expanded_line} (expanded from: {line})")

            final_line = expand_env_vars(line) if expand else line

            if final_line and not final_line.startswith('//'):
                files.add(final_line)
    
    # Get directory of the main file for relative path resolution
    main_dir = os.path.dirname(os.path.abspath(file_path))
    
    # Read and process the main file
    try:
        with open(file_path, 'r') as f:
            for line in f:
                process_line(line, main_dir, expand, verify)
    except IOError as e:
        print(f"Error: Could not read file {file_path}: {e}")
        return []
    
    # Preambles
    DEFINE_PREAMBLE  = "-d"
    INCLUDE_PREAMBLE = "-i"
    LIBRARY_PREAMBLE = "-L"

    # Combine all entries in the required order, adding prefixes back
    result: List[str] = []
    result.extend(sorted(files))  # Sort files for consistent output
    result.extend([f"{DEFINE_PREAMBLE} {d}" for d in defines])
    result.extend([f"{INCLUDE_PREAMBLE} {i}" for i in includes])
    result.extend([f"{LIBRARY_PREAMBLE} {l}" for l in libraries])

    return result

def main():
    """Main function to handle command line usage"""
    parser = argparse.ArgumentParser(description="Process a filelist file.")
    parser.add_argument("input_file", help="Path to the input filelist file")
    parser.add_argument("-o", "--out", dest="output_file", help="Path to the output file", required=False)
    parser.add_argument("-e", "--expand", dest="expand", action="store_true", help="Expand environment variables", required=False)
    parser.add_argument("-v", "--verify", dest="verify", action="store_true", help="Verify file existence", required=False)
    args = parser.parse_args()
    
    input_file = args.input_file
    output_file = args.output_file
    expand = args.expand
    verify = args.verify
    
    if not os.path.exists(input_file):
        print(f"Error: File '{input_file}' not found")
        sys.exit(1)
    
    # Process the file
    result = process_filelist(input_file, expand, verify)
    
    # Output to file or stdout
    if output_file:
        try:
            with open(output_file, 'w') as f:
                for line in result:
                    f.write(line + '\n')
        except IOError as e:
            print(f"Error: Could not write to file {output_file}: {e}")
            sys.exit(1)
    else:
        for line in result:
            print(line)

if __name__ == "__main__":
    main()