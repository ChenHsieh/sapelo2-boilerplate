#!/bin/bash
#SBATCH --job-name=omegafold
#SBATCH --partition=gpu_30d_p
#SBATCH --ntasks=1                  
#SBATCH --cpus-per-task=32
#SBATCH --gres=gpu:P100:1 # must use P100 for the memory space
#SBATCH --mem=180gb              
#SBATCH --time=720:00:00      #30*24     
#SBATCH --output=%x.%j.out     
#SBATCH --error=%x.%j.err          
#SBATCH --mail-user=ch29576@uga.edu  
#SBATCH --mail-type=ALL   

cd $SLURM_SUBMIT_DIR
ml CUDA

ml Anaconda3
conda init bash
source ~/.bashrc
conda activate omegafold

omegafold LSG1.14g.fa out
omegafold LSG2.10g.fa out
omegafold LSG3.6g.fa out
omegafold LSG4.5gCO.fa out
omegafold LSG5.3g.fa out
omegafold LSG6.2g.fa out
