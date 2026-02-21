#!/bin/bash
# === Automate GROMACS preparation for all pdb/*.pdb files ===

set -e

# === Paths ===
PDB_DIR="./pdb"
MDP_DIR="./mdp"

# === Check files ===
if ! command -v gmx_mpi &> /dev/null; then
    echo "❌ Error: gmx_mpi not found in PATH."
    exit 1
fi

if [ ! -f "$MDP_DIR/ions.mdp" ]; then
    echo "❌ Error: ions.mdp not found in mdp/ folder."
    exit 1
fi

# === Loop all *_fixed.pdb ===
for pdb in "$PDB_DIR"/*_fixed.pdb; do
    filename=$(basename -- "$pdb")
    name="${filename%.pdb}"
    workdir="${name}_prep"

    echo "============================================"
    echo " Processing: $filename"
    echo " Creating: $workdir"
    echo "============================================"

    mkdir -p "$workdir"
    cd "$workdir"

    # Copy input PDB + ions.mdp
    cp "../$pdb" input.pdb
    cp "../$MDP_DIR/ions.mdp" .

    # === 1. Generate topology ===
    echo "[1/5] pdb2gmx..."
    gmx_mpi pdb2gmx -f input.pdb -o processed.gro -ignh -water tip3p <<EOF
15
EOF

    # === 2. Define box ===
    echo "[2/5] editconf (0.8 nm padding)..."
    gmx_mpi editconf -f processed.gro -o boxed.gro -c -d 0.8 -bt cubic

    # === 3. Solvate ===
    echo "[3/5] Solvating..."
    gmx_mpi solvate -cp boxed.gro -cs spc216.gro -o solvated.gro -p topol.top

    # === 4. Pre-ion TPR ===
    echo "[4/5] grompp for ions..."
    gmx_mpi grompp -f ions.mdp -c solvated.gro -p topol.top -o ions.tpr

    # === 5. Add ions ===
    echo "[5/5] Adding ions..."
    echo "SOL" | gmx_mpi genion -s ions.tpr -o solvated_ions.gro -p topol.top \
        -pname NA -nname CL -neutral -conc 0.15

    cd ..

    echo "✅ Finished $filename → folder = $workdir"
    echo ""
done

echo "============================================"
echo " All PDBs processed successfully!"
echo "============================================"

