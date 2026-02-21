#!/bin/bash
# ------------------------------------------------------
# Run NVT equilibration for all *_fixed_prep folders
# Author: Nauval
# ------------------------------------------------------

# Define the path to the NVT parameter file
NVT_MDP="/media/rattyananda/DATA/nauval_mrnavac/mRNA_vac/ready_to_run/mdp/nvt.mdp"

# Loop through all directories ending with _fixed_prep
for dir in *_fixed_prep; do
    echo "---------------------------------------------"
    echo "Entering directory: $dir"
    echo "---------------------------------------------"
    cd "$dir" || { echo "Failed to enter $dir"; exit 1; }

    # Copy the NVT MDP file if it's not already there
    if [ ! -f "nvt.mdp" ]; then
        echo "Copying nvt.mdp..."
        cp "$NVT_MDP" .
    fi

    # Step 1: Generate the NVT input file
    echo "Running grompp for NVT..."
    gmx_mpi grompp -f nvt.mdp -c em.gro -r em.gro -p topol.top -o nvt.tpr || { echo "grompp failed in $dir"; cd ..; continue; }

    # Step 2: Run the NVT simulation
    echo "Running mdrun for NVT..."
    gmx_mpi mdrun -deffnm nvt || { echo "mdrun failed in $dir"; cd ..; continue; }

    # Step 3: Extract temperature data
    echo "Extracting temperature data..."
    echo "Temperature" | gmx_mpi energy -f nvt.edr -o temperature.xvg

    # Move back to parent directory
    cd ..
    echo "Finished NVT for $dir"
    echo
done

echo "All NVT simulations completed."
echo "All NVT simulations completed."

