# OmegaFold on Sapelo2

![GPU](https://img.shields.io/badge/GPU-A100-5e35b1)
![CPUs](https://img.shields.io/badge/CPUs-32-2962ff)
![Memory](https://img.shields.io/badge/memory-180G-2e7d32)
![Time](https://img.shields.io/badge/time-30d-ef6c00)
![Partition](https://img.shields.io/badge/partition-gpu__30d__p-616161)

Protein structure prediction from single sequence (no MSA). GPU-bound.

## Quick start

```bash
conda env create -f environment.yml
sbatch run.sh
```

## Helpers

- `remove_asterisk.py` — strip trailing `*` from peptide sequences
- `simplify_file_name.py` — shorten FASTA filenames
- `merge_dedup.py` — merge multiple inputs, drop duplicates

## FAQ & troubleshooting

1. Strip `*` from peptide sequences before running.
2. Use `python=3.8`; newer versions unsupported.
3. Install from the OmegaFold GitHub source, not PyPI.
4. Sapelo2's largest GPU (A100) handles up to ~1231 residues.
