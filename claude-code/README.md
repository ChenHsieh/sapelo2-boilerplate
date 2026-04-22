# Claude Code on Sapelo2 — setup

HPC-tuned ruleset, permission allowlist, and statusline for running Claude Code on [GACRC Sapelo2](https://wiki.gacrc.uga.edu). Narrative version with the reasoning behind each piece.

Advanced workflow (multi-env juggling, session survival, frozen-terminal recovery, statusline fields, effort levels): see [ADVANCED.md](ADVANCED.md).

Universal (non-cluster-specific) agentic research practices — portable skills, session hygiene, cowork conventions: [`agentic-research-toolkit`](https://github.com/ChenHsieh/agentic-research-toolkit).

## Read before you copy

This config is aggressive:

- **`settings.json` runs in `auto` mode** with `skipDangerousModePermissionPrompt: true`. Pre-approved commands execute without asking. The allowlist includes `Bash(python:*)`, `Bash(pip install:*)`, `Bash(sbatch:*)`. I'm comfortable with this because only I touch my home and scratch, `/scratch` purges in 30 days so accidents are bounded, and I never hold elevated cluster privileges. Your threat model may differ.
- **`CLAUDE.md` is date-stamped where facts rot fast** (module versions: 2026-04; QOS table: 2026-04-07). Re-verify with `module avail` and `sacctmgr show qos` before trusting the tables.
- **`statusline-command.sh` uses bash + python3, not jq**, because Sapelo2 login nodes don't ship `jq`. If your cluster has `jq`, the script simplifies.

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

## The mental model that matters most

**Claude Code's bash tool runs on whatever node your shell is on when you launch it.**

If you SSH into Sapelo2 and type `claude` on the login node, every command Claude executes runs on the login node. Fine for file reads, script edits, `sbatch` submissions. Not fine for model inference, large file ops, or anything CPU-intensive. GACRC watches login-node usage.

Workflow:

```mermaid
flowchart LR
    L[local] -->|ssh<br/><small>+ vpn if off-campus</small>| G[login node]
    G -->|interact| C[compute node]
    C --> K[claude]
    K -.->|sbatch| H[batch compute nodes]
```

```bash
interact -c 16 --mem=64G --time=12:00:00 --gres=gpu:L4:1   # request for the whole session
claude                                                      # inside the interact shell
```

No venv activation before `claude` — envs get activated inline in bash calls, or in sbatch headers. Claude itself submits and manages `sbatch` jobs from inside the interact session, tuning resources against `sinfo` in real time.

`tmux` is optional. Useful for splits/panels; also covers SSH drops *if* started on the login node before `interact`. It does **not** save a Claude session from `interact` walltime expiry.

## Prefer a plain terminal over VS Code

Use a plain terminal emulator (Terminal.app, iTerm2, Alacritty, WezTerm, Ghostty) — skip VS Code Remote SSH for HPC work. Two reasons:

1. **Memory.** VS Code's remote server runs persistent language servers on the login node (pylance, node, etc.). Invisible to you, very visible to GACRC. Most "why did I get a memory warning" mysteries trace back to VS Code.
2. **Control.** Running Claude inside VS Code's agent mode hides tool calls behind UI chrome. The CLI shows every bash invocation, every file read, every decision point. More signal, fewer surprises.

If you miss split panes, `tmux` handles that (`Ctrl+a |` / `-` to split in this config).

## Managing conda environments

Default: **don't pre-activate anything**. Launch `claude` from the bare interact shell and let it switch envs inline when needed — the stateless bash tool makes pre-activation fragile anyway.

**Interactive (via Claude) — `conda run -n` per command:**

```bash
conda run -n bert_env python run_dnabert.py --input data.fa
conda run -n mamba_env python run_hyenadna.py --input data.fa
```

Runs in the target env without permanently activating it. Stateless-friendly.

**sbatch — activate inside the job script, with `source activate`:**

A fresh sbatch shell has not been touched by `conda init`, so `conda activate` fails instantly. `source activate` uses the older path that works without init.

```bash
#!/bin/bash
#SBATCH --job-name=dnabert_embed
# ...

module load Miniforge3/24.11.3-0
source activate bert_env       # NOT `conda activate`

python generate_embeddings.py
```

**Rule:** nothing activated before `claude`; use `conda run -n` inline; sbatch scripts are self-contained and use `source activate`.

## The `CLAUDE.md` file

`CLAUDE.md` in this directory is what Claude Code reads at startup. For Sapelo2 it codifies:

- Login-node vs compute-node rules (refuse heavy commands on login nodes)
- Filesystem paths and quotas — and what each is for
- `source activate` vs `conda activate` in sbatch
- Module resolution order (check modules before creating new envs)
- GPU right-sizing (L4 before A100 unless needed)
- Many-small-jobs > one-large-job
- Post-submission health check (15–30s after `sbatch`, catch instant failures early)
- Background job-monitoring timer pattern
- ML pipeline sanity checks (shape, pairwise correlation, dead dims, PCA)

The more context Claude has about your environment, the fewer times it tries `pip install` or assumes `apt` works.

## Quick reference

```bash
# Launch workflow (you, not Claude)
interact -c 16 --mem=64G --time=12:00:00
claude                                      # no pre-activation needed

# Multi-env work, via Claude:
conda run -n bert_env python script.py
conda run -n mamba_env python other_script.py

# Scratch hygiene
du -sh /scratch/$USER/
find /scratch/$USER/ -mtime +25 -name "*.out"   # close to 30-day purge
```

For session-survival, frozen-terminal recovery, statusline fields, effort levels, and cluster perks: [ADVANCED.md](ADVANCED.md).
