# apps — pre-AI sbatch records

Everything under `apps/` is from **before** I used AI coding tools on HPC. These are hand-written `run.sh` scripts, half-note `README.md` files, and glue Python I wrote while actually running the work on Sapelo2 between 2021–2024. They are kept here as **a usage trace**: what I ran, roughly how I ran it, which modules existed at the time, and what broke.

Most of these scripts can now be regenerated — faster, cleaner, better-tuned — by asking Claude Code with the `claude-code/` ruleset in `CLAUDE.md`. The agent knows the current QOS table, module versions, and right-sizing rules; it won't hardcode paths or make the same partition mistakes.

**I'm not deleting them yet** because:

1. **Record of provenance** — a script that actually ran and produced data is evidence. Rewriting loses that trail.
2. **Module versions are historical** — `AlphaFold/2.0.0_conda`, `BUSCO/4.0.6-foss-2019b`, `Trinotate/4.0.2-foss-2022a`. These pin the software stack that produced published figures.
3. **AI-generated scripts need seeds** — showing the agent "here's how I did it last time" gives it a concrete starting point, which is better than describing from scratch.

## How to treat this directory

- **If you want to reproduce a past run** — read the script, trust nothing about modules/paths without verifying with `module avail` and your current quotas.
- **If you want to run the same tool today** — don't copy the script verbatim. Open Claude Code with `CLAUDE.md` loaded, point it at the tool + inputs, and let it write a new `run.sh`. Then diff against the old one to sanity-check.
- **If you're looking for a template** — use [`../generic_template/`](../generic_template/) instead. The scripts here are specific to particular inputs and lab allocations.

## Contents

| Tool | Domain | Notes |
|---|---|---|
| [`alphaFold/`](alphaFold/) | Structure prediction | GPU (P100 for 2.0.0 memory layout), GNU parallel over a cmd list |
| [`busco/`](busco/) | Genome/protein completeness | CPU, proteins mode with `--auto-lineage-euk` |
| [`MCScanx/`](MCScanx/) | Synteny & collinearity | All-vs-all DIAMOND local → MCScanX on cluster |
| [`nfcore-rnaseq/`](nfcore-rnaseq/) | RNA-seq quantification | Nextflow + singularity + phytozome-shaped annotations |
| [`omega/`](omega/) | OmegaFold structure prediction | Single-sequence, no MSA; A100 caps at ~1231 residues |
| [`orthoFinder/`](orthoFinder/) | Orthogroups | 3-stage run: prep → parallel diamond → resume |
| [`SpeedPPI/`](SpeedPPI/) | All-vs-all PPI folding | GACRC-modified FoldDock; A100, 30-day partition |
| [`Trinotate/`](Trinotate/) | Transcriptome annotation | Uses GACRC's shared `/db/trinotate/` |

## If you're using these

Fix before submitting:
- `#SBATCH --mail-user=youremail@uga.edu` → your email
- Hardcoded input filenames → your inputs
- Hardcoded `/scratch/<someone>/...` paths → your scratch
- Module versions — run `module avail <name>` and update to what's current
