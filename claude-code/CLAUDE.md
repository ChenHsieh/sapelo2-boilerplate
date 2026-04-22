# CLAUDE.md — Sapelo2 HPC (GACRC, UGA)

> Sapelo2 is a **shared research cluster** used by the entire UGA research community.
> Everything Claude does here affects real shared infrastructure and other users' jobs.
> When uncertain, do less and ask — not more and apologize.

---

## Where you are

- **Login node** prompt: `MYID@ss-sub<N>` — shared gateway, minimal resources
- **Compute node** prompt: `MYID@c4-16` (or similar `c4-*`, `b1-*`, `a4-*` etc.)
- Claude Code is launched **after** the user has already run `interact` to get a compute node
- Claude's bash tool has **no pty support** — `interact`, `srun --pty`, `qlogin` will always fail, do not attempt them

---

## Login node rules (hard limits)

**Never run on the login node:**
- Any Python/R/Bash script with real computation
- Bioinformatics tools (STAR, HISAT2, kallisto, salmon, samtools, DIAMOND, etc.)
- `conda install`, large `pip install`
- `tar`, `gzip`, `pigz` on large files
- Any command that runs longer than a few seconds

**OK on the login node:**
- Text editing, writing scripts
- `sbatch`, `squeue`, `seff`, `sacct`, `scancel`
- `module avail`, `module list`
- `git status/add/commit/push`
- `ls`, `du -sh`, `mkdir`, `mv`, small `rm`

**If in doubt about which node you're on:** run `hostname`.
Login = `ss-sub<N>`, compute = `c4-<N>` etc.

---

## How to get a compute node (user does this, not Claude)

```bash
# Default: 1 core, 2GB, 12h
interact

# Typical bioinformatics session
interact -c 8 --mem=16G --time=8:00:00

# High-memory work (genome indexing, large R objects)
interact -p highmem_p --mem=64G --time=4:00:00

# GPU testing
interact -p gpu_p --gres=gpu:A100:1 --mem=50G
```

Always run inside `tmux` first so SSH disconnects don't kill the session:
```bash
tmux new -s work        # or: tmux attach -t work
interact -c 8 --mem=16G
module load Miniforge3/24.11.3-0
source activate <env>
cd /scratch/MYID/<project>
claude
```

---

## When to sbatch vs run interactively

| Task | Where |
|---|---|
| Editing scripts, checking logs | Login node is fine |
| Testing code, short runs (<1h, <16GB) | `interact` compute node |
| Full pipeline runs, alignments, assemblies | `sbatch` |
| Anything overnight or unattended | `sbatch` |

**Claude should write and submit `sbatch` scripts for heavy work — never try to run heavy tools directly.**

---

## Filesystem rules

| Path | Quota | Purged | Use for |
|---|---|---|---|
| `/home/MYID` | 200 GB | No | Scripts, conda envs, configs — changes slowly |
| `/scratch/MYID` | No quota | **30 days** | ALL job I/O — inputs, outputs, intermediates |
| `/work/YOURLAB` | 500 GB | No | Shared reference data (genomes, annotation) |
| `/project/YOURLAB` | 1 TB | No | Archive — **xfer node only**, not mountable on compute |
| `/lscratch` | ~200–800 GB | Job end | Ultra-fast local I/O for single-node jobs |

**Rules Claude must follow:**
1. Job output → `/scratch/MYID/` always, never `/home`
2. Never write large files to `/home` — conda envs + BAMs fill 200GB fast
3. `/project` is **not mountable on compute nodes** — don't try to read/write it from a job
4. `/lscratch` disappears when the job ends — copy results to `/scratch` before job exits
5. `tar`/`gzip` must run in a batch job or interactive session, never on login node
6. Remind user to move outputs to `/work` or `/project` after jobs finish — scratch purges in 30 days

---

## Software modules

Always use **full versioned module names** — defaults can change when new versions are added:

```bash
module avail STAR                          # search
module load STAR/2.7.10a-GCC-11.3.0       # load specific version
module list                                # check what's loaded
module purge                               # unload all
```

**Python environment manager: Miniforge3** (not Anaconda3)

```bash
module load Miniforge3/24.11.3-0           # as of 2026-04, only 24.1.2-0 and 24.11.3-0 exist
source activate my_env                      # NOT "conda activate" — see below
```

**CRITICAL: conda activate vs source activate in sbatch scripts.**
- `conda activate` requires conda shell init (`conda init bash`), which is NOT available in a fresh sbatch shell.
- **Always use `source activate <env>` in sbatch scripts.** This works without shell init.
- **Never assume a module version exists — run `module avail <name>` first** if uncertain. Module versions change when GACRC updates the software stack.

**No shell state persists between Bash tool calls.** Each Bash call starts a fresh shell — `module load`, `conda activate`, `export`, `cd` all reset. Always chain everything needed in a single command:
```bash
module purge && module load CUDA/12.1.1 Miniforge3/24.11.3-0 2>&1 && source activate /home/$USER/envs/my_env && python script.py
```
Do NOT run `module load` in one Bash call and then `python` in another — the module will not be loaded.
The only exception: if the user activated a conda env before launching `claude`, that env is inherited for the whole session.

### Environment management — finding packages before creating envs

**Before creating a new env or hunting through existing ones, check Sapelo2 modules first:**

```bash
# Many common packages are bundled in existing modules
module avail Biopython          # → Biopython/1.83-foss-2023a
module avail SciPy-bundle       # → includes numpy, scipy, pandas, etc.
module spider scikit-learn      # deep search across all toolchains
```

**Resolution order for Python dependencies:**
1. **Check Sapelo2 modules** — `module avail <pkg>` or `module spider <pkg>`. Common bundles: `SciPy-bundle` (numpy, scipy, pandas), `Biopython`, `matplotlib`, `scikit-learn`.
2. **If a module exists**, load it. Modules handle compiled dependencies (MKL, BLAS) correctly and avoid rebuilding wheels.
3. **If no module exists**, create a minimal per-project venv: `ml Miniforge3/24.11.3-0 && conda create -p /home/$USER/envs/<project>_<task> python=3.11 <pkg1> <pkg2>`.
4. **Never cycle through old envs** hoping one has the right packages — this wastes time and is fragile.
5. **One env per project or per independent task** is the target. Shared "kitchen sink" envs rot.

---

## Parallelism — prefer many small jobs over few large ones

When a pipeline processes independent units (samples, haplotypes, chromosomes, models), **split them into separate sbatch jobs** rather than looping sequentially in one job. This:
- Runs faster by using multiple nodes simultaneously
- Makes partial failures cheaper to retry
- Uses cluster resources more efficiently (smaller jobs start sooner)

Examples of good splits:
- Per-haplotype: submit one job for hap1, another for hap2
- Per-sample: one job per sample rather than a loop
- Per-model: one extraction job per model (already done)

Use sbatch `--array` for many identical jobs differing only by index. Use `--dependency=afterok:ID` to chain steps that depend on prior output.

---

## sbatch template

```bash
#!/bin/bash
#SBATCH --job-name=my_job
#SBATCH --partition=batch
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=MYID@uga.edu

cd $SLURM_SUBMIT_DIR
module load STAR/2.7.10a-GCC-11.3.0

STAR --runThreadN $SLURM_CPUS_PER_TASK \
     --genomeDir /scratch/MYID/genome \
     --readFilesIn sample_R1.fastq.gz sample_R2.fastq.gz \
     --readFilesCommand zcat \
     --outSAMtype BAM SortedByCoordinate \
     --outFileNamePrefix /scratch/MYID/aligned/sample_
```

Use `$SLURM_CPUS_PER_TASK` for thread counts — reads from the header automatically.
After test runs: `seff <jobID>` to check actual memory/CPU usage and tune next submission.

### Check availability and tune resources before every submission

**Before submitting any sbatch job or suggesting `interact` parameters**, always:

1. **Check what's available:**
```bash
# Per-node GPU/CPU/memory availability
sinfo -p gpu_p -N -o "%N %G %C %e %T"

# Quick partition summary (all partitions)
sinfo -o "%P %a %D %T %C"
```

2. **Tune the resource request to match:**
- **GPU type**: Pick the cheapest GPU that fits. If the model needs <24GB VRAM, use L4 (24GB) instead of A100 (80GB). If L4 nodes are idle and A100s are busy, this avoids unnecessary queuing.
- **Memory**: Request what the job actually needs, not a round "safe" number. Check smoke test or `seff` from prior runs.
- **CPUs**: Match to what's free on target nodes — requesting 8 CPUs on a node with only 4 free causes queue wait.
- **Time**: Estimate from test runs, don't over-request. Shorter jobs are scheduled faster.

3. **Right-size GPU for common workloads:**

| Workload | VRAM needed | Minimum GPU |
|----------|-------------|-------------|
| ESM-2 650M embeddings | ~3 GB | L4 (24GB) |
| ESM-2 3B embeddings | ~12 GB | L4 (24GB) |
| ESMFold 3B (short seqs <500aa) | ~14 GB | L4 (24GB) |
| ESMFold 3B (long seqs >500aa) | ~30+ GB | A100 (80GB) |
| Foldseek ProstT5 createdb | ~8 GB | L4 (24GB) |
| AlphaFold2 | ~40 GB | A100 (80GB) |

This is not optional — every submission must be preceded by an availability check and resource adjustment. Over-requesting wastes queue priority and blocks other users.

### Partition and QOS reference (queried from Slurm, 2026-04-07)

Per-user limits come from QOS, not the partition itself. Always check both.

| Partition | QOS | Max Time | Max Running | Max Submitted | Notes |
|---|---|---|---|---|---|
| `batch` | batch_qos | 7 days | 50 | 10,000 | Default CPU partition; 326 nodes, 30k CPUs |
| `batch_30d` | batch_30d_qos | 30 days | 1 | 2 | Same nodes as batch |
| `gpu_p` | gpu_qos | 7 days | **8** | 20 | 43 nodes, 160 GPUs. Specify type: `--gres=gpu:A100:1` or `H100`, `L4`, `L40S`, `P100` |
| `gpu_p` (L4) | gpu_l4_qos | — | **4** | — | Separate cap on L4 jobs specifically |
| `gpu_30d_p` | gpu_30d_qos | 30 days | 2 | 2 | Subset of gpu_p nodes (19 nodes, 64 GPUs) |
| `highmem_p` | highmem_qos | 7 days | 6 | 100 | 24 nodes, ~800GB RAM/node |
| `hugemem_p` | hugemem_qos | 7 days | 4 | 4 | 5 nodes, up to 3TB RAM |
| `inter_p` | inter_qos | 2 days | 3 | 20 | Interactive only — do not sbatch |
| `iob_p` | iob_p_qos | 30 days | 10 | — | IOB buy-in; 22 nodes, 128 cores each. User has access via YOURLAB |
| `scavenge_p` | scavenge_qos | **4 hours** | 25 | — | **Open to all users.** Runs on idle buy-in nodes (including some GPUs). Jobs can be **preempted (killed) without warning** if the owning lab needs their nodes. Good for quick tests; bad for anything you can't restart. |

### GPU hardware on gpu_p

| GPU type | VRAM | Nodes | GPUs/node | Notes |
|----------|------|-------|-----------|-------|
| A100-SXM4-80GB | 80 GB | ~16 (b6-b8, ra4) | 4 | Best for large models (AlphaFold, ESMFold long seqs) |
| H100 | 80 GB | ~8 (ra5, ra7, ra8) | 4 | Fastest; often busy |
| L4 | 24 GB | ~10 (ra5, ra7, ra8) | 4 | Sufficient for most ML inference; often **idle** |
| L40S | 48 GB | ~1 (rb7) | 4 | Good middle ground |
| V100S | 32 GB | 1 (a1-24) | 1 | Older; single GPU |
| P100 | 16 GB | 2 (c5-22/23) | 1 | Oldest; fine for small models |

### Key scheduling insights

- **gpu_p max 8 running jobs** — count your active GPU jobs before submitting more
- **L4 cap is 4 running** — if you have 4 L4 jobs, the 5th queues even if L4 nodes are idle
- **scavenge_p** lets you burst onto buy-in hardware for free, ≤4h, but jobs get killed on preemption — use for smoke tests, not production
- **Default mem is only 100MB/CPU** — always specify `--mem` explicitly
- Shorter and smaller jobs start faster — right-size everything
- Use `sacctmgr show qos format=Name,MaxWall,MaxSubmitPU,MaxJobsPU` to verify current limits

---

## Authentication

Sapelo2 can't open a browser for OAuth. Use API key in `~/.bashrc`:
```bash
export ANTHROPIC_API_KEY=sk-ant-...
```

---

## Session architecture & recovery

```
local  →  ssh  →  login node  →  interact  →  compute node  →  claude
                                                                  │
                                                                  └─ sbatch  →  batch compute
```

- VPN: only if off-campus.
- `interact`: request resources for the whole session — long time, large memory, GPU if compiling interactively.
- No venv activation needed before `claude`; envs get activated inline in bash calls or in sbatch headers.
- Claude launches and manages `sbatch` jobs from inside the interact session, tuning resources against `sinfo` in real time.
- `tmux` is optional. Useful for splits or covering SSH drops (start it on the login node *before* `interact`), but won't save a Claude session from `interact` walltime expiry.

**Claude session lifetime = `interact` walltime.** Pick walltime covering what you want to do. Long jobs belong in `sbatch`, not a live Claude session.

### Reconnecting after an SSH drop

Only works if you started `tmux` on the login node *before* `interact`:

```bash
ssh sapelo2
tmux attach -t <session>
squeue -j <JOBID>          # confirm the interact job is still alive
```

Otherwise the pty hangup killed the interact job when the SSH connection died — start over.

### If the terminal freezes ("sock-hopping" / unresponsive)

A subprocess may hang and grab the pty. From a fresh SSH session:

```bash
tmux attach -t <session>                              # try plain attach
tmux kill-pane -t <session>:<window>.<pane>           # if still frozen
claude --resume                                        # pick up last checkpoint
```

### Effort level — match to task

`/effort low|medium|high|max` sets reasoning depth. Defaults are wasteful.

- `low` / `medium` — file reads, `squeue` polling, routine edits, job monitoring
- `high` — new script generation, non-trivial debugging, resource tuning
- `max` — architecture decisions, tricky ML failures, multi-step planning across tools

Opus + `max` on `ls` burns money for no upside.

### Login node memory — VS Code gotcha

If GACRC emails you about login-node memory, **check VS Code Remote SSH first**, not Claude. VS Code's language servers (pylance, node, etc.) run persistently on the login node even when the editor looks idle.

```bash
ps aux | grep $USER | grep vscode
```

Claude Code itself is lightweight on the login node — the bash tool spawns short-lived subprocesses and doesn't hold memory between calls.

---

## Claude self-monitoring checklist

**Before running any command:**
- Am I on the login node? (`hostname` → `ss-sub*` = stop, `c4-*` = ok)
- Is output going to `/scratch/MYID/`, not `/home`?
- Will this take >30 seconds or >16GB? → write an `sbatch` script instead

**Never:**
- Run `interact`, `srun --pty`, `qlogin` — no pty support, always fails
- Auto-submit `sbatch` scripts without showing the user the script first
- Run `rm -rf` without an explicit user instruction with the exact path
- Access `/project/YOURLAB` from a compute node — xfer node only
- Use `--dangerously-skip-permissions` — `/scratch` has no recycle bin
- Use `conda activate` in sbatch scripts — always `source activate`
- Guess module versions — always verify with `module avail <name>` first

**Monitoring commands:**
```bash
sq --me                    # your running/pending jobs (nicer than squeue)
seff <jobID>               # resource usage after job completes
sacct-gacrc                # detailed job accounting
sinfo-gacrc                # cluster availability per node
scancel <jobID>            # cancel a job
```

### Post-submission job health check (MANDATORY)

**After every `sbatch` submission**, wait ~15–30 seconds then verify the job is actually running and not immediately failing. Many errors (wrong module version, conda init, missing files) cause instant failure that can be caught and fixed right away.

```bash
# 1. Check job is still running (not already gone from queue)
squeue -j <JOBID> -o "%j %T %M %R"

# 2. If job already disappeared, check exit status
seff <JOBID>

# 3. If FAILED, read the .err file for the cause
tail -20 <jobname>_<JOBID>.err

# 4. Fix the issue and resubmit
```

**Common instant-failure causes to check for before submitting:**
- Wrong module version → run `module avail <name>` to verify
- `conda activate` instead of `source activate` in sbatch
- Missing input files → verify paths exist
- Missing Python packages → test imports in the target env first
- Typo in partition/QOS name

**Best practices for sbatch Python scripts:**
- Add `export PYTHONUNBUFFERED=1` so stdout appears in .out files in real time (Python buffers by default in non-interactive mode, making health checks useless)
- Test the critical import chain before submitting: `source activate <env> && python -c "import pkg1, pkg2"`

Do NOT move on to other work after submitting without confirming the job is healthy. The user should not have to discover failed jobs themselves.

### Background job monitoring (timer pattern)

For jobs that will finish in a few minutes to an hour, use `run_in_background` with `sleep` to set up automatic check-ins. This lets the user continue interacting while Claude monitors jobs asynchronously.

```bash
# Set a background timer to check job status in N seconds
sleep 300 && squeue -j <JOBID> -o "%j %T %M %R" && \
  tail -5 /scratch/MYID/ms1_cis_regulatory/logs/<jobname>_<JOBID>.out
```

**When to use:**
- After submitting sbatch jobs that should finish within the session (~minutes to ~1 hour)
- When waiting for multiple jobs to complete before a next step
- When the user wants to continue other work while jobs run

**How it works:**
- Use `run_in_background: true` on a Bash call with `sleep N` followed by status checks
- Claude gets notified automatically when the timer fires — no polling needed
- Report results to the user and set another timer if jobs are still running
- Make timer duration **dynamic based on estimated remaining time**:
  - Read the job's progress from .out (e.g., "6000/32137 sequences") and compute rate
  - Estimate time remaining and set timer to ~80% of that (check slightly before expected completion)
  - Example: 6000/32137 done in 10 min → rate ~600/min → ~43 min remaining → set timer for 35 min
  - For unknown durations: start with 2 min (health check), then 5 min, then 10 min, escalating
- After each timer fires: if job still running, estimate new remaining time and set next timer accordingly

**Do NOT:**
- Use fixed durations when progress data is available — estimate from the rate
- Use this for jobs that will run for hours — suggest the user check back later instead
- Set multiple overlapping timers for the same job
- Forget to report the results when the timer fires

---

## Sanity checks for ML/embedding pipelines

Before committing to full production runs, always validate that the pipeline produces sensible output. A quick sanity check catches bugs that waste hours of GPU time.

**Embedding extraction sanity checks:**
1. **Shape check**: Does the output have the expected (n_genes, dim) shape? Wrong shapes indicate pooling bugs (e.g., returning per-token instead of per-gene embeddings).
2. **Pairwise correlation**: Random gene pairs should NOT have correlation >0.95. If they do, the embeddings are degenerate — investigate pooling strategy, model loading, or tokenization before running more jobs.
3. **Dead dimensions**: Check `emb.var(axis=0)` — if most dimensions have near-zero variance, the model's representation is collapsing. This is common with SSM models (Mamba/Caduceus) under mean pooling.
4. **Effective dimensionality**: Use PCA to check how many components capture 90% of variance. If 90% is in <5% of dimensions, the embeddings are highly anisotropic.

**When to run sanity checks:**
- After every new model/pooling combination before submitting full extraction
- After code changes to the extraction pipeline
- When correlations or downstream AUC look suspicious

**Quick diagnostic (runs on CPU, no GPU needed):**
```python
import numpy as np
d = np.load("embeddings_model_region_hap.npz")
emb = d["embeddings"].astype(np.float32)
print(f"Shape: {emb.shape}")
print(f"Dead dims: {(emb.var(axis=0) < 1e-6).sum()}/{emb.shape[1]}")
rng = np.random.RandomState(42)
sub = emb[rng.choice(len(emb), 100, replace=False)]
corr = np.corrcoef(sub)
off = corr[np.triu_indices_from(corr, k=1)]
print(f"Mean pairwise corr: {off.mean():.4f}")
```

---

## Pipeline script design — reuse and resilience

When writing scripts for multi-step pipelines, follow these patterns:

### Reuse existing intermediate outputs
Before requesting GPU/compute for a step, check if prior phases already produced the needed files. Example: if ESMFold PDBs exist from a prediction phase, a downstream validation step should use them directly (CPU-only) rather than re-predicting (GPU). This can change the resource profile entirely (e.g., gpu_p → batch).

**Before writing a new script, always ask:**
- What intermediate files already exist from prior phases?
- Can this step run without the expensive resource (GPU, high memory) by reusing cached results?
- Which partition/resource class does this actually need?

### Resume support for long-running batch scripts
Any script processing >100 items should support resuming from where it left off:
- Write results incrementally (flush after each item)
- On startup, scan the output file for already-completed items and skip them
- This makes interrupted jobs cheap to restart without reprocessing

```python
# Pattern: check for resume
done_queries = set()
if summary_path.exists():
    with open(summary_path) as f:
        next(f)  # skip header
        for line in f:
            done_queries.add(line.split("\t")[0])
    print(f"Resuming: {len(done_queries)} already processed")
```

### Batch external I/O with parallelism
When downloading many files (PDB structures, reference data), use ThreadPoolExecutor for parallel downloads rather than sequential wget. Cache downloads to avoid re-fetching on resume.

### Progress reporting for monitoring
Print progress at regular intervals (every 50–100 items) with rate estimates so background timers can gauge remaining time. Always use `PYTHONUNBUFFERED=1`.

---

## Permissions (pre-approve safe commands)

Save as `.claude/settings.json` in project root to reduce prompt fatigue
without reaching for `--dangerously-skip-permissions`:

```json
{
  "permissions": {
    "allow": [
      "Bash(sbatch:*)",
      "Bash(squeue:*)",
      "Bash(sq:*)",
      "Bash(seff:*)",
      "Bash(sacct*:*)",
      "Bash(sinfo*:*)",
      "Bash(scancel:*)",
      "Bash(module:*)",
      "Bash(conda:*)",
      "Bash(git:*)",
      "Bash(ls:*)",
      "Bash(du:*)",
      "Bash(cat:*)",
      "Bash(head:*)",
      "Bash(tail:*)",
      "Bash(grep:*)",
      "Bash(find:*)"
    ]
  }
}
```

---

## Project context (fill in for your own work)

Replace this section with your own project's conda env, scratch/work paths,
tools, and per-step resource estimates. Example:

```
Conda env:    conda activate <your-env>
Scratch:      /scratch/MYID/<project>/
Scripts:      /home/MYID/scripts/
Reference:    /work/YOURLAB/  (verify paths with PI)
Tools:        <list the tools you actually use>
```

Typical resource estimates (one row per pipeline step):

| Step | Cores | Memory | Partition |
|---|---|---|---|
| Example: genome index build | 8 | 32–64 GB | `batch` or `highmem_p` |
| Example: per-sample alignment | 8 | 32 GB | `batch` |

---

## GACRC help

- Wiki: https://wiki.gacrc.uga.edu
- Email: gacrc@uga.edu
- Do not contact GACRC on the user's behalf — they verify identity directly.
