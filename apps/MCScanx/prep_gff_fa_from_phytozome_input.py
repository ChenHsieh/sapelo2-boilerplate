import pandas as pd
gff = pd.read_csv("PtremulaxPopulusalbaHAP1_717_v5.1.gene_exons.gff3", sep="\t", comment="#", header=None)
gff.columns = ["seqid", "source", "type", "start", "end", "score", "strand", "phase", "attributes"]
gff = gff[gff["type"] == "gene"]
gff["chromosome number"] = gff["seqid"].str.extract(r"(\d+)", expand=False).astype(int)
# make the sp# column as string Pt + chromosome number
gff['sp#'] = [f"Pt{cn}" for cn in gff['chromosome number'].astype(str)]

# extract the gene name from the attributes column
gff["gene"] = gff["attributes"].str.extract(r"ID=(.*?);")

gff["gene"] = [gene[:-5] for gene in gff["gene"]]
gff = gff[["sp#", "gene", "start", "end"]]
gff.to_csv("h1.gff", sep="\t", index=False, header=False)


# read the fasta file
from Bio import SeqIO 
import pandas as pd
# replace all headers in the fasta file with a shorter name
# and remove all the gaps in the sequences
fasta_sequences = SeqIO.parse(open('PtremulaxPopulusalbaHAP1_717_v5.1.protein_primaryTranscriptOnly.fa'),'fasta')
with open('h1.fa', 'w') as out_file:
    for fasta in fasta_sequences:
        name, sequence = fasta.id, str(fasta.seq)
        name = name.split(' ')[0]
        name = name[:-4]
        sequence = sequence.replace('-','')
        sequence = sequence.replace('*','')
        out_file.write('>' + name + '\n' + sequence + '\n')


