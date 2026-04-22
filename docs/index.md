---
hide:
  - navigation
  - toc
---

# Sapelo2 Boilerplate

<p style="font-size: 1.15rem; opacity: 0.85;">
Battle-tested scripts, agent rules, and pipelines for running real work on <a href="https://wiki.gacrc.uga.edu">GACRC Sapelo2</a> — UGA's shared HPC cluster. Opinionated. Cluster-aware. Written from things that broke first.
</p>

<div class="grid cards" markdown>

-   :material-rocket-launch-outline: __Getting started__

    ---

    Sapelo2 from zero: SSH clients, storage model, `interact`, sbatch basics, Claude Code on shared HPC. Updated 2026.

    [:octicons-arrow-right-24: Start here](getting-started.md)

-   :material-robot-outline: __Claude Code setup__

    ---

    The ruleset, permission allowlist, and jq-free statusline I actually run — plus the reasoning behind each rule.

    [:octicons-arrow-right-24: Claude Code](claude-code/index.md)

-   :material-dna: __Tool recipes__

    ---

    sbatch scripts + notes for alphaFold, BUSCO, OrthoFinder, nf-core/rnaseq, OmegaFold, SpeedPPI, Trinotate, MCScanX.

    [:octicons-arrow-right-24: Recipes](recipes/index.md)

-   :material-pipe: __Pipelines__

    ---

    Snakemake pipelines: YouTube → Whisper transcription, and cross-species DIAMOND best-hit annotation.

    [:octicons-arrow-right-24: Pipelines](pipelines/index.md)

</div>

## Session architecture

```mermaid
flowchart LR
    L[Local machine] -->|SSH + VPN| G[Login node<br/><small>ss-sub*</small>]
    G --> T[tmux<br/><small>survives drops</small>]
    T --> I[interact]
    I --> C[compute node<br/><small>c4-*, b1-*, a4-*</small>]
    C -->|source activate env| K[claude]
    G -.->|sbatch| B[(Batch queue)]
    B --> H[compute nodes]
    style G fill:#ede7f6,stroke:#5e35b1,color:#000
    style C fill:#e8f5e9,stroke:#2e7d32,color:#000
    style K fill:#fff3e0,stroke:#ef6c00,color:#000
```

Claude Code's bash tool runs wherever the shell that launched it runs. Launch it on the login node and every command hits the login node. Launch it inside an `interact` session and it gets real compute. The cluster doesn't care that you're using a fancy AI tool — same rules apply.

## Conventions

!!! tip "One rule, everywhere"
    Job I/O lands in `/scratch/$USER/`, never `/home`. `/scratch` has no quota but purges every 30 days.

!!! warning "sbatch footgun"
    In sbatch scripts use `source activate env`, **never** `conda activate`. Fresh sbatch shells have no conda init — `conda activate` fails instantly, `source activate` works.

!!! info "Right-size GPUs"
    L4 (24 GB) before A100 (80 GB) unless the model really needs it. L4 nodes are almost always idle.

Full rule set with reasoning: [Claude Code ruleset](claude-code/rules.md).

## What's universal vs cluster-specific

Most of this repo is GACRC-Sapelo2-specific (module names, partitions, QOS, `/work/<lab>` conventions). But several patterns are portable:

- Post-submission health check (15–30s after `sbatch`)
- Many-small-jobs > one-large-job
- `source activate` vs `conda activate` in batch shells
- ML pipeline sanity checks (shape, pairwise correlation, dead dimensions)
- Reuse-and-resume pipeline design

For universal (non-cluster-specific) agentic research practices — skills, session hygiene, cowork conventions — see [agentic-research-toolkit](https://github.com/ChenHsieh/agentic-research-toolkit).
