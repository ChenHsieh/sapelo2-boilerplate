# merge files
cat file1 file2 > file3 #might want to change fasta header before merging

# change the header
sed 's/HAP1-Chr/T/g' "$input_file" > "$output_file"

input_file="g717v5.fa"
output_file="g717v5_.fa"
sed -e 's/HAP1-//g' -e 's/HAP2-//g' "$input_file" > "$output_file"

input_file="717v5.gff"
output_file="g717v5.gff"
sed -e 's/HAP1-Chr/T/g' -e 's/HAP2-Chr/A/g' "$input_file" > "$output_file"

input_file="g717v5.gff"
output_file="g717v5_.gff"
sed -e 's/HAP1-//g' -e 's/HAP2-//g' "$input_file" > "$output_file"

# compare the two files that are too huge
file1="g717v5_.fa"
file2="g717v5_h1h2.fa"

## Calculate checksums
checksum1=$(md5sum "$file1" | awk '{print $1}')
checksum2=$(md5sum "$file2" | awk '{print $1}')

## Compare checksums
if [ "$checksum1" == "$checksum2" ]; then
    echo "The files are the same."
else
    echo "The files are different."
fi