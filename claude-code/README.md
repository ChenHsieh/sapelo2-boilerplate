# Using Claude Code on Sapelo2: What Actually Works (and What Doesn't)

*HPC · bioinformatics · Claude Code · Sapelo2 · UGA · ~10 min read*

I've been running Claude Code on [Sapelo2](https://wiki.gacrc.uga.edu) — UGA's HPC cluster — for a while now, mostly for poplar genomics: RNA-seq pipelines, SLURM jobs, multiple model environments, and multi-step embedding workflows across DNA foundation models. It's genuinely useful, but the learning curve involves non-obvious gotchas I haven't seen written up anywhere.

This isn't a Claude Code intro. This is the stuff you hit *after* you get it running — session architecture, frozen terminals, "wait, where does this actually run?" confusion, and multi-environment juggling.

The files in this directory — `CLAUDE.md`, `settings.json`, `statusline-command.sh` — are what I actually run. This README is the narrative version: what works, what doesn't, and the reasoning underneath each rule.

For universal (non-cluster-specific) agentic research practices — portable skills, session hygiene, cowork conventions — see [`agentic-research-toolkit`](https://github.com/ChenHsieh/agentic-research-toolkit).

---

## Read before you copy

This config is aggressive:

- **`settings.json` runs in `auto` mode** with `skipDangerousModePermissionPrompt: true`. Pre-approved commands execute without asking. The allowlist includes `Bash(python:*)`, `Bash(pip install:*)`, `Bash(sbatch:*)`. I'm comfortable with this because only I touch my home and scratch, `/scratch` purges in 30 days so accidents are bounded, and I never hold elevated cluster privileges. Your threat model may differ.
- **`CLAUDE.md` is date-stamped where facts rot fast** (module versions: 2026-04; QOS table: 2026-04-07). Re-verify with `module avail` and `sacctmgr show qos` before trusting the tables.
- **`statusline-command.sh` uses bash + python3, not jq**, because Sapelo2 login nodes don't ship `jq`. If your cluster has `jq`, the script simplifies.

---

## Install

```bash
git clone https://github.com/ChenHsieh/sapelo2-boilerplate.git ~/sapelo2-boilerplate
cp -r ~/sapelo2-boilerplate/claude-code ~/sapelo2-claude-setup
cd ~/sapelo2-claude-setup
sed -i "s/MYID/$USER/g"         CLAUDE.md settings.json statusline-command.sh
sed -i "s/YOURLAB/<your-lab>/g" CLAUDE.md
mkdir -p ~/.claude && cp CLAUDE.md settings.json statusline-command.sh ~/.claude/
chmod +x ~/.claude/statusline-command.sh
echo 'export ANTHROPIC_API_KEY=sk-ant-...' >> ~/.bashrc   # Sapelo2 can't do OAuth (no browser)
```

The `cp -r` keeps your personalized working copy separate from the clone so `git pull` stays clean. `MYID` is your UGA username; `YOURLAB` is your lab's allocation under `/work/` and `/project/`.

---

## The mental model that matters most

Before anything else, get this straight:

**Claude Code's bash tool runs on whatever node your shell is on when you launch it.**

That means if you SSH into Sapelo2 and type `claude` on the login node, every command Claude executes runs on the **login node**. This is fine for file reads, script edits, and `sbatch` submissions. It is emphatically not fine for model inference, large file operations, or anything CPU-intensive. GACRC watches login node usage and they will notice.

The correct workflow for compute-heavy sessions:

```
Local → VPN → SSH → login node → tmux → interact → source activate → claude
```

That `interact` session gives you a real compute node with actual resources. Claude Code then dispatches its bash commands there instead of on the login node.

---

## What Claude Code cannot do on Sapelo2

**It cannot run `interact` or `srun --pty` itself.**

Claude Code's bash tool runs in a non-interactive shell with no pseudo-terminal (pty) support. The moment it tries `interact` or any `srun --pty` variant, it fails. This is by design — you don't want an AI autonomously hopping onto compute nodes without you knowing.

The correct mental model: **Claude Code = script writer + job submitter, not an interactive compute node user.** You get yourself onto a compute node via `interact`, then launch Claude there. Claude submits further work via `sbatch`.

```bash
# You do this manually:
interact -c 8 --mem=16G --time=12:00:00 --gres=gpu:L4:1
source activate mamba_env
tmux new -s ml_work
claude

# Claude does this autonomously:
sbatch scripts/run_embedding.sh
squeue -u $USER
sacct -j 44119813 --format=State,Elapsed,MaxRSS
```

---

## The session survival question

A question I kept asking: *if my VPN drops mid-session, what survives?*

| Layer | Survives SSH/VPN drop | Survives walltime |
|---|---|---|
| `tmux` on login node | ✅ Yes — indefinitely | ✅ Yes |
| `interact` job | ❌ No — pty hangup kills it | ❌ Hard limit |
| `tmux` *inside* `interact` | ✅ Within job lifetime | ❌ Dies with job |
| Claude session | ❌ Dies with `interact` | ❌ Dies with `interact` |

**tmux on the login node survives everything.** But if you're inside an `interact` session when your connection drops, the pty hangup will likely kill the job — and Claude with it.

Practical implication: **Claude session lifetime = interact walltime**. Request enough time upfront. For a model compilation or large embedding run:

```bash
interact -t 24:00:00 -m 64gb --gres=gpu:1
```

Start tmux *before* launching Claude. That way if SSH drops but the SLURM job survives, you can reconnect, SSH back to the compute node, and `tmux attach`.

---

## The frozen terminal problem

You will hit this eventually: Claude is running, looks active, then nothing responds. Not Esc, not Ctrl+C.

What's usually happening: one of Claude's subprocess shells hung on something — a `sacct` call, a long download check — and grabbed the pty. Claude Code with bypass permissions and multiple shells open (the `5 shells` you see in the statusline) is a mini orchestrator. One deadlocked shell can freeze the whole interface.

Tell-tale sign: **"Sock-hopping…"** with a growing timer (14 minutes in my worst case). Claude is retrying the API after losing the connection, usually because the hung subprocess blocked it from receiving responses.

**Don't wait it out.** It won't self-recover.

From a new SSH connection:

```bash
tmux attach -t <session>
# If the pane is still frozen:
Ctrl+a c                       # open new tmux window (prefix is ctrl+a in this config)
squeue -u $USER                # are the SLURM jobs still alive?
claude --resume                # pick up last checkpoint
```

`--resume` recovers the conversation — you only lose whatever was mid-execution when it froze.

---

## Managing multiple conda environments

This is where bioinformatics with Claude gets interesting. My current project uses several DNA foundation models — DNABERT, HyenaDNA, AgroNT, PlantCaduceus — and they do *not* share a conda env. BERT-based and Mamba/SSM-based models have conflicting dependencies.

**Option A: activate the primary env before launching Claude.**

Whatever env you activate before `claude` becomes the inherited default. Good when most of your session uses one environment.

```bash
source activate mamba_env
claude
# Claude's bash tool now runs in mamba_env by default
```

**Option B: let Claude switch per command.**

For multi-env sessions, cleaner to let Claude handle switching inline rather than pre-activating.

```bash
# In a bash tool call:
conda run -n bert_env python run_dnabert.py --input data.fa
conda run -n mamba_env python run_hyenadna.py --input data.fa
```

`conda run -n <env>` runs a command in the target env without permanently activating it — perfect for Claude's stateless bash calls.

**Option C: explicit activation in SLURM scripts.**

For anything going to `sbatch`, always activate the env explicitly in the job script — and use `source activate`, not `conda activate`. A fresh sbatch shell has not been touched by `conda init`, so `conda activate` fails instantly; `source activate` uses the older path that works without init.

```bash
#!/bin/bash
#SBATCH --job-name=dnabert_embed
# ...

module load Miniforge3/24.11.3-0
source activate bert_env       # NOT `conda activate`

python generate_embeddings.py
```

**Rule:** Claude Code inherits; SLURM jobs must be self-contained; sbatch uses `source activate`.

---

## The VS Code memory warning mystery

I once got a GACRC warning about excessive memory on a login node — but I hadn't been running anything. The culprit was **VS Code Remote SSH**.

VS Code's remote server runs persistent background processes on the login node, including language servers for Python, R, and other extensions. They persist even when you close the VS Code window locally. Invisible to you, very visible to GACRC.

Claude Code itself is lightweight on the login node — Node.js-based, mostly idle between commands. If you get a memory warning on a node you think is idle:

```bash
ps aux | grep $USER | grep vscode
```

Fix: close VS Code properly, or use "Kill VS Code Server on Host" from its remote connection menu before logging off.

---

## The statusline: what all that info means

```
scratch:/ms1_cis_regulatory │ Opus 4.6 (1M context) │ ⏱ 1h 43m    152038 tokens
ctx  ███░░░░░░░░░░░░░░░░░ 15% / 1.0M
5h   ███████░░░ 71% ~3h 01m │  7d   ████░░░░░░ 43% ~56h 01m
💰 $10.29 │ ⬇ 54K ⬆ 75K │ ✎ +1474 -31
⏵⏵ bypass permissions on · 5 shells
```

- **ctx 15%** — 85% of 1M tokens left. Above 80% is where output quality starts degrading; `/compact` before that.
- **5h 71%** — used 71% of your 5-hour usage window. Determines whether you can keep running Opus.
- **💰 $10.29** — session cost. With Opus + bypass + 5 shells, this accumulates fast.
- **5 shells** — Claude has 5 concurrent subprocess shells open. One hanging shell can freeze the UI.
- **bypass permissions on** — Claude won't ask for approval on tool calls. Useful for autonomous runs; risky if something goes wrong.

---

## Effort levels in practice

`/effort low|medium|high|max` controls reasoning depth — and cost.

- `low` / `medium` — file reads, `squeue` polling, routine edits, most bioinformatics scripts
- `high` — new script generation, complex pipeline design, tricky debugging
- `max` — architecture decisions, hard ML failures, multi-step planning (Opus only, resets per session)

Asymmetry matters: too low on a hard problem risks a confident wrong answer (a misdiagnosed SLURM error wastes hours of compute). Too high on `ls` wastes a few tokens. When unsure, medium.

---

## The CLAUDE.md file

`CLAUDE.md` in this directory is what Claude Code reads at startup. For Sapelo2 specifically, it codifies:

- Login-node vs compute-node rules (refuse heavy commands on login nodes)
- Filesystem paths and quotas (`/home`, `/scratch`, `/work`, `/project`, `/lscratch`) + what each is for
- `source activate` vs `conda activate` (see above)
- Module resolution order (check modules before creating envs)
- GPU right-sizing (L4 before A100 unless needed)
- Many-small-jobs > one-large-job (for parallelism + cheap retries)
- Post-submission health check (15–30s after `sbatch`, catch instant failures early)
- Background job-monitoring timer pattern
- ML pipeline sanity checks (shape, pairwise correlation, dead dims, PCA)

The more context Claude has about your environment, the fewer times it tries `pip install` or assumes `apt` works.

---

## Perks worth using

Sapelo2 has real advantages over a local machine that are easy to miss:

- **Existing software modules bundle most of what you need.** `SciPy-bundle` ships numpy/scipy/pandas compiled against the right BLAS. `Biopython`, `matplotlib`, `scikit-learn` have modules. Check `module avail` or `module spider` before `pip install`.
- **`/lscratch` is node-local, fast, and free.** For I/O-bound single-node jobs, staging inputs onto `/lscratch` and copying results to `/scratch` at the end can halve wall-time.
- **`scavenge_p` bursts onto idle buy-in hardware for free**, up to 4 hours, with jobs preemptible if the owning lab needs the nodes. Perfect for smoke tests, grid searches, anything resumable from a checkpoint.
- **IOB buy-in partition (`iob_p`)** — if your lab has access, a 22-node backup when `batch` is full. 128 cores/node, 30-day time limit.
- **L4 GPUs are almost always idle.** Most researchers reflexively ask for A100s. A 24 GB L4 runs ESM-2 3B and ESMFold on short sequences with zero queue wait.

---

## Things I'm still figuring out

**Automatic env detection** — I want Claude to infer which conda env a script needs from its imports, without specifying. Possible manually, not automatic yet.

**Long autonomous runs** — for 24h embedding jobs, even `--resume` has limits. If context fills or compaction drops key state, it can lose track. Working on a checkpoint pattern where Claude writes its own progress notes to a file.

**Cost tracking across sessions** — the statusline shows per-session cost but not cumulative. [`ccusage`](https://github.com/ryoppippi/ccusage) handles cross-session totals.

---

## Quick reference

```bash
# Launch workflow (you, not Claude)
interact -c 8 --mem=16G --time=12:00:00
source activate <primary_env>
tmux new -s work
claude

# If Claude freezes — from a new SSH connection
tmux attach -t work
Ctrl+a c                       # new pane
claude --resume

# Multi-env within a Claude session
conda run -n bert_env python script.py
conda run -n mamba_env python other_script.py

# Scratch hygiene
du -sh /scratch/$USER/
find /scratch/$USER/ -mtime +25 -name "*.out"   # files close to 30-day purge
```

---

## A note on portability

Large chunks of `CLAUDE.md` are universal Claude Code + SLURM patterns, not Sapelo2-specific: no shell state between bash calls; post-submission health check; background job-monitoring timer; ML pipeline sanity checks; reuse-and-resume pipeline design. If you port this file to another cluster, strip the GACRC-specific bits (partition names, QOS table, module toolchain names, `/work` and `/project` conventions) and keep the universal sections.

The combination of `tmux` + `interact` + Claude Code is genuinely powerful for bioinformatics pipeline work — but it demands being deliberate about session architecture. The cluster doesn't care that you're using a fancy AI tool; it still has the same rules about login nodes, scratch storage, and shared resources.

Get the infrastructure right first, then let Claude handle the pipeline logic.
