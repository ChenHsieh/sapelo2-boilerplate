# SpeedPPI on Sapelo2

`A100 · 28 CPU · 32 G · 30 d · gpu_30d_p`

SpeedPPI is the improved iteration of FoldDock. Modified by GACRC associates to work on Sapelo2.

# FAQ & troubleshooting

1. when reading the fasta file, the program will split the header of the sequence by "." and only take the first element. Use the `mod.py` provided here to change the header of the fasta file.

2. some error would happen when out dir already exist. make sure to remove them before running the program, or just change the out dir name.

3. all fasta sequences should be in one line, here is a one line command to do that:

```bash
awk '/^>/ { print (NR==1 ? "" : RS) $0; next } { printf "%s", $0 } END { printf RS }' file
```