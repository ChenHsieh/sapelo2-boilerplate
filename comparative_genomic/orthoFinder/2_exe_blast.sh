#!/bin/sh
#SBATCH -J OrthoFinder_blast
#SBATCH --partition batch
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=32
#SBATCH --time=168:00:00
#SBATCH --mem=128gb
#SBATCH --mail-user=ch29576@uga.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=job_name.%j.out
#SBATCH --error=job_name.%j.err    

ml DIAMOND
ml OrthoFinder
cd $SLURM_SUBMIT_DIR
# sed -n -e '/diamond blastp/,$p' diamond.cmd > diamonds.cmd
parallel --results outdir -j 0 -a diamonds.cmd
