import os
import glob
import sys
import matplotlib.pyplot as plt

# ------------------------------------------------------
# Python Script to Plot GROMACS .xvg files
# Requires: python3, matplotlib
# Usage: 
#   python3 plot_xvg.py             (scans current dir for *_fixed_prep_02)
#   python3 plot_xvg.py /path/to/dir (processes specific directory)
# ------------------------------------------------------

# specific directory pattern to look for
DIR_PATTERN = "*_fixed_prep_*"

# Configuration for each file type
# col_idx: 1 means use the 2nd column for Y-axis (standard for GROMACS simple outputs)
PLOT_CONFIG = {
    "rmsd.xvg": {
        "title": "RMSD (Backbone)",
        "xlabel": "Time (ns)",
        "ylabel": "RMSD (nm)",
        "output": "rmsd.png"
    },
    "gyrate.xvg": {
        "title": "Radius of Gyration",
        "xlabel": "Time (ps)", 
        "ylabel": "Rg (nm)",
        "output": "gyrate.png"
    },
    "area.xvg": {
        "title": "Solvent Accessible Surface Area",
        "xlabel": "Time (ps)",
        "ylabel": "Area (nm²)",
        "output": "area.png"
    },
    "rmsf.xvg": {
        "title": "RMS Fluctuation (Per Residue)",
        "xlabel": "Residue Index",
        "ylabel": "RMSF (nm)",
        "output": "rmsf.png"
    },
    "temperature.xvg": {
        "title": "Temperature",
        "xlabel": "Time (ps)",
        "ylabel": "Temperature (K)",
        "output": "temperature.png"
    },
    "pressure.xvg": {
        "title": "Pressure",
        "xlabel": "Time (ps)",
        "ylabel": "Pressure (bar)",
        "output": "pressure.png"
    },
    "date.xvg": {
        "title": "Date ?",
        "xlabel": "Time (ps)",
        "ylabel": "Date",
        "output": "date.png"
    },
    "potential.xvg": {
        "title": "Potential Energy",
        "xlabel": "Time (ps)",
        "ylabel": "Epot (kJ/mol)",
        "output": "potential.png"
    },
    "density.xvg": {
        "title": "Density",
        "xlabel": "Time (ps)",
        "ylabel": "Density (kg/m^3)",
        "output": "density.png"
    }
}

def parse_xvg(filepath):
    """Parses GROMACS xvg file, ignoring comments."""
    x_data = []
    y_data = []
    
    try:
        with open(filepath, 'r') as f:
            for line in f:
                line = line.strip()
                # Skip comments and metadata
                if not line or line.startswith(('@', '#')):
                    continue
                
                parts = line.split()
                # Ensure we have data
                if len(parts) >= 2:
                    try:
                        x_data.append(float(parts[0]))
                        y_data.append(float(parts[1])) # Take 2nd column (Total/Value)
                    except ValueError:
                        continue
    except FileNotFoundError:
        return None, None

    return x_data, y_data

def create_plot(x, y, config, save_path):
    """Generates and saves the plot."""
    plt.figure(figsize=(10, 6))
    
    # Customize plot style based on type
    if "rmsf" in config["output"]:
        # Handle gaps in residue indices (to avoid connecting separate chains)
        x_clean, y_clean = [], []
        if len(x) > 0:
            x_clean.append(x[0])
            y_clean.append(y[0])
            
            for i in range(1, len(x)):
                # If residue index jumps by more than 1.5, insert a break (None)
                if x[i] - x[i-1] > 1.5:
                    x_clean.append(None)
                    y_clean.append(None)
                x_clean.append(x[i])
                y_clean.append(y[i])

        # RMSF: Thinner line, no grid
        plt.plot(x_clean, y_clean, linewidth=1.0, color='tab:blue')
        plt.grid(False)
    else:
        # Others: Standard line with grid
        plt.plot(x, y, linewidth=1.5, color='tab:blue')
        plt.grid(True, linestyle='--', alpha=0.7)
    
    # Title removed as requested
    # plt.title(config["title"], fontsize=14, fontweight='bold')
    
    plt.xlabel(config["xlabel"], fontsize=12)
    plt.ylabel(config["ylabel"], fontsize=12)
    
    # Save
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    plt.close() # Close memory to avoid accumulation

def main():
    # check for command line argument
    if len(sys.argv) > 1:
        # User provided a specific path
        target_path = sys.argv[1]
        if os.path.isdir(target_path):
            directories = [target_path]
        else:
            print(f"Error: {target_path} is not a valid directory")
            return
    else:
        # Scan current directory using pattern
        base_dir = os.getcwd()
        directories = glob.glob(os.path.join(base_dir, DIR_PATTERN))
    
    if not directories:
        print(f"No directories found (Pattern: {DIR_PATTERN})")
        return

    print(f"Found {len(directories)} directories to process.")

    for d in directories:
        dir_name = os.path.basename(d)
        print(f"\nProcessing {dir_name}...")
        
        # Iterate through the 4 types of plots
        for filename, config in PLOT_CONFIG.items():
            file_path = os.path.join(d, filename)
            
            if os.path.exists(file_path):
                print(f"  - Plotting {filename}...", end=" ")
                x, y = parse_xvg(file_path)
                
                if x and y:
                    out_path = os.path.join(d, config["output"])
                    create_plot(x, y, config, out_path)
                    print(f"✅ Saved to {config['output']}")
                else:
                    print("⚠️  (Empty or invalid file)")
            else:
                # Silent skip if file doesn't exist (maybe analysis failed)
                pass

    print("\n🎉 All plots generated!")

if __name__ == "__main__":
    main()
