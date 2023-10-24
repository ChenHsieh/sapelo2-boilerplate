#!/bin/bash
#SBATCH --job-name=whisper         # Job name
#SBATCH --partition=batch             # Partition (queue) name
#SBATCH --gres=gpu:V100:1         # for V100 and P100, we can use them from batch for less than 4 hours
#SBATCH --ntasks=1            # Run on a single CPU
#SBATCH --cpus-per-task=8
#SBATCH --mem=32gb                     # Job memory request
#SBATCH --time=4:00:00               # Time limit hrs:min:sec
#SBATCH --output=whisper.%j.out    # Standard output log
#SBATCH --error=whisper.%j.err     # Standard error log
#SBATCH --mail-type=ALL          # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=youremail@uga.edu  # Where to send mail

date
ml Nextflow
ml Anaconda3
ml FFmpeg
ml snakemake
cd $SLURM_SUBMIT_DIR
conda init bash
source ~/.bashrc

conda activate video_transcript
snakemake --cores all --config youtube_url="https://www.youtube.com/watch?v=EiEXiuawcq8"

# nextflow run main.nf --youtube_url 'https://www.youtube.com/watch?v=y9ctVO1HE-Y'


date
