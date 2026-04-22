#!/bin/bash
#SBATCH --job-name=orthofinder
#SBATCH --partition=batch
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=32
#SBATCH --time=168:00:00
#SBATCH --mem=128gb
#SBATCH --mail-user=youremail@uga.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=%x.%j.out
#SBATCH --error=%x.%j.err

cd "$SLURM_SUBMIT_DIR"

ml parallel
ml DIAMOND
ml OrthoFinder

# Stage 1: prep — orthofinder writes diamond blastp commands to step1.out
orthofinder -f fasta_files_directory -op -a 128 -t 128 > step1.out

# Stage 2: run all-vs-all diamond in parallel
sed -n -e '/diamond blastp/,$p' step1.out > diamond.cmd
parallel --results outdir -j 0 -a diamond.cmd

# Stage 3: resume orthofinder with precomputed blasts (adjust Results_* path)
orthofinder -b ./OrthoFinder/Results_*/WorkingDirectory/ -a 128 -t 128
