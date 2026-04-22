#!/bin/bash
#SBATCH --job-name=job_name
#SBATCH --partition=highmem_p
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --time=120:00:00
#SBATCH --mem=480gb
#SBATCH --mail-user=youremail@uga.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=%x.%j.out
#SBATCH --error=%x.%j.err

cd "$SLURM_SUBMIT_DIR"

ml Miniconda3
eval "$(conda shell.bash hook)"
conda activate env_name

echo "get things done"
