#!/bin/bash
# ------------------------------------------------------
# Production MD (100 ns) — Resumeable Batch Runner
# Author: Nauval
# ------------------------------------------------------

set -e
set -o pipefail

# Base directory containing all simulation folders
BASE_DIR="/media/rattyananda/DATA/nauval_mrnavac/mRNA_vac/ready_to_run"
MDP_FILE="$BASE_DIR/md.mdp"

# Loop through all directories ending with _fixed_prep_16
for dir in "${BASE_DIR}"/*_fixed_prep_16; do
    if [ -d "$dir" ]; then
        echo "=============================================="
        echo "Entering directory: $dir"
        echo "=============================================="
        cd "$dir" || { echo "❌ Cannot enter $dir"; exit 1; }

        # Step 1: Check prerequisites
        if [ ! -f "npt.gro" ] || [ ! -f "topol.top" ]; then
            echo "❌ Missing required input (npt.gro or topol.top). Skipping..."
            cd "$BASE_DIR"
            continue
        fi

        # Step 2: Prepare md.tpr only if missing
        if [ ! -f "md.tpr" ]; then
            echo ">> Generating new TPR file..."
            gmx_mpi grompp -f "$MDP_FILE" -c npt.gro -t npt.cpt -p topol.top -o md.tpr -maxwarn 1
        else
            echo "⚙️ Found existing md.tpr — skipping grompp."
        fi

        # Step 3: Continue or start MD run
        if [ -f "md.cpt" ]; then
            echo "🔁 Checkpoint found. Resuming MD from md.cpt..."
            mpirun -np 4 gmx_mpi mdrun -deffnm md -cpi md.cpt -append
        else
            echo "🚀 No checkpoint found. Starting new MD simulation..."
            mpirun -np 4 gmx_mpi mdrun -deffnm md
        fi

        # Step 4: Convert trajectory (TRR → XTC)
        if [ -f "md.trr" ]; then
            echo ">> Converting trajectory to .xtc..."
            echo 0 | gmx_mpi trjconv -s md.tpr -f md.trr -o md.xtc || \
                echo "⚠️ trjconv (TRR→XTC) failed, continuing..."
        fi

        # Step 5: Remove PBC effects
        if [ -f "md.xtc" ]; then
            echo ">> Removing PBC (molecule compact representation)..."
            echo 0 | gmx_mpi trjconv -s md.tpr -f md.xtc -o md_noPBC.xtc -pbc mol -ur compact || \
                echo "⚠️ trjconv (PBC removal) failed, continuing..."
        fi

        echo "✅ Finished MD for $dir"
        echo
        cd "$BASE_DIR" || exit 1
    fi
done

echo "🎯 All MD simulations completed successfully!"
