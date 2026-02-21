#!/bin/bash
# ================================
# Automated Energy Minimization for all *_fixed_prep folders
# Author: Nauval
# Description:
#   This script navigates into each *_fixed_prep folder, runs energy minimization
#   using the provided em.mdp file, and extracts the potential energy.
# ================================

# Absolute path to the em.mdp file
EM_MDP="/media/rattyananda/DATA/nauval_mrnavac/mRNA_vac/ready_to_run/mdp/em_none.mdp"

# Loop through each folder ending with "_fixed_prep"
for dir in *_fixed_prep; do
    # Check if it's actually a directory
    if [ -d "$dir" ]; then
        echo "=============================================="
        echo "Entering directory: $dir"
        echo "=============================================="
        cd "$dir" || exit 1

        # Step 1: Run grompp (prepare .tpr for minimization)
        echo ">> Preparing tpr file for energy minimization..."
        gmx_mpi grompp -f "$EM_MDP" -c solvated_ions.gro -p topol.top -o em.tpr -maxwarn 1

        # Step 2: Run energy minimization in background safely
        echo ">> Running energy minimization (em.mdp)..."
        nohup gmx_mpi mdrun -deffnm em > em.log 2>&1 &

        # Wait for the job to finish before continuing to next directory
        # (optional: uncomment if you prefer sequential execution)
        # wait

        # Step 3: Extract potential energy when done
        echo ">> Extracting potential energy to potential.xvg (check results later)"
        echo "10" | gmx_mpi energy -f em.edr -o potential.xvg > /dev/null 2>&1

        # Go back to parent directory
        cd ..

        echo ">> Finished processing: $dir"
        echo
    fi
done

echo "✅ All energy minimization tasks have been submitted."
echo "   Use 'ps aux | grep mdrun' to monitor running jobs."
