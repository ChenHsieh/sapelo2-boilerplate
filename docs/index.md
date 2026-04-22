---
hide:
  - navigation
  - toc
---

<pre class="hero-ascii">
sapelo2-boilerplate
───────────────────
notes, sbatch scripts, and Claude Code rules for running work on
UGA's HPC cluster. written from things that broke first.
</pre>

## Start here

- [Getting started](getting-started/index.md) — basics: login etiquette, storage, `interact`, sbatch.
- [Getting started — tips & tricks](getting-started/advanced.md) — arrays, `seff` tuning, `/lscratch`, shell setup.
- [Claude Code setup](claude-code/index.md) — the `CLAUDE.md` ruleset, and why each rule exists.
- [Claude Code — tips & tricks](claude-code/advanced.md) — session survival, frozen-terminal recovery, statusline, effort levels.
- [CLAUDE.md ruleset](claude-code/rules.md) — the raw rules.
- [sbatch templates](reference/sbatch.md) · [Storage topology](reference/storage.md)

## Conventions

- Job I/O in `/scratch/$USER/`. Never `/home`. `/scratch` purges at 30 days.
- Inside sbatch: `source activate env`, never `conda activate`. Fresh sbatch shells have no conda init.
- GPUs: L4 (24 GB) before A100 (80 GB) unless the model needs it. L4s are almost always idle.

Rationale + failure modes: [the ruleset](claude-code/rules.md).

## Session architecture

```mermaid
flowchart LR
    L[local] -->|ssh<br/><small>+ vpn if off-campus</small>| G[login node]
    G -->|interact| C[compute node]
    C --> K[claude]
    K -.->|sbatch| H[batch compute nodes]
```

Claude Code's bash runs wherever the shell that launched it runs. Start `interact` with enough resources for the full session — long time, large memory, GPU if compiling something interactively — then `claude` from inside.

No venv activation needed before `claude`; envs get activated inline in bash calls or in sbatch headers. Claude itself submits and manages `sbatch` jobs, tuning resources against `sinfo` in real time.

`tmux` is optional — useful for splits or covering SSH drops (start it on the login node *before* `interact`), but it won't save a Claude session from `interact` walltime expiry.

## What's universal vs cluster-specific

Most of this is GACRC-specific (partitions, QOS, module names, `/work/<lab>`). Portable parts:

- Post-submission health check (15–30 s after `sbatch`)
- Many small jobs over one large one
- `source activate` vs `conda activate` in batch shells
- Embedding pipeline sanity checks (shape, pairwise correlation, dead dims)
- Reuse-and-resume pipeline design

Universal agentic research practices (skills, session hygiene, cowork conventions): [agentic-research-toolkit](https://github.com/ChenHsieh/agentic-research-toolkit).

---

Source: [github.com/ChenHsieh/sapelo2-boilerplate](https://github.com/ChenHsieh/sapelo2-boilerplate)
