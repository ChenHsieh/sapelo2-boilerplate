#!/bin/sh
#SBATCH -J job_name
#SBATCH --partition batch
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --time=124:00:00
#SBATCH --mem=190gb
#SBATCH --mail-user=youremail@uga.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=job_name.%j.out
#SBATCH --error=job_name.%j.err

date
cd $SLURM_SUBMIT_DIR
ml Nextflow
nextflow run nf-core/rnaseq -r 3.8.1 -name run_name --outdir results -profile singularity -params-file nf-params.json -resume 

