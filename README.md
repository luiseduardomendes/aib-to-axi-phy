# AIB to AXI Bridge Project

Project for simulation and validation of bridges between AIB (Advanced Interface Bus) and AXI (Advanced eXtensible Interface) interfaces using Vivado and XSim.

## Project Structure

```
.
├── flists/              # Filelists with RTL dependencies
│   ├── aib-to-axi-phy.flist      # Multi-channel configuration
│   ├── aib-to-axi-phy-single-channel.flist
│   └── vendor/                    # Submodules (aib-phy-hardware, aib-protocols)
├── rtl/                 # RTL source code (SystemVerilog/Verilog)
│   ├── shared/          # Shared modules (bridges, wrappers)
│   └── vendor/          # RTL submodules
├── tb/                  # Testbenches
├── scripts/             # Helper scripts (process_filelist.py, env.sh)
├── tcl/                 # TCL scripts for Vivado/XSim
├── make.py              # Main build script
└── make.txt             # Alternative documentation
```

## Prerequisites

- **Xilinx Vivado** (with `vivado` in PATH)
- Python 3.12+
- Git (for submodules)
- Linux/Unix environment (bash scripts)

## Installation

### 1. Clone with submodules

```bash
git clone --recursive https://github.com/luiseduardomendes/aib-to-axi-phy
cd aib-to-axi-phy

# If already cloned without submodules:
git submodule update --init --recursive
```

### 2. Set environment variables

```bash
export IMPL_RTL_DIR=$(pwd)/rtl
export FLISTS_DIR=$(pwd)/flists
source scripts/env.sh
```

## Usage

### Build and Simulation

```bash
# Multi-channel simulation (default)
python make.py <filelist_file>
```

The script will:
1. Process filelists (`*.flist`)
2. Resolve dependencies and includes
3. Create build environment in `build/`
4. Run simulation in Vivado XSim
5. Load configured waveform (`.wcfg`)

### Opening project

```bash
vivado build/aib_project/aib_project.xpr
```

### Cleanup

```bash
rm -rf build/
```

## Dependencies (Submodules)

- `aib-phy-hardware` - AIB physical layer
- `aib-protocols` - AIB protocols

## Troubleshooting

### Error: `IMPL_RTL_DIR environment variable not set`
```bash
export IMPL_RTL_DIR=$(pwd)/rtl
export FLISTS_DIR=$(pwd)/flists
```

### Error: `vivado: command not found`
Add Vivado to PATH:
```bash
source /opt/Xilinx/Vivado/2023.x/settings64.sh
```

### Submodules not downloaded
```bash
git submodule update --init --recursive
```

## Authors

Luis Eduardo Pereira Mendes <lepmendes@inf.ufrgs.br>

```

The README is now in English while maintaining all the technical details specific to your project structure and build system.