#!/bin/sh
#SBATCH -J broccoli
#SBATCH --partition highmem_p
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --time=120:00:00
#SBATCH --mem=480gb
#SBATCH --mail-user=ch29576@uga.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=dis.%j.out
#SBATCH --error=dis.%j.err    


module load FastTree/2.1.11-GCCcore-8.3.0

ml Anaconda3

ml DIAMOND
conda init bash
source ~/.bashrc
conda activate binf

cd $SLURM_SUBMIT_DIR

python /scratch/ch29576/broccoli/Broccoli/broccoli.py -dir /scratch/ch29576/broccoli/fastaFiles -threads 32 -ext '.fa' -path_fasttree /apps/eb/FastTree/2.1.11-GCCcore-8.3.0/bin/FastTree -steps 2,3,4