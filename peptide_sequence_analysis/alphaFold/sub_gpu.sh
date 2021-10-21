#!/bin/bash
#SBATCH --job-name=alphafold
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
ml AlphaFold/2.0.0_conda

# single execution
# bash $EBROOTALPHAFOLD/alphafold/run_alphafold.sh -d /db/AlphaFold  -o ./test/ \
# -m model_1 -f ./3fasta.fa -t 2020-05-14

# parallel execution
parallel --results outdir -j 0 -a alphaFold.cmd