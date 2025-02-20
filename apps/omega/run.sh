#!/bin/bash
#SBATCH --job-name=omegafold_hap1
#SBATCH --partition=gpu_30d_p
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --gres=gpu:A100:1
#SBATCH --mem=180gb
#SBATCH --time=720:00:00      #30*24     
#SBATCH --output=%x.%j.out     
#SBATCH --error=%x.%j.err          
#SBATCH --mail-user=ch29576@uga.edu  
#SBATCH --mail-type=ALL   

# Load the necessary modules
ml purge                   # Remove any loaded modules to avoid conflicts
ml CUDA/12.2.0
ml Anaconda3

# Activate the conda environment without re-initializing bash
source activate omegafold

# Set environment variables to ensure the correct paths are being used
export PYTHONNOUSERSITE=True  # Prevent Python from adding user site packages
export PYTHONPATH=""          # Clear any existing PYTHONPATH
export LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$LD_LIBRARY_PATH  # Make sure conda libs are prioritized

# Print versions for debugging purposes
echo "Using Python version: $(python --version)"
echo "Using NumPy version: $(python -c 'import numpy; print(numpy.__version__)')"
echo "Using PyTorch version: $(python -c 'import torch; print(torch.__version__)')"

# Run OmegaFold
omegafold HAP1_remaining.fa HAP1_out_remaining
