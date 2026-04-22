# MCScanX usage at UGA

Here are some example scripts of data preprocessing and job submitting, using phytozome provided genome as an example. If the source of genome is different, adjust accordingly. I format the data and finish the all-vs-all blast locally, then use the sapelo2 to run the MCScanX. If needed, move the all-vs-all blast step to the cluster.

## 01 Preparing the input

I used the protein_primary_transcripts.fa from phytozome. I reformated the header to make sure they match the gff file. 

I used the gene_exons.gff3 from phytozome. Only the "gene" type rows were retained. Only the necessary columns were retained. 

## 02 All-vs-all BLAST

Here I used the DIAMOND to speed things up so doing this step locally on an M1 macbook only took 1 minute.

## 03 MCScanX

It's not a super computation intensive steps but I don't want to install MCScanX on my laptop so I used the sapelo2.
