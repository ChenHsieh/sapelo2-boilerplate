# Sail through Sapelo2 (2026 Edition)

*Updated March 2026 · Originally published October 2021 · ~12 min read*

*Tags: HPC · bioinformatics · PhD · tips · UGA · AI tools*

---

A lot has changed since I wrote the first version of this post in 2021 — new hardware, new partitions, the `qlogin` → `interact` rename, and now AI coding tools like Claude Code that can actually run commands on the cluster on your behalf. This edition rewrites the guide from scratch with everything I've learned since then, and adds a section on how to use Claude Code responsibly on a shared HPC.

If you're a first-timer, read straight through. If you're a returning user upgrading your mental model, jump to the sections that changed.

---

## Table of Contents

1. [What's changed since 2021](#whats-changed-since-2021)
2. [SSH clients: picking your weapon](#ssh-clients-picking-your-weapon)
3. [The Golden Rule: login node etiquette](#the-golden-rule-login-node-etiquette)
4. [Storage: five filesystems, one brain to keep them straight](#storage-five-filesystems-one-brain-to-keep-them-straight)
5. [Getting compute: interact (née qlogin)](#getting-compute-interact-née-qlogin)
6. [Submitting batch jobs with Slurm](#submitting-batch-jobs-with-slurm)
7. [New: using Claude Code on the HPC](#new-using-claude-code-on-the-hpc)
8. [Tips & tricks](#tips--tricks)

---

## What's changed since 2021

A quick diff for people who already know the cluster:

**Renamed commands:**
- `qlogin` → **`interact`** (the old name still works as an alias, but the official command is now `interact`)
- `squeue --me` replaced `squeue -u $USER` as the idiomatic way to check your own jobs
- `sq --me` is a GACRC-configured wrapper with nicer output

**New partitions:**
- `hugemem_p` and `hugemem_30d_p` for jobs needing up to **3TB of RAM** (yes, that's a node with 48 cores and 3TB)
- `scavenge_p` — you can't submit here directly, but short jobs in `batch` may get automatically routed to idle buy-in nodes, reducing your wait time
- `batch-30d`, `highmem_30d_p`, `gpu_30d_p` — 30-day variants for each major partition, with a 2-job cap per user

**New hardware:**
- AMD EPYC Genoa nodes (128-core, 764GB RAM) in `batch`
- NVIDIA H100 and L4 GPUs in `gpu_p` alongside the existing A100s and P100s
- Milan nodes with 128-core, 512GB RAM in `batch` (no longer only in `highmem_p`)

**Storage:**
- Home quota is now **200GB** (up from 100GB)
- Scratch purge is still **30 days** — this hasn't changed, but GACRC is more active about enforcement now
- Home snapshots are taken daily and kept for **14 days**; weekly/monthly go back 6 months (request via ticket)

**Open OnDemand (OOD):**
- GACRC now has a full web-based interface at `ondemand.gacrc.uga.edu` — Jupyter, RStudio, desktop environments, file browser, all in-browser. This is huge if you're not comfortable with the terminal or want to avoid X11 forwarding gymnastics.

**The 90-day → 30-day scratch misprint in my 2021 post:**
- I wrote "90 days" in the original post. The correct number has always been 30 days. Sorry about that. Double-checked against the current wiki.

---

## SSH clients: picking your weapon

The landscape has expanded but VS Code is still king for most researchers.

### VS Code + Remote-SSH (recommended)

The Remote-SSH extension turns VS Code into a full IDE pointed at the cluster. You get a file explorer, integrated terminal, syntax highlighting, and all your extensions — running remotely.

Setup: install the "Remote - SSH" extension, then `Cmd/Ctrl+Shift+P` → "Remote-SSH: Connect to Host" → `MyID@sapelo2.gacrc.uga.edu`.

One gotcha that bites people: VS Code runs its server process on the **login node**. This is fine for editing and file navigation. But your integrated terminal is also the login node shell, so the same rules apply — no heavy computation there. See the section on login node etiquette.

Connection dropping? Add to your local `~/.ssh/config`:

```
Host sapelo2.gacrc.uga.edu
    ServerAliveInterval 60
    ServerAliveCountMax 10
```

### Termius

Still great if you want an SSH client that works on your phone and has built-in snippet management. The GitHub Student Pack still includes a free Pro subscription. Good choice if you SSH from multiple devices or want snippet support without configuring a shell alias file.

### Open OnDemand (new since 2021)

If you just need a Jupyter notebook or an RStudio session, skip the SSH client entirely. OOD gives you everything in the browser. Especially useful for quick interactive analysis without setting up tunnels.

---

## The Golden Rule: login node etiquette

This is the thing that most gets new users in trouble and most annoys GACRC staff.

**When you SSH into Sapelo2, you land on a login node** (your prompt says `MyID@ss-sub<N>`). This node is shared by every user who SSHs in at the same time. It has modest resources and is meant for exactly four things:

1. Text editing
2. Writing and submitting job scripts
3. Light file management (`ls`, `du`, `mkdir`, `mv`, `rm` on small numbers of files)
4. Git operations

**Everything else goes on a compute node.** This includes:

- Running Python, R, Bash scripts with actual loops
- `module load` + running bioinformatics tools (STAR, kallisto, samtools, etc.)
- `conda install` with heavy dependency resolution
- `tar`, `gzip`, `pigz` on large archives
- Any command that takes more than a few seconds

GACRC staff will terminate processes that abuse the login node, and repeat offenders can lose access. Beyond the policy angle, hogging the login node makes everyone's experience worse — including yours, when someone else does it.

The fix is easy: **use `interact` before doing anything real.**

---

## Storage: five filesystems, one brain to keep them straight

Understanding when to use each filesystem is maybe the most important practical skill on Sapelo2.

| Path | Quota | Backed up | Purged | Use it for |
|---|---|---|---|---|
| `/home/MyID` | 200 GB | ✅ daily snapshots, 14 days | No | Scripts, conda envs, config, small databases |
| `/scratch/MyID` | No quota | ❌ | **30 days** | Active job I/O — your job's working directory |
| `/work/labname` | 500 GB, 100k files | ❌ | No | Shared reference data (genomes, annotation) |
| `/project/labname` | 1 TB | ✅ | No | Archive — **xfer node only**, not mountable on compute |
| `/lscratch` | ~210–800 GB/node | ❌ | Job end | Ultra-fast local disk for single-node I/O-heavy jobs |

The workflow GACRC recommends, and that I've found actually works:

1. Keep your scripts and environments in `/home`. They change slowly and you want them backed up.
2. Copy inputs to `/scratch` before a job runs. Run the job from `/scratch`.
3. When a job finishes, move results you want to keep to `/work` (shared reference data) or `/project` (via xfer). Delete intermediates from `/scratch` immediately.
4. Archive finished project data out of GACRC entirely (external drive, cloud storage, your institution's archival service).

**Things I've learned the hard way:**

Scratch fills up faster than you think once you have multiple running jobs. Get in the habit of running `du -sh /scratch/$USER` weekly. GACRC provides a list of your purgeable files at `/usr/local/var/lustre_stats/$USER.over30d.files.lst` — check it.

`/work` has a 100,000 file limit — this is the quota that surprises people. If your reference genome + annotation + index adds up to 50,000 files, you're closer to the edge than you think. Tarballing things you don't need to access frequently helps.

`/project` is **only accessible from the transfer node** (`xfer.gacrc.uga.edu`). You cannot read from it inside a running job. Plan around this — copy what you need to `/scratch` before submitting.

When doing bulk data transfers, use the transfer node and preferably **Globus** (browser-based, resumable, fast). And don't use the `remote.uga.edu` VPN for transfers — it has a bandwidth cap. The transfer nodes are accessible without VPN from off-campus.

---

## Getting compute: interact (née qlogin)

The `qlogin` command from the 2021 post has been replaced by `interact`. The old name still works as an alias, but `interact` is the canonical command now and it has a much nicer interface.

```bash
# Minimal interactive session (1 core, 2GB, 12 hours)
interact

# With more resources
interact -c 8 --mem=16G

# Specify time limit
interact -c 4 --mem=8G --time=4:00:00

# On a specific processor type
interact --constraint=Milan -p batch

# With a GPU (for testing GPU code interactively)
interact -p gpu_p --gres=gpu:A100:1 --mem=50G

# With X forwarding (for GUI apps)
interact --x11
```

When you run `interact`, it echoes the underlying `srun` command — useful for writing batch scripts based on what actually worked interactively.

Your prompt changes from `MyID@ss-sub<N>` (login node) to `MyID@ra3-22` or similar (compute node). That's your signal that you're on compute and can do real work.

**Always exit when you're done.** Type `exit` or `Ctrl-D`. Interactive jobs hold resources even when you're not actively doing anything, which makes other people wait longer.

**Run inside tmux.** If your SSH connection drops, your interactive session dies with it. Starting `tmux` before `interact` means you can reconnect and re-attach without losing your state.

```bash
tmux new -s work    # start named session
interact -c 8 --mem=16G
# ... do stuff ...
# Ctrl-B D to detach (keeps running)
# tmux attach -t work to get back in
```

---

## Submitting batch jobs with Slurm

Use `sbatch` for anything that:
- Takes more than ~1 hour
- Needs more than ~16GB RAM
- You want to run unattended (overnight, over the weekend)
- Is part of an automated pipeline

### Partition cheat sheet

| Partition | Max time | Notes |
|---|---|---|
| `batch` | 7 days | Default for most work |
| `batch-30d` | 30 days | Max 2 jobs/user (1 running + 1 pending) |
| `highmem_p` | 7 days | Up to ~950GB RAM |
| `hugemem_p` | 7 days | Up to 3TB RAM — use only when necessary |
| `gpu_p` | 7 days | Specify GPU type: A100, H100, L4, P100 |
| `inter_p` | 2 days | Interactive only, don't sbatch here |

### A bioinformatics-flavored template

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

cd $SLURM_SUBMIT_DIR

module load STAR/2.7.10a-GCC-11.3.0

STAR \
  --runThreadN $SLURM_CPUS_PER_TASK \
  --genomeDir /scratch/$USER/genome_index \
  --readFilesIn sample_R1.fastq.gz sample_R2.fastq.gz \
  --readFilesCommand zcat \
  --outSAMtype BAM SortedByCoordinate \
  --outFileNamePrefix /scratch/$USER/aligned/sample_
```

Note `$SLURM_CPUS_PER_TASK` — this pulls the core count from the job header so you never have to update it in two places. Many tools take a thread count argument; wire it to this variable.

### Tuning resources with seff

After a test run finishes, always check `seff <jobID>`. It shows you actual CPU and memory utilization vs. what you requested. Over-requesting memory is the most common waste — it makes your job wait longer to start because the scheduler has to find a node with enough free memory.

```bash
seff 123456
# Job ID: 123456
# Cores per node: 8
# CPU Utilized: 00:45:12
# CPU Efficiency: 92.3%
# Memory Utilized: 18.2 GB
# Memory Efficiency: 56.9%   ← you asked for 32GB, only used 18GB → request 22G next time
```

### Array jobs for batch sample processing

If you're running the same pipeline across 20 samples, use an array job instead of submitting 20 separate scripts:

```bash
#SBATCH --array=1-20
#SBATCH --output=array_%A_%a.out

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)
# ... run pipeline on $SAMPLE ...
```

### Job dependencies

Chain jobs so downstream steps start only after upstream ones finish:

```bash
JOB1=$(sbatch align.sh | awk '{print $4}')
sbatch --dependency=afterok:$JOB1 count.sh
```

---

## New: using Claude Code on the HPC

This section didn't exist in 2021 for obvious reasons. Claude Code is a CLI tool that lets you have an AI assistant that can actually read your files, write scripts, and run shell commands — all within your terminal session.

Using it on Sapelo2 requires some care, because Claude Code will execute commands on whatever node you're currently on. If you're on the login node, it'll run on the login node. That's a problem.

### Installing Claude Code on Sapelo2

The native installer works without root or Node.js:

```bash
curl -fsSL https://claude.ai/install.sh | bash
# Adds itself to ~/.local/bin — you may need to update your PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Authentication (headless — no browser needed)

Sapelo2 login nodes can't open a browser for OAuth. Use an API key instead:

```bash
echo 'export ANTHROPIC_API_KEY=sk-ant-...' >> ~/.bashrc
source ~/.bashrc
```

Get the key from [console.anthropic.com](https://console.anthropic.com). Note this is separate from your Claude Pro/Max subscription — API access is billed separately by usage.

### The right workflow: always inside interact + tmux

```bash
# From the login node:
tmux new -s claude                         # persistent session
interact -c 8 --mem=16G                    # get a compute node
module load Anaconda3/2023.03              # load what you need
conda activate my_env
cd /scratch/$USER/project
claude                                     # start Claude Code here
```

Now every command Claude runs — file reads, script executions, test runs — happens on the compute node, not the login node. If your SSH connection drops, `tmux attach -t claude` gets you back without losing Claude's context.

### What Claude Code is good for on HPC

- Writing and debugging sbatch scripts (give it your error logs, it'll fix the script)
- Generating boilerplate pipeline code (STAR → samtools → featureCounts wiring)
- Explaining error messages from failed jobs
- Refactoring messy analysis scripts
- Writing CLAUDE.md / documentation for your project

### What to watch out for

**It'll run commands you approve, on whatever node you're on.** If you forgot to `interact` first and start `claude` on the login node, anything it runs is on the login node. Check your prompt before starting a session.

**It won't automatically submit batch jobs.** Claude Code doesn't know the cluster's current load or your project's resource requirements. Always review any `sbatch` script it writes before submitting — especially the memory and time requests.

**It doesn't know what's in your `/scratch` unless you tell it.** Give it context: "I have BAM files in `/scratch/$USER/aligned/`" rather than assuming it will discover your filesystem.

**API calls cost tokens.** Pasting a 10,000-line log file into a Claude conversation will chew through your context and cost more API credits. Pipe logs through `grep` or `tail` to give it the relevant 20 lines instead.

A CLAUDE.md file in your project root is your friend — it lets you tell Claude about your environment, tools, and project layout once, so you don't have to repeat it every session.

---

## Tips & tricks

### Check cluster load before submitting

`sinfo-gacrc` is the GACRC-configured wrapper that shows per-node state, CPU, memory, features, and GPU availability in one output. During peak hours (weekday afternoons), `batch` fills up fast — check if `highmem_p` has idle nodes before assuming you have to wait in a long batch queue.

```bash
sinfo-gacrc          # full output
sinfo-gacrc 40 50    # with wider columns for long node lists
```

[NodeStat by pbasting](https://github.com/pbasting/nodestat) is still my go-to custom script for a quick summary of idle resources by partition. Clone it once to `/home/$USER/tools/` and alias it.

### Shell setup: tmux + oh-my-bash

Still recommend Oh-my-bash for color and prompt customization. Still recommend tmux for session persistence. The combination of `tmux new -s <name>` before every interactive session has saved me from redoing hours of setup more times than I can count.

### Snippets

Whether you use Termius snippets, VS Code snippets, or just a `~/.bash_aliases` file — having one-key access to your most-used commands pays off within the first week. My current must-haves:

```bash
alias myq='sq --me'
alias scratch='cd /scratch/$USER'
alias work='cd /work/bergmanlab'
alias interact8='interact -c 8 --mem=16G --time=8:00:00'
alias seffj='seff'    # I always forget the command name
```

### Use versioned module names in scripts

```bash
# Bad — "default" R version can change when GACRC adds a newer one
module load R

# Good — reproducible
module load R/4.3.1-foss-2022a
```

### Know how to recover deleted home files

If you accidentally delete something from `/home`, the snapshots are your friend. They live at `/home/.zfs/snapshot/` and are accessible from the xfer node or a compute node. Daily snapshots go back 14 days; older ones require a GACRC ticket.

```bash
# On xfer node or compute node:
ls /home/.zfs/snapshot/
cd /home/.zfs/snapshot/zrepl_YYYYMMDD_HHMMSS_000/MyID/
cp accidentally-deleted-file /home/MyID/
```

### Use Globus for big transfers

If you're moving more than a few GB between Sapelo2 and your laptop, external storage, or another cluster — use Globus. It's resumable, runs in the background, and is much faster than `scp` for large datasets. Available at [app.globus.org](https://app.globus.org) and also has a CLI accessible from the xfer node.

### The scavenge_p partition is free speedup

If you're submitting short jobs (under 4 hours) to `batch`, they may get automatically routed to idle buy-in nodes via `scavenge_p`. You don't have to do anything — it happens automatically. This can significantly reduce wait times when `batch` is busy. Just don't submit jobs with artificially inflated time limits to game this — it defeats the purpose and GACRC is aware of the pattern.

---

## Final thoughts

Sapelo2 has gotten significantly better since 2021 — more hardware, more partitions, OOD, better `interact` ergonomics. The core etiquette hasn't changed: be a good citizen on the login node, clean up your scratch, request only what you need.

The Claude Code addition is genuinely useful but requires the same discipline: make sure you're on a compute node before you start, give it a CLAUDE.md with cluster context, and always review generated sbatch scripts before submitting. It doesn't know your queue wait times or your lab's resource budget.

GACRC staff are helpful and responsive — gacrc@uga.edu or the ticket portal for anything that's not answered by the wiki. They'd rather answer a question than clean up a login node gone rogue.

Good luck out there. May your jobs run and your scratch never fill.
