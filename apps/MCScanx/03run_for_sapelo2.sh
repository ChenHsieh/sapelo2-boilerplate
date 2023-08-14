#!/bin/sh
#SBATCH -J mcscanx_h1
#SBATCH --partition batch
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=168:00:00
#SBATCH --mem=1gb
#SBATCH --mail-user=youremail@uga.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=mcscanx_h1.%j.out
#SBATCH --error=mcscanx_h1.%j.err


date

cd $SLURM_SUBMIT_DIR

ml MCScanX

MCScanX ./h1

duplicate_gene_classifier ./h1
