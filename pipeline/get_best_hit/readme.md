# getting the most similar protein from another genome

when you have a fasta file of peptide sequences, you want to know what are their best hits (most similar peptide sequences according to DIAMOND) from some other genomes for functional annotation references, then you can try this pipeline to save up some manual labor. It's not well built, some file name matching issues might happen, but a few manual renaming would help.

this is a pipeline used when helping annotating a white clover transcriptome

# usage

your peptide of interest would be in fasta format in `transcripts.fasta.transdecoder.pep`

the database (reference peptide files from a certain species) peptide fasta file name should be `{species_name}.protein_primaryTranscriptOnly.fa.gz`

modify the names or parameters as needed

output will be generated in `best_hits.csv`
