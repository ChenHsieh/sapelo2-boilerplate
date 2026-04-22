# Tips & tricks

Stuff you pick up after the first few weeks. Prerequisites: [basics](index.md).

## What's changed since the 2021 version of this guide

- `qlogin` → `interact` (old name still aliases).
- `squeue --me` / `sq --me` wrapper for your own jobs.
- New partitions: `hugemem_p` (3 TB RAM), 30-day variants.
- New hardware: AMD EPYC Genoa (128c/764G), Milan nodes in `batch`, H100 + L4 GPUs.
- Home quota 200 G (was 100 G); home snapshots 14 days.
- Open OnDemand: `ondemand.gacrc.uga.edu` — Jupyter, RStudio, desktops, files in-browser.
- The 2021 post said scratch purged at 90 days. Wrong; it's 30 days, always was.

## Array jobs for batches

Same pipeline across many samples — use `--array` instead of submitting N scripts:

```bash
#SBATCH --array=1-20
#SBATCH --output=array_%A_%a.out

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)
# ... pipeline on $SAMPLE ...
```

## Chained jobs

```bash
JOB1=$(sbatch align.sh | awk '{print $4}')
sbatch --dependency=afterok:$JOB1 count.sh
```

## Resource tuning with `seff`

After a test run:

```
Memory Utilized: 18.2 GB
Memory Efficiency: 56.9%    ← asked for 32G, used 18G → request ~22G next time
```

Over-requesting memory is the most common waste — the scheduler has to find a node with that much free, so your job waits longer. Tune from real numbers.

Use `$SLURM_CPUS_PER_TASK` in your commands so thread count stays in sync with the header:

```bash
aligner --threads "$SLURM_CPUS_PER_TASK" ...
```

## `/lscratch` staging

For I/O-bound single-node jobs, staging inputs onto the node's local disk can halve wall-time:

```bash
#SBATCH --gres=lscratch:200       # reserve 200 GB

STAGE=/lscratch/$SLURM_JOB_ID
OUT=/scratch/$USER/results

cp /work/<lab>/genome/* "$STAGE/"
cd "$STAGE"
aligner --ref "$STAGE/genome.fa" -o "$STAGE/out.bam"
cp "$STAGE/out.bam" "$OUT/"       # copy back before the job exits
```

`/lscratch` disappears at job end — always copy results out.

## `scavenge_p` is free speedup

Short (<4 h) jobs in `batch` may auto-route to idle buy-in nodes via `scavenge_p` — reduces wait time when `batch` is busy. Don't pad time limits to game this; GACRC notices the pattern.

## Recovering deleted `/home` files

Daily snapshots live at `/home/.zfs/snapshot/`, accessible from xfer or compute nodes:

```bash
ls /home/.zfs/snapshot/
cd /home/.zfs/snapshot/zrepl_YYYYMMDD_HHMMSS_000/MyID/
cp accidentally-deleted-file /home/MyID/
```

Daily go back 14 days; older → GACRC ticket.

## Big transfers — use Globus

Anything over a few GB: <https://app.globus.org>. Resumable, fast, runs in the background. Works from the xfer node. Don't use the `remote.uga.edu` VPN for transfers — it has a bandwidth cap.

## Cluster load

```bash
sinfo-gacrc                # per-node CPU/mem/GPU state
sinfo-gacrc 40 50          # wider columns
```

[NodeStat](https://github.com/pbasting/nodestat) for a cleaner summary of idle resources by partition.

## Shell setup

- `sq --me` (alias for `squeue --me`) — your jobs
- `sinfo-gacrc`, `sacct-gacrc`, `seff` — job inspection
- `tmux` for window splits; start it on the login node *before* `interact` if you want to cover SSH drops. Not a fault-tolerance layer for your Claude session — if `interact` walltime expires, tmux doesn't help.

Useful aliases:

```bash
alias myq='sq --me'
alias scratch='cd /scratch/$USER'
alias interact8='interact -c 8 --mem=16G --time=8:00:00'
```

## SSH clients — prefer a plain terminal

Skip VS Code Remote SSH if you can. Two reasons:

1. **Memory**: VS Code's remote server runs persistent language servers (pylance, node) on the login node. Invisible to you, very visible to GACRC. Frequent cause of login-node memory warnings.
2. **Control**: running Claude inside VS Code's agent mode hides tool calls behind UI chrome. The CLI shows every bash invocation, every file read, every decision point. More signal, less guessing.

A plain terminal (Terminal.app, iTerm2, Alacritty, WezTerm, Ghostty) is lighter and gives you full visibility. Use `tmux` for splits if you miss the multi-pane layout.

Termius is fine if you need mobile SSH or cross-device snippet sync. Open OnDemand covers Jupyter/RStudio in-browser without any SSH client.
