#!/bin/bash
# ------------------------------------------------------
# Production MD (100 ns) — Sequential Batch Runner
# Author: Nauval
# ------------------------------------------------------

set -e  # stop if any command fails
set -o pipefail  # detect failures inside pipes

# Base directory containing all simulation folders
BASE_DIR="/media/rattyananda/DATA/nauval_mrnavac/mRNA_vac/ready_to_run"

# Path to the MD parameter file
MDP_FILE="$BASE_DIR/md.mdp"

# Loop through all directories ending with _fixed_prep
for dir in "${BASE_DIR}"/*_fixed_prep_09; do
    if [ -d "$dir" ]; then
        echo "=============================================="
        echo "Entering directory: $dir"
        echo "=============================================="
        cd "$dir" || { echo "❌ Cannot enter $dir"; exit 1; }

        # Step 1: Prepare MD input file (TPR)
        echo ">> Step 1: Generating TPR file for MD..."
        if [ ! -f "npt.gro" ] || [ ! -f "topol.top" ]; then
            echo "❌ Missing required input (npt.gro or topol.top) in $dir"
            cd "$BASE_DIR"
            continue
        fi

        gmx_mpi grompp -f "$MDP_FILE" -c npt.gro -t npt.cpt -p topol.top -o md.tpr -maxwarn 1
        if [ $? -ne 0 ]; then
            echo "❌ grompp failed in $dir. Skipping..."
            cd "$BASE_DIR"
            continue
        fi

        # Step 2: Run MD simulation (blocking, sequential)
        echo ">> Step 2: Running production MD (this may take hours)..."
        mpirun -np 4 gmx_mpi mdrun -deffnm md
        if [ $? -ne 0 ]; then
            echo "❌ mdrun failed in $dir. Skipping..."
            cd "$BASE_DIR"
            continue
        fi

        # Step 3: Convert trajectory (TRR → XTC)
        if [ -f "md.trr" ]; then
            echo ">> Step 3: Converting trajectory to .xtc..."
            echo 0 | gmx_mpi trjconv -s md.tpr -f md.trr -o md.xtc || \
                echo "⚠️ trjconv (TRR→XTC) failed, but continuing..."
        else
            echo "⚠️ No md.trr found — skipping trajectory conversion."
        fi

        # Step 4: Remove PBC effects for visualization
        if [ -f "md.xtc" ]; then
            echo ">> Step 4: Removing PBC (compact molecule representation)..."
            echo 0 | gmx_mpi trjconv -s md.tpr -f md.xtc -o md_noPBC.xtc -pbc mol -ur compact || \
                echo "⚠️ trjconv (remove PBC) failed, but continuing..."
        else
            echo "⚠️ No md.xtc found — skipping PBC correction."
        fi

        echo "✅ Finished MD for $dir"
        echo
        cd "$BASE_DIR" || exit 1
    fi
done

echo "🎯 All MD simulations completed successfully!"

