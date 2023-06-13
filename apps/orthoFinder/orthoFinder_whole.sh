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
ml parallel
ml DIAMOND
ml OrthoFinder
cd $SLURM_SUBMIT_DIR

orthofinder -f fasta_files_directory -op -a 128 -t 128 > step1.out
sed -n -e '/diamond blastp/,$p' step1.out > diamond.cmd
parallel --results outdir -j 0 -a diamond.cmd
orthofinder -b ./OrthoFinder/Results_May31_4/WorkingDirectory/ -a 128 -t 128
