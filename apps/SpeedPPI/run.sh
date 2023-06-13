#!/bin/bash
#SBATCH --job-name=SpeedPPI              # Job name
#SBATCH --partition=gpu_30d_p             # Partition (queue) name
#SBATCH --gres=gpu:A100:1                  # Requests one GPU device 
#SBATCH --ntasks=1                    # Run a single task    
#SBATCH --cpus-per-task=28             # Number of CPU cores per task
#SBATCH --mem=32gb                    # Job memory request
#SBATCH --time=720:00:00               # Time limit hrs:min:sec
#SBATCH --output=SpeedPPI.%j.out         # Standard output log
#SBATCH --error=SpeedPPI.%j.err          # Standard error log
#SBATCH --mail-type=END,FAIL          # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=ch29576@uga.edu  # Where to send mail	


ml SpeedPPI/20230608
. ${SPEEDPPIENV}/bin/activate

cd $SLURM_SUBMIT_DIR

create_ppi_all_vs_all.sh P717_.fa hh-suite/build/bin/hhblits 0.5 output
