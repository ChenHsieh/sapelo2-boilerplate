# OrthoFinder on Sapelo2

![Nodes](https://img.shields.io/badge/nodes-4_%C3%97_32-2962ff)
![Memory](https://img.shields.io/badge/memory-128G-2e7d32)
![Time](https://img.shields.io/badge/time-168h-ef6c00)
![Partition](https://img.shields.io/badge/partition-batch-616161)

Runs OrthoFinder with DIAMOND as the all-vs-all search engine.

## Quick start

Put input proteomes (one FASTA per species) in `fasta_files_directory/`, then:

```bash
sbatch run.sh
```

`run.sh` runs the three stages in one job:

1. `orthofinder -op` — prep + emit `diamond blastp` commands
2. `parallel -a diamond.cmd` — run all-vs-all blasts
3. `orthofinder -b` — resume with precomputed blasts

## Splitting into separate jobs

For very large datasets, split each stage into its own `sbatch` so stage 2 can claim more nodes and stage 3 can drop memory/time. Copy `run.sh`, delete the other stages, and submit three jobs with `--dependency=afterok:<jobid>`.

## Helper

- `copy_certain_files_from_large_dir.py` — pulls a subset of FASTA files from a large source directory.
