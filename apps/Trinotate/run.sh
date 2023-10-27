#!/bin/sh
#SBATCH -J trinotate_database
#SBATCH --partition highmem_p
#SBATCH --ntasks=1                    # Run a single task	
#SBATCH --cpus-per-task=32
#SBATCH --time=120:00:00
#SBATCH --mem=408gb
#SBATCH --mail-user=
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=dis.%j.out
#SBATCH --error=dis.%j.err    

cd $SLURM_SUBMIT_DIR

# ml TransDecoder
TransDecoder.LongOrfs -t transcripts.fasta
TransDecoder.Predict -t transcripts.fasta

ml Trinotate/4.0.2-foss-2022a
# --
# creating database, this step is not needed anymore as GACRC created one for us
# Trinotate --create \
#             --db myTrinotate_2.sqlite \
#             --trinotate_data_dir $TRINOTATE_DATA_DIR \
#             --use_diamond

# instead we just need to copy the database and files
# $TRINOTATE_DATA_DIR
mkdir trinotate_data_2
cp /db/trinotate/20231016/* trinotate_data_2

# boilerplate.sqlite mentioned in the wiki
mv trinotate_data_2/TrinotateBoilerplate.sqlite myTrinotateDB.sqlite

# initialize db with your own sequence
Trinotate --db ./trinotate_data_2/myTrinotateDB.sqlite --init \
        --gene_trans_map gene_to_trans_map.tsv \
        --transcript_fasta transcripts.fasta \
        --transdecoder_pep transcripts.fasta.transdecoder.pep

# sequence analyses
Trinotate --db ./trinotate_data_2/myTrinotateDB.sqlite --CPU 32 \
            --transcript_fasta transcripts.fasta \
            --transdecoder_pep transcripts.fasta.transdecoder.pep \
            --trinotate_data_dir trinotate_data_2 \
            --run ALL \
            --use_diamond 

# generating report
Trinotate --db ./trinotate_data_2/myTrinotateDB.sqlite --report > myTrinotate.tsv
