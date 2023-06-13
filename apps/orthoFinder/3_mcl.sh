#!/bin/sh
#SBATCH -J OrthoFinder
#SBATCH --partition batch
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --time=120:00:00
#SBATCH --mem=120gb
#SBATCH --mail-user=ch29576@uga.edu
#SBATCH --mail-type=BEGIN,END,FAIL

cd $SLURM_SUBMIT_DIR
ml OrthoFinder

orthofinder -b /scratch/ch29576/orphanGene/fastaFiles/OrthoFinder/Results_Jan04/WorkingDirectory -a 32 -t -32

