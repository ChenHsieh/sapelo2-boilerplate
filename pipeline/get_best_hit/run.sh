#!/bin/bash
#SBATCH --job-name=razi         # Job name
#SBATCH --partition=batch             # Partition (queue) name
#SBATCH --ntasks=1            # Run on a single CPU
#SBATCH --cpus-per-task=24
#SBATCH --mem=64gb                     # Job memory request
#SBATCH --time=4:00:00               # Time limit hrs:min:sec
#SBATCH --output=razi.%j.out    # Standard output log
#SBATCH --error=razi.%j.err     # Standard error log
#SBATCH --mail-type=ALL          # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=youremail@uga.edu  # Where to send mail

date

ml Anaconda3
ml snakemake
ml DIAMOND
cd $SLURM_SUBMIT_DIR
conda init bash
source ~/.bashrc

conda activate snakemake
snakemake --cores all


date
