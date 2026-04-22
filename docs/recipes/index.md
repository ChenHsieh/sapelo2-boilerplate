# Recipes

Per-tool sbatch scripts, notes, and helpers live in [`apps/`](https://github.com/ChenHsieh/sapelo2-boilerplate/tree/main/apps) in the repo.

These are **pre-AI records** — hand-written from work I actually ran on Sapelo2 between 2021–2024. Kept as a usage trace and a seed for generating fresh scripts with Claude Code today. Regenerate with the [ruleset](../claude-code/rules.md) loaded; don't copy verbatim without re-verifying module versions.

| Tool | Resources | Source |
|---|---|---|
| alphaFold | P100 · 32 CPU · 180 G · 30 d · gpu_30d_p | [apps/alphaFold](https://github.com/ChenHsieh/sapelo2-boilerplate/tree/main/apps/alphaFold) |
| BUSCO | 4 CPU · 10 G · 48 h · batch | [apps/busco](https://github.com/ChenHsieh/sapelo2-boilerplate/tree/main/apps/busco) |
| MCScanX | 1 CPU · 1 G · 168 h · batch | [apps/MCScanx](https://github.com/ChenHsieh/sapelo2-boilerplate/tree/main/apps/MCScanx) |
| nf-core/rnaseq | 32 CPU · 190 G · 124 h · batch | [apps/nfcore-rnaseq](https://github.com/ChenHsieh/sapelo2-boilerplate/tree/main/apps/nfcore-rnaseq) |
| OmegaFold | A100 · 32 CPU · 180 G · 30 d · gpu_30d_p | [apps/omega](https://github.com/ChenHsieh/sapelo2-boilerplate/tree/main/apps/omega) |
| OrthoFinder | 4 × 32 CPU · 128 G · 168 h · batch | [apps/orthoFinder](https://github.com/ChenHsieh/sapelo2-boilerplate/tree/main/apps/orthoFinder) |
| SpeedPPI | A100 · 28 CPU · 32 G · 30 d · gpu_30d_p | [apps/SpeedPPI](https://github.com/ChenHsieh/sapelo2-boilerplate/tree/main/apps/SpeedPPI) |
| Trinotate | 32 CPU · 408 G · 120 h · highmem_p | [apps/Trinotate](https://github.com/ChenHsieh/sapelo2-boilerplate/tree/main/apps/Trinotate) |

Before submitting anything here, fix: mail-user, input filenames, hardcoded `/scratch/<someone>/` paths, module versions. Verify current versions with `module avail <name>`.

Generic starter templates: [sbatch templates](../reference/sbatch.md).
