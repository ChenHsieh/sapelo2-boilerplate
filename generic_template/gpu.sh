#!/bin/bash
#SBATCH --job-name=job_name
#SBATCH --partition=batch
#SBATCH --gres=gpu:V100:1        # V100/P100 from batch OK if <4h; else use gpu_p
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32gb
#SBATCH --time=4:00:00
#SBATCH --output=%x.%j.out
#SBATCH --error=%x.%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=youremail@uga.edu

cd "$SLURM_SUBMIT_DIR"

date
echo "do GPU stuff"
