# OmegaFold on Sapelo2

`A100 · 32 CPU · 180 G · 30 d · gpu_30d_p`

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
