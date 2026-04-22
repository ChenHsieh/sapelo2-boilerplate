# Getting started

Minimum to get a first job running on Sapelo2. See [tips & tricks](advanced.md) once you're past the basics.

## Login node etiquette

You SSH in and land on a login node (prompt: `MyID@ss-sub<N>`). Shared by everyone. Four things are OK here:

1. Text editing, writing job scripts
2. `sbatch`, `squeue`, `sacct`
3. Light file management (`ls`, `mkdir`, small `mv`/`rm`)
4. Git

Everything else goes to compute via `interact` or `sbatch`: Python/R/bash loops, bioinformatics tools, `conda install`, `tar`/`gzip` on large files, anything that takes more than a few seconds. GACRC will kill processes that abuse the login node; repeat offenders lose access.

## Storage

| Path | Quota | Backed up | Purged | Use for |
|---|---|---|---|---|
| `/home/$USER` | 200 GB | daily, 14 d | No | Scripts, envs, configs |
| `/scratch/$USER` | — | No | **30 d** | Active job I/O |
| `/work/<lab>` | 500 GB, 100k files | No | No | Shared references |
| `/project/<lab>` | 1 TB | Yes | No | Archive — xfer node only |
| `/lscratch` | 210–800 GB | No | Job end | Fast node-local |

Workflow:

1. Scripts and envs in `/home`.
2. Copy inputs to `/scratch`; run jobs from `/scratch`.
3. Results to `/work` (shared) or `/project` (via xfer); delete intermediates.
4. Archive out of GACRC when the project's done.

## Getting compute: `interact`

One command that gives you a compute-node shell. Request generously for the session — long time, enough memory, a GPU if you need to compile or test something interactively:

```bash
interact -c 16 --mem=64G --time=12:00:00                     # CPU session
interact -c 8 --mem=32G --time=8:00:00 --gres=gpu:L4:1       # with GPU for compile/test
interact -c 4 --mem=16G --time=2:00:00 --constraint=Milan    # specific CPU arch
```

`interact` echoes the underlying `srun` command — copy it into sbatch headers when you later batchify the same work.

Prompt changes from `MyID@ss-sub<N>` → `MyID@ra3-22` (or similar). That's your signal you're on compute.

Always `exit` when you're done. Idle interactive jobs hold resources that other users are waiting for.

## Submitting batch jobs with `sbatch`

For anything taking >1h, needing >16G, running unattended, or part of a pipeline. Minimal template:

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
#SBATCH --mail-user=MyID@uga.edu

cd "$SLURM_SUBMIT_DIR"
module load <versioned module name>

# ... your work ...
```

Submit: `sbatch run.sh`. Check: `squeue --me` (or `sq --me`). After: `seff <jobID>` shows actual CPU/memory usage — tune the next submission from real numbers.

Use full versioned module names (`STAR/2.7.10a-GCC-11.3.0`), not bare `STAR` — defaults change when GACRC adds newer versions.

## Partitions at a glance

| Partition | Max time | For |
|---|---|---|
| `batch` | 7 d | Default |
| `highmem_p` | 7 d | Up to ~950 G RAM |
| `gpu_p` | 7 d | `--gres=gpu:A100:1` / `H100` / `L4` / `P100` |
| `inter_p` | 2 d | Interactive only — don't `sbatch` here |

30-day variants exist for each (`batch-30d`, `highmem_30d_p`, `gpu_30d_p`) with a 2-job cap per user.

## Getting help

- Wiki: <https://wiki.gacrc.uga.edu>
- Email: <gacrc@uga.edu>
- They'd rather answer a question than clean up a rogue login-node process.

---

Next: [tips & tricks](advanced.md) — array jobs, resource tuning, `/lscratch` staging, shell setup, SSH client choice.
