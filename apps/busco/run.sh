#!/bin/bash
#SBATCH --job-name=busco_h1               # Job name
#SBATCH --partition=batch               # Partition (queue) name
#SBATCH --ntasks=1                      # Run a single task	
#SBATCH --cpus-per-task=4               # Number of CPU cores per task
#SBATCH --mem=10gb                      # Job memory request
#SBATCH --time=48:00:00                 # Time limit hrs:min:sec
#SBATCH --output=log.%j.out             # Standard output log
#SBATCH --error=log.%j.err              # Standard error log
#SBATCH --export=NONE                   # Don't export user's explicit env variables to compute node
#SBATCH --mail-type=END,FAIL            # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=youremail@uga.edu    # Where to send mail	

cd $SLURM_SUBMIT_DIR

ml BUSCO/4.0.6-foss-2019b-Python-3.7.4  # load BUSCO/4.0.6 module

export AUGUSTUS_CONFIG_PATH=${PWD}/config_augustus
export BUSCO_CONFIG_FILE=${PWD}/config.ini

time busco --config ./config.ini --cpu 4 -i PtremulaxPopulusalbaHAP1_717_v5.1.protein_primaryTranscriptOnly.fa \
-m proteins --auto-lineage-euk -o PtremulaxPopulusalbaHAP1_717_v5.1.protein_primaryTranscriptOnly.fa_busco_h1
