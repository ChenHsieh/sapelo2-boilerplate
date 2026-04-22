# AlphaFold on Sapelo2

![GPU](https://img.shields.io/badge/GPU-P100-5e35b1)
![CPUs](https://img.shields.io/badge/CPUs-32-2962ff)
![Memory](https://img.shields.io/badge/memory-180G-2e7d32)
![Time](https://img.shields.io/badge/time-30d-ef6c00)
![Partition](https://img.shields.io/badge/partition-gpu__30d__p-616161)

Structure prediction via the `AlphaFold/2.0.0_conda` module with GACRC's shared databases at `/db/AlphaFold`.

## Quick start

```bash
sbatch sub_gpu.sh
```

`sub_gpu.sh` runs GNU `parallel` over `alphaFold.cmd` (one `run_alphafold.sh` invocation per line), spreading multiple sequences across the GPU.

## Files

- `sub_gpu.sh` — sbatch script (P100 required for memory headroom)
- `alphaFold.cmd` — parallel command list, one prediction per line
- `prep.ipynb` — split input FASTA into per-chunk files and emit `alphaFold.cmd`

## Notes

- P100 over A100 here: the 2.0.0 module needs the P100 memory layout.
- Use `gpu_30d_p` partition for long runs (>7d time limit on batch GPU).
- Example input `Ptrichocarpav4.1g.primaryTrs.pep.fa` is a sample peptide file — replace with your own; do not commit large FASTA files.
