#!/bin/bash
# ------------------------------------------------------
# Analysis Script: RMSD, Rg, SASA, RMSF
# Generates .xvg data files (does not launch xmgrace)
# ------------------------------------------------------

set -e

# Base directory (Uses the current directory where the script is run)
BASE_DIR="$PWD"

# Loop through the directories
for dir in "${BASE_DIR}"/*_fixed_prep_02; do
    if [ -d "$dir" ]; then
        echo "=============================================="
        echo "Processing $dir..."
        echo "=============================================="
        cd "$dir" || continue

        # Check if required files exist
        if [ ! -f "md.tpr" ] || [ ! -f "md_noPBC.xtc" ]; then
            echo "⚠️  Missing md.tpr or md_noPBC.xtc in $dir. Skipping."
            cd "$BASE_DIR"
            continue
        fi

        # 1. RMSD (Root Mean Square Deviation)
        # Input '4 4' selects 'Backbone' for fitting and calculation
        echo ">> Calculating RMSD (rmsd.xvg)..."
        echo "4 4" | gmx_mpi rms -s md.tpr -f md_noPBC.xtc -o rmsd.xvg -tu ns

        # 2. Radius of Gyration (Rg)
        # Input '1' selects 'Protein'
        echo ">> Calculating Radius of Gyration (gyrate.xvg)..."
        echo "1" | gmx_mpi gyrate -s md.tpr -f md_noPBC.xtc -o gyrate.xvg

        # 3. SASA (Solvent Accessible Surface Area)
        # Input '1' selects 'Protein'
        echo ">> Calculating SASA (area.xvg)..."
        echo "1" | gmx_mpi sasa -s md.tpr -f md_noPBC.xtc -o area.xvg

        # 4. RMSF (Root Mean Square Fluctuation)
        # Input '4' selects 'Backbone'
        echo ">> Calculating RMSF (rmsf.xvg)..."
        echo "4" | gmx_mpi rmsf -s md.tpr -f md_noPBC.xtc -o rmsf.xvg -res

        echo "✅ Analysis complete for $dir"
        cd "$BASE_DIR" || exit 1
    fi
done

echo "🎉 All analyses finished. Data saved to .xvg files in each directory."
