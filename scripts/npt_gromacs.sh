#!/bin/bash
# ==========================================================
# Sequential NPT equilibration for all *_fixed_prep directories
# Author: Nauval
# Description:
#   Runs NPT equilibration one by one in each directory
# ==========================================================

# Path to NPT parameter file
NPT_MDP="/media/rattyananda/DATA/nauval_mrnavac/mRNA_vac/ready_to_run/mdp/npt.mdp"

# Loop through all directories ending with "_fixed_prep"
for dir in model.*_fixed_prep; do
    if [ -d "$dir" ]; then
        echo "=============================================="
        echo "Entering directory: $dir"
        echo "=============================================="
        cd "$dir" || exit 1

        # Check required files
        if [ -f "nvt.gro" ] && [ -f "topol.top" ]; then
            echo ">> Preparing NPT equilibration..."
            gmx_mpi grompp -f "$NPT_MDP" -c nvt.gro -p topol.top -o npt.tpr -maxwarn 1

            if [ -f "npt.tpr" ]; then
                echo ">> Running NPT simulation..."
                gmx_mpi mdrun -deffnm npt

                echo ">> Finished NPT for $dir"
                echo
            else
                echo "⚠️  Failed to generate npt.tpr, skipping $dir"
            fi
        else
            echo "⚠️  Missing input files in $dir, skipping..."
        fi

        # Return to parent directory
        cd ..
    fi
done

echo "✅ All NPT simulations completed sequentially."
