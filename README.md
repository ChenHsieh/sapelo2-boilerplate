# sapelo2-boilerplate

Notes, sbatch scripts, and Claude Code rules for running work on [GACRC Sapelo2](https://wiki.gacrc.uga.edu) — UGA's HPC cluster. Written from things that broke first.

Docs: <https://chenhsieh.github.io/sapelo2-boilerplate/>

## What's inside

| Dir | What |
|---|---|
| [`claude-code/`](claude-code/) | Claude Code setup tuned for Sapelo2 — `CLAUDE.md` ruleset (login vs. compute, filesystem quotas, `source activate` vs `conda activate`, right-sizing GPUs, post-submission health checks, ML pipeline sanity checks), aggressive-but-bounded permission allowlist, jq-free statusline. The README explains **why** each rule exists. |
| [`apps/`](apps/) | One dir per tool with a `run.sh` (sbatch) + `README.md` + helpers. Covers alphaFold, busco, MCScanx, nf-core/rnaseq, omega, orthoFinder, SpeedPPI, Trinotate. |
| [`pipeline/`](pipeline/) | Snakemake pipelines — `yt_whisper` (YouTube → Whisper transcripts), `get_best_hit` (cross-species DIAMOND best-hits). |
| [`generic_template/`](generic_template/) | Starter sbatch scripts — `conda.sh` (CPU+conda) and `gpu.sh` (single-GPU). Copy, rename, edit. |

For the **universal** (non-cluster-specific) agentic research practices — portable skills, session hygiene, cowork conventions — see [`agentic-research-toolkit`](https://github.com/ChenHsieh/agentic-research-toolkit).

## Quick start

```bash
git clone https://github.com/ChenHsieh/sapelo2-boilerplate.git
cd sapelo2-boilerplate/apps/<tool>
# edit run.sh: set mail-user, adjust inputs
sbatch run.sh
```

For the Claude Code setup, see [`claude-code/README.md`](claude-code/README.md).

## Conventions

- Every sbatch script uses `#!/bin/bash`, `%x.%j.out` log naming, and `youremail@uga.edu` as the placeholder email.
- `source activate env` inside sbatch, **never** `conda activate` (fresh sbatch shells have no conda init).
- Job I/O lands in `/scratch/$USER/`, never `/home`.
- Right-size GPUs: L4 (24GB) before A100 (80GB) unless you really need it.

Details and failure modes for each rule live in [`claude-code/CLAUDE.md`](claude-code/CLAUDE.md).
