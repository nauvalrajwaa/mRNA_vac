#!/bin/bash

#SBATCH --job-name=md_test
#SBATCH --ntasks=1
#SBATCH --partition=medium-small
#SBATCH --cpus-per-task=36

# module load

module load bioinformatics/amber/24
module load gcc/11.4.0

echo "=== Starting MD ==="

# sander -O -i 03_min1.in -o 03_min1.out -p 02_complex_solv.prmtop -c 02_complex_solv.inpcrd -ref 02_complex_solv.inpcrd -r 03_min1.rst

sander -O -i 03_min2.in -o 03_min2.out -p 02_complex_solv.prmtop -c 03_min1.rst -r 03_min2.rst

pmemd.cuda -O -i 03_qheat.in -o 03_qheat.out -p 02_complex_solv.prmtop -c 03_min2.rst -ref 03_min2.rst -r 03_qheat.rst -x 03_qheat.coor

pmemd.cuda -O -i 04_promd_100ns.in -o 04_promd_100ns.out -p 02_complex_solv.prmtop -c 03_qheat.rst -r 04_promd_100ns.rst -x 04_promd_100ns.coor

echo "=== All process finished ==="

