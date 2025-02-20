import sys

def remove_asterisks(input_file, output_file):
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            if line.startswith('>'):
                outfile.write(line)
            else:
                cleaned_sequence = line.replace('*', '')
                outfile.write(cleaned_sequence)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python remove_asterisks.py <input_file.fasta> <output_file.fasta>")
    else:
        input_file = sys.argv[1]
        output_file = sys.argv[2]
        remove_asterisks(input_file, output_file)
