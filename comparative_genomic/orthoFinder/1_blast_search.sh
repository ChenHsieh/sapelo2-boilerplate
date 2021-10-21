#!/bin/sh
#SBATCH -J OrthoFinder
#SBATCH --partition batch
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --time=8:00:00
#SBATCH --mem=120gb
#SBATCH --mail-user=ch29576@uga.edu
#SBATCH --mail-type=BEGIN,END,FAIL

cd $SLURM_SUBMIT_DIR
ml OrthoFinder

orthofinder -f fastaFiles -op -a 8 -t -8

