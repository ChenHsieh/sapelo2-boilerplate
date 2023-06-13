#!/bin/sh
#SBATCH -J name
#SBATCH --partition highmem_p
#SBATCH --ntasks=1                    # Run a single task	
#SBATCH --cpus-per-task=2   
#SBATCH --time=120:00:00
#SBATCH --mem=480gb
#SBATCH --mail-user=ch29576@uga.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=dis.%j.out
#SBATCH --error=dis.%j.err    

ml Anaconda3
conda init bash
source ~/.bashrc
conda activate env_name

cd $SLURM_SUBMIT_DIR

echo "get things done"
