def replace_period_with_underscore(fasta_file):
    with open(fasta_file, 'r') as file:
        lines = file.readlines()

    modified_lines = []
    for line in lines:
        if line.startswith('>'):
            line = line.replace('.', '_')
            line = line.replace(' ', '_')
        modified_lines.append(line)

    with open(fasta_file, 'w') as file:
        file.writelines(modified_lines)

def read_fasta(fasta_file):
    """Read a fasta file
    """

    ids = []
    seqs = []

    with open(fasta_file, 'r') as file:
        for line in file:
            line = line.rstrip()
            if '>' in line:
                ids.append(line[1:])
            else:
                seqs.append(line)

    return ids, seqs
# for checking fasta file lines
ids, seqs = read_fasta('./h1h2_merged/P717.fa')
print(len(ids))
print(len(seqs))

# For replacing period with underscore
replace_period_with_underscore('./h1h2_merged/P717.fa')
replace_period_with_underscore('./h1h2_primary_merged/P717_primary.fa')