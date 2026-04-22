# Claude Code on Sapelo2 — tips & tricks

Stuff you hit *after* you get it running. Prerequisites: [README.md](README.md).

## What Claude Code cannot do on Sapelo2

**It cannot run `interact` or `srun --pty` itself.**

Claude Code's bash tool runs in a non-interactive shell with no pseudo-terminal. Any `srun --pty` variant fails. By design — you don't want an AI autonomously hopping onto compute nodes without you knowing.

Mental model: **Claude = script writer + job submitter, not an interactive compute-node user.** You `interact` onto a node; Claude dispatches batch work from there:

```bash
# Claude, autonomously:
sinfo -p gpu_p -N -o "%N %G %C %e %T"     # check availability first
sbatch scripts/run_embedding.sh            # tuned to what's actually free
squeue --me
sacct -j 44119813 --format=State,Elapsed,MaxRSS
```

## Session survival — honest version

Claude session lifetime = `interact` walltime. When `interact` ends, Claude ends. No workaround inside the live session.

- **Walltime expiry** is the dominant failure mode. Request enough time upfront. Save intermediate state to files so you can resume.
- **SSH/VPN drop** only matters if you ran `tmux` on the login node *before* `interact`. Then the interact job survives the drop and you can `tmux attach` to get back in. Without that, the pty hangup kills interact.
- **`tmux` inside `interact`** is for splits/panels, not survival — it dies with the job.

So: request generous walltime, wrap in tmux if you're on a flaky off-campus VPN, otherwise keep it simple.

## The frozen terminal problem

You will hit this: Claude is running, looks active, then nothing responds. Not Esc, not Ctrl+C.

What's usually happening: one of Claude's subprocess shells hung on something — a `sacct` call, a long download — and grabbed the pty. Claude with bypass permissions and multiple shells open (the `5 shells` you see in the statusline) is a mini orchestrator. One deadlocked shell can freeze the whole interface.

Tell-tale sign: **"Sock-hopping…"** with a growing timer. Claude is retrying the API after losing connection, usually because the hung subprocess blocked it from receiving responses.

**Don't wait it out.** It won't self-recover.

From a new SSH connection:

```bash
tmux attach -t <session>                  # if you used tmux
# or SSH directly to the compute node:
ssh MyID@ra3-22
squeue -j <JOBID>                         # is the interact job still alive?
claude --resume                           # picks up the last checkpoint
```

`--resume` recovers the conversation — you only lose whatever was mid-execution when it froze.

## The statusline — reading the fields

```
scratch:/ms1_cis_regulatory │ Opus 4.6 (1M context) │ ⏱ 1h 43m    152038 tokens
ctx  ███░░░░░░░░░░░░░░░░░ 15% / 1.0M
5h   ███████░░░ 71% ~3h 01m │  7d   ████░░░░░░ 43% ~56h 01m
💰 $10.29 │ ⬇ 54K ⬆ 75K │ ✎ +1474 -31
⏵⏵ bypass permissions on · 5 shells
```

- **ctx 15%** — 85% of 1M tokens left. Above 80% is where output quality starts degrading; `/compact` before that.
- **5h 71%** — used 71% of the 5-hour window. Determines whether you can keep running Opus.
- **💰 $10.29** — session cost. With Opus + bypass + 5 shells, accumulates fast.
- **5 shells** — concurrent subprocess shells. One hanging shell can freeze the UI.
- **bypass permissions on** — Claude won't ask for approval on tool calls. Useful for autonomous runs; risky if something goes wrong.

## Effort levels in practice

`/effort low|medium|high|max` controls reasoning depth — and cost.

- `low` / `medium` — file reads, `squeue` polling, routine edits, most bioinformatics scripts
- `high` — new script generation, complex pipeline design, tricky debugging
- `max` — architecture decisions, hard ML failures, multi-step planning (Opus only; resets per session)

Asymmetry matters: too low on a hard problem risks a confident wrong answer (a misdiagnosed SLURM error wastes hours of compute). Too high on `ls` wastes a few tokens. When unsure, medium.

## Perks worth using

Sapelo2 has real advantages over a local machine that are easy to miss:

- **Existing software modules bundle most of what you need.** `SciPy-bundle` ships numpy/scipy/pandas compiled against the right BLAS. `Biopython`, `matplotlib`, `scikit-learn` have modules. Check `module avail` / `module spider` before `pip install`.
- **`/lscratch` is node-local, fast, and free.** For I/O-bound single-node jobs, staging inputs onto `/lscratch` and copying results out at the end can halve wall-time.
- **`scavenge_p` bursts onto idle buy-in hardware for free**, up to 4 hours, preemptible if the owning lab needs the nodes. Perfect for smoke tests, grid searches, anything resumable from a checkpoint.
- **IOB buy-in partition (`iob_p`)** — if your lab has access, a 22-node backup when `batch` is full. 128 cores/node, 30-day time limit.
- **L4 GPUs are almost always idle.** Most researchers reflexively request A100s. A 24 GB L4 runs ESM-2 3B and ESMFold on short sequences with zero queue wait.

## Things still figuring out

**Automatic env detection** — having Claude infer which conda env a script needs from its imports, without specifying. Possible manually, not automatic yet.

**Long autonomous runs** — for 24 h embedding jobs, even `--resume` has limits. If context fills or compaction drops key state, it loses track. Working on a checkpoint pattern where Claude writes its own progress notes to a file.

**Cost tracking across sessions** — the statusline shows per-session cost, not cumulative. [`ccusage`](https://github.com/ryoppippi/ccusage) handles cross-session totals.

## Portability

Large chunks of `CLAUDE.md` are universal Claude Code + SLURM patterns, not Sapelo2-specific: no shell state between bash calls; post-submission health check; background job-monitoring timer; ML pipeline sanity checks; reuse-and-resume pipeline design. If you port this file to another cluster, strip the GACRC-specific bits (partition names, QOS table, module toolchain names, `/work` and `/project` conventions) and keep the universal sections.

Get the infrastructure right first. Then let Claude handle the pipeline logic.
