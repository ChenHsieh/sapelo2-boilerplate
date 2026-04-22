# Sail through Sapelo2

*Originally 2021 · rewritten 2026.*

A practical guide for UGA's HPC cluster. First-timer: read through. Returning: jump to what changed.

## What's changed since 2021

- `qlogin` → `interact` (old name still aliases).
- `squeue --me` and the `sq --me` wrapper for your own jobs.
- New partitions: `hugemem_p` (3 TB RAM), 30-day variants (`batch-30d`, `highmem_30d_p`, `gpu_30d_p`).
- New hardware: AMD EPYC Genoa (128c/764G), Milan nodes in `batch`, H100 + L4 GPUs.
- Home quota: 200 GB (was 100 GB). Home snapshots kept 14 days.
- Open OnDemand: `ondemand.gacrc.uga.edu` — Jupyter, RStudio, desktops, files, all in-browser.
- The 2021 post said scratch purged at 90 days. Wrong. It's 30 days, always was.

## Login node etiquette

You SSH in and land on a login node (prompt: `MyID@ss-sub<N>`). Shared by everyone. Four things are OK here:

1. Text editing, writing job scripts
2. `sbatch`, `squeue`, `sacct`
3. Light file management
4. Git

Everything else goes to compute: Python/R/bash scripts with real loops, bioinformatics tools, `conda install`, `tar`/`gzip` on large files, anything >few seconds. GACRC will kill processes that abuse login; repeat offenders lose access.

Fix: run `interact` before doing real work.

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
2. Copy inputs to `/scratch`; run from `/scratch`.
3. Results to `/work` (shared) or `/project` (via xfer); delete intermediates.
4. Archive out of GACRC when done.

Learned the hard way:
- Scratch fills faster than you expect. `du -sh /scratch/$USER` weekly. GACRC lists your purgeable files at `/usr/local/var/lustre_stats/$USER.over30d.files.lst`.
- `/work` has a 100k file cap — this is the surprise quota. Tarball what you don't read often.
- `/project` is xfer-node-only. Not mountable on compute. Stage to `/scratch` before submitting.
- Big transfers: use xfer nodes + Globus. Don't go through `remote.uga.edu` VPN (bandwidth cap).

## Getting compute: `interact`

```bash
interact                                 # 1c, 2G, 12h
interact -c 8 --mem=16G
interact -c 4 --mem=8G --time=4:00:00
interact --constraint=Milan -p batch
interact -p gpu_p --gres=gpu:A100:1 --mem=50G
interact --x11                           # X forwarding
```

`interact` echoes the underlying `srun` — useful for copying into sbatch scripts.

Prompt changes to `MyID@ra3-22` (or similar). That's your signal.

Always `exit` when done — idle interactive jobs block other users.

Start `tmux` before `interact`. If SSH drops, your session survives:

```bash
tmux new -s work
interact -c 8 --mem=16G
# Ctrl-B D to detach; tmux attach -t work to return
```

## sbatch

Use `sbatch` for: >1h jobs, >16G RAM, unattended runs, pipeline steps.

| Partition | Max time | Notes |
|---|---|---|
| `batch` | 7 d | Default |
| `batch-30d` | 30 d | 2 jobs/user cap |
| `highmem_p` | 7 d | ~950 GB |
| `hugemem_p` | 7 d | 3 TB — only when needed |
| `gpu_p` | 7 d | `--gres=gpu:A100:1` / H100 / L4 / P100 |
| `inter_p` | 2 d | Interactive only — don't sbatch |

Template:

```bash
#!/bin/bash
#SBATCH --job-name=star_align
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
module load STAR/2.7.10a-GCC-11.3.0

STAR \
  --runThreadN "$SLURM_CPUS_PER_TASK" \
  --genomeDir /scratch/"$USER"/genome_index \
  --readFilesIn sample_R1.fastq.gz sample_R2.fastq.gz \
  --readFilesCommand zcat \
  --outSAMtype BAM SortedByCoordinate \
  --outFileNamePrefix /scratch/"$USER"/aligned/sample_
```

`$SLURM_CPUS_PER_TASK` pulls thread count from the header — update in one place.

After a run: `seff <jobID>` shows actual vs requested CPU/memory. Over-requesting memory is the most common waste — it makes jobs wait longer because the scheduler needs a node with enough free RAM.

Array jobs for sample batches:

```bash
#SBATCH --array=1-20
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)
```

Chain jobs with dependencies:

```bash
JOB1=$(sbatch align.sh | awk '{print $4}')
sbatch --dependency=afterok:$JOB1 count.sh
```

## Claude Code on Sapelo2

Claude Code runs shell commands on whatever node your terminal is on. Which means: if you start it on the login node, it runs on the login node. Problem.

Install (no root, no Node):

```bash
curl -fsSL https://claude.ai/install.sh | bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Auth — login nodes can't do OAuth, use API key:

```bash
echo 'export ANTHROPIC_API_KEY=sk-ant-...' >> ~/.bashrc
source ~/.bashrc
```

(Separate from Claude Pro/Max. Billed by usage. Key from [console.anthropic.com](https://console.anthropic.com).)

Right workflow — always inside `interact` + `tmux`:

```bash
tmux new -s claude
interact -c 8 --mem=16G
module load Miniforge3/24.11.3-0
source activate my_env
cd /scratch/"$USER"/project
claude
```

Now every command Claude runs hits the compute node. SSH drop? `tmux attach -t claude` to recover.

Good for: writing/debugging sbatch, generating pipeline boilerplate, explaining job failures, refactoring analysis scripts, writing CLAUDE.md.

Watch out for:

- Starts on whatever node you're on. Check the prompt first.
- Doesn't know cluster load or your resource budget — review generated sbatch before submitting.
- Doesn't know your `/scratch` unless you tell it.
- Token cost: don't paste 10k-line logs. `grep`/`tail` first.

Keep a `CLAUDE.md` in project root — tells Claude about your env once so you don't repeat it every session. See the [Claude Code setup](claude-code/index.md) for a full ruleset.

## Tips

**Cluster load:** `sinfo-gacrc` shows per-node CPU/mem/GPU state. [NodeStat](https://github.com/pbasting/nodestat) is a nicer summary.

**Shell setup:** `tmux new -s <name>` before every interactive session. Oh-my-bash for prompt and color.

**Snippets / aliases:**

```bash
alias myq='sq --me'
alias scratch='cd /scratch/$USER'
alias interact8='interact -c 8 --mem=16G --time=8:00:00'
```

**Versioned modules in scripts** — defaults change when GACRC adds versions:

```bash
module load R/4.3.1-foss-2022a   # good
module load R                     # brittle
```

**Recovering deleted `/home` files:**

```bash
ls /home/.zfs/snapshot/
cd /home/.zfs/snapshot/zrepl_YYYYMMDD_HHMMSS_000/MyID/
```

**Big transfers:** use Globus. Resumable, fast, background.

**`scavenge_p` is free speedup.** Short (<4h) `batch` jobs auto-route to idle buy-in nodes. Don't pad time limits to game it — GACRC notices.

## Getting help

GACRC: [gacrc@uga.edu](mailto:gacrc@uga.edu) · ticket portal · [wiki](https://wiki.gacrc.uga.edu). They'd rather answer a question than clean up a rogue login node.
